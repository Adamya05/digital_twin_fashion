import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 3D Model Cache Service
/// Manages loading, caching, and optimization of 3D models for try-on functionality
class ModelCacheService {
  static const String _prefsKey = 'model_cache';
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const Duration _cacheExpiration = Duration(hours: 24);
  
  final Map<String, CachedModel> _cache = {};
  final SharedPreferences _prefs;
  
  ModelCacheService(this._prefs);
  
  /// Get cached model data for product
  Future<CachedModel?> getCachedModel(String productId) async {
    final modelKey = _getModelKey(productId);
    
    if (_cache.containsKey(modelKey)) {
      final cachedModel = _cache[modelKey]!;
      
      // Check if cache is still valid
      if (DateTime.now().difference(cachedModel.cachedAt) < _cacheExpiration) {
        return cachedModel;
      } else {
        // Remove expired cache
        await _removeFromCache(modelKey);
      }
    }
    
    return null;
  }
  
  /// Cache model data
  Future<void> cacheModel(String productId, Uint8List modelData, {
    String? modelUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final modelKey = _getModelKey(productId);
    final cacheSize = await _getCacheSize();
    
    // Check cache size limit
    if (cacheSize + modelData.length > _maxCacheSize) {
      await _evictOldestModels(modelData.length);
    }
    
    final cachedModel = CachedModel(
      productId: productId,
      data: modelData,
      cachedAt: DateTime.now(),
      modelUrl: modelUrl,
      metadata: metadata ?? {},
    );
    
    _cache[modelKey] = cachedModel;
    
    // Save to persistent storage
    await _saveToPreferences(modelKey, cachedModel);
  }
  
  /// Preload model for smoother transitions
  Future<void> preloadModel(String productId, String modelUrl) async {
    try {
      // Check if model is already cached
      if (await getCachedModel(productId) != null) {
        return; // Already cached
      }
      
      // In a real implementation, this would fetch from the model URL
      // For now, we'll simulate the download
      await Future.delayed(Duration(milliseconds: 100));
      
      // Simulate model data (in real implementation, this would be actual GLB data)
      final mockModelData = Uint8List.fromList(List.generate(1024, (index) => index % 256));
      
      await cacheModel(productId, mockModelData, modelUrl: modelUrl);
    } catch (e) {
      debugPrint('Failed to preload model for $productId: $e');
    }
  }
  
  /// Get optimal quality level for device capabilities
  ModelQualityLevel getOptimalQuality() {
    // Check device memory and performance
    final isLowEndDevice = _isLowEndDevice();
    final connectionType = _getConnectionType();
    
    if (isLowEndDevice || connectionType == ConnectionType.slow) {
      return ModelQualityLevel.low;
    } else if (connectionType == ConnectionType.fast) {
      return ModelQualityLevel.high;
    } else {
      return ModelQualityLevel.medium;
    }
  }
  
  /// Validate 3D model format and compatibility
  Future<ModelValidationResult> validateModel(Uint8List modelData, String format) async {
    try {
      // Basic format validation
      if (!_isValidModelFormat(format)) {
        return ModelValidationResult.invalid('Unsupported model format: $format');
      }
      
      // Check file size
      if (modelData.length > 50 * 1024 * 1024) { // 50MB limit
        return ModelValidationResult.invalid('Model file too large (max 50MB)');
      }
      
      // Check for minimum file size (prevent corrupted files)
      if (modelData.length < 1024) { // 1KB minimum
        return ModelValidationResult.invalid('Model file too small or corrupted');
      }
      
      // In a real implementation, this would validate the GLB structure
      // For now, we'll do basic validation
      return ModelValidationResult.valid();
      
    } catch (e) {
      return ModelValidationResult.invalid('Validation error: $e');
    }
  }
  
  /// Dispose cached models to free memory
  Future<void> disposeUnusedModels() async {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cache.forEach((key, model) {
      if (now.difference(model.cachedAt) > _cacheExpiration) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      await _removeFromCache(key);
    }
    
    debugPrint('Disposed ${expiredKeys.length} expired models from cache');
  }
  
  /// Get cache statistics
  CacheStatistics getCacheStatistics() {
    final totalSize = _cache.values.fold<int>(0, (sum, model) => sum + model.data.length);
    final modelCount = _cache.length;
    final oldestModel = _cache.isNotEmpty 
        ? _cache.values.map((m) => m.cachedAt).reduce((a, b) => a.isBefore(b) ? a : b)
        : null;
    
    return CacheStatistics(
      totalSize: totalSize,
      modelCount: modelCount,
      oldestCachedAt: oldestModel,
      maxSize: _maxCacheSize,
    );
  }
  
  // ==================== PRIVATE METHODS ====================
  
  String _getModelKey(String productId) => 'model_$productId';
  
  Future<int> _getCacheSize() async {
    return _cache.values.fold<int>(0, (sum, model) => sum + model.data.length);
  }
  
  Future<void> _evictOldestModels(int requiredSpace) async {
    // Sort models by cache time (oldest first)
    final sortedModels = _cache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    
    int freedSpace = 0;
    final keysToRemove = <String>[];
    
    for (final entry in sortedModels) {
      if (freedSpace >= requiredSpace) break;
      
      freedSpace += entry.value.data.length;
      keysToRemove.add(entry.key);
    }
    
    // Remove evicted models
    for (final key in keysToRemove) {
      await _removeFromCache(key);
    }
    
    debugPrint('Evicted ${keysToRemove.length} models, freed ${freedSpace} bytes');
  }
  
  Future<void> _removeFromCache(String modelKey) async {
    _cache.remove(modelKey);
    await _prefs.remove(modelKey);
  }
  
  Future<void> _saveToPreferences(String modelKey, CachedModel cachedModel) async {
    try {
      await _prefs.setString(modelKey, cachedModel.toJsonString());
    } catch (e) {
      debugPrint('Failed to save model to preferences: $e');
    }
  }
  
  bool _isLowEndDevice() {
    // Simple heuristic for device capability detection
    // In a real implementation, this would use platform-specific APIs
    return false; // Assume all devices are capable for now
  }
  
  ConnectionType _getConnectionType() {
    // In a real implementation, this would check actual connection speed
    // For now, return medium
    return ConnectionType.medium;
  }
  
  bool _isValidModelFormat(String format) {
    const supportedFormats = ['glb', 'gltf', 'usdz'];
    return supportedFormats.contains(format.toLowerCase());
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Cached 3D model data
class CachedModel {
  final String productId;
  final Uint8List data;
  final DateTime cachedAt;
  final String? modelUrl;
  final Map<String, dynamic> metadata;
  
  CachedModel({
    required this.productId,
    required this.data,
    required this.cachedAt,
    this.modelUrl,
    this.metadata = const {},
  });
  
  String toJsonString() {
    // In a real implementation, this would properly serialize the model data
    return '${productId}_${cachedAt.millisecondsSinceEpoch}';
  }
  
  int get sizeInBytes => data.length;
  
  double get sizeInMB => sizeInBytes / (1024 * 1024);
}

/// Model quality levels
enum ModelQualityLevel {
  low('Low', 'Draft quality for quick loading', 0.5, 10000),
  medium('Medium', 'Balanced quality and performance', 1.0, 25000),
  high('High', 'Premium quality for detailed viewing', 2.0, 50000);
  
  const ModelQualityLevel(
    this.label,
    this.description,
    this.resolutionMultiplier,
    this.maxPolygons,
  );
  
  final String label;
  final String description;
  final double resolutionMultiplier;
  final int maxPolygons;
}

/// Network connection type
enum ConnectionType {
  slow('Slow', '2G/3G or poor WiFi'),
  medium('Medium', '4G or average WiFi'),
  fast('Fast', '5G or high-speed WiFi');
  
  const ConnectionType(this.label, this.description);
  final String label;
  final String description;
}

/// Model validation result
class ModelValidationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? details;
  
  ModelValidationResult._({
    required this.isValid,
    this.error,
    this.details,
  });
  
  factory ModelValidationResult.valid({Map<String, dynamic>? details}) {
    return ModelValidationResult._(
      isValid: true,
      details: details,
    );
  }
  
  factory ModelValidationResult.invalid(String error) {
    return ModelValidationResult._(
      isValid: false,
      error: error,
    );
  }
}

/// Cache statistics
class CacheStatistics {
  final int totalSize;
  final int modelCount;
  final DateTime? oldestCachedAt;
  final int maxSize;
  
  CacheStatistics({
    required this.totalSize,
    required this.modelCount,
    this.oldestCachedAt,
    required this.maxSize,
  });
  
  double get utilizationPercentage => (totalSize / maxSize) * 100;
  
  bool get isFull => totalSize >= maxSize;
  
  String get sizeInMB => '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  
  String get maxSizeInMB => '${(maxSize / (1024 * 1024)).toStringAsFixed(0)} MB';
}