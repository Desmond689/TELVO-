import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDualModeAccount = user?.userType == 'both';

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF00C853),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user?.profilePhoto != null
                        ? NetworkImage(user!.profilePhoto!)
                        : null,
                    child: user?.profilePhoto == null
                        ? Text(
                            user?.fullName?.substring(0, 1).toUpperCase() ??
                                '?',
                            style: const TextStyle(fontSize: 28),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.userType ?? 'Customer',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerItem(
              icon: Icons.home,
              title: 'Home',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.home);
              },
            ),
            _buildDrawerItem(
              icon: Icons.person,
              title: 'My Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.profile);
              },
            ),
            if (isDualModeAccount)
              _buildDrawerItem(
                icon: Icons.swap_horiz,
                title: 'Switch Mode',
                onTap: () {
                  Navigator.pop(context);
                  final currentMode = user?.mode;
                  final newMode = currentMode == 'professional'
                      ? 'customer'
                      : 'professional';
                  authProvider.switchMode(newMode);
                  Navigator.pushReplacementNamed(
                    context,
                    newMode == 'professional'
                        ? AppRoutes.professionalDashboard
                        : AppRoutes.home,
                  );
                },
              ),
            _buildDrawerItem(
              icon: Icons.favorite,
              title: 'My Favorites',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.favorites);
              },
            ),
            _buildDrawerItem(
              icon: Icons.history,
              title: 'Job History',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.history);
              },
            ),
            _buildDrawerItem(
              icon: Icons.payment,
              title: 'Payments',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.payment);
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.notifications);
              },
            ),
            _buildDrawerItem(
              icon: Icons.help,
              title: 'Help Center',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.safety);
              },
            ),
            _buildDrawerItem(
              icon: Icons.share,
              title: 'Invite Friends',
              onTap: () {
                Navigator.pop(context);
                // Share invitation
              },
            ),
            const Spacer(),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Logout',
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.grey.shade800),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().signOut();
              Navigator.pushReplacementNamed(context, AppRoutes.welcome);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
