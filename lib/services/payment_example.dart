import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service.dart';
import 'payment_widget.dart';
import 'payment_constants.dart';

/// Example usage of the Razorpay Payment Service
/// Demonstrates various payment scenarios and integrations

class PaymentExampleScreen extends ConsumerStatefulWidget {
  const PaymentExampleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PaymentExampleScreen> createState() => _PaymentExampleScreenState();
}

class _PaymentExampleScreenState extends ConsumerState<PaymentExampleScreen> {
  final _orderController = TextEditingController(text: 'ORDER_${DateTime.now().millisecondsSinceEpoch}');
  final _amountController = TextEditingController(text: '100.00');
  final _descriptionController = TextEditingController(text: 'Premium Subscription');
  final _customerNameController = TextEditingController(text: 'John Doe');
  final _customerEmailController = TextEditingController(text: 'john@example.com');
  final _customerPhoneController = TextEditingController(text: '9876543210');
  
  String _selectedCurrency = 'INR';
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  PaymentResult? _lastPaymentResult;
  PaymentStatistics? _paymentStats;

  @override
  void initState() {
    super.initState();
    _initializePaymentService();
    _loadPaymentStatistics();
  }

  Future<void> _initializePaymentService() async {
    // Create payment configuration
    const paymentConfig = PaymentConfig(
      apiKey: 'rzp_test_your_key_here', // Replace with your test key
      secretKey: 'your_secret_key_here',
      merchantName: 'Your App Name',
      themeColor: '#3F51B5',
      appVersion: '1.0.0',
      supportEmail: 'support@yourapp.com',
      supportPhone: '+91-9876543210',
    );
    
    // Initialize payment service
    final paymentService = ref.read(paymentServiceProvider);
    await paymentService.initialize(paymentConfig);
  }

  Future<void> _loadPaymentStatistics() async {
    final paymentService = ref.read(paymentServiceProvider);
    final stats = await paymentService.getPaymentStatistics();
    setState(() {
      _paymentStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Service Demo'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildPaymentForm(),
            const SizedBox(height: 20),
            _buildPaymentMethods(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            if (_lastPaymentResult != null) _buildResultCard(),
            if (_paymentStats != null) _buildStatisticsCard(),
            const SizedBox(height: 20),
            _buildFeaturesDemo(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Razorpay Payment Service',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comprehensive payment processing with security and compliance',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip('PCI DSS Compliant', Colors.green),
                const SizedBox(width: 8),
                _buildStatusChip('Multiple Methods', Colors.blue),
                const SizedBox(width: 8),
                _buildStatusChip('Secure', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _orderController,
                    label: 'Order ID',
                    prefixIcon: Icons.receipt_long,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCurrencySelector(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTextField(
                    controller: _amountController,
                    label: 'Amount',
                    prefixIcon: Icons.currency_rupee,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    prefixIcon: Icons.description,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: const InputDecoration(
        labelText: 'Currency',
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'INR', child: Text('INR (₹)')),
        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
        DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
        DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCurrency = value!;
        });
      },
    );
  }

  Widget _buildPaymentMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((method) {
                final isSelected = _selectedMethod == method;
                final config = PaymentConstants.methodConfigs[method]!;
                
                return FilterChip(
                  label: Text(config.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMethod = method;
                    });
                  },
                  avatar: Icon(
                    config.icon,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _processQuickPayment,
                icon: const Icon(Icons.payment),
                label: const Text('Quick Payment'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.dialog),
                label: const Text('Payment Dialog'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _validatePaymentMethod,
                icon: const Icon(Icons.check_circle),
                label: const Text('Validate Method'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _showPaymentAnalytics,
                icon: const Icon(Icons.analytics),
                label: const Text('Analytics'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final isSuccess = _lastPaymentResult!.isSuccess;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  isSuccess ? 'Payment Successful!' : 'Payment Failed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
            if (_lastPaymentResult!.paymentId != null) ...[
              const SizedBox(height: 8),
              Text('Payment ID: ${_lastPaymentResult!.paymentId}'),
            ],
            if (_lastPaymentResult!.reason != null) ...[
              const SizedBox(height: 4),
              Text('Reason: ${_lastPaymentResult!.reason}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Timestamp: ${_lastPaymentResult!.timestamp}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', _paymentStats!.totalPayments.toString()),
                _buildStatItem('Success', _paymentStats!.successfulPayments.toString()),
                _buildStatItem('Failed', _paymentStats!.failedPayments.toString()),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _paymentStats!.successRate,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            const SizedBox(height: 4),
            Text(
              'Success Rate: ${(_paymentStats!.successRate * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Amount: ${PaymentUtils.formatAmount(_paymentStats!.totalAmount)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesDemo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFeatureChip('UPI Intent', Icons.smartphone, Colors.blue),
                _buildFeatureChip('Tokenization', Icons.security, Colors.green),
                _buildFeatureChip('Analytics', Icons.analytics, Colors.orange),
                _buildFeatureChip('Refund API', Icons.undo, Colors.purple),
                _buildFeatureChip('EMI Support', Icons.payments, Colors.indigo),
                _buildFeatureChip('BNPL', Icons.schedule, Colors.teal),
                _buildFeatureChip('PCI DSS', Icons.verified, Colors.red),
                _buildFeatureChip('Auto Retry', Icons.refresh, Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label, IconData icon, Color color) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  /// Process payment using the payment service
  Future<void> _processQuickPayment() async {
    if (_validateForm()) return;

    try {
      final paymentService = ref.read(paymentServiceProvider);
      
      final paymentData = PaymentData(
        orderId: _orderController.text,
        amount: _amountController.text,
        currency: _selectedCurrency,
        description: _descriptionController.text,
        customer: CustomerInfo(
          name: _customerNameController.text,
          email: _customerEmailController.text,
          phone: _customerPhoneController.text,
        ),
      );

      final result = await paymentService.processPayment(
        orderId: paymentData.orderId,
        amount: paymentData.amount,
        currency: paymentData.currency,
        description: paymentData.description,
        customer: paymentData.customer,
        options: PaymentOptions(
          enabledMethods: {_selectedMethod},
        ),
      );

      setState(() {
        _lastPaymentResult = result;
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment successful! ID: ${result.paymentId}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${result.reason}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      _loadPaymentStatistics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show payment dialog using PaymentWidget
  Future<void> _showPaymentDialog() {
    if (_validateForm()) return Future.value();

    const paymentConfig = PaymentConfig(
      apiKey: 'rzp_test_your_key_here',
      secretKey: 'your_secret_key_here',
      merchantName: 'Your App Name',
      themeColor: '#3F51B5',
      appVersion: '1.0.0',
    );

    final paymentData = PaymentData(
      orderId: _orderController.text,
      amount: _amountController.text,
      currency: _selectedCurrency,
      description: _descriptionController.text,
      customer: CustomerInfo(
        name: _customerNameController.text,
        email: _customerEmailController.text,
        phone: _customerPhoneController.text,
      ),
    );

    return ref.read(paymentServiceProvider).showPaymentDialog(
      context,
      config: paymentConfig,
      paymentData: paymentData,
    ).then((result) {
      if (result != null) {
        setState(() {
          _lastPaymentResult = result;
        });
      }
    });
  }

  /// Validate payment method availability
  Future<void> _validatePaymentMethod() async {
    final paymentService = ref.read(paymentServiceProvider);
    
    try {
      final availability = await paymentService.checkPaymentMethodAvailability(
        _selectedMethod.name,
        null,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Method Validation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Method: ${_selectedMethod.name}'),
                const SizedBox(height: 8),
                Text('Available: ${availability.isAvailable ? 'Yes' : 'No'}'),
                if (availability.reason != null) ...[
                  const SizedBox(height: 8),
                  Text('Reason: ${availability.reason}'),
                ],
                if (availability.supportedMethods != null) ...[
                  const SizedBox(height: 8),
                  const Text('Supported Providers:'),
                  ...availability.supportedMethods!.map((provider) => 
                    Text('• $provider')
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Validation error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show payment analytics
  Future<void> _showPaymentAnalytics() async {
    final paymentService = ref.read(paymentServiceProvider);
    
    try {
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 30)).toIso8601String().split('T')[0];
      final toDate = now.toIso8601String().split('T')[0];

      final analytics = await paymentService.getPaymentAnalytics(
        fromDate: fromDate,
        toDate: toDate,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Payment Analytics'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAnalyticItem('Total Payments', analytics.totalCount.toString()),
                  _buildAnalyticItem('Successful', analytics.successCount.toString()),
                  _buildAnalyticItem('Failed', analytics.failureCount.toString()),
                  _buildAnalyticItem('Total Amount', PaymentUtils.formatAmount(analytics.totalAmount)),
                  _buildAnalyticItem('Success Rate', '${(analytics.successCount / analytics.totalCount * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 16),
                  const Text('Method Breakdown:'),
                  ...analytics.methodBreakdown.entries.map((entry) => 
                    _buildAnalyticItem(entry.key, entry.value.toString())
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Analytics error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildAnalyticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  /// Validate form inputs
  bool _validateForm() {
    final amountValidation = PaymentValidator.validateAmount(_amountController.text);
    if (!amountValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(amountValidation.errorMessage!)),
      );
      return true;
    }

    final currencyValidation = PaymentValidator.validateCurrency(_selectedCurrency);
    if (!currencyValidation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(currencyValidation.errorMessage!)),
      );
      return true;
    }

    return false;
  }
}

/// Example of integrating payment service in a real app flow
class ProductPurchaseExample extends ConsumerStatefulWidget {
  const ProductPurchaseExample({Key? key}) : super(key: key);

  @override
  ConsumerState<ProductPurchaseExample> createState() => _ProductPurchaseExampleState();
}

class _ProductPurchaseExampleState extends ConsumerState<ProductPurchaseExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase Product')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Product details
            Card(
              child: ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Premium Product'),
                subtitle: const Text('High-quality digital product'),
                trailing: Text(
                  '₹199.00',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Payment button
            ElevatedButton(
              onPressed: () => _handlePurchase(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                child: Text('Buy Now - ₹199'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePurchase() async {
    const paymentConfig = PaymentConfig(
      apiKey: 'rzp_test_your_key_here',
      secretKey: 'your_secret_key_here',
      merchantName: 'Your App Name',
      themeColor: '#3F51B5',
      appVersion: '1.0.0',
    );

    final paymentData = PaymentData(
      orderId: PaymentUtils.generateOrderId(prefix: 'purchase'),
      amount: '199.00',
      currency: 'INR',
      description: 'Premium Product Purchase',
      customer: const CustomerInfo(
        name: 'John Doe',
        email: 'john@example.com',
        phone: '9876543210',
      ),
    );

    final result = await ref.read(paymentServiceProvider).showPaymentDialog(
      context,
      config: paymentConfig,
      paymentData: paymentData,
    );

    if (result?.isSuccess == true) {
      // Handle successful purchase
      _showSuccessDialog(result!);
    } else {
      // Handle failed purchase
      _showFailureDialog(result);
    }
  }

  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Payment ID: ${result.paymentId}'),
            const Text('Your product has been purchased successfully.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(PaymentResult? result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Purchase Failed'),
        content: Text(result?.reason ?? 'Payment was not completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}