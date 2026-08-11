import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  static FirebaseApp? _app;
  static FirebaseAuth? _auth;
  static FirebaseFirestore? _firestore;

  static Future<void> initialize() async {
    // Support both a local .env file and CI-provided environment variables.
    final apiKey = (dotenv.env['FIREBASE_API_KEY'] ?? '').isNotEmpty
        ? dotenv.env['FIREBASE_API_KEY']!
        : const String.fromEnvironment('FIREBASE_API_KEY');
    final appId = (dotenv.env['FIREBASE_APP_ID'] ?? '').isNotEmpty
        ? dotenv.env['FIREBASE_APP_ID']!
        : const String.fromEnvironment('FIREBASE_APP_ID');
    final senderId = (dotenv.env['FIREBASE_SENDER_ID'] ?? '').isNotEmpty
        ? dotenv.env['FIREBASE_SENDER_ID']!
        : const String.fromEnvironment('FIREBASE_SENDER_ID');
    final projectId = (dotenv.env['FIREBASE_PROJECT_ID'] ?? '').isNotEmpty
        ? dotenv.env['FIREBASE_PROJECT_ID']!
        : const String.fromEnvironment('FIREBASE_PROJECT_ID');
    final authDomain = (dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '').isNotEmpty
        ? dotenv.env['FIREBASE_AUTH_DOMAIN']!
        : const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

    final missing = <String>[];
    if (apiKey.isEmpty || apiKey.startsWith('your_')) missing.add('FIREBASE_API_KEY');
    if (appId.isEmpty || appId.startsWith('your_')) missing.add('FIREBASE_APP_ID');
    if (senderId.isEmpty || senderId.startsWith('your_')) missing.add('FIREBASE_SENDER_ID');
    if (projectId.isEmpty || projectId.startsWith('your_')) missing.add('FIREBASE_PROJECT_ID');

    if (missing.isNotEmpty) {
      throw Exception('Missing Firebase configuration: ${missing.join(', ')}. Provide these via .env or CI environment variables.');
    }

    final app = await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        authDomain: authDomain,
      ),
    );

    _app = app;
    _auth = FirebaseAuth.instanceFor(app: app);
    _firestore = FirebaseFirestore.instanceFor(app: app);
  }

  static FirebaseAuth get auth => _auth!;
  static FirebaseFirestore get firestore => _firestore!;
  static FirebaseApp get app => _app!;

  static Future<void> setPersistence() async {
    await auth.setPersistence(Persistence.LOCAL);
  }
}
