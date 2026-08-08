// lib/screens/auth/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _sent = success;
    });

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Could not send reset link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Reset Password')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _sent ? _buildSentState() : _buildForm(),
      ),
    ),
  );

  Widget _buildForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Forgot your password?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          "Enter your email and we'll send you a link to reset your password.",
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        const SizedBox(height: 32),
        CustomTextField(
          controller: _emailController,
          labelText: 'Email',
          hintText: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Send Reset Link',
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _sendResetLink,
        ),
      ],
    ),
  );

  Widget _buildSentState() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.mark_email_read, size: 72, color: Color(0xFF00C853)),
      const SizedBox(height: 24),
      const Text(
        'Check your email',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      Text(
        "We've sent a password reset link to ${_emailController.text.trim()}. "
        "Open it to choose a new password, then come back and log in.",
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 15, color: Colors.grey),
      ),
      const SizedBox(height: 24),
      CustomButton(
        text: 'Back to Login',
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}
