import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/custom_button.dart';

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
    appBar: AppBar(title: const Text('Choose Your Mode'), elevation: 0),
    body: Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How will you use Telvo?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select how you want to interact with the platform',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ..._modes.map((mode) => _buildModeCard(mode)),
          const Spacer(),
          CustomButton(
            text: _isLoading ? 'Saving...' : 'Continue',
            onPressed: _isLoading ? null : _saveMode,
          ),
          const SizedBox(height: 16),
        ],
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF00C853) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.green.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00C853)
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                mode['icon'],
                color: isSelected ? Colors.white : Colors.grey,
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
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  Text(
                    mode['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.green.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF00C853)),
          ],
        ),
      ),
    );
  }
}
