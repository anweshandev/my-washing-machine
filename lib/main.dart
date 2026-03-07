import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/washing_machine_provider.dart';
import 'screens/permissions_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => WashingMachineProvider(),
      child: const WashingApp(),
    ),
  );
}

class WashingApp extends StatelessWidget {
  const WashingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IFB Washer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/permissions',
      routes: {
        '/permissions': (_) => const PermissionsScreen(),
        '/scan': (_) => const ScanScreen(),
        '/dashboard': (_) => const DashboardScreen(),
      },
    );
  }
}
