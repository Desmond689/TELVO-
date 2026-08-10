import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class Helpers {
  /// Whether the device currently has real internet access.
  ///
  /// `connectivity_plus` on its own only reports whether a network
  /// *interface* is up (Wi-Fi/mobile data associated) - it says nothing
  /// about whether that connection actually reaches the internet (captive
  /// portals, a router with no WAN, VPN edge cases, etc). Trusting it alone
  /// for a user-facing "no internet" message caused two problems:
  ///   1. It could report "connected" with no real internet, or transiently
  ///      "none" right after a network handoff, producing a wrong verdict.
  ///   2. Any callers that treated this as the *only* signal for "offline"
  ///      would mislabel unrelated errors (a Firestore permission error, a
  ///      malformed query, a parsing exception) as "no internet connection"
  ///      whenever this check happened to be flaky at that exact moment.
  ///
  /// This does a real reachability check as a tie-breaker, and never
  /// silently reports "offline" just because the check itself failed.
  static Future<bool> checkInternetConnection() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasNoInterface = connectivityResults.isEmpty ||
          connectivityResults.every((r) => r == ConnectivityResult.none);
      if (hasNoInterface) return false;

      try {
        final lookup = await InternetAddress.lookup('firestore.googleapis.com')
            .timeout(const Duration(seconds: 4));
        return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
      } on SocketException {
        return false;
      } on TimeoutException {
        // Ambiguous (slow DNS, not necessarily offline) - don't punish the
        // user for this alone; let the real network call be the judge.
        return true;
      }
    } catch (_) {
      // The connectivity_plus platform channel itself failed. Assume online
      // rather than surfacing a false "no internet" message.
      return true;
    }
  }

  /// Opens the phone dialer pre-filled with [phoneNumber]. Used for
  /// emergency contacts, SOS actions, and in-app "call" buttons. Shows a
  /// snackbar instead of throwing if the device has no way to place calls
  /// (e.g. some tablets/emulators).
  static Future<void> callNumber(
    BuildContext context,
    String phoneNumber,
  ) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    var launched = false;
    try {
      launched = await launchUrl(uri);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      showSnackBar(
        context,
        "This device can't place calls.",
        backgroundColor: Colors.red,
      );
    }
  }

  static Future<void> saveToSharedPreferences(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String?> getFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> removeFromSharedPreferences(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Colors.black87,
        duration: duration ?? const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.red);
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: Colors.green);
  }

  static String getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  static bool isImageFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  static bool isVideoFile(String fileName) {
    final extension = getFileExtension(fileName);
    return ['mp4', 'mov', 'avi', 'wmv', 'flv', 'mkv'].contains(extension);
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  static String generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString();

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    return phoneRegex.hasMatch(phone);
  }

  static Future<bool> isAppInForeground() async {
    // This would require the flutter_local_notifications package
    return true;
  }

  static Map<String, String> getPlatformHeaders() => {
    'Platform': Platform.operatingSystem,
    'Version': Platform.operatingSystemVersion,
    'App-Version': '1.0.0',
  };

  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  static String toTitleCase(String text) => text
      .split(' ')
      .map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      })
      .join(' ');
}
