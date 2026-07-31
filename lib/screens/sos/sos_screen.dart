import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/utils/helpers.dart';
import 'package:telvo/widgets/custom_button.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isSOSActive = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('SOS Emergency'),
      elevation: 0,
      backgroundColor: Colors.red,
    ),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _animation.value,
                        child: GestureDetector(
                          onTap: _toggleSOS,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSOSActive
                                  ? Colors.red
                                  : Colors.red.shade100,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: _isSOSActive
                                        ? Colors.white
                                        : Colors.red,
                                  ),
                                ),
                                Text(
                                  _isSOSActive ? 'ACTIVE' : 'TAP TO ACTIVATE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _isSOSActive
                                        ? Colors.white70
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_isSOSActive)
                    Column(
                      children: [
                        const Text(
                          'Emergency Alert Sent!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your emergency contacts have been notified',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'Cancel SOS',
                          backgroundColor: Colors.red,
                          onPressed: _toggleSOS,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          _buildEmergencyContacts(),
        ],
      ),
    ),
  );

  void _toggleSOS() {
    setState(() {
      _isSOSActive = !_isSOSActive;
    });

    if (_isSOSActive) {
      // Send SOS alert
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS Alert Sent! Emergency contacts notified.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmergencyContacts() {
    final contacts =
        context.watch<AuthProvider>().currentUser?.trustedContacts ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Contacts',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (contacts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No emergency contacts yet. Add one so you can reach them '
                'quickly here.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
          else
            ...contacts.map(
              (number) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(number),
                trailing: IconButton(
                  onPressed: () => Helpers.callNumber(context, number),
                  icon: const Icon(Icons.call, color: Colors.green),
                ),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.trustedContacts);
            },
            child: const Text('Add More Contacts'),
          ),
        ],
      ),
    );
  }
}
