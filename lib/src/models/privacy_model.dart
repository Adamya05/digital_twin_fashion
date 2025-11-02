/// Privacy Model
/// 
/// Data models for privacy settings, consent tracking, and compliance with Indian DPDP Act
import 'package:flutter/material.dart';

/// User consent configuration for different data processing purposes
class PrivacySettings {
  final bool dataProcessingConsent;
  final bool marketingConsent;
  final bool analyticsConsent;
  final bool locationConsent;
  final bool cameraConsent;
  final bool storageConsent;
  final String consentVersion;
  final DateTime consentTimestamp;
  final bool hasReadPrivacyPolicy;
  final bool hasReadTermsOfService;

  const PrivacySettings({
    this.dataProcessingConsent = false,
    this.marketingConsent = false,
    this.analyticsConsent = false,
    this.locationConsent = false,
    this.cameraConsent = false,
    this.storageConsent = false,
    this.consentVersion = '1.0',
    DateTime? consentTimestamp,
    this.hasReadPrivacyPolicy = false,
    this.hasReadTermsOfService = false,
  }) : consentTimestamp = consentTimestamp ?? DateTime.now();

  PrivacySettings copyWith({
    bool? dataProcessingConsent,
    bool? marketingConsent,
    bool? analyticsConsent,
    bool? locationConsent,
    bool? cameraConsent,
    bool? storageConsent,
    String? consentVersion,
    DateTime? consentTimestamp,
    bool? hasReadPrivacyPolicy,
    bool? hasReadTermsOfService,
  }) {
    return PrivacySettings(
      dataProcessingConsent: dataProcessingConsent ?? this.dataProcessingConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      analyticsConsent: analyticsConsent ?? this.analyticsConsent,
      locationConsent: locationConsent ?? this.locationConsent,
      cameraConsent: cameraConsent ?? this.cameraConsent,
      storageConsent: storageConsent ?? this.storageConsent,
      consentVersion: consentVersion ?? this.consentVersion,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      hasReadPrivacyPolicy: hasReadPrivacyPolicy ?? this.hasReadPrivacyPolicy,
      hasReadTermsOfService: hasReadTermsOfService ?? this.hasReadTermsOfService,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dataProcessingConsent': dataProcessingConsent,
      'marketingConsent': marketingConsent,
      'analyticsConsent': analyticsConsent,
      'locationConsent': locationConsent,
      'cameraConsent': cameraConsent,
      'storageConsent': storageConsent,
      'consentVersion': consentVersion,
      'consentTimestamp': consentTimestamp.toIso8601String(),
      'hasReadPrivacyPolicy': hasReadPrivacyPolicy,
      'hasReadTermsOfService': hasReadTermsOfService,
    };
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      dataProcessingConsent: json['dataProcessingConsent'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      analyticsConsent: json['analyticsConsent'] as bool? ?? false,
      locationConsent: json['locationConsent'] as bool? ?? false,
      cameraConsent: json['cameraConsent'] as bool? ?? false,
      storageConsent: json['storageConsent'] as bool? ?? false,
      consentVersion: json['consentVersion'] as String? ?? '1.0',
      consentTimestamp: DateTime.parse(json['consentTimestamp'] as String? ?? DateTime.now().toIso8601String()),
      hasReadPrivacyPolicy: json['hasReadPrivacyPolicy'] as bool? ?? false,
      hasReadTermsOfService: json['hasReadTermsOfService'] as bool? ?? false,
    );
  }

  /// Check if all required consents are given
  bool get allRequiredConsentsGiven {
    return dataProcessingConsent && cameraConsent && storageConsent;
  }

  /// Check if user has given any consent
  bool get hasAnyConsent {
    return dataProcessingConsent || marketingConsent || analyticsConsent || locationConsent || cameraConsent || storageConsent;
  }

  @override
  String toString() {
    return 'PrivacySettings(dataProcessingConsent: $dataProcessingConsent, marketingConsent: $marketingConsent, analyticsConsent: $analyticsConsent, locationConsent: $locationConsent, cameraConsent: $cameraConsent, storageConsent: $storageConsent, consentVersion: $consentVersion, consentTimestamp: $consentTimestamp, hasReadPrivacyPolicy: $hasReadPrivacyPolicy, hasReadTermsOfService: $hasReadTermsOfService)';
  }
}

/// Data retention policy information
class DataRetentionInfo {
  final String scanRetentionDays;
  final String profileDataRetentionDays;
  final String transactionRetentionDays;
  final String anonymizedDataRetentionDays;

  const DataRetentionInfo({
    this.scanRetentionDays = '30',
    this.profileDataRetentionDays = '90',
    this.transactionRetentionDays = '7',
    this.anonymizedDataRetentionDays = '365',
  });

  Map<String, dynamic> toJson() {
    return {
      'scanRetentionDays': scanRetentionDays,
      'profileDataRetentionDays': profileDataRetentionDays,
      'transactionRetentionDays': transactionRetentionDays,
      'anonymizedDataRetentionDays': anonymizedDataRetentionDays,
    };
  }

  factory DataRetentionInfo.fromJson(Map<String, dynamic> json) {
    return DataRetentionInfo(
      scanRetentionDays: json['scanRetentionDays'] as String? ?? '30',
      profileDataRetentionDays: json['profileDataRetentionDays'] as String? ?? '90',
      transactionRetentionDays: json['transactionRetentionDays'] as String? ?? '7',
      anonymizedDataRetentionDays: json['anonymizedDataRetentionDays'] as String? ?? '365',
    );
  }
}

/// User data for export/deletion purposes
class UserDataSummary {
  final String userId;
  final int scanCount;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime lastActivity;
  final List<String> dataCategories;

  const UserDataSummary({
    required this.userId,
    this.scanCount = 0,
    this.purchaseCount = 0,
    DateTime? createdAt,
    DateTime? lastActivity,
    this.dataCategories = const [],
  }) : createdAt = createdAt ?? DateTime.now(),
       lastActivity = lastActivity ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'scanCount': scanCount,
      'purchaseCount': purchaseCount,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'dataCategories': dataCategories,
    };
  }

  factory UserDataSummary.fromJson(Map<String, dynamic> json) {
    return UserDataSummary(
      userId: json['userId'] as String,
      scanCount: json['scanCount'] as int? ?? 0,
      purchaseCount: json['purchaseCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivity: DateTime.parse(json['lastActivity'] as String),
      dataCategories: (json['dataCategories'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }
}