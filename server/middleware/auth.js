const jwt = require('jsonwebtoken');
const { generateMockUser } = require('../utils/mockData');
const logger = require('../utils/logger');

// JWT Authentication middleware
const authenticate = async (req, res, next) => {
  try {
    let token;

    // Check for token in Authorization header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    } else if (req.headers['x-auth-token']) {
      // Check for token in custom header
      token = req.headers['x-auth-token'];
    } else if (req.cookies?.token) {
      // Check for token in cookies
      token = req.cookies.token;
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'NO_TOKEN',
          message: 'Access denied. No token provided.'
        }
      });
    }

    // Verify token
    let decoded;
    try {
      // For mock server, accept any valid JWT format or create a mock user
      decoded = jwt.verify(token, process.env.JWT_SECRET || 'mock-secret');
    } catch (jwtError) {
      // If JWT verification fails in mock mode, create a mock user
      if (process.env.ENABLE_MOCK_AUTH === 'true') {
        logger.info('JWT verification failed, creating mock user');
        decoded = {
          id: token.substring(0, 8),
          email: 'mock@example.com',
          name: 'Mock User'
        };
      } else {
        throw jwtError;
      }
    }

    // Generate or retrieve mock user
    const mockUser = generateMockUser(decoded.id);
    
    // Add user to request object
    req.user = {
      id: decoded.id || mockUser.id,
      email: decoded.email || mockUser.email,
      name: decoded.name || mockUser.name,
      role: decoded.role || 'user',
      isMock: true
    };

    next();
  } catch (error) {
    logger.error('Authentication error:', error);
    
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_TOKEN',
          message: 'Invalid token provided.'
        }
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        error: {
          code: 'TOKEN_EXPIRED',
          message: 'Token has expired.'
        }
      });
    }

    res.status(500).json({
      success: false,
      error: {
        code: 'AUTHENTICATION_ERROR',
        message: 'Authentication failed.'
      }
    });
  }
};

// Optional authentication - doesn't fail if no token provided
const optionalAuth = async (req, res, next) => {
  try {
    await authenticate(req, res, () => {
      next();
    });
  } catch (error) {
    // If authentication fails in optional mode, continue without user
    next();
  }
};

// Admin authorization middleware
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      error: {
        code: 'NO_TOKEN',
        message: 'Access denied. Authentication required.'
      }
    });
  }

  if (req.user.role !== 'admin' && req.user.role !== 'super_admin') {
    return res.status(403).json({
      success: false,
      error: {
        code: 'INSUFFICIENT_PERMISSIONS',
        message: 'Access denied. Admin privileges required.'
      }
    });
  }

  next();
};

// Role-based authorization middleware
const requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'NO_TOKEN',
          message: 'Access denied. Authentication required.'
        }
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: {
          code: 'INSUFFICIENT_PERMISSIONS',
          message: `Access denied. Required roles: ${roles.join(', ')}`
        }
      });
    }

    next();
  };
};

// Generate mock JWT token
const generateMockToken = (user) => {
  const payload = {
    id: user.id,
    email: user.email,
    name: user.name,
    role: user.role || 'user'
  };

  return jwt.sign(payload, process.env.JWT_SECRET || 'mock-secret', {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d'
  });
};

// Refresh token middleware
const refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'NO_REFRESH_TOKEN',
          message: 'Refresh token required.'
        }
      });
    }

    // For mock server, accept any refresh token and generate new tokens
    const user = generateMockUser('mock_user_1');
    const newToken = generateMockToken(user);
    const newRefreshToken = generateMockToken({ ...user, type: 'refresh' });

    res.json({
      success: true,
      data: {
        token: newToken,
        refreshToken: newRefreshToken,
        expiresIn: process.env.JWT_EXPIRES_IN || '7d'
      }
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(401).json({
      success: false,
      error: {
        code: 'TOKEN_REFRESH_FAILED',
        message: 'Failed to refresh token.'
      }
    });
  }
};

module.exports = {
  authenticate,
  optionalAuth,
  requireAdmin,
  requireRole,
  generateMockToken,
  refreshToken
};