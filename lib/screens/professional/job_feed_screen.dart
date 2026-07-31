import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/widgets/empty_state.dart';
import 'package:telvo/widgets/job_card.dart';
import 'package:telvo/widgets/custom_button.dart';

class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});

  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'Cleaning',
    'Painting',
  ];
  String _selectedCategory = 'All';
  bool _showOnlyNearby = false;

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Feed'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showOnlyNearby = !_showOnlyNearby;
              });
            },
            icon: Icon(
              _showOnlyNearby ? Icons.location_on : Icons.location_off,
              color: _showOnlyNearby ? const Color(0xFF00C853) : null,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await jobProvider.refreshJobs();
              },
              child: jobProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : jobProvider.jobs.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: jobProvider.jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobProvider.jobs[index];
                        return JobCard(
                          job: job,
                          onTap: () {
                            _showJobDetails(job);
                          },
                          showAction: true,
                          onAction: () {
                            _showQuoteDialog(job);
                          },
                          actionText: 'Send Quote',
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() => Container(
    height: 50,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final isSelected = _selectedCategory == category;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedCategory = selected ? category : 'All';
              });
              // Filter jobs by category
            },
            selectedColor: const Color(0xFF00C853),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        );
      },
    ),
  );

  Widget _buildEmptyState() => const EmptyState(
    title: 'No jobs available',
    subtitle: 'Check back later for new opportunities',
    imagePath: 'assets/images/empty_state.png',
  );

  void _showJobDetails(JobModel job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                job.category ?? 'Service',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.description ?? 'No description provided',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Color(0xFF00C853)),
                  const SizedBox(width: 4),
                  Text(
                    'Budget: XAF ${job.budget?.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.timer, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    job.urgency ?? 'Flexible',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (job.photos?.isNotEmpty ?? false) ...[
                const Text(
                  'Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: job.photos!.length,
                    itemBuilder: (context, index) {
                      return Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: Center(
                          child: Icon(Icons.image, color: Colors.grey.shade400),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CustomButton(
                text: 'Send Quote',
                onPressed: () {
                  Navigator.pop(context);
                  _showQuoteDialog(job);
                },
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: 'Chat with Customer',
                isOutlined: true,
                onPressed: () {
                  Navigator.pop(context);
                  if (job.customerId != null) {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: job.customerId,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuoteDialog(JobModel job) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quote'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (XAF)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estimated Time (hours)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  border: OutlineInputBorder(),
                ),
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
            onPressed: () async {
              final currentUserId = context
                  .read<AuthProvider>()
                  .currentUser
                  ?.id;
              if (currentUserId == null) {
                Navigator.pop(context);
                return;
              }

              final price = double.tryParse(priceController.text.trim()) ?? 0;
              final estimatedTime =
                  int.tryParse(timeController.text.trim()) ?? 0;
              final message = messageController.text.trim();

              if (price <= 0 || estimatedTime <= 0 || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all quote fields.'),
                  ),
                );
                return;
              }

              Navigator.pop(context);
              try {
                await context.read<JobProvider>().sendQuote(
                  QuoteModel(
                    professionalId: currentUserId,
                    jobId: job.id,
                    price: price,
                    estimatedTime: estimatedTime,
                    message: message,
                    status: 'pending',
                    createdAt: DateTime.now(),
                  ),
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Quote sent successfully!')),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send quote: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
            ),
            child: const Text('Send Quote'),
          ),
        ],
      ),
    );
  }
}
