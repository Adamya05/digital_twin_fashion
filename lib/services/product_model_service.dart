import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../models/avatar_model.dart';
import '../models/product_model.dart';

/// Service for managing 3D product models and try-on rendering
class ProductModelService extends ChangeNotifier {
  static ProductModelService? _instance;
  static ProductModelService get instance => _instance ??= ProductModelService._internal();
  
  factory ProductModelService() => instance;
  ProductModelService._internal();

  // Cache for loaded models
  final Map<String, Uint8List> _modelCache = {};
  final Map<String, Map<String, dynamic>> _modelMetadata = {};
  final Set<String> _loadingModels = {};
  
  // Preloading and streaming
  final List<String> _preloadedModels = [];
  final StreamController<ModelLoadProgress> _progressController = StreamController.broadcast();
  Stream<ModelLoadProgress> get progressStream => _progressController.stream;
  
  // Quality settings
  RenderQuality _renderQuality = RenderQuality.high;
  RenderQuality get renderQuality => _renderQuality;
  
  // Performance monitoring
  final Map<String, ModelPerformanceMetrics> _performanceMetrics = {};
  
  // Compatibility mapping
  final Map<String, List<AvatarType>> _productCompatibility = {};
  
  /// Initialize the service and preload common models
  Future<void> initialize() async {
    await _loadCompatibilityMapping();
    await _preloadCommonModels();
    _performanceMetrics.clear();
  }
  
  /// Load and cache a 3D product model
  Future<Uint8List?> loadModel(String productId, {RenderQuality? quality}) async {
    if (_modelCache.containsKey(productId)) {
      _trackModelAccess(productId);
      return _modelCache[productId];
    }
    
    if (_loadingModels.contains(productId)) {
      // Model is currently loading, wait for it
      await Future.delayed(const Duration(milliseconds: 100));
      return loadModel(productId, quality: quality);
    }
    
    _loadingModels.add(productId);
    final qualityToUse = quality ?? _renderQuality;
    
    try {
      // Simulate realistic loading time based on model size and quality
      final metadata = await getModelMetadata(productId);
      final baseLoadTime = metadata['size_mb'] * 200; // Base load time
      
      _progressController.add(ModelLoadProgress(
        productId,
        0.0,
        'Starting model load...',
        ModelLoadStage.initializing,
      ));
      
      await Future.delayed(Duration(milliseconds: (baseLoadTime * 0.3).round()));
      
      _progressController.add(ModelLoadProgress(
        productId,
        0.3,
        'Loading 3D mesh...',
        ModelLoadStage.loadingGeometry,
      ));
      
      await Future.delayed(Duration(milliseconds: (baseLoadTime * 0.4).round()));
      
      _progressController.add(ModelLoadProgress(
        productId,
        0.7,
        'Loading materials and textures...',
        ModelLoadStage.loadingMaterials,
      ));
      
      await Future.delayed(Duration(milliseconds: (baseLoadTime * 0.2).round()));
      
      _progressController.add(ModelLoadProgress(
        productId,
        0.9,
        'Optimizing for quality: ${qualityToUse.name}...',
        ModelLoadStage.optimizing,
      ));
      
      await Future.delayed(Duration(milliseconds: (baseLoadTime * 0.1).round()));
      
      // Load model data (simulated)
      final modelData = await _loadModelData(productId, qualityToUse);
      
      // Apply device-specific optimizations
      final optimizedData = await _optimizeForDevice(modelData, qualityToUse);
      
      _modelCache[productId] = optimizedData;
      _trackModelAccess(productId);
      
      _progressController.add(ModelLoadProgress(
        productId,
        1.0,
        'Model loaded successfully',
        ModelLoadStage.complete,
      ));
      
      return optimizedData;
      
    } catch (e) {
      _progressController.add(ModelLoadProgress(
        productId,
        0.0,
        'Failed to load model: $e',
        ModelLoadStage.error,
      ));
      return null;
    } finally {
      _loadingModels.remove(productId);
    }
  }
  
  /// Preload models for better UX
  Future<void> preloadModels(List<String> productIds) async {
    for (final productId in productIds) {
      if (!_preloadedModels.contains(productId)) {
        loadModel(productId);
        _preloadedModels.add(productId);
      }
    }
  }
  
  /// Get model metadata
  Future<Map<String, dynamic>> getModelMetadata(String productId) async {
    if (_modelMetadata.containsKey(productId)) {
      return _modelMetadata[productId]!;
    }
    
    // Load metadata from file
    final metadataPath = 'assets/products/3d/metadata/${productId}_metadata.json';
    try {
      final metadataFile = File(metadataPath);
      if (await metadataFile.exists()) {
        final content = await metadataFile.readAsString();
        final metadata = json.decode(content);
        _modelMetadata[productId] = metadata;
        return metadata;
      }
    } catch (e) {
      print('Error loading metadata for $productId: $e');
    }
    
    // Return default metadata
    return _getDefaultMetadata(productId);
  }
  
  /// Validate model integrity
  Future<ModelValidationResult> validateModel(String productId) async {
    try {
      final modelData = _modelCache[productId];
      if (modelData == null) {
        return ModelValidationResult(false, 'Model not loaded');
      }
      
      // Basic validation
      if (modelData.isEmpty) {
        return ModelValidationResult(false, 'Model data is empty');
      }
      
      // Check if starts with GLB header
      if (modelData.length < 4 || 
          modelData[0] != 0x67 || // 'g'
          modelData[1] != 0x6C || // 'l'  
          modelData[2] != 0x62) { // 'b'
        return ModelValidationResult(false, 'Invalid GLB header');
      }
      
      // Check file size limits based on quality settings
      final maxSize = _getMaxModelSizeForQuality();
      if (modelData.length > maxSize) {
        return ModelValidationResult(false, 'Model size exceeds quality limits');
      }
      
      return ModelValidationResult(true, 'Model validation passed');
      
    } catch (e) {
      return ModelValidationResult(false, 'Validation error: $e');
    }
  }
  
  /// Check if avatar and product are compatible
  Future<bool> isCompatible(String productId, AvatarType avatarType) async {
    final compatibleTypes = _productCompatibility[productId];
    if (compatibleTypes == null) {
      // Default to allowing all types if not specified
      return true;
    }
    return compatibleTypes.contains(avatarType);
  }
  
  /// Get size scaling factors for avatar-product fitting
  Map<String, double> getSizeScaling(String productId, AvatarType avatarType, String size) {
    final metadata = _modelMetadata[productId] ?? {};
    final sizeChart = metadata['size_chart'] ?? {};
    final avatarMeasurements = _getAvatarMeasurements(avatarType);
    final productBase = sizeChart[size] ?? {};
    
    if (productBase.isEmpty || avatarMeasurements.isEmpty) {
      return {'chest': 1.0, 'waist': 1.0, 'hips': 1.0, 'shoulders': 1.0};
    }
    
    // Calculate scaling factors
    return {
      'chest': avatarMeasurements['chest'] / (productBase['chest'] ?? 100.0),
      'waist': avatarMeasurements['waist'] / (productBase['waist'] ?? 80.0),
      'hips': avatarMeasurements['hips'] / (productBase['hips'] ?? 95.0),
      'shoulders': avatarMeasurements['shoulders'] / (productBase['shoulders'] ?? 45.0),
    };
  }
  
  /// Clear cache to free memory
  void clearCache() {
    _modelCache.clear();
    _preloadedModels.clear();
    notifyListeners();
  }
  
  /// Set render quality
  void setRenderQuality(RenderQuality quality) {
    _renderQuality = quality;
    notifyListeners();
  }
  
  /// Get performance metrics for a model
  ModelPerformanceMetrics? getPerformanceMetrics(String productId) {
    return _productCompatibility[productId] is! List ? _performanceMetrics[productId] : null;
  }
  
  /// Helper methods
  
  Future<void> _loadCompatibilityMapping() async {
    // This would typically load from a database or configuration file
    _productCompatibility.addAll({
      // Men's clothing
      'tshirt_men_basic_black': [AvatarType.regularMale, AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale, AvatarType.slimMale],
      'tshirt_men_basic_white': [AvatarType.regularMale, AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale, AvatarType.slimMale],
      'jeans_men_classic_blue': [AvatarType.regularMale, AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale, AvatarType.slimMale, AvatarType.petiteMale],
      'jacket_men_blazer_black': [AvatarType.regularMale, AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale],
      
      // Women's clothing
      'dress_women_casual_blue': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.muscularFemale, AvatarType.tallFemale, AvatarType.petiteFemale, AvatarType.plussizeFemale],
      'blouse_women_silk_red': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.tallFemale, AvatarType.slimFemale],
      'pants_women_jeans_blue': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.muscularFemale, AvatarType.tallFemale, AvatarType.petiteFemale, AvatarType.slimFemale],
      'coat_women_winter_beige': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.tallFemale, AvatarType.petiteFemale, AvatarType.plussizeFemale],
      
      // Activewear - unisex but optimized for athletic builds
      'sports_bra_women_black': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.muscularFemale, AvatarType.tallFemale, AvatarType.slimFemale],
      'leggings_women_blue': [AvatarType.regularFemale, AvatarType.athleticFemale, AvatarType.muscularFemale, AvatarType.tallFemale, AvatarType.petiteFemale, AvatarType.slimFemale],
      'shorts_men_athletic_gray': [AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale, AvatarType.slimMale],
      'tank_top_men_athletic_white': [AvatarType.athleticMale, AvatarType.muscularMale, AvatarType.tallMale],
    });
  }
  
  Future<void> _preloadCommonModels() async {
    final commonModels = [
      'tshirt_men_basic_black',
      'tshirt_men_basic_white',
      'dress_women_casual_blue',
      'blouse_women_silk_red',
      'jeans_men_classic_blue',
      'pants_women_jeans_blue',
    ];
    
    preloadModels(commonModels);
  }
  
  Future<Uint8List> _loadModelData(String productId, RenderQuality quality) async {
    // Simulate loading model data - in real implementation, this would load actual GLB files
    final category = productId.split('_')[0];
    final filePath = 'assets/products/3d/clothing/${category}/${productId}_${quality.name}_v1.glb';
    
    try {
      // For demo purposes, generate realistic mock model data
      return _generateMockModelData(productId, quality);
    } catch (e) {
      throw Exception('Failed to load model data: $e');
    }
  }
  
  Future<Uint8List> _optimizeForDevice(Uint8List modelData, RenderQuality quality) async {
    // Simulate device-specific optimizations
    // In real implementation, this would apply LOD, compression, etc.
    
    // For demonstration, vary the data size based on quality
    switch (quality) {
      case RenderQuality.high:
        return modelData; // No optimization for high quality
      case RenderQuality.medium:
        return modelData.sublist(0, (modelData.length * 0.7).round());
      case RenderQuality.low:
        return modelData.sublist(0, (modelData.length * 0.4).round());
    }
  }
  
  Uint8List _generateMockModelData(String productId, RenderQuality quality) {
    // Generate realistic mock GLB data
    final buffer = BytesBuilder();
    
    // GLB header
    buffer.add([0x67, 0x6C, 0x62, 0x01]); // Magic + version
    buffer.add(Uint8List(4)..buffer.asByteData().setUint32(0, 1000000, Endian.little)); // Length placeholder
    
    // Simulate different model sizes based on quality and product type
    final baseSize = _getBaseSizeForProduct(productId);
    final qualityMultiplier = quality == RenderQuality.high ? 1.0 : 
                             quality == RenderQuality.medium ? 0.7 : 0.4;
    final finalSize = (baseSize * qualityMultiplier).round();
    
    // Generate realistic GLB content
    buffer.add( Uint8List(finalSize) ); // Dummy content
    
    return buffer.toBytes();
  }
  
  int _getBaseSizeForProduct(String productId) {
    // Base sizes for different product types (in bytes)
    final sizes = {
      'tshirt': 800000,
      'blouse': 850000,
      'dress': 1200000,
      'jeans': 900000,
      'pants': 950000,
      'jacket': 1100000,
      'coat': 1400000,
      'sports_bra': 600000,
      'leggings': 700000,
      'shorts': 500000,
      'tank_top': 650000,
    };
    
    for (final entry in sizes.entries) {
      if (productId.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 750000; // Default size
  }
  
  Map<String, dynamic> _getDefaultMetadata(String productId) {
    // Generate default metadata for products without explicit metadata files
    final parts = productId.split('_');
    if (parts.length < 3) {
      return _getGenericProductMetadata();
    }
    
    final type = parts[0];
    final gender = parts[1];
    final category = parts[2];
    
    return {
      'id': productId,
      'name': '${type.replaceAll('_', ' ').toTitleCase()} $gender',
      'category': type,
      'gender': gender,
      'size_chart': _getDefaultSizeChart(gender, type),
      'materials': _getDefaultMaterials(type),
      'care_instructions': _getDefaultCareInstructions(type),
      'recommended_occasions': _getDefaultOccasions(type),
      'size_mb': _getBaseSizeForProduct(productId) / 1000000,
      'vertices': _estimateVertexCount(type),
      'texture_resolution': _getTextureResolution(productId),
      'animation_support': _supportsAnimation(type),
      'physics_properties': _getDefaultPhysicsProperties(type),
    };
  }
  
  Map<String, double> _getAvatarMeasurements(AvatarType avatarType) {
    final measurements = {
      AvatarType.regularMale: {'chest': 100.0, 'waist': 85.0, 'hips': 95.0, 'shoulders': 48.0},
      AvatarType.athleticMale: {'chest': 108.0, 'waist': 82.0, 'hips': 97.0, 'shoulders': 52.0},
      AvatarType.muscularMale: {'chest': 115.0, 'waist': 88.0, 'hips': 100.0, 'shoulders': 55.0},
      AvatarType.tallMale: {'chest': 102.0, 'waist': 86.0, 'hips': 96.0, 'shoulders': 49.0},
      AvatarType.slimMale: {'chest': 94.0, 'waist': 78.0, 'hips': 90.0, 'shoulders': 46.0},
      AvatarType.petiteMale: {'chest': 88.0, 'waist': 72.0, 'hips': 85.0, 'shoulders': 42.0},
      AvatarType.plussizeMale: {'chest': 120.0, 'waist': 105.0, 'hips': 110.0, 'shoulders': 58.0},
      
      AvatarType.regularFemale: {'chest': 88.0, 'waist': 70.0, 'hips': 96.0, 'shoulders': 38.0},
      AvatarType.athleticFemale: {'chest': 92.0, 'waist': 68.0, 'hips': 98.0, 'shoulders': 40.0},
      AvatarType.muscularFemale: {'chest': 98.0, 'waist': 72.0, 'hips': 102.0, 'shoulders': 42.0},
      AvatarType.tallFemale: {'chest': 90.0, 'waist': 72.0, 'hips': 98.0, 'shoulders': 39.0},
      AvatarType.slimFemale: {'chest': 84.0, 'waist': 64.0, 'hips': 92.0, 'shoulders': 36.0},
      AvatarType.petiteFemale: {'chest': 82.0, 'waist': 62.0, 'hips': 90.0, 'shoulders': 35.0},
      AvatarType.plussizeFemale: {'chest': 105.0, 'waist': 92.0, 'hips': 112.0, 'shoulders': 44.0},
    };
    
    return measurements[avatarType] ?? measurements[AvatarType.regularMale]!;
  }
  
  Map<String, Map<String, double>> _getDefaultSizeChart(String gender, String type) {
    if (gender == 'women') {
      return {
        'XS': {'chest': 78, 'waist': 58, 'hips': 84, 'shoulders': 34},
        'S': {'chest': 82, 'waist': 62, 'hips': 88, 'shoulders': 36},
        'M': {'chest': 86, 'waist': 66, 'hips': 92, 'shoulders': 38},
        'L': {'chest': 92, 'waist': 72, 'hips': 98, 'shoulders': 40},
        'XL': {'chest': 98, 'waist': 78, 'hips': 104, 'shoulders': 42},
      };
    } else {
      return {
        'S': {'chest': 94, 'waist': 78, 'hips': 90, 'shoulders': 46},
        'M': {'chest': 100, 'waist': 84, 'hips': 95, 'shoulders': 48},
        'L': {'chest': 108, 'waist': 90, 'hips': 100, 'shoulders': 52},
        'XL': {'chest': 116, 'waist': 96, 'hips': 105, 'shoulders': 56},
        'XXL': {'chest': 124, 'waist': 102, 'hips': 110, 'shoulders': 60},
      };
    }
  }
  
  List<String> _getDefaultMaterials(String type) {
    final materialsMap = {
      'tshirt': ['100% Cotton', 'Preshrunk'],
      'blouse': ['100% Silk', 'Dry clean only'],
      'dress': ['Polyester blend', 'Machine washable'],
      'jeans': ['98% Cotton, 2% Elastane', 'Machine wash'],
      'pants': ['Wool blend', 'Dry clean recommended'],
      'jacket': ['100% Wool', 'Dry clean only'],
      'coat': ['Cashmere blend', 'Dry clean only'],
      'sports_bra': ['88% Nylon, 12% Spandex', 'Machine wash cold'],
      'leggings': ['90% Polyester, 10% Spandex', 'Machine wash'],
      'shorts': ['100% Cotton', 'Machine wash'],
      'tank_top': ['50% Cotton, 50% Polyester', 'Machine wash'],
    };
    
    for (final entry in materialsMap.entries) {
      if (type.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return ['Cotton blend', 'Machine washable'];
  }
  
  List<String> _getDefaultCareInstructions(String type) {
    if (type.contains('silk') || type.contains('wool')) {
      return ['Dry clean only', 'Do not tumble dry', 'Iron on low heat'];
    } else if (type.contains('cotton')) {
      return ['Machine wash cold', 'Tumble dry low', 'Iron on medium heat'];
    } else {
      return ['Machine wash cold', 'Tumble dry low', 'Do not bleach'];
    }
  }
  
  List<String> _getDefaultOccasions(String type) {
    if (type.contains('formal')) {
      return ['Business', 'Evening events', 'Formal gatherings'];
    } else if (type.contains('casual')) {
      return ['Everyday wear', 'Casual outings', 'Weekend activities'];
    } else if (type.contains('active') || type.contains('sport')) {
      return ['Gym', 'Running', 'Yoga', 'Sports activities'];
    } else {
      return ['Casual wear', 'Everyday activities'];
    }
  }
  
  int _estimateVertexCount(String type) {
    final vertexCounts = {
      'tshirt': 25000,
      'blouse': 28000,
      'dress': 45000,
      'jeans': 30000,
      'pants': 32000,
      'jacket': 40000,
      'coat': 50000,
      'sports_bra': 15000,
      'leggings': 20000,
      'shorts': 12000,
      'tank_top': 18000,
    };
    
    for (final entry in vertexCounts.entries) {
      if (type.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 20000;
  }
  
  String _getTextureResolution(String productId) {
    if (productId.contains('premium') || productId.contains('luxury')) {
      return '4K';
    } else if (productId.contains('basic') || productId.contains('simple')) {
      return '1K';
    }
    return '2K';
  }
  
  bool _supportsAnimation(String type) {
    return !type.contains('stiff') && !type.contains('rigid');
  }
  
  Map<String, dynamic> _getDefaultPhysicsProperties(String type) {
    if (type.contains('silk') || type.contains('dress')) {
      return {
        'stiffness': 0.3,
        'damping': 0.7,
        'gravity_effect': 0.8,
        'wind_response': 0.6,
        'stretch_factor': 1.05,
      };
    } else if (type.contains('cotton') || type.contains('basic')) {
      return {
        'stiffness': 0.6,
        'damping': 0.5,
        'gravity_effect': 0.9,
        'wind_response': 0.4,
        'stretch_factor': 1.02,
      };
    } else if (type.contains('active') || type.contains('sport')) {
      return {
        'stiffness': 0.8,
        'damping': 0.3,
        'gravity_effect': 0.95,
        'wind_response': 0.8,
        'stretch_factor': 1.3,
      };
    }
    
    return {
      'stiffness': 0.5,
      'damping': 0.5,
      'gravity_effect': 0.8,
      'wind_response': 0.5,
      'stretch_factor': 1.1,
    };
  }
  
  Map<String, dynamic> _getGenericProductMetadata() {
    return {
      'id': 'unknown',
      'name': 'Unknown Product',
      'category': 'unknown',
      'size_mb': 1.0,
      'vertices': 20000,
    };
  }
  
  int _getMaxModelSizeForQuality() {
    switch (_renderQuality) {
      case RenderQuality.high:
        return 20 * 1024 * 1024; // 20MB
      case RenderQuality.medium:
        return 8 * 1024 * 1024; // 8MB
      case RenderQuality.low:
        return 3 * 1024 * 1024; // 3MB
    }
  }
  
  void _trackModelAccess(String productId) {
    final metrics = _performanceMetrics[productId] ?? ModelPerformanceMetrics();
    metrics.accessCount++;
    metrics.lastAccessed = DateTime.now();
    _performanceMetrics[productId] = metrics;
  }
  
  @override
  void dispose() {
    _progressController.close();
    _modelCache.clear();
    _preloadedModels.clear();
    super.dispose();
  }
}

/// Model load progress tracking
class ModelLoadProgress {
  final String productId;
  final double progress; // 0.0 to 1.0
  final String message;
  final ModelLoadStage stage;
  
  const ModelLoadProgress(this.productId, this.progress, this.message, this.stage);
}

/// Model load stages
enum ModelLoadStage {
  initializing,
  loadingGeometry,
  loadingMaterials,
  optimizing,
  complete,
  error,
}

/// Model validation result
class ModelValidationResult {
  final bool isValid;
  final String message;
  
  const ModelValidationResult(this.isValid, this.message);
}

/// Performance metrics for models
class ModelPerformanceMetrics {
  int accessCount = 0;
  DateTime? lastAccessed;
  Duration? averageLoadTime;
  int errorCount = 0;
  
  ModelPerformanceMetrics();
}

/// Render quality levels
enum RenderQuality {
  high(0),
  medium(1),
  low(2);
  
  const RenderQuality(this.value);
  final int value;
  
  String get name => toString().split('.').last;
  String get displayName => name.toUpperCase();
}

// Extension for title case
extension StringTitleCase on String {
  String toTitleCase() {
    return split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase()
            : word)
        .join(' ');
  }
}