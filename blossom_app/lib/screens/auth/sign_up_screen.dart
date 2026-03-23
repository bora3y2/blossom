import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_session.dart';
import '../../core/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = AppSessionScope.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
              const SizedBox(height: 48),
              // Header texting
              Text(
                'Create Account',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign up to get started',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _buildLabel('Full Name'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _fullNameController,
                hint: 'John Doe',
                obscureText: false,
              ),
              const SizedBox(height: 24),
              _buildLabel('Email'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailController,
                hint: 'hello@blossom.com',
                obscureText: false,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              _buildLabel('Password'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _passwordController,
                hint: '••••••••',
                obscureText: true,
              ),
              if (session.configurationError != null) ...[
                const SizedBox(height: 16),
                Text(
                  session.configurationError!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _successMessage!,
                  style: const TextStyle(color: AppTheme.primary),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
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
                      session.isBusy ? 'Creating account...' : 'Sign Up',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: const Text("Already have an account? Log In"),
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
      _successMessage = null;
    });
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Enter full name, email, and password.';
      });
      return;
    }
    try {
      await session.signUp(
        fullName: fullName,
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      if (session.isAuthenticated) {
        return;
      }
      setState(() {
        _successMessage =
            'Account created. Check your email to confirm, then log in.';
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
