/// Order Tracking Screen
/// 
/// Comprehensive order tracking with real-time updates:
/// - Order status tracking
/// - Payment status monitoring
/// - Shipping tracking
/// - Order modification options
/// - Customer support integration
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/payment_service.dart';
import '../../../services/checkout_service.dart';
import '../../../models/order_model.dart';
import '../../../widgets/widgets.dart';
import '../../../themes/app_theme.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  
  const OrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _statusUpdateTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startStatusPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    _statusUpdateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshOrderStatus();
      }
    });
  }

  Future<void> _refreshOrderStatus() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    try {
      final paymentService = ref.read(paymentServiceProvider);
      await paymentService.getOrderStatus(widget.orderId);
      // Handle status update
    } catch (e) {
      _showErrorSnackBar('Failed to refresh order status');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderDetailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshOrderStatus,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Tracking'),
            Tab(text: 'Details'),
          ],
        ),
      ),
      body: order == null 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(order),
                _buildTrackingTab(order),
                _buildDetailsTab(order),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(order),
    );
  }

  Widget _buildOverviewTab(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderStatusCard(order),
          const SizedBox(height: 16),
          _buildProgressCard(order),
          const SizedBox(height: 16),
          _buildQuickActionsCard(order),
        ],
      ),
    );
  }

  Widget _buildTrackingTab(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimelineCard(order),
          const SizedBox(height: 16),
          _buildShippingCard(order),
        ],
      ),
    );
  }

  Widget _buildDetailsTab(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderInfoCard(order),
          const SizedBox(height: 16),
          _buildItemsCard(order),
          const SizedBox(height: 16),
          _buildPaymentCard(order),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(order.status),
                  color: _getStatusColor(order.status),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.status.displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.status.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Order ID: '),
                Text(
                  order.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () => _copyOrderId(order.id),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Placed: '),
                Text(
                  '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: order.progressPercentage / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${order.progressPercentage.round()}% Complete',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressSteps(order),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSteps(Order order) {
    final steps = [
      {'step': OrderStatus.orderPlaced, 'title': 'Order Placed'},
      {'step': OrderStatus.paymentConfirmed, 'title': 'Payment Confirmed'},
      {'step': OrderStatus.processing, 'title': 'Processing'},
      {'step': OrderStatus.shipped, 'title': 'Shipped'},
      {'step': OrderStatus.delivered, 'title': 'Delivered'},
    ];

    return Column(
      children: steps.map((step) {
        final stepOrderStatus = step['step'] as OrderStatus;
        final isActive = _isStepActive(order.status, stepOrderStatus);
        final isCompleted = _isStepCompleted(order.status, stepOrderStatus);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? Colors.green
                      : isActive
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
                ),
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : isActive
                        ? const Icon(Icons.circle, color: Colors.white, size: 12)
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step['title'] as String,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive ? AppTheme.primaryColor : null,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickActionsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.support_agent,
                    label: 'Support',
                    onTap: () => _contactSupport(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.receipt_long,
                    label: 'Invoice',
                    onTap: () => _downloadInvoice(order),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (order.canBeCancelled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelOrder(order),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade50,
        foregroundColor: AppTheme.primaryColor,
        side: BorderSide(color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildTimelineCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildTimelineItem(
                  'Order Placed',
                  'Your order has been placed successfully',
                  Icons.shopping_cart,
                  order.createdAt,
                  isCompleted: true,
                ),
                if (order.payment.status != PaymentStatus.pending)
                  _buildTimelineItem(
                    'Payment Confirmed',
                    'Your payment has been processed',
                    Icons.payment,
                    order.createdAt.add(const Duration(minutes: 2)),
                    isCompleted: true,
                  ),
                _buildTimelineItem(
                  'Processing',
                    'Your order is being prepared',
                    Icons.inventory,
                    order.createdAt.add(const Duration(hours: 1)),
                    isCompleted: order.status != OrderStatus.orderPlaced,
                  ),
                if (order.status == OrderStatus.shipped || order.status == OrderStatus.delivered)
                  _buildTimelineItem(
                    'Shipped',
                    'Your order has been shipped',
                    Icons.local_shipping,
                    order.updatedAt,
                    isCompleted: true,
                  ),
                if (order.status == OrderStatus.delivered)
                  _buildTimelineItem(
                    'Delivered',
                    'Your order has been delivered',
                    Icons.check_circle,
                    order.completedAt ?? DateTime.now(),
                    isCompleted: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle,
    IconData icon,
    DateTime time, {
    bool isCompleted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isCompleted ? AppTheme.primaryColor : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? null : Colors.grey.shade600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (order.shipping.trackingNumber != null) ...[
              Row(
                children: [
                  const Text('Tracking Number: '),
                  Text(
                    order.shipping.trackingNumber!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () => _copyTrackingNumber(order.shipping.trackingNumber!),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Text('Shipping Method: '),
                Text(order.shipping.method.displayName),
              ],
            ),
            const SizedBox(height: 8),
            Text('Estimated Delivery: ${_getEstimatedDelivery(order)}'),
            const SizedBox(height: 16),
            if (order.shipping.trackingNumber != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _trackShipment(order.shipping.trackingNumber!),
                  child: const Text('Track Shipment'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderInfoCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', order.id),
            _buildInfoRow('Status', order.status.displayName),
            _buildInfoRow('Placed On', '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}'),
            _buildInfoRow('Last Updated', '${order.updatedAt.day}/${order.updatedAt.month}/${order.updatedAt.year}'),
            if (order.completedAt != null)
              _buildInfoRow('Completed', '${order.completedAt!.day}/${order.completedAt!.month}/${order.completedAt!.year}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...order.items.map((item) => _buildOrderItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              item.productImage,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item.size != null || item.color != null)
                  Text(
                    '${item.size ?? ''} ${item.color ?? ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Information',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Method', order.payment.displayName),
            _buildInfoRow('Status', order.payment.status.displayName),
            _buildInfoRow('Amount', '₹${order.payment.amount.toStringAsFixed(2)}'),
            _buildInfoRow('Currency', order.payment.currency),
            if (order.payment.transactionId != null)
              _buildInfoRow('Transaction ID', order.payment.transactionId!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(Order order) {
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
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Status: ${order.status.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(order.status),
                    ),
                  ),
                ],
              ),
            ),
            if (order.status != OrderStatus.delivered)
              ElevatedButton(
                onPressed: () => _contactSupport(),
                child: const Text('Support'),
              ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.orderPlaced:
        return Icons.shopping_cart;
      case OrderStatus.paymentConfirmed:
        return Icons.payment;
      case OrderStatus.processing:
        return Icons.inventory;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.orderPlaced:
      case OrderStatus.paymentConfirmed:
        return Colors.blue;
      case OrderStatus.processing:
        return Colors.orange;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  bool _isStepActive(OrderStatus currentStatus, OrderStatus stepStatus) {
    final orderValues = OrderStatus.values;
    final currentIndex = orderValues.indexOf(currentStatus);
    final stepIndex = orderValues.indexOf(stepStatus);
    return stepIndex == currentIndex;
  }

  bool _isStepCompleted(OrderStatus currentStatus, OrderStatus stepStatus) {
    final orderValues = OrderStatus.values;
    final currentIndex = orderValues.indexOf(currentStatus);
    final stepIndex = orderValues.indexOf(stepStatus);
    return stepIndex < currentIndex;
  }

  String _getEstimatedDelivery(Order order) {
    if (order.shipping.estimatedDeliveryDate != null) {
      return '${order.shipping.estimatedDeliveryDate!.day}/${order.shipping.estimatedDeliveryDate!.month}/${order.shipping.estimatedDeliveryDate!.year}';
    }
    return '3-5 business days';
  }

  void _copyOrderId(String orderId) {
    // Implement copy functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order ID copied to clipboard')),
    );
  }

  void _copyTrackingNumber(String trackingNumber) {
    // Implement copy functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking number copied to clipboard')),
    );
  }

  void _trackShipment(String trackingNumber) {
    // Open shipment tracking
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening shipment tracking...')),
    );
  }

  void _downloadInvoice(Order order) {
    // Download invoice
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading invoice...')),
    );
  }

  void _cancelOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              // Cancel order logic
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: 1800-123-4567'),
            SizedBox(height: 8),
            Text('Email: support@digitalfashion.com'),
            SizedBox(height: 8),
            Text('Hours: 9 AM - 6 PM (Mon-Sat)'),
          ],
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
