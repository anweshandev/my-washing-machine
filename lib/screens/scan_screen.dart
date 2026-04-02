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
  bool _waitingForAuth = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndAutoConnect();
    });
  }

  Future<void> _loadAndAutoConnect() async {
    final provider = context.read<WashingMachineProvider>();
    await provider.loadPairedDevices();
    if (!mounted) return;

    // Auto-connect to a paired WB-Dual device if available
    final target = provider.filteredPairedDevices.cast<BtDevice?>().firstWhere(
      (d) => d!.name.toUpperCase().contains('WB-DUAL'),
      orElse: () => null,
    );
    if (target != null) {
      await provider.connectToDevice(target);
      if (mounted) _waitForConnectionAndAuth(provider);
    }
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
    final showAll = provider.showAllDevices;

    final pairedList = showAll
        ? provider.allPairedDevices
        : provider.filteredPairedDevices;
    final discoveredList = showAll
        ? provider.discoveredDevices
        : provider.filteredDiscoveredDevices;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Washer'),
        actions: [
          IconButton(
            icon: Icon(
              showAll ? Icons.filter_list_off : Icons.filter_list,
              size: 20,
            ),
            tooltip: showAll ? 'Show IFB devices only' : 'Show all devices',
            onPressed: () => provider.toggleShowAllDevices(),
          ),
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
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(
                  CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
                ),
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

          // Connection + auth status banner
          if (provider.connectionState == BtConnectionState.connecting ||
              _waitingForAuth)
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
                    _waitingForAuth ? 'Authenticating...' : 'Connecting...',
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
          if (pairedList.isEmpty)
            _emptyCard(
              context,
              showAll
                  ? 'No paired Bluetooth devices found'
                  : 'No IFB washing machines paired.\nTry "Show all" to see other devices.',
            )
          else
            ...pairedList.map((d) => _deviceTile(context, d, provider)),

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
          if (discoveredList.isEmpty)
            _emptyCard(
              context,
              provider.isScanning
                  ? 'Scanning for IFB devices...'
                  : 'Tap search to discover nearby devices',
            )
          else
            ...discoveredList.map((d) => _deviceTile(context, d, provider)),

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
            textAlign: TextAlign.center,
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
    final isWasher = device.isWashingMachine;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isWasher ? cs.primary : cs.onSurface).withValues(
              alpha: 0.12,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isWasher ? Icons.local_laundry_service : Icons.bluetooth,
            color: isWasher ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
          ),
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
          _waitForConnectionAndAuth(provider);
        },
      ),
    );
  }

  void _waitForConnectionAndAuth(WashingMachineProvider provider) {
    int ticks = 0;
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      ticks++;
      if (!mounted) {
        timer.cancel();
        setState(() => _waitingForAuth = false);
        return;
      }

      // Connected but not yet authenticated — show "Authenticating..."
      if (provider.connectionState == BtConnectionState.connected &&
          !provider.isAuthenticated) {
        if (!_waitingForAuth) setState(() => _waitingForAuth = true);
      }

      // Authenticated — navigate to main
      if (provider.connectionState == BtConnectionState.connected &&
          provider.isAuthenticated) {
        timer.cancel();
        setState(() => _waitingForAuth = false);
        Navigator.of(context).pushReplacementNamed('/main');
        return;
      }

      // Disconnected or failed
      if (provider.connectionState == BtConnectionState.disconnected) {
        timer.cancel();
        setState(() => _waitingForAuth = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Try again.')),
        );
        return;
      }

      // Timeout after 15 seconds — go to main anyway (might auth later)
      if (ticks > 30) {
        timer.cancel();
        setState(() => _waitingForAuth = false);
        if (provider.connectionState == BtConnectionState.connected) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      }
    });
  }
}
