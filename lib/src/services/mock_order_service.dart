import 'dart:convert';
import 'dart:math';
import '../models/order_model.dart';
import '../models/product_model.dart';

/// Mock Order Service for testing and development
/// Provides realistic order data and simulation
class MockOrderService {
  static List<Order> _mockOrders = [];
  static final Random _random = Random();

  /// Initialize mock orders with sample data
  static void initializeMockOrders() {
    if (_mockOrders.isNotEmpty) return;

    final sampleOrders = [
      _createSampleOrder('1', 'user_1', OrderStatus.delivered),
      _createSampleOrder('2', 'user_2', OrderStatus.shipped),
      _createSampleOrder('3', 'user_3', OrderStatus.processing),
      _createSampleOrder('4', 'user_1', OrderStatus.paymentConfirmed),
      _createSampleOrder('5', 'user_4', OrderStatus.cancelled),
    ];

    _mockOrders.addAll(sampleOrders);
  }

  /// Create a sample order for testing
  static Order _createSampleOrder(String id, String userId, OrderStatus status) {
    final products = MockProductService.generateProductCatalog(10);
    final selectedProducts = products.take(_random.nextInt(3) + 1).toList();

    final items = selectedProducts.map((product) {
      final quantity = _random.nextInt(3) + 1;
      final unitPrice = product.currentPrice;
      final totalPrice = unitPrice * quantity;
      final savings = (product.originalPrice - product.currentPrice) * quantity;

      return OrderItem(
        id: 'item_${id}_${product.id}',
        product: product,
        size: product.availableSizes.isNotEmpty 
            ? product.availableSizes[_random.nextInt(product.availableSizes.length)]
            : null,
        color: product.availableColors.isNotEmpty 
            ? product.availableColors[_random.nextInt(product.availableColors.length)]
            : null,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: totalPrice,
        savings: savings,
        discountAmount: product.originalPrice > product.currentPrice 
            ? (product.originalPrice - product.currentPrice) * quantity 
            : 0.0,
      );
    }).toList();

    final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final shippingCost = totalAmount > 100 ? 0.0 : 50.0;
    final finalAmount = totalAmount + shippingCost;

    final customer = CustomerInfo(
      name: _getRandomCustomerName(),
      email: 'customer$id@example.com',
      phone: '+91${9000000000 + _random.nextInt(999999999)}',
      shippingAddress: _createSampleAddress(),
      customerTier: _random.nextBool() ? 'VIP' : 'Regular',
      totalOrders: _random.nextInt(10),
    );

    final payment = PaymentDetails(
      method: PaymentMethodType.razorpay,
      amount: finalAmount,
      status: status == OrderStatus.cancelled 
          ? PaymentStatus.failed 
          : PaymentStatus.succeeded,
      razorpayOrderId: 'order_${id}_razorpay_${DateTime.now().millisecondsSinceEpoch}',
      isVerified: true,
    );

    final shipping = ShippingInfo(
      method: ShippingMethod.standard,
      cost: shippingCost,
      carrier: 'BlueDart',
      status: _mapOrderStatusToShippingStatus(status),
      shippedAt: status.index >= OrderStatus.shipped.index 
          ? DateTime.now().subtract(Duration(days: _random.nextInt(5) + 1))
          : null,
      estimatedDeliveryDate: DateTime.now().add(Duration(days: _random.nextInt(7) + 2)),
      estimatedDeliveryDays: _random.nextInt(5) + 3,
    );

    final metadata = OrderMetadata(
      source: 'web',
      promoCode: _random.nextBool() ? 'SAVE10' : null,
      discountAmount: _random.nextBool() ? 50.0 : 0.0,
      createdBy: userId,
      tags: ['test', 'sample'].take(_random.nextInt(2) + 1).toList(),
    );

    final createdAt = DateTime.now().subtract(Duration(days: _random.nextInt(30) + 1));
    final updatedAt = DateTime.now().subtract(Duration(hours: _random.nextInt(48) + 1));

    return Order(
      id: 'ORD_$id',
      userId: userId,
      items: items,
      totalAmount: finalAmount,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: status == OrderStatus.delivered 
          ? DateTime.now().subtract(Duration(days: _random.nextInt(7) + 1))
          : null,
      customer: customer,
      payment: payment,
      shipping: shipping,
      metadata: metadata,
    );
  }

  /// Get random customer name
  static String _getRandomCustomerName() {
    final firstNames = ['John', 'Jane', 'Mike', 'Sarah', 'David', 'Emma', 'Chris', 'Lisa'];
    final lastNames = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis'];
    
    final firstName = firstNames[_random.nextInt(firstNames.length)];
    final lastName = lastNames[_random.nextInt(lastNames.length)];
    
    return '$firstName $lastName';
  }

  /// Create sample address
  static Address _createSampleAddress() {
    final streets = ['123 Main St', '456 Oak Ave', '789 Pine Rd', '321 Elm St'];
    final cities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata'];
    final states = ['Maharashtra', 'Karnataka', 'Tamil Nadu', 'West Bengal', 'Delhi'];
    final countries = ['India'];
    
    return Address(
      street: streets[_random.nextInt(streets.length)],
      city: cities[_random.nextInt(cities.length)],
      state: states[_random.nextInt(states.length)],
      postalCode: '${100000 + _random.nextInt(899999)}',
      country: countries.first,
      landmark: _random.nextBool() ? 'Near Shopping Mall' : null,
      isDefault: _random.nextBool(),
    );
  }

  /// Map order status to shipping status
  static ShippingStatus _mapOrderStatusToShippingStatus(OrderStatus orderStatus) {
    switch (orderStatus) {
      case OrderStatus.orderPlaced:
      case OrderStatus.paymentConfirmed:
        return ShippingStatus.pending;
      case OrderStatus.processing:
        return ShippingStatus.processing;
      case OrderStatus.shipped:
        return _random.nextBool() ? ShippingStatus.shipped : ShippingStatus.inTransit;
      case OrderStatus.delivered:
        return ShippingStatus.delivered;
      default:
        return ShippingStatus.pending;
    }
  }

  /// Get all orders with filtering and pagination
  static List<Order> getOrders({
    String? userId,
    OrderStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int perPage = 20,
  }) {
    initializeMockOrders();
    
    List<Order> filtered = List.from(_mockOrders);
    
    // Apply filters
    if (userId != null) {
      filtered = filtered.where((order) => order.userId == userId).toList();
    }
    
    if (status != null) {
      filtered = filtered.where((order) => order.status == status).toList();
    }
    
    if (fromDate != null) {
      filtered = filtered.where((order) => order.createdAt.isAfter(fromDate)).toList();
    }
    
    if (toDate != null) {
      filtered = filtered.where((order) => order.createdAt.isBefore(toDate)).toList();
    }
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Apply pagination
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;
    
    if (startIndex >= filtered.length) return [];
    
    return filtered.sublist(
      startIndex,
      endIndex < filtered.length ? endIndex : filtered.length
    );
  }

  /// Get order by ID
  static Order? getOrderById(String orderId) {
    initializeMockOrders();
    try {
      return _mockOrders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Create new order
  static Order createOrder(Map<String, dynamic> orderData) {
    initializeMockOrders();
    
    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
    final createdAt = DateTime.now();
    
    // Parse order data
    final itemsJson = orderData['items'] as List<dynamic>;
    final items = itemsJson.map((itemJson) {
      final itemData = itemJson as Map<String, dynamic>;
      final product = Product.fromJson(itemData['product']);
      
      return OrderItem(
        id: 'item_${orderId}_${product.id}',
        product: product,
        size: itemData['size'] as String?,
        color: itemData['color'] as String?,
        quantity: itemData['quantity'] as int? ?? 1,
        unitPrice: product.currentPrice,
        totalPrice: product.currentPrice * (itemData['quantity'] as int? ?? 1),
        isAvailable: product.isAvailable,
      );
    }).toList();
    
    final totalAmount = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final shippingCost = totalAmount > 100 ? 0.0 : 50.0;
    final finalAmount = totalAmount + shippingCost;
    
    final customer = CustomerInfo.fromJson(orderData['customer']);
    final shippingAddress = customer.shippingAddress;
    
    final payment = PaymentDetails(
      method: PaymentMethodType.razorpay,
      amount: finalAmount,
      status: PaymentStatus.pending,
      razorpayOrderId: 'order_${orderId}_razorpay_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    final shipping = ShippingInfo(
      method: ShippingMethod.standard,
      cost: shippingCost,
      deliveryAddress: shippingAddress,
      status: ShippingStatus.pending,
    );
    
    final metadata = OrderMetadata(
      source: orderData['source'] as String? ?? 'web',
      promoCode: orderData['promoCode'] as String?,
      createdBy: orderData['userId'],
      isGift: orderData['isGift'] as bool? ?? false,
      giftMessage: orderData['giftMessage'] as String?,
    );
    
    final order = Order(
      id: orderId,
      userId: orderData['userId'] as String,
      items: items,
      totalAmount: finalAmount,
      status: OrderStatus.orderPlaced,
      createdAt: createdAt,
      updatedAt: createdAt,
      customer: customer,
      payment: payment,
      shipping: shipping,
      metadata: metadata,
    );
    
    _mockOrders.insert(0, order);
    return order;
  }

  /// Update order status
  static Order? updateOrderStatus(String orderId, OrderStatus newStatus) {
    initializeMockOrders();
    
    final orderIndex = _mockOrders.indexWhere((order) => order.id == orderId);
    if (orderIndex == -1) return null;
    
    final order = _mockOrders[orderIndex];
    final updatedOrder = order.updateStatus(newStatus);
    
    _mockOrders[orderIndex] = updatedOrder;
    return updatedOrder;
  }

  /// Verify Razorpay payment
  static bool verifyRazorpayPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required double expectedAmount,
  }) {
    initializeMockOrders();
    
    final order = getOrderById(orderId);
    if (order == null) return false;
    
    // Verify amount matches
    if (order.payment.amount != expectedAmount) return false;
    
    // Verify Razorpay order ID
    if (order.payment.razorpayOrderId != razorpayOrderId) return false;
    
    // Simulate signature verification (in real implementation, use proper crypto verification)
    final isValidSignature = razorpaySignature.length > 10;
    
    // Update payment status
    final updatedPayment = order.payment.copyWith(
      razorpayPaymentId: razorpayPaymentId,
      razorpaySignature: razorpaySignature,
      status: isValidSignature ? PaymentStatus.succeeded : PaymentStatus.failed,
      paidAt: isValidSignature ? DateTime.now() : null,
      isVerified: isValidSignature,
    );
    
    final updatedOrder = order.copyWith(
      payment: updatedPayment,
      status: isValidSignature ? OrderStatus.paymentConfirmed : order.status,
      updatedAt: DateTime.now(),
    );
    
    final orderIndex = _mockOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      _mockOrders[orderIndex] = updatedOrder;
    }
    
    return isValidSignature;
  }

  /// Generate Razorpay order ID
  static String generateRazorpayOrderId(String orderId) {
    return 'order_${orderId}_razorpay_${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(9999)}';
  }

  /// Cancel order
  static Order? cancelOrder(String orderId, String reason) {
    initializeMockOrders();
    
    final order = getOrderById(orderId);
    if (order == null || !order.canBeCancelled) return null;
    
    final updatedOrder = order.updateStatus(OrderStatus.cancelled);
    final updatedPayment = order.payment.copyWith(
      status: PaymentStatus.cancelled,
    );
    
    final finalOrder = updatedOrder.copyWith(
      payment: updatedPayment,
      metadata: order.metadata.copyWith(
        customFields: {'cancellationReason': reason},
      ),
    );
    
    final orderIndex = _mockOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      _mockOrders[orderIndex] = finalOrder;
    }
    
    return finalOrder;
  }

  /// Get order analytics
  static Map<String, dynamic> getOrderAnalytics() {
    initializeMockOrders();
    
    final totalOrders = _mockOrders.length;
    final deliveredOrders = _mockOrders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledOrders = _mockOrders.where((o) => o.status == OrderStatus.cancelled).length;
    final totalRevenue = _mockOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
    final averageOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;
    
    final statusDistribution = <OrderStatus, int>{};
    for (final status in OrderStatus.values) {
      statusDistribution[status] = _mockOrders.where((o) => o.status == status).length;
    }
    
    return {
      'totalOrders': totalOrders,
      'deliveredOrders': deliveredOrders,
      'cancelledOrders': cancelledOrders,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'statusDistribution': statusDistribution.map((key, value) => MapEntry(key.toString().split('.').last, value)),
      'deliveryRate': totalOrders > 0 ? (deliveredOrders / totalOrders * 100) : 0.0,
      'cancellationRate': totalOrders > 0 ? (cancelledOrders / totalOrders * 100) : 0.0,
    };
  }

  /// Search orders
  static List<Order> searchOrders(String query) {
    initializeMockOrders();
    
    final queryLower = query.toLowerCase();
    return _mockOrders.where((order) {
      return order.id.toLowerCase().contains(queryLower) ||
             order.customer.name.toLowerCase().contains(queryLower) ||
             order.customer.email.toLowerCase().contains(queryLower) ||
             order.items.any((item) => 
                 item.product.name.toLowerCase().contains(queryLower));
    }).toList();
  }
}

/// Extension for copying PaymentDetails
extension PaymentDetailsCopy on PaymentDetails {
  PaymentDetails copyWith({
    PaymentMethodType? method,
    String? transactionId,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    double? amount,
    String? currency,
    PaymentStatus? status,
    DateTime? paidAt,
    String? failureReason,
    Map<String, dynamic>? metadata,
    bool? isVerified,
  }) {
    return PaymentDetails(
      method: method ?? this.method,
      transactionId: transactionId ?? this.transactionId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      failureReason: failureReason ?? this.failureReason,
      metadata: metadata ?? this.metadata,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// Extension for copying OrderMetadata
extension OrderMetadataCopy on OrderMetadata {
  OrderMetadata copyWith({
    String? source,
    String? affiliateCode,
    Map<String, dynamic>? customFields,
    String? promoCode,
    double? discountAmount,
    String? giftMessage,
    bool? isGift,
    String? orderNotes,
    Map<String, dynamic>? analytics,
    String? createdBy,
    List<String>? tags,
  }) {
    return OrderMetadata(
      source: source ?? this.source,
      affiliateCode: affiliateCode ?? this.affiliateCode,
      customFields: customFields ?? this.customFields,
      promoCode: promoCode ?? this.promoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      giftMessage: giftMessage ?? this.giftMessage,
      isGift: isGift ?? this.isGift,
      orderNotes: orderNotes ?? this.orderNotes,
      analytics: analytics ?? this.analytics,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
    );
  }
}
