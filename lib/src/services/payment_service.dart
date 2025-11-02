/// Payment Service
/// 
/// Service for handling payment processing and transaction management.
/// Integrates with payment providers for secure checkout and order processing.
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'api_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

class PaymentService {
  final ApiService _apiService = ApiService();
  late Razorpay _razorpay;
  PaymentCallback? _paymentCallback;

  // Payment configuration
  static const String _merchantKey = 'your_razorpay_merchant_key'; // Replace with your key
  static const String _applicationName = 'Digital Twin Fashion';
  static const String _applicationDescription = 'Premium Digital Fashion Experience';

  /// Initialize Razorpay payment gateway
  void initializeRazorpay({PaymentCallback? callback}) {
    _paymentCallback = callback;
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Dispose Razorpay instance
  void dispose() {
    _razorpay.clear();
  }

  /// Handle successful payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _paymentCallback?.onPaymentSuccess(response);
    _notifyServerOfPayment(response, PaymentStatus.succeeded);
  }

  /// Handle failed payment
  void _handlePaymentError(PaymentFailureResponse response) {
    _paymentCallback?.onPaymentError(response);
    _notifyServerOfPaymentFailure(response, PaymentStatus.failed);
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    _paymentCallback?.onExternalWallet(response);
  }

  /// Create Razorpay order
  Future<ApiResponse<RazorpayOrder>> createRazorpayOrder({
    required double amount,
    required String currency,
    required String receipt,
    required List<CartItem> items,
    String? discountCode,
    String? customerId,
  }) async {
    try {
      // Calculate final amount with discounts
      final double discountAmount = _calculateDiscount(amount, discountCode);
      final double finalAmount = amount - discountAmount;

      return _apiService.post<RazorpayOrder>(
        '/payments/razorpay/create-order',
        {
          'amount': (finalAmount * 100).toInt(), // Amount in paise
          'currency': currency,
          'receipt': receipt,
          'notes': {
            'items': items.map((item) => '${item.product.name} x${item.quantity}').join(', '),
            'customer_id': customerId ?? '',
            'discount_code': discountCode ?? '',
            'original_amount': amount.toString(),
            'discount_amount': discountAmount.toString(),
          },
        },
        (json) => RazorpayOrder.fromJson(json),
      );
    } catch (e) {
      return ApiResponse.error('Failed to create Razorpay order: $e');
    }
  }

  /// Open Razorpay checkout with custom options
  Future<bool> openRazorpayCheckout({
    required double amount,
    required String currency,
    required String description,
    required String customerName,
    required String customerEmail,
    required String customerContact,
    String? externalReference,
    List<String>? preferredMethods,
    Map<String, dynamic>? customOptions,
  }) async {
    try {
      // Validate input parameters
      if (amount <= 0) {
        throw Exception('Invalid amount: $amount');
      }

      final options = {
        'key': _merchantKey,
        'amount': (amount * 100).toInt(), // Amount in paise
        'name': _applicationName,
        'description': description,
        'retry': {
          'enabled': true,
          'max_count': 3,
        },
        'send_sms_hash': true,
        'allow_rotation': true,
        'prefill': {
          'contact': customerContact,
          'email': customerEmail,
          'name': customerName,
        },
        'external': {
          'wallets': preferredMethods ?? ['paytm', 'googlepay'],
        },
        'theme': _getPaymentTheme(),
        'hide_topbar': false,
        'order_id': externalReference,
      };

      // Add custom options if provided
      if (customOptions != null) {
        options.addAll(customOptions);
      }

      _razorpay.open(options);
      return true;
    } catch (e) {
      print('Error opening Razorpay: $e');
      return false;
    }
  }

  /// Get payment theme customization
  Map<String, String> _getPaymentTheme() {
    return {
      'color': '#4F46E5', // Primary app color
      'back_colour': '#F3F4F6', // Light gray background
      'primary_font_colour': '#111827', // Dark text
      'secondary_font_colour': '#6B7280', // Gray text
      'theme_bg_colour': '#FFFFFF', // White background
      'button_background_color': '#4F46E5', // Primary button color
      'button_text_color': '#FFFFFF', // White button text
    };
  }

  /// Apply discount coupon
  double _calculateDiscount(double originalAmount, String? discountCode) {
    if (discountCode == null || discountCode.isEmpty) return 0.0;

    // Simple discount logic - in production, fetch from server
    switch (discountCode.toUpperCase()) {
      case 'WELCOME10':
        return originalAmount * 0.10;
      case 'SAVE20':
        return originalAmount * 0.20;
      case 'NEWUSER':
        return originalAmount * 0.15;
      default:
        return 0.0;
    }
  }

  /// Notify server of successful payment
  Future<void> _notifyServerOfPayment(PaymentSuccessResponse response, PaymentStatus status) async {
    try {
      await _apiService.post('/payments/razorpay/verify', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });
    } catch (e) {
      print('Failed to verify payment with server: $e');
    }
  }

  /// Notify server of failed payment
  Future<void> _notifyServerOfPaymentFailure(PaymentFailureResponse response, PaymentStatus status) async {
    try {
      await _apiService.post('/payments/razorpay/failure', {
        'code': response.code,
        'message': response.message,
      });
    } catch (e) {
      print('Failed to notify server of payment failure: $e');
    }
  }

  /// Create a payment intent for processing a payment
  /// Returns client secret for client-side payment confirmation
  Future<ApiResponse<PaymentIntent>> createPaymentIntent(
    double amount,
    String currency,
    String orderId,
  ) async {
    return _apiService.post<PaymentIntent>(
      '/payments/create-intent',
      {
        'amount': (amount * 100).toInt(), // Convert to cents
        'currency': currency,
        'orderId': orderId,
      },
      (json) => PaymentIntent.fromJson(json),
    );
  }

  /// Confirm a payment using a payment intent
  Future<ApiResponse<PaymentResult>> confirmPayment(String paymentIntentId) async {
    return _apiService.post<PaymentResult>(
      '/payments/confirm',
      {'paymentIntentId': paymentIntentId},
      (json) => PaymentResult.fromJson(json),
    );
  }

  /// Process a payment with saved payment method
  Future<ApiResponse<PaymentResult>> processPaymentWithSavedMethod(
    String paymentMethodId,
    double amount,
    String currency,
    String orderId,
  ) async {
    return _apiService.post<PaymentResult>(
      '/payments/process',
      {
        'paymentMethodId': paymentMethodId,
        'amount': (amount * 100).toInt(),
        'currency': currency,
        'orderId': orderId,
      },
      (json) => PaymentResult.fromJson(json),
    );
  }

  /// Add a new payment method for the user
  Future<ApiResponse<String>> addPaymentMethod(
    String userId,
    Map<String, dynamic> paymentMethodData,
  ) async {
    return _apiService.post<String>(
      '/payments/add-method',
      {
        'userId': userId,
        'paymentMethod': paymentMethodData,
      },
      (json) => json['paymentMethodId'] as String,
    );
  }

  /// Get user's saved payment methods
  Future<ApiResponse<List<PaymentMethod>>> getPaymentMethods(String userId) async {
    return _apiService.get<List<PaymentMethod>>(
      '/payments/methods/$userId',
      (json) {
        final methodsJson = json['paymentMethods'] as List<dynamic>? ?? [];
        return methodsJson
            .map((methodJson) => 
                PaymentMethod.fromJson(methodJson as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Delete a saved payment method
  Future<ApiResponse<bool>> deletePaymentMethod(String paymentMethodId) async {
    return _apiService.delete<bool>(
      '/payments/methods/$paymentMethodId',
      (json) => json['success'] as bool? ?? false,
    );
  }

  /// Get payment history for a user
  Future<ApiResponse<List<PaymentRecord>>> getPaymentHistory(String userId) async {
    return _apiService.get<List<PaymentRecord>>(
      '/payments/history/$userId',
      (json) {
        final paymentsJson = json['payments'] as List<dynamic>? ?? [];
        return paymentsJson
            .map((paymentJson) => 
                PaymentRecord.fromJson(paymentJson as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Create order after successful payment
  Future<ApiResponse<Order>> createOrderAfterPayment({
    required String userId,
    required List<CartItem> items,
    required double totalAmount,
    required String paymentId,
    required String shippingAddress,
    String? paymentMethod,
  }) async {
    return _apiService.post<Order>(
      '/orders/create-after-payment',
      {
        'userId': userId,
        'items': items.map((item) => {
          'productId': item.product.id,
          'quantity': item.quantity,
          'price': item.product.price,
        }).toList(),
        'totalAmount': totalAmount,
        'paymentId': paymentId,
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod ?? 'razorpay',
        'status': 'confirmed',
      },
      (json) => Order.fromJson(json),
    );
  }

  /// Get order status
  Future<ApiResponse<OrderStatus>> getOrderStatus(String orderId) async {
    return _apiService.get<OrderStatus>(
      '/orders/status/$orderId',
      (json) => OrderStatus.fromString(json['status'] as String? ?? 'pending'),
    );
  }

  /// Cancel order
  Future<ApiResponse<bool>> cancelOrder(String orderId, String reason) async {
    return _apiService.post<bool>(
      '/orders/cancel/$orderId',
      {'reason': reason},
      (json) => json['success'] as bool? ?? false,
    );
  }
}

/// Payment intent data structure
class PaymentIntent {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String clientSecret;

  PaymentIntent({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.clientSecret,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? '',
      clientSecret: json['clientSecret'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'clientSecret': clientSecret,
    };
  }
}

/// Payment result structure
class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;
  final PaymentStatus status;

  PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
    required this.status,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> json) {
    return PaymentResult(
      success: json['success'] as bool? ?? false,
      transactionId: json['transactionId'] as String?,
      errorMessage: json['errorMessage'] as String?,
      status: PaymentStatus.fromString(json['status'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'transactionId': transactionId,
      'errorMessage': errorMessage,
      'status': status.toString().split('.').last,
    };
  }
}

/// Payment method structure
class PaymentMethod {
  final String id;
  final String type;
  final String last4;
  final String brand;
  final int expMonth;
  final int expYear;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expMonth,
    required this.expYear,
    required this.isDefault,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      last4: json['last4'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      expMonth: json['expMonth'] as int? ?? 0,
      expYear: json['expYear'] as int? ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'last4': last4,
      'brand': brand,
      'expMonth': expMonth,
      'expYear': expYear,
      'isDefault': isDefault,
    };
  }
}

/// Payment record for history
class PaymentRecord {
  final String id;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? description;

  PaymentRecord({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.description,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      status: PaymentStatus.fromString(json['status'] as String? ?? ''),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }
}

enum PaymentStatus {
  pending,
  succeeded,
  failed,
  cancelled,
  refunded,
  processing;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'processing':
        return PaymentStatus.processing;
      case 'succeeded':
        return PaymentStatus.succeeded;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.succeeded:
        return 'Success';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
}

/// Razorpay Order model
class RazorpayOrder {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String receipt;

  RazorpayOrder({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.receipt,
  });

  factory RazorpayOrder.fromJson(Map<String, dynamic> json) {
    return RazorpayOrder(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: json['status'] as String? ?? '',
      receipt: json['receipt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'currency': currency,
      'status': status,
      'receipt': receipt,
    };
  }
}

/// Payment callback interface
abstract class PaymentCallback {
  void onPaymentSuccess(PaymentSuccessResponse response);
  void onPaymentError(PaymentFailureResponse response);
  void onExternalWallet(ExternalWalletResponse response);
}

/// Error handling enum
enum PaymentErrorType {
  networkError,
  serverError,
  timeout,
  userCancelled,
  insufficientFunds,
  invalidCard,
  declinedPayment,
  unknown;

  static PaymentErrorType fromRazorpayCode(int code) {
    switch (code) {
      case 0:
        return PaymentErrorType.networkError;
      case 1:
        return PaymentErrorType.serverError;
      case 2:
        return PaymentErrorType.timeout;
      case 3:
        return PaymentErrorType.userCancelled;
      default:
        return PaymentErrorType.unknown;
    }
  }

  String get userMessage {
    switch (this) {
      case PaymentErrorType.networkError:
        return 'Please check your internet connection and try again.';
      case PaymentErrorType.serverError:
        return 'Server error occurred. Please try again later.';
      case PaymentErrorType.timeout:
        return 'Payment timed out. Please try again.';
      case PaymentErrorType.userCancelled:
        return 'Payment was cancelled by you.';
      case PaymentErrorType.insufficientFunds:
        return 'Insufficient funds. Please use another payment method.';
      case PaymentErrorType.invalidCard:
        return 'Invalid card details. Please check and try again.';
      case PaymentErrorType.declinedPayment:
        return 'Payment was declined. Please try another method.';
      case PaymentErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
