import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../models/avatar_model.dart';
import '../../models/product_model.dart';
import '../../services/model_cache_service.dart';
import '../../services/model_loading_service.dart';

/// 3D Model API Service
/// 
/// Handles API interactions with the /api/render/tryon endpoint for generating
/// composite 3D models that combine avatar and product data
class TryOnAPIService {
  static const String _baseUrl = 'https://mock-api.minimax.io';
  static const String _tryOnEndpoint = '/api/render/tryon';
  static const Duration _timeout = Duration(seconds: 30);
  
  final http.Client _client;
  final ModelCacheService _cacheService;
  final ModelLoadingService _modelLoadingService;
  
  TryOnAPIService(
    this._client,
    this._cacheService,
    this._modelLoadingService,
  );
  
  // ==================== MAIN API METHODS ====================
  
  /// Request 3D model rendering for try-on
  /// 
  /// This is the core method that sends avatar and product data to the backend
  /// to generate a composite 3D model for try-on experience
  Future<TryOnRenderResult> requestTryOnRender({
    required String productId,
    required String productName,
    required Avatar avatar,
    ModelQualityLevel quality = ModelQualityLevel.medium,
    RenderOptions? options,
    Map<String, dynamic>? customParameters,
  }) async {
    try {
      // Check cache first
      final cacheKey = _generateCacheKey(productId, avatar.id, quality);
      final cachedModel = await _cacheService.getCachedModel(cacheKey);
      
      if (cachedModel != null) {
        return TryOnRenderResult.success(
          modelData: cachedModel.data,
          modelUrl: cachedModel.modelUrl,
          isFromCache: true,
          metadata: cachedModel.metadata,
        );
      }
      
      // Prepare request data
      final requestData = await _buildRenderRequest(
        productId: productId,
        productName: productName,
        avatar: avatar,
        quality: quality,
        options: options,
        customParameters: customParameters,
      );
      
      // Make API request
      final response = await _client.post(
        Uri.parse('$_baseUrl$_tryOnEndpoint'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return await _processSuccessfulResponse(response);
      } else {
        return TryOnRenderResult.error(
          'API request failed with status: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
      
    } on SocketException {
      return TryOnRenderResult.error('No internet connection available');
    } on HttpException {
      return TryOnRenderResult.error('Unable to connect to rendering service');
    } catch (e) {
      return TryOnRenderResult.error('Unexpected error during rendering: $e');
    }
  }
  
  /// Batch request multiple try-on renders for smooth transitions
  Future<Map<String, TryOnRenderResult>> batchRequestTryOnRender({
    required Map<String, Product> products,
    required Avatar avatar,
    ModelQualityLevel quality = ModelQualityLevel.medium,
    int maxConcurrency = 3,
  }) async {
    final results = <String, TryOnRenderResult>{};
    final productEntries = products.entries.toList();
    
    // Process in batches to avoid overwhelming the server
    for (int i = 0; i < productEntries.length; i += maxConcurrency) {
      final batch = productEntries.skip(i).take(maxConcurrency);
      
      final batchResults = await Future.wait(
        batch.map((entry) => requestTryOnRender(
          productId: entry.key,
          productName: entry.value.name,
          avatar: avatar,
          quality: quality,
        )),
      );
      
      // Store results
      for (int j = 0; j < batch.length; j++) {
        results[batch[j].key] = batchResults[j];
      }
      
      // Small delay between batches to be respectful to the server
      if (i + maxConcurrency < productEntries.length) {
        await Future.delayed(Duration(milliseconds: 200));
      }
    }
    
    return results;
  }
  
  /// Check rendering service availability
  Future<ServiceAvailabilityResult> checkServiceAvailability() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final healthData = jsonDecode(response.body);
        return ServiceAvailabilityResult.available(
          status: healthData['status'] ?? 'unknown',
          message: healthData['message'] ?? 'Service is healthy',
          capabilities: healthData['capabilities'] ?? {},
        );
      } else {
        return ServiceAvailabilityResult.unavailable(
          'Service returned status: ${response.statusCode}',
        );
      }
      
    } catch (e) {
      return ServiceAvailabilityResult.unavailable(
        'Service check failed: $e',
      );
    }
  }
  
  /// Get rendering queue status
  Future<QueueStatusResult> getQueueStatus() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/queue/status'),
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final queueData = jsonDecode(response.body);
        return QueueStatusResult.fromJson(queueData);
      } else {
        return QueueStatusResult.error('Failed to get queue status');
      }
      
    } catch (e) {
      return QueueStatusResult.error('Queue status check failed: $e');
    }
  }
  
  /// Cancel pending render request
  Future<bool> cancelRenderRequest(String requestId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl$_tryOnEndpoint/$requestId'),
        headers: _getHeaders(),
      );
      
      return response.statusCode == 200;
      
    } catch (e) {
      debugPrint('Failed to cancel render request: $e');
      return false;
    }
  }
  
  /// Get render history for user
  Future<RenderHistoryResult> getRenderHistory({
    int page = 1,
    int perPage = 20,
    DateTime? since,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }
      
      final uri = Uri.parse('$_baseUrl/render/history').replace(
        queryParameters: queryParams,
      );
      
      final response = await _client.get(
        uri,
        headers: _getHeaders(),
      ).timeout(Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final historyData = jsonDecode(response.body);
        return RenderHistoryResult.fromJson(historyData);
      } else {
        return RenderHistoryResult.error('Failed to get render history');
      }
      
    } catch (e) {
      return RenderHistoryResult.error('Render history request failed: $e');
    }
  }
  
  // ==================== PRIVATE HELPERS ====================
  
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'DigitalTwinFashion/1.0.0',
      'X-Client-Version': '1.0.0',
    };
  }
  
  String _generateCacheKey(String productId, String avatarId, ModelQualityLevel quality) {
    return 'tryon_${productId}_${avatarId}_${quality.name}';
  }
  
  Future<Map<String, dynamic>> _buildRenderRequest({
    required String productId,
    required String productName,
    required Avatar avatar,
    required ModelQualityLevel quality,
    RenderOptions? options,
    Map<String, dynamic>? customParameters,
  }) async {
    return {
      'request_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'product': {
        'id': productId,
        'name': productName,
        'category': options?.productCategory ?? 'general',
        'size': options?.productSize ?? 'M',
        'color': options?.productColor ?? 'default',
      },
      'avatar': {
        'id': avatar.id,
        'model_url': avatar.modelUrl,
        'measurements': avatar.measurements.toJson(),
        'attributes': avatar.attributes.toJson(),
        'adjustments': {
          'height_adjust': avatar.heightAdjust,
          'chest_size': avatar.chestSize,
          'waist_size': avatar.waistSize,
          'hip_size': avatar.hipSize,
        },
      },
      'render_config': {
        'quality': quality.name,
        'resolution': _getResolutionForQuality(quality),
        'format': 'glb',
        'optimization': {
          'target_platform': _getTargetPlatform(),
          'texture_compression': quality != ModelQualityLevel.high,
          'lod_levels': quality != ModelQualityLevel.high,
          'instancing': true,
        },
        'lighting': {
          'preset': avatar.lighting.name,
          'custom_settings': options?.customLighting ?? {},
        },
        'animation': {
          'enable_animation': true,
          'animation_name': 'idle_pose',
          'crossfade_duration': 1000,
        },
      },
      'output_options': {
        'include_textures': true,
        'include_materials': true,
        'include_animations': true,
        'optimize_for_mobile': quality == ModelQualityLevel.low,
        'generate_mipmaps': quality == ModelQualityLevel.high,
      },
      'custom_parameters': customParameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Map<String, int> _getResolutionForQuality(ModelQualityLevel quality) {
    switch (quality) {
      case ModelQualityLevel.low:
        return {'width': 512, 'height': 512};
      case ModelQualityLevel.medium:
        return {'width': 1024, 'height': 1024};
      case ModelQualityLevel.high:
        return {'width': 2048, 'height': 2048};
    }
  }
  
  String _getTargetPlatform() {
    // In a real implementation, detect actual platform
    return 'mobile';
  }
  
  Future<TryOnRenderResult> _processSuccessfulResponse(http.Response response) async {
    try {
      final responseData = jsonDecode(response.body);
      
      // Extract model data
      final modelData = _extractModelData(responseData);
      final metadata = _extractMetadata(responseData);
      
      // Validate the model
      final validation = await _modelLoadingService.validateModel(
        modelData,
        metadata['format'] ?? 'glb',
      );
      
      if (validation.isValid) {
        // Cache the model for future use
        await _cacheService.cacheModel(
          metadata['cache_key'] ?? 'unknown',
          modelData,
          modelUrl: metadata['model_url'],
          metadata: metadata,
        );
        
        return TryOnRenderResult.success(
          modelData: modelData,
          modelUrl: metadata['model_url'],
          isFromCache: false,
          metadata: metadata,
        );
      } else {
        return TryOnRenderResult.error(
          validation.error ?? 'Model validation failed',
        );
      }
      
    } catch (e) {
      return TryOnRenderResult.error('Failed to process response: $e');
    }
  }
  
  Uint8List _extractModelData(Map<String, dynamic> responseData) {
    // Extract model data based on response format
    if (responseData.containsKey('model_data_base64')) {
      return base64Decode(responseData['model_data_base64'] as String);
    } else if (responseData.containsKey('model_url')) {
      // In a real implementation, download from URL
      return Uint8List.fromList(List.generate(2048, (index) => index % 256));
    } else {
      // Fallback: return mock data
      return Uint8List.fromList(List.generate(2048, (index) => index % 256));
    }
  }
  
  Map<String, dynamic> _extractMetadata(Map<String, dynamic> responseData) {
    return responseData['metadata'] as Map<String, dynamic>? ?? {
      'format': 'glb',
      'size': 0,
      'quality': 'medium',
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
  
  void dispose() {
    _client.close();
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Result of try-on render request
class TryOnRenderResult {
  final bool isSuccess;
  final Uint8List? modelData;
  final String? modelUrl;
  final bool isFromCache;
  final Map<String, dynamic>? metadata;
  final String? error;
  final int? statusCode;
  
  TryOnRenderResult._({
    required this.isSuccess,
    this.modelData,
    this.modelUrl,
    this.isFromCache = false,
    this.metadata,
    this.error,
    this.statusCode,
  });
  
  factory TryOnRenderResult.success({
    required Uint8List modelData,
    String? modelUrl,
    bool isFromCache = false,
    Map<String, dynamic>? metadata,
  }) {
    return TryOnRenderResult._(
      isSuccess: true,
      modelData: modelData,
      modelUrl: modelUrl,
      isFromCache: isFromCache,
      metadata: metadata,
    );
  }
  
  factory TryOnRenderResult.error(String error, {int? statusCode}) {
    return TryOnRenderResult._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }
  
  double get modelSizeInMB => 
      modelData != null ? modelData!.lengthInBytes / (1024 * 1024) : 0.0;
  
  bool get hasModelData => modelData != null && modelData!.isNotEmpty;
  
  String? get format => metadata?['format'] as String?;
  
  int? get renderTime => metadata?['render_time_ms'] as int?;
}

/// Options for rendering configuration
class RenderOptions {
  final String? productCategory;
  final String? productSize;
  final String? productColor;
  final Map<String, dynamic>? customLighting;
  final bool enableAdvancedLighting;
  final bool enableShadows;
  final bool enableReflections;
  final Map<String, dynamic>? physicsSettings;
  
  const RenderOptions({
    this.productCategory,
    this.productSize,
    this.productColor,
    this.customLighting,
    this.enableAdvancedLighting = false,
    this.enableShadows = true,
    this.enableReflections = false,
    this.physicsSettings,
  });
}

/// Service availability result
class ServiceAvailabilityResult {
  final bool isAvailable;
  final String? status;
  final String? message;
  final Map<String, dynamic>? capabilities;
  final String? error;
  
  ServiceAvailabilityResult._({
    required this.isAvailable,
    this.status,
    this.message,
    this.capabilities,
    this.error,
  });
  
  factory ServiceAvailabilityResult.available({
    required String status,
    required String message,
    Map<String, dynamic>? capabilities,
  }) {
    return ServiceAvailabilityResult._(
      isAvailable: true,
      status: status,
      message: message,
      capabilities: capabilities,
    );
  }
  
  factory ServiceAvailabilityResult.unavailable(String error) {
    return ServiceAvailabilityResult._(
      isAvailable: false,
      error: error,
    );
  }
}

/// Queue status result
class QueueStatusResult {
  final bool isSuccess;
  final QueueStatus? status;
  final int? position;
  final int? estimatedWaitTime;
  final String? error;
  
  QueueStatusResult._({
    required this.isSuccess,
    this.status,
    this.position,
    this.estimatedWaitTime,
    this.error,
  });
  
  factory QueueStatusResult.fromJson(Map<String, dynamic> json) {
    return QueueStatusResult._(
      isSuccess: true,
      status: QueueStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => QueueStatus.unknown,
      ),
      position: json['position'] as int?,
      estimatedWaitTime: json['estimated_wait_time'] as int?,
    );
  }
  
  factory QueueStatusResult.error(String error) {
    return QueueStatusResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Queue status enum
enum QueueStatus {
  idle,
  processing,
  busy,
  overloaded,
  unknown,
}

/// Render history result
class RenderHistoryResult {
  final bool isSuccess;
  final List<RenderHistoryItem>? items;
  final int? totalCount;
  final int? page;
  final int? perPage;
  final String? error;
  
  RenderHistoryResult._({
    required this.isSuccess,
    this.items,
    this.totalCount,
    this.page,
    this.perPage,
    this.error,
  });
  
  factory RenderHistoryResult.fromJson(Map<String, dynamic> json) {
    return RenderHistoryResult._(
      isSuccess: true,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => RenderHistoryItem.fromJson(item))
          .toList(),
      totalCount: json['total_count'] as int?,
      page: json['page'] as int?,
      perPage: json['per_page'] as int?,
    );
  }
  
  factory RenderHistoryResult.error(String error) {
    return RenderHistoryResult._(
      isSuccess: false,
      error: error,
    );
  }
}

/// Individual render history item
class RenderHistoryItem {
  final String requestId;
  final String productId;
  final String productName;
  final String avatarId;
  final DateTime createdAt;
  final ModelQualityLevel quality;
  final RenderStatus status;
  final String? modelUrl;
  final int? renderTime;
  
  RenderHistoryItem({
    required this.requestId,
    required this.productId,
    required this.productName,
    required this.avatarId,
    required this.createdAt,
    required this.quality,
    required this.status,
    this.modelUrl,
    this.renderTime,
  });
  
  factory RenderHistoryItem.fromJson(Map<String, dynamic> json) {
    return RenderHistoryItem(
      requestId: json['request_id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      avatarId: json['avatar_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      quality: ModelQualityLevel.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => ModelQualityLevel.medium,
      ),
      status: RenderStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RenderStatus.pending,
      ),
      modelUrl: json['model_url'] as String?,
      renderTime: json['render_time'] as int?,
    );
  }
}

/// Render status enum
enum RenderStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}