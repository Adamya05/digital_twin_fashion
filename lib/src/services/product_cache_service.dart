import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';

/// Service for managing product data caching and offline functionality
class ProductCacheService {
  static const String _productsCacheKey = 'cached_products';
  static const String _searchCacheKey = 'cached_searches';
  static const String _categoriesCacheKey = 'cached_categories';
  static const String _brandsCacheKey = 'cached_brands';
  static const String _favoritesCacheKey = 'cached_favorites';
  static const String _recentlyViewedKey = 'recently_viewed_products';
  
  static const Duration _cacheExpiry = Duration(hours: 24);
  static const int _maxCacheSize = 1000;
  static const int _maxSearchHistory = 50;

  SharedPreferences? _prefs;

  /// Initialize the cache service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _cleanExpiredCache();
  }

  // ==================== PRODUCT CACHING ====================

  /// Cache product list with timestamp
  Future<void> cacheProducts(List<Product> products, {String? filterKey}) async {
    if (_prefs == null) return;
    
    final cacheKey = filterKey != null 
        ? '${_productsCacheKey}_$filterKey' 
        : _productsCacheKey;
    
    try {
      final cacheData = {
        'products': products.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final jsonString = jsonEncode(cacheData);
      await _prefs!.setString(cacheKey, jsonString);
      
      // Clean old cache if size limit exceeded
      await _limitCacheSize(cacheKey);
      
    } catch (e) {
      print('Error caching products: $e');
    }
  }

  /// Get cached products
  Future<List<Product>?> getCachedProducts({String? filterKey}) async {
    if (_prefs == null) return null;
    
    final cacheKey = filterKey != null 
        ? '${_productsCacheKey}_$filterKey' 
        : _productsCacheKey;
    
    try {
      final jsonString = _prefs!.getString(cacheKey);
      if (jsonString == null) return null;
      
      final cacheData = jsonDecode(jsonString);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        await _prefs!.remove(cacheKey);
        return null;
      }
      
      final productsJson = cacheData['products'] as List<dynamic>;
      return productsJson.map((json) => Product.fromJson(json)).toList();
      
    } catch (e) {
      print('Error getting cached products: $e');
      return null;
    }
  }

  /// Check if products cache is available and valid
  Future<bool> isCacheValid({String? filterKey}) async {
    final cached = await getCachedProducts(filterKey: filterKey);
    return cached != null && cached.isNotEmpty;
  }

  // ==================== SEARCH CACHING ====================

  /// Cache search results
  Future<void> cacheSearchResults(String query, List<Product> results) async {
    if (_prefs == null) return;
    
    try {
      final searchCache = _getSearchCache();
      searchCache[query] = {
        'results': results.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _saveSearchCache(searchCache);
      
      // Add to search history
      await _addToSearchHistory(query);
      
    } catch (e) {
      print('Error caching search results: $e');
    }
  }

  /// Get cached search results
  Future<List<Product>?> getCachedSearchResults(String query) async {
    if (_prefs == null) return null;
    
    try {
      final searchCache = _getSearchCache();
      final searchData = searchCache[query];
      
      if (searchData == null) return null;
      
      final timestamp = DateTime.parse(searchData['timestamp']);
      
      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiry) {
        searchCache.remove(query);
        await _saveSearchCache(searchCache);
        return null;
      }
      
      final resultsJson = searchData['results'] as List<dynamic>;
      return resultsJson.map((json) => Product.fromJson(json)).toList();
      
    } catch (e) {
      print('Error getting cached search results: $e');
      return null;
    }
  }

  /// Add search query to history
  Future<void> _addToSearchHistory(String query) async {
    if (_prefs == null) return;
    
    try {
      final history = _getSearchHistory();
      
      // Remove if already exists
      history.remove(query);
      
      // Add to beginning
      history.insert(0, query);
      
      // Limit history size
      if (history.length > _maxSearchHistory) {
        history.removeRange(_maxSearchHistory, history.length);
      }
      
      final historyString = jsonEncode(history);
      await _prefs!.setString(_searchCacheKey, historyString);
      
    } catch (e) {
      print('Error adding to search history: $e');
    }
  }

  /// Get search history
  List<String> getSearchHistory() {
    if (_prefs == null) return [];
    return _getSearchHistory();
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    if (_prefs == null) return;
    await _prefs!.remove(_searchCacheKey);
  }

  // ==================== FAVORITES MANAGEMENT ====================

  /// Save product to favorites
  Future<void> saveToFavorites(Product product) async {
    if (_prefs == null) return;
    
    try {
      final favorites = _getFavorites();
      favorites[product.id] = product.toJson();
      
      await _saveFavorites(favorites);
      
    } catch (e) {
      print('Error saving to favorites: $e');
    }
  }

  /// Remove product from favorites
  Future<void> removeFromFavorites(String productId) async {
    if (_prefs == null) return;
    
    try {
      final favorites = _getFavorites();
      favorites.remove(productId);
      
      await _saveFavorites(favorites);
      
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }

  /// Get favorite products
  List<Product> getFavorites() {
    if (_prefs == null) return [];
    
    try {
      final favorites = _getFavorites();
      return favorites.values
          .map((json) => Product.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  /// Check if product is in favorites
  bool isFavorite(String productId) {
    if (_prefs == null) return false;
    
    final favorites = _getFavorites();
    return favorites.containsKey(productId);
  }

  // ==================== RECENTLY VIEWED ====================

  /// Add product to recently viewed
  Future<void> addToRecentlyViewed(Product product) async {
    if (_prefs == null) return;
    
    try {
      final recentlyViewed = _getRecentlyViewed();
      
      // Remove if already exists
      recentlyViewed.removeWhere((item) => item['id'] == product.id);
      
      // Add to beginning
      recentlyViewed.insert(0, product.toJson());
      
      // Limit to 20 items
      if (recentlyViewed.length > 20) {
        recentlyViewed.removeRange(20, recentlyViewed.length);
      }
      
      final recentlyViewedString = jsonEncode(recentlyViewed);
      await _prefs!.setString(_recentlyViewedKey, recentlyViewedString);
      
    } catch (e) {
      print('Error adding to recently viewed: $e');
    }
  }

  /// Get recently viewed products
  List<Product> getRecentlyViewed() {
    if (_prefs == null) return [];
    
    try {
      final recentlyViewedJson = _prefs!.getString(_recentlyViewedKey);
      if (recentlyViewedJson == null) return [];
      
      final List<dynamic> recentlyViewedData = jsonDecode(recentlyViewedJson);
      return recentlyViewedData.map((json) => Product.fromJson(json)).toList();
      
    } catch (e) {
      print('Error getting recently viewed: $e');
      return [];
    }
  }

  /// Clear recently viewed
  Future<void> clearRecentlyViewed() async {
    if (_prefs == null) return;
    await _prefs!.remove(_recentlyViewedKey);
  }

  // ==================== DATA PERSISTENCE ====================

  /// Cache categories
  Future<void> cacheCategories(List<String> categories) async {
    if (_prefs == null) return;
    
    try {
      final categoriesString = jsonEncode(categories);
      await _prefs!.setString(_categoriesCacheKey, categoriesString);
    } catch (e) {
      print('Error caching categories: $e');
    }
  }

  /// Get cached categories
  List<String>? getCachedCategories() {
    if (_prefs == null) return null;
    
    try {
      final categoriesString = _prefs!.getString(_categoriesCacheKey);
      if (categoriesString == null) return null;
      
      final categories = jsonDecode(categoriesString) as List<dynamic>;
      return categories.cast<String>();
      
    } catch (e) {
      print('Error getting cached categories: $e');
      return null;
    }
  }

  /// Cache brands
  Future<void> cacheBrands(List<String> brands) async {
    if (_prefs == null) return;
    
    try {
      final brandsString = jsonEncode(brands);
      await _prefs!.setString(_brandsCacheKey, brandsString);
    } catch (e) {
      print('Error caching brands: $e');
    }
  }

  /// Get cached brands
  List<String>? getCachedBrands() {
    if (_prefs == null) return null;
    
    try {
      final brandsString = _prefs!.getString(_brandsCacheKey);
      if (brandsString == null) return null;
      
      final brands = jsonDecode(brandsString) as List<dynamic>;
      return brands.cast<String>();
      
    } catch (e) {
      print('Error getting cached brands: $e');
      return null;
    }
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Get total cache size
  Future<int> getCacheSize() async {
    if (_prefs == null) return 0;
    
    int totalSize = 0;
    
    try {
      final keys = _prefs!.getKeys();
      for (final key in keys) {
        final value = _prefs!.getString(key);
        if (value != null) {
          totalSize += value.length;
        }
      }
    } catch (e) {
      print('Error calculating cache size: $e');
    }
    
    return totalSize;
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    if (_prefs == null) return;
    
    await _prefs!.clear();
  }

  /// Clean expired cache entries
  Future<void> _cleanExpiredCache() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys();
      final expiredKeys = <String>[];
      
      for (final key in keys) {
        if (key.startsWith('cached_')) {
          final value = _prefs!.getString(key);
          if (value != null) {
            final data = jsonDecode(value);
            if (data['timestamp'] != null) {
              final timestamp = DateTime.parse(data['timestamp']);
              if (DateTime.now().difference(timestamp) > _cacheExpiry) {
                expiredKeys.add(key);
              }
            }
          }
        }
      }
      
      for (final key in expiredKeys) {
        await _prefs!.remove(key);
      }
      
    } catch (e) {
      print('Error cleaning expired cache: $e');
    }
  }

  /// Limit cache size by removing oldest entries
  Future<void> _limitCacheSize(String cacheKey) async {
    if (_prefs == null) return;
    
    try {
      // This is a simplified implementation
      // In a real app, you might want to implement more sophisticated cache management
    } catch (e) {
      print('Error limiting cache size: $e');
    }
  }

  // ==================== PRIVATE HELPERS ====================

  Map<String, dynamic> _getSearchCache() {
    if (_prefs == null) return {};
    
    try {
      final searchCacheString = _prefs!.getString(_searchCacheKey);
      if (searchCacheString == null) return {};
      
      return jsonDecode(searchCacheString);
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveSearchCache(Map<String, dynamic> searchCache) async {
    if (_prefs == null) return;
    
    final searchCacheString = jsonEncode(searchCache);
    await _prefs!.setString(_searchCacheKey, searchCacheString);
  }

  List<String> _getSearchHistory() {
    if (_prefs == null) return [];
    
    try {
      final historyString = _prefs!.getString(_searchCacheKey);
      if (historyString == null) return [];
      
      return jsonDecode(historyString);
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> _getFavorites() {
    if (_prefs == null) return {};
    
    try {
      final favoritesString = _prefs!.getString(_favoritesCacheKey);
      if (favoritesString == null) return {};
      
      return jsonDecode(favoritesString);
    } catch (e) {
      return {};
    }
  }

  Future<void> _saveFavorites(Map<String, dynamic> favorites) async {
    if (_prefs == null) return;
    
    final favoritesString = jsonEncode(favorites);
    await _prefs!.setString(_favoritesCacheKey, favoritesString);
  }

  List<Map<String, dynamic>> _getRecentlyViewed() {
    if (_prefs == null) return [];
    
    try {
      final recentlyViewedString = _prefs!.getString(_recentlyViewedKey);
      if (recentlyViewedString == null) return [];
      
      final List<dynamic> data = jsonDecode(recentlyViewedString);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Check if app is in offline mode
  bool isOfflineMode = false;

  /// Enable/disable offline mode
  void setOfflineMode(bool offline) {
    isOfflineMode = offline;
  }

  /// Check if data is available for offline use
  Future<bool> hasOfflineData() async {
    if (isOfflineMode) {
      return await isCacheValid() || 
             getCachedCategories()?.isNotEmpty == true ||
             getCachedBrands()?.isNotEmpty == true;
    }
    return false;
  }

  /// Get offline product recommendation
  List<Product> getOfflineRecommendations() {
    final recentlyViewed = getRecentlyViewed();
    final favorites = getFavorites();
    
    // Combine and deduplicate
    final allProducts = <String>{};
    final recommendations = <Product>[];
    
    for (final product in [...recentlyViewed, ...favorites]) {
      if (!allProducts.contains(product.id)) {
        allProducts.add(product.id);
        recommendations.add(product);
      }
    }
    
    return recommendations.take(10).toList();
  }
}
