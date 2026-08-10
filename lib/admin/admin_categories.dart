import 'package:flutter/material.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final TextEditingController _categoryController = TextEditingController();
  final List<Map<String, dynamic>> _categories = [
    {'id': '1', 'name': 'Plumber', 'icon': '🔧', 'jobs': 145, 'active': true},
    {'id': '2', 'name': 'Electrician', 'icon': '⚡', 'jobs': 98, 'active': true},
    {'id': '3', 'name': 'Cleaner', 'icon': '🧹', 'jobs': 76, 'active': true},
    {'id': '4', 'name': 'Painter', 'icon': '🎨', 'jobs': 54, 'active': true},
    {'id': '5', 'name': 'Carpenter', 'icon': '🔨', 'jobs': 43, 'active': true},
    {'id': '6', 'name': 'Mechanic', 'icon': '🚗', 'jobs': 38, 'active': true},
    {'id': '7', 'name': 'Gardener', 'icon': '🌿', 'jobs': 29, 'active': true},
    {'id': '8', 'name': 'Tutor', 'icon': '📚', 'jobs': 21, 'active': true},
  ];

  void _addCategory() {
    if (_categoryController.text.trim().isEmpty) return;

    setState(() {
      _categories.add({
        'id': DateTime.now().toString(),
        'name': _categoryController.text.trim(),
        'icon': '📌',
        'jobs': 0,
        'active': true,
      });
      _categoryController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Category added successfully'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  void _toggleCategoryStatus(Map<String, dynamic> category) {
    setState(() {
      category['active'] = !category['active'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${category['name']} ${category['active'] ? 'activated' : 'deactivated'}',
        ),
        backgroundColor: category['active'] ? Colors.green : Colors.orange,
      ),
    );
  }

  void _deleteCategory(Map<String, dynamic> category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${category['name']}'),
        content: Text(
          'Are you sure you want to delete "${category['name']}" category?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.remove(category);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category deleted successfully'),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Manage Service Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add, edit, or remove service categories',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _categoryController,
                  hintText: 'Enter new category name',
                  onSubmitted: (_) => _addCategory(),
                ),
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'Add Category',
                onPressed: _addCategory,
                width: 150,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _categories.isEmpty
                ? const Center(child: Text('No categories added yet'))
                : ListView.builder(
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryCard(category);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: category['active']
                    ? Colors.green.shade100
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  category['icon'],
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: category['active'] ? Colors.black : Colors.grey,
                    ),
                  ),
                  Text(
                    '${category['jobs']} jobs • ${category['active'] ? 'Active' : 'Inactive'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: category['active'] ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                category['active'] ? Icons.visibility : Icons.visibility_off,
                color: category['active'] ? Colors.green : Colors.grey,
                size: 20,
              ),
              onPressed: () => _toggleCategoryStatus(category),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
              onPressed: () => _editCategory(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteCategory(category),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategory(Map<String, dynamic> category) {
    final TextEditingController editController = TextEditingController(
      text: category['name'],
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${category['name']}'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (editController.text.trim().isNotEmpty) {
                setState(() {
                  category['name'] = editController.text.trim();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Category updated successfully'),
                    backgroundColor: Color(0xFF00C853),
                  ),
                );
              }
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
}
