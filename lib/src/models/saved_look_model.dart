/// Saved Look Model
///
/// Represents saved outfit combinations with performance metrics,
/// categorization, and quick action support.
import 'product_model.dart';

/// Saved Look categories
enum LookCategory {
  casual('Casual', Icons.casual, 0xFF4CAF50),
  formal('Formal', Icons.business, 0xFF2196F3),
  party('Party', Icons.celebration, 0xFF9C27B0),
  work('Work', Icons.work, 0xFF607D8B),
  date('Date', Icons.favorite, 0xFFE91E63),
  workout('Workout', Icons.fitness_center, 0xFFFF9800),
  travel('Travel', Icons.airplanemode_active, 0xFF00BCD4),
  winter('Winter', Icons.ac_unit, 0xFF3F51B5),
  summer('Summer', Icons.wb_sunny, 0xFFFFEB3B);

  const LookCategory(this.displayName, this.icon, this.colorHex);
  final String displayName;
  final IconData icon;
  final int colorHex;
}

/// Performance metrics for saved looks
class LookPerformanceMetrics {
  final int tryOnCount;
  final int purchaseCount;
  final int shareCount;
  final int likeCount;
  final DateTime lastTryOn;
  final double averageRating; // User's own rating of the look
  final Map<String, int> occasionWearCount;

  const LookPerformanceMetrics({
    this.tryOnCount = 0,
    this.purchaseCount = 0,
    this.shareCount = 0,
    this.likeCount = 0,
    DateTime? lastTryOn,
    this.averageRating = 0.0,
    Map<String, int>? occasionWearCount,
  }) : lastTryOn = lastTryOn ?? DateTime.now(),
       occasionWearCount = occasionWearCount ?? {};

  LookPerformanceMetrics copyWith({
    int? tryOnCount,
    int? purchaseCount,
    int? shareCount,
    int? likeCount,
    DateTime? lastTryOn,
    double? averageRating,
    Map<String, int>? occasionWearCount,
  }) {
    return LookPerformanceMetrics(
      tryOnCount: tryOnCount ?? this.tryOnCount,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      shareCount: shareCount ?? this.shareCount,
      likeCount: likeCount ?? this.likeCount,
      lastTryOn: lastTryOn ?? this.lastTryOn,
      averageRating: averageRating ?? this.averageRating,
      occasionWearCount: occasionWearCount ?? this.occasionWearCount,
    );
  }
}

/// Main Saved Look class representing an outfit combination
class SavedLook {
  final String id;
  final String name;
  final String description;
  final List<Product> items;
  final LookCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isPublic;
  final List<String> tags;
  final String? thumbnailUrl;
  final LookPerformanceMetrics performance;
  final double totalPrice;
  final int timesWorn;
  final String? notes;
  final Map<String, dynamic> metadata;

  const SavedLook({
    required this.id,
    required this.name,
    this.description = '',
    required this.items,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isPublic = false,
    this.tags = const [],
    this.thumbnailUrl,
    LookPerformanceMetrics? performance,
    this.totalPrice = 0.0,
    this.timesWorn = 0,
    this.notes,
    this.metadata = const {},
  }) : performance = performance ?? const LookPerformanceMetrics();

  /// Get the primary item (usually the main clothing piece)
  Product? get primaryItem {
    if (items.isEmpty) return null;
    
    // Prioritize main clothing items over accessories
    final mainItems = items.where((item) => 
        item.category.toLowerCase() != 'accessories' &&
        item.category.toLowerCase() != 'jewelry' &&
        item.category.toLowerCase() != 'bags').toList();
    
    return mainItems.isNotEmpty ? mainItems.first : items.first;
  }

  /// Get accessory items
  List<Product> get accessories {
    return items.where((item) => 
        item.category.toLowerCase() == 'accessories' ||
        item.category.toLowerCase() == 'jewelry' ||
        item.category.toLowerCase() == 'bags').toList();
  }

  /// Get the main clothing items (excluding accessories)
  List<Product> get clothingItems {
    return items.where((item) => 
        item.category.toLowerCase() != 'accessories' &&
        item.category.toLowerCase() != 'jewelry' &&
        item.category.toLowerCase() != 'bags').toList();
  }

  /// Check if look is complete (has all necessary items)
  bool get isComplete {
    final categories = clothingItems.map((item) => item.category.toLowerCase()).toSet();
    
    // Basic completeness check - should have at least one top and one bottom
    // or be a dress/outfit
    final hasTop = categories.any((cat) => ['tops', 'shirts', 'blouses'].contains(cat));
    final hasBottom = categories.any((cat) => ['pants', 'skirts', 'bottoms'].contains(cat));
    final hasDress = categories.any((cat) => cat == 'dresses');
    
    return hasTop || hasDress;
  }

  /// Get look popularity score
  double get popularityScore {
    final weights = {
      'tryOnCount': 0.3,
      'purchaseCount': 0.3,
      'shareCount': 0.2,
      'likeCount': 0.2,
    };
    
    final metrics = performance;
    final maxTryOn = 50.0; // Normalize against expected max
    final maxPurchase = 20.0;
    final maxShare = 30.0;
    final maxLike = 100.0;
    
    final normalizedTryOn = (metrics.tryOnCount / maxTryOn).clamp(0.0, 1.0);
    final normalizedPurchase = (metrics.purchaseCount / maxPurchase).clamp(0.0, 1.0);
    final normalizedShare = (metrics.shareCount / maxShare).clamp(0.0, 1.0);
    final normalizedLike = (metrics.likeCount / maxLike).clamp(0.0, 1.0);
    
    return (normalizedTryOn * weights['tryOnCount']! +
            normalizedPurchase * weights['purchaseCount']! +
            normalizedShare * weights['shareCount']! +
            normalizedLike * weights['likeCount']!) * 100;
  }

  /// Get look value score (price vs performance)
  double get valueScore {
    if (totalPrice == 0) return 0.0;
    
    final performanceRatio = (performance.tryOnCount + performance.purchaseCount) / totalPrice;
    return (performanceRatio * 100).clamp(0.0, 100.0);
  }

  /// Factory constructor from JSON
  factory SavedLook.fromJson(Map<String, dynamic> json) {
    return SavedLook(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      category: LookCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => LookCategory.casual,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isPublic: json['isPublic'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      thumbnailUrl: json['thumbnailUrl'] as String?,
      performance: LookPerformanceMetrics(
        tryOnCount: json['performance']?['tryOnCount'] as int? ?? 0,
        purchaseCount: json['performance']?['purchaseCount'] as int? ?? 0,
        shareCount: json['performance']?['shareCount'] as int? ?? 0,
        likeCount: json['performance']?['likeCount'] as int? ?? 0,
        lastTryOn: json['performance']?['lastTryOn'] != null 
            ? DateTime.parse(json['performance']['lastTryOn'] as String)
            : null,
        averageRating: (json['performance']?['averageRating'] as num?)?.toDouble() ?? 0.0,
        occasionWearCount: Map<String, int>.from(json['performance']?['occasionWearCount'] ?? {}),
      ),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      timesWorn: json['timesWorn'] as int? ?? 0,
      notes: json['notes'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'category': category.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isFavorite': isFavorite,
      'isPublic': isPublic,
      'tags': tags,
      'thumbnailUrl': thumbnailUrl,
      'performance': {
        'tryOnCount': performance.tryOnCount,
        'purchaseCount': performance.purchaseCount,
        'shareCount': performance.shareCount,
        'likeCount': performance.likeCount,
        'lastTryOn': performance.lastTryOn.toIso8601String(),
        'averageRating': performance.averageRating,
        'occasionWearCount': performance.occasionWearCount,
      },
      'totalPrice': totalPrice,
      'timesWorn': timesWorn,
      'notes': notes,
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  SavedLook copyWith({
    String? id,
    String? name,
    String? description,
    List<Product>? items,
    LookCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isPublic,
    List<String>? tags,
    String? thumbnailUrl,
    LookPerformanceMetrics? performance,
    double? totalPrice,
    int? timesWorn,
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    return SavedLook(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isPublic: isPublic ?? this.isPublic,
      tags: tags ?? this.tags,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      performance: performance ?? this.performance,
      totalPrice: totalPrice ?? this.totalPrice,
      timesWorn: timesWorn ?? this.timesWorn,
      notes: notes ?? this.notes,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Quick actions available for saved looks
enum LookAction {
  edit('Edit', Icons.edit, 0xFF2196F3),
  share('Share', Icons.share, 0xFF4CAF50),
  tryOn('Try On', Icons.photo_camera, 0xFF9C27B0),
  favorite('Favorite', Icons.favorite, 0xFFE91E63),
  delete('Delete', Icons.delete, 0xFFF44336),
  duplicate('Duplicate', Icons.content_copy, 0xFF607D8B),
  wear('Mark as Worn', Icons.check_circle, 0xFF8BC34A);

  const LookAction(this.displayName, this.icon, this.colorHex);
  final String displayName;
  final IconData icon;
  final int colorHex;
}

/// User profile completion data
class ProfileCompletion {
  final double overallPercentage;
  final Map<String, double> sectionCompletion;
  final List<String> missingItems;
  final List<String> suggestions;

  const ProfileCompletion({
    this.overallPercentage = 0.0,
    this.sectionCompletion = const {},
    this.missingItems = const [],
    this.suggestions = const [],
  });

  /// Calculate profile completion percentage
  static ProfileCompletion calculateCompletion({
    required bool hasAvatar,
    required bool hasBasicInfo,
    required bool hasPreferences,
    required bool hasSavedItems,
    required bool hasReviewHistory,
    required int savedLooksCount,
  }) {
    final sectionCompletion = <String, double>{
      'avatar': hasAvatar ? 100.0 : 0.0,
      'basic_info': hasBasicInfo ? 100.0 : 0.0,
      'preferences': hasPreferences ? 100.0 : 0.0,
      'saved_items': hasSavedItems ? 100.0 : 0.0,
      'saved_looks': (savedLooksCount > 0) ? 100.0 : 0.0,
      'reviews': hasReviewHistory ? 100.0 : 0.0,
    };

    final overall = sectionCompletion.values.reduce((a, b) => a + b) / sectionCompletion.length;
    final missingItems = <String>[];
    final suggestions = <String>[];

    if (!hasAvatar) {
      missingItems.add('avatar');
      suggestions.add('Create your digital avatar for better fitting recommendations');
    }
    if (!hasBasicInfo) {
      missingItems.add('basic_info');
      suggestions.add('Complete your profile with personal information');
    }
    if (!hasPreferences) {
      missingItems.add('preferences');
      suggestions.add('Set your style preferences for personalized recommendations');
    }
    if (savedLooksCount == 0) {
      missingItems.add('saved_looks');
      suggestions.add('Start creating outfit combinations to get the most out of the app');
    }

    return ProfileCompletion(
      overallPercentage: overall,
      sectionCompletion: sectionCompletion,
      missingItems: missingItems,
      suggestions: suggestions,
    );
  }
}