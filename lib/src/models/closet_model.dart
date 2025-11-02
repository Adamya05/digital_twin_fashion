import 'product_model.dart';

/// Comprehensive Closet Management System Models
/// 
/// This file contains all the models needed for managing user closets,
/// saved items, outfits, and related functionality.

/// Main closet item model - represents an item in user's closet
class ClosetItem {
  final String id;
  final Product product;
  final DateTime savedAt;
  final String? notes;
  final List<String> customTags;
  final int wearCount;
  final bool isFavorited;
  final bool isInOutfit;
  final DateTime? lastWornDate;
  final ItemCondition condition;
  final String selectedSize;
  final String selectedColor;
  final List<OutfitUsage> usageHistory;
  final double purchasePrice;
  final DateTime? purchaseDate;
  final bool isOnSale;
  final double salePrice;
  final ItemRating rating;
  final Map<String, dynamic> customFields;

  ClosetItem({
    required this.id,
    required this.product,
    required this.savedAt,
    this.notes,
    this.customTags = const [],
    this.wearCount = 0,
    this.isFavorited = false,
    this.isInOutfit = false,
    this.lastWornDate,
    this.condition = ItemCondition.newItem,
    required this.selectedSize,
    required this.selectedColor,
    this.usageHistory = const [],
    this.purchasePrice = 0.0,
    this.purchaseDate,
    this.isOnSale = false,
    this.salePrice = 0.0,
    this.rating = const ItemRating(),
    this.customFields = const {},
  });

  factory ClosetItem.fromJson(Map<String, dynamic> json) {
    return ClosetItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
      customTags: List<String>.from(json['customTags'] as List? ?? []),
      wearCount: json['wearCount'] as int? ?? 0,
      isFavorited: json['isFavorited'] as bool? ?? false,
      isInOutfit: json['isInOutfit'] as bool? ?? false,
      lastWornDate: json['lastWornDate'] != null 
          ? DateTime.parse(json['lastWornDate'] as String) 
          : null,
      condition: ItemCondition.values.byName(json['condition'] as String? ?? 'new'),
      selectedSize: json['selectedSize'] as String? ?? '',
      selectedColor: json['selectedColor'] as String? ?? '',
      usageHistory: (json['usageHistory'] as List<dynamic>?)
          ?.map((item) => OutfitUsage.fromJson(item))
          .toList() ?? [],
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: json['purchaseDate'] != null 
          ? DateTime.parse(json['purchaseDate'] as String) 
          : null,
      isOnSale: json['isOnSale'] as bool? ?? false,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      rating: ItemRating.fromJson(json['rating'] as Map<String, dynamic>? ?? {}),
      customFields: json['customFields'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'notes': notes,
      'customTags': customTags,
      'wearCount': wearCount,
      'isFavorited': isFavorited,
      'isInOutfit': isInOutfit,
      'lastWornDate': lastWornDate?.toIso8601String(),
      'condition': condition.name,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor,
      'usageHistory': usageHistory.map((item) => item.toJson()).toList(),
      'purchasePrice': purchasePrice,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'isOnSale': isOnSale,
      'salePrice': salePrice,
      'rating': rating.toJson(),
      'customFields': customFields,
    };
  }

  ClosetItem copyWith({
    String? id,
    Product? product,
    DateTime? savedAt,
    String? notes,
    List<String>? customTags,
    int? wearCount,
    bool? isFavorited,
    bool? isInOutfit,
    DateTime? lastWornDate,
    ItemCondition? condition,
    String? selectedSize,
    String? selectedColor,
    List<OutfitUsage>? usageHistory,
    double? purchasePrice,
    DateTime? purchaseDate,
    bool? isOnSale,
    double? salePrice,
    ItemRating? rating,
    Map<String, dynamic>? customFields,
  }) {
    return ClosetItem(
      id: id ?? this.id,
      product: product ?? this.product,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
      customTags: customTags ?? this.customTags,
      wearCount: wearCount ?? this.wearCount,
      isFavorited: isFavorited ?? this.isFavorited,
      isInOutfit: isInOutfit ?? this.isInOutfit,
      lastWornDate: lastWornDate ?? this.lastWornDate,
      condition: condition ?? this.condition,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      usageHistory: usageHistory ?? this.usageHistory,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      isOnSale: isOnSale ?? this.isOnSale,
      salePrice: salePrice ?? this.salePrice,
      rating: rating ?? this.rating,
      customFields: customFields ?? this.customFields,
    );
  }

  /// Get total cost per wear
  double get costPerWear {
    if (wearCount == 0) return purchasePrice;
    return purchasePrice / wearCount;
  }

  /// Get days since last worn
  int get daysSinceLastWorn {
    if (lastWornDate == null) return -1;
    return DateTime.now().difference(lastWornDate!).inDays;
  }

  /// Get all tags (product tags + custom tags)
  List<String> get allTags => [...product.tags, ...customTags];

  /// Check if item matches search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return product.name.toLowerCase().contains(lowerQuery) ||
           product.description.toLowerCase().contains(lowerQuery) ||
           product.vendor.name.toLowerCase().contains(lowerQuery) ||
           allTags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClosetItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Item condition enum
enum ItemCondition {
  newItem,
  excellent,
  good,
  fair,
  poor,
  wornOut,
}

/// Outfit model - represents a saved outfit combination
class Outfit {
  final String id;
  final String name;
  final String? description;
  final List<OutfitItem> items;
  final DateTime createdAt;
  final DateTime lastModified;
  final List<String> tags;
  final OutfitCategory category;
  final Season season;
  final Occasion occasion;
  final List<OutfitImage> images;
  final bool isFavorited;
  final int wearCount;
  final DateTime? lastWornDate;
  final OutfitRating rating;
  final bool isPublic;
  final String? sharedWithUserIds;
  final int? totalLikes;
  final List<String> comments;
  final Map<String, dynamic> metadata;

  Outfit({
    required this.id,
    required this.name,
    this.description,
    required this.items,
    required this.createdAt,
    required this.lastModified,
    this.tags = const [],
    this.category = OutfitCategory.casual,
    this.season = Season.all,
    this.occasion = Occasion.everyday,
    this.images = const [],
    this.isFavorited = false,
    this.wearCount = 0,
    this.lastWornDate,
    this.rating = const OutfitRating(),
    this.isPublic = false,
    this.sharedWithUserIds,
    this.totalLikes = 0,
    this.comments = const [],
    this.metadata = const {},
  });

  factory Outfit.fromJson(Map<String, dynamic> json) {
    return Outfit(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => OutfitItem.fromJson(item))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: DateTime.parse(json['lastModified'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
      category: OutfitCategory.values.byName(json['category'] as String? ?? 'casual'),
      season: Season.values.byName(json['season'] as String? ?? 'all'),
      occasion: Occasion.values.byName(json['occasion'] as String? ?? 'everyday'),
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => OutfitImage.fromJson(img))
          .toList() ?? [],
      isFavorited: json['isFavorited'] as bool? ?? false,
      wearCount: json['wearCount'] as int? ?? 0,
      lastWornDate: json['lastWornDate'] != null 
          ? DateTime.parse(json['lastWornDate'] as String) 
          : null,
      rating: OutfitRating.fromJson(json['rating'] as Map<String, dynamic>? ?? {}),
      isPublic: json['isPublic'] as bool? ?? false,
      sharedWithUserIds: json['sharedWithUserIds'] as String?,
      totalLikes: json['totalLikes'] as int? ?? 0,
      comments: List<String>.from(json['comments'] as List? ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified.toIso8601String(),
      'tags': tags,
      'category': category.name,
      'season': season.name,
      'occasion': occasion.name,
      'images': images.map((img) => img.toJson()).toList(),
      'isFavorited': isFavorited,
      'wearCount': wearCount,
      'lastWornDate': lastWornDate?.toIso8601String(),
      'rating': rating.toJson(),
      'isPublic': isPublic,
      'sharedWithUserIds': sharedWithUserIds,
      'totalLikes': totalLikes,
      'comments': comments,
      'metadata': metadata,
    };
  }

  Outfit copyWith({
    String? id,
    String? name,
    String? description,
    List<OutfitItem>? items,
    DateTime? createdAt,
    DateTime? lastModified,
    List<String>? tags,
    OutfitCategory? category,
    Season? season,
    Occasion? occasion,
    List<OutfitImage>? images,
    bool? isFavorited,
    int? wearCount,
    DateTime? lastWornDate,
    OutfitRating? rating,
    bool? isPublic,
    String? sharedWithUserIds,
    int? totalLikes,
    List<String>? comments,
    Map<String, dynamic>? metadata,
  }) {
    return Outfit(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      season: season ?? this.season,
      occasion: occasion ?? this.occasion,
      images: images ?? this.images,
      isFavorited: isFavorited ?? this.isFavorited,
      wearCount: wearCount ?? this.wearCount,
      lastWornDate: lastWornDate ?? this.lastWornDate,
      rating: rating ?? this.rating,
      isPublic: isPublic ?? this.isPublic,
      sharedWithUserIds: sharedWithUserIds ?? this.sharedWithUserIds,
      totalLikes: totalLikes ?? this.totalLikes,
      comments: comments ?? this.comments,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get primary image of the outfit
  String? get primaryImage {
    if (images.isNotEmpty) return images.first.imageUrl;
    if (items.isNotEmpty) return items.first.closetItem.product.primaryImage;
    return null;
  }

  /// Get total outfit value
  double get totalValue {
    return items.fold(0.0, (sum, item) => sum + item.closetItem.purchasePrice);
  }

  /// Get outfit pieces by category
  Map<String, List<OutfitItem>> get itemsByCategory {
    return items.fold({}, (map, item) {
      final category = item.closetItem.product.category;
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(item);
      return map;
    });
  }

  /// Check if outfit matches search query
  bool matchesSearch(String query) {
    if (query.isEmpty) return true;
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
           (description?.toLowerCase().contains(lowerQuery) ?? false) ||
           tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Outfit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Individual item in an outfit
class OutfitItem {
  final String id;
  final ClosetItem closetItem;
  final int order;
  final String? notes;

  OutfitItem({
    required this.id,
    required this.closetItem,
    required this.order,
    this.notes,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) {
    return OutfitItem(
      id: json['id'] as String,
      closetItem: ClosetItem.fromJson(json['closetItem'] as Map<String, dynamic>),
      order: json['order'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'closetItem': closetItem.toJson(),
      'order': order,
      'notes': notes,
    };
  }

  OutfitItem copyWith({
    String? id,
    ClosetItem? closetItem,
    int? order,
    String? notes,
  }) {
    return OutfitItem(
      id: id ?? this.id,
      closetItem: closetItem ?? this.closetItem,
      order: order ?? this.order,
      notes: notes ?? this.notes,
    );
  }
}

/// Outfit usage tracking
class OutfitUsage {
  final String id;
  final DateTime wornDate;
  final String? notes;
  final List<String> photos;
  final int? occasion;

  OutfitUsage({
    required this.id,
    required this.wornDate,
    this.notes,
    this.photos = const [],
    this.occasion,
  });

  factory OutfitUsage.fromJson(Map<String, dynamic> json) {
    return OutfitUsage(
      id: json['id'] as String,
      wornDate: DateTime.parse(json['wornDate'] as String),
      notes: json['notes'] as String?,
      photos: List<String>.from(json['photos'] as List? ?? []),
      occasion: json['occasion'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wornDate': wornDate.toIso8601String(),
      'notes': notes,
      'photos': photos,
      'occasion': occasion,
    };
  }
}

/// Item rating and review
class ItemRating {
  final double overall;
  final double quality;
  final double fit;
  final double comfort;
  final double value;
  final int wearCount;
  final String? review;
  final DateTime lastRated;
  final List<String> photos;

  const ItemRating({
    this.overall = 0.0,
    this.quality = 0.0,
    this.fit = 0.0,
    this.comfort = 0.0,
    this.value = 0.0,
    this.wearCount = 0,
    this.review,
    this.lastRated = const DateTime.fromMillisecondsSinceEpoch(0),
    this.photos = const [],
  });

  factory ItemRating.fromJson(Map<String, dynamic> json) {
    return ItemRating(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      quality: (json['quality'] as num?)?.toDouble() ?? 0.0,
      fit: (json['fit'] as num?)?.toDouble() ?? 0.0,
      comfort: (json['comfort'] as num?)?.toDouble() ?? 0.0,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      wearCount: json['wearCount'] as int? ?? 0,
      review: json['review'] as String?,
      lastRated: json['lastRated'] != null 
          ? DateTime.parse(json['lastRated'] as String)
          : DateTime.now(),
      photos: List<String>.from(json['photos'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'quality': quality,
      'fit': fit,
      'comfort': comfort,
      'value': value,
      'wearCount': wearCount,
      'review': review,
      'lastRated': lastRated.toIso8601String(),
      'photos': photos,
    };
  }

  ItemRating copyWith({
    double? overall,
    double? quality,
    double? fit,
    double? comfort,
    double? value,
    int? wearCount,
    String? review,
    DateTime? lastRated,
    List<String>? photos,
  }) {
    return ItemRating(
      overall: overall ?? this.overall,
      quality: quality ?? this.quality,
      fit: fit ?? this.fit,
      comfort: comfort ?? this.comfort,
      value: value ?? this.value,
      wearCount: wearCount ?? this.wearCount,
      review: review ?? this.review,
      lastRated: lastRated ?? this.lastRated,
      photos: photos ?? this.photos,
    );
  }
}

/// Outfit rating and review
class OutfitRating {
  final double overall;
  final int totalLikes;
  final int totalShares;
  final double averageRating;
  final int ratingCount;
  final Map<int, int> ratingDistribution;
  final List<OutfitReview> reviews;

  const OutfitRating({
    this.overall = 0.0,
    this.totalLikes = 0,
    this.totalShares = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    this.ratingDistribution = const {},
    this.reviews = const [],
  });

  factory OutfitRating.fromJson(Map<String, dynamic> json) {
    return OutfitRating(
      overall: (json['overall'] as num?)?.toDouble() ?? 0.0,
      totalLikes: json['totalLikes'] as int? ?? 0,
      totalShares: json['totalShares'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      ratingDistribution: (json['ratingDistribution'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(int.parse(key), value as int)) ?? {},
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => OutfitReview.fromJson(review))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'totalLikes': totalLikes,
      'totalShares': totalShares,
      'averageRating': averageRating,
      'ratingCount': ratingCount,
      'ratingDistribution': ratingDistribution.map((key, value) => MapEntry(key.toString(), value)),
      'reviews': reviews.map((review) => review.toJson()).toList(),
    };
  }
}

/// Outfit review from community
class OutfitReview {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final int helpful;

  OutfitReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.helpful = 0,
  });

  factory OutfitReview.fromJson(Map<String, dynamic> json) {
    return OutfitReview(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      helpful: json['helpful'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'helpful': helpful,
    };
  }
}

/// Outfit image
class OutfitImage {
  final String id;
  final String imageUrl;
  final String? description;
  final DateTime createdAt;
  final bool isPrimary;

  OutfitImage({
    required this.id,
    required this.imageUrl,
    this.description,
    required this.createdAt,
    this.isPrimary = false,
  });

  factory OutfitImage.fromJson(Map<String, dynamic> json) {
    return OutfitImage(
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPrimary: json['isPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isPrimary': isPrimary,
    };
  }
}

// ==================== ENUMS ====================

/// Outfit categories
enum OutfitCategory {
  casual,
  formal,
  business,
  sporty,
  party,
  date,
  work,
  weekend,
  travel,
  special,
}

/// Seasonal categorization
enum Season {
  spring,
  summer,
  fall,
  winter,
  all,
}

/// Occasion types
enum Occasion {
  everyday,
  work,
  formal,
  casual,
  party,
  date,
  exercise,
  travel,
  interview,
  wedding,
  date,
  casual,
}

/// Closet analytics data
class ClosetAnalytics {
  final int totalItems;
  final int totalOutfits;
  final Map<String, int> itemsByCategory;
  final Map<String, int> itemsByBrand;
  final double totalValue;
  final double averageCostPerWear;
  final int mostWornItem;
  final Map<String, int> wearingFrequency;
  final Map<String, int> seasonalUsage;
  final List<AnalyticsInsight> insights;

  ClosetAnalytics({
    required this.totalItems,
    required this.totalOutfits,
    required this.itemsByCategory,
    required this.itemsByBrand,
    required this.totalValue,
    required this.averageCostPerWear,
    required this.mostWornItem,
    required this.wearingFrequency,
    required this.seasonalUsage,
    required this.insights,
  });

  factory ClosetAnalytics.fromJson(Map<String, dynamic> json) {
    return ClosetAnalytics(
      totalItems: json['totalItems'] as int,
      totalOutfits: json['totalOutfits'] as int,
      itemsByCategory: Map<String, int>.from(json['itemsByCategory'] as Map),
      itemsByBrand: Map<String, int>.from(json['itemsByBrand'] as Map),
      totalValue: (json['totalValue'] as num).toDouble(),
      averageCostPerWear: (json['averageCostPerWear'] as num).toDouble(),
      mostWornItem: json['mostWornItem'] as int,
      wearingFrequency: Map<String, int>.from(json['wearingFrequency'] as Map),
      seasonalUsage: Map<String, int>.from(json['seasonalUsage'] as Map),
      insights: (json['insights'] as List<dynamic>?)
          ?.map((insight) => AnalyticsInsight.fromJson(insight))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalItems': totalItems,
      'totalOutfits': totalOutfits,
      'itemsByCategory': itemsByCategory,
      'itemsByBrand': itemsByBrand,
      'totalValue': totalValue,
      'averageCostPerWear': averageCostPerWear,
      'mostWornItem': mostWornItem,
      'wearingFrequency': wearingFrequency,
      'seasonalUsage': seasonalUsage,
      'insights': insights.map((insight) => insight.toJson()).toList(),
    };
  }
}

/// Analytics insights
class AnalyticsInsight {
  final String id;
  final String type; // 'recommendation', 'warning', 'achievement'
  final String title;
  final String description;
  final String? action;
  final bool isRead;
  final DateTime createdAt;

  AnalyticsInsight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.action,
    this.isRead = false,
    required this.createdAt,
  });

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsight(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      action: json['action'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'action': action,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}