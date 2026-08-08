// src/middleware/errorHandler.js
const { logger } = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
  logger.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    body: req.body,
    user: req.userId,
  });

  // Handle specific error types
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: err.message,
    });
  }

  if (err.name === 'UnauthorizedError' || err.code === 'auth/unauthorized') {
    return res.status(401).json({
      error: 'Unauthorized',
      message: err.message || 'Invalid authentication',
    });
  }

  if (err.name === 'FirebaseError') {
    return res.status(500).json({
      error: 'Database Error',
      message: err.message,
    });
  }

  // Default error response
  const statusCode = err.statusCode || 500;
  const message = err.isOperational ? err.message : 'Internal Server Error';

  res.status(statusCode).json({
    error: message,
    ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
  });
};

module.exports = {
  errorHandler,
};