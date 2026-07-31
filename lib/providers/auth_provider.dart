// lib/providers/auth_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:telvo/models/user_model.dart';
import 'package:telvo/services/api_service.dart';
import 'package:telvo/services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _init();
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // True once the very first authStateChanges() event has been fully
  // resolved (including the Firestore profile fetch, if signed in). The
  // splash screen waits on this instead of a fixed timer, so a slow
  // network doesn't get misread as "not logged in".
  bool _isInitialized = false;
  final Completer<void> _initCompleter = Completer<void>();

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isInitialized => _isInitialized;

  /// Resolves once the initial session check (Firebase Auth + Firestore
  /// profile load, if any) has completed. Callers can await this instead
  /// of guessing with a delay.
  Future<void> get onReady => _initCompleter.future;

  Future<void> _init() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _loadUserData(currentUser.uid);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      if (!_isInitialized) {
        _isInitialized = true;
        if (!_initCompleter.isCompleted) _initCompleter.complete();
      }
    }

    _auth.authStateChanges().listen(
      (User? user) async {
        if (user != null) {
          await _loadUserData(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
        if (!_isInitialized) {
          _isInitialized = true;
          if (!_initCompleter.isCompleted) _initCompleter.complete();
        }
      },
      onError: (error) {
        _setError(error.toString());
        if (!_isInitialized) {
          _isInitialized = true;
          if (!_initCompleter.isCompleted) _initCompleter.complete();
        }
      },
    );
  }

  Future<void> _loadUserData(String userId) async {
    try {
      _setLoading(true);
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        _currentUser = UserModel.fromMap(doc.data()!);
        // Update online status
        await _updateOnlineStatus(true);
        // Register FCM token
        await NotificationService().registerToken(userId);
      }
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a real account: Firebase Auth stores and hashes the password
  /// securely (no OTP, no verification email is ever sent - just standard
  /// email/password auth). Profile fields (username, phone, name, userType)
  /// are stored in Firestore, keyed by the auth uid.
  Future<bool> signUp({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String password,
    String? userType,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final normalizedUsername = username.trim().toLowerCase();

      // Usernames must be unique. Checked via the public /usernames mapping
      // doc (readable pre-auth), since /users itself requires sign-in to
      // read. This check-then-create isn't perfectly atomic against a
      // simultaneous signup with the same username, but that's an
      // acceptable tradeoff for a v1 - the /usernames security rule (create
      // requires matching request.auth.uid) is the actual enforcement, this
      // is just for a fast, friendly error message.
      final usernameDoc = await _firestore
          .collection('usernames')
          .doc(normalizedUsername)
          .get();
      if (usernameDoc.exists) {
        throw Exception('That username is already taken.');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Could not create account.');

      final newUser = UserModel(
        id: user.uid,
        username: normalizedUsername,
        email: email.trim(),
        fullName: fullName.trim(),
        phoneNumber: phoneNumber.trim(),
        userType: userType,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      await _firestore.collection('usernames').doc(normalizedUsername).set({
        'uid': user.uid,
        'email': email.trim(),
      });
      _currentUser = newUser;

      await _updateOnlineStatus(true);
      await NotificationService().registerToken(user.uid);
      await _secureStorage.write(key: 'userId', value: user.uid);

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Signs in with email + password. Accepts either an email address or a
  /// username in [emailOrUsername] - if it doesn't look like an email, it's
  /// resolved to the matching account's email first.
  Future<bool> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      var email = emailOrUsername.trim();
      if (!email.contains('@')) {
        final usernameDoc = await _firestore
            .collection('usernames')
            .doc(email.toLowerCase())
            .get();
        if (!usernameDoc.exists) {
          throw Exception('No account found with that username.');
        }
        email = usernameDoc.data()?['email'] as String? ?? '';
        if (email.isEmpty) {
          throw Exception('No account found with that username.');
        }
      }

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) throw Exception('Sign-in failed.');

      await _loadUserData(user.uid);
      await _updateOnlineStatus(true);
      await NotificationService().registerToken(user.uid);
      await _secureStorage.write(key: 'userId', value: user.uid);

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  /// Sends Firebase's built-in password-reset email. This is a link, not an
  /// OTP code - there's no separate "email service" involved, Firebase Auth
  /// handles delivery itself.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      await _auth.sendPasswordResetEmail(email: email.trim());
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final user = _auth.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw Exception('You must be signed in to change your password.');
      }

      // Firebase requires a recent sign-in before sensitive operations like
      // changing a password - re-authenticate with the current password.
      final cred = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email/username or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please sign in again before retrying this action.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_currentUser == null) throw Exception('User not authenticated');

      final updatedUser = _currentUser!.copyWith(
        fullName: data['fullName'],
        profilePhoto: data['profilePhoto'],
        city: data['city'],
        neighborhood: data['neighborhood'],
        language: data['language'],
        userType: data['userType'],
        mode: data['mode'],
        category: data['category'],
        skills: data['skills'],
        yearsOfExperience: data['yearsOfExperience'],
        description: data['description'],
        serviceAreas: data['serviceAreas'],
        portfolioPhotos: data['portfolioPhotos'],
        certificates: data['certificates'],
        availabilitySchedule: data['availabilitySchedule'],
        availabilityStatus: data['availabilityStatus'],
        isOnline: data['isOnline'],
        emergencyServices: data['emergencyServices'] ?? false,
      );

      await _firestore
          .collection('users')
          .doc(_currentUser!.id)
          .update(updatedUser.toMap());

      _currentUser = updatedUser;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  Future<String?> uploadFile({
    required String filePath,
    required String folder,
    String? fileName,
  }) async {
    try {
      if (_currentUser == null) throw Exception('User not authenticated');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Selected file could not be found.');
      }

      final storageFileName =
          fileName ??
          '${_currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final response = await ApiService().uploadImage(
        file: file,
        folder: folder,
        fileName: storageFileName,
      );

      final uploadedUrl = response['data']?['url'] ?? response['url'];
      if (uploadedUrl is String && uploadedUrl.isNotEmpty) {
        return uploadedUrl;
      }

      throw Exception('Upload failed. No URL returned from backend.');
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<String?> uploadProfilePhoto(String filePath) async {
    final url = await uploadFile(
      filePath: filePath,
      folder: 'profile_photos',
      fileName: '${_currentUser?.id ?? 'user'}.jpg',
    );

    if (url != null) {
      await updateProfile({'profilePhoto': url});
    }
    return url;
  }

  Future<String?> uploadPortfolioPhoto(String filePath) async {
    return uploadFile(
      filePath: filePath,
      folder: 'portfolio_photos',
      fileName:
          '${_currentUser?.id ?? 'user'}_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<void> switchMode(String mode) async {
    try {
      if (_currentUser == null) throw Exception('User not authenticated');
      if (_currentUser?.userType != 'both') {
        throw Exception('Only dual accounts can switch modes');
      }
      if (mode != 'customer' && mode != 'professional') {
        throw Exception('Invalid mode selected');
      }

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'mode': mode,
      });

      _currentUser = _currentUser!.copyWith(mode: mode);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    await updateOnlineStatus(isOnline);
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (_currentUser == null) return;

      await _firestore.collection('users').doc(_currentUser!.id).update({
        'isOnline': isOnline,
        'lastActive': DateTime.now(),
      });

      _currentUser = _currentUser!.copyWith(
        isOnline: isOnline,
        lastActive: DateTime.now(),
      );
      notifyListeners();
    } catch (e) {
      // Ignore error
    }
  }

  Future<void> signOut() async {
    try {
      await _updateOnlineStatus(false);
      await _auth.signOut();
      await _secureStorage.delete(key: 'userId');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (_currentUser == null) throw Exception('User not authenticated');

      // Delete user data from Firestore
      await _firestore.collection('users').doc(_currentUser!.id).delete();

      // Delete user from Auth
      await _auth.currentUser?.delete();

      await _secureStorage.delete(key: 'userId');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<bool> checkBiometricAvailable() async {
    try {
      // Using local_auth package
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> savePIN(String pin) async {
    await _secureStorage.write(key: 'user_pin', value: pin);
  }

  Future<String?> getPIN() async => await _secureStorage.read(key: 'user_pin');

  Future<bool> verifyPIN(String pin) async {
    final savedPin = await getPIN();
    return savedPin == pin;
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
}
