Push Notifications Setup (FCM)

This document describes the manual platform steps required to enable Firebase Cloud Messaging for Android and iOS, plus notes for the code changes already applied.

Summary of code changes applied
- NotificationService:
  - registerToken(userId) now saves the FCM token and listens for token refreshes to update the Firestore user doc.
  - unregisterToken(userId) removes the token from Firestore (called on sign-out).
  - Background message handler persists incoming messages to the `notifications` collection.
  - Foreground messages are persisted to the `notifications` collection when the message contains `userId` or `toUserId` in `data`.
- AuthProvider:
  - signOut() now attempts to unregister the FCM token before signing out.

Android (android/app)
1. Place your google-services.json file at android/app/google-services.json.
2. In android/build.gradle, ensure the Google Services plugin is applied and the classpath is present:
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15' // use latest compatible
     }
   }
   and at the bottom of android/app/build.gradle add:
     apply plugin: 'com.google.gms.google-services'
3. The app manifest already includes POST_NOTIFICATIONS permission and a default notification channel meta-data. Create the notification channel at app startup with the id `default_notification_channel` if you want custom importance/sound.
4. Ensure Firebase is initialized in your Flutter app (firebase_core) before using messaging.

iOS (ios/Runner)
1. Place your GoogleService-Info.plist in ios/Runner/ and add it to the Runner target in Xcode.
2. In AppDelegate (Swift/ObjC), ensure Firebase is configured (FirebaseApp.configure()). The firebase_messaging plugin usually handles this if firebase_core is initialized in Dart.
3. Ensure Push Notifications capability is enabled in the Xcode project and you have an APNs key/certificate configured in your Firebase Console.
4. For iOS 10+, the plugin will ask for permission; optionally add usage descriptions to Info.plist if needed.

Server-side notes
- The app stores `fcmToken` in the user's Firestore document. Backend servers can read this field and send messages via FCM using the FCM server key or Firebase Admin SDK.
- When sending data messages targeted at a specific user, include `data.userId` or `data.toUserId` so the app persists the notification when it arrives.

Local/Foreground notifications
- The project previously omitted flutter_local_notifications due to compatibility concerns. Foreground messages are persisted to Firestore so the app's notifications screen can surface them. If in-app banners are required, consider re-adding flutter_local_notifications and pinning a compatible version, or implement an in-app banner system that reads the notifications collection.

Next recommended tasks (can be implemented now):
- Create a notification channel on Android at app startup (default_notification_channel).
- Implement a UI banner or snackbar that listens to incoming messages and shows a transient banner when the app is foregrounded.
- Add tests for register/unregister flows and token rotation handling.
- Update CI docs and ensure google-services files are kept out of source control (add to .gitignore if not already).

If you want, apply the platform manifest updates now (add channel creation code, configure Xcode capabilities) — confirm and I will make the edits and add example code.