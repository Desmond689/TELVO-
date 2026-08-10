// src/routes/paymentRoutes.js
const express = require('express');
const router = express.Router();
const { auth, requireCustomer } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { body, param } = require('express-validator');
const {
  processPayment,
  getPaymentHistory,
  getPaymentById,
  requestRefund,
} = require('../controllers/paymentController');

// Process payment
router.post('/process',
  auth,
  requireCustomer,
  [
    body('jobId').notEmpty().withMessage('Job ID is required'),
    body('method').notEmpty().withMessage('Payment method is required'),
    body('amount').isFloat({ min: 0 }).withMessage('Amount must be positive'),
  ],
  validate,
  processPayment
);

// Get payment history
router.get('/history',
  auth,
  getPaymentHistory
);

// Get payment by ID
router.get('/:id',
  auth,
  [
    param('id').notEmpty().withMessage('Payment ID is required'),
  ],
  validate,
  getPaymentById
);

// Request refund
router.post('/:id/refund',
  auth,
  [
    param('id').notEmpty().withMessage('Payment ID is required'),
    body('reason').optional().isString(),
  ],
  validate,
  requestRefund
);

module.exports = router;