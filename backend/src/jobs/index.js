// src/jobs/index.js
const { logger } = require('../utils/logger');
const { cleanupJob } = require('./cleanupJob');
const { notificationJob } = require('./notificationJob');
const { analyticsJob } = require('./analyticsJob');

const startJobs = () => {
  logger.info('🔄 Starting background jobs...');
  
  // Run cleanup job daily at midnight
  setInterval(() => {
    cleanupJob();
  }, 24 * 60 * 60 * 1000);
  
  // Run notification job every hour
  setInterval(() => {
    notificationJob();
  }, 60 * 60 * 1000);
  
  // Run analytics job every 6 hours
  setInterval(() => {
    analyticsJob();
  }, 6 * 60 * 60 * 1000);
  
  logger.info('✅ Background jobs started successfully');
};

module.exports = { startJobs };