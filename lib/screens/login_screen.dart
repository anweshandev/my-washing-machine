import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/input_validator.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/alert_widgets.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithEmailPassword(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (!success && auth.error != null) {
      AlertWidgets.showError(
        context,
        title: 'Login Failed',
        message: auth.error!,
      );
      auth.clearError();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;
    if (!success && auth.error != null) {
      AlertWidgets.showError(
        context,
        title: 'Sign In Failed',
        message: auth.error!,
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logos/ic_launcher-playstore.png',
                      width: 100,
                      height: 100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Center(
                    child: Text(
                      'LaundryIQ',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Smart washing machine control',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Login form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Email Address',
                          hint: 'Enter your email',
                          controller: _emailCtrl,
                          validator: InputValidator.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: const Icon(Icons.mail_outline),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordCtrl,
                          validator: InputValidator.validatePassword,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_emailCtrl.text.trim().isNotEmpty) {
                          auth.resetPassword(_emailCtrl.text.trim());
                          AlertWidgets.showSuccess(
                            context,
                            'Password reset email sent!',
                          );
                        } else {
                          AlertWidgets.showInfo(
                            context,
                            'Enter your email first',
                          );
                        }
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sign In button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: cs.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or',
                          style: TextStyle(
                            color: AppTheme.subtextColor(context),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: cs.outline)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Google Sign-In
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: auth.isLoading ? null : _handleGoogleSignIn,
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

                  const SizedBox(height: 24),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: TextStyle(
                            color: AppTheme.subtextColor(context),
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.of(context).pushNamed('/signup'),
                          child: const Text('Sign Up'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'By continuing, you agree to our Terms of Service',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
