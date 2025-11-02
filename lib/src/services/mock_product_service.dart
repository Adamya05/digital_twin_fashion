import 'dart:math';
import '../models/product_model.dart';
import '../models/avatar_model.dart';

/// Service for generating and managing mock product data
/// Provides comprehensive fashion product catalog with realistic data
class MockProductService {
  static const List<String> _categories = [
    'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Accessories', 'Footwear', 'Activewear'
  ];
  
  static const Map<String, List<String>> _subcategories = {
    'Tops': ['T-Shirts', 'Blouses', 'Shirts', 'Tank Tops', 'Hoodies', 'Sweaters'],
    'Bottoms': ['Jeans', 'Trousers', 'Shorts', 'Skirts', 'Leggings', 'Palazzo Pants'],
    'Dresses': ['Casual', 'Formal', 'Evening', 'Cocktail', 'Maxi', 'Midi'],
    'Outerwear': ['Jackets', 'Coats', 'Blazers', 'Cardigans', 'Vests'],
    'Accessories': ['Bags', 'Jewelry', 'Scarves', 'Hats', 'Belts', 'Sunglasses'],
    'Footwear': ['Sneakers', 'Heels', 'Flats', 'Boots', 'Sandals'],
    'Activewear': ['Sports Bras', 'Yoga Pants', 'Athletic Shorts', 'Tracksuits']
  };
  
  static const List<String> _brands = [
    'Zara', 'H&M', 'Uniqlo', 'Mango', 'Bershka', 'Stradivarius',
    'Forever 21', 'ASOS', 'Nike', 'Adidas', 'Gap', 'Levi\'s'
  ];
  
  static const List<String> _materials = [
    'Cotton', 'Polyester', 'Linen', 'Silk', 'Denim', 'Wool', 'Viscose', 'Lace'
  ];
  
  static const List<String> _colors = [
    'Black', 'White', 'Navy', 'Gray', 'Beige', 'Red', 'Blue', 'Green', 'Pink', 'Purple'
  ];
  
  static const List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  
  static const List<String> _bodyTypes = ['Slim', 'Regular', 'Athletic', 'PlusSize'];
  static const List<String> _genders = ['Male', 'Female', 'Unisex'];
  
  static const List<String> _styles = [
    'Casual', 'Formal', 'Business', 'Party', 'Sport', 'Street', 'Vintage', 'Modern'
  ];
  
  static const List<String> _seasons = ['Spring', 'Summer', 'Fall', 'Winter', 'All Season'];
  
  static final Random _random = Random();

  /// Generate a complete product catalog with 100+ items
  static List<Product> generateProductCatalog({int count = 120}) {
    return List.generate(count, (index) => _generateProduct('prod_$index'));
  }

  /// Generate a single product with realistic data
  static Product _generateProduct(String id) {
    final category = _categories[_random.nextInt(_categories.length)];
    final subcategory = _subcategories[category]![_random.nextInt(_subcategories[category]!.length)];
    final brand = _brands[_random.nextInt(_brands.length)];
    final basePrice = 500 + (_random.nextDouble() * 4500); // ₹500 - ₹5000
    
    // Generate images for the product
    final images = _generateProductImages(id, category);
    final primaryImage = images.first;
    
    // Generate sizes and stock
    final sizeInfo = _generateSizeInfo();
    
    // Generate pricing
    final originalPrice = basePrice;
    final isOnSale = _random.nextDouble() < 0.3; // 30% chance of being on sale
    final currentPrice = isOnSale 
        ? originalPrice * (0.7 + _random.nextDouble() * 0.2) // 70-90% of original
        : originalPrice;
    
    // Generate compatibility scores
    final compatibilityScores = _generateCompatibilityScores();
    
    // Generate vendor information
    final vendor = _generateVendorInfo(brand);
    
    // Generate reviews
    final rating = _generateRating();
    
    return Product(
      id: id,
      name: _generateProductName(subcategory, category),
      description: _generateProductDescription(subcategory, category),
      originalPrice: originalPrice,
      currentPrice: currentPrice,
      images: images,
      primaryImage: primaryImage,
      category: category,
      subcategory: subcategory,
      tags: _generateTags(category, subcategory),
      sizeInfo: sizeInfo,
      vendor: vendor,
      pricing: ProductPricing(
        originalPrice: originalPrice,
        currentPrice: currentPrice,
        discountPercentage: ((originalPrice - currentPrice) / originalPrice * 100).roundToDouble(),
        currency: 'INR',
        isOnSale: isOnSale,
        saleEndDate: isOnSale 
            ? DateTime.now().add(Duration(days: _random.nextInt(30) + 1))
            : null,
        shippingCost: currentPrice > 1999 ? 0.0 : 99.0,
        isFreeShipping: currentPrice > 1999,
      ),
      compatibility: ProductCompatibility(
        compatibleBodyTypes: _bodyTypes.where((type) => 
            (compatibilityScores[type] ?? 0.0) > 0.2
        ).toList(),
        compatibleGenders: _genders,
        compatibilityScores: compatibilityScores,
        sizeRecommendations: _getSizeRecommendations(compatibilityScores),
        fitDescription: _generateFitDescription(),
        fitGuide: {
          'XS': 'For body measurements: Chest 32-34", Waist 26-28"',
          'S': 'For body measurements: Chest 34-36", Waist 28-30"',
          'M': 'For body measurements: Chest 36-38", Waist 30-32"',
          'L': 'For body measurements: Chest 38-40", Waist 32-34"',
          'XL': 'For body measurements: Chest 40-42", Waist 34-36"',
          'XXL': 'For body measurements: Chest 42-44", Waist 36-38"',
        },
      ),
      shipping: ProductShipping(
        shippingMethod: 'Standard Shipping',
        estimatedDays: 3 + _random.nextInt(5),
        shippingCost: currentPrice > 1999 ? 0.0 : 99.0,
        isFreeShipping: currentPrice > 1999,
        isExpedited: _random.nextDouble() < 0.4,
        availableRegions: ['Pan India'],
        returnPolicy: '30-day return policy with free returns',
      ),
      inventory: ProductInventory(
        totalStock: sizeInfo.sizes
            .map((size) => sizeInfo.sizeDetails[size]?.stock ?? 0)
            .fold(0, (sum, stock) => sum + stock),
        inStock: true,
        lowStock: false,
        lowStockThreshold: 10,
        stockBySize: Map.fromEntries(
            sizeInfo.sizes.map((size) => MapEntry(size, sizeInfo.sizeDetails[size]?.stock ?? 0))),
        stockByColor: Map.fromEntries(
            sizeInfo.colors.entries.map((entry) => MapEntry(entry.key, entry.value))),
        lastRestocked: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        restockStatus: 'Available',
      ),
      rating: rating,
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
      isAvailable: true,
      isFeatured: _random.nextDouble() < 0.1, // 10% chance of being featured
      careInstructions: _generateCareInstructions(),
      metadata: ProductMetadata(
        sku: 'SKU${DateTime.now().millisecondsSinceEpoch}$id',
        material: _materials[_random.nextInt(_materials.length)],
        pattern: _random.nextDouble() < 0.3 ? 'Solid' : 'Pattern',
        style: _styles[_random.nextInt(_styles.length)],
        careInstructions: _generateCareInstructions(),
        features: _generateFeatures(category),
        specifications: _generateSpecifications(category),
        createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
        updatedAt: DateTime.now().subtract(Duration(days: _random.nextInt(30))),
        tags: _generateTags(category, subcategory),
        season: _seasons[_random.nextInt(_seasons.length)],
        occasion: _generateOccasion(),
      ),
    );
  }

  /// Generate product images URLs
  static List<String> _generateProductImages(String id, String category) {
    final baseImageUrl = 'assets/products/$category/${id}_';
    final imageCount = 3 + _random.nextInt(3); // 3-5 images per product
    final List<String> images = [];
    
    for (int i = 0; i < imageCount; i++) {
      images.add('${baseImageUrl}${i + 1}.jpg');
    }
    
    return images;
  }

  /// Generate size information with stock levels
  static ProductSizeInfo _generateSizeInfo() {
    final sizes = List<String>.from(_sizes);
    final Map<String, ProductSize> sizeDetails = {};
    final Map<String, int> colors = {};
    
    // Generate stock for each size
    for (final size in sizes) {
      sizeDetails[size] = ProductSize(
        name: size,
        stock: _random.nextInt(50) + 1,
        isAvailable: _random.nextDouble() < 0.8, // 80% availability
        measurements: _generateSizeMeasurements(size),
      );
    }
    
    // Generate color stock
    for (final color in _colors) {
      colors[color] = _random.nextInt(30) + 5;
    }
    
    return ProductSizeInfo(
      sizes: sizes,
      sizeDetails: sizeDetails,
      colors: colors,
      sizeChart: 'assets/size-charts/${category}_chart.jpg',
    );
  }

  /// Generate compatibility scores for different body types
  static Map<String, double> _generateCompatibilityScores() {
    final Map<String, double> scores = {};
    for (final bodyType in _bodyTypes) {
      scores[bodyType] = 0.3 + _random.nextDouble() * 0.6; // 0.3 to 0.9
    }
    return scores;
  }

  /// Generate vendor information
  static ProductVendor _generateVendorInfo(String brand) {
    final vendorId = 'vendor_${brand.toLowerCase().replaceAll(' ', '_')}';
    return ProductVendor(
      id: vendorId,
      name: brand,
      logo: 'assets/vendors/${brand.toLowerCase().replaceAll(' ', '_')}_logo.png',
      rating: 3.5 + _random.nextDouble() * 1.3, // 3.5 to 4.8 stars
      reviewCount: 50 + _random.nextInt(950),
      isVerified: _random.nextDouble() < 0.7,
      location: _getRandomLocation(),
      description: '$brand - Premium fashion brand offering quality clothing',
      metrics: {
        'deliverySpeed': 3.5 + _random.nextDouble() * 1.5,
        'customerService': 3.8 + _random.nextDouble() * 1.2,
        'productQuality': 4.0 + _random.nextDouble() * 1.0,
      },
    );
  }

  /// Generate product rating and reviews
  static ProductRating _generateRating() {
    final average = 3.0 + _random.nextDouble() * 2.0; // 3.0 to 5.0
    final totalReviews = _random.nextInt(500) + 10;
    
    // Generate rating distribution
    final Map<int, int> distribution = {};
    for (int rating = 1; rating <= 5; rating++) {
      if (rating <= average) {
        distribution[rating] = _random.nextInt(100) + 10;
      } else {
        distribution[rating] = _random.nextInt(50);
      }
    }
    
    // Generate sample reviews
    final List<ProductReview> reviews = [];
    for (int i = 0; i < min(5, totalReviews ~/ 100); i++) {
      reviews.add(_generateReview('review_$i'));
    }
    
    return ProductRating(
      average: average,
      totalReviews: totalReviews,
      ratingDistribution: distribution,
      reviews: reviews,
      fitRating: 3.5 + _random.nextDouble() * 1.5,
      qualityRating: 3.8 + _random.nextDouble() * 1.2,
      valueRating: 3.2 + _random.nextDouble() * 1.6,
    );
  }

  /// Generate a single product review
  static ProductReview _generateReview(String id) {
    final userNames = ['Priya', 'Anjali', 'Neha', 'Kavya', 'Sneha', 'Riya', 'Pooja', 'Kiran'];
    final fitOptions = ['Too Small', 'Perfect', 'Too Large'];
    
    return ProductReview(
      id: id,
      userId: 'user_${id}',
      userName: userNames[_random.nextInt(userNames.length)],
      userAvatar: 'assets/avatars/default_user.png',
      rating: 1 + _random.nextInt(5),
      title: _generateReviewTitle(),
      comment: _generateReviewComment(),
      createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
      verified: _random.nextDouble() < 0.8,
      fit: fitOptions[_random.nextInt(fitOptions.length)],
      images: _random.nextDouble() < 0.3 ? ['assets/reviews/${id}_1.jpg'] : [],
      helpful: _random.nextInt(50),
    );
  }

  // ==================== HELPER METHODS ====================

  static String _generateProductName(String subcategory, String category) {
    final adjectives = ['Classic', 'Modern', 'Elegant', 'Trendy', 'Comfortable', 'Stylish', 'Premium'];
    return '${adjectives[_random.nextInt(adjectives.length)]} $subcategory';
  }

  static String _generateProductDescription(String subcategory, String category) {
    final descriptions = [
      'Perfect blend of style and comfort. Crafted with attention to detail and premium materials.',
      'Elevate your wardrobe with this versatile piece. Ideal for both casual and formal occasions.',
      'Made from high-quality fabric that ensures durability and comfort throughout the day.',
      'A must-have addition to your collection. Designed to flatter and provide exceptional fit.',
      'Contemporary design meets timeless elegance. Perfect for the modern lifestyle.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  static List<String> _generateTags(String category, String subcategory) {
    final commonTags = ['trending', 'new-arrival', 'bestseller', 'premium', 'sustainable'];
    final categoryTags = {
      'Tops': ['casual', 'office', 'evening'],
      'Bottoms': ['jeans', 'trousers', 'shorts'],
      'Dresses': ['formal', 'party', 'casual'],
      'Outerwear': ['winter', 'rain', 'windproof'],
      'Accessories': ['handbag', 'jewelry', 'scarf'],
    };
    
    final tags = List<String>.from(commonTags);
    tags.addAll(categoryTags[category] ?? []);
    return tags;
  }

  static List<String> _getSizeRecommendations(Map<String, double> compatibilityScores) {
    final sortedScores = compatibilityScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedScores.take(3).map((entry) => entry.key).toList();
  }

  static String _generateFitDescription() {
    final descriptions = [
      'Fits true to size. If between sizes, size up for a looser fit.',
      'Runs slightly small. Consider sizing up for comfort.',
      'Relaxed fit. Perfect for layering or wearing alone.',
      'Slim fit. Designed to flatter the body shape.',
      'Oversized fit. Modern, trendy look with extra comfort.',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  static Map<String, dynamic> _generateSizeMeasurements(String size) {
    final measurements = {
      'XS': {'chest': 32, 'waist': 26, 'length': 24},
      'S': {'chest': 34, 'waist': 28, 'length': 25},
      'M': {'chest': 36, 'waist': 30, 'length': 26},
      'L': {'chest': 38, 'waist': 32, 'length': 27},
      'XL': {'chest': 40, 'waist': 34, 'length': 28},
      'XXL': {'chest': 42, 'waist': 36, 'length': 29},
    };
    return measurements[size] ?? {};
  }

  static String _getRandomLocation() {
    final locations = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Pune', 'Kolkata', 'Hyderabad'];
    return locations[_random.nextInt(locations.length)];
  }

  static List<String> _generateCareInstructions() {
    final instructions = [
      'Machine wash cold with like colors',
      'Do not bleach',
      'Tumble dry low',
      'Iron on low heat if needed',
      'Dry clean recommended',
    ];
    return instructions.take(2 + _random.nextInt(3)).toList();
  }

  static List<String> _generateFeatures(String category) {
    final commonFeatures = ['Breathable', 'Comfortable fit', 'Durable', 'Easy care'];
    final categoryFeatures = {
      'Tops': ['Moisture-wicking', 'Wrinkle-resistant'],
      'Bottoms': ['Stretchable', 'Pocketed'],
      'Dresses': ['Lined', 'Back zip closure'],
      'Outerwear': ['Water-resistant', 'Insulated'],
    };
    
    final features = List<String>.from(commonFeatures);
    features.addAll(categoryFeatures[category] ?? []);
    return features;
  }

  static Map<String, String> _generateSpecifications(String category) {
    return {
      'Weight': '${200 + _random.nextInt(300)}g',
      'Material': _materials[_random.nextInt(_materials.length)],
      'Care': 'Machine washable',
      'Origin': 'Made in India',
    };
  }

  static String _generateOccasion() {
    final occasions = ['Casual', 'Work', 'Party', 'Formal', 'Sports', 'Travel'];
    return occasions[_random.nextInt(occasions.length)];
  }

  static String _generateReviewTitle() {
    final titles = [
      'Great quality!',
      'Perfect fit',
      'Value for money',
      'Highly recommended',
      'Love it!',
    ];
    return titles[_random.nextInt(titles.length)];
  }

  static String _generateReviewComment() {
    final comments = [
      'Really happy with this purchase. Quality is amazing and fits perfectly.',
      'Good value for money. Will definitely buy again.',
      'Delivery was fast and the product exceeded expectations.',
      'Comfortable and stylish. Exactly what I was looking for.',
      'Good quality material. Would recommend to others.',
    ];
    return comments[_random.nextInt(comments.length)];
  }

  /// Filter products by category
  static List<Product> filterByCategory(List<Product> products, String category) {
    return products.where((product) => product.category == category).toList();
  }

  /// Filter products by price range
  static List<Product> filterByPriceRange(List<Product> products, double minPrice, double maxPrice) {
    return products.where((product) => 
        product.currentPrice >= minPrice && product.currentPrice <= maxPrice).toList();
  }

  /// Filter products by brand
  static List<Product> filterByBrand(List<Product> products, String brand) {
    return products.where((product) => 
        product.vendor.name.toLowerCase() == brand.toLowerCase()).toList();
  }

  /// Filter products by compatibility with avatar
  static List<Product> filterByCompatibility(List<Product> products, Avatar avatar) {
    return products.where((product) => 
        product.compatibility.isCompatibleWith(avatar)).toList();
  }

  /// Sort products by various criteria
  static List<Product> sortProducts(List<Product> products, String sortBy) {
    switch (sortBy) {
      case 'price-low':
        products.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
        break;
      case 'price-high':
        products.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.average.compareTo(a.rating.average));
        break;
      case 'newest':
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'popular':
        products.sort((a, b) => b.rating.totalReviews.compareTo(a.rating.totalReviews));
        break;
    }
    return products;
  }

  /// Search products by name, description, or tags
  static List<Product> searchProducts(List<Product> products, String query) {
    final queryLower = query.toLowerCase();
    return products.where((product) =>
        product.name.toLowerCase().contains(queryLower) ||
        product.description.toLowerCase().contains(queryLower) ||
        product.tags.any((tag) => tag.toLowerCase().contains(queryLower))).toList();
  }
}
