const logger = require('../utils/logger');

// Global error handling middleware
const errorHandler = (err, req, res, next) => {
  let error = { ...err };
  error.message = err.message;

  // Log error
  logger.error('Error:', {
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });

  // Mongoose bad ObjectId
  if (err.name === 'CastError') {
    const message = 'Resource not found';
    error = { message, statusCode: 404 };
  }

  // Mongoose duplicate key
  if (err.code === 11000) {
    const message = 'Duplicate field value entered';
    error = { message, statusCode: 400 };
  }

  // Mongoose validation error
  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map(val => val.message).join(', ');
    error = { message, statusCode: 400 };
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError') {
    const message = 'Invalid token';
    error = { message, statusCode: 401 };
  }

  if (err.name === 'TokenExpiredError') {
    const message = 'Token expired';
    error = { message, statusCode: 401 };
  }

  // File upload errors
  if (err.code === 'LIMIT_FILE_SIZE') {
    const message = 'File too large';
    error = { message, statusCode: 413 };
  }

  if (err.code === 'LIMIT_FILE_COUNT') {
    const message = 'Too many files';
    error = { message, statusCode: 413 };
  }

  if (err.code === 'LIMIT_UNEXPECTED_FILE') {
    const message = 'Unexpected file field';
    error = { message, statusCode: 400 };
  }

  // Rate limiting errors
  if (err.type === 'RateLimitError') {
    const message = 'Too many requests';
    error = { message, statusCode: 429 };
  }

  // Validation errors
  if (err.type === 'ValidationError') {
    const message = err.message || 'Validation failed';
    error = { message, statusCode: 400 };
  }

  // Default to 500 server error
  const statusCode = error.statusCode || 500;
  const message = error.message || 'Internal Server Error';

  const errorResponse = {
    success: false,
    error: {
      code: getErrorCode(err),
      message,
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    }
  };

  // Add request ID if available
  if (req.id) {
    errorResponse.requestId = req.id;
  }

  res.status(statusCode).json(errorResponse);
};

// Helper function to get error code based on error type
const getErrorCode = (err) => {
  if (err.name === 'CastError') return 'RESOURCE_NOT_FOUND';
  if (err.code === 11000) return 'DUPLICATE_ENTRY';
  if (err.name === 'ValidationError') return 'VALIDATION_ERROR';
  if (err.name === 'JsonWebTokenError') return 'INVALID_TOKEN';
  if (err.name === 'TokenExpiredError') return 'TOKEN_EXPIRED';
  if (err.code === 'LIMIT_FILE_SIZE') return 'FILE_TOO_LARGE';
  if (err.code === 'LIMIT_FILE_COUNT') return 'TOO_MANY_FILES';
  if (err.code === 'LIMIT_UNEXPECTED_FILE') return 'UNEXPECTED_FILE';
  if (err.type === 'RateLimitError') return 'RATE_LIMIT_EXCEEDED';
  if (err.type === 'ValidationError') return 'VALIDATION_ERROR';
  
  return 'INTERNAL_SERVER_ERROR';
};

// 404 handler for unmatched routes
const notFound = (req, res, next) => {
  const error = new Error(`Not found - ${req.originalUrl}`);
  res.status(404);
  next(error);
};

module.exports = {
  errorHandler,
  notFound
};