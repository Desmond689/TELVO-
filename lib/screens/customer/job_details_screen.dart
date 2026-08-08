import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/utils/app_colors.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/quote_card.dart';

class JobDetailsScreen extends StatefulWidget {
  const JobDetailsScreen({super.key});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  JobModel? _job;
  List<QuoteModel> _quotes = [];
  bool _loadingQuotes = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is JobModel) {
        _job = args;
      }
      setState(() {});
      _loadQuotes();
      _refreshJob();
    });
  }

  Future<void> _refreshJob() async {
    final id = _job?.id;
    if (id == null) return;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('jobs').doc(id).get();
      if (doc.exists && mounted) {
        setState(() {
          _job = JobModel.fromMap({...doc.data()!, 'id': doc.id});
        });
      }
    } catch (_) {}
  }

  Future<void> _loadQuotes() async {
    final id = _job?.id;
    if (id == null) return;
    setState(() => _loadingQuotes = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('quotes')
          .where('jobId', isEqualTo: id)
          .orderBy('createdAt', descending: true)
          .get();
      if (!mounted) return;
      setState(() {
        _quotes = snap.docs
            .map((d) => QuoteModel.fromMap({...d.data(), 'id': d.id}))
            .toList();
      });
    } catch (e) {
      // Fallback: embedded quotes on job
      if (_job?.quotes != null) {
        setState(() => _quotes = List<QuoteModel>.from(_job!.quotes!));
      }
    } finally {
      if (mounted) setState(() => _loadingQuotes = false);
    }
  }

  Future<void> _accept(QuoteModel quote) async {
    final jobId = _job?.id;
    final quoteId = quote.id;
    if (jobId == null || quoteId == null) return;
    final provider = context.read<JobProvider>();
    await provider.acceptQuote(jobId, quoteId);
    if (!mounted) return;
    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote accepted. Other quotes rejected.')),
    );
    await _refreshJob();
    await _loadQuotes();
  }

  Future<void> _reject(QuoteModel quote) async {
    final jobId = _job?.id;
    final quoteId = quote.id;
    if (jobId == null || quoteId == null) return;
    final provider = context.read<JobProvider>();
    await provider.rejectQuote(jobId, quoteId);
    if (!mounted) return;
    await _loadQuotes();
  }

  @override
  Widget build(BuildContext context) {
    if (_job == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final auth = context.watch<AuthProvider>();
    final isOwner = auth.currentUser?.id != null &&
        auth.currentUser!.id == _job!.customerId;
    final hasWorker = _job?.professionalId?.isNotEmpty ?? false;
    final status = (_job?.status ?? '').toLowerCase();
    final canAcceptQuotes = isOwner &&
        !hasWorker &&
        {'posted', 'open', 'quotes_received', 'notified'}.contains(status);

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshJob();
          await _loadQuotes();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              _job?.category ?? 'Service',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_job?.professionalName != null) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: (_job!.professionalImage != null &&
                            _job!.professionalImage!.isNotEmpty)
                        ? NetworkImage(_job!.professionalImage!)
                        : null,
                    child: (_job!.professionalImage == null)
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assigned: ${_job!.professionalName}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (_job?.budget != null) ...[
              Text('Budget', style: TextStyle(color: Colors.grey.shade700)),
              Text(
                'XAF ${_job!.budget!.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
            Text('Description', style: TextStyle(color: Colors.grey.shade700)),
            Text(_job?.description ?? 'No description'),
            if (_job?.address != null) ...[
              const SizedBox(height: 12),
              Text('Location', style: TextStyle(color: Colors.grey.shade700)),
              Text(_job!.address!),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Quotes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Text('(${_quotes.length})'),
              ],
            ),
            const SizedBox(height: 12),
            if (_loadingQuotes)
              const Center(child: CircularProgressIndicator())
            else if (_quotes.isEmpty)
              Text(
                hasWorker
                    ? 'A worker has already been assigned.'
                    : 'No quotes yet. Waiting for professionals...',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              ..._quotes.map((q) {
                final pending =
                    (q.status ?? 'pending').toLowerCase() == 'pending';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: QuoteCard(
                    quote: q,
                    onAccept: canAcceptQuotes && pending
                        ? () => _accept(q)
                        : null,
                    onReject: canAcceptQuotes && pending
                        ? () => _reject(q)
                        : null,
                  ),
                );
              }),
            const SizedBox(height: 24),
            if (isOwner && !hasWorker) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Edit Job',
                      isOutlined: true,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.jobPost,
                          arguments: _job,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: 'Cancel Job',
                      backgroundColor: Colors.red,
                      isOutlined: true,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Cancel Job?'),
                            content: const Text(
                              'Are you sure you want to cancel this job?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('No'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text(
                                  'Yes',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && _job?.id != null) {
                          await context
                              .read<JobProvider>()
                              .cancelJob(_job!.id!);
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            if (isOwner &&
                (status == 'completed') &&
                _job?.id != null) ...[
              const SizedBox(height: 12),
              CustomButton(
                text: 'Leave Review',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.review,
                    arguments: _job,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
