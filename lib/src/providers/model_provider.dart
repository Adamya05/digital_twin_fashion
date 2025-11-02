import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/model_service.dart';

part 'model_provider.g.dart';

/// Provider for the global model service instance
@riverpod
ModelService modelService(ModelServiceRef ref) {
  return ModelService();
}

/// Provider for model loading state
@Riverpod(keepAlive: true)
class ModelLoadingState extends _$ModelLoadingState {
  ModelLoadingState() : super();

  @override
  Map<String, ModelLoadState> build() {
    // Initialize the model service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeService();
    });
    return {};
  }

  Future<void> _initializeService() async {
    final service = ref.read(modelServiceProvider);
    await service.initialize();
    
    // Listen to model events
    service.events.listen((event) {
      _handleModelEvent(event);
    });
  }

  void _handleModelEvent(ModelLoadEvent event) {
    if (event.modelUrl != null) {
      switch (event.runtimeType) {
        case ModelLoadEvent:
          if (event is ModelLoadEvent) {
            switch (event.runtimeType) {
              case ModelLoadEventStarted:
                _updateState(event.modelUrl!, ModelLoadState.loading);
                break;
              case ModelLoadEventCompleted:
                _updateState(event.modelUrl!, ModelLoadState.loaded);
                break;
              case ModelLoadEventCached:
                _updateState(event.modelUrl!, ModelLoadState.cached);
                break;
              case ModelLoadEventError:
                _updateState(event.modelUrl!, ModelLoadState.error);
                break;
            }
          }
          break;
      }
    }
  }

  void _updateState(String modelUrl, ModelLoadState state) {
    state = {...state, modelUrl: state};
    notifyListeners();
  }

  /// Load a model
  Future<ModelLoadResult> loadModel({
    required String modelUrl,
    ModelQuality quality = ModelQuality.medium,
    bool forceReload = false,
  }) async {
    _updateState(modelUrl, ModelLoadState.loading);
    
    final service = ref.read(modelServiceProvider);
    final result = await service.loadModel(
      modelUrl: modelUrl,
      quality: quality,
      forceReload: forceReload,
    );
    
    if (result.isSuccess) {
      _updateState(modelUrl, ModelLoadState.loaded);
    } else {
      _updateState(modelUrl, ModelLoadState.error);
    }
    
    return result;
  }

  /// Preload a model
  void preloadModel({
    required String modelUrl,
    ModelQuality quality = ModelQuality.medium,
  }) {
    final service = ref.read(modelServiceProvider);
    service.preloadModel(modelUrl: modelUrl, quality: quality);
  }

  /// Validate a model
  Future<ModelValidationResult> validateModel(String filePath) async {
    final service = ref.read(modelServiceProvider);
    return await service.validateModel(filePath);
  }

  /// Clear all cached models
  Future<void> clearCache() async {
    final service = ref.read(modelServiceProvider);
    await service.clearCache();
    
    // Reset all states
    state = {};
  }

  /// Get current load state for a model
  ModelLoadState? getLoadState(String modelUrl) {
    return state[modelUrl];
  }

  /// Check if a model is currently loading
  bool isLoading(String modelUrl) {
    return state[modelUrl] == ModelLoadState.loading;
  }

  /// Check if a model is loaded
  bool isLoaded(String modelUrl) {
    return state[modelUrl] == ModelLoadState.loaded;
  }

  /// Check if a model has error
  bool hasError(String modelUrl) {
    return state[modelUrl] == ModelLoadState.error;
  }

  /// Get cached models
  List<String> get cachedModels {
    return state.entries
        .where((entry) => entry.value == ModelLoadState.cached)
        .map((entry) => entry.key)
        .toList();
  }
}

/// Provider for model quality settings
@Riverpod(keepAlive: true)
class ModelQualitySettings extends _$ModelQualitySettings {
  ModelQualitySettings() : super();

  @override
  ModelQuality build() {
    return ModelQuality.medium;
  }

  void setQuality(ModelQuality quality) {
    state = quality;
  }

  ModelQuality get currentQuality => state;
}

/// Provider for model cache statistics
@Riverpod(keepAlive: true)
class CacheStats extends _$CacheStats {
  CacheStats() : super();

  @override
  CacheStatistics build() {
    _updateStats();
    
    // Listen to cache events
    final service = ref.read(modelServiceProvider);
    service.events.listen((event) {
      if (event is ModelLoadEvent && event is ModelLoadEventCompleted || 
          event is ModelLoadEventCached || 
          event is ModelLoadEventCacheCleared) {
        _updateStats();
      }
    });
    
    return CacheStatistics(
      cachedModels: 0,
      totalCacheSize: 0,
      maxCacheSize: 500 * 1024 * 1024,
      cacheUtilization: 0.0,
    );
  }

  void _updateStats() {
    final service = ref.read(modelServiceProvider);
    state = service.cacheStatistics;
  }

  void refresh() {
    _updateStats();
  }
}

/// Provider for auto-rotation settings
@Riverpod(keepAlive: true)
class AutoRotateSettings extends _$AutoRotateSettings {
  AutoRotateSettings() : super();

  @override
  Map<String, bool> build() {
    return {};
  }

  void setAutoRotate(String modelUrl, bool enabled) {
    state = {...state, modelUrl: enabled};
  }

  bool isAutoRotateEnabled(String modelUrl) {
    return state[modelUrl] ?? true;
  }

  void toggleAutoRotate(String modelUrl) {
    final current = state[modelUrl] ?? true;
    setAutoRotate(modelUrl, !current);
  }
}

/// Provider for last screenshot
@Riverpod(keepAlive: true)
class LastScreenshot extends _$LastScreenshot {
  LastScreenshot() : super();

  @override
  String? build() {
    return null;
  }

  void setLastScreenshot(String filePath) {
    state = filePath;
  }

  void clear() {
    state = null;
  }
}

/// Provider for fullscreen state
@Riverpod(keepAlive: true)
class FullscreenState extends _$FullscreenState {
  FullscreenState() : super();

  @override
  bool build() {
    return false;
  }

  void enterFullscreen() {
    state = true;
  }

  void exitFullscreen() {
    state = false;
  }

  void toggle() {
    state = !state;
  }
}

/// Provider for model interaction events
@Riverpod(keepAlive: true)
class ModelInteractions extends _$ModelInteractions {
  ModelInteractions() : super();

  @override
  Map<String, DateTime> build() {
    return {};
  }

  void recordInteraction(String modelUrl) {
    state = {...state, modelUrl: DateTime.now()};
  }

  DateTime? getLastInteraction(String modelUrl) {
    return state[modelUrl];
  }

  bool isRecentlyInteracted(String modelUrl) {
    final lastInteraction = getLastInteraction(modelUrl);
    if (lastInteraction == null) return false;
    
    final now = DateTime.now();
    final duration = now.difference(lastInteraction);
    return duration < const Duration(minutes: 5);
  }

  void clearInteractionHistory() {
    state = {};
  }
}