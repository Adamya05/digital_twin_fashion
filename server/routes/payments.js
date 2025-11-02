const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

const { 
  validatePaymentIntent, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockPayment } = require('../utils/mockData');
const logger = require('../utils/logger');

// Create payment intent
router.post('/create-intent', 
  authenticate,
  validatePaymentIntent,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { amount, currency, orderId, paymentMethodId } = req.body;

      // Validate amount (minimum $0.50, maximum $10,000.00)
      if (amount < 50) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'MINIMUM_AMOUNT',
            message: 'Minimum payment amount is $0.50'
          }
        });
      }

      if (amount > 1000000) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'MAXIMUM_AMOUNT',
            message: 'Maximum payment amount is $10,000.00'
          }
        });
      }

      // Verify order exists and belongs to user
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

      if (order.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this order'
          }
        });
      }

      if (order.finalAmount !== amount / 100) { // Convert from cents
        return res.status(400).json({
          success: false,
          error: {
            code: 'AMOUNT_MISMATCH',
            message: 'Payment amount does not match order total'
          }
        });
      }

      // Create mock Razorpay payment intent
      const paymentId = uuidv4();
      const razorpayOrderId = `order_${Math.floor(Math.random() * 1000000)}`;
      
      const paymentIntent = {
        id: paymentId,
        razorpayOrderId,
        orderId,
        userId: req.user.id,
        amount,
        currency: currency || 'USD',
        status: 'created',
        paymentMethodId: paymentMethodId || null,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      // Save payment to database
      await db.create('payments', paymentIntent);

      // Generate client secret (for Razorpay integration)
      const clientSecret = `cs_${Math.random().toString(36).substr(2, 32)}`;

      logger.info('Payment intent created', { 
        paymentId, 
        orderId, 
        amount, 
        currency,
        userId: req.user.id 
      });

      res.json({
        success: true,
        data: {
          id: paymentId,
          razorpayOrderId,
          amount,
          currency: currency || 'USD',
          status: 'created',
          clientSecret,
          orderId,
          createdAt: paymentIntent.createdAt
        },
        message: 'Payment intent created successfully'
      });
    } catch (error) {
      logger.error('Create payment intent error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PAYMENT_INTENT_CREATION_FAILED',
          message: 'Failed to create payment intent'
        }
      });
    }
  }
);

// Confirm payment
router.post('/confirm', 
  authenticate,
  async (req, res) => {
    try {
      const { paymentId, razorpayPaymentId, razorpaySignature, paymentMethodId } = req.body;

      // Validate required fields
      if (!paymentId || !razorpayPaymentId) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'MISSING_FIELDS',
            message: 'Payment ID and Razorpay Payment ID are required'
          }
        });
      }

      // Get payment from database
      const payment = await db.findById('payments', paymentId);
      if (!payment) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PAYMENT_NOT_FOUND',
            message: 'Payment not found'
          }
        });
      }

      // Verify payment belongs to user
      if (payment.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this payment'
          }
        });
      }

      // Mock payment processing
      // In a real implementation, you would verify the Razorpay signature here
      const paymentSuccess = Math.random() > 0.1; // 90% success rate for mock

      if (paymentSuccess) {
        // Update payment status
        const updatedPayment = await db.update('payments', paymentId, {
          status: 'succeeded',
          razorpayPaymentId,
          razorpaySignature,
          paymentMethodId,
          processedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        });

        // Update order payment status
        await db.update('orders', payment.orderId, {
          paymentStatus: 'paid',
          paymentId,
          updatedAt: new Date().toISOString()
        });

        logger.info('Payment confirmed', { 
          paymentId, 
          orderId: payment.orderId,
          userId: req.user.id 
        });

        res.json({
          success: true,
          data: {
            paymentId,
            status: 'succeeded',
            orderId: payment.orderId,
            amount: payment.amount,
            currency: payment.currency,
            processedAt: updatedPayment.processedAt
          },
          message: 'Payment confirmed successfully'
        });
      } else {
        // Payment failed
        await db.update('payments', paymentId, {
          status: 'failed',
          razorpayPaymentId,
          failureReason: 'Payment declined by bank',
          updatedAt: new Date().toISOString()
        });

        // Update order payment status
        await db.update('orders', payment.orderId, {
          paymentStatus: 'failed',
          updatedAt: new Date().toISOString()
        });

        logger.info('Payment failed', { 
          paymentId, 
          orderId: payment.orderId,
          userId: req.user.id 
        });

        res.status(400).json({
          success: false,
          error: {
            code: 'PAYMENT_FAILED',
            message: 'Payment was declined by your bank. Please try a different payment method.'
          },
          details: {
            paymentId,
            status: 'failed'
          }
        });
      }
    } catch (error) {
      logger.error('Confirm payment error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PAYMENT_CONFIRMATION_FAILED',
          message: 'Failed to confirm payment'
        }
      });
    }
  }
);

// Get payment status
router.get('/:paymentId', 
  authenticate,
  async (req, res) => {
    try {
      const { paymentId } = req.params;

      const payment = await db.findById('payments', paymentId);
      if (!payment) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PAYMENT_NOT_FOUND',
            message: 'Payment not found'
          }
        });
      }

      // Verify user ownership
      if (payment.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this payment'
          }
        });
      }

      res.json({
        success: true,
        data: payment,
        message: 'Payment status retrieved successfully'
      });
    } catch (error) {
      logger.error('Get payment status error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PAYMENT_STATUS_FETCH_FAILED',
          message: 'Failed to fetch payment status'
        }
      });
    }
  }
);

// Get user's payment history
router.get('/', 
  authenticate,
  async (req, res) => {
    try {
      const { page = 1, limit = 10, status } = req.query;
      
      const criteria = { userId: req.user.id };
      if (status) {
        criteria.status = status;
      }

      const result = await db.findMany('payments', criteria, {
        sort: { field: 'createdAt', order: 'desc' },
        pagination: { 
          page: parseInt(page), 
          limit: parseInt(limit) 
        }
      });

      // Enrich with order information
      const payments = await Promise.all(
        result.data.map(async (payment) => {
          const order = await db.findById('orders', payment.orderId);
          return {
            ...payment,
            order: order ? {
              id: order.id,
              status: order.status,
              finalAmount: order.finalAmount,
              createdAt: order.createdAt
            } : null
          };
        })
      );

      res.json({
        success: true,
        data: {
          payments,
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: result.totalPages,
            hasNextPage: result.page < result.totalPages,
            hasPrevPage: result.page > 1
          }
        },
        message: 'Payment history retrieved successfully'
      });
    } catch (error) {
      logger.error('Get payment history error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PAYMENT_HISTORY_FETCH_FAILED',
          message: 'Failed to fetch payment history'
        }
      });
    }
  }
);

// Refund payment (admin only)
router.post('/:paymentId/refund', 
  authenticate,
  async (req, res) => {
    try {
      const { paymentId } = req.params;
      const { amount, reason } = req.body;

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

      const payment = await db.findById('payments', paymentId);
      if (!payment) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'PAYMENT_NOT_FOUND',
            message: 'Payment not found'
          }
        });
      }

      if (payment.status !== 'succeeded') {
        return res.status(400).json({
          success: false,
          error: {
            code: 'CANNOT_REFUND_UNPAID',
            message: 'Only successful payments can be refunded'
          }
        });
      }

      // Process refund
      const refundAmount = amount || payment.amount;
      const refundId = `refund_${Math.floor(Math.random() * 1000000)}`;

      await db.update('payments', paymentId, {
        status: 'refunded',
        refundAmount,
        refundId,
        refundReason: reason || 'Refund requested',
        refundedAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });

      // Update order status
      await db.update('orders', payment.orderId, {
        paymentStatus: 'refunded',
        updatedAt: new Date().toISOString()
      });

      logger.info('Payment refunded', { 
        paymentId, 
        refundAmount, 
        refundId,
        reason,
        refundedBy: req.user.id 
      });

      res.json({
        success: true,
        data: {
          paymentId,
          refundId,
          refundAmount,
          status: 'refunded',
          refundedAt: new Date().toISOString()
        },
        message: 'Payment refunded successfully'
      });
    } catch (error) {
      logger.error('Refund payment error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'PAYMENT_REFUND_FAILED',
          message: 'Failed to refund payment'
        }
      });
    }
  }
);

// Webhook endpoint for Razorpay
router.post('/webhook', async (req, res) => {
  try {
    const { event, payload } = req.body;

    // In a real implementation, you would verify the webhook signature here
    logger.info('Payment webhook received', { event, webhookType: 'razorpay' });

    switch (event) {
      case 'payment.captured':
        await handlePaymentCaptured(payload);
        break;
      case 'payment.failed':
        await handlePaymentFailed(payload);
        break;
      case 'refund.processed':
        await handleRefundProcessed(payload);
        break;
      default:
        logger.info('Unhandled webhook event', { event });
    }

    res.status(200).json({ status: 'OK' });
  } catch (error) {
    logger.error('Webhook processing error:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Webhook processing failed' 
    });
  }
});

// Helper functions for webhook handling
async function handlePaymentCaptured(payload) {
  try {
    const razorpayPaymentId = payload.payment?.entity?.id;
    
    if (razorpayPaymentId) {
      // Find payment by Razorpay payment ID
      const payment = await db.findOne('payments', { razorpayPaymentId });
      
      if (payment && payment.status === 'created') {
        await db.update('payments', payment.id, {
          status: 'succeeded',
          processedAt: new Date().toISOString(),
          updatedAt: new Date().toISOString()
        });

        await db.update('orders', payment.orderId, {
          paymentStatus: 'paid',
          updatedAt: new Date().toISOString()
        });

        logger.info('Payment captured via webhook', { paymentId: payment.id });
      }
    }
  } catch (error) {
    logger.error('Error handling payment captured:', error);
  }
}

async function handlePaymentFailed(payload) {
  try {
    const razorpayPaymentId = payload.payment?.entity?.id;
    
    if (razorpayPaymentId) {
      const payment = await db.findOne('payments', { razorpayPaymentId });
      
      if (payment && payment.status === 'created') {
        await db.update('payments', payment.id, {
          status: 'failed',
          failureReason: payload.payment?.entity?.failure_reason || 'Payment failed',
          updatedAt: new Date().toISOString()
        });

        await db.update('orders', payment.orderId, {
          paymentStatus: 'failed',
          updatedAt: new Date().toISOString()
        });

        logger.info('Payment failed via webhook', { paymentId: payment.id });
      }
    }
  } catch (error) {
    logger.error('Error handling payment failed:', error);
  }
}

async function handleRefundProcessed(payload) {
  try {
    const refundId = payload.refund?.entity?.id;
    // Handle refund processing
    logger.info('Refund processed via webhook', { refundId });
  } catch (error) {
    logger.error('Error handling refund processed:', error);
  }
}

module.exports = router;