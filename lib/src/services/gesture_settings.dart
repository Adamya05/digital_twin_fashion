/// Gesture Settings and User Preferences Manager
/// 
/// Handles user customization of swipe gestures, haptic feedback, and accessibility settings.
import 'package:flutter/foundation.dart';
import '../models/swipe_history_model.dart';

class GestureSettings {
  // Swipe sensitivity and thresholds
  static const double defaultSwipeThreshold = 120.0;
  static const double defaultSwipeVelocityThreshold = 1000.0;
  static const double minSwipeThreshold = 80.0;
  static const double maxSwipeThreshold = 200.0;

  // Animation timings
  static const Duration defaultAnimationDuration = Duration(milliseconds: 200);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 300);

  // Haptic feedback patterns
  static const Map<HapticFeedbackType, int> hapticPatternMap = {
    HapticFeedbackType.light: 10,
    HapticFeedbackType.medium: 20,
    HapticFeedbackType.heavy: 30,
  };

  // Gesture zones (for visual feedback)
  static const double gestureZoneSize = 120.0;
  static const double gestureZoneOpacity = 0.8;

  // Animation curves
  static const Map<String, Curve> availableCurves = {
    'easeOut': Curves.easeOut,
    'easeInOut': Curves.easeInOut,
    'bounceOut': Curves.bounceOut,
    'elasticOut': Curves.elasticOut,
  };

  final double swipeThreshold;
  final double swipeVelocityThreshold;
  final Duration animationDuration;
  final Curve animationCurve;
  final HapticFeedbackType hapticFeedbackLevel;
  final bool soundEffectsEnabled;
  final bool visualFeedbackEnabled;
  final bool gestureHapticsEnabled;
  final bool quickActionsEnabled;
  final bool undoEnabled;
  final Duration undoTimeout;

  const GestureSettings({
    this.swipeThreshold = defaultSwipeThreshold,
    this.swipeVelocityThreshold = defaultSwipeVelocityThreshold,
    this.animationDuration = defaultAnimationDuration,
    this.animationCurve = Curves.easeOut,
    this.hapticFeedbackLevel = HapticFeedbackType.light,
    this.soundEffectsEnabled = false,
    this.visualFeedbackEnabled = true,
    this.gestureHapticsEnabled = true,
    this.quickActionsEnabled = true,
    this.undoEnabled = true,
    this.undoTimeout = const Duration(seconds: 5),
  });

  GestureSettings copyWith({
    double? swipeThreshold,
    double? swipeVelocityThreshold,
    Duration? animationDuration,
    Curve? animationCurve,
    HapticFeedbackType? hapticFeedbackLevel,
    bool? soundEffectsEnabled,
    bool? visualFeedbackEnabled,
    bool? gestureHapticsEnabled,
    bool? quickActionsEnabled,
    bool? undoEnabled,
    Duration? undoTimeout,
  }) {
    return GestureSettings(
      swipeThreshold: swipeThreshold ?? this.swipeThreshold,
      swipeVelocityThreshold: swipeVelocityThreshold ?? this.swipeVelocityThreshold,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
      hapticFeedbackLevel: hapticFeedbackLevel ?? this.hapticFeedbackLevel,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      visualFeedbackEnabled: visualFeedbackEnabled ?? this.visualFeedbackEnabled,
      gestureHapticsEnabled: gestureHapticsEnabled ?? this.gestureHapticsEnabled,
      quickActionsEnabled: quickActionsEnabled ?? this.quickActionsEnabled,
      undoEnabled: undoEnabled ?? this.undoEnabled,
      undoTimeout: undoTimeout ?? this.undoTimeout,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'swipeThreshold': swipeThreshold,
      'swipeVelocityThreshold': swipeVelocityThreshold,
      'animationDuration': animationDuration.inMilliseconds,
      'animationCurveName': _getCurveName(animationCurve),
      'hapticFeedbackLevel': hapticFeedbackLevel.name,
      'soundEffectsEnabled': soundEffectsEnabled,
      'visualFeedbackEnabled': visualFeedbackEnabled,
      'gestureHapticsEnabled': gestureHapticsEnabled,
      'quickActionsEnabled': quickActionsEnabled,
      'undoEnabled': undoEnabled,
      'undoTimeout': undoTimeout.inSeconds,
    };
  }

  factory GestureSettings.fromJson(Map<String, dynamic> json) {
    return GestureSettings(
      swipeThreshold: (json['swipeThreshold'] as num).toDouble(),
      swipeVelocityThreshold: (json['swipeVelocityThreshold'] as num).toDouble(),
      animationDuration: Duration(milliseconds: json['animationDuration'] as int),
      animationCurve: _getCurveFromName(json['animationCurveName'] as String),
      hapticFeedbackLevel: HapticFeedbackType.values.byName(json['hapticFeedbackLevel'] as String),
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool,
      visualFeedbackEnabled: json['visualFeedbackEnabled'] as bool,
      gestureHapticsEnabled: json['gestureHapticsEnabled'] as bool,
      quickActionsEnabled: json['quickActionsEnabled'] as bool,
      undoEnabled: json['undoEnabled'] as bool,
      undoTimeout: Duration(seconds: json['undoTimeout'] as int),
    );
  }

  static String _getCurveName(Curve curve) {
    for (final entry in availableCurves.entries) {
      if (entry.value == curve) return entry.key;
    }
    return 'easeOut';
  }

  static Curve _getCurveFromName(String name) {
    return availableCurves[name] ?? Curves.easeOut;
  }

  // Preset configurations
  static GestureSettings fastGestures() {
    return const GestureSettings(
      swipeThreshold: 100.0,
      swipeVelocityThreshold: 800.0,
      animationDuration: Duration(milliseconds: 150),
      hapticFeedbackLevel: HapticFeedbackType.light,
    );
  }

  static GestureSettings preciseGestures() {
    return const GestureSettings(
      swipeThreshold: 140.0,
      swipeVelocityThreshold: 1200.0,
      animationDuration: Duration(milliseconds: 250),
      hapticFeedbackLevel: HapticFeedbackType.medium,
    );
  }

  static GestureSettings accessibilityFriendly() {
    return const GestureSettings(
      swipeThreshold: 160.0,
      swipeVelocityThreshold: 1500.0,
      animationDuration: Duration(milliseconds: 300),
      hapticFeedbackLevel: HapticFeedbackType.heavy,
      visualFeedbackEnabled: true,
      gestureHapticsEnabled: true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GestureSettings &&
          runtimeType == other.runtimeType &&
          swipeThreshold == other.swipeThreshold &&
          swipeVelocityThreshold == other.swipeVelocityThreshold &&
          animationDuration == other.animationDuration &&
          animationCurve == other.animationCurve &&
          hapticFeedbackLevel == other.hapticFeedbackLevel &&
          soundEffectsEnabled == other.soundEffectsEnabled &&
          visualFeedbackEnabled == other.visualFeedbackEnabled &&
          gestureHapticsEnabled == other.gestureHapticsEnabled &&
          quickActionsEnabled == other.quickActionsEnabled &&
          undoEnabled == other.undoEnabled &&
          undoTimeout == other.undoTimeout;

  @override
  int get hashCode {
    return swipeThreshold.hashCode ^
        swipeVelocityThreshold.hashCode ^
        animationDuration.hashCode ^
        animationCurve.hashCode ^
        hapticFeedbackLevel.hashCode ^
        soundEffectsEnabled.hashCode ^
        visualFeedbackEnabled.hashCode ^
        gestureHapticsEnabled.hashCode ^
        quickActionsEnabled.hashCode ^
        undoEnabled.hashCode ^
        undoTimeout.hashCode;
  }
}

enum HapticFeedbackType {
  none,
  light,
  medium,
  heavy,
}

class GestureAnalytics {
  final Map<String, int> swipeCounts = {};
  final Map<String, double> averageVelocities = {};
  final Map<String, Duration> averageGestureDurations = {};
  final List<Duration> sessionDurations = [];
  final List<double> swipeDistances = [];

  void recordSwipe(SwipeAction action, double velocity, Duration duration, double distance) {
    final actionKey = action.name;
    
    swipeCounts[actionKey] = (swipeCounts[actionKey] ?? 0) + 1;
    
    // Update average velocity
    final currentAvg = averageVelocities[actionKey] ?? 0.0;
    final count = swipeCounts[actionKey]!;
    averageVelocities[actionKey] = (currentAvg * (count - 1) + velocity) / count;
    
    // Update average duration
    final currentDurationAvg = averageGestureDurations[actionKey] ?? Duration.zero;
    averageGestureDurations[actionKey] = Duration(
      milliseconds: ((currentDurationAvg.inMilliseconds * (count - 1) + duration.inMilliseconds) / count).round(),
    );
    
    swipeDistances.add(distance);
  }

  Map<String, dynamic> getSummary() {
    final totalSwipes = swipeCounts.values.fold<int>(0, (sum, count) => sum + count);
    final avgVelocity = averageVelocities.isNotEmpty 
        ? averageVelocities.values.reduce((a, b) => a + b) / averageVelocities.length
        : 0.0;
    final avgDistance = swipeDistances.isNotEmpty 
        ? swipeDistances.reduce((a, b) => a + b) / swipeDistances.length
        : 0.0;
    final avgDuration = averageGestureDurations.isNotEmpty
        ? Duration(milliseconds: averageGestureDurations.values
            .map((d) => d.inMilliseconds)
            .reduce((a, b) => a + b) ~/ averageGestureDurations.length)
        : Duration.zero;

    return {
      'totalSwipes': totalSwipes,
      'actionBreakdown': Map.from(swipeCounts),
      'averageVelocity': avgVelocity,
      'averageDistance': avgDistance,
      'averageDuration': avgDuration.inMilliseconds,
      'sessionCount': sessionDurations.length,
      'mostUsedAction': swipeCounts.isNotEmpty 
          ? swipeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };
  }

  void clear() {
    swipeCounts.clear();
    averageVelocities.clear();
    averageGestureDurations.clear();
    swipeDistances.clear();
  }

  void startSession() {
    // Session tracking for advanced analytics
  }

  void endSession() {
    // Session tracking for advanced analytics
  }
}

/// Gesture Recognition Utils
class GestureUtils {
  static double calculateSwipeVelocity(Offset start, Offset end, Duration duration) {
    final distance = end.distance - start.distance;
    final timeInSeconds = duration.inMilliseconds / 1000.0;
    return timeInSeconds > 0 ? distance / timeInSeconds : 0.0;
  }

  static SwipeAction determineSwipeAction(Offset position, {double threshold = 120.0}) {
    final distance = position.distance;
    final dx = position.dx;
    final dy = position.dy;

    if (distance < threshold) return SwipeAction.skip; // Minimal movement

    // Determine primary direction
    if (dx.abs() > dy.abs()) {
      // Horizontal swipe
      return dx > 0 ? SwipeAction.like : SwipeAction.dislike;
    } else {
      // Vertical swipe
      return dy > 0 ? SwipeAction.skip : SwipeAction.superLike;
    }
  }

  static bool isValidSwipeDistance(Offset position, {double threshold = 120.0}) {
    return position.distance >= threshold;
  }

  static Offset getNormalizedSwipeVector(Offset position) {
    final distance = position.distance;
    if (distance == 0) return Offset.zero;
    return Offset(position.dx / distance, position.dy / distance);
  }

  static double getSwipeAngle(Offset position) {
    return position.direction;
  }
}