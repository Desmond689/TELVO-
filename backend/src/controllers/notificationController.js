// src/controllers/notificationController.js
const Notification = require('../models/Notification');
const Job = require('../models/Job');
const NotificationService = require('../services/notificationService');
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

const notificationService = new NotificationService();

const getNotifications = async (req, res) => {
  try {
    const { limit = 50 } = req.query;
    const notifications = await Notification.findByUser(req.userId, parseInt(limit));
    return successResponse(res, notifications);
  } catch (error) {
    logger.error('Get notifications error:', error);
    return errorResponse(res, 'Failed to get notifications', 500);
  }
};

const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const notification = await Notification.findById(id);
    if (!notification) {
      return errorResponse(res, 'Notification not found', 404);
    }
    
    if (notification.userId !== req.userId) {
      return errorResponse(res, 'Unauthorized', 403);
    }
    
    await notification.markAsRead();
    return successResponse(res, notification.toJSON(), 'Marked as read');
  } catch (error) {
    logger.error('Mark as read error:', error);
    return errorResponse(res, 'Failed to mark as read', 500);
  }
};

const markAllAsRead = async (req, res) => {
  try {
    await Notification.markAllAsRead(req.userId);
    return successResponse(res, null, 'All notifications marked as read');
  } catch (error) {
    logger.error('Mark all as read error:', error);
    return errorResponse(res, 'Failed to mark all as read', 500);
  }
};

const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    const notification = await Notification.findById(id);
    if (!notification) {
      return errorResponse(res, 'Notification not found', 404);
    }
    
    if (notification.userId !== req.userId && !req.user.isAdmin()) {
      return errorResponse(res, 'Unauthorized', 403);
    }
    
    await notification.delete();
    return successResponse(res, null, 'Notification deleted');
  } catch (error) {
    logger.error('Delete notification error:', error);
    return errorResponse(res, 'Failed to delete notification', 500);
  }
};

const clearNotifications = async (req, res) => {
  try {
    // In production, delete all notifications for user
    return successResponse(res, null, 'All notifications cleared');
  } catch (error) {
    logger.error('Clear notifications error:', error);
    return errorResponse(res, 'Failed to clear notifications', 500);
  }
};

// Triggered by the mobile client after it writes a job/quote/status change
// directly to Firestore. Recipient and content are re-derived from the job
// document itself - a client-supplied userId is never trusted - so this
// can't be abused to spam arbitrary users with fake notifications.
const triggerJobEvent = async (req, res) => {
  try {
    const { jobId, quoteId, type, status } = req.body;
    if (!jobId || !type) {
      return errorResponse(res, 'jobId and type are required', 400);
    }

    const job = await Job.findById(jobId);
    if (!job) {
      return errorResponse(res, 'Job not found', 404);
    }

    const isCustomer = job.customerId === req.userId;
    const isProfessional = job.professionalId === req.userId;

    let recipientId;
    let title;
    let body;
    const data = { jobId, type };

    switch (type) {
      case 'new_job': {
        if (!isCustomer) return errorResponse(res, 'Unauthorized', 403);
        const User = require('../models/User');
        const professionals = await User.getProfessionals({
          category: job.category,
          isOnline: true,
        });
        await Promise.all(
          professionals.map((pro) =>
            notificationService.sendPushNotification(
              pro.id,
              'New Job Available',
              `${(job.description || '').slice(0, 80)}`,
              { jobId, type: 'new_job' }
            )
          )
        );
        return successResponse(res, null, 'Professionals notified');
      }
      case 'new_quote': {
        if (!isProfessional && !isCustomer) {
          return errorResponse(res, 'Unauthorized', 403);
        }
        const quote = (job.quotes || []).find((q) => q.id === quoteId);
        if (!quote) return errorResponse(res, 'Quote not found', 404);
        recipientId = job.customerId;
        title = 'New Quote Received';
        body = `You received a quote of ${quote.price} for your job.`;
        data.quoteId = quoteId;
        break;
      }
      case 'quote_accepted': {
        if (!isCustomer) return errorResponse(res, 'Unauthorized', 403);
        const quote = (job.quotes || []).find((q) => q.id === quoteId);
        if (!quote) return errorResponse(res, 'Quote not found', 404);
        recipientId = quote.professionalId;
        title = 'Quote Accepted!';
        body = 'Your quote has been accepted by the customer.';
        data.quoteId = quoteId;
        break;
      }
      case 'job_update': {
        if (!isCustomer && !isProfessional) {
          return errorResponse(res, 'Unauthorized', 403);
        }
        recipientId = isProfessional ? job.customerId : job.professionalId;
        title = 'Job Update';
        body = `Job status changed to ${status || job.status}.`;
        data.status = status || job.status;
        break;
      }
      default:
        return errorResponse(res, 'Unknown notification type', 400);
    }

    if (recipientId) {
      await notificationService.sendPushNotification(recipientId, title, body, data);
    }

    return successResponse(res, null, 'Notification sent');
  } catch (error) {
    logger.error('Trigger job event notification error:', error);
    return errorResponse(res, 'Failed to send notification', 500);
  }
};

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearNotifications,
  triggerJobEvent,
};