/// Feed Provider
/// 
/// State management for product feed data, loading states, and search functionality.
/// Handles pagination, filtering, and real-time product updates with Riverpod integration.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/swipe_history_model.dart';
import '../services/swipe_persistence_service.dart';

final swipePersistenceServiceProvider = Provider<SwipePersistenceService>((ref) {
  return SwipePersistenceService();
});

class FeedNotifier extends StateNotifier<FeedState> {
  final SwipePersistenceService _persistenceService;
  
  FeedNotifier(this._persistenceService) : super(const FeedState()) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _persistenceService.init();
      
      // Mock products for demo
      final products = _generateMockProducts();
      
      state = state.copyWith(
        isLoading: false,
        products: products,
        hasReachedEnd: products.length < 10, // Mock pagination
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  List<Product> _generateMockProducts() {
    return List.generate(20, (index) => Product(
      id: 'product_$index',
      name: 'Trendy Fashion Item $index',
      description: 'High-quality fashion item perfect for your wardrobe',
      price: 29.99 + index * 10,
      imageUrl: 'https://picsum.photos/300/400?random=$index',
      category: index % 3 == 0 ? 'Clothing' : index % 3 == 1 ? 'Accessories' : 'Shoes',
      stock: 10 + index,
      rating: 4.0 + (index % 5) * 0.2,
      reviewCount: 100 + index * 10,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> loadMoreProducts() async {
    if (state.isLoading || state.hasReachedEnd) return;

    state = state.copyWith(isLoadingMore: true);
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      final newProducts = _generateMockProducts();
      
      state = state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...newProducts],
        hasReachedEnd: state.products.length + newProducts.length > 50,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<void> swipeProduct({
    required Product product,
    required SwipeAction action,
    required double velocity,
  }) async {
    // Create swipe history entry
    final swipeHistory = SwipeHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      productId: product.id,
      action: action,
      timestamp: DateTime.now(),
      swipeVelocity: velocity,
    );

    // Save to persistence service
    await _persistenceService.addSwipeAction(swipeHistory);

    // Remove product from current feed
    final updatedProducts = List<Product>.from(state.products)
      ..removeWhere((p) => p.id == product.id);

    // Update state
    state = state.copyWith(
      products: updatedProducts,
      lastAction: action,
      lastSwipedProduct: product,
    );

    // If we're running low on products, load more
    if (updatedProducts.length < 5) {
      await loadMoreProducts();
    }

    // If this was a like action, save to closet
    if (action == SwipeAction.like || action == SwipeAction.superLike) {
      await _persistenceService.saveItem(SavedItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        savedAt: DateTime.now(),
      ));
    }
  }

  Future<bool> undoLastSwipe() async {
    final undoAction = await _persistenceService.performUndo();
    if (undoAction == null) return false;

    // Add the product back to the feed
    final productData = undoAction['item'];
    if (productData != null) {
      final product = Product.fromJson(productData['product']);
      state = state.copyWith(
        products: [product, ...state.products],
        lastAction: null,
        lastSwipedProduct: null,
      );
      return true;
    }
    
    return false;
  }

  Future<bool> canUndo() async {
    return await _persistenceService.canUndo();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> refresh() async {
    await _loadProducts();
  }

  // Legacy methods for backward compatibility
  Future<List<Product>> _fetchProducts(int page, int limit) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final List<Product> mockProducts = [];
    for (int i = 0; i < limit; i++) {
      final index = (page - 1) * limit + i;
      mockProducts.add(Product(
        id: 'product_$index',
        name: 'Fashion Item $index',
        description: 'High-quality fashion item perfect for your style',
        price: 29.99 + (index % 5) * 10.0,
        imageUrl: 'https://picsum.photos/400/600?random=$index',
        category: ['Clothing', 'Accessories', 'Shoes'][index % 3],
        stock: 10 + (index % 20),
        rating: 3.5 + (index % 15) / 10.0,
        reviewCount: 50 + (index % 200),
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now(),
      ));
    }
    
    return mockProducts;
  }

  void likeProduct(Product product) {
    swipeProduct(
      product: product,
      action: SwipeAction.like,
      velocity: 1.0,
    );
  }

  void dislikeProduct(Product product) {
    swipeProduct(
      product: product,
      action: SwipeAction.dislike,
      velocity: 1.0,
    );
  }
}

class FeedState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? error;
  final String searchQuery;
  final SwipeAction? lastAction;
  final Product? lastSwipedProduct;
  final int? currentPage;

  const FeedState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.error,
    this.searchQuery = '',
    this.lastAction,
    this.lastSwipedProduct,
    this.currentPage,
  });

  FeedState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? error,
    String? searchQuery,
    SwipeAction? lastAction,
    Product? lastSwipedProduct,
    int? currentPage,
  }) {
    return FeedState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      lastAction: lastAction ?? this.lastAction,
      lastSwipedProduct: lastSwipedProduct ?? this.lastSwipedProduct,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  final persistenceService = ref.watch(swipePersistenceServiceProvider);
  return FeedNotifier(persistenceService);
});

// Legacy provider for backward compatibility
class FeedProvider extends ChangeNotifier {
  final FeedNotifier _notifier;
  
  FeedProvider(this._notifier) : _currentPage = 1, _totalPages = 10, _hasMoreData = true;
  
  int _currentPage;
  int _totalPages;
  bool _hasMoreData;

  List<Product> get products => _notifier.state.products;
  bool get isLoading => _notifier.state.isLoading;
  String? get error => _notifier.state.error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  String get searchQuery => _notifier.state.searchQuery;
  bool get hasMoreData => _hasMoreData;
  SwipeAction? get lastAction => _notifier.state.lastAction;
  Product? get lastSwipedProduct => _notifier.state.lastSwipedProduct;

  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    _notifier.state = _notifier.state.copyWith(isLoading: true, error: null);

    try {
      final newProducts = await _notifier._fetchProducts(_currentPage, 10);
      
      if (refresh) {
        _notifier.state = _notifier.state.copyWith(products: newProducts);
      } else {
        _notifier.state = _notifier.state.copyWith(
          products: [..._notifier.state.products, ...newProducts]
        );
      }
      
      _hasMoreData = _notifier.state.products.length < _totalPages * 10;
      _currentPage++;
      _notifier.state = _notifier.state.copyWith(isLoading: false);
    } catch (e) {
      _notifier.state = _notifier.state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }

    notifyListeners();
  }

  Future<void> loadMoreProducts() async {
    if (!_hasMoreData || _notifier.state.isLoading) return;
    
    await loadProducts();
  }

  Future<void> swipeProduct({
    required Product product,
    required SwipeAction action,
    required double velocity,
  }) async {
    await _notifier.swipeProduct(
      product: product,
      action: action,
      velocity: velocity,
    );
  }

  Future<bool> undoLastSwipe() async {
    return await _notifier.undoLastSwipe();
  }

  Future<bool> canUndo() async {
    return await _notifier.canUndo();
  }

  void updateSearchQuery(String query) {
    _notifier.updateSearchQuery(query);
  }

  void clearError() {
    _notifier.clearError();
  }

  void likeProduct(Product product) {
    _notifier.likeProduct(product);
  }

  void dislikeProduct(Product product) {
    _notifier.dislikeProduct(product);
  }

  void reset() {
    _currentPage = 1;
    _totalPages = 10;
    _hasMoreData = true;
    _notifier.refresh();
  }

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}