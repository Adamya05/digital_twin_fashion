import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import '../models/avatar_model.dart';

/// Avatar Fallback Service
/// Handles 3D placeholder models, error recovery, offline mode, and retry mechanisms
class AvatarFallbackService {
  static const String _cacheKey = 'avatar_cache';
  static const String _fallbackModelsKey = 'fallback_models';
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  // Cache for loaded models and metadata
  final Map<String, AvatarCacheEntry> _modelCache = {};
  final Map<String, AvatarErrorLog> _errorLog = {};
  
  // Fallback model definitions
  final List<FallbackModel> _fallbackModels = [
    FallbackModel(
      id: 'placeholder_slim',
      name: 'Slim Placeholder',
      path: 'assets/avatars/fallbacks/placeholder_slim.glb',
      description: 'Generic slim body type placeholder',
      bodyType: 'Slim',
      suitableFor: ['Slim', 'Regular'],
    ),
    FallbackModel(
      id: 'placeholder_regular',
      name: 'Regular Placeholder',
      path: 'assets/avatars/fallbacks/placeholder_regular.glb',
      description: 'Generic regular body type placeholder',
      bodyType: 'Regular',
      suitableFor: ['Slim', 'Regular', 'Athletic'],
    ),
    FallbackModel(
      id: 'placeholder_athletic',
      name: 'Athletic Placeholder',
      path: 'assets/avatars/fallbacks/placeholder_athletic.glb',
      description: 'Generic athletic body type placeholder',
      bodyType: 'Athletic',
      suitableFor: ['Athletic', 'Regular'],
    ),
    FallbackModel(
      id: 'placeholder_plussize',
      name: 'Plus Size Placeholder',
      path: 'assets/avatars/fallbacks/placeholder_plussize.glb',
      description: 'Generic plus size body type placeholder',
      bodyType: 'PlusSize',
      suitableFor: ['PlusSize', 'Regular'],
    ),
  ];

  /// Load avatar with comprehensive fallback system
  Future<AvatarLoadResult> loadAvatarWithFallback(
    String avatarId, {
    AvatarLoadOptions options = const AvatarLoadOptions(),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Step 1: Check cache first
      if (options.useCache && _modelCache.containsKey(avatarId)) {
        final cached = _modelCache[avatarId]!;
        if (!cached.isExpired()) {
          stopwatch.stop();
          return AvatarLoadResult.success(
            avatar: cached.avatar,
            loadTime: stopwatch.elapsedMilliseconds,
            source: LoadSource.cache,
          );
        }
      }

      // Step 2: Try to load original avatar
      final loadResult = await _tryLoadOriginalAvatar(avatarId, options);
      if (loadResult.isSuccess) {
        _cacheAvatar(avatarId, loadResult.avatar!);
        return loadResult.copyWith(loadTime: stopwatch.elapsedMilliseconds);
      }

      // Step 3: Try fallback models
      final fallbackResult = await _tryFallbackModels(avatarId, loadResult.fallbackReason);
      if (fallbackResult.isSuccess) {
        return fallbackResult.copyWith(loadTime: stopwatch.elapsedMilliseconds);
      }

      // Step 4: Try 2D placeholder
      final placeholderResult = await _try2DPlaceholder(avatarId);
      return placeholderResult.copyWith(loadTime: stopwatch.elapsedMilliseconds);

    } catch (e) {
      stopwatch.stop();
      _logError(avatarId, 'loadAvatarWithFallback', e.toString());
      
      return AvatarLoadResult.failure(
        error: 'Failed to load avatar: $e',
        loadTime: stopwatch.elapsedMilliseconds,
        hasFallbacks: _fallbackModels.isNotEmpty,
      );
    }
  }

  /// Try to load the original avatar
  Future<AvatarLoadResult> _tryLoadOriginalAvatar(
    String avatarId,
    AvatarLoadOptions options,
  ) async {
    try {
      // In real implementation, this would try to load the actual GLB file
      final modelPath = 'assets/avatars/${avatarId}_model.glb';
      
      // Check if file exists
      final file = File(modelPath);
      if (!await file.exists()) {
        return AvatarLoadResult.failure(
          error: 'Model file not found',
          fallbackReason: FallbackReason.fileNotFound,
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > _maxCacheSize && options.checkFileSize) {
        return AvatarLoadResult.failure(
          error: 'Model file too large',
          fallbackReason: FallbackReason.fileTooLarge,
        );
      }

      // Validate file integrity
      final isValid = await _validateModelIntegrity(modelPath);
      if (!isValid) {
        return AvatarLoadResult.failure(
          error: 'Invalid model file',
          fallbackReason: FallbackReason.invalidModel,
        );
      }

      // Create avatar from loaded model
      final avatar = await _createAvatarFromModel(avatarId, modelPath);
      return AvatarLoadResult.success(
        avatar: avatar,
        loadTime: 0, // Will be set by caller
        source: LoadSource.original,
      );

    } catch (e) {
      return AvatarLoadResult.failure(
        error: 'Original avatar load failed: $e',
        fallbackReason: FallbackReason.loadError,
      );
    }
  }

  /// Try fallback models based on body type
  Future<AvatarLoadResult> _tryFallbackModels(
    String avatarId,
    FallbackReason? reason,
  ) async {
    for (final fallbackModel in _fallbackModels) {
      try {
        final fallbackAvatar = await _loadFallbackModel(fallbackModel, avatarId);
        if (fallbackAvatar != null) {
          return AvatarLoadResult.success(
            avatar: fallbackAvatar,
            loadTime: 0, // Will be set by caller
            source: LoadSource.fallback,
            fallbackModel: fallbackModel,
          );
        }
      } catch (e) {
        _logError(avatarId, 'fallback_${fallbackModel.id}', e.toString());
        continue;
      }
    }

    return AvatarLoadResult.failure(
      error: 'All fallback models failed',
      fallbackReason: FallbackReason.fallbackFailed,
    );
  }

  /// Try 2D placeholder as last resort
  Future<AvatarLoadResult> _try2DPlaceholder(String avatarId) async {
    try {
      final placeholderAvatar = await _create2DPlaceholder(avatarId);
      return AvatarLoadResult.success(
        avatar: placeholderAvatar,
        loadTime: 0, // Will be set by caller
        source: LoadSource.placeholder2D,
      );
    } catch (e) {
      return AvatarLoadResult.failure(
        error: '2D placeholder failed: $e',
        fallbackReason: FallbackReason.placeholderFailed,
      );
    }
  }

  /// Retry failed avatar loading with exponential backoff
  Future<AvatarLoadResult> retryLoadAvatar(
    String avatarId, {
    int maxRetries = _maxRetryAttempts,
    Duration? customDelay,
  }) async {
    final delay = customDelay ?? _retryDelay;
    AvatarLoadResult? lastResult;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      final result = await loadAvatarWithFallback(avatarId);
      lastResult = result;

      if (result.isSuccess) {
        return result;
      }

      if (attempt < maxRetries) {
        await Future.delayed(delay * attempt); // Exponential backoff
      }
    }

    return lastResult ?? AvatarLoadResult.failure(
      error: 'Max retry attempts exceeded',
      fallbackReason: FallbackReason.maxRetriesExceeded,
    );
  }

  /// Check if avatar is available in offline mode
  bool isAvatarAvailableOffline(String avatarId) {
    return _modelCache.containsKey(avatarId) && 
           !_modelCache[avatarId]!.isExpired();
  }

  /// Preload avatar for smooth transitions
  Future<bool> preloadAvatar(String avatarId) async {
    try {
      final result = await loadAvatarWithFallback(
        avatarId,
        options: const AvatarLoadOptions(useCache: true),
      );
      return result.isSuccess;
    } catch (e) {
      _logError(avatarId, 'preload', e.toString());
      return false;
    }
  }

  /// Preload multiple avatars
  Future<List<String>> preloadAvatars(List<String> avatarIds) async {
    final results = <String>[];
    final futures = avatarIds.map((id) => preloadAvatar(id));
    final preloaded = await Future.wait(futures);
    
    for (int i = 0; i < avatarIds.length; i++) {
      if (preloaded[i]) {
        results.add(avatarIds[i]);
      }
    }
    
    return results;
  }

  /// Get cache statistics
  AvatarCacheStats getCacheStats() {
    final now = DateTime.now();
    int totalSize = 0;
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _modelCache.values) {
      totalSize += entry.size;
      if (entry.isExpired()) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return AvatarCacheStats(
      totalEntries: _modelCache.length,
      validEntries: validCount,
      expiredEntries: expiredCount,
      totalSizeBytes: totalSize,
      oldestEntry: _modelCache.values.isNotEmpty
          ? _modelCache.values.map((e) => e.lastAccessed).reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      newestEntry: _modelCache.values.isNotEmpty
          ? _modelCache.values.map((e) => e.lastAccessed).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    );
  }

  /// Clear expired cache entries
  void clearExpiredCache() {
    final now = DateTime.now();
    _modelCache.removeWhere((key, entry) => entry.isExpired());
  }

  /// Clear all cache
  void clearAllCache() {
    _modelCache.clear();
  }

  /// Get error history for debugging
  List<AvatarErrorLog> getErrorHistory({int limit = 50}) {
    final logs = _errorLog.values.toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs.take(limit).toList();
  }

  /// Get available fallback models
  List<FallbackModel> getAvailableFallbackModels() {
    return List.unmodifiable(_fallbackModels);
  }

  // Private helper methods

  Future<bool> _validateModelIntegrity(String modelPath) async {
    try {
      // In real implementation, this would validate GLB file structure
      final file = File(modelPath);
      if (!await file.exists()) return false;
      
      // Basic file size check
      final size = await file.length();
      if (size < 1024 || size > _maxCacheSize) return false;
      
      // Check file header for GLB signature
      final bytes = await file.readAsBytes();
      if (bytes.length < 12) return false;
      
      // GLB files start with 'glTF' magic number
      final signature = String.fromCharCodes(bytes.sublist(0, 4));
      return signature == 'glTF' || signature.contains('glTF');
      
    } catch (e) {
      return false;
    }
  }

  Future<Avatar> _createAvatarFromModel(String avatarId, String modelPath) async {
    // In real implementation, this would extract metadata from GLB file
    // For now, create a mock avatar based on the model
    
    return Avatar(
      id: avatarId,
      name: 'Avatar $avatarId',
      modelUrl: modelPath,
      thumbnailUrl: modelPath.replaceAll('.glb', '_thumb.jpg'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      measurements: AvatarMeasurements.empty(),
      attributes: AvatarAttributes.empty(),
      metadata: AvatarMetadata(
        fileSize: 0,
        fileFormat: 'glb',
        polyCount: 0,
        modelVersion: '1.0',
        textures: [],
        isOptimized: true,
        qualityLevel: 'Medium',
        lastUsed: DateTime.now(),
      ),
    );
  }

  Future<Avatar?> _loadFallbackModel(FallbackModel fallbackModel, String originalId) async {
    try {
      // Try to load the fallback GLB file
      final file = File(fallbackModel.path);
      if (!await file.exists()) return null;

      final fallbackAvatar = Avatar(
        id: '${originalId}_fallback_${fallbackModel.id}',
        name: '${fallbackModel.name} (Fallback)',
        modelUrl: fallbackModel.path,
        thumbnailUrl: fallbackModel.path.replaceAll('.glb', '_thumb.png'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        measurements: _generateMeasurementsForFallback(fallbackModel),
        attributes: AvatarAttributes(
          bodyType: fallbackModel.bodyType,
          ethnicity: 'Mixed',
          skinTone: 'Medium',
          hairColor: 'Brown',
          hairStyle: 'Generic',
          eyeColor: 'Brown',
          gender: 'Non-binary',
          age: 25,
        ),
        metadata: AvatarMetadata(
          fileSize: 1024000, // 1MB typical fallback
          fileFormat: 'glb',
          polyCount: 2000, // Low poly for fallback
          modelVersion: '1.0_fallback',
          textures: ['diffuse'],
          isOptimized: true,
          qualityLevel: 'Medium',
          lastUsed: DateTime.now(),
        ),
        tags: ['fallback', 'placeholder'],
        description: fallbackModel.description,
      );

      return fallbackAvatar;
    } catch (e) {
      return null;
    }
  }

  AvatarMeasurements _generateMeasurementsForFallback(FallbackModel model) {
    // Generate generic measurements based on body type
    switch (model.bodyType) {
      case 'Slim':
        return AvatarMeasurements(
          height: 170,
          weight: 60,
          chest: 88,
          waist: 68,
          hips: 90,
          shoulders: 42,
          arms: 62,
          legs: 82,
        );
      case 'Regular':
        return AvatarMeasurements(
          height: 175,
          weight: 70,
          chest: 95,
          waist: 75,
          hips: 95,
          shoulders: 45,
          arms: 65,
          legs: 85,
        );
      case 'Athletic':
        return AvatarMeasurements(
          height: 178,
          weight: 75,
          chest: 102,
          waist: 78,
          hips: 95,
          shoulders: 48,
          arms: 68,
          legs: 88,
        );
      case 'PlusSize':
        return AvatarMeasurements(
          height: 170,
          weight: 85,
          chest: 105,
          waist: 85,
          hips: 105,
          shoulders: 46,
          arms: 66,
          legs: 83,
        );
      default:
        return AvatarMeasurements.empty();
    }
  }

  Future<Avatar> _create2DPlaceholder(String avatarId) async {
    return Avatar(
      id: '${avatarId}_2d_placeholder',
      name: '2D Placeholder',
      modelUrl: '', // No 3D model
      thumbnailUrl: 'assets/avatars/fallbacks/placeholder_2d.png',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      measurements: AvatarMeasurements.empty(),
      attributes: AvatarAttributes(
        bodyType: 'Regular',
        ethnicity: 'Mixed',
        skinTone: 'Medium',
        hairColor: 'Brown',
        hairStyle: 'Generic',
        eyeColor: 'Brown',
        gender: 'Non-binary',
        age: 25,
      ),
      metadata: AvatarMetadata(
        fileSize: 51200, // 50KB for 2D image
        fileFormat: 'png',
        polyCount: 0,
        modelVersion: '2d_1.0',
        textures: [],
        isOptimized: true,
        qualityLevel: 'Low',
        lastUsed: DateTime.now(),
      ),
      tags: ['2d', 'placeholder'],
      description: '2D placeholder avatar when 3D model is unavailable',
    );
  }

  void _cacheAvatar(String avatarId, Avatar avatar) {
    _modelCache[avatarId] = AvatarCacheEntry(
      avatar: avatar,
      lastAccessed: DateTime.now(),
      size: avatar.metadata.fileSize.toInt(),
    );

    // Implement cache size limits
    _enforceCacheSizeLimit();
  }

  void _enforceCacheSizeLimit() {
    var totalSize = _modelCache.values.fold<int>(0, (sum, entry) => sum + entry.size);
    
    if (totalSize > _maxCacheSize) {
      // Remove oldest entries first
      final entries = _modelCache.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      for (final entry in entries) {
        _modelCache.remove(entry.key);
        totalSize -= entry.value.size;
        if (totalSize <= _maxCacheSize) break;
      }
    }
  }

  void _logError(String avatarId, String operation, String error) {
    _errorLog['$avatarId:$operation'] = AvatarErrorLog(
      avatarId: avatarId,
      operation: operation,
      error: error,
      timestamp: DateTime.now(),
    );

    // Keep only last 100 error logs
    if (_errorLog.length > 100) {
      final oldestKey = _errorLog.keys.first;
      _errorLog.remove(oldestKey);
    }
  }
}

// Supporting classes and enums

class AvatarLoadOptions {
  final bool useCache;
  final bool checkFileSize;
  final bool enableRetry;
  final Duration? timeout;

  const AvatarLoadOptions({
    this.useCache = true,
    this.checkFileSize = true,
    this.enableRetry = true,
    this.timeout,
  });
}

class AvatarLoadResult {
  final bool isSuccess;
  final Avatar? avatar;
  final String? error;
  final FallbackReason? fallbackReason;
  final LoadSource? source;
  final FallbackModel? fallbackModel;
  final int loadTime;
  final bool hasFallbacks;

  AvatarLoadResult._({
    required this.isSuccess,
    this.avatar,
    this.error,
    this.fallbackReason,
    this.source,
    this.fallbackModel,
    required this.loadTime,
    this.hasFallbacks = false,
  });

  factory AvatarLoadResult.success({
    required Avatar avatar,
    required int loadTime,
    required LoadSource source,
    FallbackModel? fallbackModel,
  }) {
    return AvatarLoadResult._(
      isSuccess: true,
      avatar: avatar,
      loadTime: loadTime,
      source: source,
      fallbackModel: fallbackModel,
      hasFallbacks: fallbackModel != null,
    );
  }

  factory AvatarLoadResult.failure({
    required String error,
    required int loadTime,
    required FallbackReason fallbackReason,
  }) {
    return AvatarLoadResult._(
      isSuccess: false,
      error: error,
      loadTime: loadTime,
      fallbackReason: fallbackReason,
    );
  }

  AvatarLoadResult copyWith({int? loadTime}) {
    if (isSuccess) {
      return AvatarLoadResult.success(
        avatar: avatar!,
        loadTime: loadTime ?? this.loadTime,
        source: source!,
        fallbackModel: fallbackModel,
      );
    } else {
      return AvatarLoadResult.failure(
        error: error!,
        loadTime: loadTime ?? this.loadTime,
        fallbackReason: fallbackReason!,
      );
    }
  }
}

enum FallbackReason {
  fileNotFound,
  fileTooLarge,
  invalidModel,
  loadError,
  fallbackFailed,
  placeholderFailed,
  maxRetriesExceeded,
}

enum LoadSource {
  cache,
  original,
  fallback,
  placeholder2D,
}

class FallbackModel {
  final String id;
  final String name;
  final String path;
  final String description;
  final String bodyType;
  final List<String> suitableFor;

  FallbackModel({
    required this.id,
    required this.name,
    required this.path,
    required this.description,
    required this.bodyType,
    required this.suitableFor,
  });
}

class AvatarCacheEntry {
  final Avatar avatar;
  final DateTime lastAccessed;
  final int size;

  AvatarCacheEntry({
    required this.avatar,
    required this.lastAccessed,
    required this.size,
  });

  bool isExpired({Duration expiry = const Duration(hours: 24)}) {
    return DateTime.now().difference(lastAccessed) > expiry;
  }
}

class AvatarErrorLog {
  final String avatarId;
  final String operation;
  final String error;
  final DateTime timestamp;

  AvatarErrorLog({
    required this.avatarId,
    required this.operation,
    required this.error,
    required this.timestamp,
  });
}

class AvatarCacheStats {
  final int totalEntries;
  final int validEntries;
  final int expiredEntries;
  final int totalSizeBytes;
  final DateTime? oldestEntry;
  final DateTime? newestEntry;

  AvatarCacheStats({
    required this.totalEntries,
    required this.validEntries,
    required this.expiredEntries,
    required this.totalSizeBytes,
    this.oldestEntry,
    this.newestEntry,
  });

  String get totalSizeFormatted {
    if (totalSizeBytes < 1024) return '$totalSizeBytes B';
    if (totalSizeBytes < 1024 * 1024) return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}