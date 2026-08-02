import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

String getFriendlyErrorMessage(Object error, {String fallback = 'Something went wrong. Please try again.'}) {
  final message = error.toString().toLowerCase();

  if (error is SocketException ||
      error.toString().contains('socketexception') ||
      error.toString().contains('failed host lookup') ||
      error.toString().contains('network-request-failed') ||
      message.contains('connection refused') ||
      message.contains('timed out')) {
    return 'No internet connection. Please check your connection and try again.';
  }

  if (message.contains('permission-denied')) {
    return "You don't have permission to perform this action.";
  }

  if (message.contains('not-found')) {
    return 'The requested information could not be found.';
  }

  if (message.contains('invalid-credential') || message.contains('wrong-password') || message.contains('user-not-found')) {
    return 'Incorrect email or password.';
  }

  if (message.contains('cloud_firestore/unavailable') || message.contains('unavailable')) {
    return 'No internet connection. Please check your connection and try again.';
  }

  if (message.contains('network') || message.contains('connect')) {
    return 'Unable to connect. Please check your internet.';
  }

  if (message.contains('upload failed') ||
      message.contains('upload') && message.contains('failed')) {
    return 'Unable to upload image. Please check your internet connection or try again later.';
  }

  if (message.contains('username') && message.contains('taken')) {
    return 'That username is already taken.';
  }

  if (message.contains('email-already-in-use')) {
    return 'An account already exists with that email.';
  }

  if (message.contains('weak-password')) {
    return 'Password should be at least 6 characters.';
  }

  if (message.contains('user-disabled')) {
    return 'This account has been disabled.';
  }

  if (error is FirebaseException) {
    final code = error.code.toLowerCase();
    if (code.contains('permission-denied')) {
      return "You don't have permission to perform this action.";
    }
    if (code.contains('unavailable')) {
      return 'No internet connection. Please check your connection and try again.';
    }
    if (code.contains('not-found')) {
      return 'The requested information could not be found.';
    }
    if (code.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
  }

  return fallback;
}
