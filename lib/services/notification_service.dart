// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/models/notification_model.dart';

class NotificationService {
  static NotificationService? _instance;

  /// Use NotificationService() in production. For tests, use
  /// NotificationService.test(firestore: ...) to supply a fake Firestore.
  factory NotificationService({FirebaseMessaging? fcm, FirebaseFirestore? firestore, Stream<String>? tokenRefreshStream, bool autoInit = true}) {
    if (_instance == null) {
      _instance = NotificationService._internal(
        fcm ?? FirebaseMessaging.instance,
        firestore ?? FirebaseFirestore.instance,
        tokenRefreshStream: tokenRefreshStream,
        autoInit: autoInit,
      );
    }
    return _instance!;
  }

  /// Optional override stream for token refresh events during tests.
  final Stream<String>? tokenRefreshStream;

  /// Test constructor that returns a non-singleton used by tests.
  NotificationService.test({required FirebaseFirestore firestore, this.tokenRefreshStream})
      : _fcm = FirebaseMessaging.instance,
        _firestore = firestore {
    // Do not auto-initialize listeners in tests.
  }

  NotificationService._internal(this._fcm, this._firestore, {bool autoInit = true, this.tokenRefreshStream}) {
    if (autoInit) _init();
  }

  final FirebaseMessaging _fcm;
  final FirebaseFirestore _firestore;
  StreamSubscription<String>? _tokenRefreshSubscription;

  // Stream for UI components to listen for incoming foreground messages and
  // show transient banners/snackbars.
  static final StreamController<RemoteMessage> _onMessageStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessageStream => _onMessageStreamController.stream;

  Future<void> initialize() => _init();

  Future<void> _init() async {
    try {
      // Request permissions
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      // Get token
      final token = await _fcm.getToken();
      debugPrint('FCM Token: $token');

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleMessage);

      // Handle background messages (static entrypoint)
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle tap on notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  /// Register the current device token in Firestore for [userId].
  /// Optional [testingToken] can be provided by tests to avoid relying on FCM.
  Future<void> registerToken(String userId, {String? testingToken}) async {
    try {
      final token = testingToken ?? await _fcm.getToken();
      if (token != null) {
        await _saveTokenToFirestore(userId, token);
      }

      // Keep the user's Firestore doc updated when the FCM token rotates.
      _tokenRefreshSubscription?.cancel();
      final refreshStream = tokenRefreshStream ?? _fcm.onTokenRefresh;
      _tokenRefreshSubscription = refreshStream.listen((newToken) async {
        try {
          if (newToken.isNotEmpty) {
            await _saveTokenToFirestore(userId, newToken);
            debugPrint('FCM token refreshed and saved for user $userId');
          }
        } catch (e) {
          debugPrint('onTokenRefresh update error: $e');
        }
      });
    } catch (e) {
      debugPrint('registerToken error: $e');
    }
  }

  /// Public helper that saves a token to Firestore. Useful for unit tests
  /// and for the onTokenRefresh handler.
  Future<void> _saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
    } catch (e) {
      debugPrint('_saveTokenToFirestore error: $e');
    }
  }

  /// Removes the FCM token from the user's Firestore document. Call this on
  /// sign-out so the backend no longer targets this device for notifications.
  Future<void> unregisterToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (e) {
      debugPrint('unregisterToken error: $e');
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    try {
      // Broadcast to any in-app listeners (UI) so a transient banner can be shown.
      if (!_onMessageStreamController.isClosed) {
        _onMessageStreamController.add(message);
      }
    } catch (e) {
      // ignore
    }
    await _showLocalNotification(message);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    try {
      // Background handlers run in their own isolate. Initialize Firebase
      // minimally so Firestore can be used to persist the notification for the app UI.
      await Firebase.initializeApp();
      final firestore = FirebaseFirestore.instance;

      // Safely extract fields from the message. message.data is usually
      // Map<String, dynamic> but may be Map<String, String> depending on the
      // sender. Normalize to a Map<String, dynamic>.
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data ?? {});

      final title = message.notification?.title ?? (data['title'] is String ? data['title'] as String : '');
      final body = message.notification?.body ?? (data['body'] is String ? data['body'] as String : '');

      final notif = <String, dynamic>{
        'title': title,
        'body': body,
        'data': data,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Attempt to persist the notification. If Firestore is unreachable,
      // catch and log but do not crash the background handler.
      try {
        await firestore.collection('notifications').add(notif);
        debugPrint('Background message persisted to Firestore: ${notif['title']}');
      } catch (e) {
        debugPrint('Failed to persist background notification: $e');
      }
    } catch (e) {
      debugPrint('background message handler error: $e');
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    // Navigate to appropriate screen — handled by the UI layer when
    // necessary. Keeping this lightweight to avoid retaining UI references.
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final data = Map<String, dynamic>.from(message.data ?? {});
      final userId = (data['userId'] is String ? data['userId'] as String : (data['toUserId'] is String ? data['toUserId'] as String : null));
      final title = message.notification?.title ?? (data['title'] is String ? data['title'] as String : '');
      final body = message.notification?.body ?? (data['body'] is String ? data['body'] as String : '');

      // Persist the notification so the in-app notifications screen shows it
      if (userId != null && userId.isNotEmpty) {
        await createNotification(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      }

      // Fallback logging for debugging / ephemeral UI (apps that prefer
      // in-app banners can read the notifications collection to display them).
      debugPrint('Foreground push received: $title - $body');
    } catch (e) {
      debugPrint('showLocalNotification error: $e');
    }
  }

  /// Writes a notification document directly to Firestore. This is how the
  /// app generates in-app notifications without depending on a reachable
  /// backend server (the old ApiService.triggerJobEventNotification calls
  /// silently failed when api.telvo.com was unreachable).
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final payload = <String, dynamic>{
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'pushSent': false,
      };
      if (data != null) {
        // Store as Map so Cloud Functions / FCM can use typed fields
        payload['data'] = data.map((k, v) => MapEntry(k.toString(), v?.toString()));
      }
      await _firestore.collection('notifications').add(payload);
    } catch (e) {
      debugPrint('createNotification error: $e');
    }
  }

  /// Tells professionals a new job was posted by writing notification docs
  /// for each professional whose category matches the job, and (optionally)
  /// the specific professional the job was directed at.
  Future<void> notifyProfessionals(JobModel job) async {
    try {
      // Direct hire: notify only the one professional.
      if (job.professionalId != null && job.professionalId!.isNotEmpty) {
        await createNotification(
          userId: job.professionalId!,
          title: 'New Job Request',
          body: 'A customer posted a new ${job.category ?? 'service'} job. Tap to view.',
          type: 'new_job',
          data: {'jobId': job.id},
        );
        return;
      }

      // Broadcast: match professionals by normalized category (case-insensitive).
      final jobCat = (job.category ?? '').trim().toLowerCase();
      // Prefer categoryNormalized when present; fall back to scanning category.
      QuerySnapshot<Map<String, dynamic>> snapshot;
      try {
        snapshot = await _firestore
            .collection('users')
            .where('userType', whereIn: ['professional', 'both'])
            .where('categoryNormalized', isEqualTo: jobCat)
            .limit(200)
            .get();
      } catch (_) {
        snapshot = await _firestore
            .collection('users')
            .where('userType', whereIn: ['professional', 'both'])
            .limit(200)
            .get();
      }

      for (final doc in snapshot.docs) {
        final userId = doc.id;
        if (userId == job.customerId) continue;
        final data = doc.data();
        final userCat = ((data['categoryNormalized'] as String?) ??
                (data['category'] as String?) ??
                '')
            .trim()
            .toLowerCase();
        if (jobCat.isNotEmpty && userCat != jobCat) continue;
        await createNotification(
          userId: userId,
          title: 'New Job Available',
          body: 'A ${job.category} job is available near you. Send a quote!',
          type: 'new_job',
          data: {'jobId': job.id ?? ''},
        );
      }
    } catch (e) {
      debugPrint('notifyProfessionals error: $e');
    }
  }

  Future<void> notifyQuoteAccepted(QuoteModel quote) async {
    try {
      await createNotification(
        userId: quote.professionalId ?? '',
        title: 'Quote Accepted!',
        body: 'The customer accepted your quote. Start working on the job.',
        type: 'quote_accepted',
        data: {'jobId': quote.jobId, 'quoteId': quote.id},
      );
    } catch (e) {
      debugPrint('notifyQuoteAccepted error: $e');
    }
  }

  Future<void> notifyNewQuote(QuoteModel quote) async {
    try {
      // Fetch the job to get the customer's ID.
      if (quote.jobId == null) return;
      final jobDoc = await _firestore.collection('jobs').doc(quote.jobId).get();
      if (!jobDoc.exists) return;
      final customerId = jobDoc.data()?['customerId'] as String?;
      if (customerId == null) return;

      await createNotification(
        userId: customerId,
        title: 'New Quote Received',
        body: 'A professional sent you a quote for your job.',
        type: 'new_quote',
        data: {'jobId': quote.jobId, 'quoteId': quote.id},
      );
    } catch (e) {
      debugPrint('notifyNewQuote error: $e');
    }
  }

  Future<void> notifyJobUpdate(String jobId, String status) async {
    try {
      final jobDoc = await _firestore.collection('jobs').doc(jobId).get();
      if (!jobDoc.exists) return;
      final data = jobDoc.data()!;
      final customerId = data['customerId'] as String?;
      final professionalId = data['professionalId'] as String?;

      final statusMessages = {
        'accepted': 'Your job was accepted by a professional.',
        'in_progress': 'The professional has started working on your job.',
        'worker_travels': 'The professional is on the way to you.',
        'completed': 'The job has been completed. Please leave a review.',
        'cancelled': 'The job has been cancelled.',
        'reviewed': 'You have a new review.',
      };

      final message = statusMessages[status] ?? 'Your job status changed to $status';

      if (customerId != null) {
        await createNotification(
          userId: customerId,
          title: 'Job Update',
          body: message,
          type: 'job_update',
          data: {'jobId': jobId, 'status': status},
        );
      }
      if (professionalId != null && status == 'completed') {
        await createNotification(
          userId: professionalId,
          title: 'Job Completed',
          body: 'You completed a job. Payment has been processed.',
          type: 'job_completed',
          data: {'jobId': jobId, 'status': status},
        );
      }
    } catch (e) {
      debugPrint('notifyJobUpdate error: $e');
    }
  }

  Future<void> notifyNewHireRequest({
    required String professionalId,
    required String customerId,
    required String customerName,
    required String category,
    required String hireId,
  }) async {
    await createNotification(
      userId: professionalId,
      title: 'New Hire Request',
      body: '$customerName wants to hire you for $category.',
      type: 'hire_request',
      data: {'hireId': hireId, 'customerId': customerId},
    );
  }

  Future<void> notifyHireAccepted({
    required String customerId,
    required String professionalName,
    required String hireId,
  }) async {
    await createNotification(
      userId: customerId,
      title: 'Hire Request Accepted',
      body: '$professionalName accepted your hire request.',
      type: 'hire_accepted',
      data: {'hireId': hireId},
    );
  }

  Future<void> notifyHireRejected({
    required String customerId,
    required String professionalName,
    required String hireId,
  }) async {
    await createNotification(
      userId: customerId,
      title: 'Hire Request Declined',
      body: '$professionalName declined your hire request.',
      type: 'hire_rejected',
      data: {'hireId': hireId},
    );
  }

  Future<void> showLocalNotification(
    String title,
    String body,
    Map<String, String>? data,
  ) async {
    debugPrint('showLocalNotification (no-op): $title - $body');
  }
}