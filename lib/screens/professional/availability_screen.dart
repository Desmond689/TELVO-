import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/widgets/custom_button.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  String _availabilityStatus = 'Online';
  final Map<String, Map<String, bool>> _schedule = {};
  bool _isLoading = false;
  bool _scheduleInitialized = false;

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _timeSlots = ['Morning', 'Afternoon', 'Evening', 'Night'];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _scheduleInitialized) return;

    _initializeSchedule(initialSchedule: user.availabilitySchedule);
    _scheduleInitialized = true;

    if (user.availabilityStatus != null) {
      _availabilityStatus = user.availabilityStatus!;
    } else if (user.isOnline) {
      _availabilityStatus = 'Online';
    } else {
      _availabilityStatus = 'Offline';
    }
  }

  void _initializeSchedule({Map<String, dynamic>? initialSchedule}) {
    for (final day in _days) {
      _schedule[day] = {};
      final daySchedule = initialSchedule?[day] as Map<String, dynamic>?;
      for (final slot in _timeSlots) {
        _schedule[day]![slot] = daySchedule?[slot] == true;
      }
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    await authProvider.updateProfile({
      'availabilitySchedule': _schedule,
      'availabilityStatus': _availabilityStatus,
      'isOnline': _availabilityStatus == 'Online',
    });

    if (mounted) {
      setState(() => _isLoading = false);

      if (authProvider.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated successfully')),
        );
        Navigator.pop(context);
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
      title: const Text('Availability'),
      elevation: 0,
      actions: [
        IconButton(onPressed: _saveAvailability, icon: const Icon(Icons.save)),
      ],
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusSelector(),
          const SizedBox(height: 24),
          const Text(
            'Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildScheduleTable(),
          const SizedBox(height: 24),
          CustomButton(
            text: _isLoading ? 'Saving...' : 'Save Availability',
            onPressed: _isLoading ? null : _saveAvailability,
          ),
        ],
      ),
    ),
  );

  Widget _buildStatusSelector() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Status',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatusChip('Online', Colors.green),
            const SizedBox(width: 8),
            _buildStatusChip('Offline', Colors.red),
            const SizedBox(width: 8),
            _buildStatusChip('Busy', Colors.orange),
            const SizedBox(width: 8),
            _buildStatusChip('Away', Colors.blue),
          ],
        ),
      ],
    ),
  );

  Widget _buildStatusChip(String label, Color color) {
    final isSelected = _availabilityStatus == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _availabilityStatus = selected ? label : 'Online';
        });
      },
      selectedColor: color,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
    );
  }

  Widget _buildScheduleTable() => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        _buildScheduleHeader(),
        ..._days.map((day) => _buildScheduleRow(day)),
      ],
    ),
  );

  Widget _buildScheduleHeader() => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 60,
          child: const Text(
            'Day',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ..._timeSlots.map((slot) {
          return Expanded(
            child: Text(
              slot,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              textAlign: TextAlign.center,
            ),
          );
        }),
      ],
    ),
  );

  Widget _buildScheduleRow(String day) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(day, style: const TextStyle(fontSize: 12)),
        ),
        ..._timeSlots.map((slot) {
          final isAvailable = _schedule[day]?[slot] ?? false;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _schedule[day]![slot] = !isAvailable;
                });
              },
              child: Container(
                height: 30,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isAvailable ? Colors.green : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    isAvailable ? Icons.check : Icons.close,
                    size: 14,
                    color: isAvailable ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
