import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DevConfigScreen extends StatefulWidget {
  final List<String> missingKeys;
  const _DevConfigScreen(this.missingKeys, {Key? key}) : super(key: key);

  @override
  State<_DevConfigScreen> createState() => _DevConfigScreenState();
}

class _DevConfigScreenState extends State<_DevConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final k in widget.missingKeys) {
      _controllers[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final sp = await SharedPreferences.getInstance();
    for (final entry in _controllers.entries) {
      final devKey = 'DEV_${entry.key}';
      await sp.setString(devKey, entry.value.text.trim());
    }
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved dev config. Restart the app to apply.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev: Enter Firebase keys')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Firebase keys are missing. Enter them here for local development.'),
            const SizedBox(height: 12),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    for (final key in widget.missingKeys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          controller: _controllers[key],
                          decoration: InputDecoration(labelText: key),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const CircularProgressIndicator() : const Text('Save for dev (restart app)'),
            ),
            const SizedBox(height: 12),
            if (kDebugMode)
              const Text('These values are stored locally in SharedPreferences for development only.', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
