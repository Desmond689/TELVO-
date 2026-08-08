// src/utils/validators.js
const { body, param, query } = require('express-validator');

// Common validators
const validatePhone = (field = 'phoneNumber') => {
  return body(field)
    .notEmpty().withMessage('Phone number is required')
    .isString().withMessage('Phone number must be a string')
    .matches(/^\+?[0-9]{8,15}$/).withMessage('Invalid phone number format');
};

const validateEmail = (field = 'email') => {
  return body(field)
    .optional()
    .isEmail().withMessage('Invalid email address');
};

const validateName = (field = 'fullName') => {
  return body(field)
    .notEmpty().withMessage('Name is required')
    .isLength({ min: 2, max: 50 }).withMessage('Name must be between 2 and 50 characters');
};

const validateOTP = (field = 'otp') => {
  return body(field)
    .notEmpty().withMessage('OTP is required')
    .isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits')
    .matches(/^[0-9]{6}$/).withMessage('OTP must be numeric');
};

const validateBudget = (field = 'budget') => {
  return body(field)
    .optional()
    .isFloat({ min: 0 }).withMessage('Budget must be a positive number');
};

const validateRating = (field = 'rating') => {
  return body(field)
    .notEmpty().withMessage('Rating is required')
    .isFloat({ min: 0, max: 5 }).withMessage('Rating must be between 0 and 5');
};

const validateLatitude = (field = 'latitude') => {
  return body(field)
    .optional()
    .isFloat({ min: -90, max: 90 }).withMessage('Invalid latitude');
};

const validateLongitude = (field = 'longitude') => {
  return body(field)
    .optional()
    .isFloat({ min: -180, max: 180 }).withMessage('Invalid longitude');
};

const validateUrl = (field) => {
  return body(field)
    .optional()
    .isURL().withMessage('Invalid URL');
};

const validateEnum = (field, enumValues, message) => {
  return body(field)
    .optional()
    .isIn(enumValues).withMessage(message || `Invalid value for ${field}`);
};

const validateId = (field = 'id') => {
  return param(field)
    .notEmpty().withMessage('ID is required')
    .isString().withMessage('ID must be a string');
};

const validatePagination = () => {
  return [
    query('page')
      .optional()
      .isInt({ min: 1 }).withMessage('Page must be a positive integer')
      .toInt(),
    query('limit')
      .optional()
      .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100')
      .toInt(),
  ];
};

// Auth validators
const validateSignup = () => {
  return [
    validatePhone(),
    validateEmail('email'),
    validateName('fullName'),
  ];
};

const validateLogin = () => {
  return [
    validatePhone(),
    body('password')
      .notEmpty().withMessage('Password is required'),
  ];
};

// Job validators
const validateCreateJob = () => {
  return [
    body('category')
      .notEmpty().withMessage('Category is required')
      .isString().withMessage('Category must be a string'),
    body('description')
      .notEmpty().withMessage('Description is required')
      .isLength({ min: 10, max: 1000 }).withMessage('Description must be between 10 and 1000 characters'),
    validateBudget(),
    body('urgency')
      .optional()
      .isIn(['emergency', 'today', 'tomorrow', 'flexible']).withMessage('Invalid urgency level'),
    body('address')
      .optional()
      .isString().withMessage('Address must be a string'),
    validateLatitude('latitude'),
    validateLongitude('longitude'),
  ];
};

const validateQuote = () => {
  return [
    body('price')
      .notEmpty().withMessage('Price is required')
      .isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('estimatedTime')
      .optional()
      .isInt({ min: 1 }).withMessage('Estimated time must be a positive integer'),
    body('message')
      .optional()
      .isString().withMessage('Message must be a string')
      .isLength({ max: 500 }).withMessage('Message cannot exceed 500 characters'),
  ];
};

// Review validators
const validateCreateReview = () => {
  return [
    validateRating(),
    body('comment')
      .optional()
      .isLength({ max: 1000 }).withMessage('Comment cannot exceed 1000 characters'),
    body('photos')
      .optional()
      .isArray().withMessage('Photos must be an array'),
    body('isAnonymous')
      .optional()
      .isBoolean().withMessage('isAnonymous must be a boolean'),
  ];
};

module.exports = {
  // Individual validators
  validatePhone,
  validateEmail,
  validateName,
  validateOTP,
  validateBudget,
  validateRating,
  validateLatitude,
  validateLongitude,
  validateUrl,
  validateEnum,
  validateId,
  validatePagination,
  
  // Auth validators
  validateSignup,
  validateLogin,
  
  // Job validators
  validateCreateJob,
  validateQuote,
  
  // Review validators
  validateCreateReview,
};