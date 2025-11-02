const express = require('express');
const router = express.Router();

const { 
  validateUserUpdate, 
  validateId, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockUser } = require('../utils/mockData');
const logger = require('../utils/logger');

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
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
        preferences: user.preferences || {},
        avatar: user.avatar,
        isVerified: user.isVerified || false,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin
      },
      message: 'Profile retrieved successfully'
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

// Update user profile
router.patch('/profile', 
  authenticate,
  validateUserUpdate,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { name, phone, preferences } = req.body;
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

      const updates = {
        name,
        phone,
        preferences: { ...user.preferences, ...preferences },
        updatedAt: new Date().toISOString()
      };

      // Remove undefined values
      Object.keys(updates).forEach(key => {
        if (updates[key] === undefined) {
          delete updates[key];
        }
      });

      const updatedUser = await db.update('users', user.id, updates);

      logger.info('Profile updated', { userId: user.id });

      res.json({
        success: true,
        data: {
          id: updatedUser.id,
          email: updatedUser.email,
          name: updatedUser.name,
          phone: updatedUser.phone,
          role: updatedUser.role,
          preferences: updatedUser.preferences || {},
          avatar: updatedUser.avatar,
          updatedAt: updatedUser.updatedAt
        },
        message: 'Profile updated successfully'
      });
    } catch (error) {
      logger.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PROFILE_UPDATE_FAILED',
          message: 'Failed to update profile'
        }
      });
    }
  }
);

// Upload user avatar
router.post('/avatar', authenticate, async (req, res) => {
  try {
    const { avatarUrl } = req.body;

    if (!avatarUrl) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_AVATAR_URL',
          message: 'Avatar URL is required'
        }
      });
    }

    const updatedUser = await db.update('users', req.user.id, {
      avatar: avatarUrl,
      updatedAt: new Date().toISOString()
    });

    logger.info('Avatar updated', { userId: req.user.id, avatarUrl });

    res.json({
      success: true,
      data: {
        id: updatedUser.id,
        avatar: updatedUser.avatar
      },
      message: 'Avatar updated successfully'
    });
  } catch (error) {
    logger.error('Update avatar error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'AVATAR_UPDATE_FAILED',
        message: 'Failed to update avatar'
      }
    });
  }
});

// Delete user account
router.delete('/account', authenticate, async (req, res) => {
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

    // In a real application, you would:
    // 1. Soft delete the user (mark as deleted)
    // 2. Anonymize sensitive data
    // 3. Keep some data for legal/compliance reasons

    await db.delete('users', user.id);

    logger.info('User account deleted', { userId: user.id });

    res.json({
      success: true,
      message: 'Account deleted successfully'
    });
  } catch (error) {
    logger.error('Delete account error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'ACCOUNT_DELETION_FAILED',
        message: 'Failed to delete account'
      }
    });
  }
});

// Get user statistics
router.get('/stats', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;

    // Get user data
    const user = await db.findById('users', userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'USER_NOT_FOUND',
          message: 'User not found'
        }
      });
    }

    // Get user's orders
    const ordersResult = await db.findMany('orders', { userId });
    const orders = ordersResult.data;

    // Get user's carts
    const cartsResult = await db.findMany('carts', { userId });
    const carts = cartsResult.data;

    // Get user's avatars
    const avatarsResult = await db.findMany('avatars', { userId });
    const avatars = avatarsResult.data;

    // Get user's closet items
    const closetResult = await db.findMany('closetItems', { userId });
    const closetItems = closetResult.data;

    // Calculate statistics
    const totalOrders = orders.length;
    const totalSpent = orders
      .filter(order => order.status !== 'cancelled')
      .reduce((sum, order) => sum + order.finalAmount, 0);

    const averageOrderValue = totalOrders > 0 ? totalSpent / orders.filter(order => order.status !== 'cancelled').length : 0;
    const lastOrderDate = orders.length > 0 ? orders.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))[0].createdAt : null;

    // Calculate account age
    const accountAge = Math.floor((Date.now() - new Date(user.createdAt).getTime()) / (1000 * 60 * 60 * 24));

    // Most ordered categories
    const categoryCounts = {};
    orders.forEach(order => {
      order.items.forEach(item => {
        const category = item.product?.category || 'unknown';
        categoryCounts[category] = (categoryCounts[category] || 0) + item.quantity;
      });
    });

    const topCategories = Object.entries(categoryCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5);

    res.json({
      success: true,
      data: {
        account: {
          memberSince: user.createdAt,
          accountAgeDays: accountAge,
          isVerified: user.isVerified || false,
          lastLogin: user.lastLogin
        },
        orders: {
          totalOrders,
          totalSpent: Math.round(totalSpent * 100) / 100,
          averageOrderValue: Math.round(averageOrderValue * 100) / 100,
          lastOrderDate
        },
        preferences: {
          theme: user.preferences?.theme || 'light',
          language: user.preferences?.language || 'en',
          notifications: user.preferences?.notifications || true,
          size: user.preferences?.size || 'M'
        },
        assets: {
          totalAvatars: avatars.length,
          totalClosetItems: closetItems.reduce((sum, closet) => sum + closet.totalItems, 0),
          totalCartItems: carts.reduce((sum, cart) => sum + (cart.itemCount || 0), 0)
        },
        analytics: {
          topCategories: topCategories.map(([category, count]) => ({ category, count }))
        }
      },
      message: 'User statistics retrieved successfully'
    });
  } catch (error) {
    logger.error('Get user stats error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'USER_STATS_FETCH_FAILED',
        message: 'Failed to fetch user statistics'
      }
    });
  }
});

// Get user activity feed
router.get('/activity', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const { page = 1, limit = 20 } = req.query;

    const activities = [];

    // Get recent orders
    const ordersResult = await db.findMany('orders', { userId }, {
      sort: { field: 'createdAt', order: 'desc' },
      pagination: { page: 1, limit: 10 }
    });

    ordersResult.data.forEach(order => {
      activities.push({
        id: `order_${order.id}`,
        type: 'order',
        action: order.status === 'pending' ? 'Order Placed' : `Order ${order.status}`,
        description: `Order #${order.id.slice(-8)} for $${order.finalAmount}`,
        timestamp: order.createdAt,
        metadata: {
          orderId: order.id,
          amount: order.finalAmount,
          status: order.status
        }
      });
    });

    // Get recent avatar scans
    const scansResult = await db.findMany('scanSessions', { userId }, {
      sort: { field: 'createdAt', order: 'desc' },
      pagination: { page: 1, limit: 5 }
    });

    scansResult.data.forEach(scan => {
      activities.push({
        id: `scan_${scan.id}`,
        type: 'scan',
        action: scan.status === 'completed' ? 'Avatar Created' : 'Avatar Scan',
        description: scan.status === 'completed' ? 'New avatar generated successfully' : 'Avatar scanning in progress',
        timestamp: scan.createdAt,
        metadata: {
          scanId: scan.id,
          status: scan.status,
          progress: scan.progress
        }
      });
    });

    // Sort all activities by timestamp
    activities.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

    // Apply pagination
    const start = (page - 1) * limit;
    const end = start + limit;
    const paginatedActivities = activities.slice(start, end);

    res.json({
      success: true,
      data: {
        activities: paginatedActivities,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: activities.length,
          totalPages: Math.ceil(activities.length / limit)
        }
      },
      message: 'User activity retrieved successfully'
    });
  } catch (error) {
    logger.error('Get user activity error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'USER_ACTIVITY_FETCH_FAILED',
        message: 'Failed to fetch user activity'
      }
    });
  }
});

// Update user preferences
router.patch('/preferences', authenticate, async (req, res) => {
  try {
    const { theme, language, notifications, size, privacy } = req.body;
    
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

    const updates = {
      preferences: {
        ...user.preferences,
        theme,
        language,
        notifications,
        size,
        privacy: { ...user.preferences?.privacy, ...privacy }
      },
      updatedAt: new Date().toISOString()
    };

    const updatedUser = await db.update('users', user.id, updates);

    logger.info('User preferences updated', { userId: user.id });

    res.json({
      success: true,
      data: {
        preferences: updatedUser.preferences
      },
      message: 'Preferences updated successfully'
    });
  } catch (error) {
    logger.error('Update preferences error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'PREFERENCES_UPDATE_FAILED',
        message: 'Failed to update preferences'
      }
    });
  }
});

module.exports = router;