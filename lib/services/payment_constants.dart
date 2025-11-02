/// Payment Constants and Configuration Utilities
/// Contains all payment-related constants, validations, and configuration helpers

class PaymentConstants {
  // Razorpay Configuration
  static const String testApiBaseUrl = 'https://api.razorpay.com/v1';
  static const String liveApiBaseUrl = 'https://api.razorpay.com/v1';
  
  // Timeout configurations
  static const int defaultPaymentTimeout = 15 * 60; // 15 minutes in seconds
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // Payment limits
  static const double minAmount = 1.0; // Minimum amount in INR
  static const double maxAmount = 10000000.0; // Maximum amount in INR (1 crore)
  
  // Currency support
  static const List<String> supportedCurrencies = [
    'INR', 'USD', 'EUR', 'GBP', 'AUD', 'CAD', 'SGD', 'HKD', 'JPY', 'ZAR',
  ];
  
  // Payment method configurations
  static const Map<PaymentMethod, PaymentMethodConfig> methodConfigs = {
    PaymentMethod.upi: PaymentMethodConfig(
      displayName: 'UPI',
      icon: Icons.smartphone,
      description: 'Pay using UPI apps like GPay, PhonePe, Paytm',
      maxTimeout: 900, // 15 minutes
      supportedProviders: [
        'GPay',
        'PhonePe',
        'Paytm',
        'BHIM',
        'AmazonPay',
        'MiPay',
        'SamsungPay',
        'TrueCaller',
        'Mobikwik',
        'FreeCharge',
        'AirtelMoney',
        'JioMoney',
        'PayZapp',
        'Khatabook',
        'RazorpayX',
      ],
      validationRules: {
        'min_amount': 1.0,
        'max_amount': 100000.0,
        'currency': 'INR',
      },
    ),
    PaymentMethod.card: PaymentMethodConfig(
      displayName: 'Cards',
      icon: Icons.credit_card,
      description: 'Credit and Debit Cards',
      maxTimeout: 900,
      supportedProviders: [
        'Visa',
        'Mastercard',
        'RuPay',
        'American Express',
        'Diners Club',
        'Maestro',
        'UnionPay',
        'JCB',
      ],
      validationRules: {
        'min_amount': 1.0,
        'max_amount': 200000.0,
        'currency': 'INR',
      },
    ),
    PaymentMethod.netbanking: PaymentMethodConfig(
      displayName: 'Net Banking',
      icon: Icons.account_balance,
      description: 'Internet Banking',
      maxTimeout: 900,
      supportedProviders: [
        'Axis Bank',
        'HDFC Bank',
        'ICICI Bank',
        'State Bank of India',
        'Punjab National Bank',
        'Bank of Baroda',
        'IDBI Bank',
        'Canara Bank',
        'Union Bank',
        'Kotak Mahindra Bank',
        'IndusInd Bank',
        'Yes Bank',
        'Federal Bank',
        'South Indian Bank',
        'RBL Bank',
        'DCB Bank',
        'UCO Bank',
        'Central Bank of India',
        'Indian Bank',
        'Bank of India',
        'Allahabad Bank',
        'Andhra Bank',
        'Bank of Maharashtra',
        'Corporation Bank',
        'Dena Bank',
        'Oriental Bank of Commerce',
        'Punjab & Sind Bank',
        'Syndicate Bank',
        'Ujjivan Small Finance Bank',
        'AU Small Finance Bank',
        'Equitas Small Finance Bank',
        'Utkarsh Small Finance Bank',
        'ESAF Small Finance Bank',
        'Jana Small Finance Bank',
        'North East Small Finance Bank',
        'Karnataka Bank',
        'Catholic Syrian Bank',
        'City Union Bank',
        'DCB Bank',
        'IDFC FIRST Bank',
        'IndusInd Bank',
        'Jammu & Kashmir Bank',
        'Karnataka Bank',
        'Karur Vysya Bank',
        'Lakshmi Vilas Bank',
        'Nainital Bank',
        'RBL Bank',
        'Saraswat Bank',
        'Shivalik Small Finance Bank',
        'Tamilnad Mercantile Bank',
        'UCO Bank',
        'Ujjivan Small Finance Bank',
      ],
      validationRules: {
        'min_amount': 1.0,
        'max_amount': 100000.0,
        'currency': 'INR',
      },
    ),
    PaymentMethod.wallet: PaymentMethodConfig(
      displayName: 'Digital Wallets',
      icon: Icons.wallet,
      description: 'Digital Wallet Payments',
      maxTimeout: 900,
      supportedProviders: [
        'Paytm',
        'Amazon Pay',
        'PhonePe',
        'Mobikwik',
        'FreeCharge',
        'Airtel Money',
        'JioMoney',
        'PayZapp',
        'Fino Pay',
        'Aditya Birla Money',
        'AU Small Finance Bank',
        'Bank of Baroda',
        'Bank of Maharashtra',
        'Central Bank',
        'Corporation Bank',
        'Dhanlaxmi Bank',
        'Federal Bank',
        'HDFC Bank',
        'ICICI Bank',
        'IDBI Bank',
        'IDFC First Bank',
        'Indian Bank',
        'IndusInd Bank',
        'Karnataka Bank',
        'Karur Vysya Bank',
        'Kotak Mahindra Bank',
        'Lakshmi Vilas Bank',
        'Oriental Bank of Commerce',
        'Punjab National Bank',
        'RBL Bank',
        'South Indian Bank',
        'State Bank of India',
        'Syndicate Bank',
        'UCO Bank',
        'Union Bank',
        'Utkarsh Small Finance Bank',
        'Vijaya Bank',
        'Yes Bank',
        'Standard Chartered Bank',
        'HDFC DCB',
        'Karnataka Bank',
        'Tamilnad Mercantile Bank',
        'Catholic Syrian Bank',
        'City Union Bank',
        'Nainital Bank',
        'Saraswat Bank',
        'Indian Overseas Bank',
        'Dena Bank',
        'Vijaya Bank',
        'Baroda Gujarat Gramin Bank',
        'Madhya Pradesh Gramin Bank',
        'Punjab Gramin Bank',
        'Sarva UP Gramin Bank',
        'Aryavart Bank',
        'Baroda UP Bank',
        'Chandigarh Bank',
        'Tamil Nadu Grama Bank',
        'Telangana Grameena Bank',
        'Andhra Pradesh Grameena Bank',
        'Karnataka Grameena Bank',
        'Odisha Gramya Bank',
        'Madhya Bharat Gramin Bank',
        'Maharashtra Gramin Bank',
        'Bihar Kshetriya Gramin Bank',
        'Jharkhand Gramin Bank',
        'Uttar Bihar Gramin Bank',
        'West Bengal Gramin Bank',
        'Baroda Rajasthan Kshetriya Gramin Bank',
        'Aryavart Bank',
      ],
      validationRules: {
        'min_amount': 1.0,
        'max_amount': 50000.0,
        'currency': 'INR',
      },
    ),
    PaymentMethod.emi: PaymentMethodConfig(
      displayName: 'EMI',
      icon: Icons.payments,
      description: 'Easy Monthly Installments',
      maxTimeout: 900,
      supportedProviders: [
        'Bajaj Finserv',
        'HDB Financial',
        'HDFC Bank',
        'ICICI Bank',
        'Axis Bank',
        'Kotak Mahindra Bank',
        'IndusInd Bank',
        'RBL Bank',
        'Federal Bank',
        'South Indian Bank',
        'IDFC First Bank',
        'IndusInd Bank',
        'AU Small Finance Bank',
        'Equitas Small Finance Bank',
        'Utkarsh Small Finance Bank',
        'Jana Small Finance Bank',
        'Ujjivan Small Finance Bank',
        'ESAF Small Finance Bank',
        'North East Small Finance Bank',
        'Shivalik Small Finance Bank',
        'Fincare Small Finance Bank',
        'ESAF Small Finance Bank',
      ],
      validationRules: {
        'min_amount': 2000.0,
        'max_amount': 500000.0,
        'currency': 'INR',
        'min_tenure': 3, // months
        'max_tenure': 36, // months
      },
    ),
    PaymentMethod.bnpl: PaymentMethodConfig(
      displayName: 'Buy Now Pay Later',
      icon: Icons.schedule,
      description: 'Pay later with 0% interest',
      maxTimeout: 900,
      supportedProviders: [
        'Simpl',
        'Khatabook',
        'LazyPay',
        'Pay Later',
        'ZestMoney',
        'UniPay',
        'HDFC Bank PayLater',
        'ICICI Bank PayLater',
        'Axis Bank PayLater',
        'Kotak PayLater',
        'IndusInd Bank PayLater',
        'RBL Bank PayLater',
        'Federal Bank PayLater',
        'South Indian Bank PayLater',
        'IDFC First Bank PayLater',
      ],
      validationRules: {
        'min_amount': 100.0,
        'max_amount': 50000.0,
        'currency': 'INR',
        'max_free_period_days': 30,
      },
    ),
  };
  
  // Error message mappings
  static const Map<PaymentErrorCode, String> errorMessages = {
    PaymentErrorCode.USER_CANCELLED: 'Payment was cancelled by user',
    PaymentErrorCode.NETWORK_ERROR: 'Network error occurred. Please try again',
    PaymentErrorCode.INVALID_OPTIONS: 'Invalid payment configuration',
    PaymentErrorCode.TIMEOUT: 'Payment timed out. Please try again',
    PaymentErrorCode.METHOD_UNAVAILABLE: 'Selected payment method is not available',
    PaymentErrorCode.PROCESSING_ERROR: 'Payment processing error occurred',
    PaymentErrorCode.UNKNOWN_ERROR: 'An unknown error occurred',
  };
  
  // Security configurations
  static const Map<String, dynamic> securityConfig = {
    'pci_compliance_version': '1.0',
    'data_encryption': 'AES-256',
    'token_storage': 'secure',
    'audit_logging': true,
    'fraud_detection': true,
    'rate_limiting': true,
    'ip_whitelist': false,
  };
  
  // Analytics tracking
  static const Map<String, String> analyticsEvents = {
    'payment_initiated': 'payment_initiated',
    'payment_success': 'payment_success',
    'payment_failure': 'payment_failure',
    'payment_refund': 'payment_refund',
    'method_selection': 'payment_method_selected',
    'retry_attempt': 'payment_retry',
  };
}

/// Payment Method Configuration Model
class PaymentMethodConfig {
  final String displayName;
  final IconData icon;
  final String description;
  final int maxTimeout;
  final List<String> supportedProviders;
  final Map<String, dynamic> validationRules;
  
  const PaymentMethodConfig({
    required this.displayName,
    required this.icon,
    required this.description,
    required this.maxTimeout,
    required this.supportedProviders,
    required this.validationRules,
  });
}

/// Validation utilities for payment data
class PaymentValidator {
  /// Validate payment amount
  static ValidationResult validateAmount(String amount) {
    if (amount.isEmpty) {
      return ValidationResult.failure('Amount is required');
    }
    
    final amountValue = double.tryParse(amount);
    if (amountValue == null) {
      return ValidationResult.failure('Invalid amount format');
    }
    
    if (amountValue < PaymentConstants.minAmount) {
      return ValidationResult.failure(
        'Minimum amount is ₹${PaymentConstants.minAmount}',
      );
    }
    
    if (amountValue > PaymentConstants.maxAmount) {
      return ValidationResult.failure(
        'Maximum amount is ₹${PaymentConstants.maxAmount}',
      );
    }
    
    return ValidationResult.success();
  }
  
  /// Validate currency
  static ValidationResult validateCurrency(String currency) {
    if (currency.isEmpty) {
      return ValidationResult.failure('Currency is required');
    }
    
    if (!PaymentConstants.supportedCurrencies.contains(currency)) {
      return ValidationResult.failure('Unsupported currency: $currency');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate customer information
  static ValidationResult validateCustomer(CustomerInfo customer) {
    if (customer.name.trim().isEmpty) {
      return ValidationResult.failure('Customer name is required');
    }
    
    if (!_isValidPhone(customer.phone)) {
      return ValidationResult.failure('Invalid phone number');
    }
    
    if (!_isValidEmail(customer.email)) {
      return ValidationResult.failure('Invalid email address');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate UPI ID
  static ValidationResult validateUPIId(String upiId) {
    if (upiId.isEmpty) {
      return ValidationResult.failure('UPI ID is required');
    }
    
    final upiPattern = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!upiPattern.hasMatch(upiId)) {
      return ValidationResult.failure('Invalid UPI ID format');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate card information
  static ValidationResult validateCardInfo({
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvv,
  }) {
    if (!_isValidCardNumber(cardNumber)) {
      return ValidationResult.failure('Invalid card number');
    }
    
    if (!_isValidExpiry(expiryMonth, expiryYear)) {
      return ValidationResult.failure('Invalid card expiry date');
    }
    
    if (!_isValidCVV(cvv)) {
      return ValidationResult.failure('Invalid CVV');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate bank code
  static ValidationResult validateBankCode(String bankCode) {
    if (bankCode.isEmpty) {
      return ValidationResult.failure('Bank code is required');
    }
    
    // Basic validation - in production, this should check against Razorpay's bank list
    if (bankCode.length < 2 || bankCode.length > 10) {
      return ValidationResult.failure('Invalid bank code');
    }
    
    return ValidationResult.success();
  }
  
  /// Validate payment method
  static ValidationResult validatePaymentMethod(PaymentMethod method, Map<String, dynamic> options) {
    final config = PaymentConstants.methodConfigs[method];
    if (config == null) {
      return ValidationResult.failure('Unknown payment method');
    }
    
    // Method-specific validations can be added here
    return ValidationResult.success();
  }
  
  // Private helper methods
  static bool _isValidPhone(String phone) {
    final phonePattern = RegExp(r'^[6-9]\d{9}$');
    return phonePattern.hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }
  
  static bool _isValidEmail(String email) {
    final emailPattern = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailPattern.hasMatch(email);
  }
  
  static bool _isValidCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }
    
    // Luhn algorithm check
    int sum = 0;
    bool alternate = false;
    for (int i = cleanNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cleanNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit / 10).floor() + (digit % 10);
        }
      }
      sum += digit;
      alternate = !alternate;
    }
    
    return sum % 10 == 0;
  }
  
  static bool _isValidExpiry(String month, String year) {
    final monthValue = int.tryParse(month);
    final yearValue = int.tryParse(year);
    
    if (monthValue == null || yearValue == null) {
      return false;
    }
    
    if (monthValue < 1 || monthValue > 12) {
      return false;
    }
    
    final now = DateTime.now();
    final expiryDate = DateTime(yearValue, monthValue);
    final currentDate = DateTime(now.year, now.month);
    
    return expiryDate.isAfter(currentDate);
  }
  
  static bool _isValidCVV(String cvv) {
    final cvvPattern = RegExp(r'^\d{3,4}$');
    return cvvPattern.hasMatch(cvv);
  }
}

/// Validation Result Model
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  
  const ValidationResult._({required this.isValid, this.errorMessage});
  
  factory ValidationResult.success() {
    return const ValidationResult._(isValid: true);
  }
  
  factory ValidationResult.failure(String message) {
    return ValidationResult._(isValid: false, errorMessage: message);
  }
}

/// Environment configuration utility
class PaymentEnvironment {
  static bool get isProduction => const bool.fromEnvironment('dart.vm.product');
  
  static String get apiBaseUrl => isProduction
      ? PaymentConstants.liveApiBaseUrl
      : PaymentConstants.testApiBaseUrl;
  
  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'User-Agent': 'PaymentService/1.0.0',
  };
}

/// Utility functions for payment processing
class PaymentUtils {
  /// Format amount for display
  static String formatAmount(double amount, {String currency = 'INR'}) {
    switch (currency) {
      case 'INR':
        return '₹${amount.toStringAsFixed(2)}';
      case 'USD':
        return '\$${amount.toStringAsFixed(2)}';
      case 'EUR':
        return '€${amount.toStringAsFixed(2)}';
      case 'GBP':
        return '£${amount.toStringAsFixed(2)}';
      default:
        return '$currency ${amount.toStringAsFixed(2)}';
    }
  }
  
  /// Convert amount to paise (for INR) or smallest currency unit
  static int toSmallestUnit(double amount, {String currency = 'INR'}) {
    switch (currency) {
      case 'INR':
        return (amount * 100).round(); // Convert to paise
      case 'JPY':
        return amount.round(); // JPY doesn't have decimals
      default:
        return (amount * 100).round();
    }
  }
  
  /// Convert from smallest unit to major unit
  static double fromSmallestUnit(int amount, {String currency = 'INR'}) {
    switch (currency) {
      case 'INR':
        return amount / 100.0;
      case 'JPY':
        return amount.toDouble();
      default:
        return amount / 100.0;
    }
  }
  
  /// Generate unique order ID
  static String generateOrderId({String prefix = 'order'}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (1000 + (timestamp % 9000));
    return '${prefix}_${timestamp}_$random';
  }
  
  /// Mask sensitive card information
  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return cardNumber;
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    final masked = '**** **** **** $lastFour';
    return masked;
  }
  
  /// Check if payment method is available in region
  static bool isMethodAvailableInRegion(
    PaymentMethod method, 
    String countryCode,
  ) {
    switch (countryCode.toUpperCase()) {
      case 'IN':
        return true; // All methods available in India
      case 'US':
        return [PaymentMethod.card, PaymentMethod.wallet].contains(method);
      default:
        return [PaymentMethod.card].contains(method);
    }
  }
  
  /// Get payment method icon based on card type
  static IconData getCardIcon(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanNumber.startsWith('4')) {
      return Icons.credit_card; // Visa
    } else if (cleanNumber.startsWith('5') || cleanNumber.startsWith('2')) {
      return Icons.credit_card; // Mastercard
    } else if (cleanNumber.startsWith('6')) {
      return Icons.credit_card; // RuPay/Discover
    } else {
      return Icons.credit_card; // Generic
    }
  }
}

/// Payment feature flags for A/B testing
class PaymentFeatureFlags {
  static const bool enableBNPL = true;
  static const bool enableEMI = true;
  static const bool enableRecurring = false;
  static const bool enableAutoRetry = true;
  static const bool enablePaymentAnalytics = true;
  static const bool enableUPIIntent = true;
  static const bool enableSavedCards = false;
}