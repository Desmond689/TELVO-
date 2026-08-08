import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class AdminPromotionsScreen extends StatefulWidget {
  const AdminPromotionsScreen({super.key});

  @override
  State<AdminPromotionsScreen> createState() => _AdminPromotionsScreenState();
}

class _AdminPromotionsScreenState extends State<AdminPromotionsScreen> {
  final List<Map<String, dynamic>> _promotions = [
    {
      'id': '1',
      'title': 'Weekend Special',
      'description': '20% off all plumbing services',
      'code': 'PLUMB20',
      'discount': 20,
      'type': 'percentage',
      'startDate': DateTime.now().subtract(const Duration(days: 2)),
      'endDate': DateTime.now().add(const Duration(days: 5)),
      'active': true,
      'usageLimit': 100,
      'usedCount': 45,
    },
    {
      'id': '2',
      'title': 'New User Offer',
      'description': 'XAF 5,000 off first job',
      'code': 'NEW5000',
      'discount': 5000,
      'type': 'fixed',
      'startDate': DateTime.now().subtract(const Duration(days: 10)),
      'endDate': DateTime.now().add(const Duration(days: 20)),
      'active': true,
      'usageLimit': 50,
      'usedCount': 12,
    },
    {
      'id': '3',
      'title': 'Referral Bonus',
      'description': 'Get XAF 2,000 for each referral',
      'code': 'REFER2000',
      'discount': 2000,
      'type': 'fixed',
      'startDate': DateTime.now().subtract(const Duration(days: 15)),
      'endDate': DateTime.now().add(const Duration(days: 30)),
      'active': false,
      'usageLimit': 200,
      'usedCount': 34,
    },
  ];

  void _showCreatePromotionDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController =
        TextEditingController();
    final TextEditingController codeController = TextEditingController();
    final TextEditingController discountController = TextEditingController();
    String type = 'percentage';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Promotion'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: titleController,
                  hintText: 'Promotion Title',
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: descriptionController,
                  hintText: 'Description',
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: codeController,
                  hintText: 'Promo Code',
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: discountController,
                  hintText: 'Discount Value',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage'),
                    ),
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('Fixed Amount'),
                    ),
                  ],
                  onChanged: (value) {
                    type = value!;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Discount Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              startDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Start: ${startDate.day}/${startDate.month}/${startDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() {
                              endDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'End: ${endDate.day}/${endDate.month}/${endDate.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _promotions.add({
                  'id': DateTime.now().toString(),
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'code': codeController.text,
                  'discount': double.parse(discountController.text),
                  'type': type,
                  'startDate': startDate,
                  'endDate': endDate,
                  'active': true,
                  'usageLimit': 100,
                  'usedCount': 0,
                });
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promotion created successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Promotions & Offers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              CustomButton(
                text: 'Create Promotion',
                onPressed: _showCreatePromotionDialog,
                width: 180,
                icon: Icons.add,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _promotions.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _promotions.length,
                    itemBuilder: (context, index) {
                      return _buildPromotionCard(_promotions[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No promotions created',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            'Create your first promotion to attract more customers',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promo) {
    final isActive = promo['active'];
    final isExpired = promo['endDate'].isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive && !isExpired
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    promo['type'] == 'percentage' ? '🎯' : '💰',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        promo['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        promo['description'],
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive && !isExpired
                        ? Colors.green.shade100
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive && !isExpired ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive && !isExpired
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Code',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        promo['code'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Discount',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        promo['type'] == 'percentage'
                            ? '${promo['discount']}%'
                            : 'XAF ${promo['discount']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF00C853),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Usage',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '${promo['usedCount']}/${promo['usageLimit']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isActive && !isExpired)
                  IconButton(
                    icon: const Icon(Icons.pause, color: Colors.orange),
                    onPressed: () {
                      setState(() {
                        promo['active'] = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promotion paused'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                  ),
                if (!isActive)
                  IconButton(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        promo['active'] = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Promotion activated'),
                          backgroundColor: Color(0xFF00C853),
                        ),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editPromotion(promo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePromotion(promo),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(promo['startDate'])} - ${_formatDate(promo['endDate'])}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isExpired ? Colors.red : Colors.grey.shade500,
                  ),
                ),
                if (isExpired) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Expired',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editPromotion(Map<String, dynamic> promo) {
    final TextEditingController titleController = TextEditingController(
      text: promo['title'],
    );
    final TextEditingController descriptionController = TextEditingController(
      text: promo['description'],
    );
    final TextEditingController codeController = TextEditingController(
      text: promo['code'],
    );
    final TextEditingController discountController = TextEditingController(
      text: promo['discount'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Promotion'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                controller: titleController,
                hintText: 'Promotion Title',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: descriptionController,
                hintText: 'Description',
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: codeController,
                hintText: 'Promo Code',
              ),
              const SizedBox(height: 8),
              CustomTextField(
                controller: discountController,
                hintText: 'Discount Value',
                keyboardType: TextInputType.number,
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
              setState(() {
                promo['title'] = titleController.text;
                promo['description'] = descriptionController.text;
                promo['code'] = codeController.text;
                promo['discount'] = double.parse(discountController.text);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promotion updated successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
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

  void _deletePromotion(Map<String, dynamic> promo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text(
          'Are you sure you want to delete "${promo['title']}" promotion?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _promotions.remove(promo);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Promotion deleted successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
