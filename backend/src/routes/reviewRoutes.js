// src/routes/reviewRoutes.js
const express = require('express');
const router = express.Router();
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { body, param } = require('express-validator');
const {
  createReview,
  getReviews,
  getReviewById,
  updateReview,
  deleteReview,
  addResponseToReview,
} = require('../controllers/reviewController');

// Create review
router.post('/',
  auth,
  [
    body('jobId').notEmpty().withMessage('Job ID is required'),
    body('rating').isFloat({ min: 0, max: 5 }).withMessage('Rating must be between 0 and 5'),
    body('comment').optional().isLength({ max: 500 }),
  ],
  validate,
  createReview
);

// Get reviews for user
router.get('/user/:userId',
  auth,
  [
    param('userId').notEmpty().withMessage('User ID is required'),
  ],
  validate,
  getReviews
);

// Get review by ID
router.get('/:id',
  auth,
  [
    param('id').notEmpty().withMessage('Review ID is required'),
  ],
  validate,
  getReviewById
);

// Update review
router.put('/:id',
  auth,
  [
    param('id').notEmpty().withMessage('Review ID is required'),
    body('comment').optional().isLength({ max: 500 }),
  ],
  validate,
  updateReview
);

// Delete review
router.delete('/:id',
  auth,
  [
    param('id').notEmpty().withMessage('Review ID is required'),
  ],
  validate,
  deleteReview
);

// Add response to review
router.post('/:id/response',
  auth,
  [
    param('id').notEmpty().withMessage('Review ID is required'),
    body('response').notEmpty().withMessage('Response is required'),
  ],
  validate,
  addResponseToReview
);

module.exports = router;