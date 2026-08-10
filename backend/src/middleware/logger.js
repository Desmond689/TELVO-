// src/middleware/logger.js
const { logger } = require('../utils/logger');

const logRequest = (req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info(`${req.method} ${req.url} ${res.statusCode} - ${duration}ms`);
  });
  
  next();
};

module.exports = {
  logRequest,
};