// lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/utils/validators.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _userType; // set from the Welcome screen's Customer/Professional choice

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userType ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authProvider = context.read<AuthProvider>();

    var phoneNumber = _phoneController.text.trim();
    if (!phoneNumber.startsWith('+237')) {
      phoneNumber = '+237$phoneNumber';
    }

    final success = await authProvider.signUp(
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: phoneNumber,
      password: _passwordController.text,
      userType: _userType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profileSetup,
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              const Text(
                'Create your account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _userType == 'professional'
                    ? 'Sign up to offer your services'
                    : _userType == 'both'
                        ? 'Sign up to use Telvo as both a customer and a professional'
                        : 'Sign up as a customer and get started',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                controller: _fullNameController,
                labelText: 'Full Name',
                hintText: 'e.g., Xeron M.',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _usernameController,
                labelText: 'Username',
                hintText: 'e.g., xeron_m',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please choose a username';
                  }
                  if (value.trim().length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value.trim())) {
                    return 'Letters, numbers, _ and . only';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+237',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      hintText: '6 70 12 34 56',
                      keyboardType: TextInputType.phone,
                      validator: Validators.validateCameroonPhoneNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                labelText: 'Password',
                hintText: 'At least 6 characters',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(value)) {
                    return 'Use at least one letter and one number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Create Account',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _signUp,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: const Text('Already have an account? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
