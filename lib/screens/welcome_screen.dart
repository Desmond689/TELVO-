import 'package:flutter/material.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/custom_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            Image.asset('assets/images/welcome_illustration.png', height: 200),
            const SizedBox(height: 32),
            const Text(
              'Find Trusted Professionals Near You',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Connect with verified workers for any service you need, quickly and safely.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 48),
            CustomButton(
              text: 'Get Started',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.signup,
                  arguments: 'customer',
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'I\'m a Professional',
              isOutlined: true,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.signup,
                  arguments: 'professional',
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
  );
}
