import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Model quality settings for optimization
enum ModelQuality {
  low(0.5, 'Low', 512),
  medium(0.75, 'Medium', 1024),
  high(1.0, 'High', 2048),
  ultra(1.5, 'Ultra', 4096);

  const ModelQuality(this.compression, this.displayName, this.maxResolution);
  final double compression;
  final String displayName;
  final int maxResolution;
}

/// Model loading state
enum ModelLoadState {
  idle,
  loading,
  loaded,
  error,
  cached,
}

/// 3D Model management service
/// Handles loading, caching, validation, and disposal of 3D models
class ModelService {
  static final ModelService _instance = ModelService._internal();
  factory ModelService() => _instance;
  ModelService._internal();

  static const String _cacheKey = 'model_cache';
  static const String _maxCacheSizeKey = 'max_cache_size';
  static const int _defaultMaxCacheSize = 500 * 1024 * 1024; // 500MB

  // Singleton instances
  late SharedPreferences _prefs;
  final Map<String, ModelCacheEntry> _cache = {};
  final StreamController<ModelLoadEvent> _eventController = StreamController.broadcast();
  
  // Cache management
  int _maxCacheSize = _defaultMaxCacheSize;
  int _currentCacheSize = 0;

  /// Stream of model loading events
  Stream<ModelLoadEvent> get events => _eventController.stream;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _maxCacheSize = _prefs.getInt(_maxCacheSizeKey) ?? _defaultMaxCacheSize;
    
    // Load cached models metadata
    await _loadCacheMetadata();
    
    // Clean up old cache entries
    await _cleanupExpiredCache();
  }

  /// Load a 3D model with caching and validation
  /// 
  /// [modelUrl] - URL or asset path to the 3D model
  /// [quality] - Model quality setting
  /// [forceReload] - Force reload from network even if cached
  Future<ModelLoadResult> loadModel({
    required String modelUrl,
    ModelQuality quality = ModelQuality.medium,
    bool forceReload = false,
    String? posterImage,
  }) async {
    try {
      final cacheKey = _generateCacheKey(modelUrl, quality);
      
      // Check cache first
      if (!forceReload && _cache.containsKey(cacheKey)) {
        final entry = _cache[cacheKey]!;
        if (entry.isValid) {
          _emitEvent(ModelLoadEvent.cached(modelUrl, entry.filePath));
          return ModelLoadResult.success(
            filePath: entry.filePath,
            isFromCache: true,
            loadTime: Duration.zero,
          );
        }
      }

      // Start loading
      _emitEvent(ModelLoadEvent.started(modelUrl));
      
      final stopwatch = Stopwatch()..start();
      
      // Download or load model
      final filePath = await _downloadOrLoadModel(modelUrl, quality, cacheKey);
      
      stopwatch.stop();
      
      // Update cache
      await _updateCache(cacheKey, filePath, modelUrl);
      
      _emitEvent(ModelLoadEvent.completed(modelUrl, filePath));
      
      return ModelLoadResult.success(
        filePath: filePath,
        isFromCache: false,
        loadTime: stopwatch.elapsed,
      );
      
    } catch (e) {
      final error = ModelLoadError.modelLoadFailed(e.toString());
      _emitEvent(ModelLoadEvent.error(modelUrl, error));
      return ModelLoadResult.error(error);
    }
  }

  /// Preload a model for smooth transitions
  Future<void> preloadModel({
    required String modelUrl,
    ModelQuality quality = ModelQuality.medium,
  }) async {
    // Load in background without blocking
    _loadModelInBackground(modelUrl, quality);
  }

  /// Validate a 3D model file
  Future<ModelValidationResult> validateModel(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ModelValidationResult.error('File does not exist');
      }

      final size = await file.length();
      if (size == 0) {
        return ModelValidationResult.error('File is empty');
      }

      // Check file extension
      final extension = path.extension(filePath).toLowerCase();
      if (!['.glb', '.gltf', '.obj', '.fbx'].contains(extension)) {
        return ModelValidationResult.error('Unsupported file format: $extension');
      }

      // Check if file is too large (> 50MB)
      if (size > 50 * 1024 * 1024) {
        return ModelValidationResult.error('File too large: ${(size / 1024 / 1024).toStringAsFixed(1)}MB');
      }

      // Basic format validation
      final content = await file.readAsBytes();
      final isValidFormat = _validateModelFormat(content, extension);
      
      if (!isValidFormat) {
        return ModelValidationResult.error('Invalid 3D model format');
      }

      return ModelValidationResult.valid(size);
    } catch (e) {
      return ModelValidationResult.error('Validation failed: $e');
    }
  }

  /// Get cache statistics
  CacheStatistics get cacheStatistics => CacheStatistics(
    cachedModels: _cache.length,
    totalCacheSize: _currentCacheSize,
    maxCacheSize: _maxCacheSize,
    cacheUtilization: _currentCacheSize / _maxCacheSize,
  );

  /// Clear all cached models
  Future<void> clearCache() async {
    for (final entry in _cache.values) {
      try {
        await entry.delete();
      } catch (e) {
        // Log error but continue
        print('Failed to delete cached model: $e');
      }
    }
    
    _cache.clear();
    _currentCacheSize = 0;
    await _saveCacheMetadata();
    
    _emitEvent(ModelLoadEvent.cacheCleared());
  }

  /// Set maximum cache size
  Future<void> setMaxCacheSize(int sizeInBytes) async {
    _maxCacheSize = sizeInBytes;
    await _prefs.setInt(_maxCacheSizeKey, sizeInBytes);
    
    // Trigger cache cleanup if needed
    if (_currentCacheSize > _maxCacheSize) {
      await _cleanupCacheIfNeeded();
    }
  }

  /// Dispose resources and close streams
  void dispose() {
    _eventController.close();
  }

  // Private methods

  Future<void> _loadModelInBackground(String modelUrl, ModelQuality quality) async {
    try {
      await loadModel(modelUrl: modelUrl, quality: quality);
    } catch (e) {
      // Background loading failed, ignore
    }
  }

  String _generateCacheKey(String modelUrl, ModelQuality quality) {
    final uri = Uri.parse(modelUrl);
    final fileName = path.basenameWithoutExtension(uri.path);
    return '${fileName}_${quality.name}_${uri.pathSegments.last}';
  }

  Future<String> _downloadOrLoadModel(
    String modelUrl,
    ModelQuality quality,
    String cacheKey,
  ) async {
    if (modelUrl.startsWith('assets/')) {
      return await _loadFromAssets(modelUrl);
    } else if (modelUrl.startsWith('http')) {
      return await _downloadFromNetwork(modelUrl, cacheKey, quality);
    } else {
      throw Exception('Unsupported model URL format');
    }
  }

  Future<String> _loadFromAssets(String assetPath) async {
    try {
      // For assets, we'll just return the asset path
      // In a real implementation, you might want to copy to cache
      return assetPath;
    } catch (e) {
      throw Exception('Failed to load asset: $e');
    }
  }

  Future<String> _downloadFromNetwork(
    String url,
    String cacheKey,
    ModelQuality quality,
  ) async {
    final directory = await _getCacheDirectory();
    final filePath = path.join(directory.path, cacheKey);
    
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download model: ${response.statusCode}');
    }

    // Apply quality optimization if needed
    Uint8List content = response.bodyBytes;
    
    // TODO: Add model optimization logic here
    // For now, just save as-is
    
    final file = File(filePath);
    await file.writeAsBytes(content);
    
    return filePath;
  }

  Future<Directory> _getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(directory.path, 'model_cache'));
    
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }

  Future<void> _updateCache(
    String cacheKey,
    String filePath,
    String originalUrl,
  ) async {
    final file = File(filePath);
    final size = await file.length();
    
    final entry = ModelCacheEntry(
      key: cacheKey,
      filePath: filePath,
      originalUrl: originalUrl,
      size: size,
      timestamp: DateTime.now(),
    );
    
    _cache[cacheKey] = entry;
    _currentCacheSize += size;
    
    await _saveCacheMetadata();
    await _cleanupCacheIfNeeded();
  }

  Future<void> _cleanupCacheIfNeeded() async {
    while (_currentCacheSize > _maxCacheSize && _cache.isNotEmpty) {
      // Remove oldest entry
      final oldestKey = _cache.values
          .reduce((a, b) => a.timestamp.isBefore(b.timestamp) ? a : b)
          .key;
      
      final entry = _cache[oldestKey]!;
      await entry.delete();
      _cache.remove(oldestKey);
      _currentCacheSize -= entry.size;
    }
    
    await _saveCacheMetadata();
  }

  Future<void> _cleanupExpiredCache() async {
    final now = DateTime.now();
    final expiry = const Duration(days: 30);
    
    final expiredKeys = _cache.entries
        .where((entry) => now.difference(entry.value.timestamp) > expiry)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      final entry = _cache[key]!;
      await entry.delete();
      _cache.remove(key);
      _currentCacheSize -= entry.size;
    }
    
    if (expiredKeys.isNotEmpty) {
      await _saveCacheMetadata();
    }
  }

  Future<void> _loadCacheMetadata() async {
    final cacheJson = _prefs.getString(_cacheKey);
    if (cacheJson != null) {
      // Parse cached metadata
      // This is a simplified version - in production, you'd want proper JSON parsing
      // For now, we'll just reset the cache
      _cache.clear();
      _currentCacheSize = 0;
    }
  }

  Future<void> _saveCacheMetadata() async {
    // Save cache metadata to SharedPreferences
    // This is simplified - in production, you'd want proper JSON serialization
    await _prefs.setString(_cacheKey, '{}');
  }

  void _emitEvent(ModelLoadEvent event) {
    _eventController.add(event);
  }

  bool _validateModelFormat(Uint8List content, String extension) {
    // Basic format validation
    final header = content.sublist(0, min(100, content.length));
    
    switch (extension) {
      case '.glb':
        // GLB files start with 'glTF' magic number
        return String.fromCharCodes(header.sublist(0, 4)) == 'glTF';
      case '.gltf':
        // GLTF files are JSON
        final text = String.fromCharCodes(header);
        return text.contains('{') && text.contains('"');
      case '.obj':
        // OBJ files start with 'o' or 'v' commands
        final text = String.fromCharCodes(header);
        return text.contains('o ') || text.contains('v ');
      case '.fbx':
        // FBX files have specific header
        return content.length >= 30 && 
               content[0] == 0x4B && content[1] == 0x20 && 
               content[2] == 0x3A && content[3] == 0x20;
      default:
        return false;
    }
  }
}

// Supporting classes

class ModelLoadResult {
  final bool isSuccess;
  final String? filePath;
  final ModelLoadError? error;
  final bool isFromCache;
  final Duration? loadTime;

  ModelLoadResult._({
    required this.isSuccess,
    this.filePath,
    this.error,
    required this.isFromCache,
    this.loadTime,
  });

  factory ModelLoadResult.success({
    required String filePath,
    required bool isFromCache,
    required Duration loadTime,
  }) => ModelLoadResult._(
    isSuccess: true,
    filePath: filePath,
    isFromCache: isFromCache,
    loadTime: loadTime,
  );

  factory ModelLoadResult.error(ModelLoadError error) => ModelLoadResult._(
    isSuccess: false,
    error: error,
    isFromCache: false,
  );
}

class ModelLoadError {
  final String message;
  final String? code;

  ModelLoadError._({required this.message, this.code});

  factory ModelLoadError.modelLoadFailed(String message) =>
      ModelLoadError._(message: message);

  @override
  String toString() => 'ModelLoadError: $message';
}

class ModelValidationResult {
  final bool isValid;
  final String? error;
  final int? size;

  ModelValidationResult._({
    required this.isValid,
    this.error,
    this.size,
  });

  factory ModelValidationResult.valid(int size) => ModelValidationResult._(
    isValid: true,
    size: size,
  );

  factory ModelValidationResult.error(String error) => ModelValidationResult._(
    isValid: false,
    error: error,
  );
}

class ModelCacheEntry {
  final String key;
  final String filePath;
  final String originalUrl;
  final int size;
  final DateTime timestamp;

  ModelCacheEntry({
    required this.key,
    required this.filePath,
    required this.originalUrl,
    required this.size,
    required this.timestamp,
  });

  bool get isValid {
    // Check if file still exists and size matches
    return File(filePath).existsSync();
  }

  Future<void> delete() async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

class ModelLoadEvent {
  final String? modelUrl;
  final String? filePath;
  final ModelLoadError? error;

  ModelLoadEvent._({this.modelUrl, this.filePath, this.error});

  factory ModelLoadEvent.started(String modelUrl) =>
      ModelLoadEvent._(modelUrl: modelUrl);

  factory ModelLoadEvent.completed(String modelUrl, String filePath) =>
      ModelLoadEvent._(modelUrl: modelUrl, filePath: filePath);

  factory ModelLoadEvent.cached(String modelUrl, String filePath) =>
      ModelLoadEvent._(modelUrl: modelUrl, filePath: filePath);

  factory ModelLoadEvent.error(String modelUrl, ModelLoadError error) =>
      ModelLoadEvent._(modelUrl: modelUrl, error: error);

  factory ModelLoadEvent.cacheCleared() => ModelLoadEvent._();
}

class CacheStatistics {
  final int cachedModels;
  final int totalCacheSize;
  final int maxCacheSize;
  final double cacheUtilization;

  CacheStatistics({
    required this.cachedModels,
    required this.totalCacheSize,
    required this.maxCacheSize,
    required this.cacheUtilization,
  });

  String get formattedCacheSize {
    if (totalCacheSize < 1024) {
      return '${totalCacheSize}B';
    } else if (totalCacheSize < 1024 * 1024) {
      return '${(totalCacheSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(totalCacheSize / 1024 / 1024).toStringAsFixed(1)}MB';
    }
  }

  String get formattedMaxCacheSize {
    if (maxCacheSize < 1024 * 1024) {
      return '${(maxCacheSize / 1024).toStringAsFixed(0)}KB';
    } else {
      return '${(maxCacheSize / 1024 / 1024).toStringAsFixed(0)}MB';
    }
  }
}