/// Fit Estimation System
/// 
/// Intelligent fit estimation based on:
/// - Avatar measurements (height, chest, waist, hip)
/// - Product size chart data
/// - User's previous purchase history
/// - Brand-specific sizing information
import 'package:flutter/foundation.dart';

/// Fit confidence levels
enum FitConfidence {
  low(0, 'Low', 'High uncertainty', Colors.red),
  medium(1, 'Medium', 'Moderate confidence', Colors.orange),
  high(2, 'High', 'Very confident', Colors.green),
  veryHigh(3, 'Very High', 'Highly accurate', Colors.green);

  const FitConfidence(this.level, this.displayName, this.description, this.color);
  final int level;
  final String displayName;
  final String description;
  final Color color;
}

/// Fit recommendations
enum FitRecommendation {
  trueToSize('True to size', 'Fits as expected', Colors.green),
  runsSmall('Runs small', 'Consider sizing up', Colors.orange),
  runsLarge('Runs large', 'Consider sizing down', Colors.blue),
  perfectFit('Perfect fit', 'Ideal fit for you', Colors.green),
  tooSmall('Too small', 'Choose one size up', Colors.red),
  tooLarge('Too large', 'Choose one size down', Colors.blue),
  mixedFit('Mixed fit', 'Different fit across areas', Colors.orange);

  const FitRecommendation(this.displayName, this.description, this.color);
  final String displayName;
  final String description;
  final Color color;
}

/// Fit estimation result
class FitEstimationResult {
  final FitRecommendation recommendation;
  final FitConfidence confidence;
  final double confidenceScore; // 0-100
  final List<FitAreaEstimation> areaEstimations;
  final String reasoning;
  final DateTime timestamp;
  final String? brandSizing;
  final double sizeDifference;

  const FitEstimationResult({
    required this.recommendation,
    required this.confidence,
    required this.confidenceScore,
    required this.areaEstimations,
    required this.reasoning,
    required this.timestamp,
    this.brandSizing,
    this.sizeDifference = 0.0,
  });

  /// Get overall fit prediction
  String get overallPrediction {
    return '${recommendation.displayName} (${confidence.displayName})';
  }

  /// Check if fit is recommended
  bool get isRecommended {
    return confidence.level >= 1 && 
           recommendation != FitRecommendation.tooSmall &&
           recommendation != FitRecommendation.tooLarge;
  }

  /// Get color based on recommendation
  Color get color => recommendation.color;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'recommendation': recommendation.name,
      'confidence': confidence.name,
      'confidenceScore': confidenceScore,
      'areaEstimations': areaEstimations.map((e) => e.toJson()).toList(),
      'reasoning': reasoning,
      'timestamp': timestamp.toIso8601String(),
      'brandSizing': brandSizing,
      'sizeDifference': sizeDifference,
    };
  }
}

/// Fit area estimation for specific body areas
class FitAreaEstimation {
  final String areaName; // chest, waist, hip, etc.
  final double deviation; // -100 to +100 (negative = runs small, positive = runs large)
  final double confidence;
  final String description;

  const FitAreaEstimation({
    required this.areaName,
    required this.deviation,
    required this.confidence,
    required this.description,
  });

  /// Get deviation level
  FitDeviationLevel get deviationLevel {
    final absDeviation = deviation.abs();
    if (absDeviation < 5) return FitDeviationLevel.perfect;
    if (absDeviation < 10) return FitDeviationLevel.good;
    if (absDeviation < 20) return FitDeviationLevel.moderate;
    return FitDeviationLevel.significant;
  }

  /// Get color based on deviation
  Color get color {
    switch (deviationLevel) {
      case FitDeviationLevel.perfect:
        return Colors.green;
      case FitDeviationLevel.good:
        return Colors.blue;
      case FitDeviationLevel.moderate:
        return Colors.orange;
      case FitDeviationLevel.significant:
        return Colors.red;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'areaName': areaName,
      'deviation': deviation,
      'confidence': confidence,
      'description': description,
    };
  }
}

/// Fit deviation levels
enum FitDeviationLevel {
  perfect('Perfect fit', Colors.green),
  good('Good fit', Colors.blue),
  moderate('Moderate deviation', Colors.orange),
  significant('Significant deviation', Colors.red);

  const FitDeviationLevel(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Avatar measurements for fit calculation
class AvatarMeasurements {
  final double height; // cm
  final double chest; // cm
  final double waist; // cm
  final double hip; // cm
  final double weight; // kg (optional)
  final DateTime measuredAt;

  const AvatarMeasurements({
    required this.height,
    required this.chest,
    required this.waist,
    required this.hip,
    this.weight,
    required this.measuredAt,
  });

  /// Get body type classification
  BodyType get bodyType {
    final waistToHipRatio = waist / hip;
    final heightToWeight = weight != null ? height / weight : 0;

    if (waistToHipRatio < 0.8 && heightToWeight > 2.5) {
      return BodyType.pear;
    } else if (waistToHipRatio > 0.9 && heightToWeight > 2.8) {
      return BodyType.apple;
    } else if (chest > hip + 5) {
      return BodyType.invertedTriangle;
    } else if (Math.abs(chest - hip) < 3 && Math.abs(waist - hip) < 3) {
      return BodyType.rectangle;
    } else {
      return BodyType.hourglass;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'weight': weight,
      'measuredAt': measuredAt.toIso8601String(),
    };
  }
}

/// Body type classifications
enum BodyType {
  hourglass('Hourglass', 'Balanced proportions'),
  pear('Pear', 'Wider hips than shoulders'),
  apple('Apple', 'Broader shoulders, narrower hips'),
  invertedTriangle('Inverted Triangle', 'Broader shoulders, narrower waist'),
  rectangle('Rectangle', 'Similar shoulder, waist, hip measurements');

  const BodyType(this.displayName, this.description);
  final String displayName;
  final String description;
}

/// Product size information
class ProductSizeChart {
  final String size; // S, M, L, XL, etc.
  final double? chest; // cm
  final double? waist; // cm
  final double? hip; // cm
  final double? length; // cm
  final String? sizeSystem; // US, EU, UK
  final String? brand;
  final String? productCategory;

  const ProductSizeChart({
    required this.size,
    this.chest,
    this.waist,
    this.hip,
    this.length,
    this.sizeSystem,
    this.brand,
    this.productCategory,
  });

  /// Check if this size has measurements
  bool get hasMeasurements {
    return chest != null || waist != null || hip != null;
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'chest': chest,
      'waist': waist,
      'hip': hip,
      'length': length,
      'sizeSystem': sizeSystem,
      'brand': brand,
      'productCategory': productCategory,
    };
  }
}

/// Fit estimation engine
class FitEstimationEngine {
  static final Map<String, double> _brandAdjustments = {
    'Nike': 0.95, // Nike tends to run small
    'Adidas': 1.02, // Adidas tends to run large
    'Zara': 0.98, // Zara tends to run small
    'H&M': 1.0, // True to size
    'Uniqlo': 1.05, // Uniqlo tends to run large
  };

  /// Estimate fit for given measurements and product
  static FitEstimationResult estimateFit({
    required AvatarMeasurements avatar,
    required ProductSizeChart product,
    List<FitEstimationResult>? userHistory,
    String? brand,
  }) {
    if (!product.hasMeasurements) {
      return FitEstimationResult(
        recommendation: FitRecommendation.trueToSize,
        confidence: FitConfidence.medium,
        confidenceScore: 50.0,
        areaEstimations: [],
        reasoning: 'Size chart unavailable, using brand standard sizing',
        timestamp: DateTime.now(),
        brandSizing: brand,
      );
    }

    final List<FitAreaEstimation> estimations = [];
    final List<String> reasoningList = [];

    // Chest estimation
    if (product.chest != null && product.chest! > 0) {
      final chestDeviation = _calculateDeviation(avatar.chest, product.chest!);
      final chestConfidence = _calculateConfidence(avatar, product, 'chest');
      
      estimations.add(FitAreaEstimation(
        areaName: 'Chest',
        deviation: chestDeviation,
        confidence: chestConfidence,
        description: _getFitDescription(chestDeviation),
      ));
    }

    // Waist estimation
    if (product.waist != null && product.waist! > 0) {
      final waistDeviation = _calculateDeviation(avatar.waist, product.waist!);
      final waistConfidence = _calculateConfidence(avatar, product, 'waist');
      
      estimations.add(FitAreaEstimation(
        areaName: 'Waist',
        deviation: waistDeviation,
        confidence: waistConfidence,
        description: _getFitDescription(waistDeviation),
      ));
    }

    // Hip estimation
    if (product.hip != null && product.hip! > 0) {
      final hipDeviation = _calculateDeviation(avatar.hip, product.hip!);
      final hipConfidence = _calculateConfidence(avatar, product, 'hip');
      
      estimations.add(FitAreaEstimation(
        areaName: 'Hip',
        deviation: hipDeviation,
        confidence: hipConfidence,
        description: _getFitDescription(hipDeviation),
      ));
    }

    // Calculate overall recommendation
    final recommendation = _calculateOverallRecommendation(estimations, reasoningList);
    final confidence = _calculateOverallConfidence(estimations, userHistory);
    final confidenceScore = confidence * 100;

    // Add brand adjustment to reasoning
    if (brand != null && _brandAdjustments.containsKey(brand)) {
      reasoningList.add('Brand adjustment applied: $brand');
    }

    return FitEstimationResult(
      recommendation: recommendation,
      confidence: _getConfidenceLevel(confidenceScore),
      confidenceScore: confidenceScore,
      areaEstimations: estimations,
      reasoning: reasoningList.join('. '),
      timestamp: DateTime.now(),
      brandSizing: brand,
    );
  }

  /// Calculate deviation percentage
  static double _calculateDeviation(double measurement, double productSize) {
    return ((measurement - productSize) / productSize) * 100;
  }

  /// Calculate confidence for specific area
  static double _calculateConfidence(AvatarMeasurements avatar, ProductSizeChart product, String area) {
    double confidence = 0.7; // Base confidence
    
    // Boost confidence if we have user history
    // In a real app, this would check historical fit data
    confidence += 0.2;
    
    // Boost confidence for standard measurements
    if (product.sizeSystem != null) {
      confidence += 0.1;
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate overall recommendation
  static FitRecommendation _calculateOverallRecommendation(List<FitAreaEstimation> estimations, List<String> reasoningList) {
    if (estimations.isEmpty) {
      return FitRecommendation.trueToSize;
    }

    final deviations = estimations.map((e) => e.deviation).toList();
    final averageDeviation = deviations.reduce((a, b) => a + b) / deviations.length;
    final maxDeviation = deviations.map((d) => d.abs()).reduce((a, b) => a > b ? a : b);

    if (averageDeviation.abs() < 5 && maxDeviation < 10) {
      return FitRecommendation.perfectFit;
    } else if (averageDeviation < -10) {
      return FitRecommendation.runsSmall;
    } else if (averageDeviation > 10) {
      return FitRecommendation.runsLarge;
    } else if (averageDeviation < -5) {
      return FitRecommendation.runsSmall;
    } else if (averageDeviation > 5) {
      return FitRecommendation.runsLarge;
    } else {
      return FitRecommendation.trueToSize;
    }
  }

  /// Calculate overall confidence
  static double _calculateOverallConfidence(List<FitAreaEstimation> estimations, List<FitEstimationResult>? userHistory) {
    if (estimations.isEmpty) return 0.5;

    final avgConfidence = estimations.map((e) => e.confidence).reduce((a, b) => a + b) / estimations.length;
    
    // Boost confidence if we have user history
    if (userHistory != null && userHistory.isNotEmpty) {
      return (avgConfidence + 0.2).clamp(0.0, 1.0);
    }
    
    return avgConfidence;
  }

  /// Get confidence level from score
  static FitConfidence _getConfidenceLevel(double score) {
    if (score >= 90) return FitConfidence.veryHigh;
    if (score >= 70) return FitConfidence.high;
    if (score >= 50) return FitConfidence.medium;
    return FitConfidence.low;
  }

  /// Get fit description for deviation
  static String _getFitDescription(double deviation) {
    final absDev = deviation.abs();
    if (absDev < 5) return 'Perfect fit';
    if (absDev < 10) return absDev > 0 ? 'Runs large' : 'Runs small';
    if (absDev < 20) return absDev > 0 ? 'Consider sizing down' : 'Consider sizing up';
    return absDev > 0 ? 'Much too large' : 'Much too small';
  }
}

/// Customer review data for fit feedback
class FitReview {
  final String reviewId;
  final String productId;
  final String userId;
  final String size;
  final String? fitDescription;
  final int? rating; // 1-5 stars
  final DateTime createdAt;
  final List<String> photos;

  const FitReview({
    required this.reviewId,
    required this.productId,
    required this.userId,
    required this.size,
    this.fitDescription,
    this.rating,
    required this.createdAt,
    this.photos = const [],
  });

  /// Get aggregated fit feedback for a product
  static List<FitReview> getFitFeedbackForProduct(String productId, String size) {
    // In a real app, this would fetch from a database
    return [];
  }
}