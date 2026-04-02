import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'services/tts_service.dart';
import 'providers/washing_machine_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/maintenance_provider.dart';
import 'theme/app_theme.dart';
import 'screens/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/permissions_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/main_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: capture all uncaught Flutter errors
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Firebase App Check
  if (kDebugMode || kProfileMode) {
    final debugTokenAndroid = dotenv.env['ANDROID_DEBUG_TOKEN'];
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(debugToken: debugTokenAndroid),
    );
  } else {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
    );
  }
  await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);

  // Pre-initialize TTS engine so it's bound before first speak()
  await TtsService().init();

  runApp(const LaundryIQApp());
}

class LaundryIQApp extends StatelessWidget {
  const LaundryIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WashingMachineProvider()),
        ChangeNotifierProvider(create: (_) => AiProvider()),
        ChangeNotifierProvider(create: (_) => MaintenanceProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'LaundryIQ',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.mode,
            initialRoute: '/',
            routes: {
              '/': (_) => const AuthWrapper(),
              '/login': (_) => const LoginScreen(),
              '/signup': (_) => const SignUpScreen(),
              '/permissions': (_) => const PermissionsScreen(),
              '/scan': (_) => const ScanScreen(),
              '/main': (_) => const MainScreen(),
              '/dashboard': (_) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
