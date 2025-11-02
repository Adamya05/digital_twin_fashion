/// Smart Recommendations System
/// 
/// Generates personalized recommendations including:
/// - Size recommendations
/// - Complementary products for complete looks
/// - Styling tips based on selected items
/// - Seasonal outfit recommendations
/// - Trending styling suggestions
import 'package:flutter/foundation.dart';
import 'pose_preset_model.dart';
import 'fit_estimation_model.dart';

/// Recommendation types
enum RecommendationType {
  sizeRecommendation('Size Recommendation', Icons.straighten),
  complementaryProduct('Complementary Product', Icons.adjacent_latest),
  stylingTip('Styling Tip', Icons.tips_and_updates),
  seasonalLook('Seasonal Look', Icons.seasonal),
  trendingStyle('Trending Style', Icons.trending_up),
  brandRecommendation('Brand Recommendation', Icons.label);

  const RecommendationType(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Recommendation priority levels
enum RecommendationPriority {
  high('High', 3, Colors.red),
  medium('Medium', 2, Colors.orange),
  low('Low', 1, Colors.blue),
  informational('Info', 0, Colors.grey);

  const RecommendationPriority(this.displayName, this.value, this.color);
  final String displayName;
  final int value;
  final Color color;
}

/// Base recommendation class
class Recommendation {
  final String id;
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String description;
  final String? action;
  final String? imageUrl;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;
  final double confidence; // 0.0 to 1.0

  const Recommendation({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.description,
    this.action,
    this.imageUrl,
    required this.createdAt,
    this.metadata = const {},
    this.confidence = 0.8,
  });

  /// Get color based on priority
  Color get color => priority.color;

  /// Check if recommendation is actionable
  bool get isActionable => action != null;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'priority': priority.name,
      'title': title,
      'description': description,
      'action': action,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'metadata': metadata,
      'confidence': confidence,
    };
  }
}

/// Size recommendation
class SizeRecommendation extends Recommendation {
  final String productId;
  final String recommendedSize;
  final String currentSize;
  final FitEstimationResult fitEstimation;
  final List<String> alternativeSizes;
  final double confidence;

  const SizeRecommendation({
    required this.productId,
    required this.recommendedSize,
    required this.currentSize,
    required this.fitEstimation,
    this.alternativeSizes = const [],
    double confidence = 0.9,
  }) : super(
          id: 'size_$productId',
          type: RecommendationType.sizeRecommendation,
          priority: RecommendationPriority.high,
          title: 'Size Recommendation',
          description: fitEstimation.recommendation.displayName,
          confidence: confidence,
          metadata: {
            'productId': productId,
            'recommendedSize': recommendedSize,
            'currentSize': currentSize,
            'alternativeSizes': alternativeSizes,
          },
        );

  /// Get recommendation action text
  String get actionText {
    switch (fitEstimation.recommendation) {
      case FitRecommendation.runsSmall:
        return 'Size up to $recommendedSize';
      case FitRecommendation.runsLarge:
        return 'Size down to $recommendedSize';
      case FitRecommendation.trueToSize:
        return 'Current size ($currentSize) is correct';
      case FitRecommendation.perfectFit:
        return 'Perfect fit in $recommendedSize';
      default:
        return 'Try $recommendedSize instead';
    }
  }
}

/// Complementary product recommendation
class ComplementaryProductRecommendation extends Recommendation {
  final String primaryProductId;
  final String complementaryProductId;
  final String complementaryProductName;
  final String complementaryProductCategory;
  final double compatibilityScore;
  final String reason;
  final List<String> colorSuggestions;
  final List<String> styleMatchingTags;

  const ComplementaryProductRecommendation({
    required this.primaryProductId,
    required this.complementaryProductId,
    required this.complementaryProductName,
    required this.complementaryProductCategory,
    required this.compatibilityScore,
    required this.reason,
    this.colorSuggestions = const [],
    this.styleMatchingTags = const [],
  }) : super(
          id: 'complement_$primaryProductId\_$complementaryProductId',
          type: RecommendationType.complementaryProduct,
          priority: RecommendationPriority.medium,
          title: 'Complete the Look',
          description: '$complementaryProductName pairs perfectly',
          metadata: {
            'primaryProductId': primaryProductId,
            'complementaryProductId': complementaryProductId,
            'compatibilityScore': compatibilityScore,
            'reason': reason,
            'colorSuggestions': colorSuggestions,
            'styleMatchingTags': styleMatchingTags,
          },
        );

  /// Get styling suggestions
  List<String> get stylingSuggestions {
    final suggestions = <String>[];
    
    if (compatibilityScore > 0.8) {
      suggestions.add('This combination is highly versatile');
    }
    
    if (styleMatchingTags.contains('trendy')) {
      suggestions.add('Currently trending combination');
    }
    
    if (styleMatchingTags.contains('classic')) {
      suggestions.add('Timeless styling choice');
    }
    
    return suggestions;
  }
}

/// Styling tip recommendation
class StylingTip extends Recommendation {
  final String productId;
  final String tip;
  final String category; // 'casual', 'formal', 'party', 'work', etc.
  final PosePreset? recommendedPose;
  final List<String> colorPairings;
  final List<String> accessorySuggestions;
  final String? occasion;

  const StylingTip({
    required this.productId,
    required this.tip,
    required this.category,
    this.recommendedPose,
    this.colorPairings = const [],
    this.accessorySuggestions = const [],
    this.occasion,
  }) : super(
          id: 'tip_$productId\_${DateTime.now().millisecondsSinceEpoch}',
          type: RecommendationType.stylingTip,
          priority: RecommendationPriority.informational,
          title: 'Styling Tip',
          description: tip,
          metadata: {
            'productId': productId,
            'category': category,
            'colorPairings': colorPairings,
            'accessorySuggestions': accessorySuggestions,
            'occasion': occasion,
            'recommendedPose': recommendedPose?.name,
          },
        );

  /// Get styling category display
  String get categoryDisplay {
    return category.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)).join(' ');
  }
}

/// Seasonal outfit recommendation
class SeasonalLookRecommendation extends Recommendation {
  final List<String> productIds;
  final String season; // 'spring', 'summer', 'fall', 'winter'
  final String lookName;
  final List<String> items;
  final String theme;
  final List<String> colorPalette;
  final List<String> weatherConditions;

  const SeasonalLookRecommendation({
    required this.productIds,
    required this.season,
    required this.lookName,
    required this.items,
    required this.theme,
    this.colorPalette = const [],
    this.weatherConditions = const [],
  }) : super(
          id: 'seasonal_${season}_${DateTime.now().millisecondsSinceEpoch}',
          type: RecommendationType.seasonalLook,
          priority: RecommendationPriority.medium,
          title: 'Seasonal Look',
          description: lookName,
          metadata: {
            'season': season,
            'lookName': lookName,
            'items': items,
            'theme': theme,
            'colorPalette': colorPalette,
            'weatherConditions': weatherConditions,
          },
        );

  /// Get season display name
  String get seasonDisplay {
    return season[0].toUpperCase() + season.substring(1);
  }

  /// Check if recommendation is relevant for current weather
  bool isWeatherRelevant(String currentCondition) {
    return weatherConditions.contains(currentCondition);
  }
}

/// Trending style recommendation
class TrendingStyleRecommendation extends Recommendation {
  final List<String> productIds;
  final String trendName;
  final String description;
  final List<String> trendTags;
  final DateTime trendStartDate;
  final DateTime trendEndDate;
  final String source; // 'fashion_week', 'social_media', 'celebrity', etc.
  final double popularityScore; // 0.0 to 1.0

  const TrendingStyleRecommendation({
    required this.productIds,
    required this.trendName,
    required this.description,
    required this.trendTags,
    required this.trendStartDate,
    required this.trendEndDate,
    required this.source,
    required this.popularityScore,
  }) : super(
          id: 'trend_${trendName.replaceAll(' ', '_')}',
          type: RecommendationType.trendingStyle,
          priority: RecommendationPriority.medium,
          title: 'Trending Style',
          description: trendName,
          metadata: {
            'trendName': trendName,
            'description': description,
            'trendTags': trendTags,
            'trendStartDate': trendStartDate.toIso8601String(),
            'trendEndDate': trendEndDate.toIso8601String(),
            'source': source,
            'popularityScore': popularityScore,
          },
        );

  /// Check if trend is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(trendStartDate) && now.isBefore(trendEndDate);
  }

  /// Get trend urgency based on time remaining
  String get trendUrgency {
    final now = DateTime.now();
    final daysRemaining = trendEndDate.difference(now).inDays;
    
    if (daysRemaining <= 7) return 'Ending soon!';
    if (daysRemaining <= 30) return 'Popular now';
    return 'Upcoming trend';
  }
}

/// Smart recommendations engine
class SmartRecommendationsEngine {
  static final List<String> _trendingColors = [
    'Sage Green', 'Burgundy', 'Cream', 'Navy', 'Terracotta'
  ];
  
  static final List<String> _seasonalTrends = {
    'spring': ['Pastels', 'Floral Prints', 'Light Fabrics'],
    'summer': ['Bright Colors', 'Linen', 'Swimwear'],
    'fall': ['Earth Tones', 'Leather', 'Layering'],
    'winter': ['Coats', 'Dark Colors', 'Knitwear'],
  };

  /// Generate size recommendations
  static List<SizeRecommendation> generateSizeRecommendations({
    required AvatarMeasurements avatar,
    required List<ProductSizeChart> availableSizes,
    required FitEstimationResult currentFit,
  }) {
    final recommendations = <SizeRecommendation>[];

    for (final size in availableSizes) {
      final estimation = FitEstimationEngine.estimateFit(
        avatar: avatar,
        product: size,
      );

      if (estimation.isRecommended && estimation.confidence.level >= 2) {
        recommendations.add(SizeRecommendation(
          productId: 'unknown', // Would be provided by caller
          recommendedSize: size.size,
          currentSize: 'current', // Would be determined by caller
          fitEstimation: estimation,
        ));
      }
    }

    return recommendations;
  }

  /// Generate complementary product recommendations
  static List<ComplementaryProductRecommendation> generateComplementaryRecommendations({
    required String primaryProductId,
    required String primaryProductCategory,
    String? brand,
    List<String>? userPreferences,
  }) {
    final recommendations = <ComplementaryProductRecommendation>[];

    // Simple complementary logic based on category
    final complements = _getComplementaryCategories(primaryProductCategory);
    
    for (final category in complements) {
      recommendations.add(ComplementaryProductRecommendation(
        primaryProductId: primaryProductId,
        complementaryProductId: 'complement_$category',
        complementaryProductName: _getProductName(category),
        complementaryProductCategory: category,
        compatibilityScore: 0.85,
        reason: 'Pairs well with your selected item',
        colorSuggestions: _getSuggestedColors(brand),
        styleMatchingTags: _getStyleTags(category),
      ));
    }

    return recommendations;
  }

  /// Generate styling tips
  static List<StylingTip> generateStylingTips({
    required String productId,
    required String productCategory,
    PosePreset? currentPose,
    String? season,
  }) {
    final tips = <StylingTip>[];

    // Generate category-specific tips
    final categoryTips = _getStylingTipsForCategory(productCategory);
    
    for (final tipData in categoryTips) {
      tips.add(StylingTip(
        productId: productId,
        tip: tipData['tip'],
        category: tipData['category'],
        recommendedPose: tipData['pose'],
        colorPairings: tipData['colors'] ?? [],
        accessorySuggestions: tipData['accessories'] ?? [],
        occasion: tipData['occasion'],
      ));
    }

    return tips;
  }

  /// Generate seasonal recommendations
  static List<SeasonalLookRecommendation> generateSeasonalRecommendations({
    required String season,
    required List<String> userProductIds,
  }) {
    final recommendations = <SeasonalLookRecommendation>[];

    if (_seasonalTrends.containsKey(season)) {
      final trends = _seasonalTrends[season]!;
      
      recommendations.add(SeasonalLookRecommendation(
        productIds: userProductIds,
        season: season,
        lookName: '${seasonDisplay(season)} Essentials',
        items: trends,
        theme: 'seasonal',
        colorPalette: _trendingColors,
        weatherConditions: _getWeatherForSeason(season),
      ));
    }

    return recommendations;
  }

  /// Generate trending recommendations
  static List<TrendingStyleRecommendation> generateTrendingRecommendations({
    required List<String> userProductIds,
    String? source,
  }) {
    final recommendations = <TrendingStyleRecommendation>[];

    // Sample trending styles
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 30));

    recommendations.add(TrendingStyleRecommendation(
      productIds: userProductIds,
      trendName: 'Y2K Revival',
      description: 'Early 2000s fashion is making a comeback',
      trendTags: ['denim', 'metallic', 'crop_tops'],
      trendStartDate: now.subtract(const Duration(days: 14)),
      trendEndDate: endDate,
      source: 'fashion_week',
      popularityScore: 0.9,
    ));

    return recommendations;
  }

  /// Get complementary categories for a product category
  static List<String> _getComplementaryCategories(String category) {
    final complements = <String, List<String>>{
      'tops': ['bottoms', 'jackets', 'accessories'],
      'dresses': ['jackets', 'shoes', 'jewelry'],
      'pants': ['tops', 'shoes', 'belts'],
      'skirts': ['tops', 'jackets', 'shoes'],
      'jackets': ['tops', 'bottoms', 'accessories'],
      'shoes': ['outfits', 'accessories'],
    };

    return complements[category] ?? ['accessories'];
  }

  /// Get product name for category
  static String _getProductName(String category) {
    final names = <String, String>{
      'bottoms': 'Perfect Bottom Piece',
      'jackets': 'Stylish Jacket',
      'accessories': 'Fashion Accessory',
      'shoes': 'Comfortable Shoes',
      'jewelry': 'Elegant Jewelry',
      'belts': 'Classic Belt',
    };

    return names[category] ?? 'Matching Item';
  }

  /// Get suggested colors for brand
  static List<String> _getSuggestedColors(String? brand) {
    final brandColors = <String, List<String>>{
      'Nike': ['Black', 'White', 'Grey'],
      'Zara': ['Navy', 'Beige', 'Black'],
      'H&M': ['White', 'Black', 'Denim Blue'],
    };

    return brandColors[brand] ?? _trendingColors;
  }

  /// Get style tags for category
  static List<String> _getStyleTags(String category) {
    final tags = <String, List<String>>{
      'jackets': ['versatile', 'trendy', 'layering'],
      'accessories': ['essential', 'versatile', 'statement'],
      'shoes': ['comfortable', 'practical', 'stylish'],
    };

    return tags[category] ?? ['stylish', 'versatile'];
  }

  /// Get styling tips for category
  static List<Map<String, dynamic>> _getStylingTipsForCategory(String category) {
    return [
      {
        'tip': 'This piece works great for both casual and semi-formal occasions',
        'category': 'versatile',
        'colors': ['Neutral tones', 'Classic colors'],
        'accessories': ['Minimal jewelry', 'Classic watch'],
      },
      {
        'tip': 'Perfect for layering - try wearing over a simple tee or under a blazer',
        'category': 'layering',
        'pose': PosePreset.threeQuarterView,
        'colors': ['Earth tones', 'Seasonal colors'],
      },
    ];
  }

  /// Get weather conditions for season
  static List<String> _getWeatherForSeason(String season) {
    final weatherMap = <String, List<String>>{
      'spring': ['mild', 'rainy', 'sunny'],
      'summer': ['hot', 'sunny', 'humid'],
      'fall': ['cool', 'windy', 'crisp'],
      'winter': ['cold', 'snowy', 'windy'],
    };

    return weatherMap[season] ?? ['moderate'];
  }

  /// Format season name
  static String seasonDisplay(String season) {
    return season[0].toUpperCase() + season.substring(1);
  }
}

/// User preference tracking
class UserPreferences {
  final Set<String> preferredBrands;
  final Set<String> preferredColors;
  final Set<String> preferredStyles;
  final Set<String> avoidedCategories;
  final double priceRange; // 0.0 to 1.0 (budget to luxury)
  final int styleConsistency; // How consistent user style is

  const UserPreferences({
    this.preferredBrands = const {},
    this.preferredColors = const {},
    this.preferredStyles = const {},
    this.avoidedCategories = const {},
    this.priceRange = 0.5,
    this.styleConsistency = 3, // 1-5 scale
  });

  UserPreferences copyWith({
    Set<String>? preferredBrands,
    Set<String>? preferredColors,
    Set<String>? preferredStyles,
    Set<String>? avoidedCategories,
    double? priceRange,
    int? styleConsistency,
  }) {
    return UserPreferences(
      preferredBrands: preferredBrands ?? this.preferredBrands,
      preferredColors: preferredColors ?? this.preferredColors,
      preferredStyles: preferredStyles ?? this.preferredStyles,
      avoidedCategories: avoidedCategories ?? this.avoidedCategories,
      priceRange: priceRange ?? this.priceRange,
      styleConsistency: styleConsistency ?? this.styleConsistency,
    );
  }

  /// Check if recommendation aligns with user preferences
  bool alignsWithPreferences(Recommendation recommendation) {
    // Check if any preferred brands/colors/styles are mentioned
    final metadata = recommendation.metadata;
    
    if (metadata['brand'] != null && preferredBrands.contains(metadata['brand'])) {
      return true;
    }
    
    if (metadata['colorSuggestions'] != null) {
      final colors = metadata['colorSuggestions'] as List<String>;
      if (colors.any((color) => preferredColors.contains(color))) {
        return true;
      }
    }
    
    return false;
  }
}