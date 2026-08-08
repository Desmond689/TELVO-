import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/widgets/rating_stars.dart';

class AdminProfessionalsScreen extends StatefulWidget {
  const AdminProfessionalsScreen({super.key});

  @override
  State<AdminProfessionalsScreen> createState() =>
      _AdminProfessionalsScreenState();
}

class _AdminProfessionalsScreenState extends State<AdminProfessionalsScreen> {
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';

  final List<String> _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Mechanic',
    'Gardener',
    'Tutor',
    'Photographer',
    'Chef',
    'Babysitter',
  ];

  final List<String> _statusOptions = [
    'All',
    'Verified',
    'Pending',
    'Suspended',
    'Top Rated',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadProfessionals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final professionals = _filteredProfessionals(adminProvider.professionals);

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: adminProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : professionals.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: professionals.length,
                  itemBuilder: (context, index) {
                    return _buildProfessionalCard(professionals[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search professionals...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<String>(
            value: _filterCategory,
            items: _categories.map((category) {
              return DropdownMenuItem(value: category, child: Text(category));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterCategory = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _filterStatus,
            items: _statusOptions.map((status) {
              return DropdownMenuItem(value: status, child: Text(status));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _filterStatus = value!;
              });
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              // Export professionals
            },
            icon: const Icon(Icons.download),
            label: const Text('Export'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
          ),
        ],
      ),
    );
  }

  List<UserModel> _filteredProfessionals(List<UserModel> professionals) {
    var filtered = professionals;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((pro) {
        final name = pro.fullName?.toLowerCase() ?? '';
        final category = pro.category?.toLowerCase() ?? '';
        final skills = pro.skills?.join(' ').toLowerCase() ?? '';
        return name.contains(_searchQuery) ||
            category.contains(_searchQuery) ||
            skills.contains(_searchQuery);
      }).toList();
    }

    if (_filterCategory != 'All') {
      filtered = filtered
          .where((pro) => pro.category == _filterCategory)
          .toList();
    }

    switch (_filterStatus) {
      case 'Verified':
        filtered = filtered.where((pro) => pro.isVerified).toList();
        break;
      case 'Pending':
        filtered = filtered.where((pro) => !pro.isVerified).toList();
        break;
      case 'Top Rated':
        filtered = filtered.where((pro) => (pro.rating ?? 0) >= 4.5).toList();
        break;
      case 'Suspended':
        filtered = filtered.where((pro) => false).toList();
        break;
    }

    filtered.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));

    return filtered;
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No professionals found',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalCard(UserModel professional) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: professional.profilePhoto != null
                  ? NetworkImage(professional.profilePhoto!)
                  : null,
              child: professional.profilePhoto == null
                  ? Text(
                      professional.fullName?.substring(0, 1).toUpperCase() ??
                          '?',
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        professional.fullName ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (professional.isVerified)
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF00C853),
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      if ((professional.rating ?? 0) >= 4.5)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '⭐ Top Rated',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    professional.category ?? 'No category',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: (professional.skills ?? []).take(3).map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          skill,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      RatingStars(rating: professional.rating ?? 0, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        (professional.rating ?? 0).toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${professional.jobsCompleted ?? 0} jobs',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: professional.isOnline
                              ? Colors.green
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        professional.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: professional.isOnline
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${professional.serviceAreas?.length ?? 0} areas',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.visibility,
                        size: 20,
                        color: Colors.blue,
                      ),
                      onPressed: () => _viewProfessional(professional),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.verified,
                        size: 20,
                        color: Color(0xFF00C853),
                      ),
                      onPressed: () => _toggleVerification(professional),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.block,
                        size: 20,
                        color: Colors.orange,
                      ),
                      onPressed: () => _toggleStatus(professional),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewProfessional(UserModel professional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(professional.fullName ?? 'Professional'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', professional.category ?? 'N/A'),
              _buildDetailRow(
                'Experience',
                '${professional.yearsOfExperience ?? 0} years',
              ),
              _buildDetailRow(
                'Rating',
                professional.rating?.toStringAsFixed(1) ?? 'N/A',
              ),
              _buildDetailRow(
                'Jobs',
                professional.jobsCompleted?.toString() ?? '0',
              ),
              _buildDetailRow(
                'Response Rate',
                '${professional.responseRate ?? 0}%',
              ),
              _buildDetailRow(
                'Response Time',
                '${professional.responseTime ?? 0} min',
              ),
              _buildDetailRow('Skills', (professional.skills ?? []).join(', ')),
              _buildDetailRow(
                'Service Areas',
                (professional.serviceAreas ?? []).join(', '),
              ),
              _buildDetailRow(
                'Verified',
                professional.isVerified ? '✅ Yes' : '❌ No',
              ),
              _buildDetailRow('Phone', professional.phoneNumber ?? 'N/A'),
              _buildDetailRow('Email', professional.email ?? 'N/A'),
              _buildDetailRow('City', professional.city ?? 'N/A'),
              _buildDetailRow(
                'Neighborhood',
                professional.neighborhood ?? 'N/A',
              ),
              const SizedBox(height: 8),
              if (professional.description != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(professional.description!),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _toggleVerification(UserModel professional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          professional.isVerified
              ? 'Remove Verification'
              : 'Verify Professional',
        ),
        content: Text(
          professional.isVerified
              ? 'Are you sure you want to remove verification from ${professional.fullName}?'
              : 'Are you sure you want to verify ${professional.fullName} as a professional?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final adminProvider = context.read<AdminProvider>();
              adminProvider.toggleUserVerification(
                professional.id!,
                !professional.isVerified,
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    professional.isVerified
                        ? 'Verification removed'
                        : 'Professional verified',
                  ),
                  backgroundColor: const Color(0xFF00C853),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: Text(professional.isVerified ? 'Remove' : 'Verify'),
          ),
        ],
      ),
    );
  }

  void _toggleStatus(UserModel professional) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend Professional'),
        content: Text(
          'Are you sure you want to suspend ${professional.fullName}?'
          ' They will not be able to accept jobs.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${professional.fullName} has been suspended'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
  }
}
