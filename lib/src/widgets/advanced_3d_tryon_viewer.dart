/// 3D Try-On Viewer Component
/// 
/// A comprehensive 3D viewer component that integrates model_viewer_plus with 
/// avatar-product composite rendering, user controls, and performance optimization
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/avatar_model.dart';
import '../../models/product_model.dart';
import '../../services/model_cache_service.dart';
import '../../services/model_loading_service.dart';
import '../../services/tryon_model_renderer.dart';

class Advanced3DTryOnViewer extends StatefulWidget {
  final Product product;
  final Avatar? avatar;
  final ModelQualityLevel initialQuality;
  final bool enableAutoRotate;
  final bool enableScreenshot;
  final bool enableFullscreen;
  final bool showControls;
  final Function(String)? onError;
  final Function()? onModelLoaded;
  final Function(double)? onQualityChanged;
  final Function(ScreenshotResult)? onScreenshotCaptured;
  
  const Advanced3DTryOnViewer({
    super.key,
    required this.product,
    this.avatar,
    this.initialQuality = ModelQualityLevel.medium,
    this.enableAutoRotate = true,
    this.enableScreenshot = true,
    this.enableFullscreen = true,
    this.showControls = true,
    this.onError,
    this.onModelLoaded,
    this.onQualityChanged,
    this.onScreenshotCaptured,
  });

  @override
  State<Advanced3DTryOnViewer> createState() => _Advanced3DTryOnViewerState();
}

class _Advanced3DTryOnViewerState extends State<Advanced3DTryOnViewer>
    with TickerProviderStateMixin {
  
  // Services
  late final ModelCacheService _cacheService;
  late final ModelLoadingService _modelLoadingService;
  late final TryOnModelRenderer _renderer;
  
  // Model viewer and rendering
  final GlobalKey _modelViewerKey = GlobalKey();
  final GlobalKey _viewerContainerKey = GlobalKey();
  Uint8List? _modelData;
  String? _modelUrl;
  String? _fallbackImageUrl;
  
  // State management
  bool _isLoading = true;
  bool _isModelLoaded = false;
  bool _hasError = false;
  String? _errorMessage;
  
  // User interaction
  bool _autoRotate = true;
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _isDragging = false;
  double _zoomLevel = 1.0;
  Offset? _lastPanPosition;
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _controlsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _controlsAnimation;
  
  // Performance tracking
  DateTime? _loadStartTime;
  ModelPerformanceMetrics? _performanceMetrics;
  
  // Quality management
  ModelQualityLevel _currentQuality;
  
  @override
  void initState() {
    super.initState();
    _currentQuality = widget.initialQuality;
    _loadStartTime = DateTime.now();
    
    _initializeServices();
    _initializeAnimations();
    _setupInteractionHandlers();
    _load3DModel();
  }
  
  @override
  void dispose() {
    _renderer.dispose();
    _fadeController.dispose();
    _controlsController.dispose();
    super.dispose();
  }
  
  // ==================== INITIALIZATION ====================
  
  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _cacheService = ModelCacheService(prefs);
    
    // Initialize model loading service
    // This would be set up with proper API service
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _controlsController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _controlsController.forward();
  }
  
  void _setupInteractionHandlers() {
    // Auto-hide controls after inactivity
    _startControlTimer();
  }
  
  // ==================== MODEL LOADING ====================
  
  Future<void> _load3DModel() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
      
      final loadResult = await _modelLoadingService.loadTryOnModel(
        productId: widget.product.id,
        productName: widget.product.name,
        avatar: widget.avatar,
        quality: _currentQuality,
      );
      
      if (mounted) {
        if (loadResult.isSuccess) {
          setState(() {
            _modelData = loadResult.data;
            _modelUrl = loadResult.modelUrl;
            _isModelLoaded = true;
            _isLoading = false;
          });
          
          _trackPerformance(loadResult);
          widget.onModelLoaded?.call();
          _preloadRelatedModels();
          
        } else {
          _handleLoadError(loadResult.error ?? 'Failed to load 3D model');
        }
      }
      
    } catch (e) {
      _handleLoadError('Model loading failed: $e');
    }
  }
  
  void _handleLoadError(String error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error;
        _isLoading = false;
      });
      
      widget.onError?.call(error);
    }
  }
  
  void _trackPerformance(TryOnModelResult result) {
    final loadTime = DateTime.now().difference(_loadStartTime ?? DateTime.now());
    debugPrint('Model loaded in ${loadTime.inMilliseconds}ms with quality: ${_currentQuality.label}');
    
    // Update performance metrics
    widget.onQualityChanged?.call(_currentQuality.index.toDouble());
  }
  
  Future<void> _preloadRelatedModels() async {
    // Preload models for smoother transitions
    // Implementation would depend on recommendation system
  }
  
  // ==================== USER INTERACTIONS ====================
  
  void _handlePanStart(DragStartDetails details) {
    _lastPanPosition = details.globalPosition;
    _isDragging = true;
    _showControlsForDuration();
    setState(() {
      _autoRotate = false; // Disable auto-rotate during interaction
    });
  }
  
  void _handlePanUpdate(DragUpdateDetails details) {
    if (_lastPanPosition == null) return;
    
    final delta = details.globalPosition - _lastPanPosition!;
    _updateModelRotation(delta);
    _lastPanPosition = details.globalPosition;
  }
  
  void _handlePanEnd(DragEndDetails details) {
    _lastPanPosition = null;
    _isDragging = false;
    
    // Re-enable auto-rotate after interaction ends
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDragging) {
        setState(() {
          _autoRotate = widget.enableAutoRotate;
        });
      }
    });
  }
  
  void _handleScaleStart(ScaleStartDetails details) {
    _zoomLevel = 1.0;
    _showControlsForDuration();
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoomLevel = details.scale.clamp(0.5, 3.0);
    });
    
    _updateModelZoom(_zoomLevel);
  }
  
  void _handleScaleEnd(ScaleEndDetails details) {
    _showControlsForDuration();
  }
  
  void _updateModelRotation(Offset delta) {
    // Calculate rotation based on pan delta
    final rotationY = delta.dx * 0.5;
    final rotationX = delta.dy * 0.3;
    
    // Apply rotation to model through renderer
    _renderer.updateAvatarTransform(
      rotationY: rotationY,
      rotationX: rotationX,
    );
  }
  
  void _updateModelZoom(double zoom) {
    // Apply zoom through renderer
    _renderer.updateAvatarTransform(scaleFactor: zoom);
  }
  
  // ==================== CONTROLS ====================
  
  void _showControlsForDuration() {
    if (!mounted) return;
    
    setState(() {
      _showControls = true;
    });
    
    _startControlTimer();
  }
  
  void _startControlTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isDragging) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }
  
  void _resetCamera() {
    setState(() {
      _zoomLevel = 1.0;
      _autoRotate = widget.enableAutoRotate;
    });
    
    _renderer.resetToDefault();
    _showControlsForDuration();
  }
  
  void _toggleAutoRotate() {
    setState(() {
      _autoRotate = !_autoRotate;
    });
    _showControlsForDuration();
  }
  
  Future<void> _toggleFullscreen() async {
    if (!_isFullscreen) {
      // Enter fullscreen
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      // Exit fullscreen
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
    
    // Rebuild with new constraints
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  Future<void> _captureScreenshot() async {
    try {
      final permission = await Permission.storage.request();
      if (permission != PermissionStatus.granted) {
        widget.onError?.call('Storage permission required for screenshots');
        return;
      }
      
      final result = await _renderer.captureScreenshot(
        customFileName: 'tryon_${widget.product.id}_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (result.isSuccess) {
        widget.onScreenshotCaptured?.call(result);
        _showSuccess('Screenshot saved successfully!');
      } else {
        widget.onError?.call(result.error ?? 'Failed to capture screenshot');
      }
      
    } catch (e) {
      widget.onError?.call('Screenshot capture failed: $e');
    }
  }
  
  Future<void> _changeQuality(ModelQualityLevel newQuality) async {
    if (newQuality == _currentQuality) return;
    
    setState(() {
      _currentQuality = newQuality;
      _isLoading = true;
    });
    
    final result = await _renderer.switchQuality(newQuality);
    
    if (result.isSuccess) {
      _load3DModel();
    } else {
      widget.onError?.call(result.error ?? 'Failed to switch quality');
      setState(() {
        _currentQuality = _currentQuality; // Revert
        _isLoading = false;
      });
    }
  }
  
  // ==================== UI BUILDERS ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onPanStart: _handlePanStart,
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onScaleStart: _handleScaleStart,
          onScaleUpdate: _handleScaleUpdate,
          onScaleEnd: _handleScaleEnd,
          child: RepaintBoundary(
            key: _viewerContainerKey,
            child: Container(
              key: _viewerContainerKey,
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  // Main 3D viewer
                  _build3DViewer(),
                  
                  // Controls overlay
                  if (widget.showControls && _showControls)
                    _buildControlsOverlay(),
                  
                  // Loading overlay
                  if (_isLoading)
                    _buildLoadingOverlay(),
                  
                  // Error overlay
                  if (_hasError)
                    _buildErrorOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _build3DViewer() {
    if (_modelData != null || _modelUrl != null) {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: _buildModelViewer(),
      );
    } else if (_fallbackImageUrl != null) {
      return _buildFallback2DViewer();
    } else {
      return _buildPlaceholderViewer();
    }
  }
  
  Widget _buildModelViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: ModelViewer(
        key: _modelViewerKey,
        src: _getModelSource(),
        alt: '${widget.product.name} 3D Model',
        ar: false, // Disable AR for try-on
        autoRotate: _autoRotate,
        cameraControls: true,
        interactionPrompt: InteractionPrompt.automatic,
        shadowIntensity: 0.5,
        exposure: 1.0,
        environmentImage: 'https://modelviewer.dev/shared-assets/environments/spruit_sunrise_1k_HDR.hdr',
        loading: Loading.eager,
        reveal: Reveal.auto,
        animationName: 'Idle',
        animationCrossfadeDuration: 1000,
        cameraControlsTouchAction: PanZoomBehavior(),
        style: _getModelViewerStyle(),
        onModelLoaded: () {
          debugPrint('3D model loaded successfully');
          _isModelLoaded = true;
          widget.onModelLoaded?.call();
        },
        onModelLoadError: (error) {
          debugPrint('Model load error: $error');
          _handleLoadError('Model load error: $error');
        },
      ),
    );
  }
  
  Widget _buildFallback2DViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fallback 2D image
          Image.network(
            widget.product.fallback2DImage,
            fit: BoxFit.contain,
            loadingBuilder: (context, widget, loadingProgress) {
              if (loadingProgress == null) return widget!;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderViewer();
            },
          ),
          
          // 2D mode indicator
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '2D Mode - 3D model unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlaceholderViewer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar_off,
              size: 64,
              color: Colors.grey[600],
            ),
            SizedBox(height: 16),
            Text(
              '3D Model Not Available',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'This product doesn\'t have a 3D model available',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlsOverlay() {
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: Duration(milliseconds: 200),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Top controls
              Row(
                children: [
                  // Back button (if not in main app flow)
                  if (ModalRoute.of(context)?.canPop == true)
                    _buildControlButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                      tooltip: 'Back',
                    ),
                  
                  Spacer(),
                  
                  // Quality selector
                  _buildQualitySelector(),
                  
                  SizedBox(width: 8),
                  
                  // Screenshot button
                  if (widget.enableScreenshot)
                    _buildControlButton(
                      icon: Icons.camera_alt,
                      onTap: _captureScreenshot,
                      tooltip: 'Screenshot',
                    ),
                ],
              ),
              
              Spacer(),
              
              // Bottom controls
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh,
                      onTap: _resetCamera,
                      tooltip: 'Reset View',
                    ),
                    _buildControlButton(
                      icon: _autoRotate ? Icons.play_arrow : Icons.pause,
                      onTap: _toggleAutoRotate,
                      tooltip: _autoRotate ? 'Stop Rotation' : 'Start Rotation',
                    ),
                    if (widget.enableFullscreen)
                      _buildControlButton(
                        icon: Icons.fullscreen,
                        onTap: _toggleFullscreen,
                        tooltip: 'Fullscreen',
                      ),
                    _buildControlButton(
                      icon: Icons.replay,
                      onTap: _load3DModel,
                      tooltip: 'Reload Model',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQualitySelector() {
    return PopupMenuButton<ModelQualityLevel>(
      tooltip: 'Quality Settings',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              color: Colors.white,
              size: 18,
            ),
            SizedBox(width: 4),
            Text(
              _currentQuality.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      onSelected: _changeQuality,
      itemBuilder: (context) => ModelQualityLevel.values.map((quality) {
        return PopupMenuItem<ModelQualityLevel>(
          value: quality,
          child: Row(
            children: [
              Icon(
                _getQualityIcon(quality),
                size: 18,
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quality.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    quality.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 24),
              Text(
                'Loading 3D Model...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${widget.product.name}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Quality: ${_currentQuality.label}',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildErrorOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Failed to Load 3D Model',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _load3DModel,
                      child: Text('Retry'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // ==================== UTILITY METHODS ====================
  
  String _getModelSource() {
    if (_modelData != null) {
      // In a real implementation, convert Uint8List to blob URL
      return 'data:model/gltf-binary;base64,mock_data';
    } else if (_modelUrl != null) {
      return _modelUrl!;
    }
    return '';
  }
  
  IconData _getQualityIcon(ModelQualityLevel quality) {
    switch (quality) {
      case ModelQualityLevel.low:
        return Icons.speed;
      case ModelQualityLevel.medium:
        return Icons.tune;
      case ModelQualityLevel.high:
        return Icons.grade;
    }
  }
  
  String _getModelViewerStyle() {
    return '''
      model-viewer {
        width: 100%;
        height: 100%;
        background: transparent;
        --poster-color: #ffffff00;
      }
      
      model-viewer::part(default-progress-mask) {
        background-color: rgba(0, 0, 0, 0.7);
      }
      
      model-viewer::part(default-progress-bar) {
        background-color: rgba(255, 255, 255, 0.1);
      }
    ''';
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // ==================== ENHANCED TOUCH BEHAVIOR ====================
  
  /// Enhanced touch behavior for better user experience
  class PanZoomBehavior extends StatelessWidget {
    final Widget child;
    
    const PanZoomBehavior({super.key, required this.child});
    
    @override
    Widget build(BuildContext context) {
      return child;
    }
  }
}