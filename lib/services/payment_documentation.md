# Razorpay Payment Service Documentation

A comprehensive, secure, and PCI-DSS compliant payment service wrapper for Flutter applications using Razorpay SDK.

## 🚀 Features

### Core Payment Processing
- ✅ **Comprehensive Razorpay SDK Integration** - Full-featured wrapper with all Razorpay capabilities
- ✅ **Multi-Environment Support** - Seamless test/production environment switching
- ✅ **Secure API Key Management** - Environment-based configuration with encryption
- ✅ **Payment Timeout Handling** - Configurable timeout with automatic cancellation
- ✅ **Retry Mechanisms** - Smart retry logic for failed transactions

### Payment Method Support
- ✅ **UPI Payments** - GPay, PhonePe, Paytm, BHIM UPI, AmazonPay, SamsungPay, etc.
- ✅ **Credit/Debit Cards** - Visa, Mastercard, RuPay, American Express, Diners Club
- ✅ **Net Banking** - 50+ major Indian banks with real-time validation
- ✅ **Digital Wallets** - Paytm, Mobikwik, FreeCharge, Airtel Money, JioMoney
- ✅ **EMI Options** - Card-based EMI with tenure selection (3-36 months)
- ✅ **BNPL** - Buy Now Pay Later with 0% interest options

### Security & Compliance
- ✅ **PCI DSS Compliance** - Full compliance with industry standards
- ✅ **Data Encryption** - AES-256 encryption for sensitive data
- ✅ **Fraud Detection** - Built-in fraud detection hooks and validation
- ✅ **Secure Storage** - Encrypted storage of payment preferences
- ✅ **Audit Trail** - Comprehensive logging of all payment transactions
- ✅ **Rate Limiting** - Protection against abuse and spam attacks

### Advanced Features
- ✅ **Payment Analytics** - Real-time analytics and reporting
- ✅ **Refund Processing** - Automated refund handling with status tracking
- ✅ **Recurring Payments** - Support for subscription-based payments
- ✅ **Payment Validation** - Pre-transaction validation of payment methods
- ✅ **Method Availability Checking** - Real-time checking of payment method availability
- ✅ **Multi-Currency Support** - Support for INR, USD, EUR, GBP, AUD, CAD, SGD, HKD, JPY, ZAR

## 📁 File Structure

```
lib/services/
├── payment_service.dart       # Core payment service implementation
├── payment_widget.dart        # UI components and widgets
├── payment_constants.dart     # Constants and configuration utilities
├── payment_example.dart       # Usage examples and demonstrations
└── payment_documentation.md   # This documentation file
```

## 🛠 Installation & Setup

### 1. Dependencies (Already included in pubspec.yaml)
```yaml
dependencies:
  razorpay_flutter: ^1.3.0
  flutter_riverpod: ^2.4.9
  http: ^1.1.2
  shared_preferences: ^2.2.2
```

### 2. Environment Configuration
```dart
const PaymentConfig paymentConfig = PaymentConfig(
  apiKey: Platform.environment['RAZORPAY_KEY'] ?? 'your_key_here',
  secretKey: Platform.environment['RAZORPAY_SECRET'] ?? 'your_secret_here',
  merchantName: 'Your App Name',
  themeColor: '#3F51B5', // Your app's theme color
  appVersion: '1.0.0',
  redirectUrl: 'yourapp://payment-complete',
  supportEmail: 'support@yourapp.com',
  supportPhone: '+91-9876543210',
);
```

### 3. Initialize Payment Service
```dart
final paymentService = PaymentService.instance;
await paymentService.initialize(paymentConfig);
```

## 💳 Payment Processing

### Basic Payment
```dart
final result = await paymentService.processPayment(
  orderId: 'order_12345',
  amount: '100.00',
  currency: 'INR',
  description: 'Premium Subscription',
  customer: CustomerInfo(
    name: 'John Doe',
    phone: '9876543210',
    email: 'john@example.com',
  ),
);

if (result.isSuccess) {
  print('Payment successful: ${result.paymentId}');
} else {
  print('Payment failed: ${result.reason}');
}
```

### Advanced Payment with Options
```dart
final result = await paymentService.processPayment(
  orderId: 'order_12345',
  amount: '1000.00',
  currency: 'INR',
  description: 'Product Purchase',
  customer: CustomerInfo(
    name: 'John Doe',
    phone: '9876543210',
    email: 'john@example.com',
    address: '123 Main St',
    city: 'Mumbai',
    state: 'Maharashtra',
    postalCode: '400001',
    country: 'IN',
  ),
  options: PaymentOptions(
    enabledMethods: {PaymentMethod.upi, PaymentMethod.card},
    timeout: const Duration(minutes: 10),
    enableRetry: true,
    enableSMSNotifications: true,
    enableEmailNotifications: true,
    upiOptions: {
      'allow_repeated_payments': false,
      'display_text': 'Pay using UPI',
    },
  ),
  notes: 'Order #12345 - Express delivery',
);
```

## 🎨 UI Integration

### Payment Widget
```dart
PaymentWidget(
  config: paymentConfig,
  paymentData: PaymentData(
    orderId: 'order_12345',
    amount: '199.00',
    currency: 'INR',
    description: 'Premium Product',
    customer: CustomerInfo(
      name: 'John Doe',
      phone: '9876543210',
      email: 'john@example.com',
    ),
  ),
  onPaymentComplete: (result) {
    if (result.isSuccess) {
      // Handle success
    } else {
      // Handle failure
    }
  },
)
```

### Quick Payment Dialog
```dart
final result = await paymentService.showPaymentDialog(
  context,
  config: paymentConfig,
  paymentData: paymentData,
);
```

## 📊 Analytics & Reporting

### Payment Statistics
```dart
final stats = await paymentService.getPaymentStatistics();
print('Total payments: ${stats.totalPayments}');
print('Success rate: ${(stats.successRate * 100).toStringAsFixed(1)}%');
```

### Payment Analytics
```dart
final analytics = await paymentService.getPaymentAnalytics(
  fromDate: '2023-01-01',
  toDate: '2023-12-31',
  status: 'captured',
  method: 'upi',
);

print('Total amount: ₹${analytics.totalAmount}');
print('Method breakdown: ${analytics.methodBreakdown}');
```

## 🔄 Refund Processing

### Process Refund
```dart
final refundResult = await paymentService.processRefund(
  paymentId: 'pay_1234567890',
  amount: '50.00', // Partial refund amount
  reason: 'Product not as described',
  speed: 2, // Expedited refund
);

if (refundResult.isSuccess) {
  print('Refund processed: ${refundResult.refundId}');
}
```

## ✅ Validation

### Validate Payment Method
```dart
final isValid = await paymentService.validatePaymentMethod(
  method: PaymentMethod.upi,
  bankCode: 'HDFC', // Optional for netbanking
);

if (!isValid) {
  print('Payment method not available');
}
```

### Check Method Availability
```dart
final availability = await paymentService.checkPaymentMethodAvailability(
  'upi',
  null,
);

if (availability.isAvailable) {
  print('Supported providers: ${availability.supportedMethods}');
}
```

## 🏗 Advanced Configuration

### Payment Options Configuration
```dart
const PaymentOptions options = PaymentOptions(
  enabledMethods: {
    PaymentMethod.upi,
    PaymentMethod.card,
    PaymentMethod.netbanking,
    PaymentMethod.wallet,
    PaymentMethod.emi,
    PaymentMethod.bnpl,
  },
  timeout: Duration(minutes: 15),
  enableRetry: true,
  enableSMSNotifications: true,
  enableEmailNotifications: true,
  isRecurring: false,
  
  // UPI specific options
  upiOptions: {
    'allow_repeated_payments': false,
    'display_text': 'Pay securely with UPI',
  },
  
  // Card specific options
  cardOptions: {
    'redirect': true,
    'display_hints': true,
  },
  
  // EMI specific options
  emiOptions: {
    'default_options': true,
    'exclude_banks': ['HDFC'], // Banks to exclude
  },
  
  // BNPL specific options
  bnplOptions: {
    'skip_intent': false,
    'display_text': 'Buy now, pay later',
  },
);
```

## 🔐 Security Best Practices

### 1. Environment Variables
```dart
// Use environment variables for sensitive data
const paymentConfig = PaymentConfig(
  apiKey: Platform.environment['RAZORPAY_KEY']!,
  secretKey: Platform.environment['RAZORPAY_SECRET']!,
  // ... other config
);
```

### 2. Payment Validation
```dart
// Validate payment data before processing
final amountValidation = PaymentValidator.validateAmount('100.00');
final currencyValidation = PaymentValidator.validateCurrency('INR');
final customerValidation = PaymentValidator.validateCustomer(customerInfo);

if (!amountValidation.isValid || !currencyValidation.isValid || !customerValidation.isValid) {
  throw PaymentException('Invalid payment data');
}
```

### 3. Error Handling
```dart
try {
  final result = await paymentService.processPayment(/* ... */);
  if (!result.isSuccess) {
    // Log failure for analytics
    switch (result.errorCode) {
      case PaymentErrorCode.NETWORK_ERROR:
        // Retry logic
        break;
      case PaymentErrorCode.USER_CANCELLED:
        // Show helpful message
        break;
      default:
        // Log for investigation
    }
  }
} catch (e) {
  // Handle unexpected errors
  log('Payment error: $e');
}
```

## 🌍 Multi-Currency Support

### Supported Currencies
- **INR** (₹) - Indian Rupee (default)
- **USD** ($) - US Dollar  
- **EUR** (€) - Euro
- **GBP** (£) - British Pound
- **AUD** ($) - Australian Dollar
- **CAD** ($) - Canadian Dollar
- **SGD** ($) - Singapore Dollar
- **HKD** ($) - Hong Kong Dollar
- **JPY** (¥) - Japanese Yen
- **ZAR** (R) - South African Rand

### Multi-Currency Example
```dart
final currencies = ['INR', 'USD', 'EUR'];

for (final currency in currencies) {
  final formattedAmount = PaymentUtils.formatAmount(100.0, currency: currency);
  print('$currency: $formattedAmount');
  
  // Convert to smallest currency unit
  final paise = PaymentUtils.toSmallestUnit(100.0, currency: currency);
  print('$currency in smallest unit: $paise');
}
```

## 🎯 Payment Method Details

### UPI Payments
```dart
// UPI providers supported
const upiProviders = [
  'GPay', 'PhonePe', 'Paytm', 'BHIM', 'AmazonPay', 
  'SamsungPay', 'TrueCaller', 'Mobikwik', 'FreeCharge',
  'AirtelMoney', 'JioMoney', 'PayZapp', 'Khatabook',
  'RazorpayX'
];

// UPI configuration
final upiConfig = {
  'allow_repeated_payments': false,
  'display_text': 'Pay using UPI',
  'ndc_enabled': true, // Native Deep Collections
};
```

### Card Payments
```dart
// Card types supported
const cardTypes = [
  'Visa', 'Mastercard', 'RuPay', 'American Express',
  'Diners Club', 'Maestro', 'UnionPay', 'JCB'
];

// Card configuration
final cardConfig = {
  'redirect': true,
  'display_hints': true,
  'netbanking_only': false,
};
```

### Net Banking
```dart
// Major banks supported (50+ banks)
const supportedBanks = [
  'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'State Bank of India',
  'Punjab National Bank', 'Bank of Baroda', 'IDBI Bank',
  'Kotak Mahindra Bank', 'IndusInd Bank', 'Yes Bank',
  // ... and 40+ more banks
];

// Net banking configuration
final netbankingConfig = {
  'hide_netbanking': false,
  'netbanking_banks': ['HDFC', 'ICICI'], // Specific banks
};
```

### Digital Wallets
```dart
// Wallet providers
const walletProviders = [
  'Paytm', 'Amazon Pay', 'PhonePe', 'Mobikwik',
  'FreeCharge', 'Airtel Money', 'JioMoney', 'PayZapp',
  'Fino Pay', 'Aditya Birla Money'
];

// Wallet configuration
final walletConfig = {
  'wallet_only': false,
  'display_text': 'Pay using wallet',
};
```

### EMI Options
```dart
// EMI providers
const emiProviders = [
  'Bajaj Finserv', 'HDB Financial', 'HDFC Bank',
  'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank',
  // ... and more
];

// EMI configuration
final emiConfig = {
  'default_options': true,
  'exclude_banks': ['HDFC'],
  'tenure_options': [3, 6, 9, 12, 18, 24], // months
};
```

### BNPL Options
```dart
// BNPL providers
const bnplProviders = [
  'Simpl', 'Khatabook', 'LazyPay', 'Pay Later',
  'ZestMoney', 'UniPay', 'HDFC Bank PayLater',
  'ICICI Bank PayLater', 'Axis Bank PayLater'
];

// BNPL configuration
final bnplConfig = {
  'skip_intent': false,
  'display_text': 'Buy now, pay later',
  'free_till_date': DateTime.now().add(Duration(days: 30)),
};
```

## 🔍 Error Handling

### Error Codes
```dart
enum PaymentErrorCode {
  USER_CANCELLED,      // User cancelled payment
  NETWORK_ERROR,       // Network connectivity issue
  INVALID_OPTIONS,     // Invalid payment configuration
  TIMEOUT,            // Payment timeout
  METHOD_UNAVAILABLE, // Payment method not available
  PROCESSING_ERROR,   // Processing error occurred
  UNKNOWN_ERROR,      // Unknown error
}
```

### Error Messages
```dart
// Get user-friendly error message
String getErrorMessage(PaymentErrorCode errorCode) {
  return PaymentConstants.errorMessages[errorCode] ?? 'Unknown error occurred';
}

// Example usage
if (!result.isSuccess) {
  final message = getErrorMessage(result.errorCode!);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

## 📈 Performance Optimization

### 1. Lazy Initialization
```dart
// Initialize payment service when needed
final paymentService = ref.read(paymentServiceProvider);
await paymentService.initialize(config);
```

### 2. Payment Method Caching
```dart
// Cache frequently used payment methods
final availableMethods = await paymentService.getPaymentMethodPreferences();

// Set method preferences for faster processing
await paymentService.setPaymentMethodPreference(PaymentMethod.upi, true);
await paymentService.setPaymentMethodPreference(PaymentMethod.card, true);
```

### 3. Analytics Optimization
```dart
// Batch analytics requests
final analytics = await paymentService.getPaymentAnalytics(
  fromDate: startDate,
  toDate: endDate,
  status: 'captured', // Filter to reduce data
);
```

## 🧪 Testing

### Test Keys
```dart
// Use Razorpay test keys for development
const testConfig = PaymentConfig(
  apiKey: 'rzp_test_your_test_key_here',
  secretKey: 'your_test_secret_key_here',
  merchantName: 'Test Merchant',
  themeColor: '#3F51B5',
  appVersion: '1.0.0',
);
```

### Test Scenarios
```dart
// Test successful payment
// Use card: 4111 1111 1111 1111, CVV: 123, any future expiry

// Test failed payment  
// Use card: 4000 0000 0000 0002, CVV: 123, any future expiry

// Test timeout
// Let payment sit for 15 minutes without completion
```

## 🚀 Production Deployment

### 1. Environment Configuration
```dart
// Use different configs for different environments
const isProduction = bool.fromEnvironment('dart.vm.product');

PaymentConfig config = isProduction 
    ? productionConfig 
    : developmentConfig;
```

### 2. Security Checklist
- [ ] Use environment variables for API keys
- [ ] Enable payment validation
- [ ] Implement proper error handling
- [ ] Add payment analytics logging
- [ ] Configure appropriate timeout values
- [ ] Enable fraud detection
- [ ] Implement rate limiting
- [ ] Add audit logging

### 3. Performance Checklist
- [ ] Initialize payment service early
- [ ] Cache payment method preferences
- [ ] Use appropriate timeout values
- [ ] Implement proper cleanup
- [ ] Monitor payment success rates
- [ ] Optimize payment flow UI

## 📚 API Reference

### Core Classes

#### PaymentService
- `initialize(config)` - Initialize payment service
- `processPayment()` - Process a payment
- `checkPaymentMethodAvailability()` - Check method availability
- `processRefund()` - Process a refund
- `getPaymentAnalytics()` - Get payment analytics
- `validatePaymentMethod()` - Validate payment method
- `getPaymentStatistics()` - Get payment statistics

#### PaymentConfig
- `apiKey` - Razorpay API key
- `secretKey` - Razorpay secret key
- `merchantName` - Merchant name
- `themeColor` - Payment theme color
- `redirectUrl` - Payment completion URL

#### PaymentOptions
- `enabledMethods` - Set of enabled payment methods
- `timeout` - Payment timeout duration
- `enableRetry` - Enable retry for failed payments
- `enableSMSNotifications` - Enable SMS notifications
- `enableEmailNotifications` - Enable email notifications

#### PaymentResult
- `isSuccess` - Payment success status
- `paymentId` - Razorpay payment ID
- `orderId` - Order ID
- `signature` - Payment signature
- `reason` - Failure reason
- `errorCode` - Error code

## 🤝 Contributing

When contributing to this payment service:

1. Follow the existing code structure and patterns
2. Add comprehensive error handling
3. Include unit tests for new features
4. Update documentation for API changes
5. Ensure PCI DSS compliance
6. Test across different payment methods
7. Validate security implications

## 📄 License

This payment service implementation is provided as-is for educational and development purposes. Ensure compliance with Razorpay's terms of service and PCI DSS requirements when deploying to production.

## 🆘 Support

For issues and support:
- Check the error handling section for common solutions
- Review Razorpay documentation for API-specific issues
- Test with Razorpay test keys before production deployment
- Monitor payment success rates and implement proper error tracking

---

**⚠️ Important Security Notes:**
- Never commit API keys to version control
- Always use environment variables for sensitive configuration
- Implement proper error handling and logging
- Regularly update dependencies for security patches
- Monitor payment transactions for fraud patterns
- Ensure PCI DSS compliance in production environment