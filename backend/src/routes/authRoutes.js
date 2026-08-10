// src/routes/authRoutes.js
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { auth } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { authRateLimiter } = require('../middleware/rateLimiter');
const { successResponse, errorResponse } = require('../utils/responseHandler');
const { logger } = require('../utils/logger');
const User = require('../models/User');
const { getAuth } = require('../config/firebase');

// Send OTP
router.post('/send-otp',
  authRateLimiter,
  [
    body('phoneNumber')
      .notEmpty().withMessage('Phone number is required')
      .matches(/^\+?[0-9]{8,15}$/).withMessage('Invalid phone number'),
  ],
  validate,
  async (req, res) => {
    try {
      const { phoneNumber } = req.body;
      
      // Format phone number
      let formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+' + formattedPhone;
      }
      
      // Generate OTP (in production, send via SMS)
      const otp = Math.floor(100000 + Math.random() * 900000);
      
      // Store OTP in Firebase (for demo purposes)
      // In production, use Firebase Auth phone verification
      
      logger.info(`OTP for ${formattedPhone}: ${otp}`);
      
      return successResponse(res, {
        phoneNumber: formattedPhone,
        expiresIn: 600, // 10 minutes
      }, 'OTP sent successfully');
    } catch (error) {
      logger.error('Send OTP error:', error);
      return errorResponse(res, 'Failed to send OTP', 500);
    }
  }
);

// Verify OTP
router.post('/verify-otp',
  authRateLimiter,
  [
    body('phoneNumber')
      .notEmpty().withMessage('Phone number is required'),
    body('otp')
      .notEmpty().withMessage('OTP is required')
      .isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  ],
  validate,
  async (req, res) => {
    try {
      const { phoneNumber, otp } = req.body;
      
      // In production, verify OTP with Firebase Auth
      // For demo, accept any 6-digit OTP
      
      // Check if user exists
      let user = await User.findByPhone(phoneNumber);
      
      if (!user) {
        // Create new user
        user = new User({
          phoneNumber,
          userType: 'customer',
          isPhoneVerified: true,
        });
        // Save user
        // In production, save to Firebase
      }
      
      return successResponse(res, {
        userId: user.id || 'temp_id',
        isNewUser: !user.id,
      }, 'OTP verified successfully');
    } catch (error) {
      logger.error('Verify OTP error:', error);
      return errorResponse(res, 'Failed to verify OTP', 500);
    }
  }
);

// Google Sign In
router.post('/google',
  [
    body('idToken')
      .notEmpty().withMessage('ID token is required'),
  ],
  validate,
  async (req, res) => {
    try {
      const { idToken } = req.body;
      
      // Verify Google ID token
      const decodedToken = await getAuth().verifyIdToken(idToken);
      
      if (!decodedToken) {
        return errorResponse(res, 'Invalid Google token', 401);
      }
      
      // Check if user exists
      let user = await User.findById(decodedToken.uid);
      
      if (!user) {
        // Create new user
        user = new User({
          id: decodedToken.uid,
          email: decodedToken.email,
          fullName: decodedToken.name,
          profilePhoto: decodedToken.picture,
          userType: 'customer',
          isEmailVerified: decodedToken.email_verified || false,
        });
        // Save user
      }
      
      return successResponse(res, {
        userId: user.id,
        email: user.email,
        fullName: user.fullName,
        profilePhoto: user.profilePhoto,
      }, 'Google sign in successful');
    } catch (error) {
      logger.error('Google sign in error:', error);
      return errorResponse(res, 'Failed to sign in with Google', 500);
    }
  }
);

// Apple Sign In
router.post('/apple',
  [
    body('idToken')
      .notEmpty().withMessage('ID token is required'),
  ],
  validate,
  async (req, res) => {
    try {
      const { idToken } = req.body;
      
      // Verify Apple ID token
      const decodedToken = await getAuth().verifyIdToken(idToken);
      
      if (!decodedToken) {
        return errorResponse(res, 'Invalid Apple token', 401);
      }
      
      // Check if user exists
      let user = await User.findById(decodedToken.uid);
      
      if (!user) {
        // Create new user
        user = new User({
          id: decodedToken.uid,
          email: decodedToken.email,
          fullName: decodedToken.name || 'Apple User',
          userType: 'customer',
          isEmailVerified: true,
        });
        // Save user
      }
      
      return successResponse(res, {
        userId: user.id,
        email: user.email,
        fullName: user.fullName,
      }, 'Apple sign in successful');
    } catch (error) {
      logger.error('Apple sign in error:', error);
      return errorResponse(res, 'Failed to sign in with Apple', 500);
    }
  }
);

// Facebook Sign In
router.post('/facebook',
  [
    body('accessToken')
      .notEmpty().withMessage('Access token is required'),
  ],
  validate,
  async (req, res) => {
    try {
      const { accessToken } = req.body;
      
      // Verify Facebook token
      // In production, use Firebase Auth with Facebook provider
      
      return successResponse(res, {
        message: 'Facebook sign in successful',
      }, 'Facebook sign in successful');
    } catch (error) {
      logger.error('Facebook sign in error:', error);
      return errorResponse(res, 'Failed to sign in with Facebook', 500);
    }
  }
);

// Logout
router.post('/logout',
  auth,
  async (req, res) => {
    try {
      // Update user status
      if (req.user) {
        req.user.isOnline = false;
        await req.user.save();
      }
      
      return successResponse(res, null, 'Logged out successfully');
    } catch (error) {
      logger.error('Logout error:', error);
      return errorResponse(res, 'Failed to logout', 500);
    }
  }
);

// Refresh token
router.post('/refresh-token',
  auth,
  async (req, res) => {
    try {
      // In production, refresh Firebase token
      return successResponse(res, {
        token: req.token,
      }, 'Token refreshed');
    } catch (error) {
      logger.error('Refresh token error:', error);
      return errorResponse(res, 'Failed to refresh token', 500);
    }
  }
);

module.exports = router;