import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class BusinessAccountScreen extends StatefulWidget {
  const BusinessAccountScreen({super.key});

  @override
  State<BusinessAccountScreen> createState() => _BusinessAccountScreenState();
}

class _BusinessAccountScreenState extends State<BusinessAccountScreen> {
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isVerified = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Business Account'), elevation: 0),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBusinessHeader(),
          const SizedBox(height: 24),
          _buildBusinessForm(),
          const SizedBox(height: 24),
          _buildBusinessFeatures(),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Upgrade to Business',
            onPressed: _upgradeBusiness,
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );

  Widget _buildBusinessHeader() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF00C853), Color(0xFF00E676)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.business, color: Color(0xFF00C853), size: 32),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Business Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isVerified
                    ? 'Verified Business'
                    : 'Get verified as a business',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        if (_isVerified)
          const Icon(Icons.verified, color: Colors.white, size: 32),
      ],
    ),
  );

  Widget _buildBusinessForm() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _businessNameController,
          hintText: 'Business Name',
          labelText: 'Business Name',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _registrationController,
          hintText: 'Registration Number',
          labelText: 'Registration Number',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _addressController,
          hintText: 'Business Address',
          labelText: 'Business Address',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _emailController,
          hintText: 'Business Email',
          labelText: 'Business Email',
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _phoneController,
          hintText: 'Business Phone',
          labelText: 'Business Phone',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Company Verification'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _isVerified
                    ? Colors.green.shade100
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isVerified ? 'Verified' : 'Pending',
                style: TextStyle(
                  color: _isVerified
                      ? Colors.green.shade700
                      : Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildBusinessFeatures() {
    final features = [
      {
        'icon': Icons.people,
        'title': 'Multiple Employees',
        'description': 'Add and manage your team',
      },
      {
        'icon': Icons.task,
        'title': 'Assign Jobs',
        'description': 'Assign jobs to employees',
      },
      {
        'icon': Icons.repeat,
        'title': 'Recurring Jobs',
        'description': 'Set up recurring services',
      },
      {
        'icon': Icons.receipt,
        'title': 'Monthly Billing',
        'description': 'Simplified monthly invoicing',
      },
      {
        'icon': Icons.analytics,
        'title': 'Analytics',
        'description': 'Track business performance',
      },
      {
        'icon': Icons.admin_panel_settings,
        'title': 'Manager Accounts',
        'description': 'Manager-level access',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                feature['icon'] as IconData,
                color: const Color(0xFF00C853),
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                feature['title'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                feature['description'] as String,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _upgradeBusiness() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Business'),
        content: const Text(
          'Are you sure you want to upgrade to a business account? '
          'You will get access to business features and tools.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Business upgrade request submitted for review',
                  ),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
              setState(() {
                _isVerified = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }
}
