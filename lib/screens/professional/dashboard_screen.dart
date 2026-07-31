import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/providers/payment_provider.dart';
import 'package:telvo/config/routes.dart';

class ProfessionalDashboardScreen extends StatefulWidget {
  const ProfessionalDashboardScreen({super.key});

  @override
  State<ProfessionalDashboardScreen> createState() =>
      _ProfessionalDashboardScreenState();
}

class _ProfessionalDashboardScreenState
    extends State<ProfessionalDashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId == null) {
      setState(() => _isLoadingData = false);
      return;
    }
    await Future.wait([
      context.read<JobProvider>().loadProfessionalJobs(userId),
      context.read<PaymentProvider>().loadProfessionalPayments(userId),
    ]);
    if (mounted) setState(() => _isLoadingData = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(user),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStats(user),
                      const SizedBox(height: 24),
                      _buildQuickActions(),
                      const SizedBox(height: 24),
                      _buildRecentJobs(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.jobFeed);
        },
        backgroundColor: const Color(0xFF00C853),
        child: const Icon(Icons.search),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader(UserModel? user) => Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: user?.profilePhoto != null
              ? NetworkImage(user!.profilePhoto!)
              : null,
          child: user?.profilePhoto == null
              ? const Icon(Icons.person, size: 32)
              : null,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello ${user?.fullName ?? 'Professional'}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: (user?.isOnline ?? false)
                        ? const Color(0xFF00C853)
                        : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  (user?.isOnline ?? false) ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.notifications);
          },
          icon: const Icon(Icons.notifications_outlined, size: 28),
        ),
      ],
    ),
  );

  Widget _buildStats(UserModel? user) {
    final payments = context.watch<PaymentProvider>().payments;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = startOfDay.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month);

    double sumSince(DateTime cutoff) => payments
        .where((p) => (p.createdAt ?? now).isAfter(cutoff))
        .fold(0.0, (sum, p) => sum + (p.amount ?? 0));

    final stats = [
      {
        'label': "Today's Earnings",
        'value': _formatXaf(sumSince(startOfDay)),
        'icon': Icons.today,
        'color': const Color(0xFF00C853),
      },
      {
        'label': 'Weekly Earnings',
        'value': _formatXaf(sumSince(startOfWeek)),
        'icon': Icons.weekend,
        'color': const Color(0xFF2196F3),
      },
      {
        'label': 'Monthly Earnings',
        'value': _formatXaf(sumSince(startOfMonth)),
        'icon': Icons.calendar_today,
        'color': const Color(0xFFFF9800),
      },
      {
        'label': 'Rating',
        'value': user?.rating != null
            ? '${user!.rating!.toStringAsFixed(1)} \u2b50'
            : 'No ratings yet',
        'icon': Icons.star,
        'color': const Color(0xFFFFC107),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatXaf(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );
    return 'XAF $formatted';
  }

  Widget _buildQuickActions() => Row(
    children: [
      Expanded(
        child: _buildActionCard(
          'Job Feed',
          Icons.work,
          const Color(0xFF00C853),
          () => Navigator.pushNamed(context, AppRoutes.jobFeed),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildActionCard(
          'Availability',
          Icons.toggle_on,
          const Color(0xFF2196F3),
          () => Navigator.pushNamed(context, AppRoutes.availability),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildActionCard(
          'Earnings',
          Icons.money,
          const Color(0xFFFF9800),
          () => Navigator.pushNamed(context, AppRoutes.earnings),
        ),
      ),
    ],
  );

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildRecentJobs() {
    final allJobs = context.watch<JobProvider>().myJobs;
    final recentJobs = allJobs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Jobs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (allJobs.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.jobHistory,
                  arguments: allJobs,
                ),
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isLoadingData)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (recentJobs.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No jobs yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentJobs.length,
            itemBuilder: (context, index) => _buildJobTile(recentJobs[index]),
          ),
      ],
    );
  }

  Widget _buildJobTile(JobModel job) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const Icon(Icons.work, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.serviceType ?? job.category ?? 'Service',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Status: ${_statusLabel(job.status)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (job.budget != null)
          Text(
            _formatXaf(job.budget!),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF00C853),
            ),
          ),
      ],
    ),
  );

  String _statusLabel(String? status) {
    if (status == null || status.isEmpty) return 'Unknown';
    return status
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  Widget _buildBottomNavigationBar() => BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: (index) {
      setState(() {
        _selectedIndex = index;
      });
      switch (index) {
        case 0:
          break;
        case 1:
          Navigator.pushNamed(context, AppRoutes.jobFeed);
          break;
        case 2:
          Navigator.pushNamed(context, AppRoutes.earnings);
          break;
        case 3:
          Navigator.pushNamed(context, AppRoutes.profile);
          break;
      }
    },
    type: BottomNavigationBarType.fixed,
    selectedItemColor: const Color(0xFF00C853),
    unselectedItemColor: Colors.grey,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
      BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Jobs'),
      BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Earnings'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
