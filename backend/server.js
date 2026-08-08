// server.js
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const { initializeFirebase } = require('./src/config/firebase');
const { errorHandler } = require('./src/middleware/errorHandler');
const { rateLimiter } = require('./src/middleware/rateLimiter');
const { logger } = require('./src/utils/logger');

const app = express();
const PORT = process.env.PORT || 3000;

// Initialize Firebase
initializeFirebase();

// Middleware
app.use(helmet());
app.use(compression());
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000')
  .split(',')
  .map((origin) => origin.trim());

app.use(cors({
  origin: (origin, callback) => {
    // Allow non-browser tools (curl, mobile apps, server-to-server) with no origin header
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error(`Origin ${origin} not allowed by CORS`));
    }
  },
  credentials: true
}));
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));
app.use(morgan('combined'));
app.use(rateLimiter);

// Request logging
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.url}`);
  next();
});

// Routes
app.use('/api/auth', require('./src/routes/authRoutes'));
app.use('/api/users', require('./src/routes/userRoutes'));
app.use('/api/jobs', require('./src/routes/jobRoutes'));
app.use('/api/payments', require('./src/routes/paymentRoutes'));
app.use('/api/chats', require('./src/routes/chatRoutes'));
app.use('/api/reviews', require('./src/routes/reviewRoutes'));
app.use('/api/notifications', require('./src/routes/notificationRoutes'));
app.use('/api/admin', require('./src/routes/adminRoutes'));
app.use('/api/ai', require('./src/routes/aiRoutes'));
app.use('/api/uploads', require('./src/routes/uploadRoutes'));
app.use('/api/webhooks', require('./src/routes/webhookRoutes'));

// Health check
app.get('/health', (req, res) => {
  res.status(200).json({ 
    status: 'OK', 
    timestamp: new Date().toISOString(),
    version: process.env.npm_package_version || '1.0.0',
    environment: process.env.NODE_ENV
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Not Found', 
    message: `Route ${req.url} not found` 
  });
});

// Error handling
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  logger.info(`🚀 Telvo Backend running on port ${PORT}`);
  logger.info(`📡 Environment: ${process.env.NODE_ENV || 'development'}`);
  logger.info(`📍 API URL: http://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM signal received: closing HTTP server');
  app.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

module.exports = app;