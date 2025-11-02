/// Pose Presets for Virtual Try-On
/// 
/// Defines different pose variations for virtual try-on scenarios:
/// - Front View: Standard product display
/// - Side View: Profile for fit assessment
/// - 3/4 View: Dynamic angled view
/// - Walking Pose: Active movement
/// - Seated Pose: Comfortable sitting
/// - Custom Poses: User-defined angles
import 'package:flutter/foundation.dart';

/// Pose preset enum with configurations
enum PosePreset {
  frontView(
    'Front View',
    0.0,
    'Standard product display for full front visibility',
    Icons.person,
  ),
  sideView(
    'Side View',
    90.0,
    'Profile view for side fit assessment',
    Icons.person_outline,
  ),
  threeQuarterView(
    '3/4 View',
    45.0,
    'Dynamic angled view for enhanced appearance',
    Icons.rotate_right,
  ),
  walkingPose(
    'Walking Pose',
    15.0,
    'Dynamic movement pose for active wear',
    Icons.directions_walk,
  ),
  seatedPose(
    'Seated Pose',
    0.0,
    'Comfortable sitting position',
    Icons.weekend,
  ),
  backView(
    'Back View',
    180.0,
    'Rear view for back fit visibility',
    Icons.person_pin,
  ),
  closeUp(
    'Close Up',
    0.0,
    'Detailed view for texture and details',
    Icons.zoom_in,
  );

  const PosePreset(
    this.displayName,
    this.rotationY,
    this.description,
    this.icon,
  );

  final String displayName;
  final double rotationY;
  final String description;
  final IconData icon;

  /// Get recommended lighting for this pose
  LightingRecommendation get recommendedLighting {
    switch (this) {
      case PosePreset.frontView:
        return LightingRecommendation.bright;
      case PosePreset.sideView:
        return LightingRecommendation.natural;
      case PosePreset.threeQuarterView:
        return LightingRecommendation.studio;
      case PosePreset.walkingPose:
        return LightingRecommendation.dynamic;
      case PosePreset.seatedPose:
        return LightingRecommendation.soft;
      case PosePreset.backView:
        return LightingRecommendation.evening;
      case PosePreset.closeUp:
        return LightingRecommendation.detail;
    }
  }

  /// Get recommended product types for this pose
  List<String> get recommendedProducts {
    switch (this) {
      case PosePreset.frontView:
        return ['tops', 'dresses', 'shirts', 'blazers'];
      case PosePreset.sideView:
        return ['pants', 'skirts', 'long_dresses', 'coats'];
      case PosePreset.threeQuarterView:
        return ['all_products', 'jackets', 'blazers'];
      case PosePreset.walkingPose:
        return ['activewear', 'jeans', 'sneakers', 'jackets'];
      case PosePreset.seatedPose:
        return ['casual_wear', 'sweaters', 'pants'];
      case PosePreset.backView:
        return ['dresses', 'back_details', 'jewelry'];
      case PosePreset.closeUp:
        return ['fabric_details', 'jewelry', 'accessories'];
    }
  }

  /// Get animation duration for pose transition
  Duration get animationDuration {
    switch (this) {
      case PosePreset.walkingPose:
        return const Duration(milliseconds: 800);
      case PosePreset.seatedPose:
        return const Duration(milliseconds: 1000);
      default:
        return const Duration(milliseconds: 600);
    }
  }
}

/// Lighting recommendation types
enum LightingRecommendation {
  bright('Bright'),
  natural('Natural'),
  studio('Studio'),
  dynamic('Dynamic'),
  soft('Soft'),
  evening('Evening'),
  detail('Detail');

  const LightingRecommendation(this.displayName);
  final String displayName;
}

/// Custom pose configuration
class CustomPose {
  final String name;
  final double rotationY;
  final double height;
  final double chestSize;
  final double waistSize;
  final double hipSize;
  final int? productCategoryId;

  const CustomPose({
    required this.name,
    required this.rotationY,
    this.height = 175.0,
    this.chestSize = 100.0,
    this.waistSize = 100.0,
    this.hipSize = 100.0,
    this.productCategoryId,
  });

  CustomPose copyWith({
    String? name,
    double? rotationY,
    double? height,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    int? productCategoryId,
  }) {
    return CustomPose(
      name: name ?? this.name,
      rotationY: rotationY ?? this.rotationY,
      height: height ?? this.height,
      chestSize: chestSize ?? this.chestSize,
      waistSize: waistSize ?? this.waistSize,
      hipSize: hipSize ?? this.hipSize,
      productCategoryId: productCategoryId ?? this.productCategoryId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'rotationY': rotationY,
      'height': height,
      'chestSize': chestSize,
      'waistSize': waistSize,
      'hipSize': hipSize,
      'productCategoryId': productCategoryId,
    };
  }

  factory CustomPose.fromJson(Map<String, dynamic> json) {
    return CustomPose(
      name: json['name'],
      rotationY: json['rotationY'],
      height: json['height'],
      chestSize: json['chestSize'],
      waistSize: json['waistSize'],
      hipSize: json['hipSize'],
      productCategoryId: json['productCategoryId'],
    );
  }
}

/// Pose transition configuration
class PoseTransition {
  final PosePreset fromPose;
  final PosePreset toPose;
  final Duration duration;
  final Curve curve;
  final bool includeBodyAdjustment;

  const PoseTransition({
    required this.fromPose,
    required this.toPose,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeInOut,
    this.includeBodyAdjustment = false,
  });

  /// Calculate rotation difference
  double get rotationDifference {
    return ((toPose.rotationY - fromPose.rotationY + 360) % 360)
        .clamp(0.0, 180.0); // Use shortest path
  }

  /// Get transition type
  PoseTransitionType get transitionType {
    if (rotationDifference > 120) {
      return PoseTransitionType.extensive;
    } else if (rotationDifference > 60) {
      return PoseTransitionType.moderate;
    } else {
      return PoseTransitionType.quick;
    }
  }
}

/// Pose transition types
enum PoseTransitionType {
  quick('Quick'),
  moderate('Moderate'),
  extensive('Extensive');

  const PoseTransitionType(this.displayName);
  final String displayName;
}

/// Pose preset manager
class PosePresetManager {
  static final List<PosePreset> _allPresets = PosePreset.values.toList();
  
  /// Get all available presets
  static List<PosePreset> getAllPresets() => _allPresets;
  
  /// Get presets for specific product category
  static List<PosePreset> getPresetsForCategory(String category) {
    return _allPresets.where((preset) =>
        preset.recommendedProducts.contains(category) ||
        preset.recommendedProducts.contains('all_products')
    ).toList();
  }
  
  /// Get recommended preset for product
  static PosePreset? getRecommendedPreset(String productName) {
    // Simple recommendation logic based on product type
    if (productName.toLowerCase().contains('dress')) {
      return PosePreset.threeQuarterView;
    } else if (productName.toLowerCase().contains('pants')) {
      return PosePreset.sideView;
    } else if (productName.toLowerCase().contains('active')) {
      return PosePreset.walkingPose;
    } else if (productName.toLowerCase().contains('jacket')) {
      return PosePreset.frontView;
    }
    return PosePreset.frontView; // Default fallback
  }
}