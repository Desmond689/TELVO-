// src/jobs/analyticsJob.js
const { getFirestore } = require('../config/firebase');
const { logger } = require('../utils/logger');

const analyticsJob = async () => {
  try {
    logger.info('📊 Running analytics job...');
    const db = getFirestore();
    
    // Calculate daily stats
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    
    const [users, jobs, payments] = await Promise.all([
      db.collection('users').get(),
      db.collection('jobs').where('createdAt', '>=', yesterday).get(),
      db.collection('payments').where('createdAt', '>=', yesterday).get()
    ]);
    
    const stats = {
      date: today,
      totalUsers: users.docs.length,
      newJobs: jobs.docs.length,
      newPayments: payments.docs.length,
      totalRevenue: payments.docs.reduce((sum, doc) => sum + (doc.data().amount || 0), 0)
    };
    
    await db.collection('analytics').add(stats);
    logger.info('✅ Analytics data saved');
  } catch (error) {
    logger.error('❌ Analytics job failed:', error);
  }
};

module.exports = { analyticsJob };