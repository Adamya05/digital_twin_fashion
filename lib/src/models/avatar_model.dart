class Avatar {
  final String id;
  final String name;
  final String modelUrl;
  final String thumbnailUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AvatarMeasurements measurements;
  final AvatarAttributes attributes;
  final AvatarMetadata metadata;
  final bool isDefault;
  final bool isFavorite;
  final int usageCount;
  final List<String> tags;
  final String? description;
  
  // 3D control properties
  final AvatarState state;
  final double heightAdjust; // -1.0 to 1.0 range for height adjustment
  final double chestSize; // 0.8 to 1.2 range for chest width
  final double waistSize; // 0.8 to 1.2 range for waist width  
  final double hipSize; // 0.8 to 1.2 range for hip width
  final LightingPreset lighting;
  final String? error;

  Avatar({
    required this.id,
    required this.name,
    required this.modelUrl,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.measurements,
    required this.attributes,
    required this.metadata,
    this.isDefault = false,
    this.isFavorite = false,
    this.usageCount = 0,
    this.tags = const [],
    this.description,
    this.state = AvatarState.loading,
    this.heightAdjust = 0.0,
    this.chestSize = 1.0,
    this.waistSize = 1.0,
    this.hipSize = 1.0,
    this.lighting = LightingPreset.neutral,
    this.error,
  });

  /// Factory constructor for creating an empty avatar
  factory Avatar.empty() {
    return Avatar(
      id: '',
      name: '',
      modelUrl: '',
      thumbnailUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      measurements: AvatarMeasurements.empty(),
      attributes: AvatarAttributes.empty(),
      metadata: AvatarMetadata.empty(),
      state: AvatarState.loading,
    );
  }

  /// Factory constructor for creating an avatar from JSON
  factory Avatar.fromJson(Map<String, dynamic> json) {
    return Avatar(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      modelUrl: json['modelUrl'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      measurements: AvatarMeasurements.fromJson(json['measurements'] ?? {}),
      attributes: AvatarAttributes.fromJson(json['attributes'] ?? {}),
      metadata: AvatarMetadata.fromJson(json['metadata'] ?? {}),
      isDefault: json['isDefault'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
      usageCount: json['usageCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      description: json['description'] as String?,
      state: AvatarState.values.firstWhere(
        (state) => state.name == json['state'],
        orElse: () => AvatarState.ready,
      ),
      heightAdjust: (json['heightAdjust'] as num?)?.toDouble() ?? 0.0,
      chestSize: (json['chestSize'] as num?)?.toDouble() ?? 1.0,
      waistSize: (json['waistSize'] as num?)?.toDouble() ?? 1.0,
      hipSize: (json['hipSize'] as num?)?.toDouble() ?? 1.0,
      lighting: LightingPreset.fromString(json['lighting'] as String? ?? 'neutral'),
    );
  }

  /// Convert avatar to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modelUrl': modelUrl,
      'thumbnailUrl': thumbnailUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'measurements': measurements.toJson(),
      'attributes': attributes.toJson(),
      'metadata': metadata.toJson(),
      'isDefault': isDefault,
      'isFavorite': isFavorite,
      'usageCount': usageCount,
      'tags': tags,
      'description': description,
      'state': state.name,
      'heightAdjust': heightAdjust,
      'chestSize': chestSize,
      'waistSize': waistSize,
      'hipSize': hipSize,
      'lighting': lighting.name,
    };
  }

  /// Create a copy of avatar with updated fields
  Avatar copyWith({
    String? id,
    String? name,
    String? modelUrl,
    String? thumbnailUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    AvatarMeasurements? measurements,
    AvatarAttributes? attributes,
    AvatarMetadata? metadata,
    bool? isDefault,
    bool? isFavorite,
    int? usageCount,
    List<String>? tags,
    String? description,
    AvatarState? state,
    double? heightAdjust,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    LightingPreset? lighting,
    String? error,
  }) {
    return Avatar(
      id: id ?? this.id,
      name: name ?? this.name,
      modelUrl: modelUrl ?? this.modelUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      measurements: measurements ?? this.measurements,
      attributes: attributes ?? this.attributes,
      metadata: metadata ?? this.metadata,
      isDefault: isDefault ?? this.isDefault,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      state: state ?? this.state,
      heightAdjust: heightAdjust ?? this.heightAdjust,
      chestSize: chestSize ?? this.chestSize,
      waistSize: waistSize ?? this.waistSize,
      hipSize: hipSize ?? this.hipSize,
      lighting: lighting ?? this.lighting,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Avatar && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Avatar{id: $id, name: $name, modelUrl: $modelUrl}';
  }
}

class AvatarMeasurements {
  final double height; // in cm
  final double weight; // in kg
  final double chest; // in cm
  final double waist; // in cm
  final double hips; // in cm
  final double shoulders; // in cm
  final double arms; // in cm
  final double legs; // in cm

  AvatarMeasurements({
    required this.height,
    required this.weight,
    required this.chest,
    required this.waist,
    required this.hips,
    required this.shoulders,
    required this.arms,
    required this.legs,
  });

  factory AvatarMeasurements.empty() {
    return AvatarMeasurements(
      height: 0,
      weight: 0,
      chest: 0,
      waist: 0,
      hips: 0,
      shoulders: 0,
      arms: 0,
      legs: 0,
    );
  }

  factory AvatarMeasurements.fromJson(Map<String, dynamic> json) {
    return AvatarMeasurements(
      height: (json['height'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      chest: (json['chest'] as num?)?.toDouble() ?? 0,
      waist: (json['waist'] as num?)?.toDouble() ?? 0,
      hips: (json['hips'] as num?)?.toDouble() ?? 0,
      shoulders: (json['shoulders'] as num?)?.toDouble() ?? 0,
      arms: (json['arms'] as num?)?.toDouble() ?? 0,
      legs: (json['legs'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'chest': chest,
      'waist': waist,
      'hips': hips,
      'shoulders': shoulders,
      'arms': arms,
      'legs': legs,
    };
  }

  AvatarMeasurements copyWith({
    double? height,
    double? weight,
    double? chest,
    double? waist,
    double? hips,
    double? shoulders,
    double? arms,
    double? legs,
  }) {
    return AvatarMeasurements(
      height: height ?? this.height,
      weight: weight ?? this.weight,
      chest: chest ?? this.chest,
      waist: waist ?? this.waist,
      hips: hips ?? this.hips,
      shoulders: shoulders ?? this.shoulders,
      arms: arms ?? this.arms,
      legs: legs ?? this.legs,
    );
  }
}

class AvatarAttributes {
  final String bodyType; // Slim, Regular, Athletic, PlusSize
  final String ethnicity; // Caucasian, Asian, African, Hispanic, Mixed
  final String skinTone; // Light, Medium, Dark, etc.
  final String hairColor;
  final String hairStyle;
  final String eyeColor;
  final String gender; // Male, Female, Non-binary
  final int age; // estimated age

  AvatarAttributes({
    required this.bodyType,
    required this.ethnicity,
    required this.skinTone,
    required this.hairColor,
    required this.hairStyle,
    required this.eyeColor,
    required this.gender,
    required this.age,
  });

  factory AvatarAttributes.empty() {
    return AvatarAttributes(
      bodyType: '',
      ethnicity: '',
      skinTone: '',
      hairColor: '',
      hairStyle: '',
      eyeColor: '',
      gender: '',
      age: 0,
    );
  }

  factory AvatarAttributes.fromJson(Map<String, dynamic> json) {
    return AvatarAttributes(
      bodyType: json['bodyType'] as String? ?? '',
      ethnicity: json['ethnicity'] as String? ?? '',
      skinTone: json['skinTone'] as String? ?? '',
      hairColor: json['hairColor'] as String? ?? '',
      hairStyle: json['hairStyle'] as String? ?? '',
      eyeColor: json['eyeColor'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: json['age'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyType': bodyType,
      'ethnicity': ethnicity,
      'skinTone': skinTone,
      'hairColor': hairColor,
      'hairStyle': hairStyle,
      'eyeColor': eyeColor,
      'gender': gender,
      'age': age,
    };
  }
}

class AvatarMetadata {
  final double fileSize; // in bytes
  final String fileFormat; // glb, gltf
  final int polyCount;
  final String modelVersion;
  final List<String> textures;
  final bool isOptimized;
  final String qualityLevel; // Low, Medium, High
  final DateTime lastUsed;

  AvatarMetadata({
    required this.fileSize,
    required this.fileFormat,
    required this.polyCount,
    required this.modelVersion,
    required this.textures,
    required this.isOptimized,
    required this.qualityLevel,
    required this.lastUsed,
  });

  factory AvatarMetadata.empty() {
    return AvatarMetadata(
      fileSize: 0,
      fileFormat: '',
      polyCount: 0,
      modelVersion: '',
      textures: [],
      isOptimized: false,
      qualityLevel: '',
      lastUsed: DateTime.now(),
    );
  }

  factory AvatarMetadata.fromJson(Map<String, dynamic> json) {
    return AvatarMetadata(
      fileSize: (json['fileSize'] as num?)?.toDouble() ?? 0,
      fileFormat: json['fileFormat'] as String? ?? '',
      polyCount: json['polyCount'] as int? ?? 0,
      modelVersion: json['modelVersion'] as String? ?? '',
      textures: (json['textures'] as List<dynamic>?)?.cast<String>() ?? [],
      isOptimized: json['isOptimized'] as bool? ?? false,
      qualityLevel: json['qualityLevel'] as String? ?? '',
      lastUsed: json['lastUsed'] != null 
          ? DateTime.parse(json['lastUsed'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileSize': fileSize,
      'fileFormat': fileFormat,
      'polyCount': polyCount,
      'modelVersion': modelVersion,
      'textures': textures,
      'isOptimized': isOptimized,
      'qualityLevel': qualityLevel,
      'lastUsed': lastUsed.toIso8601String(),
    };
  }
}

class AvatarListResponse {
  final List<Avatar> avatars;
  final int totalCount;
  final int page;
  final int perPage;

  AvatarListResponse({
    required this.avatars,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory AvatarListResponse.fromJson(Map<String, dynamic> json) {
    return AvatarListResponse(
      avatars: (json['avatars'] as List<dynamic>?)
          ?.map((avatarJson) => Avatar.fromJson(avatarJson))
          .toList() ?? [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 20,
    );
  }
}

/// Avatar state enum for loading states
enum AvatarState {
  loading,
  ready,
  error,
  adjusting,
  saving,
}

/// Lighting preset options for 3D models
enum LightingPreset {
  studio('Studio', 'studio'),
  day('Daylight', 'day'),
  night('Night', 'night'),
  dramatic('Dramatic', 'dramatic'),
  neutral('Neutral', 'neutral');
  
  const LightingPreset(this.label, this.environmentImage);
  
  final String label;
  final String environmentImage;
  
  String get skyboxImage => environmentImage;
  
  static LightingPreset fromString(String value) {
    return LightingPreset.values.firstWhere(
      (preset) => preset.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LightingPreset.neutral,
    );
  }
}

/// Extension on Avatar for 3D controls functionality
extension Avatar3DControls on Avatar {
  /// Get scale factor for height adjustment (-1.0 to 1.0 range)
  double get heightScale => 1.0 + (heightAdjust * 0.2); // 20% max adjustment
  
  /// Get body shape adjustment percentage
  double get chestPercentage => (chestSize - 1.0) * 100;
  double get waistPercentage => (waistSize - 1.0) * 100;
  double get hipPercentage => (hipSize - 1.0) * 100;
  
  /// Create avatar copy with 3D adjustments
  Avatar copyWithAdjustments({
    double? heightAdjust,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    LightingPreset? lighting,
  }) {
    return copyWith(
      measurements: measurements.copyWith(
        height: measurements.height * (heightAdjust != null 
            ? 1.0 + (heightAdjust * 0.2) 
            : 1.0),
      ),
      // Note: In a real implementation, you would adjust the 3D model parameters
      // This is a simplified version for demonstration
    );
  }
  
  /// Get model viewer configuration for 3D display
  Map<String, dynamic> getModelViewerConfig() {
    return {
      'src': modelUrl,
      'alt': 'Your Digital Twin - $name',
      'ar': true,
      'auto-rotate': true,
      'camera-controls': true,
      'interaction-prompt': 'auto',
      'shadow-intensity': 1,
      'exposure': 1,
      'environment-image': lighting.environmentImage,
      'skybox-image': lighting.skyboxImage,
      'loading': 'eager',
      'reveal': 'auto',
      'scale': '$heightScale 1 $heightScale', // Y-axis height adjustment
    };
  }
}