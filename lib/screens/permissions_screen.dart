import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/washing_machine_bridge.dart';
import '../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  bool _initializing = true;
  final Map<String, bool> _permissions = {
    'bluetooth': false,
    'location': false,
  };
  bool _bluetoothServiceOn = false;
  bool _showBtCard = true;
  bool _showLocCard = true;
  int? _sdkInt;
  Timer? _btServiceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    _btServiceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checking) {
      _checkPermissions();
      _checkBluetoothService();
    }
  }

  Future<int> _getSdkInt() async {
    if (_sdkInt != null) return _sdkInt!;
    final info = await DeviceInfoPlugin().androidInfo;
    _sdkInt = info.version.sdkInt;
    return _sdkInt!;
  }

  Future<void> _init() async {
    await _resolveVisibility();
    if (!mounted) return;
    await _checkPermissions();
    if (!mounted) return;
    await _checkBluetoothService();
    if (mounted) setState(() => _initializing = false);
    // Poll BT service status periodically (adapter state can change any time)
    _btServiceTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _checkBluetoothService(),
    );
  }

  Future<void> _resolveVisibility() async {
    if (!Platform.isAndroid) {
      setState(() {
        _showBtCard = true;
        _showLocCard = true;
      });
      return;
    }
    final sdk = await _getSdkInt();
    setState(() {
      if (sdk >= 31) {
        _showBtCard = true;
        _showLocCard = false;
      } else if (sdk >= 23) {
        _showBtCard = false;
        _showLocCard = true;
      } else {
        _showBtCard = false;
        _showLocCard = false;
      }
    });
  }

  Future<void> _checkPermissions() async {
    final locStatus = await Permission.location.status;
    final locWhenInUse = await Permission.locationWhenInUse.status;
    bool locGranted = locStatus.isGranted || locWhenInUse.isGranted;
    bool btGranted;

    if (Platform.isAndroid) {
      final sdk = await _getSdkInt();
      if (sdk >= 31) {
        final scan = await Permission.bluetoothScan.status;
        final connect = await Permission.bluetoothConnect.status;
        btGranted = scan.isGranted && connect.isGranted;
      } else {
        btGranted = locGranted;
      }
    } else {
      final bt = await Permission.bluetooth.status;
      btGranted = bt.isGranted;
    }

    if (!mounted) return;
    setState(() {
      _permissions['bluetooth'] = btGranted;
      _permissions['location'] = locGranted;
    });

    _checkReady();
  }

  Future<void> _checkBluetoothService() async {
    try {
      final enabled = await WashingMachineBridge.isBluetoothEnabled();
      if (!mounted) return;
      if (_bluetoothServiceOn != enabled) {
        setState(() => _bluetoothServiceOn = enabled);
        _checkReady();
      }
    } catch (_) {
      // Bridge not available yet
    }
  }

  bool _allGranted() {
    bool ok = true;
    if (_showBtCard) ok = ok && (_permissions['bluetooth'] ?? false);
    if (_showLocCard) ok = ok && (_permissions['location'] ?? false);
    return ok;
  }

  bool _canContinue() {
    return _allGranted() && _bluetoothServiceOn;
  }

  void _checkReady() {
    if (!mounted || _initializing) return;
    if (_canContinue()) {
      Navigator.of(context).pushReplacementNamed('/scan');
    }
  }

  Future<void> _enableBluetooth() async {
    // Can't programmatically enable Bluetooth without activity; open settings
    await openAppSettings();
    await Future.delayed(const Duration(seconds: 1));
    await _checkBluetoothService();
  }

  Future<void> _requestPermission(String type) async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      if (type == 'bluetooth') {
        if (Platform.isAndroid) {
          final sdk = await _getSdkInt();
          if (sdk >= 31) {
            final res = await [
              Permission.bluetoothScan,
              Permission.bluetoothConnect,
            ].request();
            final granted =
                res[Permission.bluetoothScan]!.isGranted &&
                res[Permission.bluetoothConnect]!.isGranted;
            setState(() => _permissions['bluetooth'] = granted);
            if (!granted) await openAppSettings();
          } else {
            final res = await [
              Permission.location,
              Permission.locationWhenInUse,
            ].request();
            final granted = res.values.any((s) => s.isGranted);
            setState(() {
              _permissions['bluetooth'] = granted;
              _permissions['location'] = granted;
            });
            if (!granted) await openAppSettings();
          }
        } else {
          final status = await Permission.bluetooth.request();
          setState(() => _permissions['bluetooth'] = status.isGranted);
          if (!status.isGranted && status.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      } else if (type == 'location') {
        if (Platform.isAndroid) {
          final status = await Permission.location.request();
          setState(() => _permissions['location'] = status.isGranted);
          if (!status.isGranted && status.isPermanentlyDenied) {
            await openAppSettings();
          }
        } else {
          final status = await Permission.locationWhenInUse.request();
          setState(() => _permissions['location'] = status.isGranted);
          if (!status.isGranted && status.isPermanentlyDenied) {
            await openAppSettings();
          }
        }
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
    if (mounted) {
      await _checkBluetoothService();
      _checkReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Show loading screen during initial check
    if (_initializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logos/ic_launcher-playstore.png',
                width: 80,
                height: 80,
              ),
              const SizedBox(height: 24),
              CircularProgressIndicator(color: cs.primary),
              const SizedBox(height: 16),
              Text(
                'Checking permissions...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.subtextColor(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Center(
                child: Image.asset(
                  'assets/logos/ic_launcher-playstore.png',
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Permissions Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We need Bluetooth permissions to connect and communicate with your IFB washing machine.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.subtextColor(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Permission cards
              if (_showBtCard)
                _buildPermissionCard(
                  context: context,
                  icon: Icons.bluetooth,
                  title: 'Nearby Devices',
                  description:
                      'Required to discover and connect to your washing machine via Bluetooth.',
                  isGranted: _permissions['bluetooth'] ?? false,
                  onTap: () => _requestPermission('bluetooth'),
                ),
              if (_showBtCard && _showLocCard) const SizedBox(height: 20),
              if (_showLocCard)
                _buildPermissionCard(
                  context: context,
                  icon: Icons.location_on,
                  title: 'Location Access',
                  description:
                      'Used to detect nearby Bluetooth devices for seamless connection.',
                  isGranted: _permissions['location'] ?? false,
                  onTap: () => _requestPermission('location'),
                ),

              // Services section (Android only)
              if (Platform.isAndroid) ...[
                const SizedBox(height: 32),
                Text(
                  'Services Required',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                _buildServiceCard(
                  context: context,
                  icon: Icons.bluetooth_searching,
                  title: 'Bluetooth Service',
                  description:
                      'Bluetooth must be enabled to scan and connect to your washing machine.',
                  isEnabled: _bluetoothServiceOn,
                  onTap: _enableBluetooth,
                ),
              ],

              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.secondary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        Platform.isAndroid
                            ? 'All permissions must be granted and Bluetooth must be enabled for the app to function properly.'
                            : 'All permissions must be granted for the app to function properly.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (_canContinue())
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checking
                        ? null
                        : () => Navigator.of(
                            context,
                          ).pushReplacementNamed('/scan'),
                    child: _checking
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Continue'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final granted = isGranted;
    final statusColor = granted ? cs.primary : cs.error;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: granted ? cs.primary.withValues(alpha: 0.4) : cs.outline,
          width: granted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: granted ? null : onTap,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: cs.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  granted
                                      ? Icons.check_circle
                                      : Icons.warning_amber_rounded,
                                  color: statusColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  granted ? 'Granted' : 'Not Given',
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          color: AppTheme.subtextColor(context),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                      if (!granted) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.lock_open, size: 18),
                            label: const Text('Grant Permission'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final statusColor = isEnabled ? cs.primary : cs.tertiary;
    final warningColor = cs.tertiary;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: isEnabled
              ? cs.primary.withValues(alpha: 0.3)
              : warningColor.withValues(alpha: 0.3),
          width: isEnabled ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: cs.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEnabled
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              color: statusColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isEnabled ? 'ON' : 'OFF',
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppTheme.subtextColor(context),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  if (!isEnabled) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('Enable Service'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
