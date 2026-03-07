package io.flutter.plugins;

import android.annotation.SuppressLint;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class WashingMachineBridge implements FlutterPlugin, MethodChannel.MethodCallHandler {

    private static final String TAG = "WashingMachineBridge";
    private static final String METHOD_CHANNEL = "dev.anweshan.apps.washing/methods";
    private static final String EVENT_CHANNEL_SCAN = "dev.anweshan.apps.washing/scan";
    private static final String EVENT_CHANNEL_CONNECTION = "dev.anweshan.apps.washing/connection";
    private static final String EVENT_CHANNEL_DATA = "dev.anweshan.apps.washing/data";

    private static final UUID SPP_UUID = UUID.fromString("00001101-0000-1000-8000-00805f9b34fb");

    // Connection states
    private static final int STATE_NONE = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED = 2;

    private MethodChannel methodChannel;
    private EventChannel scanEventChannel;
    private EventChannel connectionEventChannel;
    private EventChannel dataEventChannel;

    private EventChannel.EventSink scanSink;
    private EventChannel.EventSink connectionSink;
    private EventChannel.EventSink dataSink;

    private Context context;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothSocket bluetoothSocket;
    private InputStream inputStream;
    private OutputStream outputStream;
    private ConnectThread connectThread;
    private ReadThread readThread;

    private int connectionState = STATE_NONE;
    private String connectedDeviceName = "";
    private String connectedDeviceAddress = "";
    private boolean isScanning = false;

    private final Handler mainHandler = new Handler(Looper.getMainLooper());
    private final ArrayList<Map<String, String>> discoveredDevices = new ArrayList<>();

    private BroadcastReceiver discoveryReceiver;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        context = binding.getApplicationContext();
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();

        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(this);

        scanEventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_SCAN);
        scanEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                scanSink = events;
            }
            @Override
            public void onCancel(Object arguments) {
                scanSink = null;
            }
        });

        connectionEventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_CONNECTION);
        connectionEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                connectionSink = events;
            }
            @Override
            public void onCancel(Object arguments) {
                connectionSink = null;
            }
        });

        dataEventChannel = new EventChannel(binding.getBinaryMessenger(), EVENT_CHANNEL_DATA);
        dataEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override
            public void onListen(Object arguments, EventChannel.EventSink events) {
                dataSink = events;
            }
            @Override
            public void onCancel(Object arguments) {
                dataSink = null;
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        scanEventChannel.setStreamHandler(null);
        connectionEventChannel.setStreamHandler(null);
        dataEventChannel.setStreamHandler(null);
        disconnect();
        unregisterReceiver();
    }

    @SuppressLint("MissingPermission")
    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "isBluetoothAvailable":
                result.success(bluetoothAdapter != null);
                break;

            case "isBluetoothEnabled":
                result.success(bluetoothAdapter != null && bluetoothAdapter.isEnabled());
                break;

            case "getConnectionState":
                result.success(connectionState);
                break;

            case "getPairedDevices":
                result.success(getPairedDevices());
                break;

            case "startScan":
                startDiscovery();
                result.success(true);
                break;

            case "stopScan":
                stopDiscovery();
                result.success(true);
                break;

            case "connectToDevice": {
                String address = call.argument("address");
                if (address == null || address.isEmpty()) {
                    result.error("INVALID_ADDRESS", "Device address is required", null);
                    return;
                }
                connectToDevice(address);
                result.success(true);
                break;
            }

            case "disconnect":
                disconnect();
                result.success(true);
                break;

            case "authenticate": {
                String password = call.argument("password");
                if (password == null) password = "1234";
                authenticate(password);
                result.success(true);
                break;
            }

            case "sendCommand": {
                String hexCommand = call.argument("command");
                if (hexCommand == null || hexCommand.isEmpty()) {
                    result.error("INVALID_COMMAND", "Hex command is required", null);
                    return;
                }
                boolean sent = sendHexCommand(hexCommand);
                result.success(sent);
                break;
            }

            case "loadProgram": {
                int programId = call.argument("programId") != null ? (int) call.argument("programId") : 0;
                int temperature = call.argument("temperature") != null ? (int) call.argument("temperature") : 0;
                int spinSpeed = call.argument("spinSpeed") != null ? (int) call.argument("spinSpeed") : 0;
                int preWash = call.argument("preWash") != null ? (int) call.argument("preWash") : 0;
                int rinseHold = call.argument("rinseHold") != null ? (int) call.argument("rinseHold") : 0;
                int soak = call.argument("soak") != null ? (int) call.argument("soak") : 0;
                int extraRinse = call.argument("extraRinse") != null ? (int) call.argument("extraRinse") : 0;
                int timeSaver = call.argument("timeSaver") != null ? (int) call.argument("timeSaver") : 0;
                int delayStart = call.argument("delayStart") != null ? (int) call.argument("delayStart") : 0;
                int programCategory = call.argument("programCategory") != null ? (int) call.argument("programCategory") : 1;

                String cmd = buildProgramCommand(programId, temperature, spinSpeed, preWash, rinseHold, soak, extraRinse, timeSaver, delayStart, programCategory);
                boolean sent = sendHexCommand(cmd);
                result.success(sent);
                break;
            }

            case "startWash":
                sendHexCommand("6308020100000000");
                result.success(true);
                break;

            case "pauseWash":
                sendHexCommand("6308020000000000");
                result.success(true);
                break;

            case "cancelWash":
                sendHexCommand("6308020300000000");
                result.success(true);
                break;

            case "newProgram":
                sendHexCommand("6308020200000000");
                result.success(true);
                break;

            case "childLockOn":
                sendHexCommand("630A0301020100000000");
                result.success(true);
                break;

            case "childLockOff":
                sendHexCommand("630A0301020000000000");
                result.success(true);
                break;

            case "readStatus1":
                sendHexCommand("6308040100000000");
                result.success(true);
                break;

            case "readStatus2":
                sendHexCommand("6308050100000000");
                result.success(true);
                break;

            case "readStatus3":
                sendHexCommand("6308050200000000");
                result.success(true);
                break;

            case "readStatus4":
                sendHexCommand("6308050300000000");
                result.success(true);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    // ─── Bluetooth Discovery ───

    @SuppressLint("MissingPermission")
    private ArrayList<Map<String, String>> getPairedDevices() {
        ArrayList<Map<String, String>> devices = new ArrayList<>();
        if (bluetoothAdapter == null) return devices;
        Set<BluetoothDevice> paired = bluetoothAdapter.getBondedDevices();
        for (BluetoothDevice device : paired) {
            Map<String, String> d = new HashMap<>();
            d.put("name", device.getName() != null ? device.getName() : "Unknown");
            d.put("address", device.getAddress());
            d.put("paired", "true");
            devices.add(d);
        }
        return devices;
    }

    @SuppressLint("MissingPermission")
    private void startDiscovery() {
        if (bluetoothAdapter == null) return;

        discoveredDevices.clear();
        isScanning = true;

        unregisterReceiver();

        discoveryReceiver = new BroadcastReceiver() {
            @SuppressLint("MissingPermission")
            @Override
            public void onReceive(Context ctx, Intent intent) {
                String action = intent.getAction();
                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    if (device != null) {
                        String name = device.getName() != null ? device.getName() : "Unknown";
                        String address = device.getAddress();

                        boolean exists = false;
                        for (Map<String, String> d : discoveredDevices) {
                            if (address.equals(d.get("address"))) {
                                exists = true;
                                break;
                            }
                        }

                        if (!exists) {
                            Map<String, String> d = new HashMap<>();
                            d.put("name", name);
                            d.put("address", address);
                            d.put("paired", device.getBondState() == BluetoothDevice.BOND_BONDED ? "true" : "false");
                            discoveredDevices.add(d);

                            emitScanResult();
                        }
                    }
                } else if (BluetoothAdapter.ACTION_DISCOVERY_FINISHED.equals(action)) {
                    isScanning = false;
                    emitScanResult();
                }
            }
        };

        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothDevice.ACTION_FOUND);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED);
        filter.addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED);
        context.registerReceiver(discoveryReceiver, filter);

        bluetoothAdapter.cancelDiscovery();
        bluetoothAdapter.startDiscovery();
    }

    @SuppressLint("MissingPermission")
    private void stopDiscovery() {
        isScanning = false;
        if (bluetoothAdapter != null && bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }
        unregisterReceiver();
    }

    private void unregisterReceiver() {
        if (discoveryReceiver != null) {
            try {
                context.unregisterReceiver(discoveryReceiver);
            } catch (Exception ignored) {}
            discoveryReceiver = null;
        }
    }

    private void emitScanResult() {
        mainHandler.post(() -> {
            if (scanSink != null) {
                Map<String, Object> event = new HashMap<>();
                event.put("devices", new ArrayList<>(discoveredDevices));
                event.put("isScanning", isScanning);
                scanSink.success(event);
            }
        });
    }

    // ─── Bluetooth Connection ───

    @SuppressLint("MissingPermission")
    private void connectToDevice(String address) {
        if (bluetoothAdapter == null) return;

        // Cancel discovery before connecting
        if (bluetoothAdapter.isDiscovering()) {
            bluetoothAdapter.cancelDiscovery();
        }

        // Close existing connection
        disconnect();

        BluetoothDevice device = bluetoothAdapter.getRemoteDevice(address);
        connectionState = STATE_CONNECTING;
        emitConnectionState("connecting", address, device.getName());

        connectThread = new ConnectThread(device);
        connectThread.start();
    }

    private void disconnect() {
        connectionState = STATE_NONE;

        if (readThread != null) {
            readThread.cancel();
            readThread = null;
        }

        if (connectThread != null) {
            connectThread.cancel();
            connectThread = null;
        }

        if (inputStream != null) {
            try { inputStream.close(); } catch (IOException ignored) {}
            inputStream = null;
        }

        if (outputStream != null) {
            try { outputStream.close(); } catch (IOException ignored) {}
            outputStream = null;
        }

        if (bluetoothSocket != null) {
            try { bluetoothSocket.close(); } catch (IOException ignored) {}
            bluetoothSocket = null;
        }

        emitConnectionState("disconnected", connectedDeviceAddress, connectedDeviceName);
        connectedDeviceName = "";
        connectedDeviceAddress = "";
    }

    private void emitConnectionState(String state, String address, String name) {
        mainHandler.post(() -> {
            if (connectionSink != null) {
                Map<String, Object> event = new HashMap<>();
                event.put("state", state);
                event.put("address", address != null ? address : "");
                event.put("name", name != null ? name : "");
                connectionSink.success(event);
            }
        });
    }

    // ─── Authentication ───

    private void authenticate(String password) {
        String passwordHex = asciiToHex(password);
        String cmd = "630801" + "01" + passwordHex;
        sendHexCommand(cmd);
    }

    // ─── Send Commands ───

    private boolean sendHexCommand(String hexString) {
        if (outputStream == null || connectionState != STATE_CONNECTED) {
            Log.e(TAG, "Cannot send: not connected");
            return false;
        }

        try {
            // Calculate first checksum
            String cs1 = checkSum(hexString);
            String withCs1 = hexString + cs1;
            // Calculate second checksum
            String cs2 = checkSum(withCs1);
            String fullCommand = withCs1 + cs2;

            byte[] bytes = hexStringToByteArray(fullCommand);
            Log.d(TAG, "SEND: " + fullCommand);
            outputStream.write(bytes);
            outputStream.flush();
            return true;
        } catch (IOException e) {
            Log.e(TAG, "Write failed", e);
            disconnect();
            return false;
        }
    }

    // ─── Program Command Builder ───

    private String buildProgramCommand(int programId, int temperature, int spinSpeed,
                                        int preWash, int rinseHold, int soak,
                                        int extraRinse, int timeSaver,
                                        int delayStart, int programCategory) {
        String pgmCode = padHex(Integer.toHexString(programId).toUpperCase(), 2);
        String pgmCat = padHex(Integer.toHexString(programCategory).toUpperCase(), 2);

        // Spin speed as 16-bit
        String speedHex = padHex(Integer.toHexString(spinSpeed).toUpperCase(), 4);
        String speedHigh = speedHex.substring(0, 2);
        String speedLow = speedHex.substring(2, 4);

        // Temperature as 8-bit
        String temp = padHex(Integer.toHexString(temperature).toUpperCase(), 2);

        // Delay start as 16-bit
        String delayHex = padHex(Integer.toHexString(delayStart).toUpperCase(), 4);
        String delayHigh = delayHex.substring(0, 2);
        String delayLow = delayHex.substring(2, 4);

        // Soak as 8-bit
        String soakHex = padHex(Integer.toHexString(soak).toUpperCase(), 2);

        // Options byte: [0][timesaver][rinsehold][er3][er2][er1][0][prewash]
        String er1 = "0", er2 = "0", er3 = "0";
        if (extraRinse >= 1) er1 = "1";
        if (extraRinse >= 2) er2 = "1";
        if (extraRinse >= 3) er3 = "1";

        String prewashBit = preWash == 1 ? "1" : "0";
        String rinseholdBit = rinseHold == 1 ? "1" : "0";
        String timesaverBit = timeSaver == 1 ? "1" : "0";

        String optionsBinary = "00" + timesaverBit + rinseholdBit + er3 + er2 + er1 + prewashBit;
        String options = padHex(Integer.toHexString(Integer.parseInt(optionsBinary, 2)).toUpperCase(), 2);

        return "63120300" + pgmCode + "00" + speedHigh + speedLow + temp + options +
               delayHigh + delayLow + soakHex + pgmCat + "00000000";
    }

    // ─── Response Parser ───

    private void parseResponse(byte[] buffer, int length) {
        String hex = bytesToHex(buffer, length).toUpperCase();
        Log.d(TAG, "RECV: " + hex);

        // Validate frame
        String validFrame = getValidFrame(hex);
        if (validFrame.equals("0")) {
            Log.w(TAG, "Invalid frame: " + hex);
            // Still emit raw data for debugging
            emitData("raw", hex, new HashMap<>());
            return;
        }

        // Get opcode (byte index 2, hex index 4-5)
        if (validFrame.length() < 6) return;
        int opcode = Integer.parseInt(validFrame.substring(4, 6), 16);

        Map<String, Object> parsed = new HashMap<>();
        parsed.put("frame", validFrame);
        parsed.put("opcode", opcode);

        switch (opcode) {
            case 0x01: // AUTH response
                parseAuthResponse(validFrame, parsed);
                emitData("auth", validFrame, parsed);
                break;

            case 0x04: // STATUS (READ_1 response)
            case 0x05: // Extended status responses
                parseTelemetryResponse(validFrame, parsed);
                emitData("telemetry", validFrame, parsed);
                break;

            case 0x02: // START/PAUSE/CANCEL ACK
                parsed.put("ackType", "control");
                emitData("controlAck", validFrame, parsed);
                break;

            case 0x03: // Program load ACK
                parseProgramResponse(validFrame, parsed);
                emitData("programAck", validFrame, parsed);
                break;

            default:
                emitData("unknown", validFrame, parsed);
                break;
        }
    }

    private void parseAuthResponse(String hex, Map<String, Object> parsed) {
        // Auth response: look at byte after opcode
        if (hex.length() >= 8) {
            String authByte = hex.substring(6, 8);
            parsed.put("authenticated", authByte.equals("01") || authByte.equals("00"));
            parsed.put("authByte", authByte);
        }
    }

    private void parseTelemetryResponse(String hex, Map<String, Object> parsed) {
        try {
            if (hex.length() < 20) return;

            // Process state at byte 3 (hex index 6-7)
            int processState = Integer.parseInt(hex.substring(6, 8), 16);
            parsed.put("processState", processState);
            parsed.put("processName", getProcessName(processState));

            // Program ID at byte 4 (hex index 8-9)
            if (hex.length() >= 10) {
                int programId = Integer.parseInt(hex.substring(8, 10), 16);
                parsed.put("programId", programId);
            }

            // Balance time: bytes 5-6 (hex index 10-13) - minutes remaining
            if (hex.length() >= 14) {
                int balanceTime = Integer.parseInt(hex.substring(10, 14), 16);
                parsed.put("balanceTime", balanceTime);
            }

            // Temperature: byte 7 (hex index 14-15)
            if (hex.length() >= 16) {
                int temp = Integer.parseInt(hex.substring(14, 16), 16);
                parsed.put("temperature", temp);
            }

            // Spin speed: bytes 8-9 (hex index 16-19)
            if (hex.length() >= 20) {
                int speed = Integer.parseInt(hex.substring(16, 20), 16);
                parsed.put("spinSpeed", speed);
            }

            // Options byte: byte 10 (hex index 20-21)
            if (hex.length() >= 22) {
                String optionsHex = hex.substring(20, 22);
                parsed.put("optionsByte", optionsHex);
                parseOptions(optionsHex, parsed);
            }

            // Alarm bytes: look further in the frame
            if (hex.length() >= 58) {
                String alarmHex = hex.substring(52, 56);
                int alarmCode = parseAlarm(alarmHex);
                parsed.put("alarmCode", alarmCode);
                parsed.put("alarmName", getErrorName(alarmCode));
            }

            // Load flag: door position etc
            if (hex.length() >= 74) {
                String loadFlag = hex.substring(72, 74);
                parsed.put("loadFlag", loadFlag);
                parsed.put("isDoorOpen", isDoorOpen(loadFlag));
            }

            // Child lock status guess from process state
            parsed.put("childLockOn", processState == 23 || processState == 24);

        } catch (Exception e) {
            Log.e(TAG, "Parse telemetry error", e);
        }
    }

    private void parseProgramResponse(String hex, Map<String, Object> parsed) {
        try {
            if (hex.length() >= 10) {
                int programId = Integer.parseInt(hex.substring(8, 10), 16);
                parsed.put("programId", programId);
            }
            if (hex.length() >= 16) {
                int temp = Integer.parseInt(hex.substring(14, 16), 16);
                parsed.put("temperature", temp);
            }
            if (hex.length() >= 20) {
                int speed = Integer.parseInt(hex.substring(16, 20), 16);
                parsed.put("spinSpeed", speed);
            }
        } catch (Exception e) {
            Log.e(TAG, "Parse program response error", e);
        }
    }

    private void parseOptions(String optionsHex, Map<String, Object> parsed) {
        try {
            int optVal = Integer.parseInt(optionsHex, 16);
            String binary = String.format("%8s", Integer.toBinaryString(optVal)).replace(' ', '0');
            parsed.put("preWash", binary.charAt(7) == '1');
            parsed.put("rinseHold", binary.charAt(3) == '1');
            parsed.put("timeSaver", binary.charAt(2) == '1');

            // Extra rinse count
            int er = 0;
            if (binary.charAt(4) == '1') er = 3;
            else if (binary.charAt(5) == '1') er = 2;
            else if (binary.charAt(6) == '1') er = 1;
            parsed.put("extraRinse", er);
        } catch (Exception ignored) {}
    }

    private int parseAlarm(String alarmHex) {
        try {
            String al1 = alarmHex.substring(0, 2);
            String al2 = alarmHex.substring(2, 4);

            String al1Bin = String.format("%8s", Integer.toBinaryString(Integer.parseInt(al1, 16))).replace(' ', '0');
            String al2Bin = String.format("%8s", Integer.toBinaryString(Integer.parseInt(al2, 16))).replace(' ', '0');

            if (al1Bin.charAt(1) == '1') return 3;  // pressure switch
            if (al2Bin.charAt(1) == '1' && al1Bin.charAt(2) != '1') return 14; // high voltage
            if (al2Bin.charAt(2) == '1' && al1Bin.charAt(2) != '1') return 13; // low voltage
            if (al1Bin.charAt(0) == '1') return 7;  // door lock
            if (al1Bin.charAt(2) == '1') return 6;  // overheat
            if (al1Bin.charAt(3) == '1') return 2;  // overflow
            if (al2Bin.charAt(3) == '1') return 12; // drain pump
            if (al1Bin.charAt(4) == '1') return 4;  // motor
            if (al2Bin.charAt(7) == '1') return 8;  // no water
            if (al2Bin.charAt(6) == '1') return 9;  // low water pressure
            if (al1Bin.charAt(7) == '1') return 1;  // door unlocked
            if (al2Bin.charAt(0) == '1') return 15; // unbalance
            if (al1Bin.charAt(6) == '1') return 5;  // triac short
            if (al2Bin.charAt(4) == '1') return 11; // NTC
            if (al2Bin.charAt(5) == '1') return 10; // heater
        } catch (Exception ignored) {}
        return 0;
    }

    private boolean isDoorOpen(String loadFlag) {
        try {
            String bin = String.format("%8s", Integer.toBinaryString(Integer.parseInt(loadFlag, 16))).replace(' ', '0');
            return bin.charAt(7) != '1';
        } catch (Exception e) {
            return false;
        }
    }

    private void emitData(String type, String hex, Map<String, Object> parsed) {
        mainHandler.post(() -> {
            if (dataSink != null) {
                Map<String, Object> event = new HashMap<>();
                event.put("type", type);
                event.put("hex", hex);
                event.put("data", parsed);
                dataSink.success(event);
            }
        });
    }

    // ─── Frame Validation ───

    private String getValidFrame(String hexCode) {
        try {
            String h = hexCode.toUpperCase();
            if (h.startsWith("FF")) {
                h = h.substring(2);
            }
            if (!h.startsWith("63")) return "0";

            String hexLength = h.substring(2, 4);
            int len = Integer.parseInt(hexLength, 16) * 2;
            if (h.length() < len + 4) return "0";

            String frame = h.substring(0, len + 4);
            if (!validateChecksum(frame)) return "0";

            return frame;
        } catch (Exception e) {
            return "0";
        }
    }

    private boolean validateChecksum(String code) {
        try {
            String base = code.substring(0, code.length() - 4).toUpperCase();
            String cs1 = checkSum(base);
            String withCs1 = base + cs1;
            String cs2 = checkSum(withCs1);
            return code.equalsIgnoreCase(withCs1 + cs2);
        } catch (Exception e) {
            return false;
        }
    }

    // ─── Hex Utilities ───

    private String checkSum(String hexStr) {
        byte[] bytes = hexStringToByteArray(hexStr);
        byte sum = 0;
        for (byte b : bytes) {
            sum = (byte) (sum + b);
        }
        String result = Integer.toHexString(sum & 0xFF).toUpperCase();
        if (result.length() < 2) result = "0" + result;
        return result;
    }

    private byte[] hexStringToByteArray(String s) {
        int len = s.length();
        byte[] data = new byte[len / 2];
        for (int i = 0; i < len; i += 2) {
            data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                                   + Character.digit(s.charAt(i + 1), 16));
        }
        return data;
    }

    private String bytesToHex(byte[] bytes, int length) {
        StringBuilder sb = new StringBuilder(length * 2);
        for (int i = 0; i < length; i++) {
            sb.append(String.format("%02X", bytes[i] & 0xFF));
        }
        return sb.toString();
    }

    private String asciiToHex(String s) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < s.length(); i++) {
            sb.append(Integer.toHexString((int) s.charAt(i)));
        }
        return sb.toString();
    }

    private String padHex(String hex, int length) {
        while (hex.length() < length) {
            hex = "0" + hex;
        }
        return hex;
    }

    // ─── Name Lookups ───

    private String getProcessName(int id) {
        String[] names = {"Nothing", "StandBy", "Initializing", "Pre-Wash", "Main Wash",
                "Extra Rinse", "Extra Rinse", "Extra Rinse", "Rinse", "Rinse", "Rinse",
                "Final Spin", "Anticrease", "End", "Pause", "Soak", "Rinse Hold",
                "Heating", "Drain", "Intermediate Spin", "Delay Start", "Door Locking",
                "Door Unlocking", "End (Child Lock)", "Rinse Hold (Child Lock)"};
        if (id >= 0 && id < names.length) return names[id];
        return "Unknown (" + id + ")";
    }

    private String getErrorName(int id) {
        String[] names = {"No error", "Door locked", "Water overflow", "Pressostat",
                "Motor", "Motor triac", "Over heating", "Door open", "No water",
                "Low water pressure", "Heater", "NTC", "Drain pump", "Low voltage",
                "High voltage", "High unbalanced load"};
        if (id >= 0 && id < names.length) return names[id];
        return "Unknown error";
    }

    // ─── Connection Threads ───

    private class ConnectThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final BluetoothDevice mmDevice;

        @SuppressLint("MissingPermission")
        ConnectThread(BluetoothDevice device) {
            mmDevice = device;
            BluetoothSocket tmp = null;
            try {
                tmp = device.createInsecureRfcommSocketToServiceRecord(SPP_UUID);
            } catch (IOException e) {
                Log.e(TAG, "Socket create failed", e);
            }
            mmSocket = tmp;
        }

        @SuppressLint("MissingPermission")
        public void run() {
            setName("ConnectThread");
            if (bluetoothAdapter.isDiscovering()) {
                bluetoothAdapter.cancelDiscovery();
            }

            try {
                mmSocket.connect();
            } catch (IOException e) {
                Log.e(TAG, "Connection failed", e);
                try { mmSocket.close(); } catch (IOException ignored) {}
                connectionState = STATE_NONE;
                emitConnectionState("failed", mmDevice.getAddress(), mmDevice.getName());
                return;
            }

            synchronized (WashingMachineBridge.this) {
                connectThread = null;
            }

            // Connection successful
            bluetoothSocket = mmSocket;
            try {
                inputStream = mmSocket.getInputStream();
                outputStream = mmSocket.getOutputStream();
            } catch (IOException e) {
                Log.e(TAG, "Get streams failed", e);
                disconnect();
                return;
            }

            connectionState = STATE_CONNECTED;
            connectedDeviceName = mmDevice.getName() != null ? mmDevice.getName() : "Unknown";
            connectedDeviceAddress = mmDevice.getAddress();
            emitConnectionState("connected", connectedDeviceAddress, connectedDeviceName);

            // Start reading
            readThread = new ReadThread();
            readThread.start();
        }

        void cancel() {
            try { mmSocket.close(); } catch (IOException ignored) {}
        }
    }

    private class ReadThread extends Thread {
        private volatile boolean running = true;

        public void run() {
            setName("ReadThread");
            byte[] buffer = new byte[1024];
            while (running) {
                try {
                    int bytes = inputStream.read(buffer);
                    if (bytes > 0) {
                        byte[] data = new byte[bytes];
                        System.arraycopy(buffer, 0, data, 0, bytes);
                        parseResponse(data, bytes);
                    }
                } catch (IOException e) {
                    if (running) {
                        Log.e(TAG, "Read failed - connection lost", e);
                        connectionState = STATE_NONE;
                        emitConnectionState("disconnected", connectedDeviceAddress, connectedDeviceName);
                    }
                    break;
                }
            }
        }

        void cancel() {
            running = false;
            interrupt();
        }
    }
}
