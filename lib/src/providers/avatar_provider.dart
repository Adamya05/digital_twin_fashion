/// Avatar Provider
/// 
/// State management for avatar data, generation process, and user preferences.
/// Handles avatar creation, updates, and synchronization with backend services.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_model.dart';
import '../services/avatar_service.dart';
import '../services/avatar_fallback_service.dart';
import '../services/api_service.dart';

/// Avatar provider using Riverpod for reactive state management
final avatarProvider = StateNotifierProvider<AvatarNotifier, AsyncValue<Avatar>>((ref) {
  return AvatarNotifier();
});

/// State notifier for avatar operations
class AvatarNotifier extends StateNotifier<AsyncValue<Avatar>> {
  final SharedPreferences _prefs;
  final AvatarService? _avatarService;
  final AvatarFallbackService? _fallbackService;
  final ApiService _apiService;

  // Additional state for comprehensive management
  List<Avatar> _userAvatars = [];
  List<Avatar> _favoriteAvatars = [];
  List<Avatar> _recentAvatars = [];
  AvatarListResponse? _allAvatarsResponse;
  
  LoadingState _loadingState = LoadingState.idle;
  String? _loadingError;
  Map<String, AvatarLoadResult> _loadResults = {};
  
  AvatarSettings _settings = AvatarSettings.defaults();
  bool _isOfflineMode = false;

  // Stream controllers for reactive updates
  final StreamController<Avatar> _avatarUpdatedController = 
      StreamController<Avatar>.broadcast();
  final StreamController<LoadingState> _loadingController = 
      StreamController<LoadingState>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();

  AvatarNotifier({
    SharedPreferences? prefs,
  }) : _prefs = prefs ?? _getSharedPreferences(),
       _avatarService = prefs != null ? AvatarService(prefs) : null,
       _fallbackService = prefs != null ? AvatarFallbackService() : null,
       _apiService = ApiService(),
       super(const AsyncValue.loading()) {
    _initializeProvider();
  }

  static SharedPreferences _getSharedPreferences() {
    // This is a fallback - in real usage, prefs should be injected
    throw UnsupportedError('SharedPreferences must be injected for full functionality');
  }

  /// Initialize the provider
  Future<void> _initializeProvider() async {
    try {
      await _loadSettings();
      await _loadUserData();
      await _loadCurrentAvatar();
    } catch (e) {
      debugPrint('Failed to initialize avatar provider: $e');
    }
  }

  /// Load avatar from API by ID with comprehensive fallback system
  Future<void> loadAvatar(String avatarId) async {
    state = const AsyncValue.loading();
    _updateLoadingState(LoadingState.loading, 'Loading avatar: $avatarId');
    
    try {
      // Use fallback service if available
      if (_fallbackService != null) {
        final result = await _fallbackService.loadAvatarWithFallback(avatarId);
        
        if (result.isSuccess && result.avatar != null) {
          _currentAvatar = result.avatar!;
          _cacheAvatar(avatarId, result);
          state = AsyncValue.data(result.avatar!);
        } else {
          throw Exception(result.error ?? 'Failed to load avatar');
        }
      } else {
        // Fallback to basic implementation
        await _loadAvatarBasic(avatarId);
      }
    } catch (error, stackTrace) {
      _loadingError = error.toString();
      _errorController.add(error.toString());
      state = AsyncValue.error(error, stackTrace);
    } finally {
      _updateLoadingState(LoadingState.idle);
    }
  }

  /// Basic avatar loading for fallback compatibility
  Future<void> _loadAvatarBasic(String avatarId) async {
    // Simulate API call with mock data
    await Future.delayed(const Duration(seconds: 1));
    
    final avatar = Avatar(
      id: avatarId,
      name: 'My Digital Twin',
      modelUrl: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
      thumbnailUrl: 'https://picsum.photos/400/600?random=$avatarId',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      measurements: const AvatarMeasurements(
        height: 175,
        weight: 70,
        chest: 95,
        waist: 80,
        hips: 95,
        shoulders: 45,
        arms: 70,
        legs: 85,
      ),
      attributes: const AvatarAttributes(
        bodyType: 'Regular',
        ethnicity: 'Mixed',
        skinTone: 'Medium',
        hairColor: 'Brown',
        hairStyle: 'Short',
        eyeColor: 'Brown',
        gender: 'Non-binary',
        age: 25,
      ),
      metadata: AvatarMetadata(
        fileSize: 2048000,
        fileFormat: 'glb',
        polyCount: 15000,
        modelVersion: '1.2.0',
        textures: ['diffuse.jpg', 'normal.jpg', 'roughness.jpg'],
        isOptimized: true,
        qualityLevel: 'High',
        lastUsed: DateTime.now(),
      ),
    );
    
    _currentAvatar = avatar;
    state = AsyncValue.data(avatar);
  }

  /// Update avatar 3D parameters with real-time updates
  Future<void> updateAvatarAdjustments({
    double? heightAdjust,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    LightingPreset? lighting,
  }) async {
    final currentAvatar = state.value;
    if (currentAvatar == null) return;

    state = const AsyncValue.loading();

    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedAvatar = currentAvatar.copyWith(
        heightAdjust: heightAdjust,
        chestSize: chestSize,
        waistSize: waistSize,
        hipSize: hipSize,
        lighting: lighting,
        state: AvatarState.ready,
      );

      state = AsyncValue.data(updatedAvatar);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Save current avatar configuration
  Future<void> saveAvatar() async {
    final currentAvatar = state.value;
    if (currentAvatar == null) return;

    state = const AsyncValue.loading();

    try {
      // Simulate save API call
      await Future.delayed(const Duration(seconds: 2));

      final savedAvatar = currentAvatar.copyWith(
        state: AvatarState.ready,
        updatedAt: DateTime.now(),
      );

      state = AsyncValue.data(savedAvatar);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Re-scan avatar (regenerate from new scan)
  Future<void> rescanAvatar() async {
    state = const AsyncValue.loading();

    try {
      // Simulate rescan process
      await Future.delayed(const Duration(seconds: 3));

      final avatar = state.value?.copyWith(
        state: AvatarState.ready,
        updatedAt: DateTime.now(),
      ) ?? Avatar.empty();

      state = AsyncValue.data(avatar);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Capture avatar snapshot
  Future<String?> captureSnapshot() async {
    final currentAvatar = state.value;
    if (currentAvatar == null) return null;

    try {
      // In a real implementation, this would capture the 3D view
      // For now, return the thumbnail URL as a placeholder
      return currentAvatar.thumbnailUrl;
    } catch (error) {
      debugPrint('Snapshot capture failed: $error');
      return null;
    }
  }

  /// Clear any errors
  void clearError() {
    if (state.hasError) {
      final currentAvatar = state.value;
      if (currentAvatar != null) {
        state = AsyncValue.data(currentAvatar.copyWith(state: AvatarState.ready));
      } else {
        state = const AsyncValue.loading();
      }
    }
  }

  /// Reset avatar to default state
  void resetAvatar() {
    state = const AsyncValue.loading();
  }
}

/// Provider for avatar loading state
final avatarLoadingProvider = Provider<bool>((ref) {
  return ref.watch(avatarProvider).isLoading;
});

/// Provider for avatar error state
final avatarErrorProvider = Provider<String?>((ref) {
  final avatarState = ref.watch(avatarProvider);
  return avatarState.hasError ? avatarState.error.toString() : null;
});

/// Provider for avatar adjustments state
final avatarAdjustmentsProvider = StateProvider<AvatarAdjustments>((ref) {
  return const AvatarAdjustments();
});

  // ==================== ADDITIONAL STATE AND GETTERS ====================
  
  Avatar? _currentAvatar;
  List<Avatar> get userAvatars => List.unmodifiable(_userAvatars);
  List<Avatar> get favoriteAvatars => List.unmodifiable(_favoriteAvatars);
  List<Avatar> get recentAvatars => List.unmodifiable(_recentAvatars);
  AvatarListResponse? get allAvatarsResponse => _allAvatarsResponse;
  
  LoadingState get loadingState => _loadingState;
  String? get loadingError => _loadingError;
  AvatarSettings get settings => _settings;
  bool get isOfflineMode => _isOfflineMode;

  // Stream getters for reactive UI
  Stream<Avatar> get avatarUpdatedStream => _avatarUpdatedController.stream;
  Stream<LoadingState> get loadingStream => _loadingController.stream;
  Stream<String> get errorStream => _errorController.stream;

  // ==================== COMPREHENSIVE AVATAR MANAGEMENT ====================

  /// Load avatar with comprehensive fallback system
  Future<AvatarLoadResult> loadAvatarWithFallback(String avatarId, {
    bool useCache = true,
    bool enableRetry = true,
  }) async {
    if (_loadResults.containsKey(avatarId) && useCache) {
      return _loadResults[avatarId]!;
    }

    _updateLoadingState(LoadingState.loading, 'Loading avatar: $avatarId');

    try {
      final options = AvatarLoadOptions(
        useCache: useCache,
        enableRetry: enableRetry,
      );

      if (_fallbackService != null) {
        final result = await _fallbackService.loadAvatarWithFallback(
          avatarId,
          options: options,
        );

        _loadResults[avatarId] = result;

        if (result.isSuccess && result.avatar != null) {
          _currentAvatar = result.avatar!;
          state = AsyncValue.data(result.avatar!);
          
          // Save to user avatars if service available
          if (_avatarService != null) {
            await _avatarService.saveAvatar(result.avatar!);
            await _loadUserAvatars();
          }
          
          notifyListeners();
        } else {
          _loadingError = result.error;
          _errorController.add(result.error!);
        }

        return result;
      } else {
        await _loadAvatarBasic(avatarId);
        return AvatarLoadResult.success(
          avatar: _currentAvatar!,
          loadTime: 0,
          source: LoadSource.original,
        );
      }
    } catch (e) {
      final errorResult = AvatarLoadResult.failure(
        error: 'Failed to load avatar: $e',
        loadTime: 0,
        fallbackReason: FallbackReason.loadError,
      );
      
      _loadResults[avatarId] = errorResult;
      _loadingError = errorResult.error;
      notifyListeners();
      
      return errorResult;
    } finally {
      _updateLoadingState(LoadingState.idle);
    }
  }

  /// Set current active avatar
  Future<bool> setCurrentAvatar(String avatarId) async {
    try {
      if (_avatarService != null) {
        final success = await _avatarService.setCurrentAvatar(avatarId);
        
        if (success && avatarId.isNotEmpty) {
          final avatar = _avatarService.getAvatarById(avatarId);
          if (avatar != null) {
            _currentAvatar = avatar;
            state = AsyncValue.data(avatar);
            _avatarUpdatedController.add(avatar);
            notifyListeners();
            return true;
          }
        }
        return false;
      } else {
        // Fallback to basic implementation
        final avatar = _userAvatars.firstWhere(
          (a) => a.id == avatarId,
          orElse: () => Avatar.empty(),
        );
        
        if (avatar.id.isNotEmpty) {
          _currentAvatar = avatar;
          state = AsyncValue.data(avatar);
          notifyListeners();
          return true;
        }
        return false;
      }
    } catch (e) {
      _loadingError = 'Failed to set current avatar: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String avatarId) async {
    try {
      if (_avatarService != null) {
        final success = await _avatarService.toggleFavorite(avatarId);
        
        if (success) {
          await _loadFavoriteAvatars();
          
          // Update local avatar state
          final index = _userAvatars.indexWhere((a) => a.id == avatarId);
          if (index >= 0) {
            _userAvatars[index] = _userAvatars[index].copyWith(
              isFavorite: !_userAvatars[index].isFavorite,
            );
          }
          
          notifyListeners();
        }
        
        return success;
      }
      return false;
    } catch (e) {
      _loadingError = 'Failed to toggle favorite: $e';
      notifyListeners();
      return false;
    }
  }

  /// Create new avatar
  Future<Avatar?> createAvatar({
    required String name,
    required AvatarMeasurements measurements,
    required AvatarAttributes attributes,
    String? description,
    List<String>? tags,
  }) async {
    _updateLoadingState(LoadingState.saving, 'Creating avatar...');

    try {
      final avatarData = {
        'name': name,
        'measurements': measurements.toJson(),
        'attributes': attributes.toJson(),
        'description': description ?? '',
        'tags': tags ?? [],
      };

      final response = await _apiService.createAvatar(avatarData);
      
      if (response.isSuccess && response.data != null) {
        final newAvatar = response.data!;
        
        if (_avatarService != null) {
          await _avatarService.saveAvatar(newAvatar);
          await _loadUserAvatars();
        } else {
          _userAvatars.add(newAvatar);
        }
        
        state = AsyncValue.data(newAvatar);
        notifyListeners();
        return newAvatar;
      } else {
        throw Exception(response.error ?? 'Failed to create avatar');
      }
    } catch (e) {
      _loadingError = 'Failed to create avatar: $e';
      notifyListeners();
      return null;
    } finally {
      _updateLoadingState(LoadingState.idle);
    }
  }

  /// Preload multiple avatars
  Future<List<String>> preloadAvatars(List<String> avatarIds) async {
    if (_fallbackService == null) return [];
    
    final loaded = await _fallbackService.preloadAvatars(avatarIds);
    return loaded;
  }

  /// Check if avatar is available offline
  bool isAvatarAvailableOffline(String avatarId) {
    return _fallbackService?.isAvatarAvailableOffline(avatarId) ?? false;
  }

  /// Get cache statistics
  AvatarCacheStats? getCacheStats() {
    return _fallbackService?.getCacheStats();
  }

  /// Clear expired cache
  void clearExpiredCache() {
    _fallbackService?.clearExpiredCache();
  }

  // ==================== PRIVATE HELPER METHODS ====================

  void _cacheAvatar(String avatarId, AvatarLoadResult result) {
    _loadResults[avatarId] = result;
  }

  Future<void> _loadCurrentAvatar() async {
    if (_avatarService == null) return;
    
    final avatarId = _prefs.getString('current_avatar_id');
    if (avatarId != null && avatarId.isNotEmpty) {
      final avatar = _avatarService.getAvatarById(avatarId);
      if (avatar != null) {
        _currentAvatar = avatar;
      }
    }
  }

  Future<void> _loadUserAvatars() async {
    if (_avatarService != null) {
      _userAvatars = _avatarService.getAllAvatars();
    }
  }

  Future<void> _loadFavoriteAvatars() async {
    if (_avatarService != null) {
      _favoriteAvatars = _avatarService.getFavoriteAvatars();
    }
  }

  Future<void> _loadRecentAvatars() async {
    if (_avatarService != null) {
      final historyIds = _avatarService.getAvatarHistory();
      final allAvatars = _avatarService.getAllAvatars();
      
      _recentAvatars = historyIds
          .map((id) => allAvatars.firstWhere(
                (avatar) => avatar.id == id,
                orElse: () => Avatar.empty(),
              ))
          .where((avatar) => avatar.id.isNotEmpty)
          .toList();
    }
  }

  Future<void> _loadUserData() async {
    if (_avatarService == null) return;
    
    await Future.wait([
      _loadUserAvatars(),
      _loadFavoriteAvatars(),
      _loadRecentAvatars(),
    ]);
  }

  Future<void> _loadSettings() async {
    if (_avatarService == null) return;
    
    final settingsJson = _prefs.getString('avatar_settings');
    if (settingsJson != null) {
      try {
        final settingsData = jsonDecode(settingsJson);
        _settings = AvatarSettings.fromJson(settingsData);
      } catch (e) {
        _settings = AvatarSettings.defaults();
      }
    }
    
    _isOfflineMode = _prefs.getBool('avatar_offline_mode') ?? false;
  }

  void _updateLoadingState(LoadingState state, [String? message]) {
    _loadingState = state;
    _loadingController.add(state);
    
    if (state == LoadingState.idle) {
      _loadingError = null;
    }
  }

  @override
  void dispose() {
    _avatarUpdatedController.close();
    _loadingController.close();
    _errorController.close();
    super.dispose();
  }
}

/// Avatar adjustments state holder
class AvatarAdjustments {
  final double heightAdjust;
  final double chestSize;
  final double waistSize;
  final double hipSize;
  final LightingPreset lighting;

  const AvatarAdjustments({
    this.heightAdjust = 0.0,
    this.chestSize = 1.0,
    this.waistSize = 1.0,
    this.hipSize = 1.0,
    this.lighting = LightingPreset.neutral,
  });

  AvatarAdjustments copyWith({
    double? heightAdjust,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    LightingPreset? lighting,
  }) {
    return AvatarAdjustments(
      heightAdjust: heightAdjust ?? this.heightAdjust,
      chestSize: chestSize ?? this.chestSize,
      waistSize: waistSize ?? this.waistSize,
      hipSize: hipSize ?? this.hipSize,
      lighting: lighting ?? this.lighting,
    );
  }
}

/// Avatar Settings
class AvatarSettings {
  final bool autoSave;
  final bool enableNotifications;
  final bool offlineModePreferred;
  final int cacheSizeLimit;
  final String qualityPreference;
  final bool enableAnalytics;
  final Duration cacheExpiry;

  const AvatarSettings({
    this.autoSave = true,
    this.enableNotifications = true,
    this.offlineModePreferred = false,
    this.cacheSizeLimit = 500,
    this.qualityPreference = 'Medium',
    this.enableAnalytics = false,
    this.cacheExpiry = const Duration(hours: 24),
  });

  factory AvatarSettings.defaults() => const AvatarSettings();

  factory AvatarSettings.fromJson(Map<String, dynamic> json) {
    return AvatarSettings(
      autoSave: json['autoSave'] as bool? ?? true,
      enableNotifications: json['enableNotifications'] as bool? ?? true,
      offlineModePreferred: json['offlineModePreferred'] as bool? ?? false,
      cacheSizeLimit: json['cacheSizeLimit'] as int? ?? 500,
      qualityPreference: json['qualityPreference'] as String? ?? 'Medium',
      enableAnalytics: json['enableAnalytics'] as bool? ?? false,
      cacheExpiry: json['cacheExpiry'] != null 
          ? Duration(hours: json['cacheExpiry'] as int)
          : const Duration(hours: 24),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoSave': autoSave,
      'enableNotifications': enableNotifications,
      'offlineModePreferred': offlineModePreferred,
      'cacheSizeLimit': cacheSizeLimit,
      'qualityPreference': qualityPreference,
      'enableAnalytics': enableAnalytics,
      'cacheExpiry': cacheExpiry.inHours,
    };
  }
}

enum LoadingState {
  idle,
  loading,
  saving,
  deleting,
  error,
}