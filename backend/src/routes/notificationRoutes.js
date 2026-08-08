// src/routes/notificationRoutes.js
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { param, body } = require('express-validator');
const {
  getNotifications,
  markAsRead,
  markAllAsRead,
  deleteNotification,
  clearNotifications,
  triggerJobEvent,
} = require('../controllers/notificationController');

router.get('/', auth, getNotifications);

router.post(
  '/job-event',
  auth,
  [
    body('jobId').notEmpty().withMessage('jobId is required'),
    body('type')
      .isIn(['new_job', 'new_quote', 'quote_accepted', 'job_update'])
      .withMessage('Invalid notification type'),
  ],
  validate,
  triggerJobEvent
);

router.put(
  '/:id/read',
  auth,
  [param('id').notEmpty().withMessage('Notification ID is required')],
  validate,
  markAsRead
);

router.put('/read-all', auth, markAllAsRead);

router.delete(
  '/:id',
  auth,
  [param('id').notEmpty().withMessage('Notification ID is required')],
  validate,
  deleteNotification
);

router.delete('/', auth, clearNotifications);

module.exports = router;
