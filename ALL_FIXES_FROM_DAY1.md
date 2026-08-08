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
