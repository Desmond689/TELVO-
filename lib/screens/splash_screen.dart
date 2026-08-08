import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/utils/app_colors.dart';

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
        } else if (authProvider.isProfessionalMode) {
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
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.15),
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/telvo_logo.png',
                  height: 88,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Telvo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trusted workers. Real solutions.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontFamily: 'Poppins',
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}