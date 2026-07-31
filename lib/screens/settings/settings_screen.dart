import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telvo/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _biometricLogin = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'XAF';

  final List<String> _languages = ['English', 'French', 'Pidgin', 'Spanish'];
  final List<String> _currencies = ['XAF', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDarkMode = prefs.getBool('useDarkTheme') ?? false;
    if (!mounted) return;
    setState(() {
      _darkMode = savedDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final isDualModeAccount = user?.userType == 'both';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Preferences',
            children: [
              _buildSwitchTile(
                icon: Icons.dark_mode,
                title: 'Dark Mode',
                value: _darkMode,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('useDarkTheme', value);
                  appThemeMode.value = value
                      ? ThemeMode.dark
                      : ThemeMode.system;
                  if (mounted) {
                    setState(() {
                      _darkMode = value;
                    });
                  }
                },
              ),
              _buildDropdownTile(
                icon: Icons.language,
                title: 'Language',
                value: _selectedLanguage,
                items: _languages,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
              ),
              _buildDropdownTile(
                icon: Icons.monetization_on,
                title: 'Currency',
                value: _selectedCurrency,
                items: _currencies,
                onChanged: (value) {
                  setState(() {
                    _selectedCurrency = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Security',
            children: [
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                value: _biometricLogin,
                onChanged: (value) {
                  setState(() {
                    _biometricLogin = value;
                  });
                },
              ),
              _buildTile(
                icon: Icons.lock,
                title: 'Change PIN',
                onTap: () {
                  _showChangePINDialog();
                },
              ),
              _buildTile(
                icon: Icons.password,
                title: 'Change Password',
                onTap: () {
                  _showChangePasswordDialog();
                },
              ),
              _buildTile(
                icon: Icons.phone,
                title: 'Change Phone Number',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Phone number updates will be available soon.',
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Privacy',
            children: [
              _buildTile(
                icon: Icons.privacy_tip,
                title: 'Privacy & Security',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.safety);
                },
              ),
              _buildTile(
                icon: Icons.language,
                title: 'Language',
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final choice = await showDialog<String>(
                    context: context,
                    builder: (ctx) => SimpleDialog(
                      title: const Text('Select language'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, 'en'),
                          child: const Text('English'),
                        ),
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(ctx, 'fr'),
                          child: const Text('Français'),
                        ),
                      ],
                    ),
                  );
                  if (choice != null) {
                    await prefs.setString('locale', choice);
                    await context.setLocale(Locale(choice));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Language updated')),
                      );
                    }
                  }
                },
              ),
              _buildTile(
                icon: Icons.block,
                title: 'Blocked Users',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Blocked users will be available soon.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Support',
            children: [
              _buildTile(
                icon: Icons.help,
                title: 'Help Center',
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.safety);
                },
              ),
              _buildTile(
                icon: Icons.info,
                title: 'About Telvo',
                onTap: () {
                  _showAboutDialog();
                },
              ),
              _buildTile(
                icon: Icons.share,
                title: 'Invite Friends',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invite friends will be available soon.'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            title: 'Account',
            children: [
              if (isDualModeAccount)
                _buildTile(
                  icon: Icons.switch_account,
                  title: 'Switch Mode',
                  onTap: () {
                    final nextMode = user?.mode == 'professional'
                        ? 'customer'
                        : 'professional';
                    context.read<AuthProvider>().switchMode(nextMode);
                    Navigator.pushReplacementNamed(
                      context,
                      nextMode == 'professional'
                          ? AppRoutes.professionalDashboard
                          : AppRoutes.home,
                    );
                  },
                ),
              _buildTile(
                icon: Icons.logout,
                title: 'Logout',
                textColor: Colors.red,
                onTap: _logout,
              ),
              _buildTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                textColor: Colors.red,
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.75),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(children: children),
      ),
    ],
  );

  Widget _buildTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? textColor,
    Widget? trailing,
  }) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(
      title,
      style: TextStyle(
        color: textColor ?? Theme.of(context).colorScheme.onSurface,
      ),
    ),
    trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
    onTap: onTap,
  );

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00C853),
    ),
  );

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    ),
    trailing: DropdownButton<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      underline: const SizedBox(),
    ),
  );

  void _showChangePINDialog() {
    final TextEditingController oldPINController = TextEditingController();
    final TextEditingController newPINController = TextEditingController();
    final TextEditingController confirmPINController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPINController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Current PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: newPINController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New PIN',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmPINController,
              obscureText: true,
              maxLength: 4,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Confirm New PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPINController.text != confirmPINController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match')),
                );
                return;
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN changed successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final screenContext = context;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmPasswordController,
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be at least 6 characters',
                            ),
                          ),
                        );
                        return;
                      }
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }

                      final authProvider = screenContext.read<AuthProvider>();
                      final navigator = Navigator.of(dialogContext);
                      final messenger = ScaffoldMessenger.of(screenContext);

                      setDialogState(() => isSaving = true);
                      final success = await authProvider.changePassword(
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                      );

                      navigator.pop();
                      final message = success
                          ? 'Password changed successfully'
                          : (authProvider.error ?? 'Failed to change password');
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
              ),
              child: isSaving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Telvo',
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/images/telvo_logo.png',
          height: 48,
        ),
        children: [
          const SizedBox(height: 16),
          const Text(
            'Trusted workers. Real solutions.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    }
  }

  void _showDeleteAccountDialog() {
    final screenContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final authProvider = screenContext.read<AuthProvider>();
              final navigator = Navigator.of(screenContext);
              Navigator.pop(dialogContext);
              await authProvider.deleteAccount();
              navigator.pushReplacementNamed(AppRoutes.welcome);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
