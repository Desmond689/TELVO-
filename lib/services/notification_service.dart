// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/models/notification_model.dart';

class NotificationService {
  NotificationService() {
    _init();
  }
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // Handle tap on notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
    } catch (e) {
      debugPrint('NotificationService.init error: $e');
    }
  }

  Future<void> registerToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      debugPrint('registerToken error: $e');
    }
  }

  Future<void> _handleMessage(RemoteMessage message) async {
    _showLocalNotification(message);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background message
  }

  void _handleMessageOpen(RemoteMessage message) {
    // Navigate to appropriate screen
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    debugPrint(
      'Foreground push received: '
      '${message.notification?.title} - ${message.notification?.body}',
    );
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
      final notification = NotificationModel(
        userId: userId,
        title: title,
        body: body,
        type: type,
        data: data != null ? data.toString() : null,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('notifications').add(notification.toMap());
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

      // Broadcast: notify all verified professionals matching category.
      final snapshot = await _firestore
          .collection('users')
          .where('userType', whereIn: ['professional', 'both'])
          .where('category', isEqualTo: job.category)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final userId = doc.id;
        if (userId == job.customerId) continue; // don't notify the customer
        await createNotification(
          userId: userId,
          title: 'New Job Available',
          body: 'A ${job.category} job is available near you. Send a quote!',
          type: 'new_job',
          data: {'jobId': job.id},
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