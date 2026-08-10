# Batch 5 — Reviews — fixes applied

## What was already wired up
Most of the pipeline existed before this batch:
- "Leave Review" button on `job_details_screen.dart` (shown once a job's
  status is `completed`) → `review_screen.dart` (star rating + text +
  optional photos UI) → `JobProvider.submitReview()` → Firestore.
- Display side: `reviews_screen.dart` (professional's own reviews, with
  reply) and `professional_profile_screen.dart` (average rating + job
  count on a professional's public profile) both already read `rating` /
  `jobsCompleted` off the user doc and reviews off the `reviews`
  collection — no changes needed there.

## 1. Rating recalculation was silently broken in production
`JobProvider.submitReview()` used to update the professional's rating by
calling `users/{professionalId}.update({rating: ..., jobsCompleted: ...})`
directly from the *reviewing customer's* client.

`firestore.rules` only allows a user to update their own `users/{uid}` doc
(or an admin to update anyone's):
```
allow update: if (isOwner(userId) && ...) || isAdmin();
```
A customer is never the owner of the professional's doc, so this write was
rejected with `permission-denied` on every single review, in every build
that actually enforced the deployed rules. Because it ran after the review
doc and job doc writes inside one `try`/`catch`, the *whole* `submitReview()`
call surfaced as a generic failure to the customer — even though the review
had already been saved and the job already flipped to `reviewed` — and the
professional's rating was never actually updated, ever.

**Fix:** moved rating recalculation server-side. `functions/index.js` now
has `recalcRatingOnReview`, a Firestore trigger on `reviews/{reviewId}`
that runs with the Admin SDK (which bypasses security rules) and does the
weighted-average update in its own transaction. The client no longer
touches the professional's user doc at all.

Idempotency: Firestore triggers are at-least-once, not exactly-once, so a
redelivered event could double-count a review if recalculation just did a
naive read-modify-write. `recalcRatingOnReview` guards against that by
reading/writing a `ratingApplied` flag on the review doc itself inside the
same transaction that updates the rating — a redelivery sees the flag
already set and no-ops.

## 2. Duplicate-review race condition
`submitReview()` previously enforced "one review per job" with a plain
read-then-write: query `reviews` for an existing doc with this `jobId`,
proceed only if none was found, then write with a random auto-generated ID.
That check and the eventual write weren't atomic — two submissions for the
same job landing close together (a double-tap beating the button's disabled
state, a retried request after a slow/timed-out first one that actually
succeeded server-side, etc.) could both pass the check before either had
committed, producing two review docs for one job.

**Fix:** the review is now keyed by a deterministic ID — `reviews/{jobId}`
instead of a random one — and the whole "already reviewed?" check + review
write + job update runs inside a single Firestore transaction in
`submitReview()`. Firestore transactions are optimistic: if a second
transaction's reads get invalidated by the first one's commit, it's
automatically retried, and on retry it sees the review doc that now exists
and aborts cleanly with "You already reviewed this job." instead of writing
a duplicate. This is a hard, server-enforced guarantee — not dependent on
the UI disabling the button in time.

## 3. New: notify the professional on review
Added `NotificationService.notifyReviewReceived()`, called (best-effort,
non-fatal) after a review transaction commits, and added `new_review` to
`NotificationTapRouter`'s known types so tapping it navigates somewhere
sensible.

Known limitation (pre-existing, not introduced by this batch, not fixed
here): `firestore.rules` only lets a signed-in user create a `notifications`
doc where `data.userId == request.auth.uid` — i.e. only for *themselves*.
Every cross-user notification write in `notification_service.dart`
(`notifyProfessionals`, `notifyQuoteAccepted`, `notifyNewQuote`,
`notifyJobUpdate`, hire-request notifications, and now
`notifyReviewReceived`) sets `userId` to the *other* party and will be
rejected by that rule in production the same way the rating write was.
This is a systemic issue across the whole notification system, not specific
to reviews, and fixing it properly (routing these through a Cloud Function
with the Admin SDK, the same way push/rating now work) is a bigger change
than this batch's scope — flagging it clearly rather than quietly leaving it
undiscovered. `notifyReviewReceived` is wrapped in try/catch so it fails
silently and doesn't block review submission either way.

## 4. Also noticed, not fixed (out of scope for this batch)
`respondToReview()` (professional replying to a review, wired to
`reviews_screen.dart`) calls `.doc(reviewId).update(...)` directly from the
client. `firestore.rules` has `allow update, delete: if isAdmin();` on the
`reviews` collection — a professional isn't an admin, so this update is
also rejected in production today. Fixing it needs a rules change (e.g.
allow the doc's `reviewedId` to update only the response fields) or moving
it through a Cloud Function. Left alone here to keep this batch's blast
radius to the review-submission path that was actually requested.

The backend Express `reviewController.js` (`createReview`, etc.) is dead
code from the Flutter client's perspective — `lib/services/api_service.dart`
never calls the review endpoints, the app writes to Firestore directly.
Left untouched.

## Files touched
- `functions/index.js` — new `recalcRatingOnReview` trigger
- `lib/providers/job_provider.dart` — `submitReview()` rewritten
- `lib/services/notification_service.dart` — new `notifyReviewReceived()`
- `lib/services/notification_tap_router.dart` — routes `new_review` taps
