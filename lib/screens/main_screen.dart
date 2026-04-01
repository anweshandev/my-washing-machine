import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
