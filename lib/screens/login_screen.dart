import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    // Simulate a brief delay for UX
    await Future.delayed(const Duration(milliseconds: 800));

    // Persist fake auth state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/permissions');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // Logo
              Center(
                child: Image.asset(
                  'assets/logos/ic_launcher-playstore.png',
                  width: 100,
                  height: 100,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Center(
                child: Text(
                  'IFB Washer',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Control your washing machine\nright from your phone',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.subtextColor(context),
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Continue with Google button (SVG)
              SizedBox(
                width: double.infinity,
                height: 40,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: _isLoading ? null : _handleGoogleSignIn,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SvgPicture.asset(
                              'assets/icons/android_light_sq_ctn.svg',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isLoading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Info text
              Center(
                child: Text(
                  'By continuing, you agree to our Terms of Service',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.subtextColor(context),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
