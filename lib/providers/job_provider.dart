// lib/providers/job_provider.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/services/notification_service.dart';
import 'package:telvo/utils/error_messages.dart';
import 'package:telvo/utils/helpers.dart';

class JobProvider extends ChangeNotifier {
  JobProvider() {
    _init();
  }
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  List<JobModel> _jobs = [];
  List<JobModel> _myJobs = [];
  List<QuoteModel> _quotes = [];
  List<HireRequestModel> _hireRequests = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _customerJobsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _professionalJobsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _jobsFeedSubscription;

  List<JobModel> get jobs => _jobs;
  List<JobModel> get myJobs => _myJobs;
  List<QuoteModel> get quotes => _quotes;
  List<HireRequestModel> get hireRequests => _hireRequests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  static bool shouldShowInFeed(JobModel job, {String? currentUserId}) {
    final status = job.status?.trim().toLowerCase();
    if (status != 'posted' &&
        status != 'open' &&
        status != 'quotes_received' &&
        status != 'notified') {
      return false;
    }
    if (currentUserId != null && job.customerId == currentUserId) return false;
    final professionalId = (job.professionalId ?? '').trim();
    if (professionalId.isNotEmpty && professionalId != currentUserId) {
      return false;
    }
    if ((job.acceptedQuoteId ?? '').isNotEmpty) return false;
    // Exclude expired jobs (older than 24 hours)
    try {
      final now = DateTime.now();
      if (job.expiresAt != null) {
        if (job.expiresAt!.isBefore(now)) return false;
      } else if (job.createdAt != null) {
        if (now.difference(job.createdAt!).inHours >= 24) return false;
      }
    } catch (_) {}
    return true;
  }

  void _init() {
    _jobsFeedSubscription = _firestore
        .collection('jobs')
        .where('status', whereIn: ['posted', 'open', 'quotes_received', 'notified'])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            final temp = <JobModel>[];
            for (final doc in snapshot.docs) {
              try {
                final job = JobModel.fromMap({...doc.data(), 'id': doc.id});
                final showInFeed = shouldShowInFeed(job, currentUserId: _currentUserId);
                if (showInFeed) {
                  temp.add(job);
                } else {
                  if (const bool.fromEnvironment('dart.vm.product') == false) {
                    // ignore: avoid_print
                    print('Job ${doc.id} skipped from feed. status=${job.status}, customerId=${job.customerId}, professionalId=${job.professionalId}, acceptedQuoteId=${job.acceptedQuoteId}, category=${job.category}, createdAt=${job.createdAt}');
                  }
                }
              } catch (e, st) {
                // Don't let one malformed document break the whole feed.
                // Print in debug to aid diagnosis; production will swallow to avoid noisy logs.
                if (const bool.fromEnvironment('dart.vm.product') == false) {
                  // ignore: avoid_print
                  print('Job parsing error for doc ${doc.id}: $e');
                  // ignore: avoid_print
                  print(st);
                }
                continue;
              }
            }
            _jobs = temp;
            _jobs.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
            notifyListeners();
          },
          onError: (e) {
            _setError(getFriendlyErrorMessage(e));
          },
        );
  }

  /// Force-refresh jobs from Firestore (one-shot). Useful for pull-to-refresh
  /// or manual refresh actions when snapshot latency isn't sufficient.
  Future<void> refreshJobs() async {
    try {
      _setLoading(true);
      final hasInternet = await Helpers.checkInternetConnection();
      if (!hasInternet) {
        _setError('No internet connection. Please check your connection and try again.');
        _setLoading(false);
        return;
      }
      final snapshot = await _firestore
          .collection('jobs')
          .where('status', whereIn: ['posted', 'open', 'quotes_received', 'notified'])
          .orderBy('createdAt', descending: true)
          .get();
      _jobs = snapshot.docs
          .map((doc) => JobModel.fromMap({...doc.data(), 'id': doc.id}))
          .where((job) => shouldShowInFeed(job, currentUserId: _currentUserId))
          .toList();
      _jobs.sort((a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
      _setError(null);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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

      // Use server timestamp for createdAt to avoid client clock issues and
      // ensure Firestore ordering by createdAt works reliably for listeners.
      final data = newJob.toMap();
      data['createdAt'] = FieldValue.serverTimestamp();
      // Normalized category for case-insensitive matching / queries
      final cat = (newJob.category ?? '').trim();
      if (cat.isNotEmpty) {
        data['category'] = cat;
        data['categoryNormalized'] = cat.toLowerCase();
      }
      // Set an expiry 24 hours from now so the client can hide/cleanup old jobs
      try {
        data['expiresAt'] = DateTime.now().add(const Duration(hours: 24));
      } catch (_) {}
      await docRef.set(data);

      // Read the document back to get the server timestamp and any transforms
      final createdDoc = await docRef.get();
      final createdJob = JobModel.fromMap({...createdDoc.data() ?? {}, 'id': createdDoc.id});

      // Debug: print created document for diagnosis in non-production
      if (const bool.fromEnvironment('dart.vm.product') == false) {
        // ignore: avoid_print
        print('postJob created doc ${createdDoc.id}: ${createdDoc.data()}');
      }

      // Optimistically add the created job to the local feed so professionals
      // see it immediately without waiting for the Firestore snapshot listener.
      try {
        final alreadyPresent = _jobs.any((j) => j.id == createdJob.id);
        if (!alreadyPresent && shouldShowInFeed(createdJob)) {
          _jobs.insert(0, createdJob);
        }
      } catch (_) {}

      // Notify nearby professionals
      await _notificationService.notifyProfessionals(createdJob);

      _setLoading(false);
      notifyListeners();
      return createdJob;
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
      return null;
    }
  }

  Future<JobModel?> updateJob(JobModel job) async {
    try {
      _setLoading(true);
      _setError(null);

      if (job.id == null || job.id!.isEmpty) {
        throw Exception('Job ID is required to update a job.');
      }

      final docRef = _firestore.collection('jobs').doc(job.id);
      final existingDoc = await docRef.get();
      if (!existingDoc.exists) {
        throw Exception('Job not found.');
      }

      final data = job.toMap();
      data['createdAt'] = existingDoc.data()?['createdAt'] ?? FieldValue.serverTimestamp();
      if (job.category != null && job.category!.trim().isNotEmpty) {
        data['category'] = job.category!.trim();
        data['categoryNormalized'] = job.category!.trim().toLowerCase();
      }
      await docRef.update(data);

      final updatedDoc = await docRef.get();
      final updatedJob = JobModel.fromMap({...updatedDoc.data() ?? {}, 'id': updatedDoc.id});

      final idx = _jobs.indexWhere((j) => j.id == updatedJob.id);
      if (idx != -1) {
        _jobs[idx] = updatedJob;
      }

      _setLoading(false);
      notifyListeners();
      return updatedJob;
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
    }
  }

  Future<void> sendQuote(QuoteModel quote) async {
    try {
      _setLoading(true);
      _setError(null);

      // Ensure job still accepts quotes (not already accepted)
      final jobRef = _firestore.collection('jobs').doc(quote.jobId);
      final jobDoc = await jobRef.get();
      if (!jobDoc.exists) {
        _setLoading(false);
        final msg = 'Job not found';
        _setError(msg);
        throw Exception(msg);
      }
      final jobData = jobDoc.data() ?? {};
      final acceptedQuoteId = jobData['acceptedQuoteId'] as String? ?? '';
      final status = (jobData['status'] as String?)?.toLowerCase() ?? '';
      // Check expiry
      final expiryRaw = jobData['expiresAt'];
      DateTime? expiresAt;
      try {
        if (expiryRaw == null) {
          expiresAt = null;
        } else if (expiryRaw is DateTime) {
          expiresAt = expiryRaw as DateTime;
        } else if (expiryRaw is Map && expiryRaw.containsKey('_seconds')) {
          final seconds = expiryRaw['_seconds'] as int? ?? 0;
          final nanoseconds = expiryRaw['_nanoseconds'] as int? ?? 0;
          expiresAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else {
          try {
            // Firestore Timestamp
            final dynamic v = expiryRaw;
            final dt = v.toDate();
            if (dt is DateTime) expiresAt = dt;
          } catch (_) {
            if (expiryRaw is String) expiresAt = DateTime.tryParse(expiryRaw);
          }
        }
      } catch (_) { expiresAt = null; }
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        _setLoading(false);
        final msg = 'This job has expired and is no longer accepting quotes.';
        _setError(msg);
        throw Exception(msg);
      }
      if (acceptedQuoteId.isNotEmpty || status == 'accepted' || status == 'worker_selected') {
        _setLoading(false);
        final msg = 'This job is no longer accepting quotes.';
        _setError(msg);
        throw Exception(msg);
      }

      // Prevent duplicate quotes from the same professional on the same job
      if (quote.professionalId != null && quote.professionalId!.isNotEmpty) {
        final existing = await _firestore
            .collection('quotes')
            .where('jobId', isEqualTo: quote.jobId)
            .where('professionalId', isEqualTo: quote.professionalId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          _setLoading(false);
          final msg = 'You have already sent a quote for this job.';
          _setError(msg);
          throw Exception(msg);
        }
      }

      // Enrich quote with worker profile for job cards / lists
      String? workerName = quote.workerName;
      String? workerImage = quote.workerImage;
      if (quote.professionalId != null && quote.professionalId!.isNotEmpty) {
        try {
          final prof = await _firestore.collection('users').doc(quote.professionalId).get();
          if (prof.exists) {
            final pd = prof.data() ?? {};
            workerName ??= pd['fullName'] as String?;
            workerImage ??= pd['profilePhoto'] as String?;
          }
        } catch (_) {}
      }

      final docRef = _firestore.collection('quotes').doc();
      final newQuote = quote.copyWith(
        id: docRef.id,
        createdAt: DateTime.now(),
        status: quote.status ?? 'pending',
        workerName: workerName,
        workerImage: workerImage,
      );
      await docRef.set(newQuote.toMap());

      // Add quote to job and update status
      await jobRef.update({
        'quotes': FieldValue.arrayUnion([newQuote.toMap()]),
        'status': 'quotes_received',
      });

      await _notificationService.notifyNewQuote(newQuote);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
      rethrow;
    }
  }

  Future<void> acceptQuote(String jobId, String quoteId) async {
    try {
      _setLoading(true);
      _setError(null);

      final jobRef = _firestore.collection('jobs').doc(jobId);
      final jobSnap = await jobRef.get();
      if (!jobSnap.exists) {
        _setError('Job not found');
        _setLoading(false);
        return;
      }
      final jobData = jobSnap.data() ?? {};
      final currentStatus = (jobData['status'] as String?)?.toLowerCase() ?? '';
      final existingAccepted = (jobData['acceptedQuoteId'] as String?) ?? '';

      // Only open-like statuses can accept a quote
      final openStatuses = {'posted', 'open', 'quotes_received', 'notified'};
      if (!openStatuses.contains(currentStatus) || existingAccepted.isNotEmpty) {
        _setError('This job is no longer open for quote acceptance.');
        _setLoading(false);
        return;
      }

      // Enforce 24h expiry
      DateTime? expiresAt;
      final expiryRaw = jobData['expiresAt'];
      try {
        if (expiryRaw != null) {
          if (expiryRaw is DateTime) {
            expiresAt = expiryRaw;
          } else {
            final dynamic v = expiryRaw;
            try {
              expiresAt = v.toDate() as DateTime;
            } catch (_) {
              if (expiryRaw is String) expiresAt = DateTime.tryParse(expiryRaw);
            }
          }
        } else if (jobData['createdAt'] != null) {
          try {
            final created = (jobData['createdAt'] as dynamic).toDate() as DateTime;
            expiresAt = created.add(const Duration(hours: 24));
          } catch (_) {}
        }
      } catch (_) {}
      if (expiresAt != null && expiresAt.isBefore(DateTime.now())) {
        await jobRef.update({'status': 'expired'});
        _setError('This job has expired and can no longer accept quotes.');
        _setLoading(false);
        return;
      }

      // Fetch the quote to determine the professional.
      final quoteDoc = await _firestore.collection('quotes').doc(quoteId).get();
      if (!quoteDoc.exists) {
        _setError('Quote not found');
        _setLoading(false);
        return;
      }
      final quoteData = quoteDoc.data() ?? {};
      final professionalId = quoteData['professionalId'] as String?;
      final quoteStatus = (quoteData['status'] as String?)?.toLowerCase() ?? 'pending';
      if (quoteStatus == 'rejected' || quoteStatus == 'expired') {
        _setError('This quote is no longer available.');
        _setLoading(false);
        return;
      }

      // Fetch professional info for display on job cards
      String? professionalName = quoteData['workerName'] as String?;
      String? professionalImage = quoteData['workerImage'] as String?;
      if (professionalId != null && professionalId.isNotEmpty) {
        final profDoc = await _firestore.collection('users').doc(professionalId).get();
        if (profDoc.exists) {
          final pd = profDoc.data() ?? {};
          professionalName ??= pd['fullName'] as String?;
          professionalImage ??= pd['profilePhoto'] as String?;
        }
      }

      await jobRef.update({
        'status': 'accepted',
        'acceptedQuoteId': quoteId,
        'professionalId': professionalId,
        if (professionalName != null) 'professionalName': professionalName,
        if (professionalImage != null) 'professionalImage': professionalImage,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      // Update the quote status.
      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'accepted',
      });

      // Reject all other quotes for this job.
      final otherQuotes = await _firestore
          .collection('quotes')
          .where('jobId', isEqualTo: jobId)
          .get();
      for (final doc in otherQuotes.docs) {
        if (doc.id != quoteId) {
          await doc.reference.update({'status': 'rejected'});
        }
      }

      // Notify accepted professional
      final job = _jobs.firstWhere(
        (j) => j.id == jobId,
        orElse: () => JobModel(),
      );
      QuoteModel? selectedQuote;
      if (job.quotes != null) {
        try {
          selectedQuote = job.quotes!.firstWhere((q) => q.id == quoteId);
        } catch (_) {
          selectedQuote = null;
        }
      }
      if (selectedQuote != null && selectedQuote.jobId != null) {
        await _notificationService.notifyQuoteAccepted(selectedQuote);
      }

      // Optimistically update local job copy so UI shows professionalName/status immediately
      try {
        final idx = _jobs.indexWhere((j) => j.id == jobId);
        if (idx != -1) {
          final existing = _jobs[idx];
          final updated = existing.copyWith(
            status: 'accepted',
            acceptedQuoteId: quoteId,
            professionalId: professionalId,
            professionalName: professionalName,
            professionalImage: professionalImage,
          );
          _jobs[idx] = updated;
        }
      } catch (_) {}

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  Future<void> rejectQuote(String jobId, String quoteId) async {
    try {
      _setLoading(true);
      _setError(null);

      await _firestore.collection('quotes').doc(quoteId).update({
        'status': 'rejected',
      });

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  Future<void> updateJobStatus(String jobId, String status) async {
    try {
      _setLoading(true);
      _setError(null);

      final jobRef = _firestore.collection('jobs').doc(jobId);
      final update = <String, dynamic>{
        'status': status,
        if (status == 'accepted')
          'acceptedDate': DateTime.now()
        else if (status == 'in_progress')
          'startedDate': DateTime.now()
        else if (status == 'completed')
          'completedDate': DateTime.now(),
      };
      await jobRef.update(update);

      await _notificationService.notifyJobUpdate(jobId, status);

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
      return false;
    }
  }

  /// Submits a review for a completed job.
  ///
  /// One review per job is the architecture here: `jobs/{jobId}.review`
  /// holds a single review object and the job's `status` flips from
  /// 'completed' to 'reviewed' once it has one. The previous implementation
  /// enforced that with a plain read-then-write: query `reviews` for an
  /// existing doc with this jobId, and only proceed if none was found. That
  /// check and the eventual write were not atomic, so two submissions for
  /// the same job landing close together (a double-tap that beats the
  /// button's disabled state, a retried request after a slow/timed-out
  /// first one that actually succeeded, etc.) could both pass the check
  /// before either had committed, producing two review docs.
  ///
  /// This now writes the review + job update inside a single Firestore
  /// transaction, keyed by a deterministic review doc ID (`reviews/{jobId}`)
  /// instead of a random one. Firestore transactions are optimistic: if a
  /// second transaction's reads are invalidated by the first one's commit,
  /// it's automatically retried, so on retry it sees the review doc that
  /// now exists and aborts cleanly instead of writing a duplicate.
  ///
  /// Rating recalculation is deliberately NOT done here anymore. The old
  /// code tried to `userRef.update({rating: ..., jobsCompleted: ...})`
  /// directly on the professional's user doc as the reviewing *customer* -
  /// but firestore.rules only lets a user update their own doc (or an
  /// admin update anyone's), so that write was rejected with
  /// permission-denied on every single submission in production. Because
  /// it ran after the review/job writes inside one big try/catch, the
  /// whole submitReview() call surfaced as a failure to the customer even
  /// though the review had already been saved - confusing, and the rating
  /// was never actually updated. The Cloud Function
  /// `recalcRatingOnReview` (functions/index.js) now does this
  /// server-side with the Admin SDK, which isn't subject to security
  /// rules, triggered by the review doc this method writes.
  Future<void> submitReview(ReviewModel review) async {
    final jobId = review.jobId;
    if (jobId == null || jobId.isEmpty) {
      _setError('Missing job for review.');
      return;
    }
    if (review.reviewedId == null || review.reviewedId!.isEmpty) {
      _setError('Missing professional for review.');
      return;
    }
    if (review.rating == null) {
      _setError('Please rate your experience.');
      return;
    }

    _setLoading(true);
    _setError(null);

    // Deterministic ID: one review doc per job, and it doubles as the
    // atomic dedup key inside the transaction below.
    final jobRef = _firestore.collection('jobs').doc(jobId);
    final reviewRef = _firestore.collection('reviews').doc(jobId);

    String? failureMessage;
    ReviewModel? committedReview;

    try {
      await _firestore.runTransaction((tx) async {
        final jobSnap = await tx.get(jobRef);
        if (!jobSnap.exists) {
          failureMessage = 'Job not found.';
          return;
        }

        final jobStatus = (jobSnap.data()?['status'] as String?)?.toLowerCase() ?? '';
        if (jobStatus == 'reviewed') {
          failureMessage = 'You already reviewed this job.';
          return;
        }
        if (jobStatus != 'completed') {
          failureMessage = 'You can only review completed jobs.';
          return;
        }

        final existingReview = await tx.get(reviewRef);
        if (existingReview.exists) {
          // Either a genuine concurrent submission, or this transaction is
          // retrying after another one just committed the review doc.
          // Either way, it's already reviewed - stop here.
          failureMessage = 'You already reviewed this job.';
          return;
        }

        final newReview = review.copyWith(id: reviewRef.id);
        committedReview = newReview;

        tx.set(reviewRef, newReview.toMap());
        tx.update(jobRef, {
          'review': newReview.toMap(),
          'status': 'reviewed',
        });
      });
    } catch (e) {
      failureMessage = getFriendlyErrorMessage(e);
    }

    if (failureMessage != null) {
      _setError(failureMessage);
      _setLoading(false);
      return;
    }

    // Best-effort in-app notification for the professional. Non-fatal if
    // it fails - the review itself already succeeded, and rating
    // recalculation happens independently via the Cloud Function above.
    if (committedReview != null) {
      try {
        await _notificationService.notifyReviewReceived(
          professionalId: review.reviewedId!,
          jobId: jobId,
          rating: review.rating!,
        );
      } catch (_) {
        // ignore
      }
    }

    _setLoading(false);
    notifyListeners();
  }

  /// Jobs assigned to a professional (loadMyJobs above is customer-side -
  /// it filters by customerId, which is the wrong field for a
  /// professional's own job list).
  Future<void> loadProfessionalJobs(String professionalId) async {
    try {
      _setLoading(true);
      _setError(null);
      await _professionalJobsSubscription?.cancel();

      // Load jobs where this professional was selected or hired directly.
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
              _setError(getFriendlyErrorMessage(e));
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
              _setError(getFriendlyErrorMessage(e));
              _setLoading(false);
            },
          );
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  /// Loads quotes received by the customer (for comparing/accepting quotes).
  Future<void> loadCustomerQuotes(String jobId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('quotes')
          .where('jobId', isEqualTo: jobId)
          .orderBy('createdAt', descending: true)
          .get();

      _quotes = snapshot.docs
          .map((doc) => QuoteModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  // ─── Hire Request System ───────────────────────────────────────────

  /// Customer sends a direct hire request to a specific professional.
  Future<HireRequestModel?> sendHireRequest({
    required String customerId,
    required String customerName,
    required String professionalId,
    required String category,
    required String description,
    required double budget,
    String? address,
    String? preferredDate,
    String? preferredTime,
    String? paymentMethod,
    String? serviceType,
    List<String>? photos,
    String? professionalName,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // Defense in depth: mirror the block check chat_provider.sendMessage
      // does. Without this, a blocked customer could still reach a
      // professional (or vice versa) through the direct hire-request flow,
      // bypassing the block entirely.
      final customerDoc = await _firestore.collection('users').doc(customerId).get();
      final professionalDoc = await _firestore.collection('users').doc(professionalId).get();
      final customerBlocked = List<String>.from(
        (customerDoc.data()?['blockedUsers'] as List?)?.map((e) => e.toString()) ?? [],
      );
      final professionalBlocked = List<String>.from(
        (professionalDoc.data()?['blockedUsers'] as List?)?.map((e) => e.toString()) ?? [],
      );
      if (customerBlocked.contains(professionalId) || professionalBlocked.contains(customerId)) {
        throw Exception('You cannot send a hire request to this user.');
      }

      final docRef = _firestore.collection('hire_requests').doc();
      final hire = HireRequestModel(
        id: docRef.id,
        customerId: customerId,
        customerName: customerName,
        professionalId: professionalId,
        professionalName: professionalName,
        category: category,
        description: description,
        budget: budget,
        address: address,
        preferredDate: preferredDate,
        preferredTime: preferredTime,
        paymentMethod: paymentMethod,
        serviceType: serviceType,
        photos: photos,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await docRef.set(hire.toMap());

      await _notificationService.notifyNewHireRequest(
        professionalId: professionalId,
        customerId: customerId,
        customerName: customerName,
        category: category,
        hireId: docRef.id,
      );

      _setLoading(false);
      notifyListeners();
      return hire;
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
      return null;
    }
  }

  Future<void> updateHireRequestPhotos(String hireId, List<String> photoUrls) async {
    try {
      await _firestore.collection('hire_requests').doc(hireId).update({
        'photos': photoUrls,
      });
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
    }
  }

  /// Professional accepts or rejects a hire request.
  Future<void> respondToHireRequest(String hireId, bool accept) async {
    try {
      _setLoading(true);
      _setError(null);

      final hireDoc = await _firestore.collection('hire_requests').doc(hireId).get();
      if (!hireDoc.exists) {
        throw Exception('Hire request not found.');
      }
      final data = hireDoc.data()!;
      final customerId = data['customerId'] as String?;
      final professionalId = data['professionalId'] as String?;
      final professionalName = data['professionalName'] as String?;
      final status = accept ? 'accepted' : 'rejected';

      await hireDoc.reference.update({
        'status': status,
        'respondedAt': DateTime.now(),
      });

      // If accepted, promote the hire request to a job.
      if (accept && customerId != null && professionalId != null) {
        final jobDocRef = _firestore.collection('jobs').doc();
        final job = JobModel(
          id: jobDocRef.id,
          customerId: customerId,
          professionalId: professionalId,
          category: data['category'] as String?,
          description: data['description'] as String?,
          budget: (data['budget'] as num?)?.toDouble(),
          address: data['address'] as String?,
          status: 'accepted',
          createdAt: DateTime.now(),
        );
        await jobDocRef.set(job.toMap());

        // Send notification to the customer.
        await _notificationService.notifyHireAccepted(
          customerId: customerId,
          professionalName: professionalName ?? 'Professional',
          hireId: hireId,
        );
      } else {
        // Send rejection notification.
        if (customerId != null) {
          await _notificationService.notifyHireRejected(
            customerId: customerId,
            professionalName: professionalName ?? 'Professional',
            hireId: hireId,
          );
        }
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  /// Loads hire requests received by a professional.
  Future<void> loadHireRequests(String professionalId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('hire_requests')
          .where('professionalId', isEqualTo: professionalId)
          .orderBy('createdAt', descending: true)
          .get();

      _hireRequests = snapshot.docs
          .map((doc) => HireRequestModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
      _setLoading(false);
    }
  }

  /// Loads hire requests sent by a customer.
  Future<void> loadCustomerHireRequests(String customerId) async {
    try {
      _setLoading(true);
      _setError(null);

      final snapshot = await _firestore
          .collection('hire_requests')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      _hireRequests = snapshot.docs
          .map((doc) => HireRequestModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTopProfessionals() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['professional', 'both'])
          .orderBy('rating', descending: true)
          .limit(10)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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

      await _notificationService.notifyJobUpdate(jobId, 'cancelled');

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(getFriendlyErrorMessage(e));
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
      _setError(getFriendlyErrorMessage(e));
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
    _jobsFeedSubscription?.cancel();
    super.dispose();
  }
}

/// Model for a direct hire request (customer → specific professional).
class HireRequestModel {
  HireRequestModel({
    this.id,
    this.customerId,
    this.customerName,
    this.professionalId,
    this.professionalName,
    this.category,
    this.description,
    this.budget,
    this.address,
    this.preferredDate,
    this.preferredTime,
    this.paymentMethod,
    this.serviceType,
    this.photos,
    this.status,
    this.createdAt,
    this.respondedAt,
  });

  factory HireRequestModel.fromMap(Map<String, dynamic> map) {
    return HireRequestModel(
      id: map['id'],
      customerId: map['customerId'],
      customerName: map['customerName'],
      professionalId: map['professionalId'],
      professionalName: map['professionalName'],
      category: map['category'],
      description: map['description'],
      budget: map['budget']?.toDouble(),
      address: map['address'],
      preferredDate: map['preferredDate'],
      preferredTime: map['preferredTime'],
      paymentMethod: map['paymentMethod'],
      serviceType: map['serviceType'],
      photos: map['photos'] != null ? List<String>.from(map['photos']) : null,
      status: map['status'],
      createdAt: map['createdAt']?.toDate(),
      respondedAt: map['respondedAt']?.toDate(),
    );
  }
  final String? id;
  final String? customerId;
  final String? customerName;
  final String? professionalId;
  final String? professionalName;
  final String? category;
  final String? description;
  final double? budget;
  final String? address;
  final String? preferredDate;
  final String? preferredTime;
  final String? paymentMethod;
  final String? serviceType;
  final List<String>? photos;
  final String? status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime? createdAt;
  final DateTime? respondedAt;

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'professionalId': professionalId,
    'professionalName': professionalName,
    'category': category,
    'description': description,
    'budget': budget,
    'address': address,
    'preferredDate': preferredDate,
    'preferredTime': preferredTime,
    'paymentMethod': paymentMethod,
    'serviceType': serviceType,
    'photos': photos ?? [],
    'status': status,
    'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    'respondedAt': respondedAt,
  };
}