// lib/providers/job_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/services/notification_service.dart';

class JobProvider extends ChangeNotifier {
  JobProvider() {
    _init();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<JobModel> _jobs = [];
  List<JobModel> _myJobs = [];
  List<QuoteModel> _quotes = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _customerJobsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _professionalJobsSubscription;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get myJobs => _myJobs;
  List<QuoteModel> get quotes => _quotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    // Listen to job updates
    _firestore
        .collection('jobs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          _jobs = snapshot.docs
              .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
              .toList();
          notifyListeners();
        });
  }

  /// Force-refresh jobs from Firestore (one-shot). Useful for pull-to-refresh
  /// or manual refresh actions when snapshot latency isn't sufficient.
  Future<void> refreshJobs() async {
    try {
      _setLoading(true);
      final snapshot = await _firestore
          .collection('jobs')
          .orderBy('createdAt', descending: true)
          .get();
      _jobs = snapshot.docs
          .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<JobModel?> postJob(JobModel job) async {
    try {
      _setLoading(true);
      _setError(null);

      final docRef = _firestore.collection('jobs').doc();
      final newJob = job.copyWith(
        id: docRef.id,
        status: 'posted',
        createdAt: DateTime.now(),
      );

      await docRef.set(newJob.toMap());

      // Notify nearby professionals
      await _notificationService.notifyProfessionals(newJob);

      _setLoading(false);
      notifyListeners();
      return newJob;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      return null;
    }
  }

  /// Attaches uploaded photo URLs to a job after creation (photos are
  /// uploaded to Storage using the job's own ID as the folder name, so the
  /// job must exist first).
  Future<void> updateJobPhotos(String jobId, List<String> photoUrls) async {
    try {
      await _firestore.collection('jobs').doc(jobId).update({
        'photos': photoUrls,
      });
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendQuote(QuoteModel quote) async {
    try {
      _setLoading(true);
      _setError(null);

      final docRef = _firestore.collection('quotes').doc();
      final newQuote = quote.copyWith(id: docRef.id);
      await docRef.set(newQuote.toMap());

      // Add quote to job and update status
      final jobRef = _firestore.collection('jobs').doc(quote.jobId);
      await jobRef.update({
        'quotes': FieldValue.arrayUnion([newQuote.toMap()]),
        'status': 'quoted',
      });

      await _notificationService.notifyNewQuote(newQuote);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> acceptQuote(String jobId, String quoteId) async {
    try {
      _setLoading(true);
      _setError(null);

      final jobRef = _firestore.collection('jobs').doc(jobId);
      await jobRef.update({'status': 'accepted', 'acceptedQuoteId': quoteId});

      // Notify professional
      final job = _jobs.firstWhere((j) => j.id == jobId);
      final quote = job.quotes?.firstWhere((q) => q.id == quoteId);
      if (quote != null) {
        await _notificationService.notifyQuoteAccepted(quote);
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      _setLoading(true);
      _setError(null);

      final jobRef = _firestore.collection('jobs').doc(jobId);
      await jobRef.update({
        'status': status,
        if (status == 'completed') 'completedDate': DateTime.now(),
      });

      await _notificationService.notifyJobUpdate(jobId, status);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Fetches all reviews left for [userId], newest first, enriched with the
  /// reviewer's current name and photo (reviews only store reviewerId).
  Future<List<ReviewModel>> fetchReviewsForUser(String userId) async {
    final snapshot = await _firestore
        .collection('reviews')
        .where('reviewedId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    final reviews = snapshot.docs
        .map((doc) => ReviewModel.fromMap(doc.data()))
        .toList();

    // Batch-load reviewer profiles (skip anonymous reviews).
    final reviewerIds = reviews
        .where((r) => r.isAnonymous != true && r.reviewerId != null)
        .map((r) => r.reviewerId!)
        .toSet();

    final reviewerInfo = <String, Map<String, String?>>{};
    for (final id in reviewerIds) {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        reviewerInfo[id] = {
          'name': data['fullName'] as String?,
          'photo': data['profilePhoto'] as String?,
        };
      }
    }

    return reviews.map((r) {
      final info = r.reviewerId != null ? reviewerInfo[r.reviewerId] : null;
      return r.copyWith(
        reviewerName: r.isAnonymous == true
            ? 'Anonymous'
            : (info?['name'] ?? 'Telvo user'),
        reviewerPhoto: r.isAnonymous == true ? null : info?['photo'],
      );
    }).toList();
  }

  /// Saves a professional's reply to a review.
  Future<bool> respondToReview(String reviewId, String responseText) async {
    try {
      await _firestore.collection('reviews').doc(reviewId).update({
        'isResponse': true,
        'responseText': responseText,
        'responseAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  Future<void> submitReview(ReviewModel review) async {
    try {
      _setLoading(true);
      _setError(null);

      final docRef = _firestore.collection('reviews').doc();
      final newReview = review.copyWith(id: docRef.id);
      await docRef.set(newReview.toMap());

      // Update job with review
      final jobRef = _firestore.collection('jobs').doc(review.jobId);
      await jobRef.update({'review': newReview.toMap()});

      // Update professional rating
      final userRef = _firestore.collection('users').doc(review.reviewedId);
      final userDoc = await userRef.get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final currentRating = userData['rating'] ?? 0.0;
        final jobsCompleted = userData['jobsCompleted'] ?? 0;
        final newRating =
            ((currentRating * jobsCompleted) + review.rating!) /
            (jobsCompleted + 1);

        await userRef.update({
          'rating': newRating,
          'jobsCompleted': jobsCompleted + 1,
        });
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  /// Jobs assigned to a professional (loadMyJobs above is customer-side -
  /// it filters by customerId, which is the wrong field for a
  /// professional's own job list).
  Future<void> loadProfessionalJobs(String professionalId) async {
    try {
      _setLoading(true);
      _setError(null);
      await _professionalJobsSubscription?.cancel();

      _professionalJobsSubscription = _firestore
          .collection('jobs')
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _myJobs = snapshot.docs
                  .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
                  .toList();
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError(e.toString());
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadMyJobs(String userId) async {
    try {
      _setLoading(true);
      _setError(null);
      await _customerJobsSubscription?.cancel();

      _customerJobsSubscription = _firestore
          .collection('jobs')
          .where('customerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              _myJobs = snapshot.docs
                  .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
                  .toList();
              _setLoading(false);
              notifyListeners();
            },
            onError: (e) {
              _setError(e.toString());
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> loadQuotes(String professionalId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('quotes')
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true)
          .get();

      _quotes = snapshot.docs
          .map((doc) => QuoteModel.fromMap(doc.data()))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<List<JobModel>> searchJobs({
    String? category,
    String? serviceType,
    String? area,
    double? maxDistance,
    double? minBudget,
    double? maxBudget,
    bool? emergency,
  }) async {
    try {
      Query query = _firestore
          .collection('jobs')
          .where('status', isEqualTo: 'posted');

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (serviceType != null) {
        query = query.where('serviceType', isEqualTo: serviceType);
      }
      if (emergency != null) {
        query = query.where('isEmergency', isEqualTo: emergency);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map((doc) => JobModel.fromMap(doc.data()! as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<List<JobModel>> getJobsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('jobs')
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'posted')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProfessionals() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', arrayContains: 'professional')
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<void> cancelJob(String jobId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('jobs').doc(jobId).update({
        'status': 'cancelled',
      });

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('jobs').doc(jobId).delete();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _customerJobsSubscription?.cancel();
    _professionalJobsSubscription?.cancel();
    super.dispose();
  }
}
