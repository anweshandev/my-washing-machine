import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/maintenance_provider.dart';
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
  int _currentIndex = 0;
  int _overdueCount = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AiCopilotScreen(),
    MaintenanceScreen(),
    SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Init maintenance provider when user is authenticated
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      context.read<MaintenanceProvider>().init(auth.user!.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    _overdueCount = context.watch<MaintenanceProvider>().overdueCount;

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
