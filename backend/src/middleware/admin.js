// src/middleware/admin.js
const { admin } = require('../config/firebase');
const { logger } = require('../utils/logger');

const requireAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Authentication required' });
    }

    // Check if user is an admin
    const adminSnapshot = await admin.firestore()
      .collection('admins')
      .where('userId', '==', req.user.id)
      .get();

    if (adminSnapshot.empty) {
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'Admin access required' 
      });
    }

    const adminData = adminSnapshot.docs[0].data();
    
    // Check if admin is active
    if (!adminData.isActive) {
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'Admin account is inactive' 
      });
    }

    // Attach admin data to request
    req.admin = adminData;
    req.adminId = adminSnapshot.docs[0].id;
    
    // Check specific permissions if required
    if (req.requiredPermission) {
      if (adminData.role !== 'super_admin' && 
          !(adminData.permissions || []).includes(req.requiredPermission)) {
        return res.status(403).json({ 
          error: 'Forbidden', 
          message: `Missing required permission: ${req.requiredPermission}` 
        });
      }
    }

    next();
  } catch (error) {
    logger.error('Admin middleware error:', error);
    return res.status(500).json({ 
      error: 'Internal Server Error', 
      message: 'Failed to verify admin access' 
    });
  }
};

const requireSuperAdmin = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized', message: 'Authentication required' });
    }

    const adminSnapshot = await admin.firestore()
      .collection('admins')
      .where('userId', '==', req.user.id)
      .where('role', '==', 'super_admin')
      .get();

    if (adminSnapshot.empty) {
      return res.status(403).json({ 
        error: 'Forbidden', 
        message: 'Super admin access required' 
      });
    }

    req.admin = adminSnapshot.docs[0].data();
    req.adminId = adminSnapshot.docs[0].id;
    next();
  } catch (error) {
    logger.error('Super admin middleware error:', error);
    return res.status(500).json({ 
      error: 'Internal Server Error', 
      message: 'Failed to verify super admin access' 
    });
  }
};

const withPermission = (permission) => {
  return (req, res, next) => {
    req.requiredPermission = permission;
    return requireAdmin(req, res, next);
  };
};

module.exports = {
  requireAdmin,
  requireSuperAdmin,
  withPermission,
};