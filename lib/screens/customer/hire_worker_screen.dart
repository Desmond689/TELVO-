import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/services/storage_service.dart';
import 'package:telvo/utils/app_colors.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/lookup_data.dart';

/// Dedicated Hire Worker flow (direct request to one professional).
class HireWorkerScreen extends StatefulWidget {
  const HireWorkerScreen({super.key, this.professionalId});

  final String? professionalId;

  @override
  State<HireWorkerScreen> createState() => _HireWorkerScreenState();
}

class _HireWorkerScreenState extends State<HireWorkerScreen> {
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();
  final _storage = StorageService();

  UserModel? _worker;
  String? _serviceType; // Repair / Installation / Maintenance
  String? _category;
  String _schedule = 'Today';
  String _preferredTime = '10:00 AM';
  String _paymentMethod = 'Cash';
  List<XFile> _photos = [];
  bool _loadingWorker = true;
  bool _submitting = false;
  bool _usingCurrentLocation = false;

  static const _serviceTypes = ['Repair', 'Installation', 'Maintenance'];
  static const _times = [
    '8:00 AM',
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '12:00 PM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
    '5:00 PM',
    '6:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorker());
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _budgetController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadWorker() async {
    final id = widget.professionalId ??
        (ModalRoute.of(context)?.settings.arguments as String?);
    if (id == null || id.isEmpty) {
      setState(() => _loadingWorker = false);
      return;
    }
    try {
      final user = await context.read<UserProvider>().getUserById(id);
      if (!mounted) return;
      setState(() {
        _worker = user;
        _category = user?.category;
        _loadingWorker = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWorker = false);
    }
  }

  Future<void> _pickPhotos() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images.isEmpty) return;
      setState(() {
        _photos = [..._photos, ...images].take(6).toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyErrorMessage(e))),
      );
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _usingCurrentLocation = true);
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
      final pos = await Geolocator.getCurrentPosition();
      // Best-effort label — store coordinates in address text if no geocoder
      setState(() {
        _addressController.text =
            'Lat ${pos.latitude.toStringAsFixed(4)}, Lng ${pos.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _usingCurrentLocation = false);
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final customer = auth.currentUser;
    if (customer?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to hire a worker.')),
      );
      return;
    }
    if (_worker?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker not found.')),
      );
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe what you need help with.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final jobProvider = context.read<JobProvider>();
      final category = _category ?? _worker!.category ?? 'General';
      final serviceLabel = _serviceType != null ? '$_serviceType · $category' : category;
      final scheduleLine = '$_schedule at $_preferredTime';
      final description = '''
${_descriptionController.text.trim()}

Schedule: $scheduleLine
Payment: $_paymentMethod
'''.trim();

      final hire = await jobProvider.sendHireRequest(
        customerId: customer!.id!,
        customerName: customer.fullName ?? 'Customer',
        professionalId: _worker!.id!,
        professionalName: _worker!.fullName,
        category: serviceLabel,
        description: description,
        budget: double.tryParse(_budgetController.text.trim()) ?? 0,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        preferredDate: _schedule,
        preferredTime: _preferredTime,
        paymentMethod: _paymentMethod,
        serviceType: _serviceType,
      );

      if (hire == null) {
        throw Exception(jobProvider.error ?? 'Could not send hire request');
      }

      // Upload photos after we have an id (folder namespaced by hire id)
      if (_photos.isNotEmpty && hire.id != null) {
        try {
          final urls = <String>[];
          for (var i = 0; i < _photos.length; i++) {
            final url = await _storage.uploadFileDirect(
              file: File(_photos[i].path),
              folder: 'hire_photos/${hire.id}',
              fileName: '$i.jpg',
            );
            if (url != null) urls.add(url);
          }
          if (urls.isNotEmpty) {
            await jobProvider.updateHireRequestPhotos(hire.id!, urls);
          }
        } catch (e) {
          // Hire already sent — warn about photos only
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Request sent, but photos failed: ${getFriendlyErrorMessage(e)}',
                ),
              ),
            );
          }
        }
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Request Sent ✅'),
          content: Text(
            '${_worker!.fullName ?? "The worker"} has received your request.\n\n'
            'You can chat after they accept.\n\n'
            'Status: Waiting for response',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Done'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getFriendlyErrorMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hire Worker'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _loadingWorker
          ? const Center(child: CircularProgressIndicator())
          : _worker == null
              ? const Center(child: Text('Worker not found'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        children: [
                          _buildWorkerCard(theme),
                          const SizedBox(height: 20),
                          _sectionTitle('What do you need help with?'),
                          const SizedBox(height: 8),
                          _buildServiceChips(),
                          const SizedBox(height: 10),
                          _buildCategoryField(),
                          const SizedBox(height: 20),
                          _sectionTitle('Describe your problem'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'My kitchen sink is leaking and needs repair.',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Add photos'),
                          const SizedBox(height: 8),
                          _buildPhotos(),
                          const SizedBox(height: 20),
                          _sectionTitle('Where should the work be done?'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed:
                                _usingCurrentLocation ? null : _useCurrentLocation,
                            icon: _usingCurrentLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location_rounded),
                            label: const Text('Use current location'),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _addressController,
                            decoration: InputDecoration(
                              hintText: 'Enter address (e.g. Molyko, Buea)',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('When do you need it?'),
                          const SizedBox(height: 8),
                          _buildScheduleChips(),
                          const SizedBox(height: 12),
                          _sectionTitle('Preferred time'),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _preferredTime,
                            items: _times
                                .map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _preferredTime = v ?? _preferredTime),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Your expected budget (optional)'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '15,000 XAF',
                              prefixText: 'XAF ',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '💡 Worker can suggest a different price',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _sectionTitle('Payment method'),
                          const SizedBox(height: 4),
                          ...['Cash', 'MTN MoMo', 'Orange Money'].map(
                            (m) => RadioListTile<String>(
                              value: m,
                              groupValue: _paymentMethod,
                              title: Text(m),
                              onChanged: (v) =>
                                  setState(() => _paymentMethod = v ?? m),
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Send Hire Request',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      );

  Widget _buildWorkerCard(ThemeData theme) {
    final w = _worker!;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: w.profilePhoto != null && w.profilePhoto!.isNotEmpty
                ? NetworkImage(w.profilePhoto!)
                : null,
            child: (w.profilePhoto == null || w.profilePhoto!.isEmpty)
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  w.fullName ?? 'Worker',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      w.rating != null
                          ? '${w.rating!.toStringAsFixed(1)} (${w.jobsCompleted ?? 0} jobs)'
                          : 'New',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                if (w.category != null) ...[
                  const SizedBox(height: 2),
                  Text(w.category!,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      )),
                ],
                if (w.city != null) ...[
                  const SizedBox(height: 2),
                  Text(w.city!,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceChips() {
    return Wrap(
      spacing: 8,
      children: _serviceTypes.map((s) {
        final selected = _serviceType == s;
        return ChoiceChip(
          label: Text(s),
          selected: selected,
          onSelected: (_) => setState(() => _serviceType = s),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryField() {
    final cats = LookupData.jobCategories;
    return DropdownButtonFormField<String>(
      value: cats.contains(_category) ? _category : null,
      hint: const Text('Service category'),
      items: cats
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _category = v),
      decoration: InputDecoration(
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildScheduleChips() {
    return Wrap(
      spacing: 8,
      children: ['Today', 'Tomorrow', 'Pick date'].map((s) {
        final selected = _schedule == s;
        return ChoiceChip(
          label: Text(s),
          selected: selected,
          onSelected: (_) async {
            if (s == 'Pick date') {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                initialDate: DateTime.now().add(const Duration(days: 2)),
              );
              if (date != null) {
                setState(() {
                  _schedule =
                      '${date.day}/${date.month}/${date.year}';
                });
              }
            } else {
              setState(() => _schedule = s);
            }
          },
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add Photos'),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(_photos[i].path),
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 2,
                      child: GestureDetector(
                        onTap: () => setState(() => _photos.removeAt(i)),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
