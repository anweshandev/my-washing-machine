import 'dart:async';
import 'package:flutter/services.dart';

class WashingMachineBridge {
  static const _methods = MethodChannel('dev.anweshan.apps.washing/methods');
  static const _scanChannel = EventChannel('dev.anweshan.apps.washing/scan');
  static const _connectionChannel = EventChannel(
    'dev.anweshan.apps.washing/connection',
  );
  static const _dataChannel = EventChannel('dev.anweshan.apps.washing/data');

  static Stream<Map<String, dynamic>>? _scanStream;
  static Stream<Map<String, dynamic>>? _connectionStream;
  static Stream<Map<String, dynamic>>? _dataStream;

  // ─── Scan Events Stream ───
  static Stream<Map<String, dynamic>> get scanStream {
    _scanStream ??= _scanChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
    return _scanStream!;
  }

  // ─── Connection Events Stream ───
  static Stream<Map<String, dynamic>> get connectionStream {
    _connectionStream ??= _connectionChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
    return _connectionStream!;
  }

  // ─── Data Events Stream ───
  static Stream<Map<String, dynamic>> get dataStream {
    _dataStream ??= _dataChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
    return _dataStream!;
  }

  // ─── Method Calls ───

  static Future<bool> isBluetoothAvailable() async {
    return await _methods.invokeMethod<bool>('isBluetoothAvailable') ?? false;
  }

  static Future<bool> isBluetoothEnabled() async {
    return await _methods.invokeMethod<bool>('isBluetoothEnabled') ?? false;
  }

  static Future<int> getConnectionState() async {
    return await _methods.invokeMethod<int>('getConnectionState') ?? 0;
  }

  static Future<List<Map<String, String>>> getPairedDevices() async {
    final result = await _methods.invokeMethod('getPairedDevices');
    if (result == null) return [];
    return (result as List).map((d) {
      final map = Map<String, dynamic>.from(d as Map);
      return map.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    }).toList();
  }

  static Future<void> startScan() async {
    await _methods.invokeMethod('startScan');
  }

  static Future<void> stopScan() async {
    await _methods.invokeMethod('stopScan');
  }

  static Future<void> connectToDevice(String address) async {
    await _methods.invokeMethod('connectToDevice', {'address': address});
  }

  static Future<void> disconnect() async {
    await _methods.invokeMethod('disconnect');
  }

  static Future<void> authenticate({String password = '1234'}) async {
    await _methods.invokeMethod('authenticate', {'password': password});
  }

  static Future<void> startWash() async {
    await _methods.invokeMethod('startWash');
  }

  static Future<void> pauseWash() async {
    await _methods.invokeMethod('pauseWash');
  }

  static Future<void> cancelWash() async {
    await _methods.invokeMethod('cancelWash');
  }

  static Future<void> newProgram() async {
    await _methods.invokeMethod('newProgram');
  }

  static Future<void> childLockOn() async {
    await _methods.invokeMethod('childLockOn');
  }

  static Future<void> childLockOff() async {
    await _methods.invokeMethod('childLockOff');
  }

  static Future<void> readStatus1() async {
    await _methods.invokeMethod('readStatus1');
  }

  static Future<void> readStatus2() async {
    await _methods.invokeMethod('readStatus2');
  }

  static Future<void> readStatus3() async {
    await _methods.invokeMethod('readStatus3');
  }

  static Future<void> readStatus4() async {
    await _methods.invokeMethod('readStatus4');
  }

  static Future<void> loadProgram({
    required int programId,
    int temperature = 0,
    int spinSpeed = 0,
    int preWash = 0,
    int rinseHold = 0,
    int soak = 0,
    int extraRinse = 0,
    int timeSaver = 0,
    int delayStart = 0,
    int programCategory = 1,
  }) async {
    await _methods.invokeMethod('loadProgram', {
      'programId': programId,
      'temperature': temperature,
      'spinSpeed': spinSpeed,
      'preWash': preWash,
      'rinseHold': rinseHold,
      'soak': soak,
      'extraRinse': extraRinse,
      'timeSaver': timeSaver,
      'delayStart': delayStart,
      'programCategory': programCategory,
    });
  }

  static Future<bool> sendCommand(String hexCommand) async {
    return await _methods.invokeMethod<bool>('sendCommand', {
          'command': hexCommand,
        }) ??
        false;
  }

  // ─── Foreground Service ───

  static Future<void> startForegroundService({
    String title = 'LaundryIQ',
    String body = 'Wash cycle in progress',
  }) async {
    await _methods.invokeMethod('startForegroundService', {
      'title': title,
      'body': body,
    });
  }

  static Future<void> updateForegroundService({
    String title = 'LaundryIQ',
    String body = 'Wash cycle in progress',
  }) async {
    await _methods.invokeMethod('updateForegroundService', {
      'title': title,
      'body': body,
    });
  }

  static Future<void> stopForegroundService() async {
    await _methods.invokeMethod('stopForegroundService');
  }
}
