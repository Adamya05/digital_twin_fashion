import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Custom avatar canvas widget with 3D model viewing capabilities
/// Provides interactive controls, auto-rotation, screenshot, and fullscreen functionality
class AvatarCanvas extends StatefulWidget {
  /// Model URL or file path
  final String modelUrl;
  
  /// Placeholder image URL or asset path
  final String? posterImage;
  
  /// Enable auto-rotation
  final bool autoRotate;
  
  /// Auto-rotation speed (degrees per second)
  final double rotationSpeed;
  
  /// Enable touch controls
  final bool enableTouchControls;
  
  /// Background color
  final Color? backgroundColor;
  
  /// Canvas height
  final double height;
  
  /// Canvas width (defaults to full width)
  final double? width;
  
  /// Loading callback
  final VoidCallback? onLoadingStart;
  
  /// Loading complete callback
  final VoidCallback? onLoadingComplete;
  
  /// Error callback
  final Function(String error)? onError;
  
  /// Model interaction callback
  final VoidCallback? onModelClicked;

  const AvatarCanvas({
    Key? key,
    required this.modelUrl,
    this.posterImage,
    this.autoRotate = true,
    this.rotationSpeed = 30.0,
    this.enableTouchControls = true,
    this.backgroundColor,
    this.height = 300,
    this.width,
    this.onLoadingStart,
    this.onLoadingComplete,
    this.onError,
    this.onModelClicked,
  }) : super(key: key);

  @override
  State<AvatarCanvas> createState() => _AvatarCanvasState();
}

class _AvatarCanvasState extends State<AvatarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;
  bool _isInFullscreen = false;
  bool _showControls = true;
  Offset? _lastPanPosition;
  late Animation<double> _fadeAnimation;

  // Model viewer controller
  late GlobalKey _modelViewerKey;
  
  // Control overlay visibility timer
  Timer? _controlTimer;

  @override
  void initState() {
    super.initState();
    _modelViewerKey = GlobalKey();
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    _startAutoRotation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controlTimer?.cancel();
    super.dispose();
  }

  void _startAutoRotation() {
    if (widget.autoRotate) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  void _resetControlsTimer() {
    _controlTimer?.cancel();
    _controlTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 3D Model Viewer
            _buildModelViewer(),
            
            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
            
            // Control overlay
            if (_showControls) _buildControlOverlay(),
            
            // Touch feedback overlay
            _buildTouchOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelViewer() {
    return ModelViewer(
      key: _modelViewerKey,
      src: widget.modelUrl,
      poster: widget.posterImage,
      alt: "3D Avatar",
      ar: false,
      auto-rotate: widget.autoRotate,
      auto-rotate-delay: 0,
      rotation-per-second: "${widget.rotationSpeed}deg",
      camera-controls: widget.enableTouchControls,
      interaction-prompt: "none",
      shadow-intensity: 0.5,
      exposure: 0.5,
      environment-image: "neutral.hdr",
      loading: Loading.lazy,
      scale: "0.5 0.5 0.5",
      onModelLoadStart: () {
        setState(() {
          _isLoading = true;
        });
        widget.onLoadingStart?.call();
      },
      onModelLoadComplete: () {
        setState(() {
          _isLoading = false;
        });
        widget.onLoadingComplete?.call();
      },
      onModelLoadError: (error) {
        setState(() {
          _isLoading = false;
        });
        widget.onError?.call(error.toString());
      },
      onClick: (event, node, scene) {
        widget.onModelClicked?.call();
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading 3D Model...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlOverlay() {
    return Positioned(
      top: 8,
      right: 8,
      bottom: 8,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left controls
          _buildControlButton(
            icon: Icons.fullscreen,
            label: 'Fullscreen',
            onPressed: _toggleFullscreen,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.refresh,
            label: 'Reset',
            onPressed: _resetModel,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.camera_alt,
            label: 'Screenshot',
            onPressed: _takeScreenshot,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: widget.autoRotate ? Icons.pause : Icons.play_arrow,
            label: widget.autoRotate ? 'Pause' : 'Auto Rotate',
            onPressed: _toggleAutoRotate,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: _showControls ? Icons.close : Icons.settings,
            label: _showControls ? 'Hide Controls' : 'Show Controls',
            onPressed: () {
              setState(() {
                _showControls = !_showControls;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            onPressed();
            _resetControlsTimer();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTouchOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTapDown: (details) {
          setState(() {
            _showControls = true;
          });
          _resetControlsTimer();
        },
        onVerticalDragStart: widget.enableTouchControls ? (details) {
          _resetControlsTimer();
        } : null,
        onVerticalDragUpdate: widget.enableTouchControls ? (details) {
          _resetControlsTimer();
        } : null,
        onHorizontalDragStart: widget.enableTouchControls ? (details) {
          _resetControlsTimer();
        } : null,
        onHorizontalDragUpdate: widget.enableTouchControls ? (details) {
          _resetControlsTimer();
        } : null,
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    try {
      if (_isInFullscreen) {
        await FullScreen.exitFullScreen();
      } else {
        await FullScreen.enterFullScreen();
        if (mounted) {
          setState(() {
            _isInFullscreen = true;
          });
        }
      }
      
      // Reset after exiting fullscreen
      if (_isInFullscreen) {
        _isInFullscreen = false;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      widget.onError?.call('Fullscreen error: $e');
    }
  }

  void _resetModel() {
    // Reset model viewer by recreating the key
    setState(() {
      _modelViewerKey = GlobalKey();
    });
  }

  Future<void> _takeScreenshot() async {
    try {
      // Wait a frame to ensure the model is rendered
      await Future.delayed(const Duration(milliseconds: 100));
      
      RenderRepaintBoundary? boundary = _modelViewerKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary != null) {
        final image = await boundary.toImage(
          pixelRatio: 2.0,
        );
        
        final byteData = await image.toByteData(format: ImageByteFormat.png);
        if (byteData != null) {
          final Uint8List pngBytes = byteData.buffer.asUint8List();
          
          // Save to gallery or share
          await _saveScreenshot(pngBytes);
        }
      }
    } catch (e) {
      widget.onError?.call('Screenshot failed: $e');
    }
  }

  Future<void> _saveScreenshot(Uint8List pngBytes) async {
    try {
      final picker = ImagePicker();
      await picker.saveImage(
        imageData: pngBytes,
        quality: 90,
        maxWidth: 1024,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot saved to gallery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      widget.onError?.call('Save failed: $e');
    }
  }

  void _toggleAutoRotate() {
    setState(() {
      // Toggle auto-rotate by updating the widget's autoRotate property
      // This is a simplified version - in a real implementation,
      // you'd want to manage this state properly
    });
    _startAutoRotation();
  }
}