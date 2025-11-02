import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../services/mock_tryon_rendering_api.dart';
import '../services/product_model_service.dart';
import '../services/tryon_configuration_service.dart';
import '../services/quality_assurance_service.dart';

/// Mock API server for try-on rendering simulation
class MockTryOnAPIServer {
  static MockTryOnAPIServer? _instance;
  static MockTryOnAPIServer get instance => _instance ??= MockTryOnAPIServer._internal();
  
  factory MockTryOnAPIServer() => instance;
  MockTryOnAPIServer._internal();

  static const String _basePath = '/api';
  late final HttpServer _server;
  bool _isRunning = false;
  
  /// Start the mock API server
  Future<void> start({int port = 8080}) async {
    if (_isRunning) {
      print('API Server is already running on port $port');
      return;
    }
    
    // Initialize services
    await _initializeServices();
    
    // Create middleware pipeline
    final pipeline = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(handleCors)
        .addMiddleware(handleAuth)
        .addHandler(_handleRequest);
    
    // Start server
    _server = await shelf_io.serve(pipeline, 'localhost', port);
    _isRunning = true;
    
    print('Mock Try-On API Server running on http://localhost:$port');
    print('Available endpoints:');
    print('  POST $_basePath/render/tryon - Submit try-on rendering job');
    print('  GET $_basePath/render/status/{jobId} - Get rendering job status');
    print('  GET $_basePath/render/result/{jobId} - Get rendering result');
    print('  GET $_basePath/products/models/{productId} - Get product model');
    print('  GET $_basePath/products/metadata/{productId} - Get product metadata');
    print('  GET $_basePath/avatar/compatibility/{avatarType} - Get avatar compatibility');
    print('  POST $_basePath/quality/feedback - Submit quality feedback');
    print('  GET $_basePath/performance/metrics - Get performance metrics');
    print('  GET $_basePath/queue/stats - Get rendering queue statistics');
  }
  
  /// Stop the mock API server
  Future<void> stop() async {
    if (_isRunning && _server != null) {
      await _server.close();
      _isRunning = false;
      print('Mock Try-On API Server stopped');
    }
  }
  
  bool get isRunning => _isRunning;
  
  Future<void> _initializeServices() async {
    // Initialize all required services
    await ProductModelService.instance.initialize();
    await TryOnConfigurationService.instance.initialize();
    await QualityAssuranceService.instance.initialize();
    await MockTryOnRenderingAPI.instance.initialize();
  }
  
  /// Main request handler
  Future<Response> _handleRequest(Request request) async {
    final path = request.url.path;
    final method = request.method;
    
    try {
      // Route requests
      if (path.startsWith('$_basePath/render/tryon') && method == 'POST') {
        return await _handleSubmitRender(request);
      } else if (path.startsWith('$_basePath/render/status/') && method == 'GET') {
        return await _handleGetRenderStatus(request);
      } else if (path.startsWith('$_basePath/render/result/') && method == 'GET') {
        return await _handleGetRenderResult(request);
      } else if (path.startsWith('$_basePath/products/models/') && method == 'GET') {
        return await _handleGetProductModel(request);
      } else if (path.startsWith('$_basePath/products/metadata/') && method == 'GET') {
        return await _handleGetProductMetadata(request);
      } else if (path.startsWith('$_basePath/avatar/compatibility/') && method == 'GET') {
        return await _handleGetCompatibility(request);
      } else if (path.startsWith('$_basePath/quality/feedback') && method == 'POST') {
        return await _handleSubmitFeedback(request);
      } else if (path.startsWith('$_basePath/performance/metrics') && method == 'GET') {
        return await _handleGetPerformanceMetrics(request);
      } else if (path.startsWith('$_basePath/queue/stats') && method == 'GET') {
        return await _handleGetQueueStats(request);
      } else {
        return _createNotFoundResponse('Endpoint not found: $method $path');
      }
    } catch (e) {
      print('Error handling request: $e');
      return _createErrorResponse('Internal server error: $e');
    }
  }
  
  /// Handle try-on render submission
  Future<Response> _handleSubmitRender(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);
      
      // Validate request data
      final validation = _validateRenderRequest(data);
      if (!validation.isValid) {
        return _createBadRequestResponse(validation.message);
      }
      
      // Submit rendering job
      final jobId = await MockTryOnRenderingAPI.instance.submitTryOnRender(
        avatarId: data['avatar_id'],
        avatarId: data['avatar_id'],
        avatarType: AvatarType.values.firstWhere(
          (type) => type.toString() == 'AvatarType.${data['avatar_type']}',
        ),
        productIds: List<String>.from(data['product_ids']),
        customParams: data['custom_params'],
        isBatch: data['is_batch'] ?? false,
      );
      
      return _createSuccessResponse({
        'job_id': jobId,
        'status': 'submitted',
        'message': 'Try-on rendering job submitted successfully',
        'estimated_duration': '5-7 seconds',
      });
    } catch (e) {
      return _createErrorResponse('Failed to submit render job: $e');
    }
  }
  
  /// Handle render status request
  Future<Response> _handleGetRenderStatus(Request request) async {
    try {
      final jobId = request.url.path.split('/').last;
      final job = MockTryOnRenderingAPI.instance.getRenderJob(jobId);
      
      if (job == null) {
        return _createNotFoundResponse('Render job not found: $jobId');
      }
      
      return _createSuccessResponse({
        'job_id': jobId,
        'status': job.status.toString().split('.').last,
        'progress': job.progress,
        'current_stage': job.currentStage,
        'submitted_at': job.submittedAt.toIso8601String(),
        'started_at': job.startedAt?.toIso8601String(),
        'completed_at': job.completedAt?.toIso8601String(),
        'estimated_duration': job.estimatedDuration.inSeconds,
        'product_count': job.productIds.length,
      });
    } catch (e) {
      return _createErrorResponse('Failed to get render status: $e');
    }
  }
  
  /// Handle render result request
  Future<Response> _handleGetRenderResult(Request request) async {
    try {
      final jobId = request.url.path.split('/').last;
      final result = MockTryOnRenderingAPI.instance.getRenderResult(jobId);
      
      if (result == null) {
        return _createNotFoundResponse('Render result not found: $jobId');
      }
      
      if (!result.isSuccess) {
        return _createErrorResponse('Render failed for job: $jobId');
      }
      
      // Return result with image data (base64 encoded)
      final imageBase64 = base64Encode(result.imageData);
      
      return _createSuccessResponse({
        'job_id': jobId,
        'status': 'completed',
        'image_data': 'data:image/jpeg;base64,$imageBase64',
        'metadata': result.metadata,
        'created_at': result.createdAt.toIso8601String(),
        'file_size': result.imageData.length,
      });
    } catch (e) {
      return _createErrorResponse('Failed to get render result: $e');
    }
  }
  
  /// Handle product model request
  Future<Response> _handleGetProductModel(Request request) async {
    try {
      final productId = request.url.path.split('/').last;
      final modelData = await ProductModelService.instance.loadModel(productId);
      
      if (modelData == null) {
        return _createNotFoundResponse('Product model not found: $productId');
      }
      
      // Return model data as base64
      final modelBase64 = base64Encode(modelData);
      
      return _createSuccessResponse({
        'product_id': productId,
        'model_data': 'data:application/octet-stream;base64,$modelBase64',
        'file_size': modelData.length,
        'format': 'glb',
      });
    } catch (e) {
      return _createErrorResponse('Failed to get product model: $e');
    }
  }
  
  /// Handle product metadata request
  Future<Response> _handleGetProductMetadata(Request request) async {
    try {
      final productId = request.url.path.split('/').last;
      final metadata = await ProductModelService.instance.getModelMetadata(productId);
      
      return _createSuccessResponse({
        'product_id': productId,
        'metadata': metadata,
      });
    } catch (e) {
      return _createErrorResponse('Failed to get product metadata: $e');
    }
  }
  
  /// Handle avatar compatibility request
  Future<Response> _handleGetCompatibility(Request request) async {
    try {
      final avatarType = request.url.path.split('/').last;
      final avatarTypeEnum = AvatarType.values.firstWhere(
        (type) => type.toString() == 'AvatarType.$avatarType',
      );
      
      // Get all products and check compatibility
      final allProducts = [
        'tshirt_men_basic_black',
        'tshirt_men_basic_white',
        'dress_women_casual_blue',
        'jacket_men_blazer_black',
        'sports_bra_women_black',
        'jeans_men_classic_blue',
      ];
      
      final compatibleProducts = <String>[];
      final service = ProductModelService.instance;
      
      for (final productId in allProducts) {
        final isCompatible = await service.isCompatible(productId, avatarTypeEnum);
        if (isCompatible) {
          compatibleProducts.add(productId);
        }
      }
      
      return _createSuccessResponse({
        'avatar_type': avatarType,
        'compatible_products': compatibleProducts,
        'total_compatible': compatibleProducts.length,
      });
    } catch (e) {
      return _createErrorResponse('Failed to get compatibility data: $e');
    }
  }
  
  /// Handle quality feedback submission
  Future<Response> _handleSubmitFeedback(Request request) async {
    try {
      final body = await request.readAsString();
      final data = json.decode(body);
      
      QualityAssuranceService.instance.submitUserFeedback(
        renderId: data['render_id'],
        rating: RenderQualityRating.values.firstWhere(
          (rating) => rating.toString() == 'RenderQualityRating.${data['rating']}',
        ),
        comments: data['comments'],
        issues: data['issues'] != null ? List<String>.from(data['issues']) : null,
      );
      
      return _createSuccessResponse({
        'status': 'submitted',
        'message': 'Quality feedback submitted successfully',
      });
    } catch (e) {
      return _createErrorResponse('Failed to submit feedback: $e');
    }
  }
  
  /// Handle performance metrics request
  Future<Response> _handleGetPerformanceMetrics(Request request) async {
    try {
      final analytics = QualityAssuranceService.instance.getPerformanceAnalytics();
      
      return _createSuccessResponse({
        'average_user_rating': analytics.averageUserRating,
        'average_quality_score': analytics.averageQualityScore,
        'total_quality_adjustments': analytics.totalQualityAdjustments,
        'auto_adjustment_rate': analytics.autoAdjustmentRate,
        'recent_adjustments': analytics.qualityAdjustments
            .take(5)
            .map((e) => {
                  'timestamp': e.timestamp.toIso8601String(),
                  'type': e.type,
                  'reason': e.reason,
                })
            .toList(),
      });
    } catch (e) {
      return _createErrorResponse('Failed to get performance metrics: $e');
    }
  }
  
  /// Handle queue statistics request
  Future<Response> _handleGetQueueStats(Request request) async {
    try {
      final stats = MockTryOnRenderingAPI.instance.getQueueStats();
      
      return _createSuccessResponse({
        'total_queued': stats.totalQueued,
        'total_rendering': stats.totalRendering,
        'total_completed': stats.totalCompleted,
        'total_failed': stats.totalFailed,
        'average_render_time': stats.averageRenderTime.inSeconds,
        'success_rate': stats.successRate,
        'success_rate_percentage': (stats.successRate * 100).toStringAsFixed(1),
      });
    } catch (e) {
      return _createErrorResponse('Failed to get queue stats: $e');
    }
  }
  
  /// Request validation
  _RequestValidation _validateRenderRequest(Map<String, dynamic> data) {
    if (!data.containsKey('avatar_id')) {
      return _RequestValidation(false, 'Missing avatar_id');
    }
    
    if (!data.containsKey('avatar_type')) {
      return _RequestValidation(false, 'Missing avatar_type');
    }
    
    if (!data.containsKey('product_ids') || 
        data['product_ids'] is! List || 
        (data['product_ids'] as List).isEmpty) {
      return _RequestValidation(false, 'Missing or invalid product_ids');
    }
    
    // Validate avatar type
    try {
      AvatarType.values.firstWhere(
        (type) => type.toString() == 'AvatarType.${data['avatar_type']}',
      );
    } catch (e) {
      return _RequestValidation(false, 'Invalid avatar_type: ${data['avatar_type']}');
    }
    
    return _RequestValidation(true, 'Valid');
  }
  
  /// CORS middleware
  static Middleware handleCors({String origin = '*'}) {
    return (innerHandler) {
      return (request) async {
        final response = await innerHandler(request);
        return response.change(headers: {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        });
      };
    };
  }
  
  /// Authentication middleware
  static Middleware handleAuth() {
    return (innerHandler) {
      return (request) async {
        // Simple mock authentication
        final authHeader = request.headers['authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          return Response.unauthorized('Missing or invalid authorization');
        }
        
        return await innerHandler(request);
      };
    };
  }
  
  /// Success response helper
  Response _createSuccessResponse(Map<String, dynamic> data) {
    return Response.ok(
      json.encode({
        'success': true,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  /// Error response helper
  Response _createErrorResponse(String message) {
    return Response.internalServerError(
      body: json.encode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  /// Bad request response helper
  Response _createBadRequestResponse(String message) {
    return Response.badRequest(
      body: json.encode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
  
  /// Not found response helper
  Response _createNotFoundResponse(String message) {
    return Response.notFound(
      json.encode({
        'success': false,
        'error': message,
        'timestamp': DateTime.now().toIso8601String(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// Request validation result
class _RequestValidation {
  final bool isValid;
  final String message;
  
  _RequestValidation(this.isValid, this.message);
}

// Add the missing import for AvatarType
import '../models/avatar_model.dart';