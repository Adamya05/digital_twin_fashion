import '../models/product_model.dart';
import '../models/avatar_model.dart';
import '../services/api_service.dart';
import '../services/mock_product_service.dart';
import '../services/product_cache_service.dart';
import '../providers/product_provider.dart';

/// Unified product service that combines all product-related functionality
/// This service provides a single interface for all product operations
class ProductService {
  final ApiService _apiService = ApiService();
  final ProductCacheService _cacheService = ProductCacheService();
  static bool _isInitialized = false;

  /// Initialize the product service
  static Future<void> initialize() async {
    if (!_isInitialized) {
      await ProductCacheService().initialize();
      _isInitialized = true;
    }
  }

  // ==================== PRODUCT RETRIEVAL ====================

  /// Get all products with filtering and pagination
  Future<List<Product>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? sortBy = 'newest',
    bool offline = false,
  }) async {
    if (offline) {
      final cachedProducts = await _cacheService.getCachedProducts();
      return cachedProducts ?? [];
    }

    final response = await _apiService.getProducts(
      page: page,
      perPage: perPage,
      search: search,
      category: category,
      brand: brand,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
    );

    return response.isSuccess ? response.data?.products ?? [] : [];
  }

  /// Get product by ID
  Future<Product?> getProductById(String productId) async {
    final response = await _apiService.getProduct(productId);
    return response.isSuccess ? response.data : null;
  }

  /// Get featured products
  Future<List<Product>> getFeaturedProducts({int limit = 12}) async {
    final response = await _apiService.getFeaturedProducts(limit: limit);
    return response.isSuccess ? response.data?.products ?? [] : [];
  }

  /// Get sale products
  Future<List<Product>> getSaleProducts({int page = 1, int perPage = 20}) async {
    final response = await _apiService.getSaleProducts(page: page, perPage: perPage);
    return response.isSuccess ? response.data?.products ?? [] : [];
  }

  // ==================== SEARCH AND FILTER ====================

  /// Search products with advanced filters
  Future<List<Product>> searchProducts({
    required String query,
    int page = 1,
    int perPage = 20,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    bool useCache = true,
  }) async {
    // Try cache first if enabled
    if (useCache) {
      final cachedResults = _cacheService.getCachedSearchResults(query);
      if (cachedResults != null && cachedResults.isNotEmpty) {
        // Apply additional filters to cached results
        return _applyFiltersToProducts(cachedResults, {
          'category': category,
          'brand': brand,
          'minPrice': minPrice,
          'maxPrice': maxPrice,
        });
      }
    }

    final response = await _apiService.searchProducts(
      query: query,
      page: page,
      perPage: perPage,
      category: category,
      brand: brand,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sortBy: sortBy,
    );

    if (response.isSuccess && response.data != null) {
      // Cache search results
      if (useCache) {
        await _cacheService.cacheSearchResults(query, response.data!.products);
      }
      return response.data!.products;
    }

    return [];
  }

  /// Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await _apiService.getProductsByCategory(category: category);
    return response.isSuccess ? response.data?.products ?? [] : [];
  }

  /// Filter products by price range
  List<Product> filterByPriceRange(List<Product> products, double minPrice, double maxPrice) {
    return products.where((product) => 
        product.currentPrice >= minPrice && product.currentPrice <= maxPrice).toList();
  }

  /// Filter products by brand
  List<Product> filterByBrand(List<Product> products, String brand) {
    return products.where((product) => 
        product.vendor.name.toLowerCase() == brand.toLowerCase()).toList();
  }

  /// Sort products
  List<Product> sortProducts(List<Product> products, String sortBy) {
    return MockProductService.sortProducts(products, sortBy);
  }

  // ==================== AVATAR COMPATIBILITY ====================

  /// Get products compatible with specific avatar
  Future<List<Product>> getProductsForAvatar(
    Avatar avatar, {
    String? category,
    int limit = 20,
  }) async {
    final response = await _apiService.getProductsForAvatar(
      avatarId: avatar.id,
      category: category,
      page: 1,
      perPage: limit,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.products;
    }

    // Fallback to local filtering
    final allProducts = MockProductService.generateProductCatalog(50);
    return MockProductService.filterByCompatibility(allProducts, avatar);
  }

  /// Get personalized recommendations for avatar
  Future<List<Product>> getRecommendationsForAvatar(
    Avatar avatar, {
    int limit = 10,
  }) async {
    final response = await _apiService.getRecommendedProducts(
      avatarId: avatar.id,
      limit: limit,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!.products;
    }

    return [];
  }

  /// Check product compatibility with avatar
  double getCompatibilityScore(Product product, Avatar avatar) {
    return product.compatibility.getCompatibilityScore(avatar);
  }

  /// Check if product is compatible with avatar
  bool isCompatible(Product product, Avatar avatar) {
    return product.compatibility.isCompatibleWith(avatar);
  }

  /// Get recommended size for avatar
  String? getRecommendedSize(Product product, Avatar avatar) {
    final scores = product.compatibility.compatibilityScores;
    final recommended = product.compatibility.sizeRecommendations;
    
    if (recommended.isEmpty) return null;
    
    // Return the first recommended size
    return recommended.first;
  }

  // ==================== CATEGORIES AND BRANDS ====================

  /// Get all categories
  Future<List<String>> getCategories() async {
    // Try cache first
    final cachedCategories = _cacheService.getCachedCategories();
    if (cachedCategories != null && cachedCategories.isNotEmpty) {
      return cachedCategories;
    }

    final response = await _apiService.getCategories();
    if (response.isSuccess && response.data != null) {
      await _cacheService.cacheCategories(response.data!);
      return response.data!;
    }

    return [];
  }

  /// Get all brands
  Future<List<String>> getBrands() async {
    // Try cache first
    final cachedBrands = _cacheService.getCachedBrands();
    if (cachedBrands != null && cachedBrands.isNotEmpty) {
      return cachedBrands;
    }

    final response = await _apiService.getBrands();
    if (response.isSuccess && response.data != null) {
      await _cacheService.cacheBrands(response.data!);
      return response.data!;
    }

    return [];
  }

  // ==================== FAVORITES MANAGEMENT ====================

  /// Get user's favorite products
  List<Product> getFavorites() {
    return _cacheService.getFavorites();
  }

  /// Check if product is in favorites
  bool isFavorite(String productId) {
    return _cacheService.isFavorite(productId);
  }

  /// Toggle product favorite status
  Future<void> toggleFavorite(Product product) async {
    if (_cacheService.isFavorite(product.id)) {
      await _cacheService.removeFromFavorites(product.id);
    } else {
      await _cacheService.saveToFavorites(product);
    }
  }

  /// Add product to favorites
  Future<void> addToFavorites(Product product) async {
    await _cacheService.saveToFavorites(product);
  }

  /// Remove product from favorites
  Future<void> removeFromFavorites(String productId) async {
    await _cacheService.removeFromFavorites(productId);
  }

  // ==================== RECENTLY VIEWED ====================

  /// Get recently viewed products
  List<Product> getRecentlyViewed() {
    return _cacheService.getRecentlyViewed();
  }

  /// Add product to recently viewed
  Future<void> addToRecentlyViewed(Product product) async {
    await _cacheService.addToRecentlyViewed(product);
  }

  /// Clear recently viewed history
  Future<void> clearRecentlyViewed() async {
    await _cacheService.clearRecentlyViewed();
  }

  // ==================== SEARCH HISTORY ====================

  /// Get search history
  List<String> getSearchHistory() {
    return _cacheService.getSearchHistory();
  }

  /// Add search query to history
  Future<void> addToSearchHistory(String query) async {
    await _cacheService.cacheSearchResults(query, []);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _cacheService.clearSearchHistory();
  }

  // ==================== SIZE CHARTS ====================

  /// Get size chart for category
  Future<Map<String, dynamic>> getSizeChart(String category) async {
    final response = await _apiService.getSizeChart(category);
    return response.isSuccess ? response.data ?? {} : {};
  }

  /// Get available sizes for product
  List<String> getAvailableSizes(Product product) {
    return product.availableSizes;
  }

  /// Get available colors for product
  List<String> getAvailableColors(Product product) {
    return product.availableColors;
  }

  /// Check if specific size and color are available
  bool isSizeAndColorAvailable(Product product, String size, String color) {
    final sizeInfo = product.sizeInfo;
    final sizeData = sizeInfo.sizeDetails[size];
    
    if (sizeData == null || !sizeData.isAvailable) return false;
    
    final colorStock = sizeInfo.colors[color] ?? 0;
    return colorStock > 0;
  }

  // ==================== OFFLINE FUNCTIONALITY ====================

  /// Enable offline mode
  void enableOfflineMode() {
    _cacheService.setOfflineMode(true);
  }

  /// Disable offline mode
  void disableOfflineMode() {
    _cacheService.setOfflineMode(false);
  }

  /// Check if offline data is available
  Future<bool> hasOfflineData() async {
    return await _cacheService.hasOfflineData();
  }

  /// Get offline product recommendations
  List<Product> getOfflineRecommendations() {
    return _cacheService.getOfflineRecommendations();
  }

  /// Preload data for offline use
  Future<void> preloadOfflineData({
    List<String>? categories,
    List<String>? brands,
  }) async {
    final categoriesToLoad = categories ?? await getCategories();
    final brandsToLoad = brands ?? await getBrands();

    // Preload categories
    for (final category in categoriesToLoad.take(5)) {
      final products = await getProductsByCategory(category);
      await _cacheService.cacheProducts(products, filterKey: 'category_$category');
    }

    // Preload brands
    for (final brand in brandsToLoad.take(5)) {
      final products = await getProducts(brand: brand);
      await _cacheService.cacheProducts(products, filterKey: 'brand_$brand');
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Get cache size in bytes
  Future<int> getCacheSize() async {
    return await _cacheService.getCacheSize();
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cacheService.clearAllCache();
  }

  /// Clean expired cache entries
  Future<void> cleanExpiredCache() async {
    // This is handled automatically by the cache service
  }

  // ==================== PRODUCT ANALYTICS ====================

  /// Get product recommendations based on user's history
  List<Product> getRecommendationsFromHistory(
    List<Product> allProducts,
    List<Product> recentlyViewed,
    List<Product> favorites,
  ) {
    final recommendations = <String>{};
    final recommendedProducts = <Product>[];

    // Analyze recently viewed products
    for (final product in recentlyViewed.take(5)) {
      // Add products from same category
      final categoryMatches = allProducts.where((p) => 
          p.category == product.category && !recommendations.contains(p.id)
      ).toList();
      
      recommendations.addAll(categoryMatches.take(3).map((p) => p.id));
      
      // Add products from same brand
      final brandMatches = allProducts.where((p) => 
          p.vendor.name == product.vendor.name && !recommendations.contains(p.id)
      ).toList();
      
      recommendations.addAll(brandMatches.take(2).map((p) => p.id));
    }

    // Get recommended products
    for (final product in allProducts) {
      if (recommendations.contains(product.id)) {
        recommendedProducts.add(product);
      }
    }

    return recommendedProducts.take(10).toList();
  }

  /// Get price range statistics
  Map<String, double> getPriceStatistics(List<Product> products) {
    if (products.isEmpty) return {};

    final prices = products.map((p) => p.currentPrice).toList()..sort();
    
    return {
      'min': prices.first,
      'max': prices.last,
      'average': prices.reduce((a, b) => a + b) / prices.length,
      'median': prices[prices.length ~/ 2],
    };
  }

  // ==================== PRIVATE HELPERS ====================

  List<Product> _applyFiltersToProducts(
    List<Product> products,
    Map<String, dynamic> filters,
  ) {
    var filteredProducts = List<Product>.from(products);

    // Apply category filter
    if (filters['category'] != null && filters['category'] is String) {
      filteredProducts = filteredProducts.where((p) => 
          p.category.toLowerCase() == filters['category'].toLowerCase()
      ).toList();
    }

    // Apply brand filter
    if (filters['brand'] != null && filters['brand'] is String) {
      filteredProducts = filteredProducts.where((p) => 
          p.vendor.name.toLowerCase() == filters['brand'].toLowerCase()
      ).toList();
    }

    // Apply price filters
    if (filters['minPrice'] != null && filters['minPrice'] is num) {
      filteredProducts = filteredProducts.where((p) => 
          p.currentPrice >= (filters['minPrice'] as num).toDouble()
      ).toList();
    }

    if (filters['maxPrice'] != null && filters['maxPrice'] is num) {
      filteredProducts = filteredProducts.where((p) => 
          p.currentPrice <= (filters['maxPrice'] as num).toDouble()
      ).toList();
    }

    return filteredProducts;
  }
}

/// Global product service instance
final productService = ProductService();
