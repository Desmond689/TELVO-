// src/middleware/auth.js
const admin = require('firebase-admin');
const { getAuth } = require('../config/firebase');
const User = require('../models/User');
const { logger } = require('../utils/logger');

const auth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized', message: 'No token provided' });
    }

    const token = authHeader.split('Bearer ')[1];
    
    // Verify the token with Firebase Admin
    const decodedToken = await getAuth().verifyIdToken(token);
    
    if (!decodedToken) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Invalid token' });
    }

    // Get user from database
    const user = await User.findById(decodedToken.uid);
    if (!user) {
      return res.status(401).json({ error: 'Unauthorized', message: 'User not found' });
    }

    // Check if user is suspended
    if (user.isSuspended) {
      return res.status(403).json({ error: 'Forbidden', message: 'Account suspended' });
    }

    // Attach user to request
    req.user = user;
    req.userId = decodedToken.uid;
    req.token = token;
    
    // Update last active
    user.lastActive = new Date();
    user.isOnline = true;
    await user.save().catch(err => logger.error('Error updating last active:', err));

    next();
  } catch (error) {
    logger.error('Auth middleware error:', error);
    return res.status(401).json({ 
      error: 'Unauthorized', 
      message: error.message || 'Invalid token' 
    });
  }
};

const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.split('Bearer ')[1];
      const decodedToken = await getAuth().verifyIdToken(token);
      if (decodedToken) {
        const user = await User.findById(decodedToken.uid);
        if (user && !user.isSuspended) {
          req.user = user;
          req.userId = decodedToken.uid;
        }
      }
    }
    next();
  } catch (error) {
    // Don't fail on optional auth
    next();
  }
};

const requireProfessional = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Authentication required' });
  }
  
  if (!req.user.isProfessional()) {
    return res.status(403).json({ 
      error: 'Forbidden', 
      message: 'Professional access required' 
    });
  }
  
  next();
};

const requireCustomer = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ error: 'Unauthorized', message: 'Authentication required' });
  }
  
  if (!req.user.isCustomer()) {
    return res.status(403).json({ 
      error: 'Forbidden', 
      message: 'Customer access required' 
    });
  }
  
  next();
};

module.exports = {
  auth,
  optionalAuth,
  requireProfessional,
  requireCustomer,
};