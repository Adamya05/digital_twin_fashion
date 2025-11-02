/// Interactive Avatar Model with 3D Controls
/// 
/// Enhanced avatar model that supports real-time interactive controls for:
/// - 360° rotation and auto-rotation
/// - Height adjustment (150cm - 200cm)
/// - Body shape modifications (chest, waist, hip)
/// - Lighting presets and custom lighting
/// - Real-time parameter updates with smooth transitions
import 'package:flutter/foundation.dart';
import 'avatar_model.dart';

/// Interactive controls configuration for 3D avatar manipulation
class InteractiveAvatarControls {
  /// Height adjustment in centimeters (150-200 range)
  final double height;
  
  /// Body shape adjustments as percentages (90-110 range)
  final double chestSize; // percentage
  final double waistSize; // percentage  
  final double hipSize; // percentage
  
  /// Rotation controls
  final double rotationY; // degrees (0-360)
  final bool autoRotate;
  final double autoRotateSpeed; // degrees per second
  
  /// Lighting configuration
  final LightingPreset lightingPreset;
  final CustomLighting? customLighting;
  
  /// Animation and transition states
  final bool isAnimating;
  final AnimationPhase animationPhase;

  const InteractiveAvatarControls({
    this.height = 175.0,
    this.chestSize = 100.0,
    this.waistSize = 100.0,
    this.hipSize = 100.0,
    this.rotationY = 0.0,
    this.autoRotate = false,
    this.autoRotateSpeed = 2.0,
    this.lightingPreset = LightingPreset.studio,
    this.customLighting,
    this.isAnimating = false,
    this.animationPhase = AnimationPhase.idle,
  });

  /// Create a copy with updated values
  InteractiveAvatarControls copyWith({
    double? height,
    double? chestSize,
    double? waistSize,
    double? hipSize,
    double? rotationY,
    bool? autoRotate,
    double? autoRotateSpeed,
    LightingPreset? lightingPreset,
    CustomLighting? customLighting,
    bool? isAnimating,
    AnimationPhase? animationPhase,
  }) {
    return InteractiveAvatarControls(
      height: height ?? this.height,
      chestSize: chestSize ?? this.chestSize,
      waistSize: waistSize ?? this.waistSize,
      hipSize: hipSize ?? this.hipSize,
      rotationY: rotationY ?? this.rotationY,
      autoRotate: autoRotate ?? this.autoRotate,
      autoRotateSpeed: autoRotateSpeed ?? this.autoRotateSpeed,
      lightingPreset: lightingPreset ?? this.lightingPreset,
      customLighting: customLighting ?? this.customLighting,
      isAnimating: isAnimating ?? this.isAnimating,
      animationPhase: animationPhase ?? this.animationPhase,
    );
  }

  /// Create from body preset
  InteractiveAvatarControls fromBodyPreset(BodyPreset preset) {
    return copyWith(
      chestSize: preset.chestMultiplier * 100,
      waistSize: preset.waistMultiplier * 100,
      hipSize: preset.hipMultiplier * 100,
    );
  }

  /// Apply body preset values
  InteractiveAvatarControls applyBodyPreset(BodyPreset preset) {
    return copyWith(
      chestSize: preset.chestMultiplier * 100,
      waistSize: preset.waistMultiplier * 100,
      hipSize: preset.hipMultiplier * 100,
    );
  }

  /// Reset all adjustments to default values
  InteractiveAvatarControls reset() {
    return const InteractiveAvatarControls();
  }

  /// Get scale factors for 3D model transformation
  Map<String, double> getScaleFactors() {
    // Convert percentages to scale factors (0.9-1.1 range)
    return {
      'height': height / 175.0, // Normalize to base height
      'chest': chestSize / 100.0,
      'waist': waistSize / 100.0,
      'hip': hipSize / 100.0,
    };
  }

  /// Get rotation in radians for 3D model
  double get rotationYRad => rotationY * 3.14159 / 180.0;
}

/// Animation phases for smooth transitions
enum AnimationPhase {
  idle('Idle'),
  rotating('Rotating'),
  adjusting('Adjusting'),
  transitioning('Transitioning'),
  saving('Saving');

  const AnimationPhase(this.displayName);
  final String displayName;
}

/// Body type presets for quick adjustments
enum BodyPreset {
  slim('Slim', 0.95, 0.90, 0.95),
  regular('Regular', 1.0, 1.0, 1.0),
  athletic('Athletic', 1.08, 0.95, 1.05);

  const BodyPreset(this.displayName, this.chestMultiplier, this.waistMultiplier, this.hipMultiplier);
  final String displayName;
  final double chestMultiplier;
  final double waistMultiplier;
  final double hipMultiplier;
}

/// Custom lighting configuration for advanced lighting control
class CustomLighting {
  final double intensity; // 0.0 to 2.0
  final double angle; // 0 to 360 degrees
  final double elevation; // -90 to 90 degrees
  final String? environmentMap;

  const CustomLighting({
    required this.intensity,
    required this.angle,
    required this.elevation,
    this.environmentMap,
  });

  CustomLighting copyWith({
    double? intensity,
    double? angle,
    double? elevation,
    String? environmentMap,
  }) {
    return CustomLighting(
      intensity: intensity ?? this.intensity,
      angle: angle ?? this.angle,
      elevation: elevation ?? this.elevation,
      environmentMap: environmentMap ?? this.environmentMap,
    );
  }
}

/// Lighting presets with optimized settings for different scenarios
enum LightingPreset {
  studio('Studio Lighting', 1.2, 'studio'),
  day('Day Lighting', 1.0, 'neutral'),
  night('Night Lighting', 0.8, 'studio'),
  dramatic('Dramatic Lighting', 1.5, 'studio'),
  neutral('Natural Lighting', 1.0, 'neutral');

  const LightingPreset(this.displayName, this.intensity, this.environmentImage);
  final String displayName;
  final double intensity;
  final String environmentImage;
  
  String get skyboxImage => environmentImage;
  
  /// Get model viewer configuration for this lighting preset
  Map<String, dynamic> getModelViewerConfig() {
    return {
      'shadow-intensity': intensity,
      'exposure': intensity,
      'environment-image': environmentImage,
      'skybox-image': skyboxImage,
    };
  }
}

/// Enhanced Avatar with interactive controls
class InteractiveAvatar {
  final Avatar baseAvatar;
  final InteractiveAvatarControls controls;
  final AvatarHistory? history;
  final String? currentPreset;

  InteractiveAvatar({
    required this.baseAvatar,
    required this.controls,
    this.history,
    this.currentPreset,
  });

  /// Create from base avatar with default controls
  factory InteractiveAvatar.fromAvatar(Avatar avatar) {
    return InteractiveAvatar(
      baseAvatar: avatar,
      controls: const InteractiveAvatarControls(),
    );
  }

  /// Create with specific controls
  factory InteractiveAvatar.withControls(
    Avatar avatar,
    InteractiveAvatarControls controls,
  ) {
    return InteractiveAvatar(
      baseAvatar: avatar,
      controls: controls,
    );
  }

  /// Get current model viewer configuration
  Map<String, dynamic> getModelViewerConfig() {
    final scaleFactors = controls.getScaleFactors();
    
    return {
      'src': baseAvatar.modelUrl,
      'alt': 'Interactive Avatar - ${baseAvatar.name}',
      'ar': true,
      'auto-rotate': controls.autoRotate,
      'camera-controls': true,
      'interaction-prompt': 'auto',
      'shadow-intensity': controls.lightingPreset.intensity,
      'exposure': controls.lightingPreset.intensity,
      'environment-image': controls.lightingPreset.environmentImage,
      'skybox-image': controls.lightingPreset.skyboxImage,
      'loading': 'eager',
      'reveal': 'auto',
      'scale': '${scaleFactors['height']} ${scaleFactors['chest']} ${scaleFactors['hip']}',
    };
  }

  /// Apply body preset with animation
  InteractiveAvatar applyBodyPreset(BodyPreset preset, {bool animate = true}) {
    final newControls = controls.fromBodyPreset(preset);
    return copyWith(
      controls: newControls,
      currentPreset: preset.displayName,
    );
  }

  /// Update height with real-time scaling
  InteractiveAvatar updateHeight(double height, {bool animate = true}) {
    return copyWith(
      controls: controls.copyWith(
        height: height.clamp(150.0, 200.0),
        isAnimating: animate,
        animationPhase: animate ? AnimationPhase.adjusting : AnimationPhase.idle,
      ),
    );
  }

  /// Update body shape dimensions
  InteractiveAvatar updateBodyShape({
    double? chest,
    double? waist,
    double? hip,
    bool animate = true,
  }) {
    return copyWith(
      controls: controls.copyWith(
        chestSize: chest?.clamp(90.0, 110.0) ?? controls.chestSize,
        waistSize: waist?.clamp(90.0, 110.0) ?? controls.waistSize,
        hipSize: hip?.clamp(90.0, 110.0) ?? controls.hipSize,
        isAnimating: animate,
        animationPhase: animate ? AnimationPhase.adjusting : AnimationPhase.idle,
      ),
    );
  }

  /// Rotate avatar to specific angle
  InteractiveAvatar rotateTo(double angle, {bool animate = true}) {
    return copyWith(
      controls: controls.copyWith(
        rotationY: angle % 360,
        isAnimating: animate,
        animationPhase: animate ? AnimationPhase.rotating : AnimationPhase.idle,
      ),
    );
  }

  /// Toggle auto-rotation
  InteractiveAvatar toggleAutoRotate({bool? enabled, double? speed}) {
    return copyWith(
      controls: controls.copyWith(
        autoRotate: enabled ?? !controls.autoRotate,
        autoRotateSpeed: speed ?? controls.autoRotateSpeed,
        isAnimating: false,
        animationPhase: AnimationPhase.idle,
      ),
    );
  }

  /// Apply lighting preset
  InteractiveAvatar applyLighting(LightingPreset preset) {
    return copyWith(
      controls: controls.copyWith(
        lightingPreset: preset,
        isAnimating: false,
        animationPhase: AnimationPhase.idle,
      ),
    );
  }

  /// Reset all adjustments
  InteractiveAvatar reset({bool animate = true}) {
    return copyWith(
      controls: controls.reset().copyWith(
        isAnimating: animate,
        animationPhase: animate ? AnimationPhase.transitioning : AnimationPhase.idle,
      ),
      currentPreset: null,
    );
  }

  /// Complete animation
  InteractiveAvatar completeAnimation() {
    return copyWith(
      controls: controls.copyWith(
        isAnimating: false,
        animationPhase: AnimationPhase.idle,
      ),
    );
  }

  /// Save current state to history
  InteractiveAvatar saveToHistory() {
    final newHistory = AvatarHistory(
      previous: history,
      controls: controls,
      timestamp: DateTime.now(),
      preset: currentPreset,
    );
    
    return copyWith(history: newHistory);
  }

  /// Create a copy with updated values
  InteractiveAvatar copyWith({
    Avatar? baseAvatar,
    InteractiveAvatarControls? controls,
    AvatarHistory? history,
    String? currentPreset,
  }) {
    return InteractiveAvatar(
      baseAvatar: baseAvatar ?? this.baseAvatar,
      controls: controls ?? this.controls,
      history: history ?? this.history,
      currentPreset: currentPreset ?? this.currentPreset,
    );
  }

  /// Get display values formatted for UI
  Map<String, String> getFormattedValues() {
    return {
      'height': '${controls.height.round()} cm',
      'chest': '${controls.chestSize.round()}%',
      'waist': '${controls.waistSize.round()}%',
      'hip': '${controls.hipSize.round()}%',
      'rotation': '${controls.rotationY.round()}°',
      'lighting': controls.lightingPreset.displayName,
    };
  }

  /// Check if any adjustments are active
  bool get hasAdjustments {
    return controls.height != 175.0 ||
           controls.chestSize != 100.0 ||
           controls.waistSize != 100.0 ||
           controls.hipSize != 100.0 ||
           controls.rotationY != 0.0;
  }

  /// Get animation progress (0.0 to 1.0)
  double get animationProgress {
    if (!controls.isAnimating) return 1.0;
    
    // In a real implementation, this would track actual animation progress
    return 0.8; // Placeholder
  }
}

/// Avatar history for undo/redo functionality
class AvatarHistory {
  final AvatarHistory? previous;
  final InteractiveAvatarControls controls;
  final DateTime timestamp;
  final String? preset;

  const AvatarHistory({
    this.previous,
    required this.controls,
    required this.timestamp,
    this.preset,
  });

  /// Get the number of steps in history
  int get depth {
    int count = 0;
    AvatarHistory? current = this;
    while (current != null) {
      count++;
      current = current.previous;
    }
    return count;
  }

  /// Undo to previous state
  AvatarHistory? get undo => previous;

  /// Check if this is the earliest state
  bool get isFirst => previous == null;

  /// Check if this is the latest state  
  bool get isLast => false; // The current state is always the latest
}

/// Avatar comparison data for before/after views
class AvatarComparison {
  final InteractiveAvatar original;
  final InteractiveAvatar modified;
  final ComparisonMode mode;

  AvatarComparison({
    required this.original,
    required this.modified,
    this.mode = ComparisonMode.sideBySide,
  });

  /// Get the difference between original and modified
  Map<String, double> getDifferences() {
    return {
      'height': modified.controls.height - original.controls.height,
      'chest': modified.controls.chestSize - original.controls.chestSize,
      'waist': modified.controls.waistSize - original.controls.waistSize,
      'hip': modified.controls.hipSize - original.controls.hipSize,
    };
  }

  /// Check if there are any significant differences
  bool get hasSignificantDifferences {
    final differences = getDifferences();
    return differences.values.any((diff) => diff.abs() > 5.0);
  }
}

/// Comparison display modes
enum ComparisonMode {
  sideBySide('Side by Side'),
  overlay('Overlay'),
  slider('Before/After Slider');

  const ComparisonMode(this.displayName);
  final String displayName;
}