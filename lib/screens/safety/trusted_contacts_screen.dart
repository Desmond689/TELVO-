import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';

/// Manages the user's trusted emergency contacts (phone numbers), stored
/// on their profile. This is what the SOS screen's contact list and the
/// "Add More Contacts" flow actually point to - previously that flow
/// looped between /sos and /safety with no real screen at the end of it.
class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({super.key});

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  bool _isSaving = false;

  Future<void> _addContact() async {
    final controller = TextEditingController();
    final number = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add trusted contact'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: 'Phone number',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (number == null || number.isEmpty || !mounted) return;

    final authProvider = context.read<AuthProvider>();
    final current = List<String>.from(
      authProvider.currentUser?.trustedContacts ?? [],
    );

    if (current.contains(number)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That contact is already saved.')),
      );
      return;
    }

    current.add(number);
    await _save(current);
  }

  Future<void> _removeContact(String number) async {
    final authProvider = context.read<AuthProvider>();
    final current = List<String>.from(
      authProvider.currentUser?.trustedContacts ?? [],
    )..remove(number);
    await _save(current);
  }

  Future<void> _save(List<String> contacts) async {
    setState(() => _isSaving = true);
    final authProvider = context.read<AuthProvider>();
    await authProvider.updateProfile({'trustedContacts': contacts});
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't save. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = context.watch<AuthProvider>().currentUser?.trustedContacts ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Contacts'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'These contacts are shown on your SOS screen so you can reach '
              'them quickly in an emergency.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            size: 56,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 12),
                          const Text('No trusted contacts yet.'),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final number = contacts[index];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(number),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _isSaving
                                ? null
                                : () => _removeContact(number),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _addContact,
        icon: const Icon(Icons.add),
        label: const Text('Add contact'),
      ),
    );
  }
}
