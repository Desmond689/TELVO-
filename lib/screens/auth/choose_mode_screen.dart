import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/utils/app_colors.dart';

class ChooseModeScreen extends StatefulWidget {
  const ChooseModeScreen({super.key});

  @override
  State<ChooseModeScreen> createState() => _ChooseModeScreenState();
}

class _ChooseModeScreenState extends State<ChooseModeScreen> {
  String? _selectedMode;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _modes = [
    {
      'title': 'Customer',
      'description': 'Find and hire trusted professionals',
      'icon': Icons.person,
      'value': 'customer',
    },
    {
      'title': 'Professional',
      'description': 'Offer services and earn money',
      'icon': Icons.build,
      'value': 'professional',
    },
    {
      'title': 'Both',
      'description': 'Use Telvo as both customer and professional',
      'icon': Icons.swap_horiz,
      'value': 'both',
    },
  ];

  Future<void> _saveMode() async {
    if (_selectedMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select how you want to use Telvo'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final resolvedMode = _selectedMode == 'both' ? 'customer' : _selectedMode;
    await authProvider.updateProfile({
      'userType': _selectedMode,
      'mode': resolvedMode,
    });

    if (mounted) {
      setState(() => _isLoading = false);

      if (authProvider.error == null) {
        if (_selectedMode == 'professional' || _selectedMode == 'both') {
          Navigator.pushReplacementNamed(context, AppRoutes.professionalSetup);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(authProvider.error!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Choose Your Mode'),
      elevation: 0,
      backgroundColor: Colors.transparent,
    ),
    body: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
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
                            Colors.black.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Main Heading
            Text(
              'How will you use Telvo?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select how you want to interact with the platform',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            // Mode Cards
            ..._modes.map((mode) => _buildModeCard(mode)),
            const SizedBox(height: 32),
            CustomButton(
              text: _isLoading ? 'Saving...' : 'Continue',
              onPressed: _isLoading ? null : _saveMode,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );

  Widget _buildModeCard(Map<String, dynamic> mode) {
    final isSelected = _selectedMode == mode['value'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode['value'];
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? AppColors.primary 
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected 
              ? AppColors.primaryBackground 
              : Theme.of(context).colorScheme.surface,
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode['icon'],
                color: isSelected 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode['title'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mode['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withValues(
                        alpha: isSelected ? 0.7 : 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
