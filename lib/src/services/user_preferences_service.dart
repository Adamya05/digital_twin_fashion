/// User Preferences Persistence Service
/// 
/// Handles comprehensive user preferences storage using both SharedPreferences
/// and local database for optimal performance and data persistence.
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile_model.dart';
import 'data_service.dart';

class UserPreferencesService {
  static UserPreferencesService? _instance;
  static UserPreferencesService get instance => _instance ??= UserPreferencesService._();

  UserPreferencesService._();

  SharedPreferences? _preferences;
  final DataService _dataService = DataService.instance;
  final Map<String, dynamic> _cache = {};

  // SharedPreferences keys for different preference types
  static const String _themeKey = 'user_theme';
  static const String _languageKey = 'user_language';
  static const String _currencyKey = 'user_currency';
  static const String _fontSizeKey = 'user_font_size';
  static const String _layoutKey = 'user_layout';
  static const String _hapticKey = 'user_haptic';
  static const String _soundKey = 'user_sound';
  static const String _autoPlayKey = 'user_auto_play';
  static const String _imageQualityKey = 'user_image_quality';
  static const String _dataSavingKey = 'user_data_saving';
  static const String _notificationsKey = 'user_notifications';
  static const String _privacyKey = 'user_privacy';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _tutorialKey = 'tutorial_completed';
  static const String _lastUsedKey = 'last_used_timestamp';

  // ==================== INITIALIZATION ====================

  /// Initialize the preferences service
  Future<void> initialize() async {
    _preferences = await SharedPreferences.getInstance();
    
    // Load cached preferences
    await _loadCachedPreferences();
    
    debugPrint('UserPreferencesService initialized');
  }

  Future<void> _loadCachedPreferences() async {
    if (_preferences == null) return;

    try {
      // Load theme preference
      final theme = _preferences!.getString(_themeKey);
      if (theme != null) {
        _cache[_themeKey] = theme;
      }

      // Load language preference
      final language = _preferences!.getString(_languageKey);
      if (language != null) {
        _cache[_languageKey] = language;
      }

      // Load font size preference
      final fontSize = _preferences!.getDouble(_fontSizeKey);
      if (fontSize != null) {
        _cache[_fontSizeKey] = fontSize;
      }

      // Load boolean preferences
      _cache[_hapticKey] = _preferences!.getBool(_hapticKey) ?? true;
      _cache[_soundKey] = _preferences!.getBool(_soundKey) ?? true;
      _cache[_autoPlayKey] = _preferences!.getBool(_autoPlayKey) ?? true;
      _cache[_dataSavingKey] = _preferences!.getBool(_dataSavingKey) ?? false;

      // Load tutorial completion status
      _cache[_onboardingKey] = _preferences!.getBool(_onboardingKey) ?? false;
      _cache[_tutorialKey] = _preferences!.getBool(_tutorialKey) ?? false;

      // Load last used timestamp
      _cache[_lastUsedKey] = _preferences!.getString(_lastUsedKey);

    } catch (e) {
      debugPrint('Error loading cached preferences: $e');
    }
  }

  // ==================== THEME PREFERENCES ====================

  /// Get current theme preference
  String get theme => _cache[_themeKey] as String? ?? 'system';

  /// Set theme preference
  Future<void> setTheme(String theme) async {
    if (_preferences == null) return;

    await _preferences!.setString(_themeKey, theme);
    _cache[_themeKey] = theme;
    
    debugPrint('Theme preference updated: $theme');
  }

  /// Get dark mode preference
  bool get isDarkMode {
    final themeMode = theme;
    if (themeMode == 'dark') return true;
    if (themeMode == 'light') return false;
    
    // For 'system' theme, this would need device theme detection
    // This is a simplified implementation
    return false;
  }

  // ==================== LANGUAGE & LOCALE ====================

  /// Get current language preference
  String get language => _cache[_languageKey] as String? ?? 'en';

  /// Set language preference
  Future<void> setLanguage(String language) async {
    if (_preferences == null) return;

    await _preferences!.setString(_languageKey, language);
    _cache[_languageKey] = language;
    
    debugPrint('Language preference updated: $language');
  }

  /// Get current currency preference
  String get currency => _preferences?.getString(_currencyKey) ?? 'USD';

  /// Set currency preference
  Future<void> setCurrency(String currency) async {
    if (_preferences == null) return;

    await _preferences!.setString(_currencyKey, currency);
  }

  // ==================== UI PREFERENCES ====================

  /// Get font size preference (0.8 to 1.5 scale)
  double get fontSize => _cache[_fontSizeKey] as double? ?? 1.0;

  /// Set font size preference
  Future<void> setFontSize(double fontSize) async {
    if (_preferences == null) return;

    final clampedSize = fontSize.clamp(0.8, 1.5);
    await _preferences!.setDouble(_fontSizeKey, clampedSize);
    _cache[_fontSizeKey] = clampedSize;
  }

  /// Get layout density preference
  String get layout => _preferences?.getString(_layoutKey) ?? 'comfortable';

  /// Set layout density preference
  Future<void> setLayout(String layout) async {
    if (_preferences == null) return;

    await _preferences!.setString(_layoutKey, layout);
  }

  // ==================== FEATURE PREFERENCES ====================

  /// Get haptic feedback preference
  bool get hapticFeedback => _cache[_hapticKey] as bool? ?? true;

  /// Set haptic feedback preference
  Future<void> setHapticFeedback(bool enabled) async {
    if (_preferences == null) return;

    await _preferences!.setBool(_hapticKey, enabled);
    _cache[_hapticKey] = enabled;
  }

  /// Get sound effects preference
  bool get soundEffects => _cache[_soundKey] as bool? ?? true;

  /// Set sound effects preference
  Future<void> setSoundEffects(bool enabled) async {
    if (_preferences == null) return;

    await _preferences!.setBool(_soundKey, enabled);
    _cache[_soundKey] = enabled;
  }

  /// Get auto-play videos preference
  bool get autoPlayVideos => _cache[_autoPlayKey] as bool? ?? true;

  /// Set auto-play videos preference
  Future<void> setAutoPlayVideos(bool enabled) async {
    if (_preferences == null) return;

    await _preferences!.setBool(_autoPlayKey, enabled);
    _cache[_autoPlayKey] = enabled;
  }

  /// Get image quality preference
  String get imageQuality => _preferences?.getString(_imageQualityKey) ?? 'auto';

  /// Set image quality preference
  Future<void> setImageQuality(String quality) async {
    if (_preferences == null) return;

    await _preferences!.setString(_imageQualityKey, quality);
  }

  /// Get data saving mode preference
  bool get dataSavingMode => _cache[_dataSavingKey] as bool? ?? false;

  /// Set data saving mode preference
  Future<void> setDataSavingMode(bool enabled) async {
    if (_preferences == null) return;

    await _preferences!.setBool(_dataSavingKey, enabled);
    _cache[_dataSavingKey] = enabled;
  }

  // ==================== ONBOARDING & TUTORIAL ====================

  /// Get onboarding completion status
  bool get isOnboardingCompleted => _cache[_onboardingKey] as bool? ?? false;

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    if (_preferences == null) return;

    await _preferences!.setBool(_onboardingKey, true);
    _cache[_onboardingKey] = true;
  }

  /// Get tutorial completion status
  bool get isTutorialCompleted => _cache[_tutorialKey] as bool? ?? false;

  /// Mark tutorial as completed
  Future<void> completeTutorial() async {
    if (_preferences == null) return;

    await _preferences!.setBool(_tutorialKey, true);
    _cache[_tutorialKey] = true;
  }

  // ==================== LAST USED TIMESTAMP ====================

  /// Get last app usage timestamp
  DateTime? get lastUsed {
    final timestamp = _cache[_lastUsedKey] as String?;
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }

  /// Update last usage timestamp
  Future<void> updateLastUsed() async {
    if (_preferences == null) return;

    final now = DateTime.now().toIso8601String();
    await _preferences!.setString(_lastUsedKey, now);
    _cache[_lastUsedKey] = now;
  }

  /// Check if app was recently used (within 24 hours)
  bool get wasRecentlyUsed {
    final lastUsed = this.lastUsed;
    if (lastUsed == null) return false;
    
    final difference = DateTime.now().difference(lastUsed);
    return difference.inHours < 24;
  }

  // ==================== COMPREHENSIVE PREFERENCES ====================

  /// Get all user preferences as a UserPreferences object
  Future<UserPreferences> getAllPreferences(String userId) async {
    await _dataService.initialize();
    
    final userProfile = await _dataService.getUserProfile(userId);
    if (userProfile != null) {
      return userProfile.preferences;
    }

    // Return default preferences if user profile not found
    return UserPreferences(
      theme: theme,
      language: language,
      currency: currency,
      fontSize: fontSize,
      layoutPreference: layout,
      hapticFeedback: hapticFeedback,
      soundEffects: soundEffects,
      autoPlayVideos: autoPlayVideos,
      highQualityImages: imageQuality != 'low',
      dataSavingMode: dataSavingMode,
      notifications: NotificationSettings(
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: false,
        marketingEnabled: true,
        priceDropAlerts: true,
        restockAlerts: true,
        recommendationAlerts: true,
        orderUpdates: true,
        paymentAlerts: true,
        quietHours: {},
        disabledDays: [],
      ),
      privacy: PrivacySettings(
        profileVisibility: true,
        shareUsageData: true,
        shareAnalytics: true,
        allowPersonalization: true,
        saveBrowsingHistory: true,
        locationSharing: false,
        socialMediaIntegration: false,
        targetedAdvertising: false,
        dataRetentionPreferences: [],
        featurePermissions: {},
      ),
      categoryPreferences: {},
      brandPreferences: {},
      favoriteCategories: [],
      blockedTags: [],
      sizePreferences: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Update comprehensive user preferences
  Future<void> updateAllPreferences(String userId, UserPreferences preferences) async {
    await _dataService.initialize();
    
    final userProfile = await _dataService.getUserProfile(userId);
    if (userProfile == null) {
      debugPrint('User profile not found for user: $userId');
      return;
    }

    // Update SharedPreferences for quick access settings
    await setTheme(preferences.theme);
    await setLanguage(preferences.language);
    await setCurrency(preferences.currency);
    await setFontSize(preferences.fontSize);
    await setLayout(preferences.layoutPreference);
    await setHapticFeedback(preferences.hapticFeedback);
    await setSoundEffects(preferences.soundEffects);
    await setAutoPlayVideos(preferences.autoPlayVideos);
    await setDataSavingMode(preferences.dataSavingMode);

    // Update user profile with new preferences
    final updatedProfile = userProfile.copyWith(preferences: preferences);
    await _dataService.saveUserProfile(updatedProfile);

    debugPrint('All user preferences updated for user: $userId');
  }

  // ==================== PREFERENCE CATEGORIES ====================

  /// Get preference categories for UI organization
  Map<String, List<String>> get preferenceCategories => {
    'Appearance': [
      _themeKey,
      _fontSizeKey,
      _layoutKey,
      _imageQualityKey,
    ],
    'Audio & Haptics': [
      _hapticKey,
      _soundKey,
    ],
    'Content': [
      _autoPlayKey,
      _dataSavingKey,
    ],
    'Onboarding': [
      _onboardingKey,
      _tutorialKey,
    ],
  };

  /// Reset preferences to default values
  Future<void> resetToDefaults() async {
    if (_preferences == null) return;

    try {
      // Clear all cached values
      _cache.clear();

      // Reset SharedPreferences to defaults
      await _preferences!.remove(_themeKey);
      await _preferences!.remove(_languageKey);
      await _preferences!.remove(_currencyKey);
      await _preferences!.remove(_fontSizeKey);
      await _preferences!.remove(_layoutKey);
      await _preferences!.remove(_hapticKey);
      await _preferences!.remove(_soundKey);
      await _preferences!.remove(_autoPlayKey);
      await _preferences!.remove(_imageQualityKey);
      await _preferences!.remove(_dataSavingKey);
      await _preferences!.remove(_onboardingKey);
      await _preferences!.remove(_tutorialKey);

      debugPrint('Preferences reset to defaults');
    } catch (e) {
      debugPrint('Error resetting preferences: $e');
      rethrow;
    }
  }

  /// Export preferences as JSON
  Map<String, dynamic> exportPreferences() {
    return {
      'theme': theme,
      'language': language,
      'currency': currency,
      'fontSize': fontSize,
      'layout': layout,
      'hapticFeedback': hapticFeedback,
      'soundEffects': soundEffects,
      'autoPlayVideos': autoPlayVideos,
      'imageQuality': imageQuality,
      'dataSavingMode': dataSavingMode,
      'isOnboardingCompleted': isOnboardingCompleted,
      'isTutorialCompleted': isTutorialCompleted,
      'lastUsed': lastUsed?.toIso8601String(),
      'exportTimestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Import preferences from JSON
  Future<void> importPreferences(Map<String, dynamic> preferences) async {
    try {
      if (preferences['theme'] != null) {
        await setTheme(preferences['theme'] as String);
      }
      if (preferences['language'] != null) {
        await setLanguage(preferences['language'] as String);
      }
      if (preferences['currency'] != null) {
        await setCurrency(preferences['currency'] as String);
      }
      if (preferences['fontSize'] != null) {
        await setFontSize((preferences['fontSize'] as num).toDouble());
      }
      if (preferences['layout'] != null) {
        await setLayout(preferences['layout'] as String);
      }
      if (preferences['hapticFeedback'] != null) {
        await setHapticFeedback(preferences['hapticFeedback'] as bool);
      }
      if (preferences['soundEffects'] != null) {
        await setSoundEffects(preferences['soundEffects'] as bool);
      }
      if (preferences['autoPlayVideos'] != null) {
        await setAutoPlayVideos(preferences['autoPlayVideos'] as bool);
      }
      if (preferences['imageQuality'] != null) {
        await setImageQuality(preferences['imageQuality'] as String);
      }
      if (preferences['dataSavingMode'] != null) {
        await setDataSavingMode(preferences['dataSavingMode'] as bool);
      }

      debugPrint('Preferences imported successfully');
    } catch (e) {
      debugPrint('Error importing preferences: $e');
      rethrow;
    }
  }

  // ==================== STATISTICS ====================

  /// Get preferences statistics
  Map<String, dynamic> getPreferencesStatistics() {
    final totalKeys = _preferences?.getKeys().length ?? 0;
    final cachedKeys = _cache.length;
    
    return {
      'totalPreferences': totalKeys,
      'cachedPreferences': cachedKeys,
      'theme': theme,
      'language': language,
      'currency': currency,
      'fontSize': fontSize,
      'layout': layout,
      'isDarkMode': isDarkMode,
      'hapticFeedback': hapticFeedback,
      'soundEffects': soundEffects,
      'autoPlayVideos': autoPlayVideos,
      'dataSavingMode': dataSavingMode,
      'onboardingCompleted': isOnboardingCompleted,
      'tutorialCompleted': isTutorialCompleted,
      'recentlyUsed': wasRecentlyUsed,
      'lastUsed': lastUsed?.toIso8601String(),
    };
  }

  // ==================== CLEANUP ====================

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Dispose the service
  Future<void> dispose() async {
    clearCache();
    _preferences = null;
  }
}