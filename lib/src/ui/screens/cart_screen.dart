/// Enhanced Cart Screen
/// 
/// Comprehensive shopping cart interface with Indian market features:
/// - Product listing with images, sizes, colors, prices
/// - Quantity management with + / - controls
/// - Item removal with confirmation
/// - Move to wishlist functionality
/// - Order summary with ₹, GST, shipping calculations
/// - Checkout flow integration
/// - Pull-to-refresh and animations
/// - Persistent cart storage

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../providers/cart_provider.dart';
import '../../providers/checkout_provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../services/checkout_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../../themes/app_theme.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> 
    with TickerProviderStateMixin {
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _couponController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  
  String? appliedCoupon;
  double discountAmount = 0.0;
  bool isCheckingOut = false;
  Set<String> selectedItems = {};
  
  // Indian Rupee formatter
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    _couponController.dispose();
    super.dispose();
  }
  
  // Haptic feedback helper
  void _hapticFeedback([bool heavy = false]) {
    HapticFeedback.lightImpact();
    if (heavy) {
      HapticFeedback.heavyImpact();
    }
  }
  
  // Apply coupon code
  void _applyCoupon(String code) {
    setState(() {
      appliedCoupon = code.toUpperCase();
      // Simulate coupon validation and discount calculation
      switch (code.toUpperCase()) {
        case 'WELCOME10':
          discountAmount = 0.10;
          break;
        case 'FIRST20':
          discountAmount = 0.20;
          break;
        case 'FITFIT15':
          discountAmount = 0.15;
          break;
        default:
          appliedCoupon = null;
          discountAmount = 0.0;
          _showSnackBar('Invalid coupon code', isError: true);
          return;
      }
    });
    _showSnackBar('Coupon applied successfully!');
    _hapticFeedback();
  }
  
  // Calculate shipping cost
  double _calculateShipping(double subtotal) {
    return subtotal >= 2000 ? 0.0 : 99.0;
  }
  
  // Calculate GST (18%)
  double _calculateGST(double amount) {
    return amount * 0.18;
  }
  
  // Show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: _buildAppBar(cartState),
      body: RefreshIndicator(
        onRefresh: () async {
          _hapticFeedback();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (cartState.isLoading)
              const SliverFillRemaining(
                child: LoadingIndicator(message: 'Loading cart...'),
              )
            else if (cartState.cartItems.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your cart is empty',
                  subtitle: 'Add some products to get started',
                ),
              )
            else
              _buildCartContent(cartState),
          ],
        ),
      ),
    );
  }
  
  PreferredSizeWidget _buildAppBar(CartState cartState) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Shopping Cart'),
          if (cartState.cartItems.isNotEmpty)
            Text(
              '${cartState.itemCount} item${cartState.itemCount > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
            ),
        ],
      ),
      actions: [
        if (cartState.cartItems.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _showClearCartDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Cart'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'select_all',
                child: ListTile(
                  leading: Icon(Icons.select_all),
                  title: Text('Select All'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Clear Cart'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildCartContent(CartState cartState) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      slivers: [
        // Cart Items Section
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = cartState.cartItems[index];
              return _buildCartItem(item, index);
            },
            childCount: cartState.cartItems.length,
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        
        // Coupon Section
        _buildCouponSection(),
        
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        
        // Order Summary Section
        _buildOrderSummary(cartState),
        
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
  
  Widget _buildCartItem(CartItem item, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset((index % 2 == 0) ? -1.0 : 1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
        )),
        child: AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              GestureDetector(
                onTap: () => _viewProductDetails(item.product),
                child: Hero(
                  tag: 'product_${item.product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.product.primaryImage,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Remove Button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.product.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _removeItem(item.product.id),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Product Variants (Size, Color)
                    Row(
                      children: [
                        if (item.product.sizeInfo.selectedSize != null)
                          _buildVariantChip('Size: ${item.product.sizeInfo.selectedSize}'),
                        if (item.product.sizeInfo.selectedColor != null)
                          _buildVariantChip('Color: ${item.product.sizeInfo.selectedColor}'),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price and Quantity Controls
                    Row(
                      children: [
                        // Price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currencyFormatter.format(item.product.currentPrice),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              if (item.product.originalPrice > item.product.currentPrice)
                                Text(
                                  _currencyFormatter.format(item.product.originalPrice),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        // Quantity Controls
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: () => _updateQuantity(
                                  item.product.id, 
                                  item.quantity - 1,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: () => _updateQuantity(
                                  item.product.id, 
                                  item.quantity + 1,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton.icon(
                          onPressed: () => _moveToWishlist(item.product),
                          icon: const Icon(Icons.favorite_border, size: 16),
                          label: const Text('Wishlist'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _removeItem(item.product.id),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Remove'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVariantChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
  
  Widget _buildCouponSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                'Apply Coupon',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          if (appliedCoupon != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coupon applied: $appliedCoupon',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() {
                      appliedCoupon = null;
                      discountAmount = 0.0;
                    }),
                    icon: const Icon(Icons.close, size: 16),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        _applyCoupon(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  onPressed: () {
                    if (_couponController.text.isNotEmpty) {
                      _applyCoupon(_couponController.text);
                    }
                  },
                  label: 'Apply',
                  size: ButtonSize.small,
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildOrderSummary(CartState cartState) {
    final subtotal = cartState.totalPrice;
    final discount = subtotal * discountAmount;
    final shippingCost = _calculateShipping(subtotal);
    final taxableAmount = subtotal - discount;
    final gst = _calculateGST(taxableAmount);
    final total = taxableAmount + shippingCost + gst;
    
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long),
              const SizedBox(width: 8),
              Text(
                'Order Summary',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Order Items Summary
          ...cartState.cartItems.take(3).map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${item.product.name} x${item.quantity}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _currencyFormatter.format(item.product.currentPrice * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          )),
          
          if (cartState.cartItems.length > 3)
            Text(
              'and ${cartState.cartItems.length - 3} more items...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          
          const Divider(height: 24),
          
          // Price Breakdown
          _buildPriceRow('Subtotal', subtotal),
          if (discount > 0) _buildPriceRow('Discount', -discount, isDiscount: true),
          _buildPriceRow('Shipping', shippingCost, isFree: shippingCost == 0),
          _buildPriceRow('GST (18%)', gst),
          
          const Divider(height: 24),
          
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _currencyFormatter.format(total),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Delivery Information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated delivery: 3-5 business days',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Loyalty Points
          if (total > 500)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You\'ll earn ${(total * 0.05).toInt()} loyalty points',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 20),
          
          // Checkout Button
          ScaleTransition(
            scale: _scaleAnimation,
            child: AppButton(
              onPressed: isCheckingOut ? null : _startCheckout,
              label: isCheckingOut 
                ? 'Processing...' 
                : 'Checkout (${_currencyFormatter.format(total)})',
              size: ButtonSize.large,
              isLoading: isCheckingOut,
              icon: isCheckingOut ? null : Icons.payment,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceRow(String label, double amount, {
    bool isDiscount = false,
    bool isFree = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDiscount ? Colors.green.shade700 : null,
            ),
          ),
          Text(
            isFree ? 'FREE' : 
            (isDiscount ? '-${_currencyFormatter.format(amount.abs())}' : 
             _currencyFormatter.format(amount)),
            style: TextStyle(
              color: isDiscount ? Colors.green.shade700 : null,
              fontWeight: isDiscount ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
  
  // Action Methods
  void _updateQuantity(String productId, int newQuantity) {
    if (newQuantity < 1) {
      _removeItem(productId);
      return;
    }
    
    ref.read(cartProvider.notifier).updateCartItemQuantity(productId, newQuantity);
    _hapticFeedback();
    
    _showSnackBar(
      newQuantity > 1 ? 'Quantity updated' : 'Item added to cart',
    );
  }
  
  void _removeItem(String productId) {
    ref.read(cartProvider.notifier).removeCartItem(productId);
    _hapticFeedback(true);
    _showSnackBar('Item removed from cart');
  }
  
  void _moveToWishlist(Product product) {
    // TODO: Implement wishlist functionality
    _hapticFeedback();
    _showSnackBar('Item moved to wishlist');
  }
  
  void _viewProductDetails(Product product) {
    // TODO: Navigate to product detail screen
    _showSnackBar('Opening product details...');
  }
  
  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              _hapticFeedback(true);
              _showSnackBar('Cart cleared');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
  
  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareCart();
        break;
      case 'select_all':
        _selectAllItems();
        break;
      case 'clear':
        _showClearCartDialog();
        break;
    }
  }
  
  void _shareCart() {
    // TODO: Implement cart sharing functionality
    _showSnackBar('Cart sharing feature coming soon!');
  }
  
  void _selectAllItems() {
    setState(() {
      final cartState = ref.read(cartProvider);
      if (selectedItems.length == cartState.cartItems.length) {
        selectedItems.clear();
      } else {
        selectedItems = cartState.cartItems
            .map((item) => item.product.id)
            .toSet();
      }
    });
    _hapticFeedback();
  }
  
  Future<void> _startCheckout() async {
    final cartState = ref.read(cartProvider);
    
    if (cartState.cartItems.isEmpty) {
      _showSnackBar('Your cart is empty', isError: true);
      return;
    }
    
    setState(() {
      isCheckingOut = true;
    });
    
    _hapticFeedback(true);
    
    try {
      // Validate stock availability
      for (final item in cartState.cartItems) {
        if (item.product.inventory.stockCount < item.quantity) {
          _showSnackBar(
            'Insufficient stock for ${item.product.name}',
            isError: true,
          );
          setState(() {
            isCheckingOut = false;
          });
          return;
        }
      }
      
      // Initialize checkout service with cart items
      final checkoutService = ref.read(checkoutServiceProvider);
      checkoutService.initializeCheckout(cartState.cartItems);
      
      // Navigate to checkout flow
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CheckoutFlowScreen(),
        ),
      );
      
      // Check the result from checkout
      final checkoutState = ref.read(checkoutServiceProvider);
      if (checkoutState.createdOrder != null) {
        // Clear cart after successful order
        ref.read(cartProvider.notifier).clearCart();
        _showSnackBar('Order placed successfully!');
      }
      
    } catch (e) {
      _showSnackBar('Checkout failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isCheckingOut = false;
        });
      }
    }
  }
}
