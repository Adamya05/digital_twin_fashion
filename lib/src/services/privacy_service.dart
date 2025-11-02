/// Privacy Service
/// 
/// Service for managing privacy settings, consent tracking, and data operations.
/// Ensures compliance with Indian DPDP Act and handles user data securely.
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/privacy_model.dart';

class PrivacyService {
  static const String _privacySettingsKey = 'user_privacy_settings';
  static const String _consentTimestampKey = 'consent_timestamp';
  static const String _consentVersionKey = 'consent_version';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _userDataSummaryKey = 'user_data_summary';

  static PrivacyService? _instance;
  static PrivacyService get instance => _instance ??= PrivacyService._();
  
  PrivacyService._();

  SharedPreferences? _prefs;

  /// Initialize the service with SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save user privacy settings
  Future<bool> savePrivacySettings(PrivacySettings settings) async {
    if (_prefs == null) await initialize();
    final jsonString = jsonEncode(settings.toJson());
    return await _prefs!.setString(_privacySettingsKey, jsonString);
  }

  /// Load user privacy settings
  Future<PrivacySettings> loadPrivacySettings() async {
    if (_prefs == null) await initialize();
    final jsonString = _prefs!.getString(_privacySettingsKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return PrivacySettings.fromJson(json);
      } catch (e) {
        // If parsing fails, return default settings
        return const PrivacySettings();
      }
    }
    return const PrivacySettings();
  }

  /// Check if user has completed onboarding
  Future<bool> isOnboardingCompleted() async {
    if (_prefs == null) await initialize();
    return _prefs!.getBool(_onboardingCompletedKey) ?? false;
  }

  /// Mark onboarding as completed
  Future<bool> setOnboardingCompleted(bool completed) async {
    if (_prefs == null) await initialize();
    return await _prefs!.setBool(_onboardingCompletedKey, completed);
  }

  /// Save user data summary for export purposes
  Future<bool> saveUserDataSummary(UserDataSummary summary) async {
    if (_prefs == null) await initialize();
    final jsonString = jsonEncode(summary.toJson());
    return await _prefs!.setString(_userDataSummaryKey, jsonString);
  }

  /// Load user data summary
  Future<UserDataSummary?> loadUserDataSummary() async {
    if (_prefs == null) await initialize();
    final jsonString = _prefs!.getString(_userDataSummaryKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString);
        return UserDataSummary.fromJson(json);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Delete all user data (GDPR/DPDP Article 17 - Right to erasure)
  Future<bool> deleteAllUserData() async {
    if (_prefs == null) await initialize();
    
    // Clear all privacy-related data
    await _prefs!.remove(_privacySettingsKey);
    await _prefs!.remove(_consentTimestampKey);
    await _prefs!.remove(_userDataSummaryKey);
    
    // Keep onboarding completion status but reset privacy settings
    await _prefs!.setBool(_onboardingCompletedKey, false);
    
    return true;
  }

  /// Export user data (GDPR/DPDP Article 20 - Right to data portability)
  Map<String, dynamic> exportUserData() {
    if (_prefs == null) {
      return {'error': 'Privacy service not initialized'};
    }

    final exportData = <String, dynamic>{};
    
    // Add privacy settings
    final jsonString = _prefs!.getString(_privacySettingsKey);
    if (jsonString != null) {
      try {
        exportData['privacySettings'] = jsonDecode(jsonString);
      } catch (e) {
        exportData['privacySettings'] = null;
      }
    }

    // Add user data summary
    final summaryString = _prefs!.getString(_userDataSummaryKey);
    if (summaryString != null) {
      try {
        exportData['userDataSummary'] = jsonDecode(summaryString);
      } catch (e) {
        exportData['userDataSummary'] = null;
      }
    }

    // Add metadata
    exportData['exportTimestamp'] = DateTime.now().toIso8601String();
    exportData['exportVersion'] = '1.0';

    return exportData;
  }

  /// Check if consent needs to be updated (version changed)
  Future<bool> isConsentUpdateRequired(String currentVersion) async {
    if (_prefs == null) await initialize();
    final storedVersion = _prefs!.getString(_consentVersionKey);
    return storedVersion != currentVersion;
  }

  /// Update consent version
  Future<bool> updateConsentVersion(String version) async {
    if (_prefs == null) await initialize();
    return await _prefs!.setString(_consentVersionKey, version);
  }

  /// Get data retention information
  DataRetentionInfo getDataRetentionInfo() {
    return const DataRetentionInfo();
  }

  /// Reset all settings (for testing purposes)
  Future<bool> resetAllSettings() async {
    if (_prefs == null) await initialize();
    return await _prefs!.clear();
  }
}

/// Provider for PrivacyService
final privacyServiceProvider = Provider<PrivacyService>((ref) {
  return PrivacyService.instance;
});

/// Provider for privacy settings
final privacySettingsProvider = FutureProvider<PrivacySettings>((ref) async {
  final service = ref.read(privacyServiceProvider);
  await service.initialize();
  return service.loadPrivacySettings();
});

/// Provider for user data summary
final userDataSummaryProvider = FutureProvider<UserDataSummary?>((ref) async {
  final service = ref.read(privacyServiceProvider);
  await service.initialize();
  return service.loadUserDataSummary();
});

/// Provider for onboarding status
final onboardingStatusProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(privacyServiceProvider);
  await service.initialize();
  return service.isOnboardingCompleted();
});