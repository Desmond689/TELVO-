// lib/main.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telvo/providers/auth_provider.dart';
import 'package:telvo/providers/job_provider.dart';
import 'package:telvo/providers/user_provider.dart';
import 'package:telvo/providers/chat_provider.dart';
import 'package:telvo/providers/payment_provider.dart';
import 'package:telvo/providers/notification_provider.dart';
import 'package:telvo/providers/admin_provider.dart';
import 'package:telvo/theme/app_theme.dart';
import 'package:telvo/config/app_config.dart';
import 'package:telvo/config/routes.dart';
import 'package:flutter/services.dart';
import 'package:telvo/services/notification_service.dart';
import 'package:telvo/screens/dev/dev_config_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:telvo/services/app_update_service.dart';
import 'package:telvo/services/foreground_notification_manager.dart';
import 'package:telvo/services/app_navigator.dart';
import 'package:telvo/screens/splash_screen.dart';
import 'package:telvo/screens/welcome_screen.dart';
import 'package:telvo/screens/auth/login_screen.dart';
import 'package:telvo/screens/auth/forgot_password_screen.dart';
import 'package:telvo/screens/auth/signup_screen.dart';
import 'package:telvo/screens/auth/profile_setup_screen.dart';
import 'package:telvo/screens/auth/choose_mode_screen.dart';
import 'package:telvo/screens/customer/home_screen.dart';
import 'package:telvo/screens/professional/dashboard_screen.dart';
import 'package:telvo/screens/customer/search_screen.dart';
import 'package:telvo/screens/customer/professional_profile_screen.dart';
import 'package:telvo/screens/customer/job_post_screen.dart';
import 'package:telvo/screens/customer/job_tracking_screen.dart';
import 'package:telvo/screens/customer/job_details_screen.dart';
import 'package:telvo/screens/customer/payment_screen.dart';
import 'package:telvo/screens/customer/review_screen.dart';
import 'package:telvo/screens/customer/favorites_screen.dart';
import 'package:telvo/screens/customer/history_screen.dart';
import 'package:telvo/screens/chat/chat_list_screen.dart';
import 'package:telvo/screens/chat/chat_screen.dart';
import 'package:telvo/screens/notifications/notifications_screen.dart';
import 'package:telvo/screens/settings/settings_screen.dart';
import 'package:telvo/screens/profile/profile_screen.dart';
import 'package:telvo/screens/safety/safety_screen.dart';
import 'package:telvo/screens/safety/id_verification_screen.dart';
import 'package:telvo/screens/safety/trusted_contacts_screen.dart';
import 'package:telvo/screens/sos/sos_screen.dart';
import 'package:telvo/screens/business/business_account_screen.dart';
import 'package:telvo/screens/ai/ai_assistant_screen.dart';
import 'package:telvo/screens/emergency/emergency_screen.dart';
import 'package:telvo/screens/professional/professional_setup_screen.dart';
import 'package:telvo/screens/professional/availability_screen.dart';
import 'package:telvo/screens/professional/earnings_screen.dart';
import 'package:telvo/screens/professional/job_history_screen.dart';
import 'package:telvo/screens/professional/job_feed_screen.dart';
import 'package:telvo/screens/professional/reviews_screen.dart';
import 'package:telvo/admin/admin_login.dart';
import 'package:telvo/admin/admin_dashboard.dart';
import 'package:telvo/admin/admin_main.dart';

// Global navigator key for accessing context from anywhere.
// Provided from services/app_navigator.dart.
void _checkForAppUpdate() {
  final updateService = AppUpdateService();
  updateService.checkForUpdate().then((update) {
    final context = navigatorKey.currentContext;
    if (update == null || context == null || !context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog<void>(
        context: context,
        barrierDismissible: !update.isForceUpdate,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Update available'),
            content: Text(
              update.releaseNotes.isEmpty
                  ? 'A newer version of TELVO is available (${update.version}).'
                  : 'A newer version of TELVO is available (${update.version}).\n\n${update.releaseNotes}',
            ),
            actions: [
              if (!update.isForceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Later'),
                ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  await updateService.openDownloadUrl(update.apkUrl);
                },
                child: const Text('Update now'),
              ),
            ],
          );
        },
      );
    });
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;

  try {
    // Load environment variables from .env file if it exists
    // In CI/production, these may come from environment variables instead
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('Note: .env file not found, will try environment variables: $e');
    }

    // Read configuration values - check .env, compile-time defines, then
    // SharedPreferences (dev override). This helps local debug builds where
    // a .env file isn't bundled and CI uses secrets instead.
    final fromDotenv = (String? key) => (dotenv.env[key] ?? '');
    final fromDefine = (String key) => String.fromEnvironment(key);

    final apiKeyRaw = fromDotenv('FIREBASE_API_KEY').isNotEmpty
      ? fromDotenv('FIREBASE_API_KEY')
      : fromDefine('FIREBASE_API_KEY');
    final appIdRaw = fromDotenv('FIREBASE_APP_ID').isNotEmpty
      ? fromDotenv('FIREBASE_APP_ID')
      : fromDefine('FIREBASE_APP_ID');
    final senderIdRaw = fromDotenv('FIREBASE_SENDER_ID').isNotEmpty
      ? fromDotenv('FIREBASE_SENDER_ID')
      : fromDefine('FIREBASE_SENDER_ID');
    final projectIdRaw = fromDotenv('FIREBASE_PROJECT_ID').isNotEmpty
      ? fromDotenv('FIREBASE_PROJECT_ID')
      : fromDefine('FIREBASE_PROJECT_ID');
    final authDomainRaw = fromDotenv('FIREBASE_AUTH_DOMAIN').isNotEmpty
      ? fromDotenv('FIREBASE_AUTH_DOMAIN')
      : fromDefine('FIREBASE_AUTH_DOMAIN');

    // Check for developer overrides stored in SharedPreferences (debug-only)
    final sp = await SharedPreferences.getInstance();
    final apiKey = sp.getString('DEV_FIREBASE_API_KEY') ?? apiKeyRaw;
    final appId = sp.getString('DEV_FIREBASE_APP_ID') ?? appIdRaw;
    final senderId = sp.getString('DEV_FIREBASE_SENDER_ID') ?? senderIdRaw;
    final projectId = sp.getString('DEV_FIREBASE_PROJECT_ID') ?? projectIdRaw;
    final authDomain = sp.getString('DEV_FIREBASE_AUTH_DOMAIN') ?? authDomainRaw;

    // Validate that required Firebase configuration is present
    final missingOrPlaceholder = <String>[
      if (apiKey.isEmpty || apiKey.startsWith('your_')) 'FIREBASE_API_KEY',
      if (appId.isEmpty || appId.startsWith('your_')) 'FIREBASE_APP_ID',
      if (senderId.isEmpty || senderId.startsWith('your_')) 'FIREBASE_SENDER_ID',
      if (projectId.isEmpty || projectId.startsWith('your_')) 'FIREBASE_PROJECT_ID',
    ];

    if (missingOrPlaceholder.isNotEmpty) {
      if (kDebugMode) {
        // In debug, show a small interactive screen to enter keys instead of
        // crashing. This helps local development when .env isn't present.
        runApp(MaterialApp(home: DevConfigScreen(missingOrPlaceholder)));
        return;
      }

      throw Exception(
        'Missing or placeholder Firebase configuration: '
        '${missingOrPlaceholder.join(', ')}.\n\n'
        'This build cannot connect to Firebase.\n\n'
        'To fix this:\n'
        '1. Copy .env.example to .env\n'
        '2. Fill in your Firebase credentials from https://console.firebase.google.com/\n'
        '3. For CI/GitHub Actions, set these as repository secrets and pass them to the build process.\n\n'
        'For more details, check your project\'s setup documentation.',
      );
    }

    // Initialize Firebase with validated configuration
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: senderId,
        projectId: projectId,
        authDomain: authDomain,
      ),
    );

    // Enable Firestore offline persistence for better UX
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    // Initialize notification service
    await NotificationService().initialize();
  } catch (e, st) {
    debugPrint('Fatal startup error: $e\n$st');
    startupError = e.toString();
  }

  if (startupError != null) {
    // Do not continue into the normal provider/app tree: every provider
    // touches Firebase in its constructor, so continuing would just cause a
    // cascade of confusing secondary failures (or crash outright). Show a
    // clear, honest error screen instead.
    runApp(_StartupErrorApp(message: startupError));
    return;
  }

  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Determine start locale: saved preference -> device locale -> fallback
  final prefs = await SharedPreferences.getInstance();
  final savedLocale = prefs.getString('locale');
  final savedDarkMode = prefs.getBool('useDarkTheme');
  appThemeMode.value = savedDarkMode == true ? ThemeMode.dark : ThemeMode.system;
  final ui.Locale deviceLocale = ui.PlatformDispatcher.instance.locale;
  final Locale startLocale = savedLocale != null
      ? Locale(savedLocale)
      : (deviceLocale.languageCode == 'fr' ? const Locale('fr') : const Locale('en'));

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('fr')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: startLocale,
      child: const MyApp(),
    ),
  );
}

/// Shown instead of the real app when Firebase/config fails to initialize
/// at startup, so failures are visible instead of silently producing a
/// broken app that looks normal.
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B0B0F),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                const Text(
                  "TELVO couldn't start",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message ?? 'Unknown startup error.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This is a configuration problem with this build, not your device or network.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void initAppUpdateCheck() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _checkForAppUpdate();
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initAppUpdateCheck();

    // Initialize the foreground notification manager to show a custom
    // in-app banner for incoming messages.
    try {
      ForegroundNotificationManager().initialize();

      // Also request the native layer to create the Android notification
      // channel so background/system notifications use the same channel.
      const method = MethodChannel('com.telvoapp/notifications');
      method.invokeMethod('createNotificationChannel', {
        'id': 'default_notification_channel',
        'name': 'Default',
        'importance': 'high',
      }).catchError((e) {
        debugPrint('Failed to create native notification channel: $e');
      });

      // If the app was launched by tapping a notification from a fully
      // terminated state, navigate once the navigator is actually mounted
      // (a frame after this widget builds).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationService().handleInitialMessageIfAny();
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => JobProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return ValueListenableBuilder<ThemeMode>(
            valueListenable: appThemeMode,
            builder: (context, themeMode, child) {
              return MaterialApp(
                title: AppConfig.appName,
                debugShowCheckedModeBanner: false,
                navigatorKey: navigatorKey,
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                initialRoute: AppRoutes.splash,
                routes: {
                  AppRoutes.splash: (context) => const SplashScreen(),
                  AppRoutes.welcome: (context) => const WelcomeScreen(),
                  AppRoutes.login: (context) => const LoginScreen(),
                  AppRoutes.signup: (context) => const SignupScreen(),
                  AppRoutes.forgotPassword: (context) => const ForgotPasswordScreen(),
                  AppRoutes.profileSetup: (context) => const ProfileSetupScreen(),
                  AppRoutes.chooseMode: (context) => const ChooseModeScreen(),
                  AppRoutes.professionalSetup: (context) =>
                      const ProfessionalSetupScreen(),
                  AppRoutes.home: (context) => const HomeScreen(),
                  AppRoutes.search: (context) => const SearchScreen(),
                  AppRoutes.professionalProfile: (context) =>
                      const ProfessionalProfileScreen(),
                  AppRoutes.jobPost: (context) => const JobPostScreen(),
                  AppRoutes.suspended: (context) => const SuspendedScreen(),
                  AppRoutes.jobTracking: (context) => const JobTrackingScreen(),
                  AppRoutes.jobDetails: (context) => const JobDetailsScreen(),
                  AppRoutes.payment: (context) => const PaymentScreen(),
                  AppRoutes.review: (context) => const ReviewScreen(),
                  AppRoutes.favorites: (context) => const FavoritesScreen(),
                  AppRoutes.history: (context) => const HistoryScreen(),
                  AppRoutes.professionalDashboard: (context) =>
                      const ProfessionalDashboardScreen(),
                  AppRoutes.availability: (context) => const AvailabilityScreen(),
                  AppRoutes.earnings: (context) => const EarningsScreen(),
                  AppRoutes.jobHistory: (context) => const JobHistoryScreen(),
                  AppRoutes.jobFeed: (context) => const JobFeedScreen(),
                  AppRoutes.reviews: (context) => const ReviewsScreen(),
                  AppRoutes.chatList: (context) => const ChatListScreen(),
                  AppRoutes.chat: (context) => const ChatScreen(),
                  AppRoutes.notifications: (context) => const NotificationsScreen(),
                  AppRoutes.settings: (context) => const SettingsScreen(),
                  AppRoutes.profile: (context) => const ProfileScreen(),
                  AppRoutes.safety: (context) => const SafetyScreen(),
                  AppRoutes.idVerification: (context) => const IDVerificationScreen(),
                  AppRoutes.trustedContacts: (context) =>
                      const TrustedContactsScreen(),
                  AppRoutes.sos: (context) => const SOSScreen(),
                  AppRoutes.business: (context) => const BusinessAccountScreen(),
                  AppRoutes.aiAssistant: (context) => const AIAssistantScreen(),
                  AppRoutes.emergency: (context) => const EmergencyScreen(),
                  '/admin': (context) => const AdminMain(),
                  '/admin-login': (context) => const AdminLoginScreen(),
                  '/admin-dashboard': (context) => const AdminDashboardScreen(),
                },
                onGenerateRoute: (settings) {
                  if (settings.name == '/admin-login') {
                    return MaterialPageRoute(
                      builder: (_) => const AdminLoginScreen(),
                    );
                  }
                  if (settings.name == '/admin-dashboard') {
                    return MaterialPageRoute(
                      builder: (_) => const AdminDashboardScreen(),
                    );
                  }
                  if (settings.name == '/admin') {
                    return MaterialPageRoute(builder: (_) => const AdminMain());
                  }
                  return null;
                },
                navigatorObservers: [NavigatorObserver()],
              );
            },
          );
        },
      ),
    );
  }
}

// Custom Navigator Observer for route tracking
class NavigatorObserver extends RouteObserver<PageRoute<dynamic>> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('Route Pushed: ${route.settings.name}');
      // Add analytics tracking here
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('Route Popped: ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute is PageRoute) {
      debugPrint('Route Replaced: ${newRoute.settings.name}');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route is PageRoute) {
      debugPrint('Route Removed: ${route.settings.name}');
    }
  }
}

// Extension for easy navigation from anywhere
extension Navigation on BuildContext {
  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return Navigator.of(
      this,
    ).pushReplacementNamed(routeName, arguments: arguments);
  }

  Future<dynamic> pushNamedAndRemoveUntil(
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(this).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void pop({Object? result}) {
    return Navigator.of(this).pop(result);
  }

  bool canPop() {
    return Navigator.of(this).canPop();
  }
}

// Global function to show snackbar from anywhere
void showGlobalSnackbar(String message, {Color? color}) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// Global function to show loading dialog
Future<void> showGlobalLoading(String message) async {
  final context = navigatorKey.currentContext;
  if (context != null) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

// Global function to hide loading
void hideGlobalLoading() {
  final context = navigatorKey.currentContext;
  if (context != null) {
    Navigator.of(context).pop();
  }
}

// Global function to show error dialog
void showGlobalError(String message) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Global function to show success dialog
void showGlobalSuccess(String message) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Global function to show confirmation dialog
Future<bool?> showGlobalConfirm(String title, String message) async {
  final context = navigatorKey.currentContext;
  if (context != null) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
  return null;
}
