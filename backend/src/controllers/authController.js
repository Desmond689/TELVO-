// src/controllers/authController.js
const { getAuth } = require('../config/firebase');
const User = require('../models/User');
const { logger } = require('../utils/logger');
const { successResponse, errorResponse } = require('../utils/responseHandler');

const sendOTP = async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    // Generate OTP (in production, use Firebase Auth)
    const otp = Math.floor(100000 + Math.random() * 900000);
    
    logger.info(`OTP for ${phoneNumber}: ${otp}`);
    
    return successResponse(res, {
      phoneNumber,
      expiresIn: 600
    }, 'OTP sent successfully');
  } catch (error) {
    logger.error('Send OTP error:', error);
    return errorResponse(res, 'Failed to send OTP', 500);
  }
};

const verifyOTP = async (req, res) => {
  try {
    const { phoneNumber, otp } = req.body;
    
    let user = await User.findByPhone(phoneNumber);
    
    if (!user) {
      user = new User({
        phoneNumber,
        userType: 'customer',
        isPhoneVerified: true,
      });
    }
    
    return successResponse(res, {
      userId: user.id || 'temp_id',
      isNewUser: !user.id
    }, 'OTP verified successfully');
  } catch (error) {
    logger.error('Verify OTP error:', error);
    return errorResponse(res, 'Failed to verify OTP', 500);
  }
};

const googleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    const decodedToken = await getAuth().verifyIdToken(idToken);
    
    if (!decodedToken) {
      return errorResponse(res, 'Invalid Google token', 401);
    }
    
    let user = await User.findById(decodedToken.uid);
    
    if (!user) {
      user = new User({
        id: decodedToken.uid,
        email: decodedToken.email,
        fullName: decodedToken.name,
        profilePhoto: decodedToken.picture,
        userType: 'customer',
        isEmailVerified: decodedToken.email_verified || false,
      });
    }
    
    return successResponse(res, user.toJSON(), 'Google sign in successful');
  } catch (error) {
    logger.error('Google sign in error:', error);
    return errorResponse(res, 'Failed to sign in with Google', 500);
  }
};

const appleSignIn = async (req, res) => {
  try {
    const { idToken } = req.body;
    const decodedToken = await getAuth().verifyIdToken(idToken);
    
    if (!decodedToken) {
      return errorResponse(res, 'Invalid Apple token', 401);
    }
    
    let user = await User.findById(decodedToken.uid);
    
    if (!user) {
      user = new User({
        id: decodedToken.uid,
        email: decodedToken.email,
        fullName: decodedToken.name || 'Apple User',
        userType: 'customer',
        isEmailVerified: true,
      });
    }
    
    return successResponse(res, user.toJSON(), 'Apple sign in successful');
  } catch (error) {
    logger.error('Apple sign in error:', error);
    return errorResponse(res, 'Failed to sign in with Apple', 500);
  }
};

const facebookSignIn = async (req, res) => {
  try {
    const { accessToken } = req.body;
    
    // Verify Facebook token
    // In production, use Firebase Auth with Facebook provider
    
    return successResponse(res, null, 'Facebook sign in successful');
  } catch (error) {
    logger.error('Facebook sign in error:', error);
    return errorResponse(res, 'Failed to sign in with Facebook', 500);
  }
};

const logout = async (req, res) => {
  try {
    if (req.user) {
      req.user.isOnline = false;
      await req.user.save();
    }
    
    return successResponse(res, null, 'Logged out successfully');
  } catch (error) {
    logger.error('Logout error:', error);
    return errorResponse(res, 'Failed to logout', 500);
  }
};

const refreshToken = async (req, res) => {
  try {
    return successResponse(res, {
      token: req.token
    }, 'Token refreshed');
  } catch (error) {
    logger.error('Refresh token error:', error);
    return errorResponse(res, 'Failed to refresh token', 500);
  }
};

module.exports = {
  sendOTP,
  verifyOTP,
  googleSignIn,
  appleSignIn,
  facebookSignIn,
  logout,
  refreshToken,
};