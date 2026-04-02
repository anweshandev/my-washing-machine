import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
import '../providers/washing_machine_provider.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'ai_copilot_screen.dart';
import 'maintenance_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 2; // Default to AI tab
  int _overdueCount = 0;
  bool _hasAutoSwitchedToWash = false;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AiCopilotScreen(),
    MaintenanceScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDisconnectListener();
      _backgroundAutoConnect();
    });
  }

  void _setupDisconnectListener() {
    final provider = context.read<WashingMachineProvider>();
    provider.onUnexpectedDisconnect = () {
      if (!mounted) return;
      _showDisconnectDialog();
    };
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.bluetooth_disabled,
          color: Theme.of(ctx).colorScheme.error,
          size: 40,
        ),
        title: const Text('Device Disconnected'),
        content: const Text(
          'The washing machine has been disconnected. '
          'Would you like to reconnect?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _backgroundAutoConnect();
            },
            icon: const Icon(Icons.bluetooth_searching, size: 18),
            label: const Text('Reconnect'),
          ),
        ],
      ),
    );
  }

  Future<void> _backgroundAutoConnect() async {
    final provider = context.read<WashingMachineProvider>();
    await provider.autoConnectSavedDevice();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<MaintenanceProvider>().init(auth.user!.uid);
    }
  }

  @override
  void dispose() {
    // Clear the callback to avoid calling setState on a disposed widget
    context.read<WashingMachineProvider>().onUnexpectedDisconnect = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<WashingMachineProvider>();
    _overdueCount = context.watch<MaintenanceProvider>().overdueCount;

    // Auto-switch to Wash tab when machine becomes active (running/paused)
    if (!_hasAutoSwitchedToWash &&
        provider.connectionState == BtConnectionState.connected &&
        (provider.telemetry.isRunning || provider.telemetry.isPaused)) {
      _hasAutoSwitchedToWash = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = 0);
      });
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: Icon(
              Icons.local_laundry_service_outlined,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            selectedIcon: Icon(Icons.local_laundry_service, color: cs.primary),
            label: 'Wash',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.history_outlined,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            selectedIcon: Icon(Icons.history, color: cs.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.auto_awesome_outlined,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            selectedIcon: Icon(Icons.auto_awesome, color: cs.primary),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: _overdueCount > 0,
              label: Text('$_overdueCount'),
              child: Icon(
                Icons.build_outlined,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            selectedIcon: Badge(
              isLabelVisible: _overdueCount > 0,
              label: Text('$_overdueCount'),
              child: Icon(Icons.build, color: cs.primary),
            ),
            label: 'Care',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
            selectedIcon: Icon(Icons.settings, color: cs.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
