// src/routes/aiRoutes.js
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { body } = require('express-validator');
const {
  estimateCost,
  diagnosePhoto,
  recommendProfessionals,
  summarizeChat,
  translateMessage,
} = require('../controllers/aiController');

// Estimate cost
router.post('/estimate-cost',
  auth,
  [
    body('category').notEmpty().withMessage('Category is required'),
    body('description').notEmpty().withMessage('Description is required'),
  ],
  validate,
  estimateCost
);

// Diagnose photo
router.post('/diagnose',
  auth,
  [
    body('imageBase64').notEmpty().withMessage('Image is required'),
  ],
  validate,
  diagnosePhoto
);

// Recommend professionals
router.post('/recommend',
  auth,
  [
    body('category').notEmpty().withMessage('Category is required'),
  ],
  validate,
  recommendProfessionals
);

// Summarize chat
router.post('/summarize',
  auth,
  [
    body('messages').isArray().withMessage('Messages must be an array'),
  ],
  validate,
  summarizeChat
);

// Translate message
router.post('/translate',
  auth,
  [
    body('message').notEmpty().withMessage('Message is required'),
    body('targetLanguage').notEmpty().withMessage('Target language is required'),
  ],
  validate,
  translateMessage
);

module.exports = router;