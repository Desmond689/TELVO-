/**
 * Telvo Cloud Functions — real FCM push when the app is closed/backgrounded.
 *
 * Flow:
 *   Flutter writes to `notifications/{id}`
 *        ↓
 *   This function runs (server-side, trusted)
 *        ↓
 *   Reads users/{userId}.fcmToken
 *        ↓
 *   admin.messaging().send(...) → lock screen / system tray
 *
 * DEPLOY (from repo root):
 *   cd functions && npm install
 *   firebase login
 *   firebase use telvo-452fd
 *   firebase deploy --only functions
 *
 * Also:
 *   firebase deploy --only firestore:rules,firestore:indexes
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

// Keep costs predictable on Blaze plan
setGlobalOptions({
  region: 'us-central1',
  maxInstances: 20,
});

/**
 * Normalize notification `data` into a flat string map for FCM.
 * Client sometimes stores a Map, sometimes a toString()'d value.
 */
function toFlatStringMap(raw) {
  const out = {};
  if (!raw) return out;

  if (typeof raw === 'object' && !Array.isArray(raw)) {
    for (const [k, v] of Object.entries(raw)) {
      if (v === undefined || v === null) continue;
      out[String(k)] = String(v);
    }
    return out;
  }

  if (typeof raw === 'string') {
    // Try JSON first
    try {
      const parsed = JSON.parse(raw);
      if (parsed && typeof parsed === 'object') {
        return toFlatStringMap(parsed);
      }
    } catch (_) {
      // Dart Map.toString() looks like: {jobId: abc, type: new_job}
      const inner = raw.replace(/^\{/, '').replace(/\}$/, '');
      inner.split(',').forEach((part) => {
        const idx = part.indexOf(':');
        if (idx === -1) return;
        const key = part.slice(0, idx).trim();
        const val = part.slice(idx + 1).trim();
        if (key) out[key] = val;
      });
    }
  }
  return out;
}

/**
 * Every new `notifications` document → real push to that user's device.
 */
exports.sendPushOnNotificationCreate = onDocumentCreated(
  'notifications/{notificationId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const notif = snap.data() || {};
    const userId = notif.userId;
    if (!userId) {
      console.log('Notification missing userId; skip push.');
      return null;
    }

    if (notif.pushSent === true) {
      console.log('Already pushed; skip.');
      return null;
    }

    try {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        console.log(`User ${userId} not found; skip push.`);
        return null;
      }

      const fcmToken = userDoc.get('fcmToken');
      if (!fcmToken) {
        console.log(`No fcmToken for ${userId}; in-app only.`);
        return null;
      }

      const flatData = toFlatStringMap(notif.data);
      // Prefer the top-level `type` field, but fall back to `data.type` so
      // a doc that only set it inside `data` (older writers) still keeps
      // it instead of getting overwritten with an empty string - the
      // client uses this field for tap-to-navigate.
      flatData.type = notif.type ? String(notif.type) : (flatData.type || '');
      flatData.notificationId = String(event.params.notificationId || '');
      if (notif.actionUrl) flatData.actionUrl = String(notif.actionUrl);

      const title = notif.title || 'Telvo';
      const body = notif.body || '';

      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: flatData,
        android: {
          priority: 'high',
          notification: {
            channelId: 'default_notification_channel',
            sound: 'default',
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              contentAvailable: true,
            },
          },
        },
      });

      await snap.ref.update({
        pushSent: true,
        pushSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Push sent to ${userId}: ${title}`);
      return null;
    } catch (err) {
      const code = err && err.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        console.log(`Stale FCM token for ${userId}; clearing.`);
        await db.collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
        return null;
      }
      console.error('sendPushOnNotificationCreate error:', err);
      return null;
    }
  }
);

/**
 * Recalculates a professional's average rating + completed-review count
 * whenever a new review is written.
 *
 * This has to run server-side with the Admin SDK: firestore.rules only
 * lets a user update their *own* `users/{uid}` doc (or an admin update
 * anyone's), so the reviewing customer's client can never legally write
 * `users/{professionalId}.rating` directly - that update would be
 * rejected with permission-denied in production every single time. The
 * client only writes the review doc and its own job doc; this function
 * (running with elevated Admin SDK privileges, which bypass security
 * rules entirely) is what actually applies it to the professional's
 * rating.
 *
 * Idempotency: Firestore triggers are "at least once", not "exactly
 * once" - the platform can redeliver an event after a transient failure.
 * A naive read-currentRating/compute-average/write would double-count a
 * redelivered review. To guard against that, the whole recalculation
 * (including reading the review doc's own `ratingApplied` flag) runs
 * inside one transaction: the flag is checked and, if unset, is written
 * back to `true` as part of the same atomic commit that updates the
 * user's rating - so a redelivery sees it already applied and no-ops.
 */
exports.recalcRatingOnReview = onDocumentCreated(
  'reviews/{reviewId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return null;

    const reviewRef = snap.ref;
    const reviewedId = snap.get('reviewedId');
    const rating = snap.get('rating');

    if (!reviewedId || typeof rating !== 'number') {
      console.log(`Review ${event.params.reviewId} missing reviewedId/rating; skip rating recalc.`);
      return null;
    }

    const userRef = db.collection('users').doc(reviewedId);

    try {
      await db.runTransaction(async (tx) => {
        const [reviewSnap, userSnap] = await Promise.all([
          tx.get(reviewRef),
          tx.get(userRef),
        ]);

        if (reviewSnap.get('ratingApplied') === true) {
          console.log(`Rating already applied for review ${event.params.reviewId}; skip.`);
          return;
        }

        if (!userSnap.exists) {
          console.log(`Reviewed user ${reviewedId} not found; skip rating recalc.`);
          tx.update(reviewRef, { ratingApplied: true });
          return;
        }

        const currentRating = Number(userSnap.get('rating')) || 0;
        const jobsCompleted = Number(userSnap.get('jobsCompleted')) || 0;
        const newRating = ((currentRating * jobsCompleted) + rating) / (jobsCompleted + 1);

        tx.update(userRef, {
          rating: newRating,
          jobsCompleted: jobsCompleted + 1,
        });
        tx.update(reviewRef, { ratingApplied: true });
      });

      console.log(`Rating recalculated for ${reviewedId} from review ${event.params.reviewId}.`);
      return null;
    } catch (err) {
      console.error('recalcRatingOnReview error:', err);
      return null;
    }
  }
);

/**
 * Expire posted jobs past expiresAt (default 24h from create).
 * Runs every hour so the worker feed stays clean server-side.
 */
exports.expireOldJobs = onSchedule('every 60 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const snapshot = await db
    .collection('jobs')
    .where('status', 'in', ['posted', 'open', 'quotes_received'])
    .where('expiresAt', '<=', now)
    .limit(200)
    .get();

  if (snapshot.empty) {
    console.log('No jobs to expire.');
    return null;
  }

  const batch = db.batch();
  snapshot.docs.forEach((doc) => {
    batch.update(doc.ref, { status: 'expired' });
  });
  await batch.commit();
  console.log(`Expired ${snapshot.size} job(s).`);
  return null;
});
