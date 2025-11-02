import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fullscreen/fullscreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../providers/model_provider.dart';
import '../services/model_service.dart';

/// Advanced Avatar Canvas with full feature set
/// Integrates with ModelService and Riverpod for state management
class AdvancedAvatarCanvas extends ConsumerStatefulWidget {
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
  
  /// Show controls overlay
  final bool showControls;
  
  /// Auto-hide controls after inactivity
  final bool autoHideControls;
  
  /// Screenshot callback
  final Function(Uint8List screenshot)? onScreenshot;

  const AdvancedAvatarCanvas({
    Key? key,
    required this.modelUrl,
    this.posterImage,
    this.autoRotate = true,
    this.rotationSpeed = 30.0,
    this.enableTouchControls = true,
    this.backgroundColor,
    this.height = 400,
    this.width,
    this.onLoadingStart,
    this.onLoadingComplete,
    this.onError,
    this.onModelClicked,
    this.showControls = true,
    this.autoHideControls = true,
    this.onScreenshot,
  }) : super(key: key);

  @override
  ConsumerState<AdvancedAvatarCanvas> createState() => _AdvancedAvatarCanvasState();
}

class _AdvancedAvatarCanvasState extends ConsumerState<AdvancedAvatarCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isInFullscreen = false;
  bool _showControls = true;
  String? _currentModelPath;
  late GlobalKey _modelViewerKey;
  
  // Control overlay visibility timer
  Timer? _controlTimer;
  
  // Model service
  late ModelService _modelService;

  @override
  void initState() {
    super.initState();
    _modelService = ref.read(modelServiceProvider);
    _modelViewerKey = GlobalKey();
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_animationController);
    
    // Initialize auto-rotation
    _updateAutoRotation();
    
    // Load model on init
    _loadModel();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controlTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(AdvancedAvatarCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.modelUrl != widget.modelUrl ||
        oldWidget.autoRotate != widget.autoRotate) {
      _loadModel();
      _updateAutoRotation();
    }
  }

  Future<void> _loadModel() async {
    if (widget.modelUrl.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    widget.onLoadingStart?.call();

    try {
      final result = await ref.read(modelLoadingStateProvider.notifier).loadModel(
        modelUrl: widget.modelUrl,
        quality: ref.read(modelQualitySettingsProvider),
      );

      if (result.isSuccess) {
        setState(() {
          _currentModelPath = result.filePath;
          _isLoading = false;
        });
        widget.onLoadingComplete?.call();
      } else {
        setState(() {
          _isLoading = false;
        });
        widget.onError?.call(result.error?.message ?? 'Failed to load model');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      widget.onError?.call('Model loading error: $e');
    }
  }

  void _updateAutoRotation() {
    final autoRotateEnabled = ref.read(autoRotateSettingsProvider)[widget.modelUrl] ?? widget.autoRotate;
    
    if (autoRotateEnabled) {
      _animationController.repeat();
    } else {
      _animationController.stop();
    }
  }

  void _resetControlsTimer() {
    if (!widget.autoHideControls) return;
    
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
    final loadState = ref.watch(modelLoadingStateProvider).getLoadState(widget.modelUrl);
    final isLoading = loadState == ModelLoadState.loading;
    final hasError = loadState == ModelLoadState.error;
    
    return Container(
      height: widget.height,
      width: widget.width ?? double.infinity,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // 3D Model Viewer or Error State
            if (hasError) _buildErrorState()
            else _buildModelViewer(),
            
            // Loading overlay
            if (isLoading || _isLoading) _buildLoadingOverlay(),
            
            // Control overlay
            if (widget.showControls && _showControls && !hasError) _buildControlOverlay(),
            
            // Touch feedback overlay
            _buildTouchOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildModelViewer() {
    final modelPath = _currentModelPath ?? widget.modelUrl;
    
    return ModelViewer(
      key: _modelViewerKey,
      src: modelPath,
      poster: widget.posterImage,
      alt: "3D Avatar",
      ar: false,
      auto-rotate: ref.read(autoRotateSettingsProvider)[widget.modelUrl] ?? widget.autoRotate,
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
        
        // Record interaction for analytics
        ref.read(modelInteractionsProvider.notifier).recordInteraction(widget.modelUrl);
      },
      onClick: (event, node, scene) {
        widget.onModelClicked?.call();
        
        // Show controls temporarily
        setState(() {
          _showControls = true;
        });
        _resetControlsTimer();
      },
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Model',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadModel,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading 3D Model...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
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
            icon: _getAutoRotateIcon(),
            label: _getAutoRotateLabel(),
            onPressed: _toggleAutoRotate,
          ),
          const SizedBox(width: 8),
          _buildControlButton(
            icon: Icons.info_outline,
            label: 'Model Info',
            onPressed: _showModelInfo,
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
        onTap: () {
          // Record interaction
          ref.read(modelInteractionsProvider.notifier).recordInteraction(widget.modelUrl);
        },
        child: Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  Future<void> _toggleFullscreen() async {
    try {
      final isFullscreen = ref.read(fullscreenStateProvider);
      
      if (isFullscreen) {
        await FullScreen.exitFullScreen();
        ref.read(fullscreenStateProvider.notifier).exitFullscreen();
      } else {
        await FullScreen.enterFullScreen();
        ref.read(fullscreenStateProvider.notifier).enterFullscreen();
      }
    } catch (e) {
      widget.onError?.call('Fullscreen error: $e');
    }
  }

  void _resetModel() {
    // Reset model viewer by recreating the key
    setState(() {
      _modelViewerKey = GlobalKey();
      _loadModel();
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
          
          // Save to gallery
          await _saveScreenshot(pngBytes);
          
          // Notify callback
          widget.onScreenshot?.call(pngBytes);
          
          // Store last screenshot
          ref.read(lastScreenshotProvider.notifier).setLastScreenshot('screenshot_${DateTime.now().millisecondsSinceEpoch}.png');
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
    ref.read(autoRotateSettingsProvider.notifier).toggleAutoRotate(widget.modelUrl);
    _updateAutoRotation();
  }

  IconData _getAutoRotateIcon() {
    final autoRotateEnabled = ref.read(autoRotateSettingsProvider)[widget.modelUrl] ?? widget.autoRotate;
    return autoRotateEnabled ? Icons.pause : Icons.play_arrow;
  }

  String _getAutoRotateLabel() {
    final autoRotateEnabled = ref.read(autoRotateSettingsProvider)[widget.modelUrl] ?? widget.autoRotate;
    return autoRotateEnabled ? 'Pause Rotation' : 'Start Rotation';
  }

  void _showModelInfo() {
    final cacheStats = ref.read(cacheStatsProvider);
    final lastInteraction = ref.read(modelInteractionsProvider).getLastInteraction(widget.modelUrl);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Model Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Model URL', widget.modelUrl),
            _buildInfoRow('Cache Status', _getCacheStatus()),
            _buildInfoRow('Total Cached Models', '${cacheStats.cachedModels}'),
            _buildInfoRow('Cache Size', cacheStats.formattedCacheSize),
            if (lastInteraction != null)
              _buildInfoRow('Last Interaction', _formatDateTime(lastInteraction)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  String _getCacheStatus() {
    final loadState = ref.read(modelLoadingStateProvider).getLoadState(widget.modelUrl);
    switch (loadState) {
      case ModelLoadState.cached:
        return 'Cached';
      case ModelLoadState.loaded:
        return 'Loaded';
      case ModelLoadState.loading:
        return 'Loading';
      case ModelLoadState.error:
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}