import 'package:flutter/material.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/utils/app_colors.dart';
import 'package:telvo/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF0B1220), Color(0xFF111827)]
                : const [Color(0xFFF0FDF9), Color(0xFFF7F8FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  // Modern Hero Image
                  Container(
                    height: 280,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            'assets/images/Telvo app splash screen design (1).png',
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Main Heading
                  Text(
                    'Find Trusted Professionals Near You',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      letterSpacing: -0.5,
                      height: 1.3,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Connect with verified workers for any service you need, quickly and safely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Poppins',
                      height: 1.5,
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Join as Customer Button
                  CustomButton(
                    text: 'Join as a Customer',
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.signup,
                        arguments: 'customer',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Join as Professional Button
                  CustomButton(
                    text: 'Join as a Professional',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.signup,
                        arguments: 'professional',
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Use Both Modes Button
                  CustomButton(
                    text: 'Use Both Modes',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.signup,
                        arguments: 'both',
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}