/// Complete Checkout Flow Screen
/// 
/// Multi-step checkout process with Razorpay integration:
/// - Order review and validation
/// - Shipping address management
/// - Payment method selection
/// - Order confirmation
/// - Payment processing with success/failure handling
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/checkout_service.dart';
import '../../../services/payment_service.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../widgets/widgets.dart';
import '../../../themes/app_theme.dart';

class CheckoutFlowScreen extends ConsumerStatefulWidget {
  const CheckoutFlowScreen({super.key});

  @override
  ConsumerState<CheckoutFlowScreen> createState() => _CheckoutFlowScreenState();
}

class _CheckoutFlowScreenState extends ConsumerState<CheckoutFlowScreen> {
  late CheckoutService _checkoutService;
  final PageController _pageController = PageController();
  final TextEditingController _couponController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkoutService = ref.read(checkoutServiceProvider);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: AnimatedBuilder(
        animation: _checkoutService,
        builder: (context, child) => _buildContent(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final currentStep = _checkoutService.currentStep;
    final stepTitle = currentStep.displayName;

    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Checkout'),
          Text(
            stepTitle,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      actions: [
        if (_checkoutService.currentStep != CheckoutStep.success &&
            _checkoutService.currentStep != CheckoutStep.failed &&
            _checkoutService.currentStep != CheckoutStep.cancelled)
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showCancelCheckoutDialog,
          ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_checkoutService.currentStep) {
      case CheckoutStep.review:
      case CheckoutStep.address:
      case CheckoutStep.paymentMethod:
      case CheckoutStep.reviewOrder:
        return _buildCheckoutFlow();
      case CheckoutStep.processingPayment:
        return _buildProcessingPayment();
      case CheckoutStep.success:
        return _buildSuccessScreen();
      case CheckoutStep.failed:
        return _buildFailedScreen();
      case CheckoutStep.cancelled:
        return _buildCancelledScreen();
    }
  }

  Widget _buildCheckoutFlow() {
    return Column(
      children: [
        _buildStepIndicator(),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildReviewStep(),
              _buildAddressStep(),
              _buildPaymentMethodStep(),
              _buildReviewOrderStep(),
            ],
          ),
        ),
        _buildNavigationBar(),
      ],
    );
  }

  Widget _buildStepIndicator() {
    final currentStepIndex = _getStepIndex(_checkoutService.currentStep);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _buildStep(0, 'Review', currentStepIndex),
          Expanded(child: _buildStepConnector(currentStepIndex >= 1)),
          _buildStep(1, 'Address', currentStepIndex),
          Expanded(child: _buildStepConnector(currentStepIndex >= 2)),
          _buildStep(2, 'Payment', currentStepIndex),
          Expanded(child: _buildStepConnector(currentStepIndex >= 3)),
          _buildStep(3, 'Confirm', currentStepIndex),
        ],
      ),
    );
  }

  Widget _buildStep(int index, String title, int currentStepIndex) {
    final isActive = currentStepIndex == index;
    final isCompleted = currentStepIndex > index;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? Colors.green
                : isActive
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
            border: Border.all(
              color: isActive ? AppTheme.primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 16)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: isActive 
                ? AppTheme.primaryColor 
                : isCompleted 
                    ? Colors.green.shade600
                    : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isCompleted) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  int _getStepIndex(CheckoutStep step) {
    switch (step) {
      case CheckoutStep.review:
        return 0;
      case CheckoutStep.address:
        return 1;
      case CheckoutStep.paymentMethod:
        return 2;
      case CheckoutStep.reviewOrder:
        return 3;
      default:
        return 0;
    }
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Order',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Order Items
          if (_checkoutService.items.isNotEmpty)
            ..._checkoutService.items.map((item) => _buildOrderItem(item)),
          
          const SizedBox(height: 24),
          
          // Coupon Section
          _buildCouponSection(),
          
          const SizedBox(height: 24),
          
          // Price Breakdown
          _buildPriceBreakdown(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
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
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                const Text(
                  'Apply Coupon',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_checkoutService.appliedDiscount != null)
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
                        'Applied: ${_checkoutService.appliedDiscount!.code}',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _checkoutService.removeDiscount(),
                      child: const Text('Remove'),
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
                      decoration: const InputDecoration(
                        hintText: 'Enter coupon code',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _checkoutService.applyDiscount(value);
                          _couponController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (_couponController.text.isNotEmpty) {
                        _checkoutService.applyDiscount(_couponController.text);
                        _couponController.clear();
                      }
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('Subtotal', _checkoutService.subtotal),
            if (_checkoutService.discountAmount > 0)
              _buildPriceRow(
                'Discount',
                -_checkoutService.discountAmount,
                isNegative: true,
              ),
            const Divider(),
            _buildPriceRow(
              'Total',
              _checkoutService.totalAmount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Address',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Selected Address Display
          if (_checkoutService.selectedAddress != null)
            Card(
              color: AppTheme.primaryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _checkoutService.selectedAddress!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(_checkoutService.selectedAddress!.fullAddress),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${_checkoutService.selectedAddress!.phone}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No address selected'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showAddAddressDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Address'),
                    ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Saved Addresses (Placeholder)
          Text(
            'Saved Addresses',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          
          // Sample saved address
          Card(
            child: ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home Address'),
              subtitle: const Text('123 Main St, City, State 12345'),
              trailing: _checkoutService.selectedAddress != null 
                  ? null 
                  : const Text('Tap to select'),
              onTap: _selectHomeAddress,
            ),
          ),
          
          Card(
            child: ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Work Address'),
              subtitle: const Text('456 Office St, City, State 54321'),
              trailing: _checkoutService.selectedAddress != null 
                  ? null 
                  : const Text('Tap to select'),
              onTap: _selectWorkAddress,
            ),
          ),
          
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _showAddAddressDialog,
            icon: const Icon(Icons.add_location),
            label: const Text('Add New Address'),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Payment methods list
          _buildPaymentMethodOption(
            title: 'Credit/Debit Card',
            subtitle: 'Visa, MasterCard, RuPay',
            icon: Icons.credit_card,
            isSelected: true,
          ),
          
          const SizedBox(height: 8),
          
          _buildPaymentMethodOption(
            title: 'Net Banking',
            subtitle: 'All major banks supported',
            icon: Icons.account_balance,
          ),
          
          const SizedBox(height: 8),
          
          _buildPaymentMethodOption(
            title: 'UPI',
            subtitle: 'Google Pay, PhonePe, BHIM UPI',
            icon: Icons.qr_code,
          ),
          
          const SizedBox(height: 8),
          
          _buildPaymentMethodOption(
            title: 'Digital Wallets',
            subtitle: 'Paytm, Amazon Pay, Mobikwik',
            icon: Icons.wallet,
          ),
          
          const SizedBox(height: 16),
          
          // Security info
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your payment information is secure and encrypted',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Customer Support
          Card(
            color: Colors.grey.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Help?',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customer Care: 1800-123-4567',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    'Email: support@digitalfashion.com',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isSelected = false,
  }) {
    return Card(
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: Colors.green.shade600)
            : const Icon(Icons.radio_button_unchecked),
        onTap: () {
          // Handle payment method selection
        },
      ),
    );
  }

  Widget _buildReviewOrderStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Your Order',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          
          // Order Summary
          _buildReviewSection(
            'Order Summary',
            '${_checkoutService.items.length} items',
            widget: Column(
              children: _checkoutService.items.take(3).map((item) {
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      item.product.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('Qty: ${item.quantity}'),
                  trailing: Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Shipping Address
          _buildReviewSection(
            'Shipping Address',
            _checkoutService.selectedAddress?.fullAddress ?? 'Not selected',
            widget: _checkoutService.selectedAddress != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_checkoutService.selectedAddress!.name),
                      Text(_checkoutService.selectedAddress!.phone),
                      Text(_checkoutService.selectedAddress!.email),
                    ],
                  )
                : null,
          ),
          
          const SizedBox(height: 16),
          
          // Payment Method
          _buildReviewSection(
            'Payment Method',
            'Credit/Debit Card via Razorpay',
          ),
          
          const SizedBox(height: 16),
          
          // Price Breakdown
          _buildReviewSection(
            'Price Details',
            null,
            widget: Column(
              children: [
                _buildReviewPriceRow('Subtotal', _checkoutService.subtotal),
                if (_checkoutService.discountAmount > 0)
                  _buildReviewPriceRow(
                    'Discount',
                    -_checkoutService.discountAmount,
                    isNegative: true,
                  ),
                const Divider(),
                _buildReviewPriceRow(
                  'Total Amount',
                  _checkoutService.totalAmount,
                  isTotal: true,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Terms and Conditions
          CheckboxListTile(
            value: true,
            onChanged: (value) {
              // Toggle terms acceptance
            },
            title: const Text('I agree to the Terms and Conditions'),
            subtitle: const Text('By proceeding, you agree to our terms of service and privacy policy'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 16),
          
          // Special Instructions
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Special Instructions (Optional)',
              hintText: 'Any special delivery instructions...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, String? subtitle, {Widget? widget}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle),
            ],
            if (widget != null) ...[
              const SizedBox(height: 8),
              widget,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewPriceRow(
    String label,
    double amount, {
    bool isNegative = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isNegative ? Colors.red : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingPayment() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
            const SizedBox(height: 32),
            const Text(
              'Processing Payment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait while we process your payment...',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.payment, color: Colors.blue.shade600, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${_checkoutService.totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Razorpay Payment Gateway',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final order = _checkoutService.createdOrder;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 100,
              color: Colors.green.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your order has been confirmed and is being processed',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            if (order != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Order ID:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(order.id),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${_checkoutService.totalAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Credit/Debit Card'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Delivery:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Text('3-5 Business Days'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to order tracking
                    },
                    child: const Text('Track Order'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Customer Support
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.support_agent, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Need Help?',
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Contact us at support@digitalfashion.com',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 24),
            const Text(
              'Payment Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _checkoutService.state.error ?? 'Payment could not be processed. Please try again.',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Error details
            if (_checkoutService.state.error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Details:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _checkoutService.state.error!,
                        style: TextStyle(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Recommendations
            Text(
              'What you can try:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _checkoutService.getPaymentRecommendations()
                  .map((recommendation) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(recommendation)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Back to Cart'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _checkoutService.retryPayment();
                    },
                    child: const Text('Try Again'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cancel_outlined,
            size: 100,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          const Text(
            'Payment Cancelled',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can try again or continue shopping',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Back to Cart'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    _checkoutService.retryPayment();
                  },
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    final currentStep = _checkoutService.currentStep;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep != CheckoutStep.review)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _checkoutService.previousStep();
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Back'),
                ),
              ),
            if (currentStep != CheckoutStep.review) const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _checkoutService.canProceed ? _handleNextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  currentStep == CheckoutStep.reviewOrder
                      ? 'Place Order'
                      : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNextStep() {
    if (_checkoutService.nextStep()) {
      final stepIndex = _getStepIndex(_checkoutService.currentStep);
      _pageController.animateToPage(
        stepIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _showErrorSnackBar(
        _checkoutService.state.error ?? 'Please complete all required fields',
      );
    }
  }

  void _showAddAddressDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Address'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle address creation
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _selectHomeAddress() {
    // Create sample home address
    final homeAddress = ShippingAddress(
      id: 'home',
      name: 'John Doe',
      phone: '+91 9876543210',
      email: 'john@example.com',
      street: '123 Main Street, Apartment 4B',
      city: 'Mumbai',
      state: 'Maharashtra',
      zipCode: '400001',
      country: 'India',
      isDefault: true,
    );
    
    _checkoutService.updateShippingAddress(homeAddress);
  }

  void _selectWorkAddress() {
    // Create sample work address
    final workAddress = ShippingAddress(
      id: 'work',
      name: 'John Doe',
      phone: '+91 9876543210',
      email: 'john@example.com',
      street: '456 Business Park, Tower A, Floor 5',
      city: 'Mumbai',
      state: 'Maharashtra',
      zipCode: '400002',
      country: 'India',
      isDefault: false,
    );
    
    _checkoutService.updateShippingAddress(workAddress);
  }

  void _showCancelCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Checkout'),
        content: const Text('Are you sure you want to cancel the checkout process? Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
          ElevatedButton(
            onPressed: () {
              _checkoutService.cancelCheckout();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Checkout'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
