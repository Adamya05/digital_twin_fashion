import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive Razorpay Payment Service
/// Provides secure, compliant payment processing with extensive method support
class PaymentService {
  static PaymentService? _instance;
  static PaymentService get instance => _instance ??= PaymentService._();
  
  PaymentService._();

  late Razorpay _razorpay;
  Timer? _paymentTimeout;
  StreamController<PaymentEvent>? _paymentController;
  
  // Configuration
  PaymentConfig? _config;
  bool _isInitialized = false;
  
  // Payment tracking
  String? _currentPaymentId;
  PaymentRetryConfig? _retryConfig;
  
  // Security & Compliance
  static const int _maxRetryAttempts = 3;
  static const Duration _defaultTimeout = Duration(minutes: 15);
  static const String _pciComplianceVersion = "1.0";

  /// Initialize Razorpay with configuration
  Future<void> initialize(PaymentConfig config) async {
    if (_isInitialized) return;
    
    _config = config;
    _razorpay = Razorpay();
    _paymentController = StreamController<PaymentEvent>.broadcast();
    
    // Set up event handlers
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    _isInitialized = true;
    _log('PaymentService initialized');
  }

  /// Process payment with comprehensive error handling and security measures
  Future<PaymentResult> processPayment({
    required String orderId,
    required String amount,
    required String currency,
    required String description,
    required CustomerInfo customer,
    PaymentOptions options = const PaymentOptions(),
    String? notes,
    bool enableRetry = true,
  }) async {
    if (!_isInitialized) {
      throw PaymentException('PaymentService not initialized');
    }

    try {
      _log('Starting payment process for order: $orderId');
      
      // Validate payment data
      _validatePaymentData(amount, currency, customer);
      
      // Start timeout timer
      _startPaymentTimeout();
      
      // Prepare payment options
      var paymentData = await _preparePaymentData(
        orderId: orderId,
        amount: amount,
        currency: currency,
        description: description,
        customer: customer,
        options: options,
        notes: notes,
      );
      
      // Check payment method availability
      final availabilityCheck = await _checkPaymentMethodAvailability(paymentData);
      if (!availabilityCheck.isAvailable) {
        _cancelTimeout();
        return PaymentResult.failure(
          reason: availabilityCheck.reason,
          errorCode: PaymentErrorCode.METHOD_UNAVAILABLE,
        );
      }
      
      // Open Razorpay payment interface
      _razorpay.open(paymentData);
      
      // Wait for payment result
      final result = await _waitForPaymentResult();
      
      _cancelTimeout();
      
      // Log payment attempt
      await _logPaymentAttempt(paymentData, result);
      
      return result;
      
    } catch (e) {
      _cancelTimeout();
      _log('Payment processing error: $e');
      return PaymentResult.failure(
        reason: e.toString(),
        errorCode: PaymentErrorCode.PROCESSING_ERROR,
      );
    }
  }

  /// Validate payment method availability before proceeding
  Future<PaymentMethodAvailability> checkPaymentMethodAvailability(
    String method,
    String? bankCode,
  ) async {
    try {
      // This would typically call Razorpay's API to check availability
      // For now, returning basic validation
      switch (method) {
        case 'upi':
          return PaymentMethodAvailability(
            isAvailable: true,
            supportedMethods: ['GPay', 'PhonePe', 'Paytm', 'BHIM'],
          );
        case 'card':
          return PaymentMethodAvailability(
            isAvailable: true,
            supportedMethods: ['Visa', 'Mastercard', 'RuPay', 'Amex'],
          );
        case 'netbanking':
          return PaymentMethodAvailability(
            isAvailable: true,
            bankCode: bankCode,
            supportedMethods: ['netbanking'],
          );
        case 'wallet':
          return PaymentMethodAvailability(
            isAvailable: true,
            supportedMethods: ['Paytm', 'Mobikwik', 'FreeCharge', 'AirtelMoney'],
          );
        default:
          return PaymentMethodAvailability(
            isAvailable: false,
            reason: 'Unsupported payment method',
          );
      }
    } catch (e) {
      return PaymentMethodAvailability(
        isAvailable: false,
        reason: 'Error checking availability: $e',
      );
    }
  }

  /// Process refund for failed or cancelled payments
  Future<RefundResult> processRefund({
    required String paymentId,
    required String amount,
    String? reason,
    int? speed = 1, // 1 = normal, 2 = expedited
  }) async {
    try {
      _log('Processing refund for payment: $paymentId');
      
      if (_config?.apiKey.isEmpty ?? true) {
        throw PaymentException('API key not configured for refunds');
      }
      
      // Call Razorpay refund API
      final refundData = {
        'payment_id': paymentId,
        'amount': (double.parse(amount) * 100).round(), // Convert to paise
        'speed': speed,
        if (reason != null) 'notes': {'reason': reason},
      };
      
      final response = await http.post(
        Uri.parse('${_config!.apiBaseUrl}/refunds'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${_config!.apiKey}:${_config!.secretKey}'))}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(refundData),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return RefundResult.success(
          refundId: responseData['id'],
          status: responseData['status'],
          amount: (responseData['amount'] / 100).toString(),
          speed: responseData['speed'],
        );
      } else {
        throw PaymentException('Refund failed: ${response.body}');
      }
    } catch (e) {
      _log('Refund processing error: $e');
      return RefundResult.failure(
        reason: e.toString(),
        refundId: paymentId,
      );
    }
  }

  /// Get payment analytics and tracking data
  Future<PaymentAnalytics> getPaymentAnalytics({
    required String fromDate,
    required String toDate,
    String? status,
    String? method,
  }) async {
    try {
      if (_config?.apiKey.isEmpty ?? true) {
        throw PaymentException('API key not configured for analytics');
      }
      
      final params = {
        'from': fromDate,
        'to': toDate,
        if (status != null) 'status': status,
        if (method != null) 'method': method,
      };
      
      final queryString = params.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      
      final response = await http.get(
        Uri.parse('${_config!.apiBaseUrl}/payments?$queryString'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${_config!.apiKey}:${_config!.secretKey}'))}',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return PaymentAnalytics.fromJson(responseData);
      } else {
        throw PaymentException('Analytics fetch failed: ${response.body}');
      }
    } catch (e) {
      _log('Analytics fetch error: $e');
      rethrow;
    }
  }

  /// Validate payment method and bank availability
  Future<bool> validatePaymentMethod({
    required String method,
    String? bankCode,
    String? walletProvider,
  }) async {
    try {
      final availability = await checkPaymentMethodAvailability(method, bankCode);
      return availability.isAvailable;
    } catch (e) {
      _log('Payment method validation error: $e');
      return false;
    }
  }

  /// Enable/disable specific payment methods
  Future<void> setPaymentMethodPreference(PaymentMethod method, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('payment_method_${method.name}', enabled);
  }

  /// Get user payment method preferences
  Future<Set<PaymentMethod>> getPaymentMethodPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final Set<PaymentMethod> enabledMethods = {};
    
    for (final method in PaymentMethod.values) {
      if (prefs.getBool('payment_method_${method.name}') ?? true) {
        enabledMethods.add(method);
      }
    }
    
    return enabledMethods;
  }

  /// Private helper methods
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _log('Payment success: ${response.paymentId}');
    _cancelTimeout();
    
    final event = PaymentEvent.success(
      paymentId: response.paymentId!,
      orderId: response.orderId!,
      signature: response.signature!,
    );
    
    _paymentController?.add(event);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _log('Payment failed: ${response.code} - ${response.message}');
    _cancelTimeout();
    
    final errorCode = _mapRazorpayErrorCode(response.code);
    final event = PaymentEvent.failure(
      errorCode: errorCode,
      message: response.message!,
    );
    
    _paymentController?.add(event);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _log('External wallet selected: ${response.walletName}');
  }

  PaymentErrorCode _mapRazorpayErrorCode(int code) {
    switch (code) {
      case 1:
        return PaymentErrorCode.USER_CANCELLED;
      case 2:
        return PaymentErrorCode.NETWORK_ERROR;
      case 3:
        return PaymentErrorCode.INVALID_OPTIONS;
      case 0:
        return PaymentErrorCode.UNKNOWN_ERROR;
      default:
        return PaymentErrorCode.UNKNOWN_ERROR;
    }
  }

  Future<Options> _preparePaymentData({
    required String orderId,
    required String amount,
    required String currency,
    required String description,
    required CustomerInfo customer,
    required PaymentOptions options,
    String? notes,
  }) async {
    final paymentData = <String, dynamic>{
      'key': _config!.apiKey,
      'amount': (double.parse(amount) * 100).round(), // Convert to paise
      'currency': currency,
      'name': _config!.merchantName,
      'description': description,
      'order_id': orderId,
      'customer': {
        'name': customer.name,
        'contact': customer.phone,
        'email': customer.email,
      },
      'notes': {
        if (notes != null) 'description': notes,
        'platform': Platform.operatingSystem,
        'app_version': _config!.appVersion,
        'pci_compliance': _pciComplianceVersion,
      },
      'theme': {
        'color': _config!.themeColor,
      },
      'method': _buildMethodConfiguration(options),
      'timeout': options.timeout.inSeconds,
      'retry': {
        'enabled': options.enableRetry,
        'max_count': _maxRetryAttempts,
      },
      'notify': {
        'sms': options.enableSMSNotifications,
        'email': options.enableEmailNotifications,
      },
    };
    
    // Add redirect URLs if configured
    if (_config!.redirectUrl != null) {
      paymentData['redirect'] = true;
      paymentData['callback_url'] = _config!.redirectUrl;
    }
    
    // Add recurring payment support if needed
    if (options.isRecurring) {
      paymentData['recurring'] = true;
      paymentData['token'] = options.recurringToken;
    }
    
    return Options(paymentData);
  }

  Map<String, dynamic> _buildMethodConfiguration(PaymentOptions options) {
    final methods = <String, dynamic>{};
    
    if (options.enabledMethods.contains(PaymentMethod.upi)) {
      methods['upi'] = options.upiOptions;
    }
    
    if (options.enabledMethods.contains(PaymentMethod.card)) {
      methods['card'] = options.cardOptions;
    }
    
    if (options.enabledMethods.contains(PaymentMethod.netbanking)) {
      methods['netbanking'] = options.netbankingOptions;
    }
    
    if (options.enabledMethods.contains(PaymentMethod.wallet)) {
      methods['wallet'] = options.walletOptions;
    }
    
    if (options.enabledMethods.contains(PaymentMethod.emi)) {
      methods['emi'] = options.emiOptions;
    }
    
    if (options.enabledMethods.contains(PaymentMethod.bnpl)) {
      methods['paylater'] = options.bnplOptions;
    }
    
    return methods;
  }

  Future<PaymentResult> _waitForPaymentResult() async {
    final completer = Completer<PaymentResult>();
    
    final subscription = _paymentController!.stream.listen((event) {
      if (!completer.isCompleted) {
        if (event is PaymentEventSuccess) {
          completer.complete(PaymentResult.success(
            paymentId: event.paymentId,
            orderId: event.orderId,
            signature: event.signature,
          ));
        } else if (event is PaymentEventFailure) {
          completer.complete(PaymentResult.failure(
            reason: event.message,
            errorCode: event.errorCode,
          ));
        }
      }
    });
    
    // Set a timeout for waiting
    final timeout = Timer(_defaultTimeout, () {
      if (!completer.isCompleted) {
        completer.complete(PaymentResult.failure(
          reason: 'Payment timeout',
          errorCode: PaymentErrorCode.TIMEOUT,
        ));
      }
    });
    
    return completer.future.whenComplete(() {
      subscription.cancel();
      timeout.cancel();
    });
  }

  void _startPaymentTimeout() {
    _paymentTimeout?.cancel();
    _paymentTimeout = Timer(_defaultTimeout, () {
      _razorpay.clear();
      _paymentController?.add(PaymentEvent.failure(
        errorCode: PaymentErrorCode.TIMEOUT,
        message: 'Payment timeout',
      ));
    });
  }

  void _cancelTimeout() {
    _paymentTimeout?.cancel();
    _paymentTimeout = null;
  }

  void _validatePaymentData(String amount, String currency, CustomerInfo customer) {
    if (amount.isEmpty || double.tryParse(amount) == null) {
      throw PaymentException('Invalid amount');
    }
    
    if (double.parse(amount) <= 0) {
      throw PaymentException('Amount must be greater than zero');
    }
    
    if (customer.phone.isEmpty) {
      throw PaymentException('Customer phone number required');
    }
    
    if (customer.email.isEmpty) {
      throw PaymentException('Customer email required');
    }
    
    const supportedCurrencies = ['INR', 'USD', 'EUR', 'GBP'];
    if (!supportedCurrencies.contains(currency)) {
      throw PaymentException('Unsupported currency: $currency');
    }
  }

  Future<PaymentMethodAvailability> _checkPaymentMethodAvailability(
    Options paymentData,
  ) async {
    // This would typically check with Razorpay's API
    // For now, return basic availability
    return PaymentMethodAvailability(isAvailable: true);
  }

  Future<void> _logPaymentAttempt(Options paymentData, PaymentResult result) async {
    final logData = {
      'timestamp': DateTime.now().toIso8601String(),
      'payment_id': _currentPaymentId,
      'amount': paymentData.options['amount'],
      'currency': paymentData.options['currency'],
      'customer': paymentData.options['customer'],
      'result': result.toMap(),
    };
    
    // Store payment log (in production, send to analytics service)
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('payment_logs') ?? [];
    logs.insert(0, jsonEncode(logData));
    
    // Keep only last 100 logs
    if (logs.length > 100) {
      logs.removeRange(100, logs.length);
    }
    
    await prefs.setStringList('payment_logs', logs);
  }

  void _log(String message) {
    debugPrint('[PaymentService] $message');
  }

  /// Clean up resources
  void dispose() {
    _razorpay.clear();
    _paymentTimeout?.cancel();
    _paymentController?.close();
    _isInitialized = false;
  }

  /// Get payment statistics from stored logs
  Future<PaymentStatistics> getPaymentStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final logs = prefs.getStringList('payment_logs') ?? [];
    
    int totalPayments = 0;
    int successfulPayments = 0;
    int failedPayments = 0;
    double totalAmount = 0.0;
    
    for (final log in logs) {
      try {
        final logData = jsonDecode(log);
        totalPayments++;
        totalAmount += (logData['amount'] as int) / 100.0;
        
        final result = logData['result'] as Map<String, dynamic>;
        if (result['isSuccess'] == true) {
          successfulPayments++;
        } else {
          failedPayments++;
        }
      } catch (e) {
        // Skip invalid log entries
      }
    }
    
    return PaymentStatistics(
      totalPayments: totalPayments,
      successfulPayments: successfulPayments,
      failedPayments: failedPayments,
      successRate: totalPayments > 0 ? successfulPayments / totalPayments : 0.0,
      totalAmount: totalAmount,
    );
  }
}

/// Configuration classes and models

class PaymentConfig {
  final String apiKey;
  final String secretKey;
  final String merchantName;
  final String themeColor;
  final String appVersion;
  final String? redirectUrl;
  final String? supportEmail;
  final String? supportPhone;
  final String apiBaseUrl;
  
  const PaymentConfig({
    required this.apiKey,
    required this.secretKey,
    required this.merchantName,
    required this.themeColor,
    required this.appVersion,
    this.redirectUrl,
    this.supportEmail,
    this.supportPhone,
    this.apiBaseUrl = 'https://api.razorpay.com/v1',
  });
}

class PaymentOptions {
  final Set<PaymentMethod> enabledMethods;
  final Duration timeout;
  final bool enableRetry;
  final bool enableSMSNotifications;
  final bool enableEmailNotifications;
  final bool isRecurring;
  final String? recurringToken;
  final Map<String, dynamic> upiOptions;
  final Map<String, dynamic> cardOptions;
  final Map<String, dynamic> netbankingOptions;
  final Map<String, dynamic> walletOptions;
  final Map<String, dynamic> emiOptions;
  final Map<String, dynamic> bnplOptions;
  
  const PaymentOptions({
    this.enabledMethods = const {
      PaymentMethod.upi,
      PaymentMethod.card,
      PaymentMethod.netbanking,
      PaymentMethod.wallet,
    },
    this.timeout = const Duration(minutes: 15),
    this.enableRetry = true,
    this.enableSMSNotifications = true,
    this.enableEmailNotifications = true,
    this.isRecurring = false,
    this.recurringToken,
    this.upiOptions = const {},
    this.cardOptions = const {},
    this.netbankingOptions = const {},
    this.walletOptions = const {},
    this.emiOptions = const {},
    this.bnplOptions = const {},
  });
}

class CustomerInfo {
  final String name;
  final String phone;
  final String email;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  
  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.email,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });
}

enum PaymentMethod {
  upi,
  card,
  netbanking,
  wallet,
  emi,
  bnpl,
}

class PaymentResult {
  final bool isSuccess;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? reason;
  final PaymentErrorCode? errorCode;
  final DateTime timestamp;
  
  const PaymentResult._({
    required this.isSuccess,
    this.paymentId,
    this.orderId,
    this.signature,
    this.reason,
    this.errorCode,
    required this.timestamp,
  });
  
  factory PaymentResult.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentResult._(
      isSuccess: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
      timestamp: DateTime.now(),
    );
  }
  
  factory PaymentResult.failure({
    required String reason,
    required PaymentErrorCode errorCode,
  }) {
    return PaymentResult._(
      isSuccess: false,
      reason: reason,
      errorCode: errorCode,
      timestamp: DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'isSuccess': isSuccess,
      'paymentId': paymentId,
      'orderId': orderId,
      'signature': signature,
      'reason': reason,
      'errorCode': errorCode?.name,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum PaymentErrorCode {
  USER_CANCELLED,
  NETWORK_ERROR,
  INVALID_OPTIONS,
  TIMEOUT,
  METHOD_UNAVAILABLE,
  PROCESSING_ERROR,
  UNKNOWN_ERROR,
}

class RefundResult {
  final bool isSuccess;
  final String? refundId;
  final String? status;
  final String? amount;
  final int? speed;
  final String? reason;
  
  const RefundResult._({
    required this.isSuccess,
    this.refundId,
    this.status,
    this.amount,
    this.speed,
    this.reason,
  });
  
  factory RefundResult.success({
    required String refundId,
    required String status,
    required String amount,
    required int speed,
  }) {
    return RefundResult._(
      isSuccess: true,
      refundId: refundId,
      status: status,
      amount: amount,
      speed: speed,
    );
  }
  
  factory RefundResult.failure({
    required String reason,
    required String refundId,
  }) {
    return RefundResult._(
      isSuccess: false,
      refundId: refundId,
      reason: reason,
    );
  }
}

class PaymentEvent {
  final DateTime timestamp;
  
  const PaymentEvent._({required this.timestamp});
  
  factory PaymentEvent.success({
    required String paymentId,
    required String orderId,
    required String signature,
  }) {
    return PaymentEventSuccess._(
      timestamp: DateTime.now(),
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }
  
  factory PaymentEvent.failure({
    required PaymentErrorCode errorCode,
    required String message,
  }) {
    return PaymentEventFailure._(
      timestamp: DateTime.now(),
      errorCode: errorCode,
      message: message,
    );
  }
}

class PaymentEventSuccess extends PaymentEvent {
  final String paymentId;
  final String orderId;
  final String signature;
  
  PaymentEventSuccess._({
    required super.timestamp,
    required this.paymentId,
    required this.orderId,
    required this.signature,
  }) : super._();
}

class PaymentEventFailure extends PaymentEvent {
  final PaymentErrorCode errorCode;
  final String message;
  
  PaymentEventFailure._({
    required super.timestamp,
    required this.errorCode,
    required this.message,
  }) : super._();
}

class PaymentMethodAvailability {
  final bool isAvailable;
  final String? reason;
  final String? bankCode;
  final List<String>? supportedMethods;
  
  const PaymentMethodAvailability({
    required this.isAvailable,
    this.reason,
    this.bankCode,
    this.supportedMethods,
  });
}

class PaymentAnalytics {
  final int totalCount;
  final int successCount;
  final int failureCount;
  final double totalAmount;
  final double successAmount;
  final double failureAmount;
  final Map<String, int> methodBreakdown;
  final Map<String, int> statusBreakdown;
  
  const PaymentAnalytics({
    required this.totalCount,
    required this.successCount,
    required this.failureCount,
    required this.totalAmount,
    required this.successAmount,
    required this.failureAmount,
    required this.methodBreakdown,
    required this.statusBreakdown,
  });
  
  factory PaymentAnalytics.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    
    int totalCount = 0;
    int successCount = 0;
    int failureCount = 0;
    double totalAmount = 0.0;
    double successAmount = 0.0;
    double failureAmount = 0.0;
    final methodBreakdown = <String, int>{};
    final statusBreakdown = <String, int>{};
    
    for (final item in items) {
      totalCount++;
      final amount = (item['amount'] as int) / 100.0;
      final method = item['method'] as String? ?? 'unknown';
      final status = item['status'] as String? ?? 'unknown';
      
      totalAmount += amount;
      statusBreakdown[status] = (statusBreakdown[status] ?? 0) + 1;
      methodBreakdown[method] = (methodBreakdown[method] ?? 0) + 1;
      
      if (status == 'captured') {
        successCount++;
        successAmount += amount;
      } else {
        failureCount++;
        failureAmount += amount;
      }
    }
    
    return PaymentAnalytics(
      totalCount: totalCount,
      successCount: successCount,
      failureCount: failureCount,
      totalAmount: totalAmount,
      successAmount: successAmount,
      failureAmount: failureAmount,
      methodBreakdown: methodBreakdown,
      statusBreakdown: statusBreakdown,
    );
  }
}

class PaymentStatistics {
  final int totalPayments;
  final int successfulPayments;
  final int failedPayments;
  final double successRate;
  final double totalAmount;
  
  const PaymentStatistics({
    required this.totalPayments,
    required this.successfulPayments,
    required this.failedPayments,
    required this.successRate,
    required this.totalAmount,
  });
}

class PaymentRetryConfig {
  final int maxAttempts;
  final Duration delayBetweenRetries;
  final Set<PaymentErrorCode> retryableErrors;
  
  const PaymentRetryConfig({
    required this.maxAttempts,
    required this.delayBetweenRetries,
    required this.retryableErrors,
  });
}

class PaymentException implements Exception {
  final String message;
  const PaymentException(this.message);
  
  @override
  String toString() => 'PaymentException: $message';
}

/// Riverpod provider for dependency injection
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService.instance;
});

/// Provider for payment configuration
final paymentConfigProvider = Provider<PaymentConfig>((ref) {
  // This should come from environment configuration
  const isProduction = bool.fromEnvironment('dart.vm.product');
  
  return const PaymentConfig(
    apiKey: isProduction 
        ? 'rzp_live_your_key_here' 
        : 'rzp_test_your_key_here',
    secretKey: isProduction 
        ? 'your_secret_key_here' 
        : 'your_secret_key_here',
    merchantName: 'Your Merchant Name',
    themeColor: '#3F51B5',
    appVersion: '1.0.0',
    supportEmail: 'support@yourapp.com',
    supportPhone: '+91-9876543210',
  );
});