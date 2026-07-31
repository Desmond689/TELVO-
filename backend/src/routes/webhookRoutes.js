// src/routes/webhookRoutes.js
const express = require('express');
const router = express.Router();
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

// Payment webhook
router.post('/payment', async (req, res) => {
  try {
    const { type, data } = req.body;
    
    logger.info(`Payment webhook received: ${type}`);
    
    // Process webhook based on type
    switch (type) {
      case 'payment.success':
        // Process successful payment
        break;
      case 'payment.failed':
        // Process failed payment
        break;
      case 'payment.refunded':
        // Process refunded payment
        break;
      default:
        logger.info(`Unknown webhook type: ${type}`);
    }
    
    return successResponse(res, null, 'Webhook processed successfully');
  } catch (error) {
    logger.error('Webhook error:', error);
    return errorResponse(res, 'Failed to process webhook', 500);
  }
});

// SMS webhook
router.post('/sms', async (req, res) => {
  try {
    const { from, to, message } = req.body;
    logger.info(`SMS webhook: from ${from} to ${to}: ${message}`);
    
    return successResponse(res, null, 'SMS processed successfully');
  } catch (error) {
    logger.error('SMS webhook error:', error);
    return errorResponse(res, 'Failed to process SMS', 500);
  }
});

// Email webhook
router.post('/email', async (req, res) => {
  try {
    const { to, subject, status } = req.body;
    logger.info(`Email webhook: ${to} - ${subject} - ${status}`);
    
    return successResponse(res, null, 'Email webhook processed');
  } catch (error) {
    logger.error('Email webhook error:', error);
    return errorResponse(res, 'Failed to process email webhook', 500);
  }
});

module.exports = router;