const { body, param, query, validationResult } = require('express-validator');
const logger = require('../utils/logger');

// Handle validation results
const handleValidationErrors = (req, res, next) => {
  const errors = validationResult(req);
  
  if (!errors.isEmpty()) {
    const formattedErrors = errors.array().map(error => ({
      field: error.type === 'field' ? error.path : error.param,
      message: error.msg,
      value: error.value
    }));

    logger.warn('Validation failed:', {
      url: req.url,
      method: req.method,
      errors: formattedErrors
    });

    return res.status(400).json({
      success: false,
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Request validation failed',
        details: formattedErrors
      }
    });
  }
  
  next();
};

// User validation rules
const validateUserRegistration = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .isLength({ min: 6 })
    .withMessage('Password must be at least 6 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one lowercase letter, one uppercase letter, and one number'),
  body('name')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  handleValidationErrors
];

const validateUserLogin = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Please provide a valid email'),
  body('password')
    .notEmpty()
    .withMessage('Password is required'),
  handleValidationErrors
];

const validateUserUpdate = [
  body('name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Name must be between 2 and 50 characters'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  body('preferences')
    .optional()
    .isObject()
    .withMessage('Preferences must be an object'),
  body('preferences.theme')
    .optional()
    .isIn(['light', 'dark', 'auto'])
    .withMessage('Theme must be light, dark, or auto'),
  body('preferences.language')
    .optional()
    .isIn(['en', 'es', 'fr', 'de', 'zh'])
    .withMessage('Unsupported language'),
  handleValidationErrors
];

// Product validation rules
const validateProductQuery = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('category')
    .optional()
    .isIn(['tops', 'bottoms', 'dresses', 'outerwear', 'accessories', 'footwear', 'activewear'])
    .withMessage('Invalid category'),
  query('sort')
    .optional()
    .isIn(['price_asc', 'price_desc', 'name_asc', 'name_desc', 'rating_desc', 'newest'])
    .withMessage('Invalid sort option'),
  query('minPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Minimum price must be a positive number'),
  query('maxPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Maximum price must be a positive number'),
  handleValidationErrors
];

const validateProductId = [
  param('id')
    .isAlphanumeric()
    .withMessage('Product ID must be alphanumeric'),
  handleValidationErrors
];

const validateAddToCart = [
  body('productId')
    .isAlphanumeric()
    .withMessage('Valid product ID is required'),
  body('quantity')
    .isInt({ min: 1, max: 10 })
    .withMessage('Quantity must be between 1 and 10'),
  handleValidationErrors
];

// Scan validation rules
const validateScanStart = [
  body('userId')
    .isAlphanumeric()
    .withMessage('Valid user ID is required'),
  body('method')
    .optional()
    .isIn(['camera', 'upload', 'manual'])
    .withMessage('Invalid scan method'),
  body('preferences')
    .optional()
    .isObject()
    .withMessage('Preferences must be an object'),
  handleValidationErrors
];

const validateScanStatus = [
  param('sessionId')
    .isUUID()
    .withMessage('Valid session ID is required'),
  handleValidationErrors
];

// Order validation rules
const validateCreateOrder = [
  body('items')
    .isArray({ min: 1 })
    .withMessage('Order must contain at least one item'),
  body('items.*.productId')
    .isAlphanumeric()
    .withMessage('Valid product ID required for each item'),
  body('items.*.quantity')
    .isInt({ min: 1, max: 10 })
    .withMessage('Quantity must be between 1 and 10'),
  body('shippingAddress')
    .isObject()
    .withMessage('Shipping address is required'),
  body('shippingAddress.street')
    .trim()
    .isLength({ min: 5, max: 100 })
    .withMessage('Street address must be between 5 and 100 characters'),
  body('shippingAddress.city')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('City must be between 2 and 50 characters'),
  body('shippingAddress.state')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('State must be between 2 and 50 characters'),
  body('shippingAddress.zipCode')
    .matches(/^\d{5}(-\d{4})?$/)
    .withMessage('Invalid ZIP code format'),
  body('shippingAddress.country')
    .trim()
    .isLength({ min: 2, max: 50 })
    .withMessage('Country must be between 2 and 50 characters'),
  handleValidationErrors
];

// Payment validation rules
const validatePaymentIntent = [
  body('amount')
    .isInt({ min: 50, max: 1000000 })
    .withMessage('Amount must be between $0.50 and $10,000.00'),
  body('currency')
    .isIn(['USD', 'EUR', 'GBP'])
    .withMessage('Currency must be USD, EUR, or GBP'),
  body('orderId')
    .isAlphanumeric()
    .withMessage('Valid order ID is required'),
  body('paymentMethodId')
    .optional()
    .isAlphanumeric()
    .withMessage('Valid payment method ID required'),
  handleValidationErrors
];

// Avatar validation rules
const validateAvatarCreation = [
  body('name')
    .trim()
    .isLength({ min: 1, max: 50 })
    .withMessage('Avatar name must be between 1 and 50 characters'),
  body('type')
    .optional()
    .isIn(['basic', 'detailed', 'custom'])
    .withMessage('Avatar type must be basic, detailed, or custom'),
  body('preferences')
    .optional()
    .isObject()
    .withMessage('Preferences must be an object'),
  handleValidationErrors
];

// Generic ID validation
const validateId = [
  param('id')
    .isAlphanumeric()
    .withMessage('Valid ID is required'),
  handleValidationErrors
];

// Pagination validation
const validatePagination = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  handleValidationErrors
];

// File upload validation
const validateFileUpload = [
  body('file')
    .custom((value, { req }) => {
      if (!req.file) {
        throw new Error('File is required');
      }
      
      const allowedTypes = ['.jpg', '.jpeg', '.png', '.glb', '.gltf', '.fbx'];
      const fileExt = path.extname(req.file.originalname).toLowerCase();
      
      if (!allowedTypes.includes(fileExt)) {
        throw new Error(`File type not allowed. Allowed types: ${allowedTypes.join(', ')}`);
      }
      
      const maxSize = 50 * 1024 * 1024; // 50MB
      if (req.file.size > maxSize) {
        throw new Error('File size too large. Maximum size is 50MB');
      }
      
      return true;
    }),
  handleValidationErrors
];

module.exports = {
  handleValidationErrors,
  validateUserRegistration,
  validateUserLogin,
  validateUserUpdate,
  validateProductQuery,
  validateProductId,
  validateAddToCart,
  validateScanStart,
  validateScanStatus,
  validateCreateOrder,
  validatePaymentIntent,
  validateAvatarCreation,
  validateId,
  validatePagination,
  validateFileUpload
};