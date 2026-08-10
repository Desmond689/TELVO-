// src/jobs/notificationJob.js
const { getFirestore } = require('../config/firebase');
const { logger } = require('../utils/logger');

const notificationJob = async () => {
  try {
    logger.info('📨 Running notification job...');
    const db = getFirestore();
    
    // Send pending notifications
    const notifications = await db.collection('notifications')
      .where('isSent', '==', false)
      .get();
    
    for (const doc of notifications.docs) {
      const data = doc.data();
      
      // Send notification (implement your notification logic)
      logger.info(`📨 Sending notification to ${data.userId}: ${data.title}`);
      
      await doc.ref.update({
        isSent: true,
        sentAt: new Date()
      });
    }
    
    logger.info(`✅ Sent ${notifications.docs.length} notifications`);
  } catch (error) {
    logger.error('❌ Notification job failed:', error);
  }
};

module.exports = { notificationJob };