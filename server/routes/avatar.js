const express = require('express');
const router = express.Router();

const { 
  validateAvatarCreation, 
  validateId, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockAvatar } = require('../utils/mockData');
const logger = require('../utils/logger');

// Get user's avatars
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 10 } = req.query;
    
    const result = await db.findMany('avatars', 
      { userId: req.user.id },
      {
        sort: { field: 'createdAt', order: 'desc' },
        pagination: { page: parseInt(page), limit: parseInt(limit) }
      }
    );

    res.json({
      success: true,
      data: {
        avatars: result.data,
        pagination: {
          page: result.page,
          limit: result.limit,
          total: result.total,
          totalPages: result.totalPages
        }
      },
      message: 'Avatars retrieved successfully'
    });
  } catch (error) {
    logger.error('Get avatars error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'AVATARS_FETCH_FAILED',
        message: 'Failed to fetch avatars'
      }
    });
  }
});

// Create new avatar
router.post('/', 
  authenticate,
  validateAvatarCreation,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { name, type = 'basic', preferences = {} } = req.body;

      // Create avatar
      const avatarData = {
        userId: req.user.id,
        name,
        type,
        preferences,
        status: 'pending',
        progress: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      const avatar = await db.create('avatars', avatarData);

      // Simulate avatar processing
      setTimeout(async () => {
        try {
          await db.update('avatars', avatar.id, {
            status: 'processing',
            progress: 25,
            updatedAt: new Date().toISOString()
          });

          setTimeout(async () => {
            try {
              await db.update('avatars', avatar.id, {
                status: 'completed',
                progress: 100,
                imageUrl: `https://randomuser.me/api/portraits/${Math.random() > 0.5 ? 'men' : 'women'}/${Math.floor(Math.random() * 100)}.jpg`,
                modelUrl: `/models/avatar_${Math.floor(Math.random() * 20)}.glb`,
                updatedAt: new Date().toISOString()
              });
            } catch (err) {
              logger.error('Avatar completion error:', err);
            }
          }, 3000);
        } catch (err) {
          logger.error('Avatar processing error:', err);
        }
      }, 2000);

      logger.info('Avatar created', { avatarId: avatar.id, userId: req.user.id });

      res.status(201).json({
        success: true,
        data: avatar,
        message: 'Avatar created successfully'
      });
    } catch (error) {
      logger.error('Create avatar error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'AVATAR_CREATION_FAILED',
          message: 'Failed to create avatar'
        }
      });
    }
  }
);

// Get single avatar
router.get('/:id', 
  authenticate,
  validateId,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { id } = req.params;

      const avatar = await db.findById('avatars', id);
      if (!avatar) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'AVATAR_NOT_FOUND',
            message: 'Avatar not found'
          }
        });
      }

      // Verify user ownership
      if (avatar.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this avatar'
          }
        });
      }

      res.json({
        success: true,
        data: avatar,
        message: 'Avatar retrieved successfully'
      });
    } catch (error) {
      logger.error('Get avatar error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'AVATAR_FETCH_FAILED',
          message: 'Failed to fetch avatar'
        }
      });
    }
  }
);

// Update avatar
router.patch('/:id', 
  authenticate,
  validateId,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { name, preferences } = req.body;

      const avatar = await db.findById('avatars', id);
      if (!avatar) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'AVATAR_NOT_FOUND',
            message: 'Avatar not found'
          }
        });
      }

      // Verify user ownership
      if (avatar.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this avatar'
          }
        });
      }

      const updates = {
        name: name || avatar.name,
        preferences: { ...avatar.preferences, ...preferences },
        updatedAt: new Date().toISOString()
      };

      const updatedAvatar = await db.update('avatars', id, updates);

      logger.info('Avatar updated', { avatarId: id, userId: req.user.id });

      res.json({
        success: true,
        data: updatedAvatar,
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
  }
);

// Delete avatar
router.delete('/:id', 
  authenticate,
  validateId,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { id } = req.params;

      const avatar = await db.findById('avatars', id);
      if (!avatar) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'AVATAR_NOT_FOUND',
            message: 'Avatar not found'
          }
        });
      }

      // Verify user ownership
      if (avatar.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this avatar'
          }
        });
      }

      await db.delete('avatars', id);

      logger.info('Avatar deleted', { avatarId: id, userId: req.user.id });

      res.json({
        success: true,
        message: 'Avatar deleted successfully'
      });
    } catch (error) {
      logger.error('Delete avatar error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'AVATAR_DELETION_FAILED',
          message: 'Failed to delete avatar'
        }
      });
    }
  }
);

// Get avatar templates
router.get('/templates/list', async (req, res) => {
  try {
    // Mock avatar templates
    const templates = [
      {
        id: 'template_1',
        name: 'Athletic Male',
        type: 'basic',
        imageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
        description: 'Athletic build, 6ft tall',
        measurements: {
          height: 183,
          weight: 80,
          chest: 102,
          waist: 84,
          hips: 98
        }
      },
      {
        id: 'template_2',
        name: 'Casual Female',
        type: 'basic',
        imageUrl: 'https://randomuser.me/api/portraits/women/1.jpg',
        description: 'Regular build, 5ft 6in tall',
        measurements: {
          height: 168,
          weight: 65,
          chest: 88,
          waist: 70,
          hips: 96
        }
      },
      {
        id: 'template_3',
        name: 'Business Professional',
        type: 'detailed',
        imageUrl: 'https://randomuser.me/api/portraits/men/2.jpg',
        description: 'Professional attire focused avatar',
        measurements: {
          height: 175,
          weight: 75,
          chest: 96,
          waist: 80,
          hips: 95
        }
      }
    ];

    res.json({
      success: true,
      data: { templates },
      message: 'Avatar templates retrieved successfully'
    });
  } catch (error) {
    logger.error('Get avatar templates error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'AVATAR_TEMPLATES_FETCH_FAILED',
        message: 'Failed to fetch avatar templates'
      }
    });
  }
});

// Duplicate avatar
router.post('/:id/duplicate', 
  authenticate,
  validateId,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { id } = req.params;
      const { name } = req.body;

      const originalAvatar = await db.findById('avatars', id);
      if (!originalAvatar) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'AVATAR_NOT_FOUND',
            message: 'Avatar not found'
          }
        });
      }

      // Verify user ownership
      if (originalAvatar.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this avatar'
          }
        });
      }

      // Create duplicate
      const duplicateData = {
        ...originalAvatar,
        id: undefined, // Remove original ID
        userId: req.user.id,
        name: name || `${originalAvatar.name} (Copy)`,
        status: 'pending',
        progress: 0,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      const duplicate = await db.create('avatars', duplicateData);

      logger.info('Avatar duplicated', { 
        originalId: id, 
        duplicateId: duplicate.id, 
        userId: req.user.id 
      });

      res.status(201).json({
        success: true,
        data: duplicate,
        message: 'Avatar duplicated successfully'
      });
    } catch (error) {
      logger.error('Duplicate avatar error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'AVATAR_DUPLICATION_FAILED',
          message: 'Failed to duplicate avatar'
        }
      });
    }
  }
);

module.exports = router;