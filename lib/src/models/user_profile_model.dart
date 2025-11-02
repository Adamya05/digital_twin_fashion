/// User Profile Model
/// 
/// Comprehensive user profile with preferences, settings, and history
import 'dart:convert';
import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final UserPreferences preferences;
  final AvatarData avatarData;
  final UserStatistics statistics;
  final AppSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastActiveAt;
  final bool isPremium;
  final String subscriptionTier;
  final Map<String, dynamic> customAttributes;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.preferences,
    required this.avatarData,
    required this.statistics,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
    required this.lastActiveAt,
    this.isPremium = false,
    this.subscriptionTier = 'free',
    this.customAttributes = const {},
  });

  /// Factory constructor for creating user profile from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      avatarData: AvatarData.fromJson(json['avatarData'] ?? {}),
      statistics: UserStatistics.fromJson(json['statistics'] ?? {}),
      settings: AppSettings.fromJson(json['settings'] ?? {}),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      lastActiveAt: json['lastActiveAt'] != null 
          ? DateTime.parse(json['lastActiveAt'] as String)
          : DateTime.now(),
      isPremium: json['isPremium'] as bool? ?? false,
      subscriptionTier: json['subscriptionTier'] as String? ?? 'free',
      customAttributes: json['customAttributes'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert user profile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'preferences': preferences.toJson(),
      'avatarData': avatarData.toJson(),
      'statistics': statistics.toJson(),
      'settings': settings.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'isPremium': isPremium,
      'subscriptionTier': subscriptionTier,
      'customAttributes': customAttributes,
    };
  }

  /// Create a copy of user profile with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    UserPreferences? preferences,
    AvatarData? avatarData,
    UserStatistics? statistics,
    AppSettings? settings,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActiveAt,
    bool? isPremium,
    String? subscriptionTier,
    Map<String, dynamic>? customAttributes,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      preferences: preferences ?? this.preferences,
      avatarData: avatarData ?? this.avatarData,
      statistics: statistics ?? this.statistics,
      settings: settings ?? this.settings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastActiveAt: lastActiveAt ?? DateTime.now(),
      isPremium: isPremium ?? this.isPremium,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  /// Update last active timestamp
  UserProfile updateLastActive() {
    return copyWith(lastActiveAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
    id, email, name, avatarUrl, preferences, avatarData, statistics,
    settings, createdAt, updatedAt, lastActiveAt, isPremium, 
    subscriptionTier, customAttributes
  ];

  @override
  String toString() {
    return 'UserProfile{id: $id, name: $name, email: $email, isPremium: $isPremium}';
  }
}

/// User Preferences Model
/// 
/// Comprehensive user preferences for app customization
class UserPreferences extends Equatable {
  final String theme; // light, dark, system
  final String language; // en, es, fr, etc.
  final String currency; // USD, EUR, INR, etc.
  final double fontSize; // 0.8 to 1.5 scale
  final String layoutPreference; // compact, comfortable, spacious
  final bool hapticFeedback;
  final bool soundEffects;
  final bool autoPlayVideos;
  final bool highQualityImages;
  final bool dataSavingMode;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final Map<String, dynamic> categoryPreferences;
  final Map<String, dynamic> brandPreferences;
  final List<String> favoriteCategories;
  final List<String> blockedTags;
  final Map<String, double> sizePreferences;
  final DateTime lastUpdated;

  const UserPreferences({
    this.theme = 'system',
    this.language = 'en',
    this.currency = 'USD',
    this.fontSize = 1.0,
    this.layoutPreference = 'comfortable',
    this.hapticFeedback = true,
    this.soundEffects = true,
    this.autoPlayVideos = true,
    this.highQualityImages = true,
    this.dataSavingMode = false,
    required this.notifications,
    required this.privacy,
    this.categoryPreferences = const {},
    this.brandPreferences = const {},
    this.favoriteCategories = const [],
    this.blockedTags = const [],
    this.sizePreferences = const {},
    required this.lastUpdated,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String? ?? 'system',
      language: json['language'] as String? ?? 'en',
      currency: json['currency'] as String? ?? 'USD',
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
      layoutPreference: json['layoutPreference'] as String? ?? 'comfortable',
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      soundEffects: json['soundEffects'] as bool? ?? true,
      autoPlayVideos: json['autoPlayVideos'] as bool? ?? true,
      highQualityImages: json['highQualityImages'] as bool? ?? true,
      dataSavingMode: json['dataSavingMode'] as bool? ?? false,
      notifications: NotificationSettings.fromJson(json['notifications'] ?? {}),
      privacy: PrivacySettings.fromJson(json['privacy'] ?? {}),
      categoryPreferences: json['categoryPreferences'] as Map<String, dynamic>? ?? {},
      brandPreferences: json['brandPreferences'] as Map<String, dynamic>? ?? {},
      favoriteCategories: (json['favoriteCategories'] as List<dynamic>?)?.cast<String>() ?? [],
      blockedTags: (json['blockedTags'] as List<dynamic>?)?.cast<String>() ?? [],
      sizePreferences: (json['sizePreferences'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme,
      'language': language,
      'currency': currency,
      'fontSize': fontSize,
      'layoutPreference': layoutPreference,
      'hapticFeedback': hapticFeedback,
      'soundEffects': soundEffects,
      'autoPlayVideos': autoPlayVideos,
      'highQualityImages': highQualityImages,
      'dataSavingMode': dataSavingMode,
      'notifications': notifications.toJson(),
      'privacy': privacy.toJson(),
      'categoryPreferences': categoryPreferences,
      'brandPreferences': brandPreferences,
      'favoriteCategories': favoriteCategories,
      'blockedTags': blockedTags,
      'sizePreferences': sizePreferences,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? theme,
    String? language,
    String? currency,
    double? fontSize,
    String? layoutPreference,
    bool? hapticFeedback,
    bool? soundEffects,
    bool? autoPlayVideos,
    bool? highQualityImages,
    bool? dataSavingMode,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    Map<String, dynamic>? categoryPreferences,
    Map<String, dynamic>? brandPreferences,
    List<String>? favoriteCategories,
    List<String>? blockedTags,
    Map<String, double>? sizePreferences,
  }) {
    return UserPreferences(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      fontSize: fontSize ?? this.fontSize,
      layoutPreference: layoutPreference ?? this.layoutPreference,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      soundEffects: soundEffects ?? this.soundEffects,
      autoPlayVideos: autoPlayVideos ?? this.autoPlayVideos,
      highQualityImages: highQualityImages ?? this.highQualityImages,
      dataSavingMode: dataSavingMode ?? this.dataSavingMode,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      brandPreferences: brandPreferences ?? this.brandPreferences,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      blockedTags: blockedTags ?? this.blockedTags,
      sizePreferences: sizePreferences ?? this.sizePreferences,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    theme, language, currency, fontSize, layoutPreference, hapticFeedback,
    soundEffects, autoPlayVideos, highQualityImages, dataSavingMode,
    notifications, privacy, categoryPreferences, brandPreferences,
    favoriteCategories, blockedTags, sizePreferences, lastUpdated
  ];
}

/// Notification Settings
class NotificationSettings extends Equatable {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool marketingEnabled;
  final bool priceDropAlerts;
  final bool restockAlerts;
  final bool recommendationAlerts;
  final bool orderUpdates;
  final bool paymentAlerts;
  final Map<String, int> quietHours; // startHour, endHour
  final List<String> disabledDays;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.marketingEnabled = true,
    this.priceDropAlerts = true,
    this.restockAlerts = true,
    this.recommendationAlerts = true,
    this.orderUpdates = true,
    this.paymentAlerts = true,
    this.quietHours = const {},
    this.disabledDays = const [],
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['pushEnabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? true,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      marketingEnabled: json['marketingEnabled'] as bool? ?? true,
      priceDropAlerts: json['priceDropAlerts'] as bool? ?? true,
      restockAlerts: json['restockAlerts'] as bool? ?? true,
      recommendationAlerts: json['recommendationAlerts'] as bool? ?? true,
      orderUpdates: json['orderUpdates'] as bool? ?? true,
      paymentAlerts: json['paymentAlerts'] as bool? ?? true,
      quietHours: (json['quietHours'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      disabledDays: (json['disabledDays'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
      'marketingEnabled': marketingEnabled,
      'priceDropAlerts': priceDropAlerts,
      'restockAlerts': restockAlerts,
      'recommendationAlerts': recommendationAlerts,
      'orderUpdates': orderUpdates,
      'paymentAlerts': paymentAlerts,
      'quietHours': quietHours,
      'disabledDays': disabledDays,
    };
  }

  @override
  List<Object?> get props => [
    pushEnabled, emailEnabled, smsEnabled, marketingEnabled, priceDropAlerts,
    restockAlerts, recommendationAlerts, orderUpdates, paymentAlerts,
    quietHours, disabledDays
  ];
}

/// Privacy Settings
class PrivacySettings extends Equatable {
  final bool profileVisibility; // public, private
  final bool shareUsageData;
  final bool shareAnalytics;
  final bool allowPersonalization;
  final bool saveBrowsingHistory;
  final bool locationSharing;
  final bool socialMediaIntegration;
  final bool targetedAdvertising;
  final List<String> dataRetentionPreferences;
  final Map<String, bool> featurePermissions;

  const PrivacySettings({
    this.profileVisibility = true,
    this.shareUsageData = true,
    this.shareAnalytics = true,
    this.allowPersonalization = true,
    this.saveBrowsingHistory = true,
    this.locationSharing = false,
    this.socialMediaIntegration = false,
    this.targetedAdvertising = false,
    this.dataRetentionPreferences = const [],
    this.featurePermissions = const {},
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      profileVisibility: json['profileVisibility'] as bool? ?? true,
      shareUsageData: json['shareUsageData'] as bool? ?? true,
      shareAnalytics: json['shareAnalytics'] as bool? ?? true,
      allowPersonalization: json['allowPersonalization'] as bool? ?? true,
      saveBrowsingHistory: json['saveBrowsingHistory'] as bool? ?? true,
      locationSharing: json['locationSharing'] as bool? ?? false,
      socialMediaIntegration: json['socialMediaIntegration'] as bool? ?? false,
      targetedAdvertising: json['targetedAdvertising'] as bool? ?? false,
      dataRetentionPreferences: (json['dataRetentionPreferences'] as List<dynamic>?)
          ?.cast<String>() ?? [],
      featurePermissions: (json['featurePermissions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as bool)) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profileVisibility': profileVisibility,
      'shareUsageData': shareUsageData,
      'shareAnalytics': shareAnalytics,
      'allowPersonalization': allowPersonalization,
      'saveBrowsingHistory': saveBrowsingHistory,
      'locationSharing': locationSharing,
      'socialMediaIntegration': socialMediaIntegration,
      'targetedAdvertising': targetedAdvertising,
      'dataRetentionPreferences': dataRetentionPreferences,
      'featurePermissions': featurePermissions,
    };
  }

  @override
  List<Object?> get props => [
    profileVisibility, shareUsageData, shareAnalytics, allowPersonalization,
    saveBrowsingHistory, locationSharing, socialMediaIntegration,
    targetedAdvertising, dataRetentionPreferences, featurePermissions
  ];
}