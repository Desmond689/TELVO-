// src/jobs/cleanupJob.js
const { getFirestore } = require('../config/firebase');
const { logger } = require('../utils/logger');

const cleanupJob = async () => {
  try {
    logger.info('🧹 Running cleanup job...');
    const db = getFirestore();
    
    // Delete jobs older than 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const jobsSnapshot = await db.collection('jobs')
      .where('status', 'in', ['completed', 'cancelled'])
      .where('createdAt', '<', thirtyDaysAgo)
      .get();
    
    const batch = db.batch();
    jobsSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });
    
    if (jobsSnapshot.docs.length > 0) {
      await batch.commit();
      logger.info(`✅ Cleaned up ${jobsSnapshot.docs.length} old jobs`);
    } else {
      logger.info('✅ No old jobs to clean up');
    }
  } catch (error) {
    logger.error('❌ Cleanup job failed:', error);
  }
};

module.exports = { cleanupJob };