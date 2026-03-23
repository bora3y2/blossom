import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/theme.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<LogInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand Header
              const Icon(
                Icons.filter_vintage_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Blossom',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 64),
              // Header texting
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please enter your details to continue',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildLabel('Email'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                hint: 'hello@blossom.com',
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 32),
              _buildLabel('Password'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: session.isBusy
                    ? null
                    : () => _forgotPassword(session),
                child: const Text('Forgot password?'),
              ),
              if (session.configurationError != null) ...[
                Text(
                  session.configurationError!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (_infoMessage != null) ...[
                Text(
                  _infoMessage!,
                  style: const TextStyle(color: AppTheme.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: ElevatedButton(
                    onPressed: session.isBusy ? null : () => _submit(session),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                    child: Text(
                      session.isBusy ? 'Logging in...' : 'Log In',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/signup');
                },
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit(AppSession session) async {
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter both email and password.';
      });
      return;
    }
    try {
      await session.signIn(email: email, password: password);
    } on AppSessionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _forgotPassword(AppSession session) async {
    final emailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(emailController.text.trim()),
              child: const Text('Send email'),
            ),
          ],
        );
      },
    );
    emailController.dispose();
    if (email == null) {
      return;
    }
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email address to reset your password.';
        _infoMessage = null;
      });
      return;
    }
    setState(() {
      _errorMessage = null;
      _infoMessage = null;
    });
    try {
      await session.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        _infoMessage = 'Password reset email sent to $email';
      });
    } on AppSessionException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.primary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF5F4EF),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 20,
          horizontal: 32,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9999),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
