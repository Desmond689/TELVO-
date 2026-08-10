import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:telvo/models/admin_model.dart';
import 'package:telvo/models/admin_stats.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/models/payment_model.dart';

class AdminProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AdminModel? currentAdmin;
  String? error;

  // Dashboard stats
  AdminStats stats = const AdminStats();

  List<UserModel> users = [];
  List<UserModel> professionals = [];
  List<JobModel> jobs = [];
  List<PaymentModel> payments = [];

  bool isLoading = false;

  void _setError(String? message) {
    error = message;
    notifyListeners();
  }

  /// Admin accounts authenticate via regular Firebase Auth (email/password);
  /// admin *privilege* is then verified against the `admins` Firestore
  /// collection - mirrors the backend's `requireAdmin` middleware exactly.
  Future<bool> loginAdmin(String email, String password) async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        throw Exception('Sign-in failed');
      }

      final adminSnap = await _firestore
          .collection('admins')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (adminSnap.docs.isEmpty) {
        await _auth.signOut();
        throw Exception('This account does not have admin access.');
      }

      final adminDoc = adminSnap.docs.first;
      final admin = AdminModel.fromMap(adminDoc.data(), adminDoc.id);

      if (!admin.isActive) {
        await _auth.signOut();
        throw Exception('This admin account has been deactivated.');
      }

      currentAdmin = admin;
      await adminDoc.reference.update({'lastLogin': FieldValue.serverTimestamp()});

      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      isLoading = false;
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      isLoading = false;
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  // Load dashboard statistics - mirrors backend/src/controllers/adminController.js#getDashboardStats
  Future<void> loadDashboardStats() async {
    isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _firestore.collection('users').get(),
        _firestore.collection('jobs').get(),
        _firestore.collection('payments').get(),
        _firestore.collection('reports').where('status', isEqualTo: 'pending').get(),
        _firestore
            .collection('reports')
            .where('type', isEqualTo: 'fraud')
            .where('status', isEqualTo: 'pending')
            .get(),
      ]);

      final usersSnap = results[0];
      final jobsSnap = results[1];
      final paymentsSnap = results[2];
      final disputesSnap = results[3];
      final fraudSnap = results[4];

      var totalProfessionals = 0;
      var pendingVerifications = 0;
      var verifiedVerifications = 0;
      var rejectedVerifications = 0;
      var requiredVerifications = 0;
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        final userType = data['userType'];
        final isProfessional = userType == 'professional' ||
            (userType is List && userType.contains('professional'));
        if (isProfessional) totalProfessionals++;

        final status = (data['verificationStatus'] as String?)?.toLowerCase();
        if (status == 'pending') {
          pendingVerifications++;
        } else if (status == 'verified') {
          verifiedVerifications++;
        } else if (status == 'rejected') {
          rejectedVerifications++;
        } else if (status == 'required') {
          requiredVerifications++;
        }
      }

      var totalRevenue = 0.0;
      for (final doc in paymentsSnap.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          totalRevenue += ((data['amount'] ?? 0) as num).toDouble();
        }
      }

      var activeJobs = 0;
      final categoryStats = <String, int>{};
      for (final doc in jobsSnap.docs) {
        final data = doc.data();
        if (['accepted', 'working'].contains(data['status'])) {
          activeJobs++;
        }
        final category = data['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryStats[category] = (categoryStats[category] ?? 0) + 1;
        }
      }

      // Recent activity: latest jobs, most-recent first (no dedicated
      // activity-log collection exists yet - this is a reasonable proxy).
      final sortedJobs = jobsSnap.docs.toList()
        ..sort((a, b) {
          final aTime = a.data()['createdAt'];
          final bTime = b.data()['createdAt'];
          if (aTime == null || bTime == null) return 0;
          return (bTime as Timestamp).compareTo(aTime as Timestamp);
        });
      final recentActivity = sortedJobs.take(5).map((doc) {
        final data = doc.data();
        return <String, dynamic>{
          'type': 'job',
          'title': 'New job: ${data['category'] ?? 'Service'}',
          'description': (data['description'] ?? '').toString(),
          'time': data['createdAt'],
        };
      }).toList();

      stats = AdminStats(
        totalUsers: usersSnap.docs.length,
        totalProfessionals: totalProfessionals,
        totalJobs: jobsSnap.docs.length,
        totalRevenue: totalRevenue,
        pendingVerifications: pendingVerifications,
        verifiedVerifications: verifiedVerifications,
        rejectedVerifications: rejectedVerifications,
        requiredVerifications: requiredVerifications,
        activeJobs: activeJobs,
        disputes: disputesSnap.docs.length,
        fraudReports: fraudSnap.docs.length,
        categoryStats: categoryStats,
        recentActivity: recentActivity,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading dashboard stats: $e');
      _setError('Failed to load dashboard stats');
    }

    isLoading = false;
    notifyListeners();
  }

  // Load users
  Future<void> loadUsers() async {
    isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection('users').get();
      users = snap.docs
          .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading users: $e');
      _setError('Failed to load users');
    }

    isLoading = false;
    notifyListeners();
  }

  // Load professionals
  Future<void> loadProfessionals() async {
    isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'professional')
          .get();
      professionals = snap.docs
          .map((doc) => UserModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading professionals: $e');
      _setError('Failed to load professionals');
    }

    isLoading = false;
    notifyListeners();
  }

  // Load jobs
  Future<void> loadJobs() async {
    isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection('jobs').get();
      jobs = snap.docs
          .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading jobs: $e');
      _setError('Failed to load jobs');
    }

    isLoading = false;
    notifyListeners();
  }

  // Load payments
  Future<void> loadPayments() async {
    isLoading = true;
    notifyListeners();

    try {
      final snap = await _firestore.collection('payments').get();
      payments = snap.docs
          .map((doc) => PaymentModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading payments: $e');
      _setError('Failed to load payments');
    }

    isLoading = false;
    notifyListeners();
  }

  // Update job status
  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({'status': status});
      await loadJobs();
    } catch (e) {
      if (kDebugMode) debugPrint('Error updating job status: $e');
      _setError('Failed to update job status');
    }
  }

  // Delete job
  Future<void> deleteJob(String jobId) async {
    try {
      await _firestore.collection('jobs').doc(jobId).delete();
      await loadJobs();
    } catch (e) {
      if (kDebugMode) debugPrint('Error deleting job: $e');
      _setError('Failed to delete job');
    }
  }

  // Process refund
  Future<void> processRefund(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'refunded',
        'refundedAt': FieldValue.serverTimestamp(),
      });
      await loadPayments();
    } catch (e) {
      if (kDebugMode) debugPrint('Error processing refund: $e');
      _setError('Failed to process refund');
    }
  }

  // Set a professional's verification status explicitly
  Future<void> toggleUserVerification(String userId, bool verified) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': verified,
        'verificationStatus': verified ? 'verified' : 'unverified',
        if (verified) ...{
          'verificationRejectedReason': null,
          'verificationRejectionReason': null,
          'verificationRejectedAt': null,
        }
      });
      await loadProfessionals();
    } catch (e) {
      if (kDebugMode) debugPrint('Error toggling verification: $e');
      _setError('Failed to update verification status');
    }
  }

  // Logout admin
  Future<void> logoutAdmin() async {
    await _auth.signOut();
    currentAdmin = null;
    error = null;
    users.clear();
    professionals.clear();
    jobs.clear();
    payments.clear();
    stats = const AdminStats();
    notifyListeners();
  }
}
