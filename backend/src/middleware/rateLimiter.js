// src/middleware/rateLimiter.js
const rateLimit = require('express-rate-limit');

const rateLimiter = rateLimit({
  windowMs: (process.env.RATE_LIMIT_WINDOW || 15) * 60 * 1000,
  max: parseInt(process.env.RATE_LIMIT_MAX || 100),
  message: {
    error: 'Too many requests',
    message: 'Please try again later',
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const authRateLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 20,
  message: {
    error: 'Too many authentication attempts',
    message: 'Please try again later',
  },
});

const apiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: {
    error: 'Too many requests',
    message: 'Please slow down',
  },
});

module.exports = {
  rateLimiter,
  authRateLimiter,
  apiRateLimiter,
};