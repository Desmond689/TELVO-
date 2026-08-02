import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/widgets/profile_photo_picker.dart';
import 'package:telvo/widgets/rating_stars.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDualModeAccount = authProvider.canSwitchModes;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view profile')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildProfileInfo(user),
              const SizedBox(height: 24),
              _buildStats(user),
              const SizedBox(height: 24),
              _buildMenuItems(),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Edit Profile',
                isOutlined: true,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.profileSetup);
                },
              ),
              const SizedBox(height: 12),
              if (isDualModeAccount)
                CustomButton(
                  text: 'Switch Mode',
                  isOutlined: true,
                  onPressed: () async {
                    final nextMode = user.mode == 'professional'
                        ? 'customer'
                        : 'professional';
                    await authProvider.switchMode(nextMode);
                    if (!mounted) return;
                    if (authProvider.error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authProvider.error!)),
                      );
                      return;
                    }
                    Navigator.pushReplacementNamed(
                      context,
                      nextMode == 'professional'
                          ? AppRoutes.professionalDashboard
                          : AppRoutes.home,
                    );
                  },
                ),
              if (isDualModeAccount) const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) => Column(
    children: [
      ProfilePhotoPicker(
        initialPhoto: user.profilePhoto,
        userId: user.id,
        onPhotoSelected: (filePath) async {
          if (filePath == null) return;
          final url = await context
              .read<AuthProvider>()
              .uploadProfilePhoto(filePath);
          if (url != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo updated!')),
            );
          }
        },
      ),
      const SizedBox(height: 8),
      Text(
        user.fullName ?? 'Unknown',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        user.userType ?? 'Customer',
        style: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (user.isVerified)
            const Icon(Icons.verified, color: Color(0xFF00C853), size: 16),
          const SizedBox(width: 4),
          if (user.isVerified)
            const Text(
              'Verified',
              style: TextStyle(color: Color(0xFF00C853), fontSize: 14),
            ),
        ],
      ),
    ],
  );

  Widget _buildProfileInfo(UserModel user) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
    ),
    child: Column(
      children: [
        _buildInfoRow(Icons.phone, user.phoneNumber ?? 'Not set'),
        _buildInfoRow(Icons.email, user.email ?? 'Not set'),
        _buildInfoRow(
          Icons.location_on,
          '${user.city ?? ''}, ${user.neighborhood ?? ''}',
        ),
        _buildInfoRow(Icons.language, user.language ?? 'Not set'),
        if (user.category != null) _buildInfoRow(Icons.work, user.category!),
      ],
    ),
  );

  Widget _buildInfoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildStats(UserModel user) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.35),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          'Rating',
          user.rating?.toStringAsFixed(1) ?? '0.0',
          RatingStars(rating: user.rating ?? 0, size: 14),
        ),
        _buildStatItem(
          'Jobs',
          '${user.jobsCompleted ?? 0}',
          const Icon(Icons.work, color: Colors.grey),
        ),
        _buildStatItem(
          'Response',
          '${user.responseTime ?? 0} min',
          const Icon(Icons.timer, color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildStatItem(String label, String value, Widget icon) => Column(
    children: [
      icon,
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildMenuItems() {
    final items = [
      {
        'icon': Icons.favorite,
        'title': 'My Favorites',
        'route': AppRoutes.favorites,
      },
      {
        'icon': Icons.history,
        'title': 'Job History',
        'route': AppRoutes.history,
      },
      {'icon': Icons.payment, 'title': 'Payments', 'route': AppRoutes.payment},
      {'icon': Icons.security, 'title': 'Safety', 'route': AppRoutes.safety},
      {
        'icon': Icons.settings,
        'title': 'Settings',
        'route': AppRoutes.settings,
      },
      {'icon': Icons.help, 'title': 'Help Center', 'route': AppRoutes.safety},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: items
            .map(
              (item) => ListTile(
                leading: Icon(
                  item['icon'] as IconData,
                  color: Colors.grey.shade600,
                ),
                title: Text(item['title'] as String),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.pushNamed(context, item['route'] as String);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
