# Batch 4 — Notifications (in-app + FCM push) — fixes applied

## Existing backend/Cloud Function confirmed
`functions/index.js` already has `sendPushOnNotificationCreate`, a Firestore
trigger on `notifications/{id}` that resolves `users/{userId}.fcmToken`,
sends the real FCM push, stamps `pushSent`/`pushSentAt`, and clears stale
tokens on failure. This is the intended single sender per
`docs/PUSH_NOTIFICATIONS_DEPLOY.md`. Nothing new was added to duplicate it —
the fixes below make sure everything else routes through it instead of
sending in parallel.

## 1. Double-push bug: Express backend was sending FCM directly too
`backend/src/services/notificationService.js` → `sendPushNotification()`
called `admin.messaging().send()` itself *and* wrote a `notifications` doc
without `pushSent: true`, so the Cloud Function fired again on that doc and
sent a second push. This affected every job posting, quote, message,
payment, and hire-request notification sent through the backend
(`jobController`, `chatController`, `paymentController`,
`notificationController`).

Fix: `sendPushNotification()` now only writes the Firestore doc (with a
top-level `type` field, mirroring the Flutter client) and lets the Cloud
Function be the sole sender. Removed the now-unused `getMessaging`/`admin`
import and the local stale-token cleanup (the Cloud Function already does
this).

Also hardened `functions/index.js`'s `type` resolution so it falls back to
`data.type` instead of clobbering it with `''` when the top-level `type`
field is absent (matters more now that the backend relies on that field for
tap-to-navigate).

## 2. Duplicate in-app notification docs on the client
`lib/services/notification_service.dart`'s foreground (`_showLocalNotification`)
and background (`_handleBackgroundMessage`) handlers were unconditionally
writing a new `notifications` doc for every incoming push — even though real
pushes already originate from an existing doc (the Cloud Function includes
`notificationId` in the FCM data payload). This double-counted every
notification in the in-app list whenever the app happened to be foregrounded
or backgrounded when the push landed.

Fix: both handlers now check for `data.notificationId` and skip re-persisting
when it's present. A doc is only written for genuinely local/data-only
messages that have no server-side doc behind them.

## 3. Tap-to-navigate did nothing for background/terminated notifications
`_handleMessageOpen` (wired to `FirebaseMessaging.onMessageOpenedApp`) was an
empty stub, and there was no `getInitialMessage()` check for a cold-start
launch (app fully terminated, user taps the notification to open it). Only
the in-app foreground banner had working tap navigation.

Fix: extracted the routing logic into a new shared
`lib/services/notification_tap_router.dart` (`NotificationTapRouter.handle`),
used by:
- the foreground banner (`ForegroundNotificationManager._handleTap`)
- `_handleMessageOpen` (background tap while app is alive)
- `NotificationService.handleInitialMessageIfAny()`, called once via
  `WidgetsBinding.instance.addPostFrameCallback` in `main.dart`'s
  `_MyAppState.initState` — after the navigator is mounted, since
  `getInitialMessage()` resolves before `runApp()` and there'd be no
  context to push to yet if called from `_init()`.

## 4. FCM token could leak to the wrong user after sign-out
`unregisterToken(userId)` deleted the Firestore `fcmToken` field but never
cancelled the `onTokenRefresh` subscription set up in `registerToken`. If the
token rotated after sign-out (before the next user logs in on the same
device), the refresh listener — still bound to the old `userId` — would
silently write a fresh token back onto the signed-out user's doc, quietly
re-enabling push for an account nobody is authenticated as.

Fix: `unregisterToken()` now cancels `_tokenRefreshSubscription` before
deleting the token field.

## 5. iOS foreground presentation
Added `_fcm.setForegroundNotificationPresentationOptions(alert: true, badge:
true, sound: true)` in `_init()` — iOS suppresses the system
alert/badge/sound for foreground pushes by default; `onMessage` still fired
before, but the user got no system-level feedback while the app was open.
No-op on Android.

## Files touched
- `backend/src/services/notificationService.js`
- `functions/index.js`
- `lib/services/notification_service.dart`
- `lib/services/foreground_notification_manager.dart`
- `lib/services/notification_tap_router.dart` (new)
- `lib/main.dart`

## Not changed / out of scope
- Android manifest channel setup (`default_notification_channel`) and the
  native `MethodChannel` channel-creation call in `MainActivity.kt` were
  already correct and consistent with the Cloud Function's `channelId`.
- iOS `AppDelegate`/`Info.plist` were empty placeholders in this batch's
  source tree (not included), so no native iOS changes were made — only the
  Dart-level foreground presentation option above.
