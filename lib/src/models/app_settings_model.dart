/// App Settings Model
/// 
/// Comprehensive app configuration and user preferences
import 'dart:convert';
import 'package:equatable/equatable.dart';

class AppSettings extends Equatable {
  final String id;
  final String userId;
  final String version;
  final DateTime lastUpdated;
  final Map<String, dynamic> configuration;
  final UserInterfaceSettings ui;
  final PerformanceSettings performance;
  final PrivacySettingsData privacy;
  final SyncSettings sync;
  final NotificationSettingsData notifications;
  final AccessibilitySettings accessibility;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> customSettings;
  final List<SettingsBackup> backupHistory;
  final bool isFirstLaunch;
  final String onboardingStatus;

  const AppSettings({
    required this.id,
    required this.userId,
    this.version = '1.0.0',
    required this.lastUpdated,
    this.configuration = const {},
    required this.ui,
    required this.performance,
    required this.privacy,
    required this.sync,
    required this.notifications,
    required this.accessibility,
    this.featureFlags = const {},
    this.customSettings = const {},
    this.backupHistory = const [],
    this.isFirstLaunch = true,
    this.onboardingStatus = 'not_started',
  });

  /// Factory constructor for creating app settings from JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      version: json['version'] as String? ?? '1.0.0',
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      configuration: json['configuration'] as Map<String, dynamic>? ?? {},
      ui: UserInterfaceSettings.fromJson(json['ui'] ?? {}),
      performance: PerformanceSettings.fromJson(json['performance'] ?? {}),
      privacy: PrivacySettingsData.fromJson(json['privacy'] ?? {}),
      sync: SyncSettings.fromJson(json['sync'] ?? {}),
      notifications: NotificationSettingsData.fromJson(json['notifications'] ?? {}),
      accessibility: AccessibilitySettings.fromJson(json['accessibility'] ?? {}),
      featureFlags: (json['featureFlags'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as bool)) ?? {},
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
      backupHistory: (json['backupHistory'] as List<dynamic>?)
          ?.map((backup) => SettingsBackup.fromJson(backup))
          .toList() ?? [],
      isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
      onboardingStatus: json['onboardingStatus'] as String? ?? 'not_started',
    );
  }

  /// Convert app settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'version': version,
      'lastUpdated': lastUpdated.toIso8601String(),
      'configuration': configuration,
      'ui': ui.toJson(),
      'performance': performance.toJson(),
      'privacy': privacy.toJson(),
      'sync': sync.toJson(),
      'notifications': notifications.toJson(),
      'accessibility': accessibility.toJson(),
      'featureFlags': featureFlags,
      'customSettings': customSettings,
      'backupHistory': backupHistory.map((backup) => backup.toJson()).toList(),
      'isFirstLaunch': isFirstLaunch,
      'onboardingStatus': onboardingStatus,
    };
  }

  /// Create a copy of app settings with updated fields
  AppSettings copyWith({
    String? id,
    String? userId,
    String? version,
    DateTime? lastUpdated,
    Map<String, dynamic>? configuration,
    UserInterfaceSettings? ui,
    PerformanceSettings? performance,
    PrivacySettingsData? privacy,
    SyncSettings? sync,
    NotificationSettingsData? notifications,
    AccessibilitySettings? accessibility,
    Map<String, bool>? featureFlags,
    Map<String, dynamic>? customSettings,
    List<SettingsBackup>? backupHistory,
    bool? isFirstLaunch,
    String? onboardingStatus,
  }) {
    return AppSettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? DateTime.now(),
      configuration: configuration ?? this.configuration,
      ui: ui ?? this.ui,
      performance: performance ?? this.performance,
      privacy: privacy ?? this.privacy,
      sync: sync ?? this.sync,
      notifications: notifications ?? this.notifications,
      accessibility: accessibility ?? this.accessibility,
      featureFlags: featureFlags ?? this.featureFlags,
      customSettings: customSettings ?? this.customSettings,
      backupHistory: backupHistory ?? this.backupHistory,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      onboardingStatus: onboardingStatus ?? this.onboardingStatus,
    );
  }

  /// Mark first launch as completed
  AppSettings completeFirstLaunch() {
    return copyWith(
      isFirstLaunch: false,
      onboardingStatus: 'completed',
    );
  }

  /// Update onboarding status
  AppSettings updateOnboardingStatus(String status) {
    return copyWith(onboardingStatus: status);
  }

  /// Add backup to history
  AppSettings addBackup(SettingsBackup backup) {
    final updatedHistory = [...backupHistory, backup];
    // Keep only last 10 backups
    if (updatedHistory.length > 10) {
      updatedHistory.removeAt(0);
    }
    return copyWith(backupHistory: updatedHistory);
  }

  /// Toggle feature flag
  AppSettings toggleFeatureFlag(String flagName) {
    final updatedFlags = Map<String, bool>.from(featureFlags);
    updatedFlags[flagName] = !(featureFlags[flagName] ?? false);
    return copyWith(featureFlags: updatedFlags);
  }

  /// Check if feature is enabled
  bool isFeatureEnabled(String flagName) {
    return featureFlags[flagName] ?? false;
  }

  /// Get setting value with fallback
  T? getSetting<T>(String key, T? defaultValue) {
    return customSettings[key] as T? ?? defaultValue;
  }

  /// Set custom setting value
  AppSettings setSetting<T>(String key, T value) {
    final updatedSettings = Map<String, dynamic>.from(customSettings);
    updatedSettings[key] = value;
    return copyWith(customSettings: updatedSettings);
  }

  /// Get app theme mode
  String get themeMode => ui.themeMode;

  /// Get current language
  String get currentLanguage => ui.language;

  /// Check if dark mode is enabled
  bool get isDarkMode => ui.themeMode == 'dark';

  @override
  List<Object?> get props => [
    id, userId, version, lastUpdated, configuration, ui, performance,
    privacy, sync, notifications, accessibility, featureFlags, customSettings,
    backupHistory, isFirstLaunch, onboardingStatus
  ];

  @override
  String toString() {
    return 'AppSettings{id: $id, version: $version, theme: $themeMode, language: $currentLanguage}';
  }
}

/// User Interface Settings
class UserInterfaceSettings extends Equatable {
  final String themeMode; // light, dark, system
  final String language;
  final String fontFamily;
  final double fontScale; // 0.8 to 1.5 scale
  final String layoutDensity; // compact, comfortable, spacious
  final bool hapticFeedback;
  final bool soundEffects;
  final bool animations;
  final String colorScheme; // default, high_contrast, colorblind_friendly
  final bool reduceMotion;
  final String navigationStyle; // bottom_tabs, drawer, top_tabs
  final Map<String, String> customColors;
  final bool showTutorial;

  const UserInterfaceSettings({
    this.themeMode = 'system',
    this.language = 'en',
    this.fontFamily = 'default',
    this.fontScale = 1.0,
    this.layoutDensity = 'comfortable',
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.animations = true,
    this.colorScheme = 'default',
    this.reduceMotion = false,
    this.navigationStyle = 'bottom_tabs',
    this.customColors = const {},
    this.showTutorial = true,
  });

  factory UserInterfaceSettings.fromJson(Map<String, dynamic> json) {
    return UserInterfaceSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      fontFamily: json['fontFamily'] as String? ?? 'default',
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      layoutDensity: json['layoutDensity'] as String? ?? 'comfortable',
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      soundEffects: json['soundEffects'] as bool? ?? true,
      animations: json['animations'] as bool? ?? true,
      colorScheme: json['colorScheme'] as String? ?? 'default',
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      navigationStyle: json['navigationStyle'] as String? ?? 'bottom_tabs',
      customColors: (json['customColors'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
      showTutorial: json['showTutorial'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode,
      'language': language,
      'fontFamily': fontFamily,
      'fontScale': fontScale,
      'layoutDensity': layoutDensity,
      'hapticFeedback': hapticFeedback,
      'soundEffects': soundEffects,
      'animations': animations,
      'colorScheme': colorScheme,
      'reduceMotion': reduceMotion,
      'navigationStyle': navigationStyle,
      'customColors': customColors,
      'showTutorial': showTutorial,
    };
  }

  UserInterfaceSettings copyWith({
    String? themeMode,
    String? language,
    String? fontFamily,
    double? fontScale,
    String? layoutDensity,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? animations,
    String? colorScheme,
    bool? reduceMotion,
    String? navigationStyle,
    Map<String, String>? customColors,
    bool? showTutorial,
  }) {
    return UserInterfaceSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      animations: animations ?? this.animations,
      colorScheme: colorScheme ?? this.colorScheme,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      navigationStyle: navigationStyle ?? this.navigationStyle,
      customColors: customColors ?? this.customColors,
      showTutorial: showTutorial ?? this.showTutorial,
    );
  }

  @override
  List<Object?> get props => [
    themeMode, language, fontFamily, fontScale, layoutDensity,
    hapticFeedback, soundEffects, animations, colorScheme, reduceMotion,
    navigationStyle, customColors, showTutorial
  ];
}

/// Performance Settings
class PerformanceSettings extends Equatable {
  final String imageQuality; // low, medium, high, auto
  final bool enableCache;
  final bool lazyLoading;
  final bool preloading;
  final int maxCacheSize; // in MB
  final int cacheExpiryDays;
  final bool optimizeForBattery;
  final bool enableAnalytics;
  final String networkMode; // wifi_only, cellular_allowed, offline_first
  final bool enableBackgroundSync;
  final int maxConcurrentRequests;

  const PerformanceSettings({
    this.imageQuality = 'auto',
    this.enableCache = true,
    this.lazyLoading = true,
    this.preloading = false,
    this.maxCacheSize = 500,
    this.cacheExpiryDays = 30,
    this.optimizeForBattery = false,
    this.enableAnalytics = true,
    this.networkMode = 'cellular_allowed',
    this.enableBackgroundSync = true,
    this.maxConcurrentRequests = 3,
  });

  factory PerformanceSettings.fromJson(Map<String, dynamic> json) {
    return PerformanceSettings(
      imageQuality: json['imageQuality'] as String? ?? 'auto',
      enableCache: json['enableCache'] as bool? ?? true,
      lazyLoading: json['lazyLoading'] as bool? ?? true,
      preloading: json['preloading'] as bool? ?? false,
      maxCacheSize: json['maxCacheSize'] as int? ?? 500,
      cacheExpiryDays: json['cacheExpiryDays'] as int? ?? 30,
      optimizeForBattery: json['optimizeForBattery'] as bool? ?? false,
      enableAnalytics: json['enableAnalytics'] as bool? ?? true,
      networkMode: json['networkMode'] as String? ?? 'cellular_allowed',
      enableBackgroundSync: json['enableBackgroundSync'] as bool? ?? true,
      maxConcurrentRequests: json['maxConcurrentRequests'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageQuality': imageQuality,
      'enableCache': enableCache,
      'lazyLoading': lazyLoading,
      'preloading': preloading,
      'maxCacheSize': maxCacheSize,
      'cacheExpiryDays': cacheExpiryDays,
      'optimizeForBattery': optimizeForBattery,
      'enableAnalytics': enableAnalytics,
      'networkMode': networkMode,
      'enableBackgroundSync': enableBackgroundSync,
      'maxConcurrentRequests': maxConcurrentRequests,
    };
  }

  PerformanceSettings copyWith({
    String? imageQuality,
    bool? enableCache,
    bool? lazyLoading,
    bool? preloading,
    int? maxCacheSize,
    int? cacheExpiryDays,
    bool? optimizeForBattery,
    bool? enableAnalytics,
    String? networkMode,
    bool? enableBackgroundSync,
    int? maxConcurrentRequests,
  }) {
    return PerformanceSettings(
      imageQuality: imageQuality ?? this.imageQuality,
      enableCache: enableCache ?? this.enableCache,
      lazyLoading: lazyLoading ?? this.lazyLoading,
      preloading: preloading ?? this.preloading,
      maxCacheSize: maxCacheSize ?? this.maxCacheSize,
      cacheExpiryDays: cacheExpiryDays ?? this.cacheExpiryDays,
      optimizeForBattery: optimizeForBattery ?? this.optimizeForBattery,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      networkMode: networkMode ?? this.networkMode,
      enableBackgroundSync: enableBackgroundSync ?? this.enableBackgroundSync,
      maxConcurrentRequests: maxConcurrentRequests ?? this.maxConcurrentRequests,
    );
  }

  @override
  List<Object?> get props => [
    imageQuality, enableCache, lazyLoading, preloading, maxCacheSize,
    cacheExpiryDays, optimizeForBattery, enableAnalytics, networkMode,
    enableBackgroundSync, maxConcurrentRequests
  ];
}

/// Privacy Settings Data
class PrivacySettingsData extends Equatable {
  final bool allowAnalytics;
  final bool allowPersonalization;
  final bool shareUsageData;
  final bool enableLocation;
  final bool saveBrowsingHistory;
  final String dataRetentionPeriod; // 30_days, 6_months, 1_year, forever
  final bool allowMarketingEmails;
  final bool allowPushNotifications;
  final bool allowDataExport;
  final Map<String, bool> dataSharingPermissions;
  final bool enableGDPRCompliance;

  const PrivacySettingsData({
    this.allowAnalytics = true,
    this.allowPersonalization = true,
    this.shareUsageData = true,
    this.enableLocation = false,
    this.saveBrowsingHistory = true,
    this.dataRetentionPeriod = '1_year',
    this.allowMarketingEmails = true,
    this.allowPushNotifications = true,
    this.allowDataExport = true,
    this.dataSharingPermissions = const {},
    this.enableGDPRCompliance = true,
  });

  factory PrivacySettingsData.fromJson(Map<String, dynamic> json) {
    return PrivacySettingsData(
      allowAnalytics: json['allowAnalytics'] as bool? ?? true,
      allowPersonalization: json['allowPersonalization'] as bool? ?? true,
      shareUsageData: json['shareUsageData'] as bool? ?? true,
      enableLocation: json['enableLocation'] as bool? ?? false,
      saveBrowsingHistory: json['saveBrowsingHistory'] as bool? ?? true,
      dataRetentionPeriod: json['dataRetentionPeriod'] as String? ?? '1_year',
      allowMarketingEmails: json['allowMarketingEmails'] as bool? ?? true,
      allowPushNotifications: json['allowPushNotifications'] as bool? ?? true,
      allowDataExport: json['allowDataExport'] as bool? ?? true,
      dataSharingPermissions: (json['dataSharingPermissions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as bool)) ?? {},
      enableGDPRCompliance: json['enableGDPRCompliance'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allowAnalytics': allowAnalytics,
      'allowPersonalization': allowPersonalization,
      'shareUsageData': shareUsageData,
      'enableLocation': enableLocation,
      'saveBrowsingHistory': saveBrowsingHistory,
      'dataRetentionPeriod': dataRetentionPeriod,
      'allowMarketingEmails': allowMarketingEmails,
      'allowPushNotifications': allowPushNotifications,
      'allowDataExport': allowDataExport,
      'dataSharingPermissions': dataSharingPermissions,
      'enableGDPRCompliance': enableGDPRCompliance,
    };
  }

  PrivacySettingsData copyWith({
    bool? allowAnalytics,
    bool? allowPersonalization,
    bool? shareUsageData,
    bool? enableLocation,
    bool? saveBrowsingHistory,
    String? dataRetentionPeriod,
    bool? allowMarketingEmails,
    bool? allowPushNotifications,
    bool? allowDataExport,
    Map<String, bool>? dataSharingPermissions,
    bool? enableGDPRCompliance,
  }) {
    return PrivacySettingsData(
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      shareUsageData: shareUsageData ?? this.shareUsageData,
      enableLocation: enableLocation ?? this.enableLocation,
      saveBrowsingHistory: saveBrowsingHistory ?? this.saveBrowsingHistory,
      dataRetentionPeriod: dataRetentionPeriod ?? this.dataRetentionPeriod,
      allowMarketingEmails: allowMarketingEmails ?? this.allowMarketingEmails,
      allowPushNotifications: allowPushNotifications ?? this.allowPushNotifications,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      dataSharingPermissions: dataSharingPermissions ?? this.dataSharingPermissions,
      enableGDPRCompliance: enableGDPRCompliance ?? this.enableGDPRCompliance,
    );
  }

  @override
  List<Object?> get props => [
    allowAnalytics, allowPersonalization, shareUsageData, enableLocation,
    saveBrowsingHistory, dataRetentionPeriod, allowMarketingEmails,
    allowPushNotifications, allowDataExport, dataSharingPermissions,
    enableGDPRCompliance
  ];
}

/// Sync Settings
class SyncSettings extends Equatable {
  final bool enableCloudSync;
  final bool autoSync;
  final int syncIntervalMinutes;
  final bool syncOverCellular;
  final bool syncOnWifiOnly;
  final List<String> syncDataTypes; // profiles, settings, history, favorites
  final bool conflictResolutionAuto;
  final String lastSyncTime;
  final bool enableOfflineMode;

  const SyncSettings({
    this.enableCloudSync = true,
    this.autoSync = true,
    this.syncIntervalMinutes = 60,
    this.syncOverCellular = false,
    this.syncOnWifiOnly = true,
    this.syncDataTypes = const [],
    this.conflictResolutionAuto = true,
    this.lastSyncTime = '',
    this.enableOfflineMode = true,
  });

  factory SyncSettings.fromJson(Map<String, dynamic> json) {
    return SyncSettings(
      enableCloudSync: json['enableCloudSync'] as bool? ?? true,
      autoSync: json['autoSync'] as bool? ?? true,
      syncIntervalMinutes: json['syncIntervalMinutes'] as int? ?? 60,
      syncOverCellular: json['syncOverCellular'] as bool? ?? false,
      syncOnWifiOnly: json['syncOnWifiOnly'] as bool? ?? true,
      syncDataTypes: (json['syncDataTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      conflictResolutionAuto: json['conflictResolutionAuto'] as bool? ?? true,
      lastSyncTime: json['lastSyncTime'] as String? ?? '',
      enableOfflineMode: json['enableOfflineMode'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableCloudSync': enableCloudSync,
      'autoSync': autoSync,
      'syncIntervalMinutes': syncIntervalMinutes,
      'syncOverCellular': syncOverCellular,
      'syncOnWifiOnly': syncOnWifiOnly,
      'syncDataTypes': syncDataTypes,
      'conflictResolutionAuto': conflictResolutionAuto,
      'lastSyncTime': lastSyncTime,
      'enableOfflineMode': enableOfflineMode,
    };
  }

  SyncSettings copyWith({
    bool? enableCloudSync,
    bool? autoSync,
    int? syncIntervalMinutes,
    bool? syncOverCellular,
    bool? syncOnWifiOnly,
    List<String>? syncDataTypes,
    bool? conflictResolutionAuto,
    String? lastSyncTime,
    bool? enableOfflineMode,
  }) {
    return SyncSettings(
      enableCloudSync: enableCloudSync ?? this.enableCloudSync,
      autoSync: autoSync ?? this.autoSync,
      syncIntervalMinutes: syncIntervalMinutes ?? this.syncIntervalMinutes,
      syncOverCellular: syncOverCellular ?? this.syncOverCellular,
      syncOnWifiOnly: syncOnWifiOnly ?? this.syncOnWifiOnly,
      syncDataTypes: syncDataTypes ?? this.syncDataTypes,
      conflictResolutionAuto: conflictResolutionAuto ?? this.conflictResolutionAuto,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      enableOfflineMode: enableOfflineMode ?? this.enableOfflineMode,
    );
  }

  @override
  List<Object?> get props => [
    enableCloudSync, autoSync, syncIntervalMinutes, syncOverCellular,
    syncOnWifiOnly, syncDataTypes, conflictResolutionAuto, lastSyncTime,
    enableOfflineMode
  ];
}

/// Notification Settings Data
class NotificationSettingsData extends Equatable {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final bool priceAlerts;
  final bool restockAlerts;
  final bool recommendationAlerts;
  final bool orderUpdates;
  final bool promotionalContent;
  final Map<String, int> quietHours; // start_hour, end_hour
  final List<String> disabledDays;

  const NotificationSettingsData({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    this.priceAlerts = true,
    this.restockAlerts = true,
    this.recommendationAlerts = true,
    this.orderUpdates = true,
    this.promotionalContent = false,
    this.quietHours = const {},
    this.disabledDays = const [],
  });

  factory NotificationSettingsData.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsData(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? true,
      priceAlerts: json['priceAlerts'] as bool? ?? true,
      restockAlerts: json['restockAlerts'] as bool? ?? true,
      recommendationAlerts: json['recommendationAlerts'] as bool? ?? true,
      orderUpdates: json['orderUpdates'] as bool? ?? true,
      promotionalContent: json['promotionalContent'] as bool? ?? false,
      quietHours: (json['quietHours'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      disabledDays: (json['disabledDays'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'inAppEnabled': inAppEnabled,
      'priceAlerts': priceAlerts,
      'restockAlerts': restockAlerts,
      'recommendationAlerts': recommendationAlerts,
      'orderUpdates': orderUpdates,
      'promotionalContent': promotionalContent,
      'quietHours': quietHours,
      'disabledDays': disabledDays,
    };
  }

  NotificationSettingsData copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    bool? priceAlerts,
    bool? restockAlerts,
    bool? recommendationAlerts,
    bool? orderUpdates,
    bool? promotionalContent,
    Map<String, int>? quietHours,
    List<String>? disabledDays,
  }) {
    return NotificationSettingsData(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      priceAlerts: priceAlerts ?? this.priceAlerts,
      restockAlerts: restockAlerts ?? this.restockAlerts,
      recommendationAlerts: recommendationAlerts ?? this.recommendationAlerts,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotionalContent: promotionalContent ?? this.promotionalContent,
      quietHours: quietHours ?? this.quietHours,
      disabledDays: disabledDays ?? this.disabledDays,
    );
  }

  @override
  List<Object?> get props => [
    pushEnabled, emailEnabled, inAppEnabled, priceAlerts, restockAlerts,
    recommendationAlerts, orderUpdates, promotionalContent, quietHours,
    disabledDays
  ];
}

/// Accessibility Settings
class AccessibilitySettings extends Equatable {
  final bool enableVoiceOver;
  final bool enableHighContrast;
  final bool enableLargeText;
  final bool enableReduceMotion;
  final bool enableClosedCaptions;
  final String colorBlindnessType; // none, protanopia, deuteranopia, tritanopia
  final double textScale; // 0.5 to 2.0
  final bool enableFocusIndicators;
  final bool enableHapticFeedback;
  final Map<String, String> customLabels;

  const AccessibilitySettings({
    this.enableVoiceOver = false,
    this.enableHighContrast = false,
    this.enableLargeText = false,
    this.enableReduceMotion = false,
    this.enableClosedCaptions = false,
    this.colorBlindnessType = 'none',
    this.textScale = 1.0,
    this.enableFocusIndicators = false,
    this.enableHapticFeedback = true,
    this.customLabels = const {},
  });

  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      enableVoiceOver: json['enableVoiceOver'] as bool? ?? false,
      enableHighContrast: json['enableHighContrast'] as bool? ?? false,
      enableLargeText: json['enableLargeText'] as bool? ?? false,
      enableReduceMotion: json['enableReduceMotion'] as bool? ?? false,
      enableClosedCaptions: json['enableClosedCaptions'] as bool? ?? false,
      colorBlindnessType: json['colorBlindnessType'] as String? ?? 'none',
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      enableFocusIndicators: json['enableFocusIndicators'] as bool? ?? false,
      enableHapticFeedback: json['enableHapticFeedback'] as bool? ?? true,
      customLabels: (json['customLabels'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableVoiceOver': enableVoiceOver,
      'enableHighContrast': enableHighContrast,
      'enableLargeText': enableLargeText,
      'enableReduceMotion': enableReduceMotion,
      'enableClosedCaptions': enableClosedCaptions,
      'colorBlindnessType': colorBlindnessType,
      'textScale': textScale,
      'enableFocusIndicators': enableFocusIndicators,
      'enableHapticFeedback': enableHapticFeedback,
      'customLabels': customLabels,
    };
  }

  AccessibilitySettings copyWith({
    bool? enableVoiceOver,
    bool? enableHighContrast,
    bool? enableLargeText,
    bool? enableReduceMotion,
    bool? enableClosedCaptions,
    String? colorBlindnessType,
    double? textScale,
    bool? enableFocusIndicators,
    bool? enableHapticFeedback,
    Map<String, String>? customLabels,
  }) {
    return AccessibilitySettings(
      enableVoiceOver: enableVoiceOver ?? this.enableVoiceOver,
      enableHighContrast: enableHighContrast ?? this.enableHighContrast,
      enableLargeText: enableLargeText ?? this.enableLargeText,
      enableReduceMotion: enableReduceMotion ?? this.enableReduceMotion,
      enableClosedCaptions: enableClosedCaptions ?? this.enableClosedCaptions,
      colorBlindnessType: colorBlindnessType ?? this.colorBlindnessType,
      textScale: textScale ?? this.textScale,
      enableFocusIndicators: enableFocusIndicators ?? this.enableFocusIndicators,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
      customLabels: customLabels ?? this.customLabels,
    );
  }

  @override
  List<Object?> get props => [
    enableVoiceOver, enableHighContrast, enableLargeText, enableReduceMotion,
    enableClosedCaptions, colorBlindnessType, textScale, enableFocusIndicators,
    enableHapticFeedback, customLabels
  ];
}

/// Settings Backup for versioning and recovery
class SettingsBackup extends Equatable {
  final String id;
  final DateTime timestamp;
  final String version;
  final Map<String, dynamic> backupData;
  final String description;
  final bool isAutoBackup;

  const SettingsBackup({
    required this.id,
    required this.timestamp,
    required this.version,
    required this.backupData,
    this.description = '',
    this.isAutoBackup = false,
  });

  factory SettingsBackup.fromJson(Map<String, dynamic> json) {
    return SettingsBackup(
      id: json['id'] as String? ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      version: json['version'] as String? ?? '',
      backupData: json['backupData'] as Map<String, dynamic>? ?? {},
      description: json['description'] as String? ?? '',
      isAutoBackup: json['isAutoBackup'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'backupData': backupData,
      'description': description,
      'isAutoBackup': isAutoBackup,
    };
  }

  SettingsBackup copyWith({
    String? id,
    DateTime? timestamp,
    String? version,
    Map<String, dynamic>? backupData,
    String? description,
    bool? isAutoBackup,
  }) {
    return SettingsBackup(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      version: version ?? this.version,
      backupData: backupData ?? this.backupData,
      description: description ?? this.description,
      isAutoBackup: isAutoBackup ?? this.isAutoBackup,
    );
  }

  @override
  List<Object?> get props => [
    id, timestamp, version, backupData, description, isAutoBackup
  ];

  @override
  String toString() {
    return 'SettingsBackup{id: $id, version: $version, timestamp: $timestamp}';
  }
}