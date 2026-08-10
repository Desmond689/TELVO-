import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/admin/admin_users.dart';
import 'package:telvo/admin/admin_professionals.dart';
import 'package:telvo/admin/admin_jobs.dart';
import 'package:telvo/admin/admin_payments.dart';
import 'package:telvo/admin/admin_analytics.dart';
import 'package:telvo/admin/admin_verification.dart';
import 'package:telvo/admin/admin_disputes.dart';
import 'package:telvo/admin/admin_fraud.dart';
import 'package:telvo/admin/admin_promotions.dart';
import 'package:telvo/admin/admin_settings.dart';
import 'package:telvo/admin/admin_reviews.dart';
import 'package:telvo/admin/admin_categories.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _menuItems = [
    {
      'icon': Icons.dashboard,
      'label': 'Dashboard',
      'widget': const _DashboardContent(),
    },
    {
      'icon': Icons.people,
      'label': 'Users',
      'widget': const AdminUsersScreen(),
    },
    {
      'icon': Icons.construction,
      'label': 'Professionals',
      'widget': const AdminProfessionalsScreen(),
    },
    {'icon': Icons.work, 'label': 'Jobs', 'widget': const AdminJobsScreen()},
    {
      'icon': Icons.payment,
      'label': 'Payments',
      'widget': const AdminPaymentsScreen(),
    },
    {
      'icon': Icons.star,
      'label': 'Reviews',
      'widget': const AdminReviewsScreen(),
    },
    {
      'icon': Icons.category,
      'label': 'Categories',
      'widget': const AdminCategoriesScreen(),
    },
    {
      'icon': Icons.analytics,
      'label': 'Analytics',
      'widget': const AdminAnalyticsScreen(),
    },
    {
      'icon': Icons.verified,
      'label': 'Verification',
      'widget': const AdminVerificationScreen(),
    },
    {
      'icon': Icons.gavel,
      'label': 'Disputes',
      'widget': const AdminDisputesScreen(),
    },
    {
      'icon': Icons.security,
      'label': 'Fraud Detection',
      'widget': const AdminFraudDetectionScreen(),
    },
    {
      'icon': Icons.local_offer,
      'label': 'Promotions',
      'widget': const AdminPromotionsScreen(),
    },
    {
      'icon': Icons.settings,
      'label': 'Settings',
      'widget': const AdminSettingsScreen(),
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final admin = adminProvider.currentAdmin;

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildHeader(admin),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: _menuItems
                        .map((item) => item['widget'] as Widget)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildSidebarHeader(),
          const Divider(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00C853).withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    leading: Icon(
                      item['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF00C853)
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    title: Text(
                      item['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF00C853)
                            : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      _pageController.jumpToPage(index);
                    },
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _buildLogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: Color(0xFF00C853), size: 32),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Telvo Admin',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
                ),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic admin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _buildHeaderButton(Icons.refresh, 'Refresh', () {
            context.read<AdminProvider>().loadDashboardStats();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Refreshing data...'),
                duration: Duration(seconds: 1),
                backgroundColor: Color(0xFF00C853),
              ),
            );
          }),
          const SizedBox(width: 8),
          _buildHeaderButton(Icons.notifications, 'Notifications', () {
            // Show notifications
          }),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF00C853),
                    child: Text(
                      admin?.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    admin?.fullName ?? 'Admin',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.grey.shade700),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text(
        'Logout',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
      ),
      onTap: _showLogoutDialog,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout from the admin panel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<AdminProvider>().logoutAdmin();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logged out successfully'),
                  backgroundColor: Color(0xFF00C853),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// Dashboard Content
class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    final adminProvider = context.watch<AdminProvider>();
    final stats = adminProvider.stats;

    if (adminProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back! Here\'s what\'s happening with your platform.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                title: 'Total Users',
                value: stats.totalUsers.toString(),
                icon: Icons.people,
                color: Colors.blue,
                subtitle: 'Registered users',
                change: '+12%',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Professionals',
                value: stats.totalProfessionals.toString(),
                icon: Icons.construction,
                color: Colors.orange,
                subtitle: 'Active professionals',
                change: '+8%',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Total Jobs',
                value: stats.totalJobs.toString(),
                icon: Icons.work,
                color: Colors.green,
                subtitle: 'All time jobs',
                change: '+15%',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Revenue',
                value: 'XAF ${stats.totalRevenue.toString()}',
                icon: Icons.money,
                color: Colors.purple,
                subtitle: 'Total revenue',
                change: '+25%',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Pending Verifications',
                value: stats.pendingVerifications.toString(),
                icon: Icons.pending,
                color: Colors.red,
                subtitle: 'Awaiting review',
                change: '-5',
                isPositive: false,
              ),
              _buildStatCard(
                title: 'Verified Professionals',
                value: stats.verifiedVerifications.toString(),
                icon: Icons.verified,
                color: Colors.green,
                subtitle: 'Verified accounts',
                change: '+8',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Rejected Verifications',
                value: stats.rejectedVerifications.toString(),
                icon: Icons.cancel,
                color: Colors.deepOrange,
                subtitle: 'Rejected requests',
                change: '-1',
                isPositive: false,
              ),
              _buildStatCard(
                title: 'Active Jobs',
                value: stats.activeJobs.toString(),
                icon: Icons.play_circle,
                color: Colors.teal,
                subtitle: 'In progress',
                change: '+3',
                isPositive: true,
              ),
              _buildStatCard(
                title: 'Disputes',
                value: stats.disputes.toString(),
                icon: Icons.gavel,
                color: Colors.deepOrange,
                subtitle: 'Open disputes',
                change: '-2',
                isPositive: false,
              ),
              _buildStatCard(
                title: 'Fraud Reports',
                value: stats.fraudReports.toString(),
                icon: Icons.security,
                color: Colors.redAccent,
                subtitle: 'Pending review',
                change: '+2',
                isPositive: false,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildCategoryChart(stats)),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentActivity(stats)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    required String change,
    required bool isPositive,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChart(dynamic stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jobs by Category',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: stats.categoryStats.entries.map((entry) {
                final percentage = stats.totalJobs > 0
                    ? (entry.value / stats.totalJobs * 100).round()
                    : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${entry.value} jobs',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade600,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 50,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.green.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Container(
                          width: (50 * (percentage / 100)).toDouble(),
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(dynamic stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (stats.recentActivity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No recent activity'),
                ),
              )
            else
              Column(
                children: stats.recentActivity.take(5).map((activity) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getActivityColor(activity['type']),
                      radius: 18,
                      child: Icon(
                        _getActivityIcon(activity['type']),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      activity['title'] ?? 'Activity',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      activity['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Text(
                      _formatTime(activity['time']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'user':
        return Colors.blue;
      case 'job':
        return Colors.green;
      case 'payment':
        return Colors.purple;
      case 'dispute':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'user':
        return Icons.person_add;
      case 'job':
        return Icons.work;
      case 'payment':
        return Icons.payment;
      case 'dispute':
        return Icons.gavel;
      default:
        return Icons.info;
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return 'Just now';
    try {
      final diff = DateTime.now().difference(time);
      if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}
