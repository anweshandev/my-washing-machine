import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/washing_machine_bridge.dart';
import '../models/washing_data.dart';

/// Represents a discovered or paired Bluetooth device.
class BtDevice {
  final String name;
  final String address;
  BtDevice({required this.name, required this.address});
}

/// Live telemetry from the washing machine.
class MachineTelemetry {
  final int processState;
  final int temperature;
  final int spinSpeed;
  final int remainingMinutes;
  final int remainingSeconds;
  final String error;
  final bool childLock;
  final bool doorLock;

  MachineTelemetry({
    this.processState = 0,
    this.temperature = 0,
    this.spinSpeed = 0,
    this.remainingMinutes = 0,
    this.remainingSeconds = 0,
    this.error = 'No error',
    this.childLock = false,
    this.doorLock = false,
  });

  String get processName => WashingData.getProcessName(processState);
  String get remainingTime =>
      '${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';

  bool get isRunning =>
      processState >= 1 && processState <= 7 ||
      processState >= 13 && processState <= 20;
  bool get isCompleted => processState == 8 || processState == 21;
  bool get isPaused => processState == 9 || processState == 22;
  bool get hasError => error != 'No error';
}

enum BtConnectionState { disconnected, connecting, connected }

/// Main state manager for the washing machine app.
class WashingMachineProvider extends ChangeNotifier {
  // ─── Connection State ───
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  BtConnectionState get connectionState => _connectionState;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _connectedDeviceName;
  String? get connectedDeviceName => _connectedDeviceName;

  // ─── Scan State ───
  final List<BtDevice> _pairedDevices = [];
  List<BtDevice> get pairedDevices => List.unmodifiable(_pairedDevices);

  final List<BtDevice> _discoveredDevices = [];
  List<BtDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // ─── Telemetry ───
  MachineTelemetry _telemetry = MachineTelemetry();
  MachineTelemetry get telemetry => _telemetry;

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
    final name = event['name'] as String? ?? 'Unknown';
    final address = event['address'] as String? ?? '';
    if (address.isEmpty) return;

    final exists = _discoveredDevices.any((d) => d.address == address);
    if (!exists) {
      _discoveredDevices.add(BtDevice(name: name, address: address));
      notifyListeners();
    }
  }

  // ─── Connection Events ───
  void _onConnectionEvent(Map<String, dynamic> event) {
    final state = event['state'] as String? ?? '';
    _addLog('Connection: $state');
    switch (state) {
      case 'connecting':
        _connectionState = BtConnectionState.connecting;
        break;
      case 'connected':
        _connectionState = BtConnectionState.connected;
        break;
      case 'disconnected':
      case 'failed':
        _connectionState = BtConnectionState.disconnected;
        _isAuthenticated = false;
        _connectedDeviceName = null;
        _stopPolling();
        break;
    }
    notifyListeners();
  }

  // ─── Data Events (telemetry & auth feedback) ───
  void _onDataEvent(Map<String, dynamic> event) {
    final type = event['type'] as String? ?? '';
    switch (type) {
      case 'auth':
        _isAuthenticated = event['success'] == true;
        _addLog(
          'Auth: ${_isAuthenticated ? 'success' : 'failed – ${event['message']}'}',
        );
        if (_isAuthenticated) _startPolling();
        break;
      case 'control_ack':
        _addLog(
          'Control ACK: ${event['accepted'] == true ? 'accepted' : 'rejected'}',
        );
        break;
      case 'program_ack':
        _addLog(
          'Program ACK: ${event['accepted'] == true ? 'accepted' : 'rejected'}',
        );
        break;
      case 'telemetry':
        _telemetry = MachineTelemetry(
          processState: (event['processState'] as int?) ?? 0,
          temperature: (event['temperature'] as int?) ?? 0,
          spinSpeed: (event['spinSpeed'] as int?) ?? 0,
          remainingMinutes: (event['remainingMinutes'] as int?) ?? 0,
          remainingSeconds: (event['remainingSeconds'] as int?) ?? 0,
          error: (event['error'] as String?) ?? 'No error',
          childLock: event['childLock'] == true,
          doorLock: event['doorLock'] == true,
        );
        break;
      case 'raw':
        _addLog('Raw: ${event['hex'] ?? ''}');
        break;
    }
    notifyListeners();
  }

  // ─── Polling ───
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_connectionState == BtConnectionState.connected && _isAuthenticated) {
        WashingMachineBridge.readStatus1();
      }
    });
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
        BtDevice(name: d['name'] ?? 'Unknown', address: d['address'] ?? ''),
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
  }

  Future<void> pauseWash() async {
    await WashingMachineBridge.pauseWash();
    _addLog('Pause wash');
  }

  Future<void> cancelWash() async {
    await WashingMachineBridge.cancelWash();
    _addLog('Cancel wash');
  }

  Future<void> childLockOn() async {
    await WashingMachineBridge.childLockOn();
    _addLog('Child lock ON');
  }

  Future<void> childLockOff() async {
    await WashingMachineBridge.childLockOff();
    _addLog('Child lock OFF');
  }

  Future<void> readAllStatus() async {
    await WashingMachineBridge.readStatus1();
    await Future.delayed(const Duration(milliseconds: 300));
    await WashingMachineBridge.readStatus2();
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
