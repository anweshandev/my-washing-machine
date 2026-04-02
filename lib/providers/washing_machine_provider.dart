import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/washing_machine_bridge.dart';
import '../services/tts_service.dart';
import '../models/washing_data.dart';

/// Represents a discovered or paired Bluetooth device.
class BtDevice {
  final String name;
  final String address;
  final bool paired;
  BtDevice({required this.name, required this.address, this.paired = false});

  /// Returns true if this device looks like an IFB washing machine.
  bool get isWashingMachine {
    final n = name.toUpperCase();
    return n.contains('WB-DUAL') || n.contains('IFB') || n.contains('SENORITA');
  }
}

/// Live telemetry from the washing machine.
class MachineTelemetry {
  final int processState;
  final int temperature;
  final int spinSpeed;
  final int balanceTime; // in minutes from device
  final String error;
  final int errorCode;
  final bool childLock;
  final bool doorLock;

  MachineTelemetry({
    this.processState = 0,
    this.temperature = 0,
    this.spinSpeed = 0,
    this.balanceTime = 0,
    this.error = 'No error',
    this.errorCode = 0,
    this.childLock = false,
    this.doorLock = false,
  });

  String get processName => WashingData.getProcessName(processState);
  String get remainingTime {
    final h = balanceTime ~/ 60;
    final m = balanceTime % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m.toString().padLeft(2, '0')}:00';
  }

  bool get isRunning =>
      processState >= 2 &&
          processState <= 12 &&
          processState != 13 &&
          processState != 14 ||
      processState == 17 ||
      processState == 18 ||
      processState == 19;
  bool get isCompleted => processState == 13 || processState == 23;
  bool get isPaused => processState == 14;
  bool get hasError => errorCode != 0;
}

enum BtConnectionState { disconnected, connecting, connected }

/// Alert from the washing machine (error or status notification).
class MachineAlert {
  final String message;
  final int errorCode;
  final DateTime time;
  MachineAlert({required this.message, required this.errorCode, DateTime? time})
    : time = time ?? DateTime.now();
}

/// Main state manager for the washing machine app.
class WashingMachineProvider extends ChangeNotifier {
  // ─── Connection State ───
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtConnectionState get connectionState => _connectionState;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  String? _connectedDeviceAddress;

  // ─── Scan State ───
  final List<BtDevice> _pairedDevices = [];
  List<BtDevice> get pairedDevices => List.unmodifiable(_pairedDevices);

  final List<BtDevice> _discoveredDevices = [];
  List<BtDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// Only washing-machine devices from paired list.
  List<BtDevice> get filteredPairedDevices =>
      _pairedDevices.where((d) => d.isWashingMachine).toList();

  /// Only washing-machine devices from discovered list.
  List<BtDevice> get filteredDiscoveredDevices =>
      _discoveredDevices.where((d) => d.isWashingMachine).toList();

  /// All paired devices (unfiltered) for advanced users.
  List<BtDevice> get allPairedDevices => List.unmodifiable(_pairedDevices);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  bool _showAllDevices = false;
  bool get showAllDevices => _showAllDevices;
  void toggleShowAllDevices() {
    _showAllDevices = !_showAllDevices;
    notifyListeners();
  }

  // ─── Telemetry ───
  MachineTelemetry _telemetry = MachineTelemetry();
  MachineTelemetry get telemetry => _telemetry;

  // ─── Alerts ───
  final List<MachineAlert> _alerts = [];
  List<MachineAlert> get alerts => List.unmodifiable(_alerts);
  MachineAlert? _latestAlert;
  MachineAlert? get latestAlert => _latestAlert;
  int _lastErrorCode = 0;

  /// Clear the latest alert (dismiss).
  void dismissAlert() {
    _latestAlert = null;
    notifyListeners();
  }

  // ─── Program Config ───
  int _selectedProgramId = 0;
  int get selectedProgramId => _selectedProgramId;
  WashProgram get selectedProgram => WashingData.programs[_selectedProgramId];

  int _temperature = 40;
  int get temperature => _temperature;

  int _spinSpeed = 1400;
  int get spinSpeed => _spinSpeed;

  bool _preWash = false;
  bool get preWash => _preWash;
  bool _rinseHold = false;
  bool get rinseHold => _rinseHold;
  bool _soak = false;
  bool get soak => _soak;
  int _extraRinse = 0;
  int get extraRinse => _extraRinse;
  bool _timeSaver = false;
  bool get timeSaver => _timeSaver;
  int _delayStart = 0;
  int get delayStart => _delayStart;

  // ─── Status log ───
  final List<String> _log = [];
  List<String> get log => List.unmodifiable(_log);

  // ─── Subscriptions ───
  StreamSubscription? _scanSub;
  StreamSubscription? _connectionSub;
  StreamSubscription? _dataSub;

  Timer? _pollTimer;
  int _authRetries = 0;
  int _lastProcessState = 0;
  final TtsService _tts = TtsService();

  WashingMachineProvider() {
    _listenToStreams();
  }

  void _listenToStreams() {
    _scanSub = WashingMachineBridge.scanStream.listen(_onScanEvent);
    _connectionSub = WashingMachineBridge.connectionStream.listen(
      _onConnectionEvent,
    );
    _dataSub = WashingMachineBridge.dataStream.listen(_onDataEvent);
  }

  // ─── Scan Events ───
  void _onScanEvent(Map<String, dynamic> event) {
    // Java bridge emits { "devices": [...], "isScanning": bool }
    final devices = event['devices'];
    if (devices is List) {
      _discoveredDevices.clear();
      for (final d in devices) {
        final map = Map<String, dynamic>.from(d as Map);
        final name = (map['name'] as String?) ?? 'Unknown';
        final address = (map['address'] as String?) ?? '';
        final paired = (map['paired'] as String?) == 'true';
        if (address.isEmpty) continue;
        _discoveredDevices.add(
          BtDevice(name: name, address: address, paired: paired),
        );
      }
    }
    final scanning = event['isScanning'];
    if (scanning is bool) _isScanning = scanning;
    notifyListeners();
  }

  // ─── Connection Events ───
  void _onConnectionEvent(Map<String, dynamic> event) {
    final state = event['state'] as String? ?? '';
    final name = event['name'] as String? ?? '';
    final address = event['address'] as String? ?? '';
    _addLog('Connection: $state ${name.isNotEmpty ? "($name)" : ""}');
    switch (state) {
      case 'connecting':
        _connectionState = BtConnectionState.connecting;
        break;
      case 'connected':
        _connectionState = BtConnectionState.connected;
        _connectedDeviceName = name.isNotEmpty ? name : _connectedDeviceName;
        _tts.speak(
          'Connected to ${name.isNotEmpty ? name : "washing machine"}',
        );
        _connectedDeviceAddress = address.isNotEmpty
            ? address
            : _connectedDeviceAddress;
        // Start polling immediately on connection (no auth required)
        _startPolling();
        // Auto-authenticate on connect
        _authRetries = 0;
        _autoAuthenticate();
        break;
      case 'disconnected':
      case 'failed':
        _connectionState = BtConnectionState.disconnected;
        _isAuthenticated = false;
        _tts.speak('Disconnected from washing machine');
        _connectedDeviceName = null;
        _connectedDeviceAddress = null;
        _stopPolling();
        break;
    }
    notifyListeners();
  }

  /// Automatically authenticate after connecting.
  Future<void> _autoAuthenticate() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_connectionState == BtConnectionState.connected && !_isAuthenticated) {
      _addLog('Auto-authenticating...');
      await authenticate();
    }
  }

  // ─── Data Events (telemetry & auth feedback) ───
  void _onDataEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';
    // The Java bridge puts parsed data in a nested 'data' map
    final data = event['data'] is Map
        ? Map<String, dynamic>.from(event['data'] as Map)
        : <String, dynamic>{};

    switch (type) {
      case 'auth':
        final authenticated = data['authenticated'] == true;
        final authByte = data['authByte'] as String? ?? '';
        _isAuthenticated = authenticated;
        _addLog(
          'Auth: ${authenticated ? 'success' : 'failed (byte=$authByte)'}',
        );
        if (authenticated) {
          _authRetries = 0;
        } else if (_authRetries < 3) {
          // Retry auth
          _authRetries++;
          _addLog('Retrying auth (attempt $_authRetries)...');
          Future.delayed(const Duration(seconds: 1), () {
            if (_connectionState == BtConnectionState.connected &&
                !_isAuthenticated) {
              authenticate();
            }
          });
        }
        break;

      case 'telemetry':
        final processState = (data['processState'] as int?) ?? 0;
        final temp = (data['temperature'] as int?) ?? 0;
        final speed = (data['spinSpeed'] as int?) ?? 0;
        final balTime = (data['balanceTime'] as int?) ?? 0;
        final childLockOn = data['childLockOn'] == true;
        final doorOpen = data['isDoorOpen'] == true;
        final alarmCode = (data['alarmCode'] as int?) ?? 0;
        final alarmName = (data['alarmName'] as String?) ?? 'No error';

        _telemetry = MachineTelemetry(
          processState: processState,
          temperature: temp,
          spinSpeed: speed,
          balanceTime: balTime,
          error: alarmCode != 0 ? alarmName : 'No error',
          errorCode: alarmCode,
          childLock: childLockOn,
          doorLock: !doorOpen,
        );

        // Check for new alerts
        if (alarmCode != 0 && alarmCode != _lastErrorCode) {
          _raiseAlert(alarmName, alarmCode);
        }
        _lastErrorCode = alarmCode;

        // Speak state-change cues
        _speakStateChange(processState);
        _lastProcessState = processState;
        break;

      case 'controlAck':
        _addLog('Control ACK received');
        // Request fresh status after control command
        Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
        break;

      case 'programAck':
        final progId = data['programId'];
        _addLog('Program ACK: loaded program ${progId ?? "unknown"}');
        Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
        break;

      case 'raw':
        _addLog('Raw: ${event['hex'] ?? ''}');
        break;

      case 'unknown':
        _addLog('Unknown frame: ${event['hex'] ?? ''}');
        break;
    }
    notifyListeners();
  }

  // ─── Alerts ───
  void _raiseAlert(String message, int errorCode) {
    final alert = MachineAlert(message: message, errorCode: errorCode);
    _alerts.insert(0, alert);
    if (_alerts.length > 50) _alerts.removeLast();
    _latestAlert = alert;
    _addLog('ALERT: $message (code $errorCode)');
    // Play system beep
    _playAlertSound();
    // Speak the error
    _tts.speak('Error: $message');
  }

  void _speakStateChange(int newState) {
    if (newState == _lastProcessState) return;
    // Wash completed
    if (newState == 13 || newState == 23) {
      _tts.speak('Wash cycle completed');
    }
    // Paused
    else if (newState == 14 && _lastProcessState != 14) {
      _tts.speak('Wash paused');
    }
    // Started / Resumed
    else if (_lastProcessState == 14 &&
        newState != 14 &&
        newState >= 2 &&
        newState <= 12) {
      _tts.speak('Wash resumed');
    }
    // First start (from standby/init to a running state)
    else if (_lastProcessState <= 1 && newState >= 2 && newState <= 12) {
      _tts.speak('Wash cycle started');
    }
  }

  Future<void> _playAlertSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
      // Double beep for urgency
      await Future.delayed(const Duration(milliseconds: 300));
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  // ─── Polling ───
  void _startPolling() {
    _pollTimer?.cancel();
    // Immediate first poll
    _pollOnce();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _pollOnce();
    });
  }

  void _pollOnce() {
    if (_connectionState == BtConnectionState.connected) {
      // Use READ_2 (opcode 05) for live telemetry — READ_1 only gives program details
      WashingMachineBridge.readStatus2();
    }
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  // ─── User Actions ───

  Future<void> loadPairedDevices() async {
    final devices = await WashingMachineBridge.getPairedDevices();
    _pairedDevices.clear();
    for (final d in devices) {
      _pairedDevices.add(
        BtDevice(
          name: d['name'] ?? 'Unknown',
          address: d['address'] ?? '',
          paired: true,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    _discoveredDevices.clear();
    _isScanning = true;
    notifyListeners();
    await WashingMachineBridge.startScan();
    // Auto-stop after 12 seconds
    Future.delayed(const Duration(seconds: 12), () {
      if (_isScanning) stopScan();
    });
  }

  Future<void> stopScan() async {
    _isScanning = false;
    notifyListeners();
    await WashingMachineBridge.stopScan();
  }

  Future<void> connectToDevice(BtDevice device) async {
    _connectedDeviceName = device.name;
    _connectionState = BtConnectionState.connecting;
    notifyListeners();
    await WashingMachineBridge.connectToDevice(device.address);
  }

  Future<void> disconnect() async {
    await WashingMachineBridge.disconnect();
  }

  Future<void> authenticate({String password = '1234'}) async {
    _addLog('Sending auth with password');
    await WashingMachineBridge.authenticate(password: password);
  }

  void selectProgram(int programId) {
    _selectedProgramId = programId;
    final p = selectedProgram;
    _temperature = p.defaultTemp;
    _spinSpeed = p.defaultSpin;
    _preWash = false;
    _rinseHold = false;
    _soak = false;
    _extraRinse = 0;
    _timeSaver = false;
    _delayStart = 0;
    notifyListeners();
  }

  void setTemperature(int temp) {
    _temperature = temp;
    notifyListeners();
  }

  void setSpinSpeed(int speed) {
    _spinSpeed = speed;
    notifyListeners();
  }

  void setPreWash(bool v) {
    _preWash = v;
    notifyListeners();
  }

  void setRinseHold(bool v) {
    _rinseHold = v;
    notifyListeners();
  }

  void setSoak(bool v) {
    _soak = v;
    notifyListeners();
  }

  void setExtraRinse(int v) {
    _extraRinse = v;
    notifyListeners();
  }

  void setTimeSaver(bool v) {
    _timeSaver = v;
    notifyListeners();
  }

  void setDelayStart(int v) {
    _delayStart = v;
    notifyListeners();
  }

  Future<void> loadAndStartProgram() async {
    await WashingMachineBridge.loadProgram(
      programId: _selectedProgramId,
      temperature: _temperature,
      spinSpeed: _spinSpeed,
      preWash: _preWash ? 1 : 0,
      rinseHold: _rinseHold ? 1 : 0,
      soak: _soak ? 1 : 0,
      extraRinse: _extraRinse,
      timeSaver: _timeSaver ? 1 : 0,
      delayStart: _delayStart,
      programCategory: selectedProgram.programCategory,
    );
    _addLog('Loaded program: ${selectedProgram.name}');
  }

  Future<void> startWash() async {
    await WashingMachineBridge.startWash();
    _addLog('Start wash');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> pauseWash() async {
    await WashingMachineBridge.pauseWash();
    _addLog('Pause wash');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> cancelWash() async {
    await WashingMachineBridge.cancelWash();
    _addLog('Cancel wash');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> newProgram() async {
    await WashingMachineBridge.newProgram();
    _addLog('New program');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> childLockOn() async {
    await WashingMachineBridge.childLockOn();
    _addLog('Child lock ON');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> childLockOff() async {
    await WashingMachineBridge.childLockOff();
    _addLog('Child lock OFF');
    Future.delayed(const Duration(milliseconds: 500), () => _pollOnce());
  }

  Future<void> readAllStatus() async {
    // READ_2 gives live telemetry (opcode 0x85 response)
    await WashingMachineBridge.readStatus2();
    await Future.delayed(const Duration(milliseconds: 300));
    // READ_1 gives program details (opcode 0x84 response)
    await WashingMachineBridge.readStatus1();
  }

  void _addLog(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    _log.insert(0, '[$ts] $msg');
    if (_log.length > 100) _log.removeLast();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connectionSub?.cancel();
    _dataSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }
}
