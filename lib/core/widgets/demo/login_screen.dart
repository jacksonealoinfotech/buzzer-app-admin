import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:buzzer_app_admin/core/di/injection.dart';
import 'package:buzzer_app_admin/core/responsive/app_spacing.dart';
import 'package:buzzer_app_admin/core/security/secure_text_field.dart';
import 'package:buzzer_app_admin/core/security/token_manager.dart';
import 'package:buzzer_app_admin/core/widgets/buttons/app_button.dart';
import 'package:buzzer_app_admin/core/widgets/inputs/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    // Store in-memory access token & secure refresh token via TokenManager
    await getIt<TokenManager>().saveTokens(
      accessToken:
          'demo_jwt_access_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'demo_refresh_token_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (mounted) {
      setState(() => _isLoading = false);
      context.go('/');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_rounded, size: 64),
                Gap.v24,
                AppTextField(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'user@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                Gap.v16,
                SecureTextField(
                  controller: _passwordController,
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                Gap.v24,
                AppButton(
                  text: 'Sign In',
                  isLoading: _isLoading,
                  isFullWidth: true,
                  onPressed: _handleLogin,
                ),
                Gap.v16,
                TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Continue as Guest'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
