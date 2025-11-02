const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

const { 
  validateScanStart, 
  validateScanStatus, 
  handleValidationErrors 
} = require('../middleware/validation');
const { authenticate } = require('../middleware/auth');
const { db } = require('../utils/database');
const { generateMockAvatar } = require('../utils/mockData');
const logger = require('../utils/logger');

// In-memory storage for scan sessions
const activeScans = new Map();

// Start new scan session
router.post('/start', 
  validateScanStart,
  handleValidationErrors,
  async (req, res) => {
    try {
      const { userId, method = 'camera', preferences = {} } = req.body;
      const user = req.user; // From authentication middleware

      // Check if user exists (for non-authenticated requests)
      let scanUser = user;
      if (!scanUser && process.env.ENABLE_MOCK_AUTH === 'true') {
        scanUser = { id: userId, email: 'mock@example.com', name: 'Mock User' };
      }

      // Create scan session
      const sessionId = uuidv4();
      const scanSession = {
        id: sessionId,
        userId: scanUser.id,
        status: 'pending',
        progress: 0,
        message: 'Initializing scan...',
        method,
        preferences,
        startTime: new Date().toISOString(),
        estimatedDuration: 30, // seconds
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      // Store in memory for quick access
      activeScans.set(sessionId, scanSession);
      
      // Save to database
      await db.create('scanSessions', scanSession);

      // Simulate scan progression
      simulateScanProgress(sessionId);

      logger.info('Scan session started', { sessionId, userId: scanUser.id, method });

      res.status(201).json({
        success: true,
        data: {
          sessionId,
          status: 'pending',
          message: 'Scan session created successfully',
          estimatedDuration: 30
        },
        message: 'Scan session started'
      });
    } catch (error) {
      logger.error('Start scan error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'SCAN_START_FAILED',
          message: 'Failed to start scan session'
        }
      });
    }
  }
);

// Get scan status
router.get('/status/:sessionId', 
  validateScanStatus,
  handleValidationErrors,
  authenticate,
  async (req, res) => {
    try {
      const { sessionId } = req.params;

      // Try to get from memory first
      let scanSession = activeScans.get(sessionId);
      
      if (!scanSession) {
        // Try to get from database
        scanSession = await db.findById('scanSessions', sessionId);
      }

      if (!scanSession) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'SCAN_SESSION_NOT_FOUND',
            message: 'Scan session not found'
          }
        });
      }

      // Verify user ownership (unless it's a public access or mock mode)
      if (req.user && scanSession.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this scan session'
          }
        });
      }

      // Clean up old completed scans
      if (scanSession.status === 'completed' || scanSession.status === 'error') {
        const age = Date.now() - new Date(scanSession.updatedAt).getTime();
        if (age > 24 * 60 * 60 * 1000) { // 24 hours
          activeScans.delete(sessionId);
        }
      }

      logger.info('Scan status retrieved', { sessionId, status: scanSession.status });

      res.json({
        success: true,
        data: {
          sessionId: scanSession.id,
          status: scanSession.status,
          progress: scanSession.progress,
          message: scanSession.message,
          method: scanSession.method,
          startTime: scanSession.startTime,
          endTime: scanSession.endTime,
          estimatedDuration: scanSession.estimatedDuration
        }
      });
    } catch (error) {
      logger.error('Get scan status error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'SCAN_STATUS_FAILED',
          message: 'Failed to get scan status'
        }
      });
    }
  }
);

// Get scan result
router.get('/result/:sessionId',
  validateScanStatus,
  handleValidationErrors,
  authenticate,
  async (req, res) => {
    try {
      const { sessionId } = req.params;

      // Try to get from memory first
      let scanSession = activeScans.get(sessionId);
      
      if (!scanSession) {
        // Try to get from database
        scanSession = await db.findById('scanSessions', sessionId);
      }

      if (!scanSession) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'SCAN_SESSION_NOT_FOUND',
            message: 'Scan session not found'
          }
        });
      }

      // Verify user ownership
      if (req.user && scanSession.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this scan session'
          }
        });
      }

      // Check if scan is still in progress
      if (scanSession.status === 'pending' || scanSession.status === 'processing') {
        return res.status(202).json({
          success: true,
          data: {
            status: 'processing',
            message: 'Avatar generation still in progress',
            progress: scanSession.progress
          },
          message: 'Scan still in progress'
        });
      }

      // Handle completed scans
      if (scanSession.status === 'completed') {
        if (!scanSession.avatarId) {
          // Create avatar from scan session
          const avatar = generateMockAvatar(null, scanSession.userId);
          avatar.id = `avatar_${sessionId}`;
          avatar.scanSessionId = sessionId;
          avatar.createdAt = scanSession.endTime || scanSession.updatedAt;
          
          // Save avatar to database
          await db.create('avatars', avatar);
          
          // Link avatar to scan session
          await db.update('scanSessions', sessionId, {
            avatarId: avatar.id,
            avatar
          });
          
          scanSession.avatar = avatar;
        }

        // Clean up from memory if old
        const age = Date.now() - new Date(scanSession.updatedAt).getTime();
        if (age > 24 * 60 * 60 * 1000) {
          activeScans.delete(sessionId);
        }

        logger.info('Scan result retrieved', { sessionId, avatarId: scanSession.avatar?.id });

        return res.json({
          success: true,
          data: scanSession.avatar,
          message: 'Avatar generated successfully'
        });
      }

      // Handle error state
      if (scanSession.status === 'error') {
        return res.status(500).json({
          success: false,
          error: {
            code: 'SCAN_FAILED',
            message: scanSession.error || 'Avatar generation failed',
            details: scanSession.errorDetails
          },
          message: 'Avatar generation failed'
        });
      }

      res.status(400).json({
        success: false,
        error: {
          code: 'INVALID_SCAN_STATUS',
          message: `Invalid scan status: ${scanSession.status}`
        }
      });
    } catch (error) {
      logger.error('Get scan result error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'SCAN_RESULT_FAILED',
          message: 'Failed to get scan result'
        }
      });
    }
  }
);

// Cancel scan session
router.delete('/:sessionId',
  validateScanStatus,
  handleValidationErrors,
  authenticate,
  async (req, res) => {
    try {
      const { sessionId } = req.params;

      // Try to get from memory first
      let scanSession = activeScans.get(sessionId);
      
      if (!scanSession) {
        scanSession = await db.findById('scanSessions', sessionId);
      }

      if (!scanSession) {
        return res.status(404).json({
          success: false,
          error: {
            code: 'SCAN_SESSION_NOT_FOUND',
            message: 'Scan session not found'
          }
        });
      }

      // Verify user ownership
      if (req.user && scanSession.userId !== req.user.id && process.env.ENABLE_MOCK_AUTH !== 'true') {
        return res.status(403).json({
          success: false,
          error: {
            code: 'ACCESS_DENIED',
            message: 'Access denied to this scan session'
          }
        });
      }

      // Update status to cancelled
      const updatedSession = await db.update('scanSessions', sessionId, {
        status: 'cancelled',
        endTime: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      });

      // Remove from active scans
      activeScans.delete(sessionId);

      logger.info('Scan session cancelled', { sessionId });

      res.json({
        success: true,
        data: {
          sessionId,
          status: 'cancelled',
          message: 'Scan session cancelled successfully'
        },
        message: 'Scan session cancelled'
      });
    } catch (error) {
      logger.error('Cancel scan error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'SCAN_CANCEL_FAILED',
          message: 'Failed to cancel scan session'
        }
      });
    }
  }
);

// Get user's scan history
router.get('/history', 
  authenticate,
  async (req, res) => {
    try {
      const { page = 1, limit = 10 } = req.query;
      
      const result = await db.findMany('scanSessions', 
        { userId: req.user.id },
        {
          sort: { field: 'createdAt', order: 'desc' },
          pagination: { page: parseInt(page), limit: parseInt(limit) }
        }
      );

      // Transform data for response
      const sessions = result.data.map(session => ({
        id: session.id,
        status: session.status,
        progress: session.progress,
        method: session.method,
        startTime: session.startTime,
        endTime: session.endTime,
        avatarId: session.avatarId,
        createdAt: session.createdAt
      }));

      res.json({
        success: true,
        data: {
          sessions,
          pagination: {
            page: result.page,
            limit: result.limit,
            total: result.total,
            totalPages: result.totalPages
          }
        }
      });
    } catch (error) {
      logger.error('Get scan history error:', error);
      res.status(500).json({
        success: false,
        error: {
          code: 'SCAN_HISTORY_FAILED',
          message: 'Failed to get scan history'
        }
      });
    }
  }
);

// Helper function to simulate scan progress
function simulateScanProgress(sessionId) {
  const steps = [
    { progress: 20, message: 'Processing images...', delay: 2000 },
    { progress: 40, message: 'Analyzing body measurements...', delay: 3000 },
    { progress: 60, message: 'Generating 3D model...', delay: 4000 },
    { progress: 80, message: 'Applying textures...', delay: 2000 },
    { progress: 100, message: 'Finalizing avatar...', delay: 1000 }
  ];

  let stepIndex = 0;

  const updateProgress = () => {
    if (stepIndex >= steps.length) {
      // Complete the scan
      completeScan(sessionId);
      return;
    }

    const step = steps[stepIndex];
    
    // Update session in memory
    const session = activeScans.get(sessionId);
    if (session) {
      session.progress = step.progress;
      session.message = step.message;
      session.status = step.progress === 100 ? 'completed' : 'processing';
      session.endTime = step.progress === 100 ? new Date().toISOString() : null;
      session.updatedAt = new Date().toISOString();

      // Update in database
      db.update('scanSessions', sessionId, session).catch(err => {
        logger.error('Failed to update scan session:', err);
      });
    }

    stepIndex++;
    setTimeout(updateProgress, step.delay);
  };

  // Start the progress simulation
  setTimeout(updateProgress, 1000);
}

// Helper function to complete scan
function completeScan(sessionId) {
  const session = activeScans.get(sessionId);
  if (session) {
    session.status = 'completed';
    session.progress = 100;
    session.message = 'Avatar generated successfully!';
    session.endTime = new Date().toISOString();
    session.updatedAt = new Date().toISOString();

    // Update in database
    db.update('scanSessions', sessionId, session).catch(err => {
      logger.error('Failed to update completed scan session:', err);
    });

    logger.info('Scan completed', { sessionId });
  }
}

module.exports = router;