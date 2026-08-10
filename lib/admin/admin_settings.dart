import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/widgets/custom_button.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _autoVerification = false;
  String _commissionRate = '10';
  String _currency = 'XAF';
  String _language = 'English';

  final List<String> _currencies = ['XAF', 'USD', 'EUR', 'GBP'];
  final List<String> _languages = [
    'English',
    'French',
    'Spanish',
    'Portuguese',
  ];

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final admin = adminProvider.currentAdmin;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCard(
                    title: 'General Settings',
                    children: [
                      _buildDropdownTile(
                        label: 'Currency',
                        value: _currency,
                        items: _currencies,
                        onChanged: (value) {
                          setState(() {
                            _currency = value!;
                          });
                        },
                      ),
                      _buildDropdownTile(
                        label: 'Language',
                        value: _language,
                        items: _languages,
                        onChanged: (value) {
                          setState(() {
                            _language = value!;
                          });
                        },
                      ),
                      _buildTextFieldTile(
                        label: 'Default Commission Rate (%)',
                        value: _commissionRate,
                        onChanged: (value) {
                          setState(() {
                            _commissionRate = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Platform Settings',
                    children: [
                      _buildSwitchTile(
                        label: 'Maintenance Mode',
                        value: _maintenanceMode,
                        subtitle: 'Temporarily disable platform access',
                        onChanged: (value) {
                          setState(() {
                            _maintenanceMode = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        label: 'Push Notifications',
                        value: _pushNotifications,
                        subtitle: 'Enable push notifications for all users',
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        label: 'Email Notifications',
                        value: _emailNotifications,
                        subtitle: 'Enable email notifications for all users',
                        onChanged: (value) {
                          setState(() {
                            _emailNotifications = value;
                          });
                        },
                      ),
                      _buildSwitchTile(
                        label: 'Auto Verification',
                        value: _autoVerification,
                        subtitle: 'Automatically verify new professionals',
                        onChanged: (value) {
                          setState(() {
                            _autoVerification = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Admin Profile',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.grey),
                        title: const Text('Name'),
                        subtitle: Text(admin?.fullName ?? 'N/A'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.grey),
                        title: const Text('Email'),
                        subtitle: Text(admin?.email ?? 'N/A'),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.grey,
                        ),
                        title: const Text('Role'),
                        subtitle: Text(admin?.role.toUpperCase() ?? 'N/A'),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.calendar_today,
                          color: Colors.grey,
                        ),
                        title: const Text('Last Login'),
                        subtitle: Text(_formatDate(admin?.lastLogin)),
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Change Password',
                        isOutlined: true,
                        onPressed: _showChangePasswordDialog,
                      ),
                      const SizedBox(height: 8),
                      CustomButton(
                        text: 'Update Profile',
                        isOutlined: true,
                        onPressed: _showUpdateProfileDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Data Management',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.backup, color: Colors.blue),
                        title: const Text('Backup Database'),
                        subtitle: const Text(
                          'Create a full backup of all data',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showConfirmDialog(
                          'Backup Database',
                          'This will create a full backup of all user data, jobs, and payments. This may take a few minutes.',
                          'Backup',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Backup started. You will be notified when complete.',
                                ),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.restore,
                          color: Colors.orange,
                        ),
                        title: const Text('Restore Database'),
                        subtitle: const Text('Restore from a previous backup'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showConfirmDialog(
                          'Restore Database',
                          'This will restore all data from the latest backup. Current data will be overwritten.',
                          'Restore',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Restore started. This may take a few minutes.',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.analytics,
                          color: Colors.purple,
                        ),
                        title: const Text('Export Data'),
                        subtitle: const Text('Export all data as CSV/JSON'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Export started. File will be downloaded shortly.',
                              ),
                              backgroundColor: Color(0xFF00C853),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text('Clear Cache'),
                        subtitle: const Text('Clear all cached data'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => _showConfirmDialog(
                          'Clear Cache',
                          'This will clear all cached data. Users will need to reload their data.',
                          'Clear',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cache cleared successfully'),
                                backgroundColor: Color(0xFF00C853),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCard(
                    title: 'Danger Zone',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.warning, color: Colors.red),
                        title: const Text(
                          'Delete All Data',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Permanently delete all platform data',
                          style: TextStyle(color: Colors.red),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.red,
                        ),
                        onTap: () => _showConfirmDialog(
                          '⚠️ Delete All Data',
                          'This will permanently delete ALL data including users, jobs, payments, and all platform content. This action cannot be undone!',
                          'Delete Everything',
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Data deletion request initiated. All data will be deleted in 24 hours.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          isDanger: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String label,
    required bool value,
    required String subtitle,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00C853),
    );
  }

  Widget _buildDropdownTile({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: value,
              items: items.map((item) {
                return DropdownMenuItem(value: item, child: Text(item));
              }).toList(),
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldTile({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: value,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmDialog(
    String title,
    String message,
    String actionText,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: TextButton.styleFrom(
              foregroundColor: isDanger ? Colors.red : const Color(0xFF00C853),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController oldPassword = TextEditingController();
    final TextEditingController newPassword = TextEditingController();
    final TextEditingController confirmPassword = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: newPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmPassword,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
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
                  content: Text('Password changed successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showUpdateProfileDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
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
                  content: Text('Profile updated successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
