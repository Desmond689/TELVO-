// lib/services/notification_tap_router.dart
//
// Single place that decides where a notification tap should navigate to.
// Previously this logic only lived inside ForegroundNotificationManager's
// in-app banner, which meant tapping the *system tray* notification (app
// backgrounded, or launching the app fresh from a terminated state) did
// nothing at all - the tap was received but never routed anywhere.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:telvo/config/routes.dart';
import 'package:telvo/services/app_navigator.dart';

class NotificationTapRouter {
  NotificationTapRouter._();

  /// Routes to the right screen for a notification of [type] carrying
  /// [data]. Safe to call multiple times / before the navigator is ready -
  /// it no-ops if there's no current context yet.
  static void handle(String? type, Map<String, dynamic>? data) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('NotificationTapRouter: no navigator context yet, dropping tap for type=$type');
      return;
    }

    try {
      if (type == 'chat' || type == 'message') {
        final thread = data?['thread'] ?? data?['chatId'] ?? data?['threadId'];
        Navigator.pushNamed(ctx, AppRoutes.chat, arguments: thread);
        return;
      }

      if (type == 'new_job' || type == 'job_update' || type == 'job_completed' ||
          type == 'new_quote' || type == 'quote_accepted' || type == 'new_review' ||
          type == 'hire_request' || type == 'hire_accepted' || type == 'hire_rejected') {
        // Many screens expect a full job/hire object; fall back to the
        // notifications list which can navigate on from there.
        Navigator.pushNamed(ctx, AppRoutes.notifications);
        return;
      }

      if (type == 'payment') {
        Navigator.pushNamed(ctx, AppRoutes.payment);
        return;
      }

      // Default fallback: open the notifications screen.
      Navigator.pushNamed(ctx, AppRoutes.notifications);
    } catch (e) {
      debugPrint('NotificationTapRouter.handle error: $e');
    }
  }
}
