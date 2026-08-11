import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/services/storage_service.dart';
import 'package:telvo/widgets/custom_button.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/app_colors.dart';

class IDVerificationScreen extends StatefulWidget {
  const IDVerificationScreen({super.key});

  @override
  State<IDVerificationScreen> createState() => _IDVerificationScreenState();
}

class _IDVerificationScreenState extends State<IDVerificationScreen> {
  int _currentStep = 0;
  String _idType = 'National ID';
  XFile? _front;
  XFile? _back;
  XFile? _selfie;
  bool _isSubmitting = false;
  bool _isReviewingStatus = false;

  Future<void> _pickImage(ImageSource source, String target) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (target == 'front') {
        _front = picked;
      } else if (target == 'back') {
        _back = picked;
      } else {
        _selfie = picked;
      }
    });
  }

  Future<void> _submitVerification() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final userId = user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You must be signed in.')));
      return;
    }
    if (_front == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload the front of your ID.')));
      return;
    }
    if (_selfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a selfie for identity confirmation.')));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final storage = StorageService();
      final uploadedPhotos = <String>[];
      final idFolder = 'verifications/$userId';

      final frontUrl = await storage.uploadFileDirect(
        file: File(_front!.path),
        folder: idFolder,
        fileName: 'id_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (frontUrl != null) uploadedPhotos.add(frontUrl);

      if (_back != null) {
        final backUrl = await storage.uploadFileDirect(
          file: File(_back!.path),
          folder: idFolder,
          fileName: 'id_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (backUrl != null) uploadedPhotos.add(backUrl);
      }

      final selfieUrl = await storage.uploadFileDirect(
        file: File(_selfie!.path),
        folder: idFolder,
        fileName: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (selfieUrl != null) uploadedPhotos.add(selfieUrl);

      await FirebaseFirestore.instance.collection('verifications').add({
        'userId': userId,
        'idType': _idType,
        'photos': uploadedPhotos,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isVerified': false,
        'isIdVerified': false,
        'isSelfieVerified': false,
        'verificationStatus': 'pending',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verificationRejectedReason': null,
        'verificationRejectionReason': null,
        'verificationRejectedAt': null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification submitted — admin will review it shortly.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = getFriendlyErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $msg')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final status = user?.verificationStatus.toLowerCase() ?? 'unverified';

    return Scaffold(
      appBar: AppBar(title: const Text('ID Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: user == null
            ? const Center(child: Text('Please sign in to verify your identity.'))
            : _buildBody(context, user, status),
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserModel user, String status) {
    if (status == 'verified') {
      return _buildStatusMessage(
        title: 'Verified successfully',
        description: 'Your identity has already been approved by the Telvo team.',
        icon: Icons.verified,
        iconColor: Colors.green,
        actionLabel: 'Back to dashboard',
        onAction: () => Navigator.pop(context),
      );
    }

    if (status == 'pending') {
      return _buildStatusMessage(
        title: 'Verification pending',
        description: 'Your documents are under review. We will notify you once a decision is made.',
        icon: Icons.hourglass_top,
        iconColor: Colors.orange,
        actionLabel: 'Back',
        onAction: () => Navigator.pop(context),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (status == 'rejected') ...[
          _buildRejectionBanner(user.verificationRejectedReason),
          const SizedBox(height: 16),
        ],
        _buildStepper(),
        const SizedBox(height: 20),
        Expanded(child: _buildCurrentStep()),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : () {
                    setState(() => _currentStep--);
                  },
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: _currentStep < 2 ? 'Next' : (_isSubmitting ? 'Submitting...' : 'Submit Verification'),
                onPressed: _isSubmitting ? null : _handleNext,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusMessage({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Icon(icon, size: 72, color: iconColor),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: actionLabel,
          onPressed: onAction,
        ),
      ],
    );
  }

  Widget _buildRejectionBanner(String? reason) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verification rejected',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason != null && reason.isNotEmpty
                ? 'Reason: $reason'
                : 'Your previous verification attempt was rejected. Please update your documents and submit again.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: [
        _buildStepMarker(0, 'Document'),
        _buildStepDivider(),
        _buildStepMarker(1, 'Upload'),
        _buildStepDivider(),
        _buildStepMarker(2, 'Selfie'),
      ],
    );
  }

  Widget _buildStepMarker(int index, String label) {
    final isActive = _currentStep == index;
    final isComplete = _currentStep > index;
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: isComplete || isActive 
                ? AppColors.primary 
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: isComplete || isActive ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 24,
      height: 2,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildIdTypeStep();
      case 1:
        return _buildDocumentUploadStep();
      case 2:
        return _buildSelfieStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdTypeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the ID type you will submit',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose the primary identity document to verify your account.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _buildIdTypeOption('National ID'),
        _buildIdTypeOption('Passport'),
        _buildIdTypeOption('Driver License'),
        _buildIdTypeOption('Other'),
      ],
    );
  }

  Widget _buildIdTypeOption(String option) {
    return RadioListTile<String>(
      title: Text(option),
      value: option,
      groupValue: _idType,
      onChanged: (value) {
        if (value == null) return;
        setState(() => _idType = value);
      },
    );
  }

  Widget _buildDocumentUploadStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload your identity document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Capture a clear front photo of your document. The back side is optional but recommended.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPhotoCard('Front of ID', _front, () => _pickImage(ImageSource.camera, 'front'))),
            const SizedBox(width: 12),
            Expanded(child: _buildPhotoCard('Back of ID', _back, () => _pickImage(ImageSource.camera, 'back'))),
          ],
        ),
      ],
    );
  }

  Widget _buildSelfieStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Take a selfie',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Take a selfie while holding your ID next to your face. This helps verify your identity securely.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 16),
        _buildPhotoCard('Selfie with ID', _selfie, () => _pickImage(ImageSource.camera, 'selfie')),
      ],
    );
  }

  Widget _buildPhotoCard(String label, XFile? file, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (file == null) ...[
              Icon(
                Icons.camera_alt,
                size: 36,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ] else ...[
              Expanded(child: Image.file(File(file.path), fit: BoxFit.cover, width: double.infinity)),
            ],
          ],
        ),
      ),
    );
  }

  void _handleNext() {
    if (_currentStep == 0) {
      setState(() => _currentStep = 1);
      return;
    }
    if (_currentStep == 1) {
      if (_front == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or capture the front of your ID.')));
        return;
      }
      setState(() => _currentStep = 2);
      return;
    }

    _submitVerification();
  }
}
