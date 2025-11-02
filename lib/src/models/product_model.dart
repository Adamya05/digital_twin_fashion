import 'avatar_model.dart';

/// Enhanced Product model for digital twin fashion marketplace
class Product {
  final String id;
  final String name;
  final String description;
  final double originalPrice;
  final double currentPrice;
  final List<String> images;
  final String primaryImage;
  final String category;
  final String subcategory;
  final List<String> tags;
  final ProductSizeInfo sizeInfo;
  final ProductVendor vendor;
  final ProductPricing pricing;
  final ProductCompatibility compatibility;
  final ProductShipping shipping;
  final ProductInventory inventory;
  final ProductRating rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isAvailable;
  final bool isFeatured;
  final List<String> careInstructions;
  final ProductMetadata metadata;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.currentPrice,
    required this.images,
    required this.primaryImage,
    required this.category,
    required this.subcategory,
    required this.tags,
    required this.sizeInfo,
    required this.vendor,
    required this.pricing,
    required this.compatibility,
    required this.shipping,
    required this.inventory,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.isAvailable = true,
    this.isFeatured = false,
    this.careInstructions = const [],
    required this.metadata,
  });

  /// Factory constructor for creating a product from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      primaryImage: json['primaryImage'] as String? ?? '',
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      sizeInfo: ProductSizeInfo.fromJson(json['sizeInfo'] ?? {}),
      vendor: ProductVendor.fromJson(json['vendor'] ?? {}),
      pricing: ProductPricing.fromJson(json['pricing'] ?? {}),
      compatibility: ProductCompatibility.fromJson(json['compatibility'] ?? {}),
      shipping: ProductShipping.fromJson(json['shipping'] ?? {}),
      inventory: ProductInventory.fromJson(json['inventory'] ?? {}),
      rating: ProductRating.fromJson(json['rating'] ?? {}),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      careInstructions: (json['careInstructions'] as List<dynamic>?)?.cast<String>() ?? [],
      metadata: ProductMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  /// Convert product to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'images': images,
      'primaryImage': primaryImage,
      'category': category,
      'subcategory': subcategory,
      'tags': tags,
      'sizeInfo': sizeInfo.toJson(),
      'vendor': vendor.toJson(),
      'pricing': pricing.toJson(),
      'compatibility': compatibility.toJson(),
      'shipping': shipping.toJson(),
      'inventory': inventory.toJson(),
      'rating': rating.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'careInstructions': careInstructions,
      'metadata': metadata.toJson(),
    };
  }

  /// Create a copy of product with updated fields
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? originalPrice,
    double? currentPrice,
    List<String>? images,
    String? primaryImage,
    String? category,
    String? subcategory,
    List<String>? tags,
    ProductSizeInfo? sizeInfo,
    ProductVendor? vendor,
    ProductPricing? pricing,
    ProductCompatibility? compatibility,
    ProductShipping? shipping,
    ProductInventory? inventory,
    ProductRating? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isAvailable,
    bool? isFeatured,
    List<String>? careInstructions,
    ProductMetadata? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      images: images ?? this.images,
      primaryImage: primaryImage ?? this.primaryImage,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      tags: tags ?? this.tags,
      sizeInfo: sizeInfo ?? this.sizeInfo,
      vendor: vendor ?? this.vendor,
      pricing: pricing ?? this.pricing,
      compatibility: compatibility ?? this.compatibility,
      shipping: shipping ?? this.shipping,
      inventory: inventory ?? this.inventory,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      careInstructions: careInstructions ?? this.careInstructions,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product{id: $id, name: $name, currentPrice: $currentPrice}';
  }

  /// Get discount percentage
  double get discountPercentage {
    if (originalPrice <= 0) return 0.0;
    return ((originalPrice - currentPrice) / originalPrice * 100).roundToDouble();
  }

  /// Check if product is on sale
  bool get isOnSale => currentPrice < originalPrice;

  /// Get available colors
  List<String> get availableColors => sizeInfo.colors;

  /// Get available sizes
  List<String> get availableSizes => sizeInfo.sizes.keys.toList();

  /// Get total stock
  int get totalStock => sizeInfo.sizes.values
      .map((size) => size.stock)
      .fold(0, (sum, stock) => sum + stock);

  /// Check if product is in stock
  bool get inStock => totalStock > 0;

  /// Get average rating
  double get averageRating => rating.average;

  /// Get vendor rating
  double get vendorRating => vendor.rating;

  /// 3D Model support methods
  /// Get the primary 3D model URL for try-on
  String get primary3DModelUrl => metadata.tryOnModelUrl.isNotEmpty 
      ? metadata.tryOnModelUrl 
      : 'assets/models/${id}_tryon.glb';
  
  /// Check if product has 3D model available
  bool get has3DModel => metadata.has3DModel;
  
  /// Get quality levels for 3D model
  List<ModelQuality> get available3DQualities => metadata.availableQualities;
  
  /// Get fallback 2D image for 3D viewer
  String get fallback2DImage => primaryImage.isNotEmpty 
      ? primaryImage 
      : (images.isNotEmpty ? images.first : '');
}

// ==================== SUPPORTING DATA CLASSES ====================

/// Product size information with availability
class ProductSizeInfo {
  final List<String> sizes;
  final Map<String, ProductSize> sizeDetails;
  final Map<String, int> colors;
  final String sizeChart;

  ProductSizeInfo({
    required this.sizes,
    required this.sizeDetails,
    required this.colors,
    this.sizeChart = '',
  });

  factory ProductSizeInfo.fromJson(Map<String, dynamic> json) {
    return ProductSizeInfo(
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      sizeDetails: (json['sizeDetails'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, ProductSize.fromJson(value))) ?? {},
      colors: (json['colors'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      sizeChart: json['sizeChart'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sizes': sizes,
      'sizeDetails': sizeDetails.map((key, value) => MapEntry(key, value.toJson())),
      'colors': colors,
      'sizeChart': sizeChart,
    };
  }
}

/// Individual product size information
class ProductSize {
  final String name;
  final int stock;
  final bool isAvailable;
  final Map<String, dynamic> measurements;

  ProductSize({
    required this.name,
    required this.stock,
    required this.isAvailable,
    this.measurements = const {},
  });

  factory ProductSize.fromJson(Map<String, dynamic> json) {
    return ProductSize(
      name: json['name'] as String? ?? '',
      stock: json['stock'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
      measurements: json['measurements'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'stock': stock,
      'isAvailable': isAvailable,
      'measurements': measurements,
    };
  }
}

/// Vendor information
class ProductVendor {
  final String id;
  final String name;
  final String logo;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final String location;
  final String description;
  final Map<String, double> metrics;

  ProductVendor({
    required this.id,
    required this.name,
    required this.logo,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.location,
    required this.description,
    this.metrics = const {},
  });

  factory ProductVendor.fromJson(Map<String, dynamic> json) {
    return ProductVendor(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      logo: json['logo'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      metrics: (json['metrics'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo': logo,
      'rating': rating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'location': location,
      'description': description,
      'metrics': metrics,
    };
  }
}

/// Pricing information with taxes and fees
class ProductPricing {
  final double originalPrice;
  final double currentPrice;
  final double discountPercentage;
  final String currency;
  final bool isOnSale;
  final DateTime? saleEndDate;
  final Map<String, double> taxes;
  final double shippingCost;
  final bool isFreeShipping;

  ProductPricing({
    required this.originalPrice,
    required this.currentPrice,
    required this.discountPercentage,
    required this.currency,
    required this.isOnSale,
    this.saleEndDate,
    this.taxes = const {},
    required this.shippingCost,
    required this.isFreeShipping,
  });

  factory ProductPricing.fromJson(Map<String, dynamic> json) {
    return ProductPricing(
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      isOnSale: json['isOnSale'] as bool? ?? false,
      saleEndDate: json['saleEndDate'] != null 
          ? DateTime.parse(json['saleEndDate'] as String)
          : null,
      taxes: (json['taxes'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      isFreeShipping: json['isFreeShipping'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'originalPrice': originalPrice,
      'currentPrice': currentPrice,
      'discountPercentage': discountPercentage,
      'currency': currency,
      'isOnSale': isOnSale,
      'saleEndDate': saleEndDate?.toIso8601String(),
      'taxes': taxes,
      'shippingCost': shippingCost,
      'isFreeShipping': isFreeShipping,
    };
  }
}

/// Avatar-product compatibility information
class ProductCompatibility {
  final List<String> compatibleBodyTypes;
  final List<String> compatibleGenders;
  final Map<String, double> compatibilityScores;
  final List<String> sizeRecommendations;
  final String fitDescription;
  final Map<String, String> fitGuide;

  ProductCompatibility({
    required this.compatibleBodyTypes,
    required this.compatibleGenders,
    required this.compatibilityScores,
    required this.sizeRecommendations,
    required this.fitDescription,
    this.fitGuide = const {},
  });

  factory ProductCompatibility.fromJson(Map<String, dynamic> json) {
    return ProductCompatibility(
      compatibleBodyTypes: (json['compatibleBodyTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      compatibleGenders: (json['compatibleGenders'] as List<dynamic>?)?.cast<String>() ?? [],
      compatibilityScores: (json['compatibilityScores'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      sizeRecommendations: (json['sizeRecommendations'] as List<dynamic>?)?.cast<String>() ?? [],
      fitDescription: json['fitDescription'] as String? ?? '',
      fitGuide: (json['fitGuide'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'compatibleBodyTypes': compatibleBodyTypes,
      'compatibleGenders': compatibleGenders,
      'compatibilityScores': compatibilityScores,
      'sizeRecommendations': sizeRecommendations,
      'fitDescription': fitDescription,
      'fitGuide': fitGuide,
    };
  }

  /// Get compatibility score for a specific avatar
  double getCompatibilityScore(Avatar avatar) {
    final bodyTypeScore = compatibilityScores[avatar.attributes.bodyType] ?? 0.0;
    final genderScore = compatibilityScores[avatar.attributes.gender] ?? 0.0;
    return (bodyTypeScore + genderScore) / 2.0;
  }

  /// Check if avatar is compatible with this product
  bool isCompatibleWith(Avatar avatar) {
    return compatibleBodyTypes.contains(avatar.attributes.bodyType) &&
           compatibleGenders.contains(avatar.attributes.gender) &&
           getCompatibilityScore(avatar) > 0.3;
  }
}

/// Shipping information
class ProductShipping {
  final String shippingMethod;
  final int estimatedDays;
  final double shippingCost;
  final bool isFreeShipping;
  final bool isExpedited;
  final List<String> availableRegions;
  final Map<String, double> regionCosts;
  final String returnPolicy;

  ProductShipping({
    required this.shippingMethod,
    required this.estimatedDays,
    required this.shippingCost,
    required this.isFreeShipping,
    required this.isExpedited,
    required this.availableRegions,
    this.regionCosts = const {},
    this.returnPolicy = '',
  });

  factory ProductShipping.fromJson(Map<String, dynamic> json) {
    return ProductShipping(
      shippingMethod: json['shippingMethod'] as String? ?? '',
      estimatedDays: json['estimatedDays'] as int? ?? 0,
      shippingCost: (json['shippingCost'] as num?)?.toDouble() ?? 0.0,
      isFreeShipping: json['isFreeShipping'] as bool? ?? false,
      isExpedited: json['isExpedited'] as bool? ?? false,
      availableRegions: (json['availableRegions'] as List<dynamic>?)?.cast<String>() ?? [],
      regionCosts: (json['regionCosts'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},
      returnPolicy: json['returnPolicy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shippingMethod': shippingMethod,
      'estimatedDays': estimatedDays,
      'shippingCost': shippingCost,
      'isFreeShipping': isFreeShipping,
      'isExpedited': isExpedited,
      'availableRegions': availableRegions,
      'regionCosts': regionCosts,
      'returnPolicy': returnPolicy,
    };
  }
}

/// Product inventory information
class ProductInventory {
  final int totalStock;
  final bool inStock;
  final bool lowStock;
  final int lowStockThreshold;
  final Map<String, int> stockBySize;
  final Map<String, int> stockByColor;
  final DateTime lastRestocked;
  final String restockStatus;

  ProductInventory({
    required this.totalStock,
    required this.inStock,
    required this.lowStock,
    required this.lowStockThreshold,
    required this.stockBySize,
    required this.stockByColor,
    required this.lastRestocked,
    required this.restockStatus,
  });

  factory ProductInventory.fromJson(Map<String, dynamic> json) {
    return ProductInventory(
      totalStock: json['totalStock'] as int? ?? 0,
      inStock: json['inStock'] as bool? ?? false,
      lowStock: json['lowStock'] as bool? ?? false,
      lowStockThreshold: json['lowStockThreshold'] as int? ?? 5,
      stockBySize: (json['stockBySize'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      stockByColor: (json['stockByColor'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as int)) ?? {},
      lastRestocked: json['lastRestocked'] != null 
          ? DateTime.parse(json['lastRestocked'] as String)
          : DateTime.now(),
      restockStatus: json['restockStatus'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalStock': totalStock,
      'inStock': inStock,
      'lowStock': lowStock,
      'lowStockThreshold': lowStockThreshold,
      'stockBySize': stockBySize,
      'stockByColor': stockByColor,
      'lastRestocked': lastRestocked.toIso8601String(),
      'restockStatus': restockStatus,
    };
  }
}

/// Product rating and review information
class ProductRating {
  final double average;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final List<ProductReview> reviews;
  final double fitRating;
  final double qualityRating;
  final double valueRating;

  ProductRating({
    required this.average,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.reviews,
    required this.fitRating,
    required this.qualityRating,
    required this.valueRating,
  });

  factory ProductRating.fromJson(Map<String, dynamic> json) {
    return ProductRating(
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      ratingDistribution: (json['ratingDistribution'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(int.parse(key), value as int)) ?? {},
      reviews: (json['reviews'] as List<dynamic>?)
          ?.map((review) => ProductReview.fromJson(review)).toList() ?? [],
      fitRating: (json['fitRating'] as num?)?.toDouble() ?? 0.0,
      qualityRating: (json['qualityRating'] as num?)?.toDouble() ?? 0.0,
      valueRating: (json['valueRating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'average': average,
      'totalReviews': totalReviews,
      'ratingDistribution': ratingDistribution.map((key, value) => MapEntry(key.toString(), value)),
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'fitRating': fitRating,
      'qualityRating': qualityRating,
      'valueRating': valueRating,
    };
  }
}

/// Individual product review
class ProductReview {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final int rating;
  final String title;
  final String comment;
  final DateTime createdAt;
  final bool verified;
  final String fit;
  final List<String> images;
  final int helpful;

  ProductReview({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.title,
    required this.comment,
    required this.createdAt,
    required this.verified,
    required this.fit,
    required this.images,
    required this.helpful,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      userAvatar: json['userAvatar'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      verified: json['verified'] as bool? ?? false,
      fit: json['fit'] as String? ?? '',
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
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
      'title': title,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'verified': verified,
      'fit': fit,
      'images': images,
      'helpful': helpful,
    };
  }
}

/// Product metadata
class ProductMetadata {
  final String sku;
  final String material;
  final String pattern;
  final String style;
  final List<String> careInstructions;
  final List<String> features;
  final Map<String, String> specifications;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> tags;
  final String season;
  final String occasion;
  
  // 3D Model support
  final String tryOnModelUrl;
  final bool has3DModel;
  final List<ModelQuality> availableQualities;
  final Map<String, String> qualityModelUrls;
  final String modelFormat; // glb, gltf, usdz
  final double modelFileSize;
  final List<String> modelVariants; // different sizes, colors
  final bool isOptimizedForMobile;
  final ModelCompatibility modelCompatibility;

  ProductMetadata({
    required this.sku,
    required this.material,
    required this.pattern,
    required this.style,
    required this.careInstructions,
    required this.features,
    required this.specifications,
    required this.createdAt,
    required this.updatedAt,
    required this.tags,
    required this.season,
    required this.occasion,
    this.tryOnModelUrl = '',
    this.has3DModel = false,
    this.availableQualities = const [],
    this.qualityModelUrls = const {},
    this.modelFormat = '',
    this.modelFileSize = 0.0,
    this.modelVariants = const [],
    this.isOptimizedForMobile = false,
    this.modelCompatibility = const ModelCompatibility(),
  });

  factory ProductMetadata.fromJson(Map<String, dynamic> json) {
    return ProductMetadata(
      sku: json['sku'] as String? ?? '',
      material: json['material'] as String? ?? '',
      pattern: json['pattern'] as String? ?? '',
      style: json['style'] as String? ?? '',
      careInstructions: (json['careInstructions'] as List<dynamic>?)?.cast<String>() ?? [],
      features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
      specifications: (json['specifications'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      season: json['season'] as String? ?? '',
      occasion: json['occasion'] as String? ?? '',
      tryOnModelUrl: json['tryOnModelUrl'] as String? ?? '',
      has3DModel: json['has3DModel'] as bool? ?? false,
      availableQualities: (json['availableQualities'] as List<dynamic>?)
          ?.map((quality) => ModelQuality.fromJson(quality))
          .toList() ?? [],
      qualityModelUrls: (json['qualityModelUrls'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, value as String)) ?? {},
      modelFormat: json['modelFormat'] as String? ?? '',
      modelFileSize: (json['modelFileSize'] as num?)?.toDouble() ?? 0.0,
      modelVariants: (json['modelVariants'] as List<dynamic>?)?.cast<String>() ?? [],
      isOptimizedForMobile: json['isOptimizedForMobile'] as bool? ?? false,
      modelCompatibility: ModelCompatibility.fromJson(json['modelCompatibility'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sku': sku,
      'material': material,
      'pattern': pattern,
      'style': style,
      'careInstructions': careInstructions,
      'features': features,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'season': season,
      'occasion': occasion,
      'tryOnModelUrl': tryOnModelUrl,
      'has3DModel': has3DModel,
      'availableQualities': availableQualities.map((quality) => quality.toJson()).toList(),
      'qualityModelUrls': qualityModelUrls,
      'modelFormat': modelFormat,
      'modelFileSize': modelFileSize,
      'modelVariants': modelVariants,
      'isOptimizedForMobile': isOptimizedForMobile,
      'modelCompatibility': modelCompatibility.toJson(),
    };
}
}

// ==================== 3D MODEL SUPPORT CLASSES ====================

/// 3D Model quality levels
class ModelQuality {
  final String name; // 'Low', 'Medium', 'High'
  final String label; // 'Draft', 'Standard', 'Premium'
  final double resolutionMultiplier;
  final int maxPolygonCount;
  final double fileSize; // in MB
  final bool isMobileOptimized;
  final String modelUrl;

  ModelQuality({
    required this.name,
    required this.label,
    required this.resolutionMultiplier,
    required this.maxPolygonCount,
    required this.fileSize,
    required this.isMobileOptimized,
    required this.modelUrl,
  });

  factory ModelQuality.fromJson(Map<String, dynamic> json) {
    return ModelQuality(
      name: json['name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      resolutionMultiplier: (json['resolutionMultiplier'] as num?)?.toDouble() ?? 1.0,
      maxPolygonCount: json['maxPolygonCount'] as int? ?? 10000,
      fileSize: (json['fileSize'] as num?)?.toDouble() ?? 0.0,
      isMobileOptimized: json['isMobileOptimized'] as bool? ?? false,
      modelUrl: json['modelUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'label': label,
      'resolutionMultiplier': resolutionMultiplier,
      'maxPolygonCount': maxPolygonCount,
      'fileSize': fileSize,
      'isMobileOptimized': isMobileOptimized,
      'modelUrl': modelUrl,
    };
  }
}

/// 3D Model compatibility information
class ModelCompatibility {
  final List<String> supportedAvatarTypes;
  final List<String> supportedBodyTypes;
  final String fitType; // 'tight', 'regular', 'loose'
  final Map<String, double> scalingFactors;
  final List<String> supportedSizes;
  final bool requiresModelPrep;
  final String prepInstructions;

  const ModelCompatibility({
    this.supportedAvatarTypes = const [],
    this.supportedBodyTypes = const [],
    this.fitType = 'regular',
    this.scalingFactors = const {},
    this.supportedSizes = const [],
    this.requiresModelPrep = false,
    this.prepInstructions = '',
  });

  factory ModelCompatibility.fromJson(Map<String, dynamic> json) {
    return ModelCompatibility(
      supportedAvatarTypes: (json['supportedAvatarTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      supportedBodyTypes: (json['supportedBodyTypes'] as List<dynamic>?)?.cast<String>() ?? [],
      fitType: json['fitType'] as String? ?? 'regular',
      scalingFactors: (json['scalingFactors'] as Map<String, dynamic>?)\n          ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ?? {},\n      supportedSizes: (json['supportedSizes'] as List<dynamic>?)?.cast<String>() ?? [],\n      requiresModelPrep: json['requiresModelPrep'] as bool? ?? false,\n      prepInstructions: json['prepInstructions'] as String? ?? '',\n    );\n  }\n\n  Map<String, dynamic> toJson() {\n    return {\n      'supportedAvatarTypes': supportedAvatarTypes,\n      'supportedBodyTypes': supportedBodyTypes,\n      'fitType': fitType,\n      'scalingFactors': scalingFactors,\n      'supportedSizes': supportedSizes,\n      'requiresModelPrep': requiresModelPrep,\n      'prepInstructions': prepInstructions,\n    };\n  }\n\n  /// Check if avatar is compatible with this model\n  bool isAvatarCompatible(Avatar avatar) {\n    return supportedAvatarTypes.contains(avatar.id) &&\n           supportedBodyTypes.contains(avatar.attributes.bodyType);\n  }\n\n  /// Get scaling factor for specific avatar\n  double getScalingForAvatar(Avatar avatar) {\n    return scalingFactors[avatar.id] ?? 1.0;\n  }\n}