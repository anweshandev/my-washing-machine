import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  bool _checking = false;
  final Map<String, bool> _permissions = {
    'bluetooth': false,
    'location': false,
  };
  bool _showBtCard = true;
  bool _showLocCard = true;
  int? _sdkInt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_checking) {
      _checkPermissions();
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

  bool _allGranted() {
    bool ok = true;
    if (_showBtCard) ok = ok && (_permissions['bluetooth'] ?? false);
    if (_showLocCard) ok = ok && (_permissions['location'] ?? false);
    return ok;
  }

  void _checkReady() {
    if (!mounted) return;
    if (_allGranted()) {
      Navigator.of(context).pushReplacementNamed('/scan');
    }
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
    if (mounted) _checkReady();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
                        'All permissions must be granted for the app to communicate with the washing machine.',
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
              if (_allGranted())
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/scan'),
                    child: const Text('Continue'),
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
}
