// src/utils/constants.js
module.exports = {
  // User Types
  USER_TYPES: {
    CUSTOMER: 'customer',
    PROFESSIONAL: 'professional',
    BOTH: 'both',
    ADMIN: 'admin',
  },

  // Job Statuses
  JOB_STATUS: {
    POSTED: 'posted',
    NOTIFIED: 'notified',
    QUOTES_RECEIVED: 'quotes_received',
    QUOTES_EXPIRED: 'quotes_expired',
    ACCEPTED: 'accepted',
    REJECTED: 'rejected',
    ON_THE_WAY: 'on_the_way',
    WORKING: 'working',
    COMPLETED: 'completed',
    CANCELLED: 'cancelled',
  },

  // Payment Methods
  PAYMENT_METHODS: {
    CASH: 'cash',
    MOMO: 'momo',
    ORANGE: 'orange',
    CARD: 'card',
    ESCROW: 'escrow',
  },

  // Payment Statuses
  PAYMENT_STATUS: {
    PENDING: 'pending',
    PROCESSING: 'processing',
    COMPLETED: 'completed',
    FAILED: 'failed',
    REFUNDED: 'refunded',
  },

  // Urgency Levels
  URGENCY: {
    EMERGENCY: 'emergency',
    TODAY: 'today',
    TOMORROW: 'tomorrow',
    FLEXIBLE: 'flexible',
  },

  // Verification Types
  VERIFICATION: {
    PHONE: 'phone',
    EMAIL: 'email',
    ID: 'id',
    SELFIE: 'selfie',
  },

  // Notification Types
  NOTIFICATION_TYPES: {
    JOB: 'job',
    MESSAGE: 'message',
    PAYMENT: 'payment',
    PROMOTION: 'promotion',
    SYSTEM: 'system',
  },

  // Error Codes
  ERROR_CODES: {
    UNAUTHORIZED: 'UNAUTHORIZED',
    FORBIDDEN: 'FORBIDDEN',
    NOT_FOUND: 'NOT_FOUND',
    VALIDATION_ERROR: 'VALIDATION_ERROR',
    DUPLICATE: 'DUPLICATE',
    RATE_LIMIT: 'RATE_LIMIT',
    INTERNAL_ERROR: 'INTERNAL_ERROR',
  },

  // Limits
  LIMITS: {
    MAX_PHOTOS_PER_JOB: 10,
    MAX_PHOTOS_PER_REVIEW: 5,
    MAX_QUOTES_PER_JOB: 20,
    MAX_MESSAGE_LENGTH: 5000,
    MAX_PORTFOLIO_PHOTOS: 20,
    MAX_SKILLS: 20,
  },

  // Timeouts
  TIMEOUTS: {
    OTP_EXPIRY: 600, // 10 minutes
    JOB_EXPIRY: 86400, // 24 hours
    SESSION_TIMEOUT: 3600, // 1 hour
  },
};