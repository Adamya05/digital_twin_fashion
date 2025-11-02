/// Cart Provider
/// 
/// State management for shopping cart items, pricing calculations, and checkout process.
/// Handles cart operations like add, remove, update quantities, and total calculations.
/// Integrates with saved items from swipe actions.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/swipe_history_model.dart';
import '../services/swipe_persistence_service.dart';

class CartNotifier extends StateNotifier<CartState> {
  final SwipePersistenceService _persistenceService;
  
  CartNotifier(this._persistenceService) : super(const CartState()) {
    _loadSavedItems();
  }

  Future<void> _loadSavedItems() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _persistenceService.init();
      final savedItems = await _persistenceService.getSavedItems();
      
      state = state.copyWith(
        isLoading: false,
        savedItems: savedItems,
        cartItems: savedItems.map((item) => item.product).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addSavedItemToCart(SavedItem savedItem) async {
    // Convert saved item to cart item
    final cartItem = CartItem(
      id: savedItem.id,
      product: savedItem.product,
      quantity: 1,
      addedAt: DateTime.now(),
    );

    final updatedItems = List<CartItem>.from(state.cartItems);
    
    // Check if item already exists
    final existingIndex = updatedItems.indexWhere((item) => item.product.id == savedItem.product.id);
    
    if (existingIndex != -1) {
      // Update quantity if item exists
      updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
        quantity: updatedItems[existingIndex].quantity + 1,
      );
    } else {
      // Add new item
      updatedItems.add(cartItem);
    }

    state = state.copyWith(cartItems: updatedItems);
  }

  Future<void> removeSavedItem(String itemId) async {
    try {
      await _persistenceService.removeSavedItem(itemId);
      final savedItems = await _persistenceService.getSavedItems();
      
      state = state.copyWith(
        savedItems: savedItems,
        cartItems: savedItems.map((item) => CartItem(
          id: item.id,
          product: item.product,
          quantity: 1,
          addedAt: item.savedAt,
        )).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateSavedItem(SavedItem updatedItem) async {
    try {
      await _persistenceService.updateSavedItem(updatedItem);
      final savedItems = await _persistenceService.getSavedItems();
      
      state = state.copyWith(savedItems: savedItems);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void updateCartItemQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeCartItem(productId);
      return;
    }

    final updatedItems = List<CartItem>.from(state.cartItems);
    final index = updatedItems.indexWhere((item) => item.product.id == productId);
    
    if (index != -1) {
      updatedItems[index] = updatedItems[index].copyWith(quantity: quantity);
      state = state.copyWith(cartItems: updatedItems);
    }
  }

  void removeCartItem(String productId) {
    final updatedItems = state.cartItems.where((item) => item.product.id != productId).toList();
    state = state.copyWith(cartItems: updatedItems);
  }

  void clearCart() {
    state = state.copyWith(cartItems: []);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Stock validation
  bool validateStockAvailability() {
    for (final item in state.cartItems) {
      if (item.product.inventory.stockCount < item.quantity) {
        return false;
      }
    }
    return true;
  }

  // Get items with low stock
  List<CartItem> getLowStockItems() {
    return state.cartItems
        .where((item) => item.product.inventory.stockCount < item.quantity)
        .toList();
  }

  // Persistent cart storage with SharedPreferences
  Future<void> saveCartToStorage() async {
    try {
      await _persistenceService.saveCartItems(state.cartItems);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save cart: $e');
    }
  }

  Future<void> loadCartFromStorage() async {
    try {
      final savedCartItems = await _persistenceService.getCartItems();
      if (savedCartItems.isNotEmpty) {
        state = state.copyWith(cartItems: savedCartItems);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to load cart: $e');
    }
  }

  // Bulk operations
  void addMultipleItems(List<CartItem> items) {
    final updatedItems = List<CartItem>.from(state.cartItems);
    
    for (final newItem in items) {
      final existingIndex = updatedItems.indexWhere(
        (item) => item.product.id == newItem.product.id,
      );
      
      if (existingIndex != -1) {
        // Merge quantities if item exists
        updatedItems[existingIndex] = updatedItems[existingIndex].copyWith(
          quantity: updatedItems[existingIndex].quantity + newItem.quantity,
        );
      } else {
        // Add new item
        updatedItems.add(newItem);
      }
    }
    
    state = state.copyWith(cartItems: updatedItems);
  }

  void removeMultipleItems(List<String> productIds) {
    final updatedItems = state.cartItems
        .where((item) => !productIds.contains(item.product.id))
        .toList();
    state = state.copyWith(cartItems: updatedItems);
  }

  // Move items to wishlist
  void moveToWishlist(String productId) {
    // TODO: Implement wishlist integration
    removeCartItem(productId);
  }

  // Cart sharing functionality
  Map<String, dynamic> createCartShareData() {
    return {
      'items': state.cartItems.map((item) => {
        'id': item.product.id,
        'name': item.product.name,
        'price': item.product.currentPrice,
        'quantity': item.quantity,
        'image': item.product.primaryImage,
      }).toList(),
      'totalAmount': state.totalPrice,
      'itemCount': state.itemCount,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Cart history and recently viewed items
  Future<void> saveToCartHistory() async {
    try {
      await _persistenceService.saveCartHistory(
        createCartShareData(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to save cart history: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getCartHistory() async {
    try {
      return await _persistenceService.getCartHistory();
    } catch (e) {
      return [];
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getCartAnalytics() async {
    final analytics = {
      'totalItems': state.cartItems.length,
      'totalValue': state.cartItems.fold<double>(
        0.0, 
        (sum, item) => sum + (item.product.price * item.quantity)
      ),
      'averageItemValue': state.cartItems.isNotEmpty
          ? state.cartItems.fold<double>(0.0, (sum, item) => sum + item.product.price) / state.cartItems.length
          : 0.0,
      'savedItemsCount': state.savedItems.length,
      'categories': _getCategoryBreakdown(),
    };
    
    return analytics;
  }

  Map<String, int> _getCategoryBreakdown() {
    final categoryCount = <String, int>{};
    
    for (final item in state.cartItems) {
      final category = item.product.category;
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }
    
    return categoryCount;
  }

  Future<void> checkout() async {
    // TODO: Implement checkout process
    state = state.copyWith(isProcessing: true);
    
    try {
      // Simulate checkout delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Clear cart after successful checkout
      state = state.copyWith(
        isProcessing: false,
        cartItems: [],
        lastOrderTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }
}

class CartState {
  final List<SavedItem> savedItems;
  final List<CartItem> cartItems;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final DateTime? lastOrderTime;

  const CartState({
    this.savedItems = const [],
    this.cartItems = const [],
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.lastOrderTime,
  });

  double get totalPrice => cartItems.fold(
    0.0,
    (sum, item) => sum + (item.product.price * item.quantity),
  );

  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<SavedItem>? savedItems,
    List<CartItem>? cartItems,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    DateTime? lastOrderTime,
  }) {
    return CartState(
      savedItems: savedItems ?? this.savedItems,
      cartItems: cartItems ?? this.cartItems,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      lastOrderTime: lastOrderTime ?? this.lastOrderTime,
    );
  }
}

class CartItem {
  final String id;
  final Product product;
  final int quantity;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  double get totalPrice => product.price * quantity;
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  final persistenceService = ref.read(swipePersistenceServiceProvider);
  return CartNotifier(persistenceService);
});

// Legacy provider for backward compatibility
class CartProvider extends ChangeNotifier {
  final CartNotifier _notifier;
  
  CartProvider(this._notifier);

  List<dynamic> get cartItems => _notifier.state.cartItems.map((item) => item.product).toList();
  double get totalPrice => _notifier.state.totalPrice;
  int get itemCount => _notifier.state.itemCount;
  bool get isLoading => _notifier.state.isLoading;
  String? get error => _notifier.state.error;
  bool get isProcessing => _notifier.state.isProcessing;

  Future<void> addSavedItemToCart(SavedItem savedItem) async {
    await _notifier.addSavedItemToCart(savedItem);
    notifyListeners();
  }

  Future<void> removeSavedItem(String itemId) async {
    await _notifier.removeSavedItem(itemId);
    notifyListeners();
  }

  void addItem(dynamic product) {
    // Legacy method - converts product to SavedItem and adds to cart
    final savedItem = SavedItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      product: product as Product,
      savedAt: DateTime.now(),
    );
    _notifier.addSavedItemToCart(savedItem);
    notifyListeners();
  }

  void removeItem(dynamic product) {
    _notifier.removeCartItem((product as Product).id);
    notifyListeners();
  }

  void updateQuantity(dynamic product, int quantity) {
    _notifier.updateCartItemQuantity((product as Product).id, quantity);
    notifyListeners();
  }

  void clearCart() {
    _notifier.clearCart();
    notifyListeners();
  }

  void clearError() {
    _notifier.clearError();
    notifyListeners();
  }

  Future<void> checkout() async {
    await _notifier.checkout();
    notifyListeners();
  }
}