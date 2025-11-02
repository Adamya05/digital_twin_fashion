const express = require('express');
const router = express.Router();

const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockCloset } = require('../utils/mockData');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

// Get user's closet
router.get('/', authenticate, async (req, res) => {
  try {
    const { page = 1, limit = 12 } = req.query;
    
    const result = await db.findMany('closetItems', 
      { userId: req.user.id },
      {
        sort: { field: 'createdAt', order: 'desc' },
        pagination: { page: parseInt(page), limit: parseInt(limit) }
      }
    );

    // Transform closet items for response
    const closetItems = result.data.map(closet => ({
      id: closet.id,
      name: closet.name,
      totalItems: closet.totalItems,
      isPublic: closet.isPublic,
      tags: closet.tags,
      previewImage: closet.items[0]?.imageUrl || null,
      createdAt: closet.createdAt,
      updatedAt: closet.updatedAt
    }));

    res.json({
      success: true,
      data: {
        closets: closetItems,
        pagination: {
          page: result.page,
          limit: result.limit,
          total: result.total,
          totalPages: result.totalPages
        }
      },
      message: 'Closet retrieved successfully'
    });
  } catch (error) {
    logger.error('Get closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_FETCH_FAILED',
        message: 'Failed to fetch closet'
      }
    });
  }
});

// Create new closet
router.post('/', authenticate, async (req, res) => {
  try {
    const { name, description, isPublic = false, tags = [] } = req.body;

    if (!name) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_NAME',
          message: 'Closet name is required'
        }
      });
    }

    // Create empty closet
    const closetData = {
      userId: req.user.id,
      name,
      description: description || '',
      items: [],
      totalItems: 0,
      isPublic,
      tags,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    const closet = await db.create('closetItems', closetData);

    logger.info('Closet created', { closetId: closet.id, userId: req.user.id });

    res.status(201).json({
      success: true,
      data: closet,
      message: 'Closet created successfully'
    });
  } catch (error) {
    logger.error('Create closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_CREATION_FAILED',
        message: 'Failed to create closet'
      }
    });
  }
});

// Get single closet
router.get('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Check access permissions
    const isOwner = closet.userId === req.user.id;
    const isPublic = closet.isPublic;

    if (!isOwner && !isPublic && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    res.json({
      success: true,
      data: closet,
      message: 'Closet retrieved successfully'
    });
  } catch (error) {
    logger.error('Get closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_FETCH_FAILED',
        message: 'Failed to fetch closet'
      }
    });
  }
});

// Update closet
router.patch('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, isPublic, tags } = req.body;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    const updates = {
      name: name || closet.name,
      description: description !== undefined ? description : closet.description,
      isPublic: isPublic !== undefined ? isPublic : closet.isPublic,
      tags: tags || closet.tags,
      updatedAt: new Date().toISOString()
    };

    const updatedCloset = await db.update('closetItems', id, updates);

    logger.info('Closet updated', { closetId: id, userId: req.user.id });

    res.json({
      success: true,
      data: updatedCloset,
      message: 'Closet updated successfully'
    });
  } catch (error) {
    logger.error('Update closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_UPDATE_FAILED',
        message: 'Failed to update closet'
      }
    });
  }
});

// Delete closet
router.delete('/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    await db.delete('closetItems', id);

    logger.info('Closet deleted', { closetId: id, userId: req.user.id });

    res.json({
      success: true,
      message: 'Closet deleted successfully'
    });
  } catch (error) {
    logger.error('Delete closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_DELETION_FAILED',
        message: 'Failed to delete closet'
      }
    });
  }
});

// Add item to closet
router.post('/:id/items', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { productId } = req.body;

    if (!productId) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'MISSING_PRODUCT_ID',
          message: 'Product ID is required'
        }
      });
    }

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    // Check if product already exists in closet
    const existingItem = closet.items.find(item => item.id === productId);
    if (existingItem) {
      return res.status(409).json({
        success: false,
        error: {
          code: 'PRODUCT_ALREADY_IN_CLOSET',
          message: 'Product is already in this closet'
        }
      });
    }

    // Add product to closet items
    const updatedItems = [...closet.items, { id: productId, addedAt: new Date().toISOString() }];
    const updatedCloset = await db.update('closetItems', id, {
      items: updatedItems,
      totalItems: updatedItems.length,
      updatedAt: new Date().toISOString()
    });

    logger.info('Item added to closet', { 
      closetId: id, 
      productId, 
      userId: req.user.id 
    });

    res.json({
      success: true,
      data: {
        id: updatedCloset.id,
        totalItems: updatedCloset.totalItems,
        items: updatedCloset.items
      },
      message: 'Item added to closet successfully'
    });
  } catch (error) {
    logger.error('Add item to closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'ADD_TO_CLOSET_FAILED',
        message: 'Failed to add item to closet'
      }
    });
  }
});

// Remove item from closet
router.delete('/:id/items/:productId', authenticate, async (req, res) => {
  try {
    const { id, productId } = req.params;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    // Remove product from closet items
    const updatedItems = closet.items.filter(item => item.id !== productId);
    const updatedCloset = await db.update('closetItems', id, {
      items: updatedItems,
      totalItems: updatedItems.length,
      updatedAt: new Date().toISOString()
    });

    logger.info('Item removed from closet', { 
      closetId: id, 
      productId, 
      userId: req.user.id 
    });

    res.json({
      success: true,
      data: {
        id: updatedCloset.id,
        totalItems: updatedCloset.totalItems,
        items: updatedCloset.items
      },
      message: 'Item removed from closet successfully'
    });
  } catch (error) {
    logger.error('Remove item from closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'REMOVE_FROM_CLOSET_FAILED',
        message: 'Failed to remove item from closet'
      }
    });
  }
});

// Get closet items with product details
router.get('/:id/items', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20, category, color, brand } = req.query;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Check access permissions
    const isOwner = closet.userId === req.user.id;
    const isPublic = closet.isPublic;

    if (!isOwner && !isPublic && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    // Get product details for items in closet
    const closetItemProducts = await Promise.all(
      closet.items.map(async (item) => {
        const product = await db.findById('products', item.id);
        if (!product) return null;
        
        // Apply filters
        if (category && product.category !== category) return null;
        if (color && !product.colors.includes(color)) return null;
        if (brand && product.brand !== brand) return null;
        
        return {
          ...product,
          addedAt: item.addedAt
        };
      })
    );

    // Filter out null products and apply pagination
    const validProducts = closetItemProducts.filter(product => product !== null);
    const start = (page - 1) * limit;
    const end = start + limit;
    const paginatedProducts = validProducts.slice(start, end);

    res.json({
      success: true,
      data: {
        closet: {
          id: closet.id,
          name: closet.name,
          totalItems: validProducts.length
        },
        items: paginatedProducts,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total: validProducts.length,
          totalPages: Math.ceil(validProducts.length / limit)
        },
        filters: {
          category,
          color,
          brand
        }
      },
      message: 'Closet items retrieved successfully'
    });
  } catch (error) {
    logger.error('Get closet items error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_ITEMS_FETCH_FAILED',
        message: 'Failed to fetch closet items'
      }
    });
  }
});

// Create outfit from closet
router.post('/:id/outfits', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, productIds, description } = req.body;

    if (!name || !Array.isArray(productIds) || productIds.length === 0) {
      return res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_PARAMETERS',
          message: 'Name and product IDs array are required'
        }
      });
    }

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    // Create outfit (in real implementation, save to database)
    const outfit = {
      id: uuidv4(),
      closetId: id,
      name,
      description: description || '',
      productIds,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    logger.info('Outfit created', { 
      outfitId: outfit.id, 
      closetId: id, 
      productCount: productIds.length,
      userId: req.user.id 
    });

    res.status(201).json({
      success: true,
      data: outfit,
      message: 'Outfit created successfully'
    });
  } catch (error) {
    logger.error('Create outfit error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'OUTFIT_CREATION_FAILED',
        message: 'Failed to create outfit'
      }
    });
  }
});

// Share closet
router.post('/:id/share', authenticate, async (req, res) => {
  try {
    const { id } = req.params;

    const closet = await db.findById('closetItems', id);
    if (!closet) {
      return res.status(404).json({
        success: false,
        error: {
          code: 'CLOSET_NOT_FOUND',
          message: 'Closet not found'
        }
      });
    }

    // Verify ownership
    if (closet.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
      return res.status(403).json({
        success: false,
        error: {
          code: 'ACCESS_DENIED',
          message: 'Access denied to this closet'
        }
      });
    }

    // Generate share link
    const shareToken = uuidv4();
    const shareUrl = `${req.protocol}://${req.get('host')}/api/closet/shared/${shareToken}`;

    // Update closet to make it shareable
    const updatedCloset = await db.update('closetItems', id, {
      isPublic: true,
      shareToken,
      sharedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    });

    logger.info('Closet shared', { closetId: id, userId: req.user.id });

    res.json({
      success: true,
      data: {
        shareUrl,
        shareToken,
        isPublic: true
      },
      message: 'Closet shared successfully'
    });
  } catch (error) {
    logger.error('Share closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CLOSET_SHARE_FAILED',
        message: 'Failed to share closet'
      }
    });
  }
});

// Get shared closet
router.get('/shared/:shareToken', async (req, res) => {
  try {
    const { shareToken } = req.params;

    // Mock shared closet (in real implementation, search by shareToken)
    const sharedCloset = generateMockCloset();
    sharedCloset.id = 'shared_' + shareToken;
    sharedCloset.isPublic = true;
    sharedCloset.shareToken = shareToken;

    res.json({
      success: true,
      data: {
        closet: sharedCloset,
        isShared: true
      },
      message: 'Shared closet retrieved successfully'
    });
  } catch (error) {
    logger.error('Get shared closet error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'SHARED_CLOSET_FETCH_FAILED',
        message: 'Failed to fetch shared closet'
      }
    });
  }
});

module.exports = router;