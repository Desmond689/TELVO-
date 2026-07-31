// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:telvo/models/job_model.dart';
import 'package:telvo/services/api_service.dart';

class NotificationService {
  NotificationService() {
    _init();
  }
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final ApiService _api = ApiService();

  Future<void> initialize() => _init();

  Future<void> _init() async {
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
  }

  Future<void> registerToken(String userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': token,
      });
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
    // flutter_local_notifications was removed (see pubspec.yaml), so there is
    // no in-app banner while the app is in the foreground. FCM still shows a
    // system notification automatically when the app is backgrounded/killed.
    debugPrint(
      'Foreground push received: '
      '${message.notification?.title} - ${message.notification?.body}',
    );
  }

  /// Tells the backend a new job was posted so it can notify matching
  /// professionals. The backend re-derives recipients from the job record.
  Future<void> notifyProfessionals(JobModel job) async {
    try {
      if (job.id == null) return;
      await _api.triggerJobEventNotification({
        'jobId': job.id,
        'type': 'new_job',
      });
    } catch (e) {
      debugPrint('Error notifying professionals: $e');
    }
  }

  Future<void> notifyQuoteAccepted(QuoteModel quote) async {
    try {
      if (quote.jobId == null || quote.id == null) return;
      await _api.triggerJobEventNotification({
        'jobId': quote.jobId,
        'quoteId': quote.id,
        'type': 'quote_accepted',
      });
    } catch (e) {
      debugPrint('Error notifying quote accepted: $e');
    }
  }

  Future<void> notifyNewQuote(QuoteModel quote) async {
    try {
      if (quote.jobId == null || quote.id == null) return;
      await _api.triggerJobEventNotification({
        'jobId': quote.jobId,
        'quoteId': quote.id,
        'type': 'new_quote',
      });
    } catch (e) {
      debugPrint('Error notifying new quote: $e');
    }
  }

  Future<void> notifyJobUpdate(String jobId, String status) async {
    try {
      await _api.triggerJobEventNotification({
        'jobId': jobId,
        'type': 'job_update',
        'status': status,
      });
    } catch (e) {
      debugPrint('Error notifying job update: $e');
    }
  }

  Future<void> showLocalNotification(
    String title,
    String body,
    Map<String, String>? data,
  ) async {
    // flutter_local_notifications was removed (see pubspec.yaml). Kept as a
    // no-op stub so existing call sites don't need to change.
    debugPrint('showLocalNotification (no-op): $title - $body');
  }
}
