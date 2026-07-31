// lib/screens/customer/job_post_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/services/storage_service.dart';
import 'package:telvo/utils/geo.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/widgets/custom_text_field.dart';
import 'package:telvo/widgets/searchable_option_picker.dart';

class JobPostScreen extends StatefulWidget {
  const JobPostScreen({super.key});

  @override
  State<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends State<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String? _selectedProfessionalId;
  String? _selectedBusinessId;
  String? _selectedCategory;
  String? _selectedUrgency;
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();
  bool _isPosting = false;

  final List<String> _categories = [
    'Plumber',
    'Electrician',
    'Cleaner',
    'Painter',
    'Carpenter',
    'Mechanic',
    'Gardener',
    'Tutor',
  ];

  final List<String> _urgencyOptions = [
    'Emergency',
    'Today',
    'Tomorrow',
    'Flexible',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _selectedProfessionalId = args;
    } else if (args is JobPostArguments) {
      _selectedProfessionalId = args.professionalId;
      _selectedBusinessId = args.businessId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedProfessionalId != null ||
                  _selectedBusinessId != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFB9F6CA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedProfessionalId != null)
                        const Text(
                          'This request will be sent to the selected professional.',
                        ),
                      if (_selectedBusinessId != null)
                        const Text(
                          'This request will be sent to the selected business.',
                        ),
                    ],
                  ),
                ),
              Text(
                'What service do you need?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                hintText: 'Describe your problem',
                maxLines: 4,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please describe the problem'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _budgetController,
                hintText: 'Budget (XAF)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a budget';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Budget must be a positive number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                hintText: 'Address / Location',
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter an address or location'
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Urgency',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              _buildUrgencySelector(),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Post Job',
                isLoading: _isPosting,
                onPressed: _isPosting ? null : _postJob,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() => SizedBox(
    height: 56,
    child: Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final selected = await showSearchableOptionPicker(
                context: context,
                title: 'Select service',
                options: _categories,
                initialValue: _selectedCategory,
              );
              if (selected != null) {
                setState(() => _selectedCategory = selected);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedCategory ?? 'Select category',
                      style: TextStyle(
                        color: _selectedCategory == null
                            ? Colors.grey
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildImagePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: _pickImages,
            icon: const Icon(Icons.photo_camera),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 8),
          if (_selectedImages.isNotEmpty)
            Text('${_selectedImages.length} photos selected'),
        ],
      ),
      if (_selectedImages.isNotEmpty)
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: FileImage(File(_selectedImages[index].path)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );

  Widget _buildUrgencySelector() => Row(
    children: _urgencyOptions.map((urgency) {
      final isSelected = _selectedUrgency == urgency;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: Text(urgency),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedUrgency = selected ? urgency : null;
              });
            },
            selectedColor: const Color(0xFF00C853),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }).toList(),
  );

  Future<void> _pickImages() async {
    final images = await _picker.pickMultiImage();
    setState(() {
      _selectedImages = images ?? [];
    });
  }

  Future<void> _postJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Please select a service category.');
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please describe your problem.');
      return;
    }
    if (_budgetController.text.trim().isEmpty) {
      _showError('Please enter a budget.');
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      _showError('Please enter an address or location.');
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final customerId = authProvider.currentUser?.id;
    if (customerId == null) {
      _showError('You must be signed in to post a job.');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final jobProvider = context.read<JobProvider>();

      // Create the job first so we have an ID to namespace uploaded photos.
      var job = JobModel(
        customerId: customerId,
        professionalId: _selectedProfessionalId,
        businessId: _selectedBusinessId,
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        budget: double.tryParse(_budgetController.text.trim()),
        address: _addressController.text.trim(),
        urgency: _selectedUrgency,
        isEmergency: _selectedUrgency == 'Emergency',
        createdAt: DateTime.now(),
      );

      // Attempt to attach current location to the job for proximity matching
      try {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
            ),
          );
          job = job.copyWith(
            latitude: pos.latitude,
            longitude: pos.longitude,
            geoHash: encodeGeoHash(pos.latitude, pos.longitude),
          );
        }
      } catch (_) {}

      final createdJob = await jobProvider.postJob(job);

      if (jobProvider.error != null || createdJob == null) {
        throw Exception(jobProvider.error ?? 'Could not create job');
      }

      if (createdJob.id != null && _selectedImages.isNotEmpty) {
        final photoUrls = await _storageService.uploadJobPhotos(
          createdJob.id!,
          _selectedImages,
        );
        if (photoUrls.isNotEmpty) {
          await jobProvider.updateJobPhotos(createdJob.id!, photoUrls);
        }
      }

      if (!mounted) return;
      setState(() => _isPosting = false);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Job Posted!'),
          content: const Text(
            'Your job has been posted successfully. Nearby professionals will be notified.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                final navigator = Navigator.of(context);
                if (navigator.canPop()) {
                  navigator.pop();
                }
                if (navigator.canPop()) {
                  navigator.pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      _showError(
        'Failed to post job: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}

class JobPostArguments {
  final String? professionalId;
  final String? businessId;

  JobPostArguments({this.professionalId, this.businessId});
}
