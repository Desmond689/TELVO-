# Telvo — all fixes from day 1

## Critical (must deploy)
1. **Firestore rules** — workers can read open jobs; notifications creatable for others; users readable for discovery
2. **Cloud Functions** (`functions/`) — FCM push when app closed + job expiry
3. Deploy: `firebase deploy --only functions,firestore:rules,firestore:indexes`

## App icon
- Real launcher icons from `assets/images/app_logo.png` in all mipmap densities + adaptive icon
- Uninstall old APK before installing new one

## Jobs / quotes
- Accept quote: open-status check, 24h expiry, single accept, reject others
- professionalName + professionalImage on job
- Job card: assigned worker avatar, Accepted/Expired badges
- Quote confirmation dialog
- Backend acceptQuote expiry validation

## Hire Worker
- Full screen: worker card, service chips, description, photos, location, schedule, budget, payment
- Route `/hire-worker` — Book/Hire navigates here

## Home cards
- Bollo-style marketplace cards (image, title, price, tags, Book)

## Search
- Compact search + chips + filter sheet

## Chat
- WhatsApp-style bubbles, block check on send

## Reviews
- Only after completed job; one review per job

## Block / unblock
- UserProvider blockUser / unblockUser

## Share / invite
- share_plus; drawer Invite Friends; profile share

## Uploads
- Unsigned Cloudinary; errors thrown (not silent)
- Never ship API_SECRET in mobile .env

## Notifications
- In-app list + badge (Firestore listeners)
- createNotification stores Map data + pushSent: false
- Cloud Function sends real FCM push

## Suspend
- isSuspended enforced on auth

## Deploy checklist
```bash
firebase deploy --only functions,firestore:rules,firestore:indexes
flutter pub get
flutter build apk --release
# Uninstall old app, install new APK
```

## P0 bugfix batch (Aug 6)
- Job feed query uses whereIn open statuses (posted/open/quotes_received/notified)
- categoryNormalized on post job + professional setup
- notifyProfessionals case-insensitive + limit 200
- Hire request includes professionalName
- Job details loads quotes + Accept/Reject via QuoteCard
- Firestore indexes: status+expiresAt, userType+categoryNormalized

## Batch 2 — Image upload + profile picture (Aug 10)
- Traced full upload flow: picker (gallery/camera) -> StorageService validation -> Cloudinary upload w/ retry -> AuthProvider.updateProfile Firestore write -> live snapshots() listener -> UI rebuild
- StorageService: added real validation before upload (file exists, non-empty, <=10MB, allowed image extensions) instead of no validation at all
- getFriendlyErrorMessage: was silently discarding custom Exception messages (e.g. "file too large") and replacing with generic fallback; now passes through deliberately-thrown human-readable messages while still translating known technical errors
- profile_photo_picker.dart: fixed empty-string photo URL crash ("" passed `!= null` check then crashed NetworkImage/FileImage); fixed unsafe setState from mid-paint image error callback (deferred via addPostFrameCallback)
- profile_screen.dart: onPhotoSelected callback was never returning the uploaded URL back to the picker (silently broken contract, only masked by the Firestore listener re-syncing later) - now returns it properly
- profile_setup_screen.dart: same empty-string/no-error-fallback avatar crash pattern fixed with clean-URL getter + failed-load state
- Rolled out SafeAvatar (circular) / RemoteImage (rectangular) - both already null/empty-safe with load-failure fallback - to remaining raw CircleAvatar+NetworkImage / Image.network call sites that were still crash-prone or could render a blank circle on empty string: admin_professionals.dart, admin_users.dart, admin_verification.dart, chat_screen.dart, job_feed_screen.dart, professional_setup_screen.dart (portfolio grid), reviews_screen.dart, job_card.dart, professional_card.dart, quote_card.dart, worker_feed_card.dart
- Verified Home screen already renders profile picture from the live user doc via SafeAvatar with proper fallback icon (no changes needed there)

## Batch 3 — Chat + Block user (Aug 10)

### Chat
- **Date-separator direction bug**: messages stream newest-first and render in a `reverse: true` ListView (index 0 pinned at the bottom). `_buildListItems` was inserting each day's separator *before* that day's messages in the array, which — once the list is flipped for display — put every "Today"/"Yesterday" label below that day's messages instead of above them. Rewrote the grouping so the separator is appended only when a day boundary is crossed (plus once at the end), fixing the on-screen order for every day, not just the first.
- Audited sender/receiver bubble logic (`isMe = senderId == currentUser.id` → right side) — this was already correct; no change needed.
- `chat_list_screen.dart` was missing the `SafeAvatar` import entirely — a straight compile error, now fixed.
- Both `ChatScreen` and `ChatListScreen` called `provider.getChatMessages(...)` / `getUserAllThreads(...)` directly inside `build()`, creating a brand-new Firestore listener (and loading-spinner flash) on every rebuild, including rebuilds triggered by unrelated provider changes. Both streams are now cached per chat/user id instead of recreated each frame.
- Real-time listener, timestamps, and empty/loading/error states were already correct — verified, no changes.

### Block / unblock end-to-end
- `UserProvider.blockUser` / `unblockUser` caught Firestore errors but never rethrew them, so every caller's `try/catch` was dead code — the UI always said "User blocked" even when the write failed. Now rethrows so failures surface.
- Found and fixed the same silent-failure pattern in `reportUser`, plus a missing `reportedBy` field — the Firestore rule requires it on create, so every report was being silently rejected as permission-denied.
- Built the missing **Blocked Users screen** (`lib/screens/settings/blocked_users_screen.dart`): lists blocked users live from `AuthProvider.currentUser.blockedUsers`, with per-row Unblock buttons and proper loading/empty/error states. Wired into Settings (previously just showed a "coming soon" snackbar) and registered as `/blocked-users` in `routes.dart`.
- Blocked-user restrictions were incomplete: chat already blocked sending messages/photos, but the call button, "Hire Now," and "Chat with Professional" all remained fully usable even when blocked. Added block-aware gating (disabled buttons + explanatory banner, replaced message input entirely) in both `chat_screen.dart` and `professional_profile_screen.dart`, plus a live Block/Unblock toggle in each popup menu.
- Added the same block check `chat_provider.sendMessage` already did to `job_provider.sendHireRequest`, so a blocked user can't reach the other party through the direct-hire flow instead.
- **`firestore.rules` had zero server-side block enforcement** — blocking only worked as long as every client honored it; anyone hitting the Firestore SDK/REST API directly could bypass a block entirely. Added an `isBlockedPair()` rule function and applied it to `chats` creation, chat `messages` creation (both the nested and legacy top-level collections), and `hire_requests` creation.
- Verified block persistence: `blockUser`/`unblockUser` write directly to the user's Firestore doc, and `AuthProvider`'s live snapshot listener already syncs `blockedUsers` back into the session — this survives app restart with no changes needed.
