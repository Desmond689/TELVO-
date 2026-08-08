# Telvo feature completion notes

## Implemented / strengthened

### 1. Quote lifecycle
- `acceptQuote` validates job is still open (`posted`/`open`/`quotes_received`/`notified`)
- Rejects acceptance if already has `acceptedQuoteId` or status accepted
- Enforces 24h expiry (marks job `expired` if past)
- Stores `professionalName` + `professionalImage` on job
- Rejects all other quotes
- Quote model includes `workerName` / `workerImage` (filled on send)
- QuoteCard shows confirmation dialog before accept
- Job card shows assigned worker avatar, name, Accepted badge, Expired badge
- Backend `acceptQuote` also checks expiry + single acceptance

### 2. Notifications + badges
- Existing `NotificationProvider` real-time listener + unread count kept
- Firestore rules allow creating notifications for other users (needed without backend push)
- FCM token registration already on login
- System tray push still needs Cloud Function (documented previously)

### 3. Uploads
- StorageService throws on failure (profile/job/portfolio/chat)
- Unsigned Cloudinary path

### 4. Category filters
- UserProvider queries Firestore with `category` where clause (not client-only)

### 5. Reviews
- `submitReview` requires job status completed/reviewed
- Blocks duplicate review for same jobId

### 6. Block / unblock
- `blockUser` / `unblockUser` on UserProvider
- Chat send blocked when either side blocked

### 7. WhatsApp-style chat
- Green bubbles (me, right), white (other, left)
- WA-like radii + chat background `#ECE5DD`

### 8. Share / Invite
- `share_plus` added
- Invite Friends in drawer
- Share on professional profile

### 9. Admin suspend
- Existing `isSuspended` enforced on auth listener + login
- Admin users UI already has suspend

### 10. Firestore rules
- Open jobs readable by signed-in users (worker feed)
- Users readable for discovery
- Notifications creatable for others
- Owner cannot self-set `isSuspended`

## Deploy
```bash
firebase deploy --only firestore:rules
flutter pub get
flutter analyze
flutter build apk --release
```
Uninstall old app before install (icon + clean state).
