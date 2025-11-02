import 'product_model.dart';

/// Comprehensive Order class with all required fields for order management
class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;
  
  // Customer Information
  final CustomerInfo customer;
  
  // Order Items (enhanced)
  // Already defined in items field
  
  // Payment Details
  final PaymentDetails payment;
  
  // Order Status Tracking
  // Already defined in status field
  
  // Shipping Information
  final ShippingInfo shipping;
  
  // Order Metadata
  final OrderMetadata metadata;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.customer,
    required this.payment,
    required this.shipping,
    required this.metadata,
  });

  /// Factory constructor for creating an order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final items = itemsJson
        .map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      items: items,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: OrderStatus.fromString(json['status'] as String? ?? 'pending'),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      customer: CustomerInfo.fromJson(json['customer'] ?? {}),
      payment: PaymentDetails.fromJson(json['payment'] ?? {}),
      shipping: ShippingInfo.fromJson(json['shipping'] ?? {}),
      metadata: OrderMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  /// Convert order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'customer': customer.toJson(),
      'payment': payment.toJson(),
      'shipping': shipping.toJson(),
      'metadata': metadata.toJson(),
    };
  }

  /// Create a copy of the order with updated fields
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? totalAmount,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    CustomerInfo? customer,
    PaymentDetails? payment,
    ShippingInfo? shipping,
    OrderMetadata? metadata,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      customer: customer ?? this.customer,
      payment: payment ?? this.payment,
      shipping: shipping ?? this.shipping,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Update order status with timestamp
  Order updateStatus(OrderStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      completedAt: newStatus == OrderStatus.delivered ? DateTime.now() : completedAt,
    );
  }

  /// Get order progress percentage based on status
  double get progressPercentage {
    switch (status) {
      case OrderStatus.orderPlaced:
        return 10.0;
      case OrderStatus.paymentConfirmed:
        return 25.0;
      case OrderStatus.processing:
        return 50.0;
      case OrderStatus.shipped:
        return 75.0;
      case OrderStatus.delivered:
        return 100.0;
      case OrderStatus.cancelled:
        return 0.0;
      case OrderStatus.returnRequested:
        return 0.0;
      case OrderStatus.refunded:
        return 0.0;
      default:
        return 0.0;
    }
  }

  /// Check if order can be cancelled
  bool get canBeCancelled {
    return [
      OrderStatus.orderPlaced,
      OrderStatus.paymentConfirmed,
      OrderStatus.processing,
    ].contains(status);
  }

  /// Check if order can be returned
  bool get canBeReturned {
    return status == OrderStatus.delivered;
  }

  /// Check if order is in final state
  bool get isFinalState {
    return [
      OrderStatus.delivered,
      OrderStatus.cancelled,
      OrderStatus.refunded,
    ].contains(status);
  }

  /// Get estimated delivery date based on shipping method
  DateTime? get estimatedDeliveryDate {
    final days = shipping.estimatedDeliveryDays;
    if (days == null) return null;
    return createdAt.add(Duration(days: days));
  }

  /// Get total items count
  int get totalItemsCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get total savings compared to original prices
  double get totalSavings {
    return items.fold(0.0, (sum, item) => sum + item.savings);
  }

  /// Check if order has any discounts
  bool get hasDiscounts {
    return totalSavings > 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Order && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Order{id: $id, totalAmount: $totalAmount, status: $status}';
  }
}

class CartItem {
  final String id;
  final Product product;
  final int quantity;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
  });

  /// Factory constructor for creating a cart item from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int? ?? 1,
    );
  }

  /// Convert cart item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  /// Create a copy of cart item with updated fields
  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Calculate total price for this cart item
  double get totalPrice => product.price * quantity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItem{id: $id, product: ${product.name}, quantity: $quantity}';
  }
}

/// Enhanced OrderItem class with size, color, and pricing details
class OrderItem {
  final String id;
  final Product product;
  final String? size;
  final String? color;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final double discountAmount;
  final double savings;
  final DateTime? availabilityCheckAt;
  final bool isAvailable;
  final String? notes;

  OrderItem({
    required this.id,
    required this.product,
    this.size,
    this.color,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.discountAmount = 0.0,
    this.savings = 0.0,
    this.availabilityCheckAt,
    this.isAvailable = true,
    this.notes,
  });

  /// Factory constructor for creating an order item from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String? ?? '',
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      size: json['size'] as String?,
      color: json['color'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      savings: (json['savings'] as num?)?.toDouble() ?? 0.0,
      availabilityCheckAt: json['availabilityCheckAt'] != null 
          ? DateTime.parse(json['availabilityCheckAt'] as String)
          : null,
      isAvailable: json['isAvailable'] as bool? ?? true,
      notes: json['notes'] as String?,
    );
  }

  /// Convert order item to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'size': size,
      'color': color,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'discountAmount': discountAmount,
      'savings': savings,
      'availabilityCheckAt': availabilityCheckAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'notes': notes,
    };
  }

  /// Create a copy of the order item with updated fields
  OrderItem copyWith({
    String? id,
    Product? product,
    String? size,
    String? color,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    double? discountAmount,
    double? savings,
    DateTime? availabilityCheckAt,
    bool? isAvailable,
    String? notes,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;
    final newTotalPrice = totalPrice ?? (newUnitPrice * newQuantity);
    
    return OrderItem(
      id: id ?? this.id,
      product: product ?? this.product,
      size: size ?? this.size,
      color: color ?? this.color,
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      totalPrice: newTotalPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      savings: savings ?? this.savings,
      availabilityCheckAt: availabilityCheckAt ?? this.availabilityCheckAt,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
    );
  }

  /// Calculate total price with current quantity and unit price
  double calculateTotalPrice() {
    return unitPrice * quantity;
  }

  /// Calculate savings compared to original price
  double calculateSavings() {
    return (product.originalPrice - unitPrice) * quantity;
  }

  /// Check if item can be modified
  bool get canBeModified {
    return isAvailable && quantity > 0;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OrderItem{id: $id, product: ${product.name}, size: $size, color: $color, quantity: $quantity, totalPrice: $totalPrice}';
  }
}

/// Customer information for orders
class CustomerInfo {
  final String name;
  final String email;
  final String phone;
  final String? alternatePhone;
  final Address shippingAddress;
  final Address? billingAddress;
  final bool useBillingForShipping;
  final Map<String, dynamic> preferences;
  final DateTime? lastOrderDate;
  final int totalOrders;
  final String customerTier;

  CustomerInfo({
    required this.name,
    required this.email,
    required this.phone,
    this.alternatePhone,
    required this.shippingAddress,
    this.billingAddress,
    this.useBillingForShipping = false,
    this.preferences = const {},
    this.lastOrderDate,
    this.totalOrders = 0,
    this.customerTier = 'Regular',
  });

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      alternatePhone: json['alternatePhone'] as String?,
      shippingAddress: Address.fromJson(json['shippingAddress'] ?? {}),
      billingAddress: json['billingAddress'] != null 
          ? Address.fromJson(json['billingAddress'] as Map<String, dynamic>)
          : null,
      useBillingForShipping: json['useBillingForShipping'] as bool? ?? false,
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      lastOrderDate: json['lastOrderDate'] != null 
          ? DateTime.parse(json['lastOrderDate'] as String)
          : null,
      totalOrders: json['totalOrders'] as int? ?? 0,
      customerTier: json['customerTier'] as String? ?? 'Regular',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'alternatePhone': alternatePhone,
      'shippingAddress': shippingAddress.toJson(),
      'billingAddress': billingAddress?.toJson(),
      'useBillingForShipping': useBillingForShipping,
      'preferences': preferences,
      'lastOrderDate': lastOrderDate?.toIso8601String(),
      'totalOrders': totalOrders,
      'customerTier': customerTier,
    };
  }

  /// Check if customer is VIP
  bool get isVip => customerTier == 'VIP' || customerTier == 'Premium';
  
  /// Check if customer is new
  bool get isNewCustomer => totalOrders == 0;
}

/// Address class for shipping and billing
class Address {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? landmark;
  final String? apartmentNumber;
  final bool isDefault;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.landmark,
    this.apartmentNumber,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      country: json['country'] as String? ?? '',
      landmark: json['landmark'] as String?,
      apartmentNumber: json['apartmentNumber'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'landmark': landmark,
      'apartmentNumber': apartmentNumber,
      'isDefault': isDefault,
    };
  }

  /// Get full address as string
  String get fullAddress {
    final parts = [street];
    if (apartmentNumber != null) parts.add(apartmentNumber!);
    if (landmark != null) parts.add(landmark!);
    parts.addAll([city, state, postalCode, country]);
    return parts.join(', ');
  }

  /// Check if address is complete
  bool get isComplete {
    return street.isNotEmpty && city.isNotEmpty && 
           state.isNotEmpty && postalCode.isNotEmpty && country.isNotEmpty;
  }
}

/// Payment details for orders
class PaymentDetails {
  final PaymentMethodType method;
  final String? transactionId;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? razorpaySignature;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final DateTime? paidAt;
  final String? failureReason;
  final Map<String, dynamic> metadata;
  final bool isVerified;

  PaymentDetails({
    required this.method,
    this.transactionId,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
    required this.amount,
    this.currency = 'INR',
    this.status = PaymentStatus.pending,
    this.paidAt,
    this.failureReason,
    this.metadata = const {},
    this.isVerified = false,
  });

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    return PaymentDetails(
      method: PaymentMethodType.fromString(json['method'] as String? ?? 'razorpay'),
      transactionId: json['transactionId'] as String?,
      razorpayOrderId: json['razorpayOrderId'] as String?,
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      razorpaySignature: json['razorpaySignature'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'INR',
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      paidAt: json['paidAt'] != null 
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      failureReason: json['failureReason'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.toString().split('.').last,
      'transactionId': transactionId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
      'amount': amount,
      'currency': currency,
      'status': status.toString().split('.').last,
      'paidAt': paidAt?.toIso8601String(),
      'failureReason': failureReason,
      'metadata': metadata,
      'isVerified': isVerified,
    };
  }

  /// Check if payment is successful
  bool get isSuccessful => status == PaymentStatus.succeeded && isVerified;
  
  /// Check if payment failed
  bool get hasFailed => status == PaymentStatus.failed || status == PaymentStatus.cancelled;
  
  /// Check if payment is pending
  bool get isPending => status == PaymentStatus.pending;

  /// Get payment method display name
  String get displayName {
    switch (method) {
      case PaymentMethodType.razorpay:
        return 'Razorpay';
      case PaymentMethodType.stripe:
        return 'Stripe';
      case PaymentMethodType.paypal:
        return 'PayPal';
      case PaymentMethodType.cod:
        return 'Cash on Delivery';
      case PaymentMethodType.bank_transfer:
        return 'Bank Transfer';
    }
  }
}

/// Shipping information for orders
class ShippingInfo {
  final ShippingMethod method;
  final double cost;
  final String? carrier;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? shippedAt;
  final DateTime? estimatedDeliveryDate;
  final int? estimatedDeliveryDays;
  final Address? deliveryAddress;
  final String? specialInstructions;
  final ShippingStatus status;
  final List<String> statusHistory;

  ShippingInfo({
    required this.method,
    required this.cost,
    this.carrier,
    this.trackingNumber,
    this.trackingUrl,
    this.shippedAt,
    this.estimatedDeliveryDate,
    this.estimatedDeliveryDays,
    this.deliveryAddress,
    this.specialInstructions,
    this.status = ShippingStatus.pending,
    this.statusHistory = const [],
  });

  factory ShippingInfo.fromJson(Map<String, dynamic> json) {
    return ShippingInfo(
      method: ShippingMethod.fromString(json['method'] as String? ?? 'standard'),
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      carrier: json['carrier'] as String?,
      trackingNumber: json['trackingNumber'] as String?,
      trackingUrl: json['trackingUrl'] as String?,
      shippedAt: json['shippedAt'] != null 
          ? DateTime.parse(json['shippedAt'] as String)
          : null,
      estimatedDeliveryDate: json['estimatedDeliveryDate'] != null 
          ? DateTime.parse(json['estimatedDeliveryDate'] as String)
          : null,
      estimatedDeliveryDays: json['estimatedDeliveryDays'] as int?,
      deliveryAddress: json['deliveryAddress'] != null 
          ? Address.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      specialInstructions: json['specialInstructions'] as String?,
      status: ShippingStatus.fromString(json['status'] as String? ?? 'pending'),
      statusHistory: (json['statusHistory'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'method': method.toString().split('.').last,
      'cost': cost,
      'carrier': carrier,
      'trackingNumber': trackingNumber,
      'trackingUrl': trackingUrl,
      'shippedAt': shippedAt?.toIso8601String(),
      'estimatedDeliveryDate': estimatedDeliveryDate?.toIso8601String(),
      'estimatedDeliveryDays': estimatedDeliveryDays,
      'deliveryAddress': deliveryAddress?.toJson(),
      'specialInstructions': specialInstructions,
      'status': status.toString().split('.').last,
      'statusHistory': statusHistory,
    };
  }

  /// Check if order has been shipped
  bool get isShipped => status == ShippingStatus.shipped || status == ShippingStatus.delivered;
  
  /// Check if order has been delivered
  bool get isDelivered => status == ShippingStatus.delivered;
  
  /// Check if tracking is available
  bool get hasTracking => trackingNumber != null && trackingNumber!.isNotEmpty;

  /// Get estimated delivery date or calculate from shipping date
  DateTime? getEstimatedDeliveryDate() {
    if (estimatedDeliveryDate != null) return estimatedDeliveryDate;
    if (estimatedDeliveryDays != null && shippedAt != null) {
      return shippedAt!.add(Duration(days: estimatedDeliveryDays!));
    }
    return null;
  }
}

/// Order metadata for additional information
class OrderMetadata {
  final String? source; // web, mobile, api
  final String? affiliateCode;
  final Map<String, dynamic> customFields;
  final String? promoCode;
  final double? discountAmount;
  final String? giftMessage;
  final bool isGift;
  final String? orderNotes;
  final Map<String, dynamic> analytics;
  final String? createdBy; // userId or system
  final List<String> tags;

  OrderMetadata({
    this.source,
    this.affiliateCode,
    this.customFields = const {},
    this.promoCode,
    this.discountAmount,
    this.giftMessage,
    this.isGift = false,
    this.orderNotes,
    this.analytics = const {},
    this.createdBy,
    this.tags = const [],
  });

  factory OrderMetadata.fromJson(Map<String, dynamic> json) {
    return OrderMetadata(
      source: json['source'] as String?,
      affiliateCode: json['affiliateCode'] as String?,
      customFields: Map<String, dynamic>.from(json['customFields'] ?? {}),
      promoCode: json['promoCode'] as String?,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      giftMessage: json['giftMessage'] as String?,
      isGift: json['isGift'] as bool? ?? false,
      orderNotes: json['orderNotes'] as String?,
      analytics: Map<String, dynamic>.from(json['analytics'] ?? {}),
      createdBy: json['createdBy'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'affiliateCode': affiliateCode,
      'customFields': customFields,
      'promoCode': promoCode,
      'discountAmount': discountAmount,
      'giftMessage': giftMessage,
      'isGift': isGift,
      'orderNotes': orderNotes,
      'analytics': analytics,
      'createdBy': createdBy,
      'tags': tags,
    };
  }

  /// Check if order has promo code
  bool get hasPromoCode => promoCode != null && promoCode!.isNotEmpty;
  
  /// Check if order is a gift
  bool get isGiftOrder => isGift;
  
  /// Check if order has discount
  bool get hasDiscount => (discountAmount ?? 0) > 0;

  /// Get all custom field values
  Map<String, dynamic> getAllCustomFields() => Map.from(customFields);
  
  /// Get analytics data
  Map<String, dynamic> getAnalyticsData() => Map.from(analytics);
}

/// Enhanced OrderStatus enum with comprehensive status tracking
enum OrderStatus {
  orderPlaced,
  paymentConfirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  returnRequested,
  refunded;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'order_placed':
        return OrderStatus.orderPlaced;
      case 'payment_confirmed':
        return OrderStatus.paymentConfirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'return_requested':
        return OrderStatus.returnRequested;
      case 'refunded':
        return OrderStatus.refunded;
      default:
        return OrderStatus.orderPlaced;
    }
  }

  /// Get display name for status
  String get displayName {
    switch (this) {
      case OrderStatus.orderPlaced:
        return 'Order Placed';
      case OrderStatus.paymentConfirmed:
        return 'Payment Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returnRequested:
        return 'Return Requested';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  /// Get next possible status
  OrderStatus? get nextStatus {
    switch (this) {
      case OrderStatus.orderPlaced:
        return OrderStatus.paymentConfirmed;
      case OrderStatus.paymentConfirmed:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  /// Check if status is active (not completed or cancelled)
  bool get isActiveStatus {
    return [
      OrderStatus.orderPlaced,
      OrderStatus.paymentConfirmed,
      OrderStatus.processing,
      OrderStatus.shipped,
    ].contains(this);
  }

  /// Check if status is completed
  bool get isCompletedStatus {
    return this == OrderStatus.delivered;
  }

  /// Check if status is terminal (no further updates possible)
  bool get isTerminalStatus {
    return [
      OrderStatus.delivered,
      OrderStatus.cancelled,
      OrderStatus.refunded,
    ].contains(this);
  }
}

/// Payment method types
enum PaymentMethodType {
  razorpay,
  stripe,
  paypal,
  cod,
  bank_transfer;

  static PaymentMethodType fromString(String method) {
    switch (method.toLowerCase()) {
      case 'razorpay':
        return PaymentMethodType.razorpay;
      case 'stripe':
        return PaymentMethodType.stripe;
      case 'paypal':
        return PaymentMethodType.paypal;
      case 'cod':
        return PaymentMethodType.cod;
      case 'bank_transfer':
        return PaymentMethodType.bank_transfer;
      default:
        return PaymentMethodType.razorpay;
    }
  }
}

/// Payment statuses
enum PaymentStatus {
  pending,
  succeeded,
  failed,
  cancelled,
  refunded;

  static PaymentStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
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
}

/// Shipping methods
enum ShippingMethod {
  standard,
  express,
  overnight,
  pickup,
  digitalDelivery;

  static ShippingMethod fromString(String method) {
    switch (method.toLowerCase()) {
      case 'standard':
        return ShippingMethod.standard;
      case 'express':
        return ShippingMethod.express;
      case 'overnight':
        return ShippingMethod.overnight;
      case 'pickup':
        return ShippingMethod.pickup;
      case 'digital_delivery':
        return ShippingMethod.digitalDelivery;
      default:
        return ShippingMethod.standard;
    }
  }

  /// Get estimated delivery days for method
  int? get estimatedDays {
    switch (this) {
      case ShippingMethod.standard:
        return 5;
      case ShippingMethod.express:
        return 2;
      case ShippingMethod.overnight:
        return 1;
      case ShippingMethod.pickup:
        return 0;
      case ShippingMethod.digitalDelivery:
        return 0;
    }
  }
}

/// Shipping status
enum ShippingStatus {
  pending,
  processing,
  shipped,
  inTransit,
  outForDelivery,
  delivered,
  failedDelivery,
  returned;

  static ShippingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ShippingStatus.pending;
      case 'processing':
        return ShippingStatus.processing;
      case 'shipped':
        return ShippingStatus.shipped;
      case 'in_transit':
        return ShippingStatus.inTransit;
      case 'out_for_delivery':
        return ShippingStatus.outForDelivery;
      case 'delivered':
        return ShippingStatus.delivered;
      case 'failed_delivery':
        return ShippingStatus.failedDelivery;
      case 'returned':
        return ShippingStatus.returned;
      default:
        return ShippingStatus.pending;
    }
  }
}