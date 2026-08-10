// src/services/notificationService.js
const { getFirestore } = require('../config/firebase');
const { logger } = require('../utils/logger');
const axios = require('axios');

class NotificationService {
  constructor() {
    this.db = getFirestore();
  }

  // NOTE: This no longer calls admin.messaging().send() directly. The
  // Firestore-triggered Cloud Function `sendPushOnNotificationCreate`
  // (functions/index.js) already owns real FCM delivery for every doc
  // written to the `notifications` collection - it resolves the user's
  // fcmToken, sends the push, marks `pushSent: true`, and clears stale
  // tokens on failure. This service used to *also* call FCM directly,
  // which meant every job/quote/message/payment event fired the push
  // twice (once from here, once from the Cloud Function trigger a moment
  // later, since the doc it wrote didn't set pushSent). Writing the doc
  // and letting the Cloud Function send it keeps push delivery in one
  // place. See docs/PUSH_NOTIFICATIONS_DEPLOY.md for the intended flow.
  async sendPushNotification(userId, title, body, data = {}) {
    try {
      // Resolve a friendly action URL for the web notification page.
      const finalData = { ...data };
      if (!finalData.actionUrl && finalData.type === 'message' && finalData.senderId) {
        finalData.actionUrl = `messages?with=${finalData.senderId}`;
      }
      if (!finalData.actionUrl && finalData.type === 'payment') {
        finalData.actionUrl = 'notifications';
      }

      const userDoc = await this.db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        logger.warn(`User ${userId} not found for push notification`);
        return false;
      }

      if (!userDoc.data().fcmToken) {
        logger.warn(`No fcmToken for user ${userId} yet - in-app notification only, no push until they log in on a device.`);
      }

      // Save to Firestore. This is what the Cloud Function trigger fires
      // on - it will resolve the token, send the FCM push, and stamp
      // pushSent/pushSentAt itself. Do not set pushSent here, and do not
      // send via FCM from this process, or the user gets two pushes.
      await this.db.collection('notifications').add({
        userId,
        title,
        body,
        // Top-level `type` mirrors the Flutter client's own writes and is
        // what the Cloud Function reads for the FCM data payload's
        // `type` field (used for tap-to-navigate on the device).
        type: finalData.type || null,
        data: finalData,
        isRead: false,
        createdAt: new Date(),
      });

      return true;
    } catch (error) {
      logger.error('Push notification error:', error);
      return false;
    }
  }

  async sendEmail(to, subject, htmlContent) {
    try {
      // In production, use nodemailer or SendGrid
      logger.info(`📧 Email to ${to}: ${subject}`);
      
      // Save email to database for tracking
      await this.db.collection('emails').add({
        to,
        subject,
        htmlContent,
        status: 'sent',
        createdAt: new Date(),
      });

      return true;
    } catch (error) {
      logger.error('Email sending error:', error);
      return false;
    }
  }

  async sendSMS(to, message) {
    try {
      // In production, use Twilio or other SMS provider
      logger.info(`📱 SMS to ${to}: ${message}`);
      
      // Save SMS to database for tracking
      await this.db.collection('sms').add({
        to,
        message,
        status: 'sent',
        createdAt: new Date(),
      });

      return true;
    } catch (error) {
      logger.error('SMS sending error:', error);
      return false;
    }
  }

  async notifyNewJob(jobId, jobData, radiusKm = 10) {
    try {
      const geoService = require('./geoService');
      // Find nearby professionals using geohash prefix + haversine filter
      const professionals = await geoService.findProfessionalsNearby(
        { latitude: jobData.latitude, longitude: jobData.longitude, category: jobData.category },
        radiusKm,
        100
      );

      if (!professionals || professionals.length === 0) {
        logger.info('No nearby professionals found for job', jobId);
        return true;
      }

      await Promise.all(
        professionals.map((pro) =>
          this.sendPushNotification(
            pro.id,
            'New Job Available',
            `${jobData.category} job - ${(jobData.budget || '')} XAF`,
            { type: 'new_job', jobId }
          )
        )
      );

      return true;
    } catch (error) {
      logger.error('Notify new job error:', error);
      return false;
    }
  }

  async notifyQuoteAccepted(jobId, professionalId) {
    try {
      await this.sendPushNotification(
        professionalId,
        'Quote Accepted!',
        'Your quote has been accepted by the customer.',
        {
          type: 'quote_accepted',
          jobId,
        }
      );
      return true;
    } catch (error) {
      logger.error('Notify quote accepted error:', error);
      return false;
    }
  }

  async notifyJobUpdate(jobId, userId, message) {
    try {
      await this.sendPushNotification(
        userId,
        'Job Update',
        message,
        {
          type: 'job_update',
          jobId,
        }
      );
      return true;
    } catch (error) {
      logger.error('Notify job update error:', error);
      return false;
    }
  }

  async notifyPaymentReceived(userId, amount) {
    try {
      await this.sendPushNotification(
        userId,
        'Payment Received',
        `You received XAF ${amount} for your job.`,
        {
          type: 'payment',
          amount: amount.toString(),
        }
      );
      return true;
    } catch (error) {
      logger.error('Notify payment received error:', error);
      return false;
    }
  }

  async notifyAdmins(title, body, data = {}) {
    try {
      const admins = await this.db.collection('users').where('userType', '==', 'admin').get();
      const tasks = admins.docs.map((adminDoc) => this.sendPushNotification(adminDoc.id, title, body, data));
      await Promise.all(tasks);
      return true;
    } catch (error) {
      logger.error('Notify admins error:', error);
      return false;
    }
  }

  async notifyMessage(chatId, userId, message, senderId) {
    try {
      await this.sendPushNotification(
        userId,
        'New Message',
        message.substring(0, 50),
        {
          type: 'message',
          chatId,
          senderId,
        }
      );
      return true;
    } catch (error) {
      logger.error('Notify message error:', error);
      return false;
    }
  }
}

module.exports = NotificationService;