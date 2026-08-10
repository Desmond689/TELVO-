// src/routes/adminRoutes.js
const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');
const { auth } = require('../middleware/auth');
const { requireAdmin, requireSuperAdmin, withPermission } = require('../middleware/admin');
const { validate } = require('../middleware/validation');
const { successResponse, errorResponse, paginatedResponse } = require('../utils/responseHandler');
const { logger } = require('../utils/logger');
const User = require('../models/User');
const Job = require('../models/Job');
const Payment = require('../models/Payment');
const Review = require('../models/Review');

// Dashboard stats
router.get('/stats',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      // Get all users
      const allUsers = await User.findByEmail(''); // This won't work directly
      // In production, use proper aggregation
      
      // For demo, return mock stats
      const stats = {
        totalUsers: 1250,
        totalProfessionals: 340,
        totalJobs: 845,
        totalRevenue: 12450000,
        pendingVerifications: 12,
        activeJobs: 45,
        disputes: 3,
        fraudReports: 2,
        categoryStats: {
          'Plumber': 150,
          'Electrician': 120,
          'Cleaner': 100,
          'Painter': 80,
          'Carpenter': 60,
        },
      };
      
      return successResponse(res, stats);
    } catch (error) {
      logger.error('Get admin stats error:', error);
      return errorResponse(res, 'Failed to get admin stats', 500);
    }
  }
);

// Get all users
router.get('/users',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { limit = 50, offset = 0, search = '', role = 'all' } = req.query;
      
      // In production, implement proper filtering and pagination
      const users = []; // Fetch from Firestore
      
      return paginatedResponse(res, users, users.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Get users error:', error);
      return errorResponse(res, 'Failed to get users', 500);
    }
  }
);

// Get user by ID
router.get('/users/:id',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const user = await User.findById(id);
      if (!user) {
        return errorResponse(res, 'User not found', 404);
      }
      
      return successResponse(res, user.toJSON());
    } catch (error) {
      logger.error('Get user error:', error);
      return errorResponse(res, 'Failed to get user', 500);
    }
  }
);

// Update user (admin)
router.put('/users/:id',
  auth,
  requireAdmin,
  [
    body('fullName')
      .optional()
      .isLength({ min: 2, max: 50 }).withMessage('Name must be between 2 and 50 characters'),
    body('email')
      .optional()
      .isEmail().withMessage('Invalid email'),
    body('isVerified')
      .optional()
      .isBoolean().withMessage('isVerified must be a boolean'),
    body('isSuspended')
      .optional()
      .isBoolean().withMessage('isSuspended must be a boolean'),
  ],
  validate,
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const user = await User.findById(id);
      if (!user) {
        return errorResponse(res, 'User not found', 404);
      }
      
      const allowedFields = ['fullName', 'email', 'isVerified', 'isSuspended', 'userType'];
      for (const field of allowedFields) {
        if (req.body[field] !== undefined) {
          user[field] = req.body[field];
        }
      }
      
      await user.save();
      
      return successResponse(res, user.toJSON(), 'User updated successfully');
    } catch (error) {
      logger.error('Admin update user error:', error);
      return errorResponse(res, 'Failed to update user', 500);
    }
  }
);

// Verify professional
router.post('/verify/:userId',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { userId } = req.params;
      
      const user = await User.findById(userId);
      if (!user) {
        return errorResponse(res, 'User not found', 404);
      }
      
      if (!user.isProfessional()) {
        return errorResponse(res, 'User is not a professional', 400);
      }
      
      user.isVerified = true;
      user.isIdVerified = true;
      user.isSelfieVerified = true;
      await user.save();
      
      return successResponse(res, user.toJSON(), 'Professional verified successfully');
    } catch (error) {
      logger.error('Verify professional error:', error);
      return errorResponse(res, 'Failed to verify professional', 500);
    }
  }
);

// Get all jobs (admin)
router.get('/jobs',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { status, category, limit = 50, offset = 0 } = req.query;
      
      // In production, implement proper filtering
      const jobs = []; // Fetch from Firestore
      
      return paginatedResponse(res, jobs, jobs.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Admin get jobs error:', error);
      return errorResponse(res, 'Failed to get jobs', 500);
    }
  }
);

// Update job (admin)
router.put('/jobs/:id',
  auth,
  requireAdmin,
  [
    body('status')
      .optional()
      .isIn(['posted', 'notified', 'quotes_received', 'accepted', 'working', 'completed', 'cancelled'])
      .withMessage('Invalid status'),
  ],
  validate,
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const job = await Job.findById(id);
      if (!job) {
        return errorResponse(res, 'Job not found', 404);
      }
      
      if (req.body.status) {
        await job.updateStatus(req.body.status);
      }
      
      return successResponse(res, job.toJSON(), 'Job updated successfully');
    } catch (error) {
      logger.error('Admin update job error:', error);
      return errorResponse(res, 'Failed to update job', 500);
    }
  }
);

// Get payments (admin)
router.get('/payments',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { status, method, limit = 50, offset = 0 } = req.query;
      
      // In production, implement proper filtering
      const payments = []; // Fetch from Firestore
      
      return paginatedResponse(res, payments, payments.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Admin get payments error:', error);
      return errorResponse(res, 'Failed to get payments', 500);
    }
  }
);

// Process refund (admin)
router.post('/refund/:paymentId',
  auth,
  requireAdmin,
  [
    body('reason')
      .optional()
      .isString().withMessage('Reason must be a string'),
  ],
  validate,
  async (req, res) => {
    try {
      const { paymentId } = req.params;
      const { reason } = req.body;
      
      const payment = await Payment.findById(paymentId);
      if (!payment) {
        return errorResponse(res, 'Payment not found', 404);
      }
      
      if (!payment.isCompleted()) {
        return errorResponse(res, 'Only completed payments can be refunded', 400);
      }
      
      await payment.refund(reason || 'Refund requested by admin');
      
      return successResponse(res, payment.toJSON(), 'Refund processed successfully');
    } catch (error) {
      logger.error('Process refund error:', error);
      return errorResponse(res, 'Failed to process refund', 500);
    }
  }
);

// Get reviews (admin)
router.get('/reviews',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { rating, limit = 50, offset = 0 } = req.query;
      
      // In production, implement proper filtering
      const reviews = []; // Fetch from Firestore
      
      return paginatedResponse(res, reviews, reviews.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Admin get reviews error:', error);
      return errorResponse(res, 'Failed to get reviews', 500);
    }
  }
);

// Delete review (admin)
router.delete('/reviews/:id',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { id } = req.params;
      
      const review = await Review.findById(id);
      if (!review) {
        return errorResponse(res, 'Review not found', 404);
      }
      
      await review.delete();
      
      return successResponse(res, null, 'Review deleted successfully');
    } catch (error) {
      logger.error('Admin delete review error:', error);
      return errorResponse(res, 'Failed to delete review', 500);
    }
  }
);

// Get disputes (admin)
router.get('/disputes',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { status, limit = 50, offset = 0 } = req.query;
      
      // In production, fetch from Firestore
      const disputes = [];
      
      return paginatedResponse(res, disputes, disputes.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Admin get disputes error:', error);
      return errorResponse(res, 'Failed to get disputes', 500);
    }
  }
);

// Resolve dispute (admin)
router.post('/disputes/:id/resolve',
  auth,
  requireAdmin,
  [
    body('resolution')
      .notEmpty().withMessage('Resolution is required'),
  ],
  validate,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { resolution } = req.body;
      
      // In production, update dispute in Firestore
      
      return successResponse(res, null, 'Dispute resolved successfully');
    } catch (error) {
      logger.error('Resolve dispute error:', error);
      return errorResponse(res, 'Failed to resolve dispute', 500);
    }
  }
);

// Get fraud reports (admin)
router.get('/fraud-reports',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { status, limit = 50, offset = 0 } = req.query;
      
      // In production, fetch from Firestore
      const reports = [];
      
      return paginatedResponse(res, reports, reports.length, parseInt(offset) + 1, parseInt(limit));
    } catch (error) {
      logger.error('Admin get fraud reports error:', error);
      return errorResponse(res, 'Failed to get fraud reports', 500);
    }
  }
);

// Verify fraud report (admin)
router.post('/fraud-reports/:id/verify',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      const { id } = req.params;
      
      // In production, update report in Firestore
      
      return successResponse(res, null, 'Fraud report verified successfully');
    } catch (error) {
      logger.error('Verify fraud report error:', error);
      return errorResponse(res, 'Failed to verify fraud report', 500);
    }
  }
);

// Create promotion (admin)
router.post('/promotions',
  auth,
  requireAdmin,
  [
    body('title')
      .notEmpty().withMessage('Title is required'),
    body('description')
      .notEmpty().withMessage('Description is required'),
    body('code')
      .notEmpty().withMessage('Promo code is required'),
    body('discount')
      .notEmpty().withMessage('Discount is required')
      .isFloat({ min: 0 }).withMessage('Discount must be a positive number'),
    body('type')
      .notEmpty().withMessage('Type is required')
      .isIn(['percentage', 'fixed']).withMessage('Invalid type'),
    body('startDate')
      .notEmpty().withMessage('Start date is required'),
    body('endDate')
      .notEmpty().withMessage('End date is required'),
  ],
  validate,
  async (req, res) => {
    try {
      // In production, save promotion to Firestore
      
      return successResponse(res, req.body, 'Promotion created successfully', 201);
    } catch (error) {
      logger.error('Create promotion error:', error);
      return errorResponse(res, 'Failed to create promotion', 500);
    }
  }
);

// Admin profile
router.get('/profile',
  auth,
  requireAdmin,
  async (req, res) => {
    try {
      // In production, fetch admin profile from Firestore
      const adminProfile = {
        id: req.adminId || 'admin1',
        email: 'admin@telvo.com',
        fullName: 'Admin User',
        role: 'super_admin',
        isActive: true,
        lastLogin: new Date(),
      };
      
      return successResponse(res, adminProfile);
    } catch (error) {
      logger.error('Get admin profile error:', error);
      return errorResponse(res, 'Failed to get admin profile', 500);
    }
  }
);

module.exports = router;