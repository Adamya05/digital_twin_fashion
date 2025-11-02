/// Checkout Screen
/// 
/// Comprehensive checkout flow for the shopping cart:
/// - Order review with itemized breakdown
/// - Address selection and management
/// - Payment method selection
/// - Order summary with final pricing
/// - Indian market specific features (GST, delivery estimates)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../../themes/app_theme.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> 
    with TickerProviderStateMixin {
  
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  
  int _selectedAddressIndex = 0;
  int _selectedPaymentMethod = 0;
  String? appliedCoupon;
  double discountAmount = 0.0;
  bool isProcessingOrder = false;
  
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );
  
  // Sample addresses
  final List<Map<String, String>> _addresses = [
    {
      'name': 'John Doe',
      'phone': '+91 98765 43210',
      'address': '123, MG Road, Bangalore, Karnataka 560001',
      'type': 'Home',
    },
    {
      'name': 'John Doe',
      'phone': '+91 98765 43210',
      'address': '456, Brigade Road, Bangalore, Karnataka 560025',
      'type': 'Office',
    },
  ];
  
  // Sample payment methods
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'type': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Visa, Mastercard, RuPay',
    },
    {
      'type': 'upi',
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'description': 'Google Pay, PhonePe, Paytm',
    },
    {
      'type': 'netbanking',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'description': 'All major banks supported',
    },
    {
      'type': 'cod',
      'name': 'Cash on Delivery',
      'icon': Icons.money,
      'description': 'Pay when you receive',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserAddresses();
  }
  
  void _loadUserAddresses() {
    // TODO: Load user addresses from API or local storage
  }
  
  void _hapticFeedback([bool heavy = false]) {
    HapticFeedback.lightImpact();
    if (heavy) {
      HapticFeedback.heavyImpact();
    }
  }
  
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
  
  double _calculateShipping(double subtotal) {
    return subtotal >= 2000 ? 0.0 : 99.0;
  }
  
  double _calculateGST(double amount) {
    return amount * 0.18;
  }
  
  void _applyCoupon(String code) {
    setState(() {
      appliedCoupon = code.toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: cartState.isLoading
        ? const LoadingIndicator(message: 'Preparing checkout...')
        : _buildCheckoutContent(cartState),
    );
  }
  
  Widget _buildCheckoutContent(CartState cartState) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          slivers: [
            // Order Items Section
            _buildOrderItemsSection(cartState),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Delivery Address Section
            _buildDeliveryAddressSection(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Payment Method Section
            _buildPaymentMethodSection(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Coupon Section
            _buildCouponSection(),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Order Summary Section
            _buildOrderSummary(cartState),
            
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ],
    );
  }
  
  Widget _buildOrderItemsSection(CartState cartState) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag),
              const SizedBox(width: 8),
              Text(
                'Order Items (${cartState.itemCount})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ...cartState.cartItems.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.primaryImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Quantity: ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                
                Text(
                  _currencyFormatter.format(item.product.currentPrice * item.quantity),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildDeliveryAddressSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => _showAddAddressDialog(),
                child: const Text('Add New'),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ..._addresses.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAddressIndex = index;
                });
                _hapticFeedback();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedAddressIndex == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio(
                      value: index,
                      groupValue: _selectedAddressIndex,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddressIndex = value!;
                        });
                        _hapticFeedback();
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                address['type']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                address['name']!,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(address['phone']!),
                          const SizedBox(height: 4),
                          Text(
                            address['address']!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMethodSection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payment),
              const SizedBox(width: 8),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          ..._paymentMethods.asMap().entries.map((entry) {
            final index = entry.key;
            final method = entry.value;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPaymentMethod = index;
                });
                _hapticFeedback();
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPaymentMethod == index
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Radio(
                      value: index,
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value!;
                        });
                        _hapticFeedback();
                      },
                    ),
                    Icon(
                      method['icon'],
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            method['name'],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            method['description'],
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
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
          
          _buildPriceRow('Subtotal', subtotal),
          if (discount > 0) _buildPriceRow('Discount', -discount, isDiscount: true),
          _buildPriceRow('Shipping', shippingCost, isFree: shippingCost == 0),
          _buildPriceRow('GST (18%)', gst),
          
          const Divider(height: 24),
          
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
          
          const SizedBox(height: 20),
          
          // Place Order Button
          AppButton(
            onPressed: isProcessingOrder ? null : _placeOrder,
            label: isProcessingOrder 
              ? 'Processing Order...' 
              : 'Place Order (${_currencyFormatter.format(total)})',
            size: ButtonSize.large,
            isLoading: isProcessingOrder,
            icon: Icons.shopping_cart_checkout,
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
  Future<void> _placeOrder() async {
    setState(() {
      isProcessingOrder = true;
    });
    
    _hapticFeedback(true);
    
    try {
      final cartState = ref.read(cartProvider);
      
      // Validate stock
      if (!ref.read(cartProvider.notifier).validateStockAvailability()) {
        _showSnackBar('Some items are out of stock', isError: true);
        setState(() {
          isProcessingOrder = false;
        });
        return;
      }
      
      // Create order
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'current_user_id', // TODO: Get from auth
        items: cartState.cartItems
            .map((item) => OrderItem(
                  id: item.id,
                  product: item.product,
                  quantity: item.quantity,
                  price: item.product.currentPrice,
                ))
            .toList(),
        totalAmount: _calculateFinalTotal(cartState.totalPrice),
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        shippingAddress: _addresses[_selectedAddressIndex]['address'],
        paymentMethod: _paymentMethods[_selectedPaymentMethod]['type'],
      );
      
      // Simulate order processing
      await Future.delayed(const Duration(seconds: 3));
      
      // Clear cart
      ref.read(cartProvider.notifier).clearCart();
      
      // Show success and navigate
      _showOrderSuccessDialog(order);
      
    } catch (e) {
      _showSnackBar('Order failed: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        isProcessingOrder = false;
      });
    }
  }
  
  double _calculateFinalTotal(double subtotal) {
    final discount = subtotal * discountAmount;
    final shippingCost = _calculateShipping(subtotal);
    final taxableAmount = subtotal - discount;
    final gst = _calculateGST(taxableAmount);
    return taxableAmount + shippingCost + gst;
  }
  
  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Add address logic
              Navigator.of(context).pop();
              _showSnackBar('Address added successfully!');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
  
  void _showOrderSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          size: 64,
          color: Colors.green.shade600,
        ),
        title: const Text('Order Placed Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Order ID: ${order.id}'),
            const SizedBox(height: 8),
            Text(
              'Thank you for your purchase! Your order will be delivered in 3-5 business days.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to cart or home
            },
            child: const Text('Continue Shopping'),
          ),
        ],
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout Help'),
        content: const Text(
          'Having trouble with checkout? Contact our support team at support@fittwin.com',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}