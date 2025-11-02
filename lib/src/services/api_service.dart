import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/avatar_model.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'mock_product_service.dart';
import 'mock_order_service.dart';

/// Base API service for handling HTTP requests
/// This class provides a foundation for all API operations
class ApiService {
  static const String baseUrl = 'https://mock-api.minimax.io'; // Mock server endpoint
  static const Duration timeout = Duration(seconds: 30);

  // HTTP client with timeout
  final http.Client _client = http.Client();
  
  // Headers for all requests
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Make a GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, 
    T Function(Map<String, dynamic>) fromJsonT, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .get(uri, headers: {..._defaultHeaders, ...?headers})
          .timeout(timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('Unable to connect to server');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Make a POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJsonT, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .post(
            uri,
            headers: {..._defaultHeaders, ...?headers},
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('Unable to connect to server');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Make a PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJsonT, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .put(
            uri,
            headers: {..._defaultHeaders, ...?headers},
            body: jsonEncode(data),
          )
          .timeout(timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('Unable to connect to server');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Make a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJsonT, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .delete(uri, headers: {..._defaultHeaders, ...?headers})
          .timeout(timeout);

      return _handleResponse<T>(response, fromJsonT);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on HttpException {
      return ApiResponse.error('Unable to connect to server');
    } catch (e) {
      return ApiResponse.error('Unexpected error: $e');
    }
  }

  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    try {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = fromJsonT(jsonResponse);
        return ApiResponse.success(data);
      } else {
        final errorMessage = jsonResponse['message'] ?? 'Request failed';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  // ==================== AVATAR API ENDPOINTS ====================

  /// Get avatar by ID with mock response
  Future<ApiResponse<Avatar>> getAvatar(String avatarId) async {
    // Simulate realistic loading time
    await Future.delayed(Duration(seconds: 2 + (avatarId.length % 3)));
    
    if (avatarId.isEmpty) {
      return ApiResponse.error('Avatar ID is required');
    }

    try {
      // Mock avatar data based on ID
      final avatar = _generateMockAvatar(avatarId);
      return ApiResponse.success(avatar);
    } catch (e) {
      return ApiResponse.error('Failed to load avatar: $e');
    }
  }

  /// Get all avatars with pagination
  Future<ApiResponse<AvatarListResponse>> getAvatars({
    int page = 1,
    int perPage = 20,
    String? search,
    String? bodyType,
    String? ethnicity,
    String? gender,
  }) async {
    // Simulate realistic loading time
    await Future.delayed(Duration(seconds: 2 + (page % 3)));
    
    try {
      final mockAvatars = _generateMockAvatarList(50); // Generate 50 mock avatars
      List<Avatar> filteredAvatars = mockAvatars;
      
      // Apply filters
      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        filteredAvatars = filteredAvatars.where((avatar) =>
            avatar.name.toLowerCase().contains(searchLower) ||
            avatar.description?.toLowerCase().contains(searchLower) == true ||
            avatar.tags.any((tag) => tag.toLowerCase().contains(searchLower))
        ).toList();
      }
      
      if (bodyType != null) {
        filteredAvatars = filteredAvatars.where((avatar) =>
            avatar.attributes.bodyType == bodyType
        ).toList();
      }
      
      if (ethnicity != null) {
        filteredAvatars = filteredAvatars.where((avatar) =>
            avatar.attributes.ethnicity == ethnicity
        ).toList();
      }
      
      if (gender != null) {
        filteredAvatars = filteredAvatars.where((avatar) =>
            avatar.attributes.gender == gender
        ).toList();
      }

      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedAvatars = filteredAvatars.sublist(
        startIndex,
        endIndex < filteredAvatars.length ? endIndex : filteredAvatars.length
      );

      final response = AvatarListResponse(
        avatars: paginatedAvatars,
        totalCount: filteredAvatars.length,
        page: page,
        perPage: perPage,
      );

      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch avatars: $e');
    }
  }

  /// Create new avatar
  Future<ApiResponse<Avatar>> createAvatar(Map<String, dynamic> avatarData) async {
    await Future.delayed(Duration(seconds: 3 + (DateTime.now().millisecond % 3)));
    
    try {
      final newAvatar = Avatar.fromJson(avatarData);
      final id = 'avatar_${DateTime.now().millisecondsSinceEpoch}';
      final createdAvatar = newAvatar.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        modelUrl: 'assets/avatars/${id}_model.glb',
        thumbnailUrl: 'assets/avatars/${id}_thumb.jpg',
      );
      
      return ApiResponse.success(createdAvatar);
    } catch (e) {
      return ApiResponse.error('Failed to create avatar: $e');
    }
  }

  /// Update existing avatar
  Future<ApiResponse<Avatar>> updateAvatar(String avatarId, Map<String, dynamic> updates) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      // In a real implementation, this would update the avatar on the server
      final avatar = _generateMockAvatar(avatarId);
      final updatedAvatar = Avatar.fromJson({...avatar.toJson(), ...updates});
      final finalAvatar = updatedAvatar.copyWith(
        updatedAt: DateTime.now(),
      );
      
      return ApiResponse.success(finalAvatar);
    } catch (e) {
      return ApiResponse.error('Failed to update avatar: $e');
    }
  }

  /// Delete avatar
  Future<ApiResponse<bool>> deleteAvatar(String avatarId) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (avatarId.isEmpty) {
      return ApiResponse.error('Avatar ID is required');
    }
    
    try {
      // Simulate 95% success rate
      final success = avatarId.length % 20 != 0; // Simulate occasional failures
      
      if (success) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to delete avatar: Server error');
      }
    } catch (e) {
      return ApiResponse.error('Failed to delete avatar: $e');
    }
  }

  /// Get avatar measurements
  Future<ApiResponse<AvatarMeasurements>> getAvatarMeasurements(String avatarId) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final avatar = _generateMockAvatar(avatarId);
      return ApiResponse.success(avatar.measurements);
    } catch (e) {
      return ApiResponse.error('Failed to get measurements: $e');
    }
  }

  /// Update avatar measurements
  Future<ApiResponse<AvatarMeasurements>> updateAvatarMeasurements(
    String avatarId, 
    AvatarMeasurements measurements
  ) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      // In real implementation, this would update on server
      return ApiResponse.success(measurements);
    } catch (e) {
      return ApiResponse.error('Failed to update measurements: $e');
    }
  }

  /// Get avatar attributes
  Future<ApiResponse<AvatarAttributes>> getAvatarAttributes(String avatarId) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final avatar = _generateMockAvatar(avatarId);
      return ApiResponse.success(avatar.attributes);
    } catch (e) {
      return ApiResponse.error('Failed to get attributes: $e');
    }
  }

  /// Update avatar attributes
  Future<ApiResponse<AvatarAttributes>> updateAvatarAttributes(
    String avatarId, 
    AvatarAttributes attributes
  ) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      return ApiResponse.success(attributes);
    } catch (e) {
      return ApiResponse.error('Failed to update attributes: $e');
    }
  }

  /// Get avatar metadata
  Future<ApiResponse<AvatarMetadata>> getAvatarMetadata(String avatarId) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final avatar = _generateMockAvatar(avatarId);
      return ApiResponse.success(avatar.metadata);
    } catch (e) {
      return ApiResponse.error('Failed to get metadata: $e');
    }
  }

  /// Validate avatar model
  Future<ApiResponse<bool>> validateAvatarModel(String modelUrl) async {
    await Future.delayed(Duration(seconds: 3));
    
    try {
      // Simulate validation - most models are valid
      final isValid = modelUrl.contains('.glb') || modelUrl.contains('.gltf');
      await Future.delayed(Duration(seconds: 1)); // Additional processing time
      
      if (isValid) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Invalid model format');
      }
    } catch (e) {
      return ApiResponse.error('Validation failed: $e');
    }
  }

  /// Upload avatar model (mock)
  Future<ApiResponse<String>> uploadAvatarModel(File modelFile) async {
    await Future.delayed(Duration(seconds: 5)); // Simulate upload time
    
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.glb';
      final uploadUrl = 'assets/avatars/$fileName';
      
      // Simulate occasional upload failures
      if (modelFile.lengthSync() > 50 * 1024 * 1024) { // 50MB limit
        return ApiResponse.error('File too large. Maximum size is 50MB');
      }
      
      return ApiResponse.success(uploadUrl);
    } catch (e) {
      return ApiResponse.error('Upload failed: $e');
    }
  }

  /// Get recommended avatars based on user preferences
  Future<ApiResponse<List<Avatar>>> getRecommendedAvatars({
    String? bodyType,
    String? style,
    int limit = 10,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final allAvatars = _generateMockAvatarList(20);
      List<Avatar> recommended = allAvatars;
      
      // Simple recommendation logic
      if (bodyType != null) {
        recommended = recommended.where((avatar) =>
            avatar.attributes.bodyType == bodyType
        ).toList();
      }
      
      recommended = recommended.take(limit).toList();
      return ApiResponse.success(recommended);
    } catch (e) {
      return ApiResponse.error('Failed to get recommendations: $e');
    }
  }

  // ==================== PRODUCT API ENDPOINTS ====================

  /// Get all products with pagination and filtering
  Future<ApiResponse<ProductListResponse>> getProducts({
    int page = 1,
    int perPage = 20,
    String? search,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? size,
    String? color,
    bool? onSale,
  }) async {
    // Simulate realistic loading time
    await Future.delayed(Duration(seconds: 1 + (page % 2)));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(150);
      List<Product> filteredProducts = List.from(allProducts);
      
      // Apply filters
      if (search != null && search.isNotEmpty) {
        filteredProducts = MockProductService.searchProducts(filteredProducts, search);
      }
      
      if (category != null && category.isNotEmpty) {
        filteredProducts = MockProductService.filterByCategory(filteredProducts, category);
      }
      
      if (brand != null && brand.isNotEmpty) {
        filteredProducts = MockProductService.filterByBrand(filteredProducts, brand);
      }
      
      if (minPrice != null) {
        filteredProducts = filteredProducts.where((product) => 
            product.currentPrice >= minPrice).toList();
      }
      
      if (maxPrice != null) {
        filteredProducts = filteredProducts.where((product) => 
            product.currentPrice <= maxPrice).toList();
      }
      
      if (onSale != null) {
        filteredProducts = filteredProducts.where((product) => 
            product.isOnSale == onSale).toList();
      }
      
      if (size != null) {
        filteredProducts = filteredProducts.where((product) => 
            product.availableSizes.contains(size)).toList();
      }
      
      if (color != null) {
        filteredProducts = filteredProducts.where((product) => 
            product.availableColors.contains(color)).toList();
      }
      
      // Apply sorting
      if (sortBy != null) {
        filteredProducts = MockProductService.sortProducts(filteredProducts, sortBy);
      }
      
      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedProducts = filteredProducts.sublist(
        startIndex,
        endIndex < filteredProducts.length ? endIndex : filteredProducts.length
      );
      
      final response = ProductListResponse(
        products: paginatedProducts,
        totalCount: filteredProducts.length,
        page: page,
        perPage: perPage,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch products: $e');
    }
  }

  /// Get product by ID
  Future<ApiResponse<Product>> getProduct(String productId) async {
    // Simulate realistic loading time
    await Future.delayed(Duration(seconds: 1 + (productId.length % 2)));
    
    if (productId.isEmpty) {
      return ApiResponse.error('Product ID is required');
    }
    
    try {
      // Generate a specific product based on ID
      final product = _generateMockProduct(productId);
      return ApiResponse.success(product);
    } catch (e) {
      return ApiResponse.error('Failed to load product: $e');
    }
  }

  /// Get recommended products based on avatar or user preferences
  Future<ApiResponse<ProductListResponse>> getRecommendedProducts({
    String? avatarId,
    String? category,
    int limit = 10,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(50);
      List<Product> recommended = List.from(allProducts);
      
      // Apply category filter if specified
      if (category != null && category.isNotEmpty) {
        recommended = MockProductService.filterByCategory(recommended, category);
      }
      
      // If avatar ID is provided, filter by compatibility
      if (avatarId != null && avatarId.isNotEmpty) {
        final avatar = _generateMockAvatar(avatarId);
        recommended = MockProductService.filterByCompatibility(recommended, avatar);
      }
      
      // Limit results
      recommended = recommended.take(limit).toList();
      
      final response = ProductListResponse(
        products: recommended,
        totalCount: recommended.length,
        page: 1,
        perPage: limit,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to get recommendations: $e');
    }
  }

  /// Search products with advanced filters
  Future<ApiResponse<ProductListResponse>> searchProducts({
    required String query,
    int page = 1,
    int perPage = 20,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    List<String>? tags,
  }) async {
    await Future.delayed(Duration(seconds: 1 + (query.length % 2)));
    
    if (query.isEmpty) {
      return ApiResponse.error('Search query cannot be empty');
    }
    
    try {
      final allProducts = MockProductService.generateProductCatalog(100);
      List<Product> searchResults = MockProductService.searchProducts(allProducts, query);
      
      // Apply additional filters
      if (category != null) {
        searchResults = MockProductService.filterByCategory(searchResults, category);
      }
      
      if (brand != null) {
        searchResults = MockProductService.filterByBrand(searchResults, brand);
      }
      
      if (minPrice != null) {
        searchResults = MockProductService.filterByPriceRange(searchResults, minPrice, double.infinity);
      }
      
      if (maxPrice != null) {
        searchResults = MockProductService.filterByPriceRange(searchResults, 0, maxPrice);
      }
      
      if (tags != null && tags.isNotEmpty) {
        searchResults = searchResults.where((product) =>
            tags.any((tag) => product.tags.contains(tag))
        ).toList();
      }
      
      // Apply sorting
      if (sortBy != null) {
        searchResults = MockProductService.sortProducts(searchResults, sortBy);
      }
      
      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedResults = searchResults.sublist(
        startIndex,
        endIndex < searchResults.length ? endIndex : searchResults.length
      );
      
      final response = ProductListResponse(
        products: paginatedResults,
        totalCount: searchResults.length,
        page: page,
        perPage: perPage,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Search failed: $e');
    }
  }

  /// Get products compatible with specific avatar
  Future<ApiResponse<ProductListResponse>> getProductsForAvatar({
    required String avatarId,
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(100);
      final avatar = _generateMockAvatar(avatarId);
      
      List<Product> compatibleProducts = MockProductService.filterByCompatibility(allProducts, avatar);
      
      // Apply category filter if specified
      if (category != null && category.isNotEmpty) {
        compatibleProducts = MockProductService.filterByCategory(compatibleProducts, category);
      }
      
      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedProducts = compatibleProducts.sublist(
        startIndex,
        endIndex < compatibleProducts.length ? endIndex : compatibleProducts.length
      );
      
      final response = ProductListResponse(
        products: paginatedProducts,
        totalCount: compatibleProducts.length,
        page: page,
        perPage: perPage,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to get compatible products: $e');
    }
  }

  /// Get products by category
  Future<ApiResponse<ProductListResponse>> getProductsByCategory({
    required String category,
    int page = 1,
    int perPage = 20,
    String? sortBy,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(80);
      List<Product> categoryProducts = MockProductService.filterByCategory(allProducts, category);
      
      // Apply sorting
      if (sortBy != null) {
        categoryProducts = MockProductService.sortProducts(categoryProducts, sortBy);
      }
      
      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedProducts = categoryProducts.sublist(
        startIndex,
        endIndex < categoryProducts.length ? endIndex : categoryProducts.length
      );
      
      final response = ProductListResponse(
        products: paginatedProducts,
        totalCount: categoryProducts.length,
        page: page,
        perPage: perPage,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to get products by category: $e');
    }
  }

  /// Get featured products
  Future<ApiResponse<ProductListResponse>> getFeaturedProducts({
    int limit = 12,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(50);
      final featuredProducts = allProducts.where((product) => product.isFeatured).toList();
      
      final response = ProductListResponse(
        products: featuredProducts.take(limit).toList(),
        totalCount: featuredProducts.length,
        page: 1,
        perPage: limit,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to get featured products: $e');
    }
  }

  /// Get sale products
  Future<ApiResponse<ProductListResponse>> getSaleProducts({
    int page = 1,
    int perPage = 20,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final allProducts = MockProductService.generateProductCatalog(60);
      final saleProducts = allProducts.where((product) => product.isOnSale).toList();
      
      // Pagination
      final startIndex = (page - 1) * perPage;
      final endIndex = startIndex + perPage;
      final paginatedProducts = saleProducts.sublist(
        startIndex,
        endIndex < saleProducts.length ? endIndex : saleProducts.length
      );
      
      final response = ProductListResponse(
        products: paginatedProducts,
        totalCount: saleProducts.length,
        page: page,
        perPage: perPage,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to get sale products: $e');
    }
  }

  /// Get available categories
  Future<ApiResponse<List<String>>> getCategories() async {
    await Future.delayed(Duration(seconds: 0.5));
    
    try {
      final categories = [
        'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Accessories', 'Footwear', 'Activewear'
      ];
      return ApiResponse.success(categories);
    } catch (e) {
      return ApiResponse.error('Failed to get categories: $e');
    }
  }

  /// Get available brands
  Future<ApiResponse<List<String>>> getBrands() async {
    await Future.delayed(Duration(seconds: 0.5));
    
    try {
      final brands = [
        'Zara', 'H&M', 'Uniqlo', 'Mango', 'Bershka', 'Stradivarius',
        'Forever 21', 'ASOS', 'Nike', 'Adidas', 'Gap', 'Levi\'s'
      ];
      return ApiResponse.success(brands);
    } catch (e) {
      return ApiResponse.error('Failed to get brands: $e');
    }
  }

  /// Get size chart for a specific category
  Future<ApiResponse<Map<String, dynamic>>> getSizeChart(String category) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final sizeCharts = {
        'Tops': {
          'XS': {'chest': '32-34"', 'waist': '26-28"', 'length': '24"'},
          'S': {'chest': '34-36"', 'waist': '28-30"', 'length': '25"'},
          'M': {'chest': '36-38"', 'waist': '30-32"', 'length': '26"'},
          'L': {'chest': '38-40"', 'waist': '32-34"', 'length': '27"'},
          'XL': {'chest': '40-42"', 'waist': '34-36"', 'length': '28"'},
        },
        'Bottoms': {
          'XS': {'waist': '26-28"', 'hip': '34-36"', 'inseam': '30"'},
          'S': {'waist': '28-30"', 'hip': '36-38"', 'inseam': '30"'},
          'M': {'waist': '30-32"', 'hip': '38-40"', 'inseam': '30"'},
          'L': {'waist': '32-34"', 'hip': '40-42"', 'inseam': '30"'},
          'XL': {'waist': '34-36"', 'hip': '42-44"', 'inseam': '30"'},
        },
      };
      
      final sizeChart = sizeCharts[category] ?? {};
      return ApiResponse.success(sizeChart);
    } catch (e) {
      return ApiResponse.error('Failed to get size chart: $e');
    }
  }

  // ==================== ORDER MANAGEMENT API ENDPOINTS ====================

  /// Create a new order
  /// This is the main order creation endpoint as specified in requirements
  Future<ApiResponse<Order>> createOrder(Map<String, dynamic> orderData) async {
    await Future.delayed(Duration(seconds: 2)); // Simulate API delay
    
    try {
      // Validate required fields
      final validation = _validateOrderData(orderData);
      if (!validation.isValid) {
        return ApiResponse.error(validation.errorMessage!);
      }

      // Create Razorpay order ID if payment method is Razorpay
      final paymentMethod = PaymentMethodType.fromString(
        orderData['paymentMethod'] as String? ?? 'razorpay'
      );
      
      if (paymentMethod == PaymentMethodType.razorpay) {
        final customerInfo = CustomerInfo.fromJson(orderData['customer']);
        final itemsJson = orderData['items'] as List<dynamic>;
        final items = itemsJson.map((item) => OrderItem.fromJson(item)).toList();
        final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
        
        final razorpayOrderId = MockOrderService.generateRazorpayOrderId('temp');
        
        // Add Razorpay order ID to order data
        orderData['razorpayOrderId'] = razorpayOrderId;
      }

      // Create the order using mock service
      final order = MockOrderService.createOrder(orderData);
      
      return ApiResponse.success(order);
    } catch (e) {
      return ApiResponse.error('Failed to create order: $e');
    }
  }

  /// Get all orders with pagination and filtering
  Future<ApiResponse<OrderListResponse>> getOrders({
    String? userId,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 20,
    String? search,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      List<Order> orders;
      
      if (search != null && search.isNotEmpty) {
        // Use search functionality
        orders = MockOrderService.searchOrders(search);
      } else {
        // Use filtered list
        orders = MockOrderService.getOrders(
          userId: userId,
          status: status,
          fromDate: fromDate,
          toDate: toDate,
          page: page,
          perPage: perPage,
        );
      }
      
      // Apply user filter after search if needed
      if (userId != null && search == null) {
        orders = orders.where((order) => order.userId == userId).toList();
      }
      
      // Apply status filter after search if needed
      if (status != null && search == null) {
        orders = orders.where((order) => order.status == status).toList();
      }
      
      // Calculate summary statistics
      final totalOrders = orders.length;
      final totalRevenue = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
      final deliveredOrders = orders.where((o) => o.status == OrderStatus.delivered).length;
      final cancelledOrders = orders.where((o) => o.status == OrderStatus.cancelled).length;
      
      final summary = {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'deliveredOrders': deliveredOrders,
        'cancelledOrders': cancelledOrders,
        'averageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
        'deliveryRate': totalOrders > 0 ? (deliveredOrders / totalOrders * 100) : 0.0,
        'cancellationRate': totalOrders > 0 ? (cancelledOrders / totalOrders * 100) : 0.0,
      };
      
      final response = OrderListResponse(
        orders: orders,
        totalCount: totalOrders,
        page: page,
        perPage: perPage,
        summary: summary,
      );
      
      return ApiResponse.success(response);
    } catch (e) {
      return ApiResponse.error('Failed to fetch orders: $e');
    }
  }

  /// Get order by ID
  Future<ApiResponse<Order>> getOrder(String orderId) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (orderId.isEmpty) {
      return ApiResponse.error('Order ID is required');
    }
    
    try {
      final order = MockOrderService.getOrderById(orderId);
      if (order == null) {
        return ApiResponse.error('Order not found');
      }
      
      return ApiResponse.success(order);
    } catch (e) {
      return ApiResponse.error('Failed to fetch order: $e');
    }
  }

  /// Update order status
  Future<ApiResponse<Order>> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (orderId.isEmpty) {
      return ApiResponse.error('Order ID is required');
    }
    
    try {
      final updatedOrder = MockOrderService.updateOrderStatus(orderId, newStatus);
      if (updatedOrder == null) {
        return ApiResponse.error('Order not found or status update not allowed');
      }
      
      return ApiResponse.success(updatedOrder);
    } catch (e) {
      return ApiResponse.error('Failed to update order status: $e');
    }
  }

  /// Cancel order
  Future<ApiResponse<Order>> cancelOrder(String orderId, String reason) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (orderId.isEmpty) {
      return ApiResponse.error('Order ID is required');
    }
    
    if (reason.isEmpty) {
      return ApiResponse.error('Cancellation reason is required');
    }
    
    try {
      final cancelledOrder = MockOrderService.cancelOrder(orderId, reason);
      if (cancelledOrder == null) {
        return ApiResponse.error('Order cannot be cancelled');
      }
      
      return ApiResponse.success(cancelledOrder);
    } catch (e) {
      return ApiResponse.error('Failed to cancel order: $e');
    }
  }

  /// Razorpay webhook handler for payment verification
  Future<ApiResponse<PaymentVerificationResult>> handleRazorpayWebhook(
    RazorpayWebhookPayload webhookPayload
  ) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate webhook processing
    
    try {
      final event = webhookPayload.event;
      final payload = webhookPayload.payload;
      
      if (event == 'payment.captured') {
        final paymentData = payload['payment'] as Map<String, dynamic>;
        final orderId = paymentData['notes']['order_id'] as String? ?? '';
        final razorpayOrderId = paymentData['order_id'] as String? ?? '';
        final razorpayPaymentId = paymentData['id'] as String? ?? '';
        final razorpaySignature = paymentData['signature'] as String? ?? '';
        final amount = (paymentData['amount'] as num?)?.toDouble() ?? 0.0;
        
        if (orderId.isEmpty) {
          return ApiResponse.error('Order ID not found in webhook payload');
        }
        
        // Verify the payment
        final isVerified = MockOrderService.verifyRazorpayPayment(
          orderId: orderId,
          razorpayOrderId: razorpayOrderId,
          razorpayPaymentId: razorpayPaymentId,
          razorpaySignature: razorpaySignature,
          expectedAmount: amount / 100, // Razorpay amount is in paise
        );
        
        if (isVerified) {
          final result = PaymentVerificationResult.success(
            orderId: orderId,
            paymentId: razorpayPaymentId,
            amount: amount / 100,
            currency: paymentData['currency'] as String? ?? 'INR',
          );
          return ApiResponse.success(result);
        } else {
          final result = PaymentVerificationResult.failure('Payment verification failed');
          return ApiResponse.error('Payment verification failed');
        }
      } else if (event == 'payment.failed') {
        final paymentData = payload['payment'] as Map<String, dynamic>;
        final orderId = paymentData['notes']['order_id'] as String? ?? '';
        final error = paymentData['error_description'] as String? ?? 'Payment failed';
        
        if (orderId.isNotEmpty) {
          // Update order status to reflect failed payment
          MockOrderService.updateOrderStatus(orderId, OrderStatus.cancelled);
        }
        
        final result = PaymentVerificationResult.failure(error);
        return ApiResponse.error('Payment failed: $error');
      } else {
        // Unsupported webhook event
        return ApiResponse.error('Unsupported webhook event: $event');
      }
    } catch (e) {
      return ApiResponse.error('Failed to process webhook: $e');
    }
  }

  /// Verify Razorpay payment signature
  Future<ApiResponse<PaymentVerificationResult>> verifyPaymentSignature({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required double expectedAmount,
  }) async {
    await Future.delayed(Duration(seconds: 1));
    
    try {
      final isVerified = MockOrderService.verifyRazorpayPayment(
        orderId: orderId,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
        expectedAmount: expectedAmount,
      );
      
      if (isVerified) {
        final result = PaymentVerificationResult.success(
          orderId: orderId,
          paymentId: razorpayPaymentId,
          amount: expectedAmount,
          currency: 'INR',
        );
        return ApiResponse.success(result);
      } else {
        final result = PaymentVerificationResult.failure('Payment verification failed');
        return ApiResponse.error('Payment verification failed');
      }
    } catch (e) {
      return ApiResponse.error('Payment verification failed: $e');
    }
  }

  /// Generate Razorpay order ID
  Future<ApiResponse<String>> generateRazorpayOrderId(String orderId) async {
    await Future.delayed(Duration(seconds: 0.5));
    
    try {
      final razorpayOrderId = MockOrderService.generateRazorpayOrderId(orderId);
      return ApiResponse.success(razorpayOrderId);
    } catch (e) {
      return ApiResponse.error('Failed to generate Razorpay order ID: $e');
    }
  }

  /// Get order analytics and reporting
  Future<ApiResponse<Map<String, dynamic>>> getOrderAnalytics({
    DateTime? fromDate,
    DateTime? toDate,
    String? userId,
  }) async {
    await Future.delayed(Duration(seconds: 2));
    
    try {
      final analytics = MockOrderService.getOrderAnalytics();
      
      // Add additional date filtering if specified
      if (fromDate != null || toDate != null) {
        var filteredOrders = MockOrderService.getOrders();
        
        if (fromDate != null) {
          filteredOrders = filteredOrders.where((order) => 
              order.createdAt.isAfter(fromDate!)).toList();
        }
        
        if (toDate != null) {
          filteredOrders = filteredOrders.where((order) => 
              order.createdAt.isBefore(toDate!)).toList();
        }
        
        if (userId != null) {
          filteredOrders = filteredOrders.where((order) => 
              order.userId == userId).toList();
        }
        
        // Recalculate analytics with filtered data
        final totalOrders = filteredOrders.length;
        final deliveredOrders = filteredOrders.where((o) => o.status == OrderStatus.delivered).length;
        final totalRevenue = filteredOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
        
        analytics.addAll({
          'filteredTotalOrders': totalOrders,
          'filteredDeliveredOrders': deliveredOrders,
          'filteredTotalRevenue': totalRevenue,
          'filteredAverageOrderValue': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
          'dateRange': {
            'fromDate': fromDate?.toIso8601String(),
            'toDate': toDate?.toIso8601String(),
          },
        });
      }
      
      return ApiResponse.success(analytics);
    } catch (e) {
      return ApiResponse.error('Failed to get order analytics: $e');
    }
  }

  /// Export orders data
  Future<ApiResponse<String>> exportOrders({
    String? userId,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    String format = 'json',
  }) async {
    await Future.delayed(Duration(seconds: 3)); // Simulate export processing
    
    try {
      final orders = MockOrderService.getOrders(
        userId: userId,
        status: status,
        fromDate: fromDate,
        toDate: toDate,
        page: 1,
        perPage: 1000, // Export all orders
      );
      
      if (format == 'json') {
        final jsonData = orders.map((order) => order.toJson()).toList();
        final jsonString = jsonEncode(jsonData);
        return ApiResponse.success(jsonString);
      } else if (format == 'csv') {
        // Generate CSV format
        final csvData = _generateCsvFromOrders(orders);
        return ApiResponse.success(csvData);
      } else {
        return ApiResponse.error('Unsupported export format: $format');
      }
    } catch (e) {
      return ApiResponse.error('Failed to export orders: $e');
    }
  }

  /// Get order status history
  Future<ApiResponse<List<Map<String, dynamic>>>> getOrderStatusHistory(String orderId) async {
    await Future.delayed(Duration(seconds: 1));
    
    if (orderId.isEmpty) {
      return ApiResponse.error('Order ID is required');
    }
    
    try {
      final order = MockOrderService.getOrderById(orderId);
      if (order == null) {
        return ApiResponse.error('Order not found');
      }
      
      // Generate status history (in real implementation, this would come from database)
      final history = <Map<String, dynamic>>[
        {
          'status': OrderStatus.orderPlaced.displayName,
          'timestamp': order.createdAt.toIso8601String(),
          'description': 'Order has been placed successfully',
        },
      ];
      
      if (order.payment.isSuccessful) {
        history.add({
          'status': OrderStatus.paymentConfirmed.displayName,
          'timestamp': order.payment.paidAt?.toIso8601String(),
          'description': 'Payment has been confirmed and verified',
        });
      }
      
      if (order.status.index >= OrderStatus.processing.index) {
        history.add({
          'status': OrderStatus.processing.displayName,
          'timestamp': order.updatedAt.toIso8601String(),
          'description': 'Order is being processed for shipment',
        });
      }
      
      if (order.shipping.isShipped) {
        history.add({
          'status': OrderStatus.shipped.displayName,
          'timestamp': order.shipping.shippedAt?.toIso8601String(),
          'description': 'Order has been shipped',
          'trackingNumber': order.shipping.trackingNumber,
          'carrier': order.shipping.carrier,
        });
      }
      
      if (order.shipping.isDelivered) {
        history.add({
          'status': OrderStatus.delivered.displayName,
          'timestamp': order.completedAt?.toIso8601String(),
          'description': 'Order has been delivered successfully',
        });
      }
      
      return ApiResponse.success(history);
    } catch (e) {
      return ApiResponse.error('Failed to get order status history: $e');
    }
  }

  // ==================== ORDER VALIDATION HELPERS ====================

  /// Validate order data before creation
  OrderValidationResult _validateOrderData(Map<String, dynamic> orderData) {
    // Check required fields
    if (!orderData.containsKey('userId') || orderData['userId'].toString().isEmpty) {
      return OrderValidationResult(false, 'User ID is required');
    }
    
    if (!orderData.containsKey('items') || orderData['items'] == null) {
      return OrderValidationResult(false, 'Order items are required');
    }
    
    if (!orderData.containsKey('customer') || orderData['customer'] == null) {
      return OrderValidationResult(false, 'Customer information is required');
    }
    
    if (!orderData.containsKey('paymentMethod') || orderData['paymentMethod'].toString().isEmpty) {
      return OrderValidationResult(false, 'Payment method is required');
    }
    
    // Validate items
    final itemsJson = orderData['items'] as List<dynamic>;
    if (itemsJson.isEmpty) {
      return OrderValidationResult(false, 'At least one item is required');
    }
    
    // Validate each item
    for (final item in itemsJson) {
      final itemData = item as Map<String, dynamic>;
      if (!itemData.containsKey('product') || itemData['product'] == null) {
        return OrderValidationResult(false, 'Product information is required for each item');
      }
      
      if (!itemData.containsKey('quantity') || itemData['quantity'] <= 0) {
        return OrderValidationResult(false, 'Valid quantity is required for each item');
      }
    }
    
    // Validate customer information
    try {
      final customer = CustomerInfo.fromJson(orderData['customer']);
      if (customer.name.isEmpty || customer.email.isEmpty || customer.phone.isEmpty) {
        return OrderValidationResult(false, 'Complete customer information is required');
      }
      
      if (!customer.shippingAddress.isComplete) {
        return OrderValidationResult(false, 'Complete shipping address is required');
      }
    } catch (e) {
      return OrderValidationResult(false, 'Invalid customer information format');
    }
    
    return OrderValidationResult(true, null);
  }

  /// Generate CSV format from orders
  String _generateCsvFromOrders(List<Order> orders) {
    final buffer = StringBuffer();
    
    // CSV headers
    buffer.writeln('Order ID,Customer Name,Customer Email,Total Amount,Status,Created Date,Items Count,Shipping Cost');
    
    // CSV data rows
    for (final order in orders) {
      buffer.writeln([
        order.id,
        order.customer.name,
        order.customer.email,
        order.totalAmount.toStringAsFixed(2),
        order.status.displayName,
        order.createdAt.toIso8601String().split('T')[0], // Date only
        order.totalItemsCount.toString(),
        order.shipping.cost.toStringAsFixed(2),
      ].join(','));
    }
    
    return buffer.toString();
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Generate mock product for testing
  Product _generateMockProduct(String id) {
    final allProducts = MockProductService.generateProductCatalog(150);
    // Find product by ID or return a random one
    final productIndex = int.tryParse(id.split('_').last) ?? 0;
    return allProducts[productIndex % allProducts.length];
  }

  /// Generate mock avatar for testing
  Avatar _generateMockAvatar(String id) {
    final bodyTypes = ['Slim', 'Regular', 'Athletic', 'PlusSize'];
    final ethnicities = ['Caucasian', 'Asian', 'African', 'Hispanic', 'Mixed'];
    final genders = ['Male', 'Female', 'Non-binary'];
    final skinTones = ['Light', 'Medium', 'Dark', 'Olive', 'Tan'];
    final hairColors = ['Black', 'Brown', 'Blonde', 'Red', 'Gray'];
    final eyeColors = ['Brown', 'Blue', 'Green', 'Hazel', 'Gray'];
    
    final random = DateTime.now().millisecondsSinceEpoch + id.hashCode;
    final bodyType = bodyTypes[random % bodyTypes.length];
    final ethnicity = ethnicities[random % ethnicities.length];
    final gender = genders[random % genders.length];
    final skinTone = skinTones[random % skinTones.length];
    final hairColor = hairColors[random % hairColors.length];
    final eyeColor = eyeColors[random % eyeColors.length];
    
    // Generate measurements based on body type
    final measurements = _generateMeasurements(bodyType, gender);
    final attributes = AvatarAttributes(
      bodyType: bodyType,
      ethnicity: ethnicity,
      skinTone: skinTone,
      hairColor: hairColor,
      hairStyle: 'Style ${random % 5}',
      eyeColor: eyeColor,
      gender: gender,
      age: 18 + (random % 40),
    );
    
    final metadata = AvatarMetadata(
      fileSize: 2048576 + (random % 10485760), // 2MB - 12MB
      fileFormat: 'glb',
      polyCount: 5000 + (random % 45000),
      modelVersion: '1.${random % 5}',
      textures: ['diffuse', 'normal', 'roughness'],
      isOptimized: random % 3 == 0,
      qualityLevel: ['Low', 'Medium', 'High'][random % 3],
      lastUsed: DateTime.now().subtract(Duration(days: random % 30)),
    );
    
    return Avatar(
      id: id,
      name: 'Avatar ${id.substring(0, 8)}',
      modelUrl: 'assets/avatars/${id}_model.glb',
      thumbnailUrl: 'assets/avatars/${id}_thumb.jpg',
      createdAt: DateTime.now().subtract(Duration(days: random % 365)),
      updatedAt: DateTime.now().subtract(Duration(days: random % 30)),
      measurements: measurements,
      attributes: attributes,
      metadata: metadata,
      isDefault: random % 10 == 0,
      isFavorite: random % 5 == 0,
      usageCount: random % 100,
      tags: ['featured', 'popular', 'new'].take(random % 3).toList(),
      description: 'A beautiful avatar with $bodyType body type and $ethnicity features',
    );
  }

  /// Generate mock avatar list
  List<Avatar> _generateMockAvatarList(int count) {
    return List.generate(count, (index) {
      final id = 'avatar_${index}_${DateTime.now().millisecondsSinceEpoch}';
      return _generateMockAvatar(id);
    });
  }

  /// Generate measurements based on body type and gender
  AvatarMeasurements _generateMeasurements(String bodyType, String gender) {
    final baseHeight = gender == 'Male' ? 175.0 : 162.0;
    final heightVariance = bodyType == 'Tall' ? 10.0 : bodyType == 'Short' ? -10.0 : 0.0;
    
    final height = baseHeight + heightVariance + (DateTime.now().millisecond % 20 - 10);
    final weight = 60 + (DateTime.now().millisecond % 40);
    
    final chestMultiplier = gender == 'Male' ? 1.1 : 1.0;
    final waistMultiplier = gender == 'Male' ? 0.9 : 1.0;
    
    return AvatarMeasurements(
      height: height,
      weight: weight,
      chest: 90 * chestMultiplier + (DateTime.now().millisecond % 20 - 10),
      waist: 70 * waistMultiplier + (DateTime.now().millisecond % 15 - 7.5),
      hips: 95 + (DateTime.now().millisecond % 20 - 10),
      shoulders: 45 + (DateTime.now().millisecond % 10 - 5),
      arms: 65 + (DateTime.now().millisecond % 15 - 7.5),
      legs: 85 + (DateTime.now().millisecond % 20 - 10),
    );
  }

  /// Close the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Order validation result class
class OrderValidationResult {
  final bool isValid;
  final String? errorMessage;

  OrderValidationResult(this.isValid, this.errorMessage);
}

/// API response wrapper class
class ApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    this.statusCode,
  });

  /// Create a successful response
  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
    );
  }

  /// Create an error response
  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  /// Check if response has data
  bool get hasData => data != null;

  /// Check if response has error
  bool get hasError => error != null;

  @override
  String toString() {
    return 'ApiResponse{isSuccess: $isSuccess, data: $data, error: $error}';
  }
}

/// Product list response wrapper
class ProductListResponse {
  final List<Product> products;
  final int totalCount;
  final int page;
  final int perPage;

  ProductListResponse({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.perPage,
  });

  factory ProductListResponse.fromJson(Map<String, dynamic> json) {
    return ProductListResponse(
      products: (json['products'] as List<dynamic>?)
          ?.map((product) => Product.fromJson(product))
          .toList() ?? [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 20,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'products': products.map((product) => product.toJson()).toList(),
      'totalCount': totalCount,
      'page': page,
      'perPage': perPage,
    };
  }

  int get totalPages => (totalCount / perPage).ceil();

  bool get hasMore => page < totalPages;

  @override
  String toString() {
    return 'ProductListResponse{products: ${products.length}, totalCount: $totalCount, page: $page, perPage: $perPage}';
  }
}

/// Order list response wrapper
class OrderListResponse {
  final List<Order> orders;
  final int totalCount;
  final int page;
  final int perPage;
  final Map<String, dynamic> summary;

  OrderListResponse({
    required this.orders,
    required this.totalCount,
    required this.page,
    required this.perPage,
    required this.summary,
  });

  factory OrderListResponse.fromJson(Map<String, dynamic> json) {
    final ordersJson = json['orders'] as List<dynamic>? ?? [];
    final orders = ordersJson
        .map((orderJson) => Order.fromJson(orderJson as Map<String, dynamic>))
        .toList();

    return OrderListResponse(
      orders: orders,
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 20,
      summary: json['summary'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orders': orders.map((order) => order.toJson()).toList(),
      'totalCount': totalCount,
      'page': page,
      'perPage': perPage,
      'summary': summary,
    };
  }

  int get totalPages => (totalCount / perPage).ceil();
  bool get hasMore => page < totalPages;

  @override
  String toString() {
    return 'OrderListResponse{orders: ${orders.length}, totalCount: $totalCount, page: $page, perPage: $perPage}';
  }
}

/// Razorpay webhook payload
class RazorpayWebhookPayload {
  final String event;
  final Map<String, dynamic> payload;
  final String createdAt;

  RazorpayWebhookPayload({
    required this.event,
    required this.payload,
    required this.createdAt,
  });

  factory RazorpayWebhookPayload.fromJson(Map<String, dynamic> json) {
    return RazorpayWebhookPayload(
      event: json['event'] as String? ?? '',
      payload: json['payload'] as Map<String, dynamic>? ?? {},
      createdAt: json['created_at'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event': event,
      'payload': payload,
      'created_at': createdAt,
    };
  }
}

/// Payment verification result
class PaymentVerificationResult {
  final bool isValid;
  final String? orderId;
  final String? paymentId;
  final String? errorMessage;
  final double? amount;
  final String? currency;
  final Map<String, dynamic> rawResponse;

  PaymentVerificationResult({
    required this.isValid,
    this.orderId,
    this.paymentId,
    this.errorMessage,
    this.amount,
    this.currency,
    required this.rawResponse,
  });

  factory PaymentVerificationResult.success({
    required String orderId,
    required String paymentId,
    required double amount,
    required String currency,
  }) {
    return PaymentVerificationResult(
      isValid: true,
      orderId: orderId,
      paymentId: paymentId,
      amount: amount,
      currency: currency,
      rawResponse: {},
    );
  }

  factory PaymentVerificationResult.failure(String errorMessage) {
    return PaymentVerificationResult(
      isValid: false,
      errorMessage: errorMessage,
      rawResponse: {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'orderId': orderId,
      'paymentId': paymentId,
      'errorMessage': errorMessage,
      'amount': amount,
      'currency': currency,
      'rawResponse': rawResponse,
    };
  }
}