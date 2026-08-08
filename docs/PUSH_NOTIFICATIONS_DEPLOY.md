# Deploy real push notifications (app closed / background)

## What this does

When the Flutter app creates a document in `notifications/`:

1. Cloud Function `sendPushOnNotificationCreate` runs
2. It reads `users/{userId}.fcmToken`
3. It sends an FCM message
4. The phone shows a **system notification** even if Telvo is closed

## Prerequisites

1. Firebase project on the **Blaze (pay as you go)** plan — Cloud Functions require it (free tier still has a generous free quota).
2. Android app has `google-services.json` and users allow notifications.
3. After login, `users/{uid}` has field `fcmToken`.

## Deploy steps

```bash
# 1. Login & select project
firebase login
firebase use telvo-452fd

# 2. Install function dependencies
cd functions
npm install
cd ..

# 3. Deploy function + rules + indexes
firebase deploy --only functions,firestore:rules,firestore:indexes
```

First deploy can take 2–5 minutes.

## Verify in Firebase Console

1. **Functions** → you should see:
   - `sendPushOnNotificationCreate`
   - `expireOldJobs`
2. **Logs** → Functions → `sendPushOnNotificationCreate` → when a notification is created you should see `Push sent to ...`

## Test end-to-end

1. Install APK on a **real phone**, log in as Worker, allow notifications.
2. Confirm Firestore `users/{workerId}` has `fcmToken`.
3. Force-close Telvo (swipe away from recents).
4. From another account, post a job in that worker’s category (or send a hire request).
5. Worker phone should show a **system tray / lock screen** notification.
6. In Firestore, the notification doc should get `pushSent: true`.

## If push does not appear

| Check | Fix |
|--------|-----|
| No `fcmToken` on user | Log out/in; ensure `registerToken` runs |
| Function not deployed | `firebase deploy --only functions` |
| Not on Blaze plan | Upgrade project billing (required for Functions) |
| Android notifications disabled | Phone Settings → Apps → Telvo → Notifications ON |
| Wrong channel | Manifest uses `default_notification_channel` — function uses the same |
| Stale token | Function clears invalid tokens; log in again |

## Emulator note

FCM on emulators is unreliable. Always test push on a **physical device**.

## Cost

Blaze plan: FCM is free. Cloud Functions has a free monthly quota that is enough for early traffic. You only pay after exceeding the free allotment.
