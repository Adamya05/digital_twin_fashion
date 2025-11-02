/// Mock Avatar Service
/// 
/// Provides mock avatar data for development and testing.
/// Simulates API responses with realistic avatar information including:
/// - Different body types and ethnicities
/// - Mock GLB model URLs
/// - Avatar measurements and attributes
/// - Fallback system for unavailable avatars
import 'dart:math';
import '../models/avatar_model.dart';
import '../models/interactive_avatar_model.dart';

/// Mock avatar data service
class MockAvatarService {
  static const List<String> _mockModelUrls = [
    'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
    'https://modelviewer.dev/shared-assets/models/ShopifyModels/Chair.glb',
    'https://modelviewer.dev/shared-assets/models/ShopifyModels/Motorcycle.glb',
    'https://modelviewer.dev/shared-assets/models/ShopifyModels/RobotExpressive.glb',
  ];

  static const List<String> _mockImageUrls = [
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1494790108755-2616b612b5bc?w=400&h=600&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=600&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop&crop=face',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=600&fit=crop&crop=face',
  ];

  /// Get mock avatar by ID
  static Future<Avatar> getAvatarById(String avatarId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    final avatar = _generateMockAvatar(avatarId);
    if (avatar == null) {
      throw Exception('Avatar not found: $avatarId');
    }
    
    return avatar;
  }

  /// Get list of available avatars
  static Future<List<Avatar>> getAvatars({
    int page = 1,
    int limit = 20,
    String? bodyType,
    String? ethnicity,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate API delay
    
    List<Avatar> avatars = [];
    for (int i = 0; i < min(limit, 10); i++) {
      final avatarId = 'avatar_${page}_$i';
      avatars.add(_generateMockAvatar(avatarId, bodyType: bodyType, ethnicity: ethnicity)!);
    }
    
    return avatars;
  }

  /// Get avatar measurements by scan ID
  static Future<AvatarMeasurements> getMeasurementsByScanId(String scanId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Generate measurements based on scan ID hash for consistency
    final random = Random(scanId.hashCode);
    
    return AvatarMeasurements(
      height: 160.0 + random.nextDouble() * 40.0, // 160-200 cm
      weight: 50.0 + random.nextDouble() * 40.0, // 50-90 kg
      chest: 80.0 + random.nextDouble() * 30.0, // 80-110 cm
      waist: 60.0 + random.nextDouble() * 30.0, // 60-90 cm
      hips: 85.0 + random.nextDouble() * 25.0, // 85-110 cm
      shoulders: 40.0 + random.nextDouble() * 15.0, // 40-55 cm
      arms: 55.0 + random.nextDouble() * 10.0, // 55-65 cm
      legs: 85.0 + random.nextDouble() * 15.0, // 85-100 cm
    );
  }

  /// Generate interactive avatar from base avatar
  static InteractiveAvatar createInteractiveAvatar(Avatar baseAvatar) {
    final random = Random(baseAvatar.id.hashCode);
    
    // Generate random but consistent controls based on avatar ID
    final controls = InteractiveAvatarControls(
      height: 160.0 + random.nextDouble() * 40.0,
      chestSize: 95.0 + random.nextDouble() * 15.0, // 95-110%
      waistSize: 90.0 + random.nextDouble() * 20.0, // 90-110%
      hipSize: 92.0 + random.nextDouble() * 18.0, // 92-110%
      rotationY: random.nextDouble() * 360.0,
      autoRotate: random.nextBool(),
      autoRotateSpeed: 1.0 + random.nextDouble() * 3.0, // 1-4 deg/s
      lightingPreset: LightingPreset.values[random.nextInt(LightingPreset.values.length)],
    );
    
    return InteractiveAvatar.fromAvatar(baseAvatar).copyWith(
      controls: controls,
    );
  }

  /// Get avatar with fallback
  static Future<Avatar> getAvatarWithFallback(String avatarId) async {
    try {
      return await getAvatarById(avatarId);
    } catch (e) {
      // Return default avatar if specific one not found
      return _generateDefaultAvatar();
    }
  }

  /// Create avatar from body measurements
  static Avatar createAvatarFromMeasurements({
    required String id,
    required AvatarMeasurements measurements,
    AvatarAttributes? attributes,
  }) {
    final now = DateTime.now();
    final random = Random(id.hashCode);
    
    final avatarAttributes = attributes ?? AvatarAttributes(
      bodyType: _determineBodyType(measurements),
      ethnicity: _ethnicities[random.nextInt(_ethnicities.length)],
      skinTone: _skinTones[random.nextInt(_skinTones.length)],
      hairColor: _hairColors[random.nextInt(_hairColors.length)],
      hairStyle: _hairStyles[random.nextInt(_hairStyles.length)],
      eyeColor: _eyeColors[random.nextInt(_eyeColors.length)],
      gender: _genders[random.nextInt(_genders.length)],
      age: 20 + random.nextInt(40), // 20-60 years
    );

    return Avatar(
      id: id,
      name: 'Avatar $id',
      modelUrl: _mockModelUrls[random.nextInt(_mockModelUrls.length)],
      thumbnailUrl: _mockImageUrls[random.nextInt(_mockImageUrls.length)],
      createdAt: now,
      updatedAt: now,
      measurements: measurements,
      attributes: avatarAttributes,
      metadata: AvatarMetadata(
        fileSize: 1024.0 * (500 + random.nextInt(2000)), // 500-2500 KB
        fileFormat: 'glb',
        polyCount: 5000 + random.nextInt(15000), // 5K-20K polygons
        modelVersion: '1.${random.nextInt(5)}.${random.nextInt(10)}',
        textures: ['diffuse', 'normal', 'roughness'],
        isOptimized: random.nextBool(),
        qualityLevel: ['Low', 'Medium', 'High'][random.nextInt(3)],
        lastUsed: now.subtract(Duration(days: random.nextInt(30))),
      ),
      isDefault: id == 'default',
      isFavorite: random.nextBool(),
      usageCount: random.nextInt(100),
      tags: _generateTags(avatarAttributes),
      description: 'AI-generated avatar based on body measurements',
    );
  }

  /// Generate mock avatar
  static Avatar? _generateMockAvatar(
    String id, {
    String? bodyType,
    String? ethnicity,
  }) {
    final random = Random(id.hashCode);
    final now = DateTime.now();
    
    // Override random with specified filters
    if (bodyType != null || ethnicity != null) {
      // This would filter avatars in a real implementation
    }
    
    final measurements = AvatarMeasurements(
      height: 160.0 + random.nextDouble() * 40.0,
      weight: 50.0 + random.nextDouble() * 40.0,
      chest: 80.0 + random.nextDouble() * 30.0,
      waist: 60.0 + random.nextDouble() * 30.0,
      hips: 85.0 + random.nextDouble() * 25.0,
      shoulders: 40.0 + random.nextDouble() * 15.0,
      arms: 55.0 + random.nextDouble() * 10.0,
      legs: 85.0 + random.nextDouble() * 15.0,
    );
    
    final attributes = AvatarAttributes(
      bodyType: bodyType ?? _bodyTypes[random.nextInt(_bodyTypes.length)],
      ethnicity: ethnicity ?? _ethnicities[random.nextInt(_ethnicities.length)],
      skinTone: _skinTones[random.nextInt(_skinTones.length)],
      hairColor: _hairColors[random.nextInt(_hairColors.length)],
      hairStyle: _hairStyles[random.nextInt(_hairStyles.length)],
      eyeColor: _eyeColors[random.nextInt(_eyeColors.length)],
      gender: _genders[random.nextInt(_genders.length)],
      age: 20 + random.nextInt(40),
    );

    return Avatar(
      id: id,
      name: 'Avatar ${id.substring(id.length - 3)}',
      modelUrl: _mockModelUrls[random.nextInt(_mockModelUrls.length)],
      thumbnailUrl: _mockImageUrls[random.nextInt(_mockImageUrls.length)],
      createdAt: now.subtract(Duration(days: random.nextInt(365))),
      updatedAt: now,
      measurements: measurements,
      attributes: attributes,
      metadata: AvatarMetadata(
        fileSize: 1024.0 * (800 + random.nextInt(1200)),
        fileFormat: 'glb',
        polyCount: 8000 + random.nextInt(7000),
        modelVersion: '1.${random.nextInt(3)}.${random.nextInt(5)}',
        textures: ['diffuse', 'normal', 'roughness', 'metallic'],
        isOptimized: random.nextBool(),
        qualityLevel: ['Medium', 'High'][random.nextInt(2)],
        lastUsed: now.subtract(Duration(days: random.nextInt(7))),
      ),
      isDefault: id.contains('default'),
      isFavorite: random.nextBool(),
      usageCount: random.nextInt(50),
      tags: _generateTags(attributes),
      description: 'Mock avatar for development and testing',
    );
  }

  /// Generate default avatar
  static Avatar _generateDefaultAvatar() {
    final now = DateTime.now();
    final measurements = AvatarMeasurements(
      height: 175.0,
      weight: 70.0,
      chest: 95.0,
      waist: 75.0,
      hips: 95.0,
      shoulders: 45.0,
      arms: 60.0,
      legs: 90.0,
    );
    
    final attributes = AvatarAttributes(
      bodyType: 'Regular',
      ethnicity: 'Caucasian',
      skinTone: 'Medium',
      hairColor: 'Brown',
      hairStyle: 'Short',
      eyeColor: 'Blue',
      gender: 'Female',
      age: 28,
    );

    return Avatar(
      id: 'default',
      name: 'Default Avatar',
      modelUrl: _mockModelUrls.first,
      thumbnailUrl: _mockImageUrls.first,
      createdAt: now,
      updatedAt: now,
      measurements: measurements,
      attributes: attributes,
      metadata: AvatarMetadata(
        fileSize: 1024.0 * 1200,
        fileFormat: 'glb',
        polyCount: 10000,
        modelVersion: '1.0.0',
        textures: ['diffuse', 'normal', 'roughness'],
        isOptimized: true,
        qualityLevel: 'High',
        lastUsed: now,
      ),
      isDefault: true,
      isFavorite: false,
      usageCount: 0,
      tags: ['default', 'baseline'],
      description: 'Default avatar for fallback scenarios',
    );
  }

  /// Determine body type from measurements
  static String _determineBodyType(AvatarMeasurements measurements) {
    final bmi = measurements.weight / pow(measurements.height / 100, 2);
    
    if (bmi < 18.5) return 'Slim';
    if (bmi < 25.0) return 'Regular';
    if (bmi < 30.0) return 'Plus Size';
    return 'Athletic';
  }

  /// Generate tags from attributes
  static List<String> _generateTags(AvatarAttributes attributes) {
    final tags = <String>[];
    tags.add(attributes.bodyType.toLowerCase());
    tags.add(attributes.ethnicity.toLowerCase());
    tags.add(attributes.gender.toLowerCase());
    
    if (attributes.age < 25) tags.add('young');
    if (attributes.age > 40) tags.add('mature');
    
    return tags;
  }

  // Mock data constants
  static const List<String> _bodyTypes = ['Slim', 'Regular', 'Athletic', 'Plus Size'];
  static const List<String> _ethnicities = ['Caucasian', 'Asian', 'African', 'Hispanic', 'Mixed'];
  static const List<String> _skinTones = ['Light', 'Medium', 'Dark', 'Olive', 'Tan'];
  static const List<String> _hairColors = ['Black', 'Brown', 'Blonde', 'Red', 'Gray'];
  static const List<String> _hairStyles = ['Short', 'Medium', 'Long', 'Curly', 'Bald'];
  static const List<String> _eyeColors = ['Brown', 'Blue', 'Green', 'Hazel', 'Gray'];
  static const List<String> _genders = ['Male', 'Female', 'Non-binary'];
}