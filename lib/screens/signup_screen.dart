import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/input_validator.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/alert_widgets.dart';
import '../theme/app_theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signUpWithEmailPassword(
      fullName: _fullNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/');
    } else if (auth.error != null) {
      AlertWidgets.showError(
        context,
        title: 'Sign Up Failed',
        message: auth.error!,
      );
      auth.clearError();
    }
  }

  Future<void> _handleGoogleSignUp() async {
    final auth = context.read<AuthProvider>();
    final success = await auth.signInWithGoogle();

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushReplacementNamed('/');
    } else if (auth.error != null) {
      AlertWidgets.showError(
        context,
        title: 'Sign Up Failed',
        message: auth.error!,
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Join LaundryIQ',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to get started',
                    style: TextStyle(color: AppTheme.subtextColor(context)),
                  ),
                  const SizedBox(height: 32),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Full Name',
                          hint: 'Enter your first and last name',
                          controller: _fullNameCtrl,
                          validator: InputValidator.validateFullName,
                          keyboardType: TextInputType.name,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        const SizedBox(height: 20),
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
                          hint: 'Create a strong password',
                          controller: _passwordCtrl,
                          validator: InputValidator.validatePassword,
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter your password',
                          controller: _confirmCtrl,
                          validator: (v) =>
                              InputValidator.validateConfirmPassword(
                                v,
                                _passwordCtrl.text,
                              ),
                          isPassword: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleSignUp,
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),

                  const SizedBox(height: 24),

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

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _handleGoogleSignUp,
                      icon: Image.asset(
                        'assets/logos/icon-192.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.g_mobiledata, size: 20),
                      ),
                      label: const Text('Continue with Google'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'By creating an account, you agree to our Terms of Service',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                      textAlign: TextAlign.center,
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
