// src/middleware/validation.js
const { validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (errors.isEmpty()) {
    return next();
  }

  const extractedErrors = errors.array().map(err => ({
    field: err.path,
    message: err.msg,
  }));

  return res.status(400).json({
    error: 'Validation Error',
    errors: extractedErrors,
  });
};

module.exports = {
  validate,
};