import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/washing_machine_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => WashingMachineProvider()),
      ],
      child: WashingApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class WashingApp extends StatelessWidget {
  final bool isLoggedIn;
  const WashingApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'IFB Washer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      initialRoute: isLoggedIn ? '/permissions' : '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/permissions': (_) => const PermissionsScreen(),
        '/scan': (_) => const ScanScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
