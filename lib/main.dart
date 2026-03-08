import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/washing_machine_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/permissions_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WashingMachineProvider()),
      ],
      child: const WashingApp(),
    ),
  );
}

class WashingApp extends StatelessWidget {
  const WashingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'IFB Washer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      initialRoute: '/permissions',
      routes: {
        '/permissions': (_) => const PermissionsScreen(),
        '/scan': (_) => const ScanScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
