const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');

const { 
  validateUserRegistration, 
  validateUserLogin, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate, generateMockToken } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockUser, hashPassword, comparePassword } = require('../utils/mockData');
const logger = require('../utils/logger');

// Mock password hashing for demo purposes
const mockUsers = new Map();

// Register new user
router.post('/register', validateUserRegistration, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: errors.array()
        }
      });
    }

    const { email, password, name, phone } = req.body;

    // Check if user already exists
    const existingUser = await db.findOne('users', { email });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'USER_ALREADY_EXISTS',
          message: 'User with this email already exists'
        }
      });
    }

    // Create new user
    const userData = {
      id: uuidv4(),
      email,
      name,
      phone,
      password: await hashPassword(password), // In mock server, this is just for demonstration
      role: 'user',
      isVerified: false,
      lastLogin: null
    };

    const user = await db.create('users', userData);

    // Generate token
    const token = generateMockToken(user);

    logger.info('User registered successfully', { userId: user.id, email: user.email });

    res.status(201).json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role
        },
        token,
        expiresIn: process.env.JWT_EXPIRES_IN || '7d'
      },
      message: 'User registered successfully'
    });
  } catch (error) {
    logger.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'REGISTRATION_FAILED',
        message: 'Failed to register user'
      }
    });
  }
});

// Login user
router.post('/login', validateUserLogin, async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Validation failed',
          details: errors.array()
        }
      });
    }

    const { email, password } = req.body;

    // Find user
    const user = await db.findOne('users', { email });
    if (!user) {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      });
    }

    // For mock server, accept any password (in production, validate password)
    const isPasswordValid = await comparePassword(password, user.password);
    if (!isPasswordValid && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(401).json({
        success: false,
        error: {
          code: 'INVALID_CREDENTIALS',
          message: 'Invalid email or password'
        }
      });
    }

    // Update last login
    await db.update('users', user.id, { lastLogin: new Date().toISOString() });

    // Generate token
    const token = generateMockToken(user);

    logger.info('User logged in successfully', { userId: user.id, email: user.email });

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          lastLogin: user.lastLogin
        },
        token,
        expiresIn: process.env.JWT_EXPIRES_IN || '7d'
      },
      message: 'Login successful'
    });
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'LOGIN_FAILED',
        message: 'Failed to login user'
      }
    });
  }
});

// Refresh token
router.post('/refresh', authenticate, async (req, res) => {
  try {
    const user = await db.findById('users', req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    // Generate new token
    const token = generateMockToken(user);

    res.json({
      success: true,
      data: {
        token,
        expiresIn: process.env.JWT_EXPIRES_IN || '7d'
      },
      message: 'Token refreshed successfully'
    });
  } catch (error) {
    logger.error('Token refresh error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'TOKEN_REFRESH_FAILED',
        message: 'Failed to refresh token'
      }
    });
  }
});

// Get current user profile
router.get('/profile', authenticate, async (req, res) => {
  try {
    const user = await db.findById('users', req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          name: user.name,
          phone: user.phone,
          role: user.role,
          preferences: user.preferences || {},
          avatar: user.avatar,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin
        }
      }
    });
  } catch (error) {
    logger.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'PROFILE_FETCH_FAILED',
        message: 'Failed to fetch user profile'
      }
    });
  }
});

// Logout user
router.post('/logout', authenticate, async (req, res) => {
  try {
    // In a real application, you might blacklist the token
    // For mock server, we just log the logout event
    
    logger.info('User logged out', { userId: req.user.id });

    res.json({
      success: true,
      message: 'Logout successful'
    });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'LOGOUT_FAILED',
        message: 'Failed to logout user'
      }
    });
  }
});

// Change password
router.post('/change-password', 
  authenticate,
  [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword')
      .isLength({ min: 6 })
      .withMessage('New password must be at least 6 characters long')
      .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
      .withMessage('New password must contain at least one lowercase letter, one uppercase letter, and one number'),
    handleValidationErrors
  ],
  async (req, res) => {
    try {
      const { currentPassword, newPassword } = req.body;

      const user = await db.findById('users', req.user.id);
      if (!user) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'USER_NOT_FOUND',
            message: 'User not found'
          }
        });
      }

      // For mock server, accept any current password (in production, validate)
      const isCurrentPasswordValid = await comparePassword(currentPassword, user.password);
      if (!isCurrentPasswordValid && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_CURRENT_PASSWORD',
            message: 'Current password is incorrect'
          }
        });
      }

      // Update password
      await db.update('users', user.id, {
        password: await hashPassword(newPassword),
        updatedAt: new Date().toISOString()
      });

      logger.info('Password changed successfully', { userId: user.id });

      res.json({
        success: true,
        message: 'Password changed successfully'
      });
    } catch (error) {
      logger.error('Change password error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PASSWORD_CHANGE_FAILED',
          message: 'Failed to change password'
        }
      });
    }
  }
);

// Mock login for demo/testing
router.post('/mock-login', async (req, res) => {
  try {
    const { userId } = req.body;
    
    // Generate mock user
    const mockUser = generateMockUser(userId);
    await db.create('users', mockUser);
    
    // Generate token
    const token = generateMockToken(mockUser);

    logger.info('Mock login successful', { userId: mockUser.id });

    res.json({
      success: true,
      data: {
        user: {
          id: mockUser.id,
          email: mockUser.email,
          name: mockUser.name,
          role: mockUser.role
        },
        token,
        expiresIn: process.env.JWT_EXPIRES_IN || '7d'
      },
      message: 'Mock login successful'
    });
  } catch (error) {
    logger.error('Mock login error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'MOCK_LOGIN_FAILED',
        message: 'Failed to perform mock login'
      }
    });
  }
});

module.exports = router;