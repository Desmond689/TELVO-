import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/admin/admin_login.dart';
import 'package:telvo/admin/admin_dashboard.dart';

class AdminMain extends StatelessWidget {
  const AdminMain({super.key});

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();

    if (adminProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
              ),
              SizedBox(height: 16),
              Text('Loading Admin Panel...'),
            ],
          ),
        ),
      );
    }

    if (adminProvider.currentAdmin != null) {
      return const AdminDashboardScreen();
    }

    return const AdminLoginScreen();
  }
}
