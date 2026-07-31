// src/routes/chatRoutes.js
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { body, param } = require('express-validator');
const {
  getChatThreads,
  getChatMessages,
  sendMessage,
  createChat,
  markMessagesRead,
  deleteChat,
} = require('../controllers/chatController');

// Get all chat threads
router.get('/threads',
  auth,
  getChatThreads
);

// Create chat
router.post('/threads',
  auth,
  [
    body('userId').notEmpty().withMessage('User ID is required'),
  ],
  validate,
  createChat
);

// Get chat messages
router.get('/threads/:threadId/messages',
  auth,
  [
    param('threadId').notEmpty().withMessage('Thread ID is required'),
  ],
  validate,
  getChatMessages
);

// Send message
router.post('/threads/:threadId/messages',
  auth,
  [
    param('threadId').notEmpty().withMessage('Thread ID is required'),
    body('message').notEmpty().withMessage('Message is required'),
  ],
  validate,
  sendMessage
);

// Mark messages as read
router.put('/threads/:threadId/read',
  auth,
  [
    param('threadId').notEmpty().withMessage('Thread ID is required'),
  ],
  validate,
  markMessagesRead
);

// Delete chat
router.delete('/threads/:threadId',
  auth,
  [
    param('threadId').notEmpty().withMessage('Thread ID is required'),
  ],
  validate,
  deleteChat
);

module.exports = router;