import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    final authProvider = context.read<AuthProvider>();

    // Wait for the real session check to resolve (Firebase Auth state +
    // the Firestore profile fetch), not a guessed delay. A 6s ceiling
    // keeps a dead connection from stranding the user on splash forever;
    // in that case we fall through to the logged-out flow below.
    await Future.any([
      authProvider.onReady,
      Future.delayed(const Duration(seconds: 6)),
    ]);

    // Keep the logo on screen briefly so the transition doesn't flash.
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      if (authProvider.isAuthenticated) {
        final user = authProvider.currentUser;
        if (user?.fullName == null || user?.fullName?.isEmpty == true) {
          Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
        } else if (user?.userType == null) {
          Navigator.pushReplacementNamed(context, AppRoutes.chooseMode);
        } else if (user?.mode == 'professional') {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.professionalDashboard,
          );
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/splash_background.png', fit: BoxFit.cover),
        Container(color: Colors.black.withOpacity(0.28)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/telvo_logo.png', height: 100),
              const SizedBox(height: 16),
              const Text(
                'Telvo',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Trusted workers. Real solutions.',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
