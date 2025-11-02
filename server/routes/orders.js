const express = require('express');
const router = express.Router();
const { body } = require('express-validator');

const { 
  validateCreateOrder, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockOrder } = require('../utils/mockData');
const { v4: uuidv4 } = require('uuid');
const logger = require('../utils/logger');

// Create new order
router.post('/', 
  authenticate,
  validateCreateOrder,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { items, shippingAddress, paymentMethodId, notes } = req.body;

      // Get user's cart
      const cart = await db.findOne('carts', { userId: req.user.id });
      if (!cart || cart.items.length === 0) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'EMPTY_CART',
            message: 'Cart is empty'
          }
        });
      }

      // Validate items
      const validatedItems = [];
      let totalAmount = 0;

      for (const cartItem of items) {
        const product = await db.findById('products', cartItem.productId);
        if (!product || !product.isAvailable) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'PRODUCT_UNAVAILABLE',
              message: `Product ${cartItem.productId} is not available`
            }
          });
        }

        if (product.stock < cartItem.quantity) {
          return res.status(400).json({
            success: false,
            error: {
              code: 'INSUFFICIENT_STOCK',
              message: `Insufficient stock for product ${cartItem.productId}`
            }
          });
        }

        const itemTotal = product.price * cartItem.quantity;
        totalAmount += itemTotal;

        validatedItems.push({
          ...cartItem,
          product: {
            id: product.id,
            name: product.name,
            price: product.price,
            imageUrl: product.imageUrl,
            brand: product.brand,
            category: product.category,
            size: cartItem.size || 'M',
            color: cartItem.color || 'Black'
          }
        });
      }

      // Calculate totals
      const shippingCost = totalAmount > 100 ? 0 : 9.99; // Free shipping over $100
      const tax = totalAmount * 0.08; // 8% tax
      const finalAmount = totalAmount + shippingCost + tax;

      // Create order
      const orderData = {
        id: uuidv4(),
        userId: req.user.id,
        items: validatedItems,
        totalAmount,
        shippingCost,
        tax,
        finalAmount,
        currency: 'USD',
        status: 'pending',
        paymentStatus: 'pending',
        shippingAddress: {
          street: shippingAddress.street,
          city: shippingAddress.city,
          state: shippingAddress.state,
          zipCode: shippingAddress.zipCode,
          country: shippingAddress.country || 'United States'
        },
        paymentMethod: paymentMethodId ? { id: paymentMethodId } : null,
        notes: notes || null,
        trackingNumber: null,
        estimatedDelivery: null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      const order = await db.create('orders', orderData);

      // Update product stock
      for (const item of validatedItems) {
        const product = await db.findById('products', item.productId);
        await db.update('products', item.productId, {
          stock: product.stock - item.quantity,
          updatedAt: new Date().toISOString()
        });
      }

      // Clear user's cart after successful order creation
      await db.update('carts', cart.id, {
        items: [],
        total: 0,
        itemCount: 0,
        updatedAt: new Date().toISOString()
      });

      logger.info('Order created', { 
        orderId: order.id, 
        userId: req.user.id, 
        amount: finalAmount,
        itemCount: validatedItems.length
      });

      res.status(201).json({
        success: true,
        data: order,
        message: 'Order created successfully'
      });
    } catch (error) {
      logger.error('Create order error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDER_CREATION_FAILED',
          message: 'Failed to create order'
        }
      });
    }
  }
);

// Get user's orders
router.get('/', 
  authenticate,
  async (req, res) => {
    try {
      const { page = 1, limit = 10, status } = req.query;
      
      const criteria = { userId: req.user.id };
      if (status) {
        criteria.status = status;
      }

      const result = await db.findMany('orders', criteria, {
        sort: { field: 'createdAt', order: 'desc' },
        pagination: { 
          page: parseInt(page), 
          limit: parseInt(limit) 
        }
      });

      logger.info('Orders retrieved', { 
        userId: req.user.id, 
        count: result.data.length,
        page: parseInt(page) 
      });

      res.json({
        success: true,
        data: {
          orders: result.data,
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: result.totalPages,
            hasNextPage: result.page < result.totalPages,
            hasPrevPage: result.page > 1
          }
        },
        message: 'Orders retrieved successfully'
      });
    } catch (error) {
      logger.error('Get orders error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDERS_FETCH_FAILED',
          message: 'Failed to fetch orders'
        }
      });
    }
  }
);

// Get single order
router.get('/:orderId', 
  authenticate,
  async (req, res) => {
    try {
      const { orderId } = req.params;

      const order = await db.findById('orders', orderId);
      if (!order) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'ORDER_NOT_FOUND',
            message: 'Order not found'
          }
        });
      }

      // Verify user ownership
      if (order.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this order'
          }
        });
      }

      logger.info('Order retrieved', { orderId, userId: req.user.id });

      res.json({
        success: true,
        data: order,
        message: 'Order retrieved successfully'
      });
    } catch (error) {
      logger.error('Get order error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDER_FETCH_FAILED',
          message: 'Failed to fetch order'
        }
      });
    }
  }
);

// Update order status (admin only)
router.patch('/:orderId/status', 
  authenticate,
  async (req, res) => {
    try {
      const { orderId } = req.params;
      const { status, trackingNumber } = req.body;

      // Check if user is admin
      if (req.user.role !== 'admin' && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'INSUFFICIENT_PERMISSIONS',
            message: 'Admin access required'
          }
        });
      }

      const order = await db.findById('orders', orderId);
      if (!order) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'ORDER_NOT_FOUND',
            message: 'Order not found'
          }
        });
      }

      const updates = {
        status,
        updatedAt: new Date().toISOString()
      };

      // Add tracking number if provided
      if (trackingNumber) {
        updates.trackingNumber = trackingNumber;
        
        // Calculate estimated delivery if order is being shipped
        if (status === 'shipped') {
          const estimatedDelivery = new Date();
          estimatedDelivery.setDate(estimatedDelivery.getDate() + 7); // 7 days delivery
          updates.estimatedDelivery = estimatedDelivery.toISOString();
        }
      }

      const updatedOrder = await db.update('orders', orderId, updates);

      logger.info('Order status updated', { 
        orderId, 
        status, 
        trackingNumber,
        updatedBy: req.user.id 
      });

      res.json({
        success: true,
        data: updatedOrder,
        message: 'Order status updated successfully'
      });
    } catch (error) {
      logger.error('Update order status error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDER_STATUS_UPDATE_FAILED',
          message: 'Failed to update order status'
        }
      });
    }
  }
);

// Cancel order
router.patch('/:orderId/cancel', 
  authenticate,
  async (req, res) => {
    try {
      const { orderId } = req.params;
      const { reason } = req.body;

      const order = await db.findById('orders', orderId);
      if (!order) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'ORDER_NOT_FOUND',
            message: 'Order not found'
          }
        });
      }

      // Verify user ownership
      if (order.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this order'
          }
        });
      }

      // Check if order can be cancelled
      if (['shipped', 'delivered', 'cancelled'].includes(order.status)) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'ORDER_CANNOT_BE_CANCELLED',
            message: `Order in status '${order.status}' cannot be cancelled`
          }
        });
      }

      // Update order status
      const updatedOrder = await db.update('orders', orderId, {
        status: 'cancelled',
        cancellationReason: reason || 'Cancelled by user',
        cancelledAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });

      // Restore product stock
      for (const item of order.items) {
        const product = await db.findById('products', item.productId);
        if (product) {
          await db.update('products', item.productId, {
            stock: product.stock + item.quantity,
            updatedAt: new Date().toISOString()
          });
        }
      }

      logger.info('Order cancelled', { 
        orderId, 
        userId: req.user.id, 
        reason: reason || 'Cancelled by user'
      });

      res.json({
        success: true,
        data: updatedOrder,
        message: 'Order cancelled successfully'
      });
    } catch (error) {
      logger.error('Cancel order error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDER_CANCELLATION_FAILED',
          message: 'Failed to cancel order'
        }
      });
    }
  }
);

// Get order statistics
router.get('/stats/overview', 
  authenticate,
  async (req, res) => {
    try {
      const userId = req.user.id;
      
      // Get all user orders
      const result = await db.findMany('orders', { userId });
      
      const orders = result.data;
      const totalOrders = orders.length;
      const totalSpent = orders
        .filter(order => order.status !== 'cancelled')
        .reduce((sum, order) => sum + order.finalAmount, 0);
      
      // Status distribution
      const statusDistribution = orders.reduce((acc, order) => {
        acc[order.status] = (acc[order.status] || 0) + 1;
        return acc;
      }, {});

      // Recent orders (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const recentOrders = orders.filter(order => 
        new Date(order.createdAt) >= thirtyDaysAgo
      );

      // Average order value
      const averageOrderValue = totalOrders > 0 ? totalSpent / orders.filter(order => order.status !== 'cancelled').length : 0;

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

      logger.info('Order stats retrieved', { userId, totalOrders });

      res.json({
        success: true,
        data: {
          totalOrders,
          totalSpent: Math.round(totalSpent * 100) / 100,
          averageOrderValue: Math.round(averageOrderValue * 100) / 100,
          statusDistribution,
          recentOrdersCount: recentOrders.length,
          topCategories: topCategories.map(([category, count]) => ({ category, count }))
        },
        message: 'Order statistics retrieved successfully'
      });
    } catch (error) {
      logger.error('Get order stats error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'ORDER_STATS_FETCH_FAILED',
          message: 'Failed to fetch order statistics'
        }
      });
    }
  }
);

// Request order return
router.post('/:orderId/return', 
  authenticate,
  async (req, res) => {
    try {
      const { orderId } = req.params;
      const { items, reason, comments } = req.body;

      const order = await db.findById('orders', orderId);
      if (!order) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'ORDER_NOT_FOUND',
            message: 'Order not found'
          }
        });
      }

      // Verify user ownership
      if (order.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this order'
          }
        });
      }

      // Check if order can be returned
      if (order.status !== 'delivered') {
        return res.status(400).json({
          success: false,
          error: {
            code: 'ORDER_CANNOT_BE_RETURNED',
            message: 'Only delivered orders can be returned'
          }
        });
      }

      // Create return request
      const returnRequest = {
        id: uuidv4(),
        orderId,
        userId: req.user.id,
        items: items || order.items.map(item => ({ productId: item.productId, quantity: item.quantity })),
        reason: reason || 'Not specified',
        comments: comments || null,
        status: 'pending',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      // In a real implementation, you would save this to a separate returns table
      // For now, we'll just log it and return a success response

      logger.info('Return request created', { 
        orderId, 
        userId: req.user.id,
        returnId: returnRequest.id
      });

      res.json({
        success: true,
        data: {
          returnRequestId: returnRequest.id,
          status: 'pending',
          message: 'Return request submitted successfully. You will receive a response within 2-3 business days.'
        },
        message: 'Return request submitted successfully'
      });
    } catch (error) {
      logger.error('Request return error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'RETURN_REQUEST_FAILED',
          message: 'Failed to submit return request'
        }
      });
    }
  }
);

module.exports = router;