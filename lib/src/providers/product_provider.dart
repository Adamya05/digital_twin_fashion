import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/avatar_model.dart';
import '../services/api_service.dart';
import '../services/product_cache_service.dart';

/// Provider for managing product state and operations
class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ProductCacheService _cacheService = ProductCacheService();

  // Product list state
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  // Current product
  Product? _currentProduct;
  bool _isProductLoading = false;

  // Search and filter state
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedBrand = '';
  double _minPrice = 0;
  double _maxPrice = 10000;
  String _sortBy = 'newest';
  String _selectedSize = '';
  String _selectedColor = '';
  bool _showOnlyOnSale = false;

  // Search results
  List<Product> _searchResults = [];
  bool _isSearching = false;
  List<String> _searchHistory = [];

  // Recommendations
  List<Product> _recommendedProducts = [];
  bool _isLoadingRecommendations = false;

  // Categories and brands
  List<String> _categories = [];
  List<String> _brands = [];
  bool _isLoadingCategories = false;
  bool _isLoadingBrands = false;

  // Favorites
  List<Product> _favorites = [];
  Set<String> _favoriteIds = {};

  // Recently viewed
  List<Product> _recentlyViewed = [];

  // Product for avatar compatibility
  List<Product> _compatibleProducts = [];
  bool _isLoadingCompatible = false;

  // Offline mode
  bool _isOfflineMode = false;

  // ==================== INITIALIZATION ====================

  /// Initialize the provider
  Future<void> initialize() async {
    await _cacheService.initialize();
    await _loadCachedData();
  }

  /// Load cached data on startup
  Future<void> _loadCachedData() async {
    // Load favorites
    _favorites = _cacheService.getFavorites();
    _favoriteIds = _favorites.map((p) => p.id).toSet();

    // Load recently viewed
    _recentlyViewed = _cacheService.getRecentlyViewed();

    // Load search history
    _searchHistory = _cacheService.getSearchHistory();

    // Load cached categories and brands
    _categories = _cacheService.getCachedCategories() ?? [];
    _brands = _cacheService.getCachedBrands() ?? [];

    // Set offline mode
    _isOfflineMode = _cacheService.isOfflineMode;

    notifyListeners();
  }

  // ==================== PRODUCT LIST ====================

  /// Load products with current filters
  Future<void> loadProducts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final filterKey = _generateFilterKey();
      
      // Try to get from cache if offline mode
      if (_isOfflineMode) {
        final cachedProducts = await _cacheService.getCachedProducts(filterKey: filterKey);
        if (cachedProducts != null) {
          if (refresh) {
            _products = cachedProducts;
          } else {
            _products.addAll(cachedProducts);
          }
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Make API call
      final response = await _apiService.getProducts(
        page: _currentPage,
        perPage: 20,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
        brand: _selectedBrand.isEmpty ? null : _selectedBrand,
        minPrice: _minPrice > 0 ? _minPrice : null,
        maxPrice: _maxPrice < 10000 ? _maxPrice : null,
        sortBy: _sortBy,
        size: _selectedSize.isEmpty ? null : _selectedSize,
        color: _selectedColor.isEmpty ? null : _selectedColor,
        onSale: _showOnlyOnSale ? true : null,
      );

      if (response.isSuccess && response.data != null) {
        final productList = response.data!;
        
        if (refresh) {
          _products = productList.products;
        } else {
          _products.addAll(productList.products);
        }
        
        _hasMore = productList.hasMore;
        _currentPage++;
        
        // Cache products
        await _cacheService.cacheProducts(
          _isOfflineMode ? _products : productList.products,
          filterKey: filterKey,
        );
        
      } else {
        _error = response.error ?? 'Failed to load products';
        
        // Try to load from cache on error
        final cachedProducts = await _cacheService.getCachedProducts(filterKey: filterKey);
        if (cachedProducts != null) {
          if (refresh) {
            _products = cachedProducts;
          } else {
            _products.addAll(cachedProducts);
          }
          _error = null;
        }
      }
      
    } catch (e) {
      _error = 'Network error: $e';
      
      // Try to load from cache on error
      final cachedProducts = await _cacheService.getCachedProducts(
        filterKey: _generateFilterKey(),
      );
      if (cachedProducts != null) {
        _products = refresh ? cachedProducts : [..._products, ...cachedProducts];
        _error = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Refresh products
  Future<void> refreshProducts() async {
    await loadProducts(refresh: true);
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoading || !_hasMore) return;
    await loadProducts();
  }

  // ==================== SEARCH ====================

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    notifyListeners();

    try {
      // Try cache first
      final cachedResults = _cacheService.getCachedSearchResults(query);
      if (cachedResults != null) {
        _searchResults = cachedResults;
        _isSearching = false;
        notifyListeners();
        return;
      }

      // Make API call
      final response = await _apiService.searchProducts(
        query: query,
        page: 1,
        perPage: 50,
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
        brand: _selectedBrand.isEmpty ? null : _selectedBrand,
        sortBy: _sortBy,
      );

      if (response.isSuccess && response.data != null) {
        _searchResults = response.data!.products;
        
        // Cache search results
        await _cacheService.cacheSearchResults(query, _searchResults);
        
      } else {
        _searchResults = [];
      }
      
    } catch (e) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  // ==================== PRODUCT DETAILS ====================

  /// Load product details
  Future<void> loadProductDetails(String productId) async {
    if (_isProductLoading) return;

    _isProductLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getProduct(productId);
      
      if (response.isSuccess && response.data != null) {
        _currentProduct = response.data;
        
        // Add to recently viewed
        _cacheService.addToRecentlyViewed(response.data);
        
        // Update local recently viewed list
        _recentlyViewed = _cacheService.getRecentlyViewed();
        
      } else {
        _error = response.error ?? 'Failed to load product details';
      }
      
    } catch (e) {
      _error = 'Network error: $e';
    }

    _isProductLoading = false;
    notifyListeners();
  }

  // ==================== RECOMMENDATIONS ====================

  /// Load recommended products
  Future<void> loadRecommendations({
    String? avatarId,
    String? category,
  }) async {
    if (_isLoadingRecommendations) return;

    _isLoadingRecommendations = true;
    notifyListeners();

    try {
      final response = await _apiService.getRecommendedProducts(
        avatarId: avatarId,
        category: category,
        limit: 12,
      );

      if (response.isSuccess && response.data != null) {
        _recommendedProducts = response.data!.products;
      } else {
        _recommendedProducts = [];
      }
      
    } catch (e) {
      _recommendedProducts = [];
    }

    _isLoadingRecommendations = false;
    notifyListeners();
  }

  /// Load compatible products for avatar
  Future<void> loadCompatibleProducts(Avatar avatar) async {
    if (_isLoadingCompatible) return;

    _isLoadingCompatible = true;
    notifyListeners();

    try {
      final response = await _apiService.getProductsForAvatar(
        avatarId: avatar.id,
        category: _selectedCategory.isEmpty ? null : _selectedCategory,
        page: 1,
        perPage: 20,
      );

      if (response.isSuccess && response.data != null) {
        _compatibleProducts = response.data!.products;
      } else {
        _compatibleProducts = [];
      }
      
    } catch (e) {
      _compatibleProducts = [];
    }

    _isLoadingCompatible = false;
    notifyListeners();
  }

  // ==================== CATEGORIES & BRANDS ====================

  /// Load categories
  Future<void> loadCategories() async {
    if (_isLoadingCategories) return;

    _isLoadingCategories = true;
    notifyListeners();

    try {
      // Try cache first
      final cachedCategories = _cacheService.getCachedCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        _categories = cachedCategories;
        _isLoadingCategories = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.getCategories();
      
      if (response.isSuccess && response.data != null) {
        _categories = response.data!;
        
        // Cache categories
        await _cacheService.cacheCategories(_categories);
      }
      
    } catch (e) {
      // Use cached or default categories
      if (_categories.isEmpty) {
        _categories = ['Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Accessories'];
      }
    }

    _isLoadingCategories = false;
    notifyListeners();
  }

  /// Load brands
  Future<void> loadBrands() async {
    if (_isLoadingBrands) return;

    _isLoadingBrands = true;
    notifyListeners();

    try {
      // Try cache first
      final cachedBrands = _cacheService.getCachedBrands();
      if (cachedBrands != null && cachedBrands.isNotEmpty) {
        _brands = cachedBrands;
        _isLoadingBrands = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.getBrands();
      
      if (response.isSuccess && response.data != null) {
        _brands = response.data!;
        
        // Cache brands
        await _cacheService.cacheBrands(_brands);
      }
      
    } catch (e) {
      // Use cached or default brands
      if (_brands.isEmpty) {
        _brands = ['Zara', 'H&M', 'Uniqlo', 'Mango', 'Nike'];
      }
    }

    _isLoadingBrands = false;
    notifyListeners();
  }

  // ==================== FAVORITES ====================

  /// Toggle favorite status
  Future<void> toggleFavorite(Product product) async {
    if (_favoriteIds.contains(product.id)) {
      // Remove from favorites
      await _cacheService.removeFromFavorites(product.id);
      _favoriteIds.remove(product.id);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      // Add to favorites
      await _cacheService.saveToFavorites(product);
      _favoriteIds.add(product.id);
      _favorites.insert(0, product);
    }
    
    notifyListeners();
  }

  /// Check if product is favorite
  bool isFavorite(String productId) {
    return _favoriteIds.contains(productId);
  }

  // ==================== FILTERS ====================

  /// Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    refreshProducts();
  }

  /// Set brand filter
  void setBrand(String brand) {
    _selectedBrand = brand;
    refreshProducts();
  }

  /// Set price range
  void setPriceRange(double minPrice, double maxPrice) {
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    refreshProducts();
  }

  /// Set sort order
  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    refreshProducts();
  }

  /// Set size filter
  void setSize(String size) {
    _selectedSize = size;
    refreshProducts();
  }

  /// Set color filter
  void setColor(String color) {
    _selectedColor = color;
    refreshProducts();
  }

  /// Toggle sale filter
  void toggleSaleFilter() {
    _showOnlyOnSale = !_showOnlyOnSale;
    refreshProducts();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedBrand = '';
    _selectedSize = '';
    _selectedColor = '';
    _showOnlyOnSale = false;
    _minPrice = 0;
    _maxPrice = 10000;
    _sortBy = 'newest';
    refreshProducts();
  }

  // ==================== OFFLINE MODE ====================

  /// Toggle offline mode
  void toggleOfflineMode() {
    _isOfflineMode = !_isOfflineMode;
    _cacheService.setOfflineMode(_isOfflineMode);
    notifyListeners();
  }

  /// Check if offline data is available
  Future<bool> hasOfflineData() async {
    return await _cacheService.hasOfflineData();
  }

  // ==================== GETTERS ====================

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get isOfflineMode => _isOfflineMode;

  Product? get currentProduct => _currentProduct;
  bool get isProductLoading => _isProductLoading;

  List<Product> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  List<String> get searchHistory => _searchHistory;

  List<Product> get recommendedProducts => _recommendedProducts;
  bool get isLoadingRecommendations => _isLoadingRecommendations;

  List<Product> get compatibleProducts => _compatibleProducts;
  bool get isLoadingCompatible => _isLoadingCompatible;

  List<String> get categories => _categories;
  List<String> get brands => _brands;
  bool get isLoadingCategories => _isLoadingCategories;
  bool get isLoadingBrands => _isLoadingBrands;

  List<Product> get favorites => _favorites;

  List<Product> get recentlyViewed => _recentlyViewed;

  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;
  String get sortBy => _sortBy;
  String get selectedSize => _selectedSize;
  String get selectedColor => _selectedColor;
  bool get showOnlyOnSale => _showOnlyOnSale;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  // ==================== PRIVATE HELPERS ====================

  /// Generate filter key for caching
  String _generateFilterKey() {
    return [
      _searchQuery,
      _selectedCategory,
      _selectedBrand,
      _sortBy,
      _selectedSize,
      _selectedColor,
      _showOnlyOnSale,
      _minPrice.toString(),
      _maxPrice.toString(),
    ].join('_');
  }

  // ==================== DISPOSAL ====================

  @override
  void dispose() {
    // No specific disposal needed for now
    super.dispose();
  }
}
