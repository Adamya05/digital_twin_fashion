const winston = require('winston');
const path = require('path');
const fs = require('fs');

// Ensure logs directory exists
const logsDir = path.join(__dirname, '../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

// Define log format
const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

// Define log level colors
const logColors = {
  error: 'red',
  warn: 'yellow',
  info: 'cyan',
  debug: 'green'
};

winston.addColors(logColors);

// Create logger instance
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: logFormat,
  defaultMeta: { service: 'virtual-tryon-mock-server' },
  transports: [
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(logsDir, 'error.log'),
      level: 'error',
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      format: logFormat
    }),
    
    // File transport for all logs
    new winston.transports.File({
      filename: path.join(logsDir, 'combined.log'),
      maxsize: 5242880, // 5MB
      maxFiles: 5,
      format: logFormat
    })
  ],
  
  // Handle exceptions and rejections
  exceptionHandlers: [
    new winston.transports.File({
      filename: path.join(logsDir, 'exceptions.log')
    })
  ],
  
  rejectionHandlers: [
    new winston.transports.File({
      filename: path.join(logsDir, 'rejections.log')
    })
  ]
});

// Add console transport in development
if (process.env.NODE_ENV !== 'production') {
  logger.add(new winston.transports.Console({
    format: winston.format.combine(
      winston.format.colorize({ all: true }),
      winston.format.simple(),
      winston.format.printf(({ timestamp, level, message, service, ...meta }) => {
        const metaStr = Object.keys(meta).length ? JSON.stringify(meta, null, 2) : '';
        return `${timestamp} [${service}] ${level}: ${message} ${metaStr}`;
      })
    )
  }));
}

// API request logging middleware
const apiLogger = (req, res, next) => {
  const start = Date.now();
  
  // Log request
  logger.info('API Request', {
    method: req.method,
    url: req.url,
    ip: req.ip,
    userAgent: req.get('User-Agent'),
    contentLength: req.get('Content-Length'),
    requestId: req.id || 'unknown'
  });
  
  // Override res.end to log response
  const originalEnd = res.end;
  res.end = function(chunk, encoding) {
    const duration = Date.now() - start;
    
    logger.info('API Response', {
      method: req.method,
      url: req.url,
      statusCode: res.statusCode,
      duration: `${duration}ms`,
      contentLength: res.get('Content-Length'),
      requestId: req.id || 'unknown'
    });
    
    originalEnd.call(this, chunk, encoding);
  };
  
  next();
};

// Error logging middleware
const errorLogger = (error, req, res, next) => {
  logger.error('API Error', {
    error: {
      message: error.message,
      stack: error.stack,
      name: error.name,
      code: error.code
    },
    request: {
      method: req.method,
      url: req.url,
      ip: req.ip,
      userAgent: req.get('User-Agent'),
      body: req.body,
      params: req.params,
      query: req.query,
      requestId: req.id || 'unknown'
    }
  });
  
  next(error);
};

// Performance logging middleware
const performanceLogger = (req, res, next) => {
  const start = process.hrtime.bigint();
  
  res.on('finish', () => {
    const end = process.hrtime.bigint();
    const duration = Number(end - start) / 1000000; // Convert to milliseconds
    
    if (duration > 1000) { // Log slow requests (>1s)
      logger.warn('Slow Request', {
        method: req.method,
        url: req.url,
        duration: `${duration.toFixed(2)}ms`,
        statusCode: res.statusCode,
        requestId: req.id || 'unknown'
      });
    }
  });
  
  next();
};

// Custom logging methods
const logApiCall = (endpoint, method, duration, statusCode) => {
  logger.info('API Call', {
    endpoint,
    method,
    duration: `${duration}ms`,
    statusCode
  });
};

const logDatabaseOperation = (operation, table, duration, success) => {
  logger.info('Database Operation', {
    operation,
    table,
    duration: `${duration}ms`,
    success
  });
};

const logExternalApiCall = (api, method, duration, statusCode) => {
  logger.info('External API Call', {
    api,
    method,
    duration: `${duration}ms`,
    statusCode
  });
};

const logFileOperation = (operation, filename, size, duration) => {
  logger.info('File Operation', {
    operation,
    filename,
    size: `${size} bytes`,
    duration: `${duration}ms`
  });
};

const logSecurityEvent = (event, details) => {
  logger.warn('Security Event', {
    event,
    details,
    timestamp: new Date().toISOString()
  });
};

// Export logger and middleware
module.exports = {
  logger,
  apiLogger,
  errorLogger,
  performanceLogger,
  logApiCall,
  logDatabaseOperation,
  logExternalApiCall,
  logFileOperation,
  logSecurityEvent
};