import 'package:flutter/material.dart';
import 'package:telvo/utils/helpers.dart';
import 'package:telvo/widgets/custom_button.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Emergency'),
          elevation: 0,
          backgroundColor: Colors.red,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildEmergencyHeader(),
                const SizedBox(height: 24),
                _buildEmergencyContacts(context),
                const SizedBox(height: 24),
                _buildEmergencyServices(context),
                const SizedBox(height: 24),
                _buildSafetyTips(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Call Emergency Services',
                  backgroundColor: Colors.red,
                  onPressed: () => Helpers.callNumber(context, '150'),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmergencyHeader() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    'Get immediate help in case of emergency',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmergencyContacts(BuildContext context) => Container(
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
              'Quick Emergency Contacts',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContactTile(
              context,
              'Police',
              '117',
              Icons.local_police,
              Colors.blue,
            ),
            _buildContactTile(
              context,
              'Ambulance',
              '119',
              Icons.local_hospital,
              Colors.red,
            ),
            _buildContactTile(
              context,
              'Fire',
              '118',
              Icons.fire_extinguisher,
              Colors.orange,
            ),
            _buildContactTile(
              context,
              'SOS Hotline',
              '150',
              Icons.phone,
              Colors.purple,
            ),
          ],
        ),
      );

  Widget _buildContactTile(
    BuildContext context,
    String title,
    String number,
    IconData icon,
    Color color,
  ) =>
      ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(number),
        trailing: IconButton(
          onPressed: () => Helpers.callNumber(context, number),
          icon: const Icon(Icons.call, color: Colors.green),
        ),
      );

  Widget _buildEmergencyServices(BuildContext context) {
    final services = [
      {
        'title': 'Police',
        'icon': Icons.local_police,
        'color': Colors.blue,
        'number': '117',
      },
      {
        'title': 'Ambulance',
        'icon': Icons.local_hospital,
        'color': Colors.red,
        'number': '119',
      },
      {
        'title': 'Fire',
        'icon': Icons.fire_extinguisher,
        'color': Colors.orange,
        'number': '118',
      },
      {
        'title': 'SOS',
        'icon': Icons.sos,
        'color': Colors.purple,
        'number': '150',
      },
    ];

    return Container(
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
            'Emergency Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return GestureDetector(
                onTap: () =>
                    Helpers.callNumber(context, service['number'] as String),
                child: Container(
                  decoration: BoxDecoration(
                    color: (service['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (service['color'] as Color).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        service['icon'] as IconData,
                        color: service['color'] as Color,
                        size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: service['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTips() {
    final tips = [
      'Always verify professional credentials before hiring',
      'Share your location with trusted contacts',
      'Use the SOS button in case of emergency',
      'Report suspicious behavior immediately',
      'Keep emergency contacts updated',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Colors.orange),
              const SizedBox(width: 8),
              const Text(
                'Safety Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
