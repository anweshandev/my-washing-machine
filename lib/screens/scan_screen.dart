import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/washing_machine_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WashingMachineProvider>().loadPairedDevices();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WashingMachineProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Washer'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().isDark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle theme',
            onPressed: () => context.read<ThemeProvider>().toggle(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Animated find-my SVG when scanning
          if (provider.isScanning)
            Center(
              child: FadeTransition(
                opacity: _pulseCtrl,
                child: SvgPicture.asset(
                  'assets/images/find-my.svg',
                  width: 120,
                  height: 120,
                  colorFilter: ColorFilter.mode(
                    cs.primary.withValues(alpha: 0.6),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          if (provider.isScanning) const SizedBox(height: 8),

          // Connection status banner
          if (provider.connectionState == BtConnectionState.connecting)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Connecting...',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),

          // Paired devices section
          _sectionHeader(
            context,
            'Paired Devices',
            trailing: IconButton(
              icon: Icon(Icons.refresh, size: 20, color: cs.primary),
              onPressed: () => provider.loadPairedDevices(),
            ),
          ),
          if (provider.pairedDevices.isEmpty)
            _emptyCard(context, 'No paired Bluetooth devices found')
          else
            ...provider.pairedDevices.map(
              (d) => _deviceTile(context, d, provider),
            ),

          const SizedBox(height: 24),

          // Discovered devices section
          _sectionHeader(
            context,
            'Discovered Devices',
            trailing: provider.isScanning
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.search, size: 20, color: cs.primary),
                    onPressed: () => provider.startScan(),
                  ),
          ),
          if (provider.discoveredDevices.isEmpty)
            _emptyCard(
              context,
              provider.isScanning
                  ? 'Scanning for devices...'
                  : 'Tap search to discover nearby devices',
            )
          else
            ...provider.discoveredDevices.map(
              (d) => _deviceTile(context, d, provider),
            ),

          const SizedBox(height: 24),

          // Scan button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: provider.isScanning
                  ? null
                  : () => provider.startScan(),
              icon: const Icon(Icons.bluetooth_searching),
              label: Text(provider.isScanning ? 'Scanning...' : 'Start Scan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }

  Widget _emptyCard(BuildContext context, String msg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            msg,
            style: TextStyle(color: AppTheme.subtextColor(context)),
          ),
        ),
      ),
    );
  }

  Widget _deviceTile(
    BuildContext context,
    BtDevice device,
    WashingMachineProvider provider,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.bluetooth, color: cs.primary),
        ),
        title: Text(
          device.name,
          style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        subtitle: Text(
          device.address,
          style: TextStyle(fontSize: 12, color: AppTheme.subtextColor(context)),
        ),
        trailing:
            provider.connectionState == BtConnectionState.connecting &&
                provider.connectedDeviceName == device.name
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : Icon(
                Icons.chevron_right,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
        onTap: () async {
          await provider.connectToDevice(device);
          _waitForConnection(provider);
        },
      ),
    );
  }

  void _waitForConnection(WashingMachineProvider provider) {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (provider.connectionState == BtConnectionState.connected) {
        timer.cancel();
        provider.authenticate();
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else if (provider.connectionState == BtConnectionState.disconnected) {
        timer.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Try again.')),
        );
      }
    });
  }
}
