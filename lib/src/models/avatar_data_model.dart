/// Avatar Data Model
/// 
/// Comprehensive avatar data storage with measurements, history, and settings
import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'avatar_model.dart';

class AvatarData extends Equatable {
  final String id;
  final String userId;
  final String name;
  final AvatarMeasurements measurements;
  final AvatarAttributes attributes;
  final AvatarMetadata metadata;
  final List<AvatarMeasurementHistory> measurementHistory;
  final List<AvatarCustomization> customizations;
  final AvatarSettings settings;
  final List<AvatarStylePreset> stylePresets;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastUsed;
  final int usageCount;
  final bool isDefault;
  final bool isActive;
  final Map<String, dynamic> customData;

  const AvatarData({
    required this.id,
    required this.userId,
    required this.name,
    required this.measurements,
    required this.attributes,
    required this.metadata,
    this.measurementHistory = const [],
    this.customizations = const [],
    required this.settings,
    this.stylePresets = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.lastUsed,
    this.usageCount = 0,
    this.isDefault = false,
    this.isActive = true,
    this.customData = const {},
  });

  /// Factory constructor for creating avatar data from JSON
  factory AvatarData.fromJson(Map<String, dynamic> json) {
    return AvatarData(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      measurements: AvatarMeasurements.fromJson(json['measurements'] ?? {}),
      attributes: AvatarAttributes.fromJson(json['attributes'] ?? {}),
      metadata: AvatarMetadata.fromJson(json['metadata'] ?? {}),
      measurementHistory: (json['measurementHistory'] as List<dynamic>?)
          ?.map((history) => AvatarMeasurementHistory.fromJson(history))
          .toList() ?? [],
      customizations: (json['customizations'] as List<dynamic>?)
          ?.map((custom) => AvatarCustomization.fromJson(custom))
          .toList() ?? [],
      settings: AvatarSettings.fromJson(json['settings'] ?? {}),
      stylePresets: (json['stylePresets'] as List<dynamic>?)
          ?.map((preset) => AvatarStylePreset.fromJson(preset))
          .toList() ?? [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      lastUsed: json['lastUsed'] != null 
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.now(),
      usageCount: json['usageCount'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      customData: json['customData'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert avatar data to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'measurements': measurements.toJson(),
      'attributes': attributes.toJson(),
      'metadata': metadata.toJson(),
      'measurementHistory': measurementHistory.map((history) => history.toJson()).toList(),
      'customizations': customizations.map((custom) => custom.toJson()).toList(),
      'settings': settings.toJson(),
      'stylePresets': stylePresets.map((preset) => preset.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'usageCount': usageCount,
      'isDefault': isDefault,
      'isActive': isActive,
      'customData': customData,
    };
  }

  /// Create a copy of avatar data with updated fields
  AvatarData copyWith({
    String? id,
    String? userId,
    String? name,
    AvatarMeasurements? measurements,
    AvatarAttributes? attributes,
    AvatarMetadata? metadata,
    List<AvatarMeasurementHistory>? measurementHistory,
    List<AvatarCustomization>? customizations,
    AvatarSettings? settings,
    List<AvatarStylePreset>? stylePresets,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsed,
    int? usageCount,
    bool? isDefault,
    bool? isActive,
    Map<String, dynamic>? customData,
  }) {
    return AvatarData(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      measurements: measurements ?? this.measurements,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
      measurementHistory: measurementHistory ?? this.measurementHistory,
      customizations: customizations ?? this.customizations,
      settings: settings ?? this.settings,
      stylePresets: stylePresets ?? this.stylePresets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastUsed: lastUsed ?? DateTime.now(),
      usageCount: usageCount ?? this.usageCount,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      customData: customData ?? this.customData,
    );
  }

  /// Update usage statistics
  AvatarData updateUsage() {
    return copyWith(
      lastUsed: DateTime.now(),
      usageCount: usageCount + 1,
    );
  }

  /// Add measurement to history
  AvatarData addMeasurement(AvatarMeasurementHistory newMeasurement) {
    final updatedHistory = [...measurementHistory, newMeasurement];
    // Keep only last 50 measurements to prevent data bloat
    if (updatedHistory.length > 50) {
      updatedHistory.removeAt(0);
    }
    return copyWith(
      measurements: newMeasurement.measurements,
      measurementHistory: updatedHistory,
      updatedAt: DateTime.now(),
    );
  }

  /// Check if avatar is ready for try-on
  bool get isReadyForTryOn {
    return isActive && 
           measurements.height > 0 && 
           measurements.weight > 0 &&
           metadata.isOptimized;
  }

  /// Get body type compatibility score
  double getBodyTypeScore(String targetBodyType) {
    return attributes.bodyType.toLowerCase() == targetBodyType.toLowerCase() ? 1.0 : 0.0;
  }

  /// Get age compatibility score
  double getAgeCompatibility(int targetAge) {
    final ageDiff = (attributes.age - targetAge).abs();
    if (ageDiff <= 2) return 1.0;
    if (ageDiff <= 5) return 0.8;
    if (ageDiff <= 10) return 0.5;
    return 0.2;
  }

  @override
  List<Object?> get props => [
    id, userId, name, measurements, attributes, metadata, measurementHistory,
    customizations, settings, stylePresets, createdAt, updatedAt, lastUsed,
    usageCount, isDefault, isActive, customData
  ];

  @override
  String toString() {
    return 'AvatarData{id: $id, name: $name, isActive: $isActive, usageCount: $usageCount}';
  }
}

/// Avatar Measurement History for tracking changes over time
class AvatarMeasurementHistory extends Equatable {
  final DateTime timestamp;
  final AvatarMeasurements measurements;
  final String note;
  final String source; // manual, scanning, estimation
  final double confidence;

  const AvatarMeasurementHistory({
    required this.timestamp,
    required this.measurements,
    this.note = '',
    this.source = 'manual',
    this.confidence = 1.0,
  });

  factory AvatarMeasurementHistory.fromJson(Map<String, dynamic> json) {
    return AvatarMeasurementHistory(
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      measurements: AvatarMeasurements.fromJson(json['measurements'] ?? {}),
      note: json['note'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'measurements': measurements.toJson(),
      'note': note,
      'source': source,
      'confidence': confidence,
    };
  }

  AvatarMeasurementHistory copyWith({
    DateTime? timestamp,
    AvatarMeasurements? measurements,
    String? note,
    String? source,
    double? confidence,
  }) {
    return AvatarMeasurementHistory(
      timestamp: timestamp ?? this.timestamp,
      measurements: measurements ?? this.measurements,
      note: note ?? this.note,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
    );
  }

  @override
  List<Object?> get props => [timestamp, measurements, note, source, confidence];
}

/// Avatar Customization settings
class AvatarCustomization extends Equatable {
  final String id;
  final String name;
  final String type; // hair, makeup, clothing, accessory
  final Map<String, dynamic> properties;
  final bool isEnabled;
  final DateTime createdAt;

  const AvatarCustomization({
    required this.id,
    required this.name,
    required this.type,
    required this.properties,
    this.isEnabled = true,
    required this.createdAt,
  });

  factory AvatarCustomization.fromJson(Map<String, dynamic> json) {
    return AvatarCustomization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'properties': properties,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AvatarCustomization copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? properties,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return AvatarCustomization(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      properties: properties ?? this.properties,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, type, properties, isEnabled, createdAt];
}

/// Avatar Settings for behavior and appearance
class AvatarSettings extends Equatable {
  final double heightAdjust;
  final double chestSize;
  final double waistSize;
  final double hipSize;
  final String lighting;
  final String posePreset;
  final Map<String, double> proportions;
  final bool showWireframe;
  final bool enableAnimations;
  final String renderQuality; // low, medium, high
  final bool autoSaveAdjustments;
  final Map<String, dynamic> customSettings;

  const AvatarSettings({
    this.heightAdjust = 0.0,
    this.chestSize = 1.0,
    this.waistSize = 1.0,
    this.hipSize = 1.0,
    this.lighting = 'neutral',
    this.posePreset = 'neutral',
    this.proportions = const {},
    this.showWireframe = false,
    this.enableAnimations = true,
    this.renderQuality = 'medium',
    this.autoSaveAdjustments = true,
    this.customSettings = const {},
  });

  factory AvatarSettings.fromJson(Map<String, dynamic> json) {
    return AvatarSettings(
      heightAdjust: (json['heightAdjust'] as num?)?.toDouble() ?? 0.0,
      chestSize: (json['chestSize'] as num?)?.toDouble() ?? 1.0,
      waistSize: (json['waistSize'] as num?)?.toDouble() ?? 1.0,
      hipSize: (json['hipSize'] as num?)?.toDouble() ?? 1.0,
      lighting: json['lighting'] as String? ?? 'neutral',
      posePreset: json['posePreset'] as String? ?? 'neutral',
      proportions: (json['proportions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      showWireframe: json['showWireframe'] as bool? ?? false,
      enableAnimations: json['enableAnimations'] as bool? ?? true,
      renderQuality: json['renderQuality'] as String? ?? 'medium',
      autoSaveAdjustments: json['autoSaveAdjustments'] as bool? ?? true,
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heightAdjust': heightAdjust,
      'chestSize': chestSize,
      'waistSize': waistSize,
      'hipSize': hipSize,
      'lighting': lighting,
      'posePreset': posePreset,
      'proportions': proportions,
      'showWireframe': showWireframe,
      'enableAnimations': enableAnimations,
      'renderQuality': renderQuality,
      'autoSaveAdjustments': autoSaveAdjustments,
      'customSettings': customSettings,
    };
  }

  AvatarSettings copyWith({
    double? heightAdjust,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    String? lighting,
    String? posePreset,
    Map<String, double>? proportions,
    bool? showWireframe,
    bool? enableAnimations,
    String? renderQuality,
    bool? autoSaveAdjustments,
    Map<String, dynamic>? customSettings,
  }) {
    return AvatarSettings(
      heightAdjust: heightAdjust ?? this.heightAdjust,
      chestSize: chestSize ?? this.chestSize,
      waistSize: waistSize ?? this.waistSize,
      hipSize: hipSize ?? this.hipSize,
      lighting: lighting ?? this.lighting,
      posePreset: posePreset ?? this.posePreset,
      proportions: proportions ?? this.proportions,
      showWireframe: showWireframe ?? this.showWireframe,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      renderQuality: renderQuality ?? this.renderQuality,
      autoSaveAdjustments: autoSaveAdjustments ?? this.autoSaveAdjustments,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  List<Object?> get props => [
    heightAdjust, chestSize, waistSize, hipSize, lighting, posePreset,
    proportions, showWireframe, enableAnimations, renderQuality,
    autoSaveAdjustments, customSettings
  ];
}

/// Avatar Style Presets for quick styling
class AvatarStylePreset extends Equatable {
  final String id;
  final String name;
  final String description;
  final AvatarSettings settings;
  final String category;
  final List<String> tags;
  final bool isDefault;
  final DateTime createdAt;

  const AvatarStylePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.settings,
    this.category = 'general',
    this.tags = const [],
    this.isDefault = false,
    required this.createdAt,
  });

  factory AvatarStylePreset.fromJson(Map<String, dynamic> json) {
    return AvatarStylePreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      settings: AvatarSettings.fromJson(json['settings'] ?? {}),
      category: json['category'] as String? ?? 'general',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'settings': settings.toJson(),
      'category': category,
      'tags': tags,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AvatarStylePreset copyWith({
    String? id,
    String? name,
    String? description,
    AvatarSettings? settings,
    String? category,
    List<String>? tags,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AvatarStylePreset(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      settings: settings ?? this.settings,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id, name, description, settings, category, tags, isDefault, createdAt
  ];
}