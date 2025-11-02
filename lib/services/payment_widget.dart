import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'payment_service.dart';

/// Payment Widget for easy integration
/// Provides a user-friendly interface for processing payments
class PaymentWidget extends ConsumerStatefulWidget {
  final PaymentConfig config;
  final PaymentData paymentData;
  final PaymentWidgetConfig widgetConfig;
  final Function(PaymentResult) onPaymentComplete;
  
  const PaymentWidget({
    Key? key,
    required this.config,
    required this.paymentData,
    this.widgetConfig = const PaymentWidgetConfig(),
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  ConsumerState<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends ConsumerState<PaymentWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  
  PaymentResult? _lastPaymentResult;
  bool _isProcessing = false;
  String? _selectedPaymentMethod;
  
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
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    
    // Initialize payment service
    _initializePaymentService();
  }
  
  void _initializePaymentService() async {
    final paymentService = ref.read(paymentServiceProvider);
    await paymentService.initialize(widget.config);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Card(
        elevation: widget.widgetConfig.elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.widgetConfig.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildAmountDisplay(),
                      const SizedBox(height: 20),
                      _buildPaymentMethodSelector(),
                      const SizedBox(height: 20),
                      if (widget.paymentData.customer.email.isNotEmpty)
                        _buildCustomerInfo(),
                      const SizedBox(height: 24),
                      _buildPaymentButton(),
                      if (_lastPaymentResult != null) ...[
                        const SizedBox(height: 16),
                        _buildPaymentResult(),
                      ],
                      if (widget.widgetConfig.showSecurityInfo) ...[
                        const SizedBox(height: 16),
                        _buildSecurityInfo(),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.payment,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Payment',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.paymentData.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Amount to Pay',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[700],
            ),
          ),
          Text(
            '${widget.paymentData.currency} ${widget.paymentData.amount}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    final availableMethods = _getAvailablePaymentMethods();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Method',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...availableMethods.map((method) => _buildMethodOption(method)),
      ],
    );
  }

  Widget _buildMethodOption(PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method.name;
    final icon = _getMethodIcon(method);
    final label = _getMethodLabel(method);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isProcessing ? null : () {
          setState(() {
            _selectedPaymentMethod = method.name;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected 
                  ? Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF')))
                  : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected 
                ? Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF'))).withOpacity(0.05)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF')))
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected 
                        ? Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF')))
                        : null,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF'))),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment will be processed for:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.paymentData.customer.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.blue[800],
            ),
          ),
          Text(
            '${widget.paymentData.customer.phone} • ${widget.paymentData.customer.email}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return ElevatedButton(
      onPressed: _isProcessing || _selectedPaymentMethod == null ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(int.parse(widget.config.themeColor.replaceAll('#', '0xFF'))),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: _isProcessing ? 0 : 2,
      ),
      child: _isProcessing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Processing Payment...'),
              ],
            )
          : Text(
              widget.widgetConfig.buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildPaymentResult() {
    if (_lastPaymentResult == null) return const SizedBox.shrink();
    
    final isSuccess = _lastPaymentResult!.isSuccess;
    final color = isSuccess ? Colors.green : Colors.red;
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    final message = isSuccess ? 'Payment Successful!' : 'Payment Failed';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (!isSuccess && _lastPaymentResult!.reason != null)
                  Text(
                    _lastPaymentResult!.reason!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security,
            color: Colors.grey[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Secured by Razorpay • PCI DSS Compliant',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) return;
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final paymentService = ref.read(paymentServiceProvider);
      
      final result = await paymentService.processPayment(
        orderId: widget.paymentData.orderId,
        amount: widget.paymentData.amount,
        currency: widget.paymentData.currency,
        description: widget.paymentData.description,
        customer: widget.paymentData.customer,
        options: PaymentOptions(
          enabledMethods: {PaymentMethod.values.firstWhere(
            (m) => m.name == _selectedPaymentMethod,
          )},
        ),
      );
      
      setState(() {
        _lastPaymentResult = result;
        _isProcessing = false;
      });
      
      widget.onPaymentComplete(result);
      
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<PaymentMethod> _getAvailablePaymentMethods() {
    // Return methods based on configuration
    return [
      PaymentMethod.upi,
      PaymentMethod.card,
      PaymentMethod.netbanking,
      PaymentMethod.wallet,
    ];
  }

  IconData _getMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return Icons.smartphone;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.netbanking:
        return Icons.account_balance;
      case PaymentMethod.wallet:
        return Icons.wallet;
      case PaymentMethod.emi:
        return Icons.payments;
      case PaymentMethod.bnpl:
        return Icons.schedule;
    }
  }

  String _getMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI (GPay, PhonePe, Paytm)';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.netbanking:
        return 'Net Banking';
      case PaymentMethod.wallet:
        return 'Digital Wallet';
      case PaymentMethod.emi:
        return 'EMI';
      case PaymentMethod.bnpl:
        return 'Buy Now Pay Later';
    }
  }
}

/// Configuration for Payment Widget appearance
class PaymentWidgetConfig {
  final double elevation;
  final double borderRadius;
  final String buttonText;
  final bool showSecurityInfo;
  final bool showCustomerInfo;
  
  const PaymentWidgetConfig({
    this.elevation = 4.0,
    this.borderRadius = 16.0,
    this.buttonText = 'Pay Securely',
    this.showSecurityInfo = true,
    this.showCustomerInfo = true,
  });
}

/// Data class for payment information
class PaymentData {
  final String orderId;
  final String amount;
  final String currency;
  final String description;
  final CustomerInfo customer;
  final String? notes;
  
  const PaymentData({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.description,
    required this.customer,
    this.notes,
  });
}

/// Quick payment dialog widget
class QuickPaymentDialog extends ConsumerDialog<PaymentResult> {
  final PaymentConfig config;
  final PaymentData paymentData;
  
  const QuickPaymentDialog({
    Key? key,
    required this.config,
    required this.paymentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: PaymentWidget(
        config: config,
        paymentData: paymentData,
        onPaymentComplete: (result) {
          Navigator.of(context).pop(result);
        },
      ),
    );
  }
}

/// Extension for easier dialog usage
extension PaymentDialogExtension on PaymentService {
  Future<PaymentResult?> showPaymentDialog(
    BuildContext context, {
    required PaymentConfig config,
    required PaymentData paymentData,
  }) {
    return showDialog<PaymentResult>(
      context: context,
      builder: (context) => QuickPaymentDialog(
        config: config,
        paymentData: paymentData,
      ),
    );
  }
}