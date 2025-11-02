import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/avatar_model.dart';
import '../models/product_model.dart';
import 'model_cache_service.dart';

/// 3D Model Loading Service
/// Handles API interactions for 3D model loading, validation, and optimization
class ModelLoadingService {
  static const String _baseUrl = 'https://mock-api.minimax.io';
  static const String _tryOnEndpoint = '/api/render/tryon';
  static const Duration _timeout = Duration(seconds: 30);
  
  final http.Client _client;
  final ModelCacheService _cacheService;
  
  ModelLoadingService(this._client, SharedPreferences prefs) 
      : _cacheService = ModelCacheService(prefs);
  
  /// Load 3D model for try-on from API
  Future<TryOnModelResult> loadTryOnModel({
    required String productId,
    required String productName,
    required Avatar? avatar,
    ModelQualityLevel quality = ModelQualityLevel.medium,
    Map<String, dynamic>? customParameters,
  }) async {
    try {
      // Check cache first
      final cachedModel = await _cacheService.getCachedModel(productId);
      if (cachedModel != null) {
        return TryOnModelResult.success(
          data: cachedModel.data,
          isFromCache: true,
          metadata: cachedModel.metadata,
        );
      }
      
      // Prepare API request
      final requestData = _buildTryOnRequestData(
        productId: productId,
        productName: productName,
        avatar: avatar,
        quality: quality,
        customParameters: customParameters,
      );
      
      // Make API request
      final response = await _client.post(
        Uri.parse('$_baseUrl$_tryOnEndpoint'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final modelData = _extractModelData(responseData);
        final metadata = _extractMetadata(responseData);
        
        // Validate the loaded model
        final validation = await _cacheService.validateModel(
          modelData, 
          metadata['format'] ?? 'glb',
        );
        
        if (validation.isValid) {
          // Cache the model for future use
          await _cacheService.cacheModel(
            productId, 
            modelData,
            modelUrl: metadata['url'],
            metadata: metadata,
          );
          
          return TryOnModelResult.success(
            data: modelData,
            isFromCache: false,
            metadata: metadata,
          );
        } else {
          return TryOnModelResult.error(validation.error ?? 'Model validation failed');
        }
      } else {
        return TryOnModelResult.error('API request failed: ${response.statusCode}');
      }
      
    } on SocketException {
      return TryOnModelResult.error('No internet connection');
    } on HttpException {
      return TryOnModelResult.error('Unable to connect to server');
    } catch (e) {
      return TryOnModelResult.error('Unexpected error: $e');
    }
  }
  
  /// Preload multiple models for smoother transitions
  Future<Map<String, TryOnModelResult>> preloadModels({
    required List<Product> products,
    Avatar? avatar,
    ModelQualityLevel quality = ModelQualityLevel.medium,
  }) async {
    final results = <String, TryOnModelResult>{};
    
    // Process models in batches to avoid overwhelming the system
    const batchSize = 3;
    for (int i = 0; i < products.length; i += batchSize) {
      final batch = products.skip(i).take(batchSize).toList();
      
      final batchResults = await Future.wait(
        batch.map((product) => loadTryOnModel(
          productId: product.id,
          productName: product.name,
          avatar: avatar,
          quality: quality,
        )),
      );
      
      // Store results
      for (int j = 0; j < batch.length; j++) {
        results[batch[j].id] = batchResults[j];
      }
      
      // Small delay between batches
      if (i + batchSize < products.length) {
        await Future.delayed(Duration(milliseconds: 100));
      }
    }
    
    return results;
  }
  
  /// Get optimal model quality for current device and connection
  ModelQualityLevel getOptimalQualityForDevice() {
    return _cacheService.getOptimalQuality();
  }
  
  /// Check if product has 3D model available
  Future<bool> has3DModel(String productId, String productCategory) async {
    try {
      // In a real implementation, this would check the product catalog
      // For now, simulate checking
      await Future.delayed(Duration(milliseconds: 200));
      
      // Simulate that certain categories have 3D models
      final categoriesWith3D = ['Tops', 'Dresses', 'Outerwear', 'Activewear'];
      return categoriesWith3D.contains(productCategory);
      
    } catch (e) {
      debugPrint('Failed to check 3D model availability: $e');
      return false;
    }
  }
  
  /// Get fallback 2D product image
  String getFallback2DImage(Product product) {
    if (product.images.isNotEmpty) {
      return product.images.first;
    }
    return product.primaryImage;
  }
  
  /// Adjust model quality based on device performance
  ModelQualityLevel adjustQualityForPerformance(ModelQualityLevel currentQuality) {
    // In a real implementation, this would analyze device performance
    // For now, return the current quality
    return currentQuality;
  }
  
  /// Get model compatibility score for avatar
  double calculateCompatibilityScore(Product product, Avatar avatar) {
    try {
      if (!product.has3DModel) return 0.0;
      
      // Check body type compatibility
      final bodyTypeScore = product.compatibility.isCompatibleWith(avatar) ? 0.7 : 0.3;
      
      // Check size compatibility
      final availableSizes = product.availableSizes;
      final hasMatchingSize = availableSizes.isNotEmpty; // Simplified check
      final sizeScore = hasMatchingSize ? 0.3 : 0.1;
      
      return bodyTypeScore + sizeScore;
      
    } catch (e) {
      debugPrint('Failed to calculate compatibility: $e');
      return 0.0;
    }
  }
  
  /// Optimize model for mobile device
  Future<TryOnModelResult> optimizeModelForMobile(TryOnModelResult originalModel) async {
    // In a real implementation, this would process the 3D model for mobile
    // For now, just return the original model
    return originalModel;
  }
  
  /// Dispose resources
  void dispose() {
    _client.close();
    _cacheService.disposeUnusedModels();
  }
  
  // ==================== PRIVATE METHODS ====================
  
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'DigitalTwinFashion/1.0.0',
    };
  }
  
  Map<String, dynamic> _buildTryOnRequestData({
    required String productId,
    required String productName,
    required Avatar? avatar,
    required ModelQualityLevel quality,
    Map<String, dynamic>? customParameters,
  }) {
    return {
      'product_id': productId,
      'product_name': productName,
      'quality_level': quality.name,
      'avatar': avatar != null ? {
        'id': avatar.id,
        'model_url': avatar.modelUrl,
        'measurements': avatar.measurements.toJson(),
        'attributes': avatar.attributes.toJson(),
      } : null,
      'custom_parameters': customParameters ?? {},
      'optimization': {
        'target_platform': defaultTargetPlatform(),
        'texture_compression': true,
        'lod_levels': quality != ModelQualityLevel.high,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  String defaultTargetPlatform() {
    // In a real implementation, this would detect the actual platform
    return 'mobile';
  }
  
  Uint8List _extractModelData(Map<String, dynamic> responseData) {
    // In a real implementation, this would extract the actual model data
    // For now, return mock data
    final base64Data = responseData['model_data'] as String? ?? '';
    
    if (base64Data.isNotEmpty) {
      return base64Decode(base64Data);
    } else {
      // Return mock GLB data
      return Uint8List.fromList(List.generate(2048, (index) => index % 256));
    }
  }
  
  Map<String, dynamic> _extractMetadata(Map<String, dynamic> responseData) {
    return responseData['metadata'] as Map<String, dynamic>? ?? {
      'format': 'glb',
      'url': '',
      'size': 0,
      'quality': 'medium',
    };
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Result of 3D model loading operation
class TryOnModelResult {
  final bool isSuccess;
  final Uint8List? data;
  final String? error;
  final bool isFromCache;
  final Map<String, dynamic>? metadata;
  
  TryOnModelResult._({
    required this.isSuccess,
    this.data,
    this.error,
    this.isFromCache = false,
    this.metadata,
  });
  
  factory TryOnModelResult.success({
    required Uint8List data,
    bool isFromCache = false,
    Map<String, dynamic>? metadata,
  }) {
    return TryOnModelResult._(
      isSuccess: true,
      data: data,
      isFromCache: isFromCache,
      metadata: metadata,
    );
  }
  
  factory TryOnModelResult.error(String error) {
    return TryOnModelResult._(
      isSuccess: false,
      error: error,
    );
  }
  
  bool get hasData => data != null;
  
  double get sizeInMB => data != null ? data!.lengthInBytes / (1024 * 1024) : 0.0;
  
  String? get modelUrl => metadata?['url'] as String?;
  
  String? get format => metadata?['format'] as String?;
}