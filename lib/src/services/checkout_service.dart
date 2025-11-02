/// Checkout Service
/// 
/// Complete checkout flow management including order preparation, payment processing,
/// and success/failure handling. Integrates with Razorpay for payment processing.
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'payment_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/swipe_history_model.dart';

/// Checkout step states
enum CheckoutStep {
  review,
  address,
  paymentMethod,
  reviewOrder,
  processingPayment,
  success,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case CheckoutStep.review:
        return 'Review Cart';
      case CheckoutStep.address:
        return 'Shipping Address';
      case CheckoutStep.paymentMethod:
        return 'Payment Method';
      case CheckoutStep.reviewOrder:
        return 'Review Order';
      case CheckoutStep.processingPayment:
        return 'Processing Payment';
      case CheckoutStep.success:
        return 'Payment Successful';
      case CheckoutStep.failed:
        return 'Payment Failed';
      case CheckoutStep.cancelled:
        return 'Payment Cancelled';
    }
  }
}

/// Checkout configuration
class CheckoutConfig {
  final String merchantKey;
  final String applicationName;
  final String applicationDescription;
  final bool enableRetry;
  final int maxRetries;
  final Duration paymentTimeout;
  final List<String> preferredWallets;
  final Map<String, String> theme;

  CheckoutConfig({
    this.merchantKey = 'your_razorpay_merchant_key',
    this.applicationName = 'Digital Twin Fashion',
    this.applicationDescription = 'Premium Digital Fashion Experience',
    this.enableRetry = true,
    this.maxRetries = 3,
    this.paymentTimeout = const Duration(minutes: 10),
    this.preferredWallets = const ['paytm', 'googlepay', 'phonepe'],
    this.theme = const {
      'color': '#4F46E5',
      'back_colour': '#F3F4F6',
      'primary_font_colour': '#111827',
      'secondary_font_colour': '#6B7280',
      'theme_bg_colour': '#FFFFFF',
      'button_background_color': '#4F46E5',
      'button_text_color': '#FFFFFF',
    },
  });
}

/// Shipping address model
class ShippingAddress {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final bool isDefault;

  ShippingAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.isDefault = false,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zipCode: json['zipCode'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'isDefault': isDefault,
    };
  }

  String get fullAddress {
    return '$street, $city, $state $zipCode, $country';
  }

  String get contactInfo {
    return '$name\n$phone\n$email';
  }
}

/// Discount/coupon information
class DiscountInfo {
  final String? code;
  final double amount;
  final String type; // 'percentage' or 'fixed'
  final String description;

  DiscountInfo({
    this.code,
    required this.amount,
    required this.type,
    required this.description,
  });

  double applyDiscount(double originalAmount) {
    if (code == null || code!.isEmpty) return originalAmount;
    
    if (type == 'percentage') {
      return originalAmount * (1 - amount / 100);
    } else {
      return (originalAmount - amount).clamp(0, double.infinity);
    }
  }
}

/// Checkout state management
class CheckoutState {
  final CheckoutStep step;
  final List<CartItem> items;
  final ShippingAddress? selectedAddress;
  final DiscountInfo? appliedDiscount;
  final bool isProcessing;
  final String? error;
  final Order? createdOrder;
  final PaymentStatus paymentStatus;
  final DateTime? startTime;

  const CheckoutState({
    this.step = CheckoutStep.review,
    this.items = const [],
    this.selectedAddress,
    this.appliedDiscount,
    this.isProcessing = false,
    this.error,
    this.createdOrder,
    this.paymentStatus = PaymentStatus.pending,
    this.startTime,
  });

  /// Calculate subtotal
  double get subtotal {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  /// Calculate discount amount
  double get discountAmount {
    if (appliedDiscount == null) return 0.0;
    if (appliedDiscount!.type == 'percentage') {
      return subtotal * (appliedDiscount!.amount / 100);
    } else {
      return appliedDiscount!.amount;
    }
  }

  /// Calculate final amount
  double get totalAmount {
    return (subtotal - discountAmount).clamp(0, double.infinity);
  }

  /// Check if checkout can proceed
  bool get canProceed {
    switch (step) {
      case CheckoutStep.review:
        return items.isNotEmpty;
      case CheckoutStep.address:
        return selectedAddress != null;
      case CheckoutStep.paymentMethod:
        return true; // Always have Razorpay option
      case CheckoutStep.reviewOrder:
        return selectedAddress != null;
      default:
        return false;
    }
  }

  CheckoutState copyWith({
    CheckoutStep? step,
    List<CartItem>? items,
    ShippingAddress? selectedAddress,
    DiscountInfo? appliedDiscount,
    bool? isProcessing,
    String? error,
    Order? createdOrder,
    PaymentStatus? paymentStatus,
    DateTime? startTime,
  }) {
    return CheckoutState(
      step: step ?? this.step,
      items: items ?? this.items,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      appliedDiscount: appliedDiscount ?? this.appliedDiscount,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      createdOrder: createdOrder ?? this.createdOrder,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      startTime: startTime ?? this.startTime,
    );
  }

  CheckoutState clearError() {
    return copyWith(error: null);
  }

  CheckoutState setError(String error) {
    return copyWith(error: error);
  }

  CheckoutState startProcessing() {
    return copyWith(
      isProcessing: true,
      error: null,
      startTime: DateTime.now(),
    );
  }

  CheckoutState stopProcessing() {
    return copyWith(isProcessing: false);
  }
}

/// Complete checkout service
class CheckoutService with ChangeNotifier {
  final PaymentService _paymentService;
  late CheckoutConfig _config;
  CheckoutState _state = const CheckoutState();
  
  // Timer for payment timeout
  Timer? _paymentTimeoutTimer;

  CheckoutService(this._paymentService) {
    _config = CheckoutConfig();
    _paymentService.initializeRazorpay(callback: this);
  }

  // Getters
  CheckoutState get state => _state;
  CheckoutStep get currentStep => _state.step;
  List<CartItem> get items => _state.items;
  ShippingAddress? get selectedAddress => _state.selectedAddress;
  DiscountInfo? get appliedDiscount => _state.appliedDiscount;
  double get subtotal => _state.subtotal;
  double get discountAmount => _state.discountAmount;
  double get totalAmount => _state.totalAmount;
  bool get isProcessing => _state.isProcessing;
  Order? get createdOrder => _state.createdOrder;
  PaymentStatus get paymentStatus => _state.paymentStatus;
  bool get canProceed => _state.canProceed;

  /// Initialize checkout with cart items
  void initializeCheckout(List<CartItem> items) {
    _state = _state.copyWith(items: items);
    notifyListeners();
  }

  /// Apply discount coupon
  bool applyDiscount(String couponCode) {
    if (couponCode.isEmpty) return false;

    // Validate coupon code
    final validatedDiscount = _validateCouponCode(couponCode);
    if (validatedDiscount != null) {
      _state = _state.copyWith(appliedDiscount: validatedDiscount);
      notifyListeners();
      return true;
    }
    
    _state = _state.copyWith(error: 'Invalid coupon code');
    notifyListeners();
    return false;
  }

  /// Validate coupon code
  DiscountInfo? _validateCouponCode(String code) {
    switch (code.toUpperCase()) {
      case 'WELCOME10':
        return DiscountInfo(
          code: code,
          amount: 10,
          type: 'percentage',
          description: '10% off for new customers',
        );
      case 'SAVE20':
        return DiscountInfo(
          code: code,
          amount: 20,
          type: 'percentage',
          description: 'Save 20% on your order',
        );
      case 'NEWUSER':
        return DiscountInfo(
          code: code,
          amount: 15,
          type: 'percentage',
          description: '15% off for new users',
        );
      case 'FREESHIP':
        return DiscountInfo(
          code: code,
          amount: 50,
          type: 'fixed',
          description: 'Free shipping',
        );
      default:
        return null;
    }
  }

  /// Remove applied discount
  void removeDiscount() {
    _state = _state.copyWith(appliedDiscount: null);
    notifyListeners();
  }

  /// Update shipping address
  void updateShippingAddress(ShippingAddress address) {
    _state = _state.copyWith(
      selectedAddress: address,
      error: null,
    );
    notifyListeners();
  }

  /// Navigate to next step
  bool nextStep() {
    switch (_state.step) {
      case CheckoutStep.review:
        _state = _state.copyWith(step: CheckoutStep.address);
        break;
      case CheckoutStep.address:
        if (_state.selectedAddress == null) {
          _state = _state.copyWith(error: 'Please select a shipping address');
          return false;
        }
        _state = _state.copyWith(step: CheckoutStep.paymentMethod);
        break;
      case CheckoutStep.paymentMethod:
        _state = _state.copyWith(step: CheckoutStep.reviewOrder);
        break;
      case CheckoutStep.reviewOrder:
        // Start payment process
        _startPaymentProcess();
        break;
      default:
        return false;
    }
    notifyListeners();
    return true;
  }

  /// Navigate to previous step
  void previousStep() {
    switch (_state.step) {
      case CheckoutStep.address:
        _state = _state.copyWith(step: CheckoutStep.review);
        break;
      case CheckoutStep.paymentMethod:
        _state = _state.copyWith(step: CheckoutStep.address);
        break;
      case CheckoutStep.reviewOrder:
        _state = _state.copyWith(step: CheckoutStep.paymentMethod);
        break;
      default:
        break;
    }
    notifyListeners();
  }

  /// Start payment process
  Future<void> _startPaymentProcess() async {
    if (_state.selectedAddress == null) {
      _state = _state.copyWith(error: 'Shipping address required');
      notifyListeners();
      return;
    }

    _state = _state.copyWith(step: CheckoutStep.processingPayment);
    notifyListeners();

    try {
      // Create Razorpay order
      final orderResponse = await _paymentService.createRazorpayOrder(
        amount: _state.totalAmount,
        currency: 'INR',
        receipt: 'order_${DateTime.now().millisecondsSinceEpoch}',
        items: _state.items,
        discountCode: _state.appliedDiscount?.code,
      );

      if (orderResponse.isError) {
        _handlePaymentError(orderResponse.error ?? 'Failed to create order');
        return;
      }

      final orderId = orderResponse.data?.id;
      if (orderId == null) {
        _handlePaymentError('Invalid order ID');
        return;
      }

      // Open Razorpay checkout
      await _openRazorpayCheckout(orderId);

    } catch (e) {
      _handlePaymentError('Payment initialization failed: $e');
    }
  }

  /// Open Razorpay checkout
  Future<void> _openRazorpayCheckout(String orderId) async {
    try {
      _startPaymentTimeout();

      final success = await _paymentService.openRazorpayCheckout(
        amount: _state.totalAmount,
        currency: 'INR',
        description: 'Order payment for ${_state.items.length} items',
        customerName: _state.selectedAddress!.name,
        customerEmail: _state.selectedAddress!.email,
        customerContact: _state.selectedAddress!.phone,
        externalReference: orderId,
        preferredMethods: _config.preferredWallets,
        customOptions: {
          'theme': _config.theme,
          'view': 'form',
        },
      );

      if (!success) {
        _handlePaymentError('Failed to open payment gateway');
      }
    } catch (e) {
      _handlePaymentError('Payment gateway error: $e');
    }
  }

  /// Start payment timeout timer
  void _startPaymentTimeout() {
    _paymentTimeoutTimer?.cancel();
    _paymentTimeoutTimer = Timer(_config.paymentTimeout, () {
      _handlePaymentError('Payment timeout. Please try again.');
    });
  }

  /// Handle payment success
  void onPaymentSuccess(PaymentSuccessResponse response) {
    _paymentTimeoutTimer?.cancel();
    
    _state = _state.copyWith(
      step: CheckoutStep.success,
      paymentStatus: PaymentStatus.succeeded,
      isProcessing: false,
      error: null,
    );

    // Create order in database
    _createOrderAfterPayment(response);

    notifyListeners();
  }

  /// Handle payment failure
  void onPaymentError(PaymentFailureResponse response) {
    _paymentTimeoutTimer?.cancel();
    
    _state = _state.copyWith(
      step: CheckoutStep.failed,
      paymentStatus: PaymentStatus.failed,
      isProcessing: false,
      error: response.message ?? 'Payment failed',
    );

    notifyListeners();
  }

  /// Handle external wallet
  void onExternalWallet(ExternalWalletResponse response) {
    print('External wallet selected: ${response.walletName}');
    // Handle external wallet selection if needed
  }

  /// Create order after successful payment
  Future<void> _createOrderAfterPayment(PaymentSuccessResponse response) async {
    try {
      final orderItems = _state.items.map((item) => OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        productImage: item.product.imageUrl,
        price: item.product.price,
        quantity: item.quantity,
      )).toList();

      final order = Order(
        id: 'order_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_123', // Replace with actual user ID
        items: orderItems,
        totalAmount: _state.subtotal,
        status: OrderStatus.paymentConfirmed, // This is a new status
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customer: CustomerInfo(
          name: _state.selectedAddress!.name,
          email: _state.selectedAddress!.email,
          phone: _state.selectedAddress!.phone,
        ),
        payment: PaymentDetails(
          method: 'razorpay',
          transactionId: response.paymentId,
          status: PaymentStatus.succeeded,
          amount: _state.totalAmount,
        ),
        shipping: ShippingInfo(
          address: _state.selectedAddress!.fullAddress,
          method: 'standard',
          estimatedDays: 5,
        ),
        metadata: OrderMetadata(
          couponCode: _state.appliedDiscount?.code,
          notes: 'Digital fashion order',
        ),
      );

      _state = _state.copyWith(createdOrder: order);
      notifyListeners();

      // Save order to server
      await _paymentService.createOrderAfterPayment(
        userId: 'user_123', // Replace with actual user ID
        items: _state.items,
        totalAmount: _state.totalAmount,
        paymentId: response.paymentId,
        shippingAddress: _state.selectedAddress!.fullAddress,
        paymentMethod: 'razorpay',
      );

    } catch (e) {
      print('Failed to create order: $e');
      _handlePaymentError('Order creation failed. Please contact support.');
    }
  }

  /// Handle payment error
  void _handlePaymentError(String error) {
    _paymentTimeoutTimer?.cancel();
    
    _state = _state.copyWith(
      step: CheckoutStep.failed,
      paymentStatus: PaymentStatus.failed,
      isProcessing: false,
      error: error,
    );

    notifyListeners();
  }

  /// Retry payment
  void retryPayment() {
    if (_state.createdOrder != null) {
      _startPaymentProcess();
    }
  }

  /// Cancel checkout
  void cancelCheckout() {
    _paymentTimeoutTimer?.cancel();
    _state = const CheckoutState();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  /// Get order tracking information
  Future<Map<String, dynamic>> getOrderTracking(String orderId) async {
    try {
      final statusResponse = await _paymentService.getOrderStatus(orderId);
      if (statusResponse.isError) {
        throw Exception(statusResponse.error ?? 'Failed to get order status');
      }

      return {
        'orderId': orderId,
        'status': statusResponse.data?.toString() ?? 'pending',
        'lastUpdated': DateTime.now().toIso8601String(),
        'estimatedDelivery': _state.createdOrder?.estimatedDeliveryDate?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get tracking info: $e');
    }
  }

  /// Get order details
  Order? getOrderDetails() {
    return _state.createdOrder;
  }

  /// Check if terms are accepted (for future implementation)
  bool get areTermsAccepted => true; // Placeholder for terms acceptance

  /// Get payment recommendations based on failure
  List<String> getPaymentRecommendations() {
    final List<String> recommendations = [];

    switch (_state.paymentStatus) {
      case PaymentStatus.failed:
        recommendations.addAll([
          'Try a different payment method',
          'Check your card details',
          'Verify sufficient balance',
          'Try again in a few minutes',
        ]);
        break;
      case PaymentStatus.cancelled:
        recommendations.addAll([
          'Complete the payment process',
          'Choose a preferred payment method',
        ]);
        break;
      default:
        recommendations.add('Use a different payment method');
    }

    return recommendations;
  }

  @override
  void dispose() {
    _paymentTimeoutTimer?.cancel();
    _paymentService.dispose();
    super.dispose();
  }
}
