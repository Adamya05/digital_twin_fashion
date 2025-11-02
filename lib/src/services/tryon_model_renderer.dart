import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../models/avatar_model.dart';
import '../../models/product_model.dart';

/// 3D Try-On Model Renderer
/// Handles the rendering of product 3D models on avatars with model_viewer_plus integration
class TryOnModelRenderer {
  static const MethodChannel _methodChannel = MethodChannel('tryon_renderer');
  
  final ModelViewer _modelViewer;
  final GlobalKey _viewerKey;
  
  // Rendering state
  bool _isModelLoaded = false;
  bool _isRendering = false;
  Uint8List? _modelData;
  String? _modelUrl;
  String? _fallbackImageUrl;
  
  // Performance tracking
  DateTime? _renderStartTime;
  int _modelLoadTime = 0;
  int _renderTime = 0;
  
  // Model parameters
  ModelQualityLevel _currentQuality = ModelQualityLevel.medium;
  double _scaleFactor = 1.0;
  double _rotationY = 0.0;
  double _rotationX = 0.0;
  double _positionX = 0.0;
  double _positionY = 0.0;
  double _positionZ = 0.0;
  
  // Callbacks
  final Function(String)? onModelLoadError;
  final Function()? onModelLoaded;
  final Function(double)? onQualityChanged;
  final Function(int)? onPerformanceMetric;
  
  TryOnModelRenderer({
    required this._modelViewer,
    required this._viewerKey,
    this.onModelLoadError,
    this.onModelLoaded,
    this.onQualityChanged,
    this.onPerformanceMetric,
  });
  
  // ==================== PUBLIC API ====================
  
  /// Load 3D model for try-on rendering
  Future<ModelLoadResult> loadModelForTryOn({
    required Product product,
    required Avatar avatar,
    ModelQualityLevel quality = ModelQualityLevel.medium,
    Map<String, dynamic>? renderParameters,
  }) async {
    if (_isRendering) {
      return ModelLoadResult.error('Model is already loading');
    }
    
    _renderStartTime = DateTime.now();
    _isRendering = true;
    
    try {
      // Update quality level
      _currentQuality = quality;
      
      // Prepare model data
      final modelResult = await _prepareModelData(product, avatar, quality);
      
      if (!modelResult.isSuccess) {
        _isRendering = false;
        return ModelLoadResult.error(modelResult.error ?? 'Failed to prepare model data');
      }
      
      // Configure model viewer
      await _configureModelViewer(product, avatar, modelResult);
      
      // Apply initial transformations
      await _applyInitialTransformations();
      
      // Start rendering process
      await _startRendering();
      
      _isModelLoaded = true;
      _isRendering = false;
      
      // Track performance
      _trackPerformance();
      
      return ModelLoadResult.success(
        loadTime: _modelLoadTime,
        renderTime: _renderTime,
        quality: quality,
      );
      
    } catch (e) {
      _isRendering = false;
      final error = 'Failed to load model: $e';
      onModelLoadError?.call(error);
      return ModelLoadResult.error(error);
    }
  }
  
  /// Update avatar pose/positioning
  Future<void> updateAvatarTransform({
    double? rotationY,
    double? rotationX,
    double? scaleFactor,
    double? positionX,
    double? positionY,
    double? positionZ,
  }) async {
    try {
      if (rotationY != null) _rotationY = rotationY;
      if (rotationX != null) _rotationX = rotationX;
      if (scaleFactor != null) _scaleFactor = scaleFactor;
      if (positionX != null) _positionX = positionX;
      if (positionY != null) _positionY = positionY;
      if (positionZ != null) _positionZ = positionZ;
      
      // Apply transformations to model viewer
      await _applyTransformations();
      
    } catch (e) {
      debugPrint('Failed to update avatar transforms: $e');
    }
  }
  
  /// Switch to different model quality
  Future<ModelLoadResult> switchQuality(ModelQualityLevel newQuality) async {
    if (newQuality == _currentQuality || !_isModelLoaded) {
      return ModelLoadResult.error('Cannot switch quality');
    }
    
    final previousQuality = _currentQuality;
    _currentQuality = newQuality;
    
    try {
      onQualityChanged?.call(newQuality.index.toDouble());
      
      // Reload model with new quality
      // This would typically involve re-fetching from the API with quality parameter
      
      return ModelLoadResult.success(
        loadTime: _modelLoadTime,
        renderTime: _renderTime,
        quality: newQuality,
      );
      
    } catch (e) {
      _currentQuality = previousQuality; // Revert on failure
      return ModelLoadResult.error('Failed to switch quality: $e');
    }
  }
  
  /// Capture screenshot of the 3D model
  Future<ScreenshotResult> captureScreenshot({
    String? customFileName,
    bool includeWatermark = true,
  }) async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (permission != PermissionStatus.granted) {
        return ScreenshotResult.error('Storage permission required');
      }
      
      // Capture using model viewer
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = customFileName ?? 'tryon_${timestamp}.png';
      final filePath = '${directory.path}/$fileName';
      
      // In a real implementation, this would use the model viewer's screenshot API
      // For now, simulate the screenshot capture
      await _simulateScreenshotCapture(filePath);
      
      return ScreenshotResult.success(
        filePath: filePath,
        fileName: fileName,
        fileSize: await _getFileSize(filePath),
      );
      
    } catch (e) {
      return ScreenshotResult.error('Failed to capture screenshot: $e');
    }
  }
  
  /// Reset model to default state
  Future<void> resetToDefault() async {
    try {
      _rotationY = 0.0;
      _rotationX = 0.0;
      _scaleFactor = 1.0;
      _positionX = 0.0;
      _positionY = 0.0;
      _positionZ = 0.0;
      
      await _applyTransformations();
      
    } catch (e) {
      debugPrint('Failed to reset model: $e');
    }
  }
  
  /// Get performance metrics
  ModelPerformanceMetrics getPerformanceMetrics() {
    return ModelPerformanceMetrics(
      isModelLoaded: _isModelLoaded,
      isRendering: _isRendering,
      loadTime: _modelLoadTime,
      renderTime: _renderTime,
      currentQuality: _currentQuality,
      scaleFactor: _scaleFactor,
      rotationY: _rotationY,
      rotationX: _rotationX,
    );
  }
  
  /// Dispose resources
  void dispose() {
    _modelData = null;
    _modelUrl = null;
    _fallbackImageUrl = null;
    _isModelLoaded = false;
    _isRendering = false;
  }
  
  // ==================== PRIVATE METHODS ====================
  
  Future<ModelPreparationResult> _prepareModelData(
    Product product,
    Avatar avatar,
    ModelQualityLevel quality,
  ) async {
    try {
      // Check if product has 3D model
      if (!product.has3DModel) {
        _fallbackImageUrl = product.fallback2DImage;
        return ModelPreparationResult.fallback2D(_fallbackImageUrl!);
      }
      
      // Get model URL based on quality
      final modelUrl = _getModelUrlForQuality(product, quality);
      
      // Fetch model data from API
      final modelData = await _fetchModelFromAPI(product.id, modelUrl);
      
      if (modelData == null) {
        return ModelPreparationResult.error('Failed to fetch model data');
      }
      
      return ModelPreparationResult.success(
        modelData: modelData,
        modelUrl: modelUrl,
        quality: quality,
      );
      
    } catch (e) {
      return ModelPreparationResult.error('Model preparation failed: $e');
    }
  }
  
  String _getModelUrlForQuality(Product product, ModelQualityLevel quality) {
    // Check if product has specific quality URLs
    if (product.metadata.qualityModelUrls.containsKey(quality.name)) {
      return product.metadata.qualityModelUrls[quality.name]!;
    }
    
    // Generate URL based on quality
    final baseUrl = product.primary3DModelUrl;
    final qualitySuffix = quality == ModelQualityLevel.high ? '_high' 
        : quality == ModelQualityLevel.low ? '_low' : '';
    
    return '${baseUrl.split('.').first}$qualitySuffix.glb';
  }
  
  Future<Uint8List?> _fetchModelFromAPI(String productId, String modelUrl) async {
    try {
      // In a real implementation, this would make an API call to /api/render/tryon
      // For now, simulate the fetch with mock data
      await Future.delayed(Duration(milliseconds: 500));
      
      // Return mock GLB data
      return Uint8List.fromList(List.generate(2048, (index) => index % 256));
      
    } catch (e) {
      debugPrint('Failed to fetch model from API: $e');
      return null;
    }
  }
  
  Future<void> _configureModelViewer(
    Product product,
    Avatar avatar,
    ModelPreparationResult modelData,
  ) async {
    final config = <String, dynamic>{
      'src': _getModelViewerSrc(modelData),
      'alt': '${product.name} 3D Model',
      'ar': false, // Disable AR for try-on
      'auto-rotate': true,
      'camera-controls': true,
      'interaction-prompt': InteractionPrompt.automatic,
      'shadow-intensity': 0.5,
      'exposure': 1.0,
      'environment-image': _getEnvironmentImage(avatar.lighting),
      'skybox-image': _getSkyboxImage(avatar.lighting),
      'loading': Loading.eager,
      'reveal': Reveal.auto,
      'animation-name': 'Idle',
      'animation-crossfade-duration': 1000,
      'camera-controls-touch-action': PanZoomBehavior(),
      'style': _getModelViewerStyle(),
    };
    
    // Apply configuration to model viewer
    // In a real implementation, this would update the model viewer's properties
  }
  
  String _getModelViewerSrc(ModelPreparationResult modelData) {
    if (modelData is ModelPreparationResultSuccess) {
      if (modelData.modelData != null) {
        // Convert Uint8List to blob URL for model viewer
        return _createBlobUrl(modelData.modelData!);
      } else if (modelData.modelUrl != null) {
        return modelData.modelUrl!;
      }
    } else if (modelData is ModelPreparationResultFallback2D) {
      return modelData.imageUrl;
    }
    
    // Fallback to empty string
    return '';
  }
  
  String _createBlobUrl(Uint8List data) {
    // In a real implementation, this would create a blob URL from the data
    // For now, return a placeholder URL
    return 'data:model/gltf-binary;base64,${data.isNotEmpty ? 'mock_data' : ''}';
  }
  
  String _getEnvironmentImage(LightingPreset lighting) {
    // Return appropriate environment image URL based on lighting preset
    switch (lighting) {
      case LightingPreset.studio:
        return 'https://modelviewer.dev/shared-assets/environments/spruit_sunrise_1k_HDR.hdr';
      case LightingPreset.day:
        return 'https://modelviewer.dev/shared-assets/environments/moonless_golf_1k_HDR.hdr';
      case LightingPreset.night:
        return 'https://modelviewer.dev/shared-assets/environments/venice_sunset_1k_HDR.hdr';
      default:
        return 'https://modelviewer.dev/shared-assets/environments/spruit_sunrise_1k_HDR.hdr';
    }
  }
  
  String _getSkyboxImage(LightingPreset lighting) {
    return _getEnvironmentImage(lighting);
  }
  
  String _getModelViewerStyle() {
    return '''
      model-viewer {
        width: 100%;
        height: 100%;
        background: transparent;
        --poster-color: #ffffff00;
      }
      
      model-viewer:focus {
        outline: none;
      }
      
      model-viewer::part(default-progress-bar) {
        background-color: rgba(255, 255, 255, 0.1);
      }
      
      model-viewer::part(default-progress-mask) {
        background-color: rgba(0, 0, 0, 0.7);
      }
    ''';
  }
  
  Future<void> _applyInitialTransformations() async {
    // Calculate optimal positioning based on avatar measurements
    _calculateOptimalAvatarPosition();
    
    // Apply initial transformations
    await _applyTransformations();
  }
  
  void _calculateOptimalAvatarPosition() {
    // In a real implementation, this would calculate the optimal position
    // based on avatar measurements and clothing fit
    _scaleFactor = 1.0;
    _positionY = -0.1; // Slightly lower the avatar
  }
  
  Future<void> _applyTransformations() async {
    // Apply transformations using native platform or model viewer APIs
    try {
      // In a real implementation, this would send transformation data to the platform
      await _methodChannel.invokeMethod('applyTransformations', {
        'scale': _scaleFactor,
        'rotationY': _rotationY,
        'rotationX': _rotationX,
        'positionX': _positionX,
        'positionY': _positionY,
        'positionZ': _positionZ,
      });
      
    } catch (e) {
      debugPrint('Failed to apply transformations: $e');
    }
  }
  
  Future<void> _startRendering() async {
    // Start the rendering process
    await Future.delayed(Duration(milliseconds: 100));
    onModelLoaded?.call();
  }
  
  Future<void> _simulateScreenshotCapture(String filePath) async {
    // Simulate screenshot capture
    await Future.delayed(Duration(milliseconds: 500));
    
    // In a real implementation, this would actually capture the screenshot
    debugPrint('Screenshot would be saved to: $filePath');
  }
  
  Future<int> _getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      debugPrint('Failed to get file size: $e');
    }
    return 0;
  }
  
  void _trackPerformance() {
    final now = DateTime.now();
    if (_renderStartTime != null) {
      _modelLoadTime = now.difference(_renderStartTime!).inMilliseconds;
      onPerformanceMetric?.call(_modelLoadTime);
    }
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Result of model loading operation
class ModelLoadResult {
  final bool isSuccess;
  final String? error;
  final int? loadTime;
  final int? renderTime;
  final ModelQualityLevel? quality;
  
  ModelLoadResult._({
    required this.isSuccess,
    this.error,
    this.loadTime,
    this.renderTime,
    this.quality,
  });
  
  factory ModelLoadResult.success({
    required int loadTime,
    required int renderTime,
    required ModelQualityLevel quality,
  }) {
    return ModelLoadResult._(
      isSuccess: true,
      loadTime: loadTime,
      renderTime: renderTime,
      quality: quality,
    );
  }
  
  factory ModelLoadResult.error(String error) {
    return ModelLoadResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Result of model preparation
class ModelPreparationResult {
  final bool isSuccess;
  final Uint8List? modelData;
  final String? modelUrl;
  final String? imageUrl;
  final String? error;
  final ModelQualityLevel? quality;
  
  ModelPreparationResult._({
    required this.isSuccess,
    this.modelData,
    this.modelUrl,
    this.imageUrl,
    this.error,
    this.quality,
  });
  
  factory ModelPreparationResult.success({
    required Uint8List modelData,
    required String modelUrl,
    required ModelQualityLevel quality,
  }) {
    return ModelPreparationResult._(
      isSuccess: true,
      modelData: modelData,
      modelUrl: modelUrl,
      quality: quality,
    );
  }
  
  factory ModelPreparationResult.fallback2D(String imageUrl) {
    return ModelPreparationResult._(
      isSuccess: true,
      imageUrl: imageUrl,
    );
  }
  
  factory ModelPreparationResult.error(String error) {
    return ModelPreparationResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Screenshot capture result
class ScreenshotResult {
  final bool isSuccess;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final String? error;
  
  ScreenshotResult._({
    required this.isSuccess,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.error,
  });
  
  factory ScreenshotResult.success({
    required String filePath,
    required String fileName,
    required int fileSize,
  }) {
    return ScreenshotResult._(
      isSuccess: true,
      filePath: filePath,
      fileName: fileName,
      fileSize: fileSize,
    );
  }
  
  factory ScreenshotResult.error(String error) {
    return ScreenshotResult._(
      isSuccess: false,
      error: error,
    );
  }
  
  double get fileSizeInMB => (fileSize ?? 0) / (1024 * 1024);
}

/// Performance metrics for model rendering
class ModelPerformanceMetrics {
  final bool isModelLoaded;
  final bool isRendering;
  final int loadTime;
  final int renderTime;
  final ModelQualityLevel currentQuality;
  final double scaleFactor;
  final double rotationY;
  final double rotationX;
  
  ModelPerformanceMetrics({
    required this.isModelLoaded,
    required this.isRendering,
    required this.loadTime,
    required this.renderTime,
    required this.currentQuality,
    required this.scaleFactor,
    required this.rotationY,
    required this.rotationX,
  });
  
  double get totalTime => (loadTime + renderTime) / 1000.0;
  
  String get loadTimeFormatted => '${(loadTime / 1000).toStringAsFixed(2)}s';
  
  String get renderTimeFormatted => '${(renderTime / 1000).toStringAsFixed(2)}s';
  
  String get totalTimeFormatted => '${totalTime.toStringAsFixed(2)}s';
}

/// Enhanced ModelViewer with try-on specific functionality
class TryOnModelViewer extends StatefulWidget {
  final Product product;
  final Avatar? avatar;
  final ModelQualityLevel initialQuality;
  final Function(String)? onError;
  final Function()? onLoaded;
  final Function(double)? onQualityChanged;
  
  const TryOnModelViewer({
    super.key,
    required this.product,
    this.avatar,
    this.initialQuality = ModelQualityLevel.medium,
    this.onError,
    this.onLoaded,
    this.onQualityChanged,
  });

  @override
  State<TryOnModelViewer> createState() => _TryOnModelViewerState();
}

class _TryOnModelViewerState extends State<TryOnModelViewer> {
  final GlobalKey _viewerKey = GlobalKey();
  late TryOnModelRenderer _renderer;
  
  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }
  
  void _initializeRenderer() {
    // Initialize the renderer
    // This would be implemented based on the renderer setup
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      key: _viewerKey,
      child: ModelViewer(
        key: _viewerKey,
        // Model viewer configuration would be set here
      ),
    );
  }
}