const express = require('express');
const router = express.Router();

const { 
  validateAddToCart, 
  validateProductId, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockCart } = require('../utils/mockData');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

// Get user's cart
router.get('/', authenticate, async (req, res) => {
  try {
    let cart = await db.findOne('carts', { userId: req.user.id });
    
    // Create cart if it doesn't exist
    if (!cart) {
      cart = generateMockCart(req.user.id);
      await db.create('carts', cart);
    }

    // Enrich cart with product details
    const enrichedItems = await Promise.all(
      cart.items.map(async (item) => {
        const product = await db.findById('products', item.productId);
        return {
          ...item,
          product: product ? {
            id: product.id,
            name: product.name,
            price: product.price,
            imageUrl: product.imageUrl,
            brand: product.brand,
            category: product.category,
            isAvailable: product.isAvailable,
            stock: product.stock
          } : null
        };
      })
    );

    // Filter out items with missing products
    const validItems = enrichedItems.filter(item => item.product !== null);
    
    // Update cart if items were filtered out
    if (validItems.length !== cart.items.length) {
      await db.update('carts', cart.id, {
        items: validItems,
        itemCount: validItems.reduce((sum, item) => sum + item.quantity, 0),
        total: validItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0),
        updatedAt: new Date().toISOString()
      });
    }

    const updatedCart = await db.findById('carts', cart.id);

    logger.info('Cart retrieved', { userId: req.user.id, itemCount: validItems.length });

    res.json({
      success: true,
      data: {
        id: updatedCart.id,
        items: validItems,
        total: updatedCart.total,
        itemCount: updatedCart.itemCount,
        currency: 'USD',
        createdAt: updatedCart.createdAt,
        updatedAt: updatedCart.updatedAt
      },
      message: 'Cart retrieved successfully'
    });
  } catch (error) {
    logger.error('Get cart error:', error);
    res.status(500).json({
      success: false,
      error: {
        code: 'CART_FETCH_FAILED',
        message: 'Failed to fetch cart'
      }
    });
  }
});

// Add item to cart
router.post('/', 
  authenticate,
  validateAddToCart,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { productId, quantity, size, color } = req.body;

      // Check if product exists and is available
      const product = await db.findById('products', productId);
      if (!product) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PRODUCT_NOT_FOUND',
            message: 'Product not found'
          }
        });
      }

      if (!product.isAvailable) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'PRODUCT_UNAVAILABLE',
            message: 'Product is not available'
          }
        });
      }

      if (product.stock < quantity) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INSUFFICIENT_STOCK',
            message: `Only ${product.stock} items available in stock`
          }
        });
      }

      // Get or create cart
      let cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart) {
        cart = generateMockCart(req.user.id);
        await db.create('carts', cart);
      }

      // Check if item already exists in cart
      const existingItemIndex = cart.items.findIndex(item => 
        item.productId === productId && 
        item.size === size && 
        item.color === color
      );

      if (existingItemIndex !== -1) {
        // Update existing item
        const newQuantity = cart.items[existingItemIndex].quantity + quantity;
        
        if (newQuantity > product.stock) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'QUANTITY_EXCEEDS_STOCK',
              message: `Cannot add ${quantity} more items. Only ${product.stock - cart.items[existingItemIndex].quantity} more available.`
            }
          });
        }

        cart.items[existingItemIndex].quantity = newQuantity;
      } else {
        // Add new item
        const newItem = {
          id: uuidv4(),
          productId,
          quantity,
          size: size || (product.sizes && product.sizes[0]) || 'M',
          color: color || (product.colors && product.colors[0]) || 'Black',
          addedAt: new Date().toISOString()
        };
        cart.items.push(newItem);
      }

      // Recalculate totals
      const enrichedItems = await Promise.all(
        cart.items.map(async (item) => {
          const prod = await db.findById('products', item.productId);
          return {
            ...item,
            product: prod ? {
              id: prod.id,
              name: prod.name,
              price: prod.price,
              imageUrl: prod.imageUrl,
              brand: prod.brand,
              category: prod.category,
              isAvailable: prod.isAvailable,
              stock: prod.stock
            } : null
          };
        })
      );

      const validItems = enrichedItems.filter(item => item.product !== null);
      const total = validItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      const itemCount = validItems.reduce((sum, item) => sum + item.quantity, 0);

      // Update cart in database
      const updatedCart = await db.update('carts', cart.id, {
        items: validItems,
        total,
        itemCount,
        updatedAt: new Date().toISOString()
      });

      logger.info('Item added to cart', { 
        userId: req.user.id, 
        productId, 
        quantity, 
        cartId: cart.id 
      });

      res.json({
        success: true,
        data: {
          cart: {
            id: updatedCart.id,
            items: validItems,
            total,
            itemCount,
            currency: 'USD'
          },
          addedItem: {
            productId,
            quantity,
            size,
            color
          }
        },
        message: 'Item added to cart successfully'
      });
    } catch (error) {
      logger.error('Add to cart error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ADD_TO_CART_FAILED',
          message: 'Failed to add item to cart'
        }
      });
    }
  }
);

// Update cart item
router.put('/items/:itemId', 
  authenticate,
  async (req, res) => {
    try {
      const { itemId } = req.params;
      const { quantity, size, color } = req.body;

      // Get cart
      const cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'CART_NOT_FOUND',
            message: 'Cart not found'
          }
        });
      }

      // Find item in cart
      const itemIndex = cart.items.findIndex(item => item.id === itemId);
      if (itemIndex === -1) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'CART_ITEM_NOT_FOUND',
            message: 'Item not found in cart'
          }
        });
      }

      const cartItem = cart.items[itemIndex];
      
      // Update item
      if (quantity !== undefined) {
        if (quantity <= 0) {
          // Remove item if quantity is 0 or negative
          cart.items.splice(itemIndex, 1);
        } else {
          // Check stock availability
          const product = await db.findById('products', cartItem.productId);
          if (product && quantity > product.stock) {
            return res.status(400).json({
              success: false,
              error: {
                code: 'QUANTITY_EXCEEDS_STOCK',
                message: `Only ${product.stock} items available in stock`
              }
            });
          }
          cartItem.quantity = quantity;
        }
      }

      if (size !== undefined) {
        cartItem.size = size;
      }

      if (color !== undefined) {
        cartItem.color = color;
      }

      // Recalculate totals
      const enrichedItems = await Promise.all(
        cart.items.map(async (item) => {
          const product = await db.findById('products', item.productId);
          return {
            ...item,
            product: product ? {
              id: product.id,
              name: product.name,
              price: product.price,
              imageUrl: product.imageUrl,
              brand: product.brand,
              category: product.category,
              isAvailable: product.isAvailable,
              stock: product.stock
            } : null
          };
        })
      );

      const validItems = enrichedItems.filter(item => item.product !== null);
      const total = validItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      const itemCount = validItems.reduce((sum, item) => sum + item.quantity, 0);

      // Update cart in database
      const updatedCart = await db.update('carts', cart.id, {
        items: validItems,
        total,
        itemCount,
        updatedAt: new Date().toISOString()
      });

      logger.info('Cart item updated', { 
        userId: req.user.id, 
        itemId, 
        quantity, 
        cartId: cart.id 
      });

      res.json({
        success: true,
        data: {
          cart: {
            id: updatedCart.id,
            items: validItems,
            total,
            itemCount,
            currency: 'USD'
          }
        },
        message: 'Cart item updated successfully'
      });
    } catch (error) {
      logger.error('Update cart item error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'CART_ITEM_UPDATE_FAILED',
          message: 'Failed to update cart item'
        }
      });
    }
  }
);

// Remove item from cart
router.delete('/items/:itemId', 
  authenticate,
  async (req, res) => {
    try {
      const { itemId } = req.params;

      // Get cart
      const cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'CART_NOT_FOUND',
            message: 'Cart not found'
          }
        });
      }

      // Find and remove item
      const itemIndex = cart.items.findIndex(item => item.id === itemId);
      if (itemIndex === -1) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'CART_ITEM_NOT_FOUND',
            message: 'Item not found in cart'
          }
        });
      }

      cart.items.splice(itemIndex, 1);

      // Recalculate totals
      const enrichedItems = await Promise.all(
        cart.items.map(async (item) => {
          const product = await db.findById('products', item.productId);
          return {
            ...item,
            product: product ? {
              id: product.id,
              name: product.name,
              price: product.price,
              imageUrl: product.imageUrl,
              brand: product.brand,
              category: product.category,
              isAvailable: product.isAvailable,
              stock: product.stock
            } : null
          };
        })
      );

      const validItems = enrichedItems.filter(item => item.product !== null);
      const total = validItems.reduce((sum, item) => sum + (item.product.price * item.quantity), 0);
      const itemCount = validItems.reduce((sum, item) => sum + item.quantity, 0);

      // Update cart in database
      const updatedCart = await db.update('carts', cart.id, {
        items: validItems,
        total,
        itemCount,
        updatedAt: new Date().toISOString()
      });

      logger.info('Cart item removed', { 
        userId: req.user.id, 
        itemId, 
        cartId: cart.id 
      });

      res.json({
        success: true,
        data: {
          cart: {
            id: updatedCart.id,
            items: validItems,
            total,
            itemCount,
            currency: 'USD'
          }
        },
        message: 'Item removed from cart successfully'
      });
    } catch (error) {
      logger.error('Remove cart item error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'CART_ITEM_REMOVE_FAILED',
          message: 'Failed to remove cart item'
        }
      });
    }
  }
);

// Clear entire cart
router.delete('/', 
  authenticate,
  async (req, res) => {
    try {
      const cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'CART_NOT_FOUND',
            message: 'Cart not found'
          }
        });
      }

      // Clear cart
      const updatedCart = await db.update('carts', cart.id, {
        items: [],
        total: 0,
        itemCount: 0,
        updatedAt: new Date().toISOString()
      });

      logger.info('Cart cleared', { userId: req.user.id, cartId: cart.id });

      res.json({
        success: true,
        data: {
          cart: {
            id: updatedCart.id,
            items: [],
            total: 0,
            itemCount: 0,
            currency: 'USD'
          }
        },
        message: 'Cart cleared successfully'
      });
    } catch (error) {
      logger.error('Clear cart error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'CART_CLEAR_FAILED',
          message: 'Failed to clear cart'
        }
      });
    }
  }
);

// Apply coupon/discount
router.post('/apply-coupon', 
  authenticate,
  async (req, res) => {
    try {
      const { code } = req.body;

      // Mock coupon codes
      const validCoupons = {
        'SAVE10': { discount: 10, type: 'percentage', minAmount: 50 },
        'WELCOME20': { discount: 20, type: 'fixed', minAmount: 100 },
        'FREESHIP': { discount: 0, type: 'shipping', minAmount: 0 }
      };

      const coupon = validCoupons[code.toUpperCase()];
      if (!coupon) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'INVALID_COUPON',
            message: 'Invalid coupon code'
          }
        });
      }

      const cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart || cart.total < coupon.minAmount) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'COUPON_NOT_APPLICABLE',
            message: `Coupon requires minimum order of $${coupon.minAmount}`
          }
        });
      }

      // Calculate discount
      let discount = 0;
      if (coupon.type === 'percentage') {
        discount = (cart.total * coupon.discount) / 100;
      } else if (coupon.type === 'fixed') {
        discount = coupon.discount;
      }

      const discountedTotal = Math.max(0, cart.total - discount);

      logger.info('Coupon applied', { 
        userId: req.user.id, 
        code, 
        discount, 
        originalTotal: cart.total,
        newTotal: discountedTotal
      });

      res.json({
        success: true,
        data: {
          coupon: {
            code: code.toUpperCase(),
            discount,
            type: coupon.type,
            originalTotal: cart.total,
            discountedTotal,
            savings: discount
          }
        },
        message: 'Coupon applied successfully'
      });
    } catch (error) {
      logger.error('Apply coupon error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'COUPON_APPLICATION_FAILED',
          message: 'Failed to apply coupon'
        }
      });
    }
  }
);

module.exports = router;