/// Order Management System Demo
/// 
/// This file demonstrates the complete order management system implementation
/// showing all features: order creation, payment verification, status tracking,
/// and analytics.
import 'dart:convert';
import 'api_service.dart';
import 'mock_order_service.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';

/// Demo class showcasing order management features
class OrderManagementDemo {
  final ApiService _apiService = ApiService();
  
  /// Run complete demo of order management system
  Future<void> runFullDemo() async {
    print('🚀 Starting Order Management System Demo\n');
    
    // Initialize mock data
    MockOrderService.initializeMockOrders();
    
    // Demo 1: Order Creation
    await demoOrderCreation();
    
    // Demo 2: Payment Verification
    await demoPaymentVerification();
    
    // Demo 3: Order Status Management
    await demoOrderStatusManagement();
    
    // Demo 4: Order Analytics
    await demoOrderAnalytics();
    
    // Demo 5: Order Search and Filtering
    await demoOrderSearchAndFiltering();
    
    // Demo 6: Order Export
    await demoOrderExport();
    
    // Demo 7: Complete Order Flow
    await demoCompleteOrderFlow();
    
    print('\n✅ Order Management System Demo Completed!');
  }
  
  /// Demo: Order Creation Endpoint
  Future<void> demoOrderCreation() async {
    print('📦 Demo 1: Order Creation');
    print('=' * 50);
    
    // Create sample order data
    final orderData = _createSampleOrderData();
    
    try {
      final response = await _apiService.createOrder(orderData);
      
      if (response.isSuccess) {
        final order = response.data!;
        print('✅ Order created successfully!');
        print('Order ID: ${order.id}');
        print('Customer: ${order.customer.name}');
        print('Total Amount: ₹${order.totalAmount}');
        print('Status: ${order.status.displayName}');
        print('Items: ${order.items.length}');
        print('Razorpay Order ID: ${order.payment.razorpayOrderId}');
      } else {
        print('❌ Order creation failed: ${response.error}');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
    }
    
    print('');
  }
  
  /// Demo: Payment Verification System
  Future<void> demoPaymentVerification() async {
    print('💳 Demo 2: Payment Verification');
    print('=' * 50);
    
    try {
      // Simulate Razorpay payment verification
      final verificationResult = await _apiService.verifyPaymentSignature(
        orderId: 'ORD_123',
        razorpayOrderId: 'order_123_razorpay_12345',
        razorpayPaymentId: 'pay_123_razorpay',
        razorpaySignature: 'valid_signature_hash_12345',
        expectedAmount: 2999.00,
      );
      
      if (verificationResult.isSuccess) {
        final result = verificationResult.data!;
        print('✅ Payment verified successfully!');
        print('Order ID: ${result.orderId}');
        print('Payment ID: ${result.paymentId}');
        print('Amount: ₹${result.amount}');
        print('Currency: ${result.currency}');
      } else {
        print('❌ Payment verification failed: ${verificationResult.error}');
      }
      
      // Demo Razorpay webhook handling
      print('\n📡 Testing Razorpay Webhook Handler...');
      final webhookPayload = RazorpayWebhookPayload(
        event: 'payment.captured',
        payload: {
          'payment': {
            'id': 'pay_123',
            'order_id': 'order_123_razorpay_12345',
            'amount': 299900, // Amount in paise
            'currency': 'INR',
            'status': 'captured',
            'method': 'card',
            'description': 'Payment for order ORD_123',
            'notes': {
              'order_id': 'ORD_123',
            },
            'signature': 'webhook_signature_12345',
          }
        },
        createdAt: DateTime.now().toIso8601String(),
      );
      
      final webhookResult = await _apiService.handleRazorpayWebhook(webhookPayload);
      
      if (webhookResult.isSuccess) {
        print('✅ Webhook processed successfully!');
        print('Verification Result: ${webhookResult.data!.isValid}');
      } else {
        print('❌ Webhook processing failed: ${webhookResult.error}');
      }
      
    } catch (e) {
      print('❌ Error in payment verification: $e');
    }
    
    print('');
  }
  
  /// Demo: Order Status Management
  Future<void> demoOrderStatusManagement() async {
    print('📊 Demo 3: Order Status Management');
    print('=' * 50);
    
    // Get existing orders
    final ordersResponse = await _apiService.getOrders(page: 1, perPage: 5);
    
    if (ordersResponse.isSuccess) {
      final orders = ordersResponse.data!.orders;
      
      if (orders.isNotEmpty) {
        final order = orders.first;
        print('Sample Order: ${order.id}');
        print('Current Status: ${order.status.displayName}');
        print('Progress: ${order.progressPercentage}%');
        print('Can be cancelled: ${order.canBeCancelled}');
        print('Estimated delivery: ${order.estimatedDeliveryDate?.toString().split(' ')[0] ?? 'Not available'}');
        
        // Demo status update
        print('\n🔄 Updating order status to Processing...');
        final updatedOrderResponse = await _apiService.updateOrderStatus(
          order.id, 
          OrderStatus.processing
        );
        
        if (updatedOrderResponse.isSuccess) {
          final updatedOrder = updatedOrderResponse.data!;
          print('✅ Status updated successfully!');
          print('New Status: ${updatedOrder.status.displayName}');
          print('Progress: ${updatedOrder.progressPercentage}%');
          print('Updated at: ${updatedOrder.updatedAt}');
        }
        
        // Demo order history
        print('\n📋 Getting order status history...');
        final historyResponse = await _apiService.getOrderStatusHistory(order.id);
        
        if (historyResponse.isSuccess) {
          final history = historyResponse.data!;
          print('Status History:');
          for (final entry in history) {
            print('  • ${entry['status']} - ${entry['description']}');
            if (entry['timestamp'] != null) {
              print('    📅 ${entry['timestamp'].toString().split('T')[0]}');
            }
          }
        }
        
        // Demo order cancellation
        if (order.canBeCancelled) {
          print('\n❌ Cancelling order...');
          final cancelledOrderResponse = await _apiService.cancelOrder(
            order.id, 
            'Customer request - demo purposes'
          );
          
          if (cancelledOrderResponse.isSuccess) {
            final cancelledOrder = cancelledOrderResponse.data!;
            print('✅ Order cancelled successfully!');
            print('Status: ${cancelledOrder.status.displayName}');
          }
        }
      }
    }
    
    print('');
  }
  
  /// Demo: Order Analytics
  Future<void> demoOrderAnalytics() async {
    print('📈 Demo 4: Order Analytics');
    print('=' * 50);
    
    try {
      final analyticsResponse = await _apiService.getOrderAnalytics(
        fromDate: DateTime.now().subtract(Duration(days: 30)),
      );
      
      if (analyticsResponse.isSuccess) {
        final analytics = analyticsResponse.data!;
        
        print('📊 Order Analytics (Last 30 Days):');
        print('Total Orders: ${analytics['totalOrders']}');
        print('Total Revenue: ₹${analytics['totalRevenue'].toStringAsFixed(2)}');
        print('Average Order Value: ₹${analytics['averageOrderValue'].toStringAsFixed(2)}');
        print('Delivered Orders: ${analytics['deliveredOrders']}');
        print('Cancelled Orders: ${analytics['cancelledOrders']}');
        print('Delivery Rate: ${analytics['deliveryRate'].toStringAsFixed(1)}%');
        print('Cancellation Rate: ${analytics['cancellationRate'].toStringAsFixed(1)}%');
        
        print('\n📈 Status Distribution:');
        final statusDist = analytics['statusDistribution'] as Map<String, dynamic>;
        statusDist.forEach((status, count) {
          final displayStatus = status.replaceAll('_', ' ').split(' ').map((word) => 
            word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
          print('  • $displayStatus: $count');
        });
      } else {
        print('❌ Failed to get analytics: ${analyticsResponse.error}');
      }
      
    } catch (e) {
      print('❌ Error getting analytics: $e');
    }
    
    print('');
  }
  
  /// Demo: Order Search and Filtering
  Future<void> demoOrderSearchAndFiltering() async {
    print('🔍 Demo 5: Order Search and Filtering');
    print('=' * 50);
    
    // Demo filtering by status
    print('📋 Getting shipped orders...');
    final shippedOrdersResponse = await _apiService.getOrders(
      status: OrderStatus.shipped,
      page: 1,
      perPage: 10,
    );
    
    if (shippedOrdersResponse.isSuccess) {
      final response = shippedOrdersResponse.data!;
      print('Shipped Orders Found: ${response.orders.length}');
      
      for (final order in response.orders.take(3)) {
        print('  • ${order.id} - ${order.customer.name} - ₹${order.totalAmount}');
        if (order.shipping.trackingNumber != null) {
          print('    📦 Tracking: ${order.shipping.trackingNumber}');
        }
      }
    }
    
    // Demo search functionality
    print('\n🔎 Searching for orders containing "blue"...');
    final searchResults = MockOrderService.searchOrders('blue');
    print('Search Results: ${searchResults.length} orders found');
    
    for (final order in searchResults.take(3)) {
      print('  • ${order.id} - ${order.customer.name}');
      final blueItems = order.items.where((item) => 
        item.color?.toLowerCase().contains('blue') == true ||
        item.product.name.toLowerCase().contains('blue') == true
      ).toList();
      
      if (blueItems.isNotEmpty) {
        print('    🔵 Blue items: ${blueItems.length}');
      }
    }
    
    // Demo advanced filtering
    print('\n📅 Getting orders from last 7 days...');
    final recentOrdersResponse = await _apiService.getOrders(
      fromDate: DateTime.now().subtract(Duration(days: 7)),
      page: 1,
      perPage: 5,
    );
    
    if (recentOrdersResponse.isSuccess) {
      final response = recentOrdersResponse.data!;
      print('Recent Orders: ${response.orders.length}');
      print('Summary: ${response.summary}');
    }
    
    print('');
  }
  
  /// Demo: Order Export
  Future<void> demoOrderExport() async {
    print('📤 Demo 6: Order Export');
    print('=' * 50);
    
    try {
      // Export as JSON
      print('📄 Exporting delivered orders as JSON...');
      final jsonExportResponse = await _apiService.exportOrders(
        status: OrderStatus.delivered,
        format: 'json',
      );
      
      if (jsonExportResponse.isSuccess) {
        final jsonData = jsonExportResponse.data!;
        print('✅ JSON export successful!');
        print('Data length: ${jsonData.length} characters');
        
        // Parse and show sample
        final ordersJson = jsonDecode(jsonData) as List;
        print('Exported ${ordersJson.length} orders');
        
        if (ordersJson.isNotEmpty) {
          final sampleOrder = ordersJson.first;
          print('Sample order ID: ${sampleOrder['id']}');
        }
      }
      
      // Export as CSV
      print('\n📊 Exporting all orders as CSV...');
      final csvExportResponse = await _apiService.exportOrders(
        format: 'csv',
      );
      
      if (csvExportResponse.isSuccess) {
        final csvData = csvExportResponse.data!;
        print('✅ CSV export successful!');
        print('Data length: ${csvData.length} characters');
        
        // Show CSV headers
        final lines = csvData.split('\n');
        if (lines.isNotEmpty) {
          print('CSV Headers: ${lines.first}');
        }
      }
      
    } catch (e) {
      print('❌ Error exporting orders: $e');
    }
    
    print('');
  }
  
  /// Demo: Complete Order Flow
  Future<void> demoCompleteOrderFlow() async {
    print('🔄 Demo 7: Complete Order Flow');
    print('=' * 50);
    
    print('Simulating complete order lifecycle...\n');
    
    // Step 1: Create order
    print('1️⃣ Creating new order...');
    final orderData = _createSampleOrderData();
    final createResponse = await _apiService.createOrder(orderData);
    
    if (!createResponse.isSuccess) {
      print('❌ Order creation failed: ${createResponse.error}');
      return;
    }
    
    final order = createResponse.data!;
    print('✅ Order created: ${order.id}');
    print('Status: ${order.status.displayName}');
    print('Amount: ₹${order.totalAmount}');
    
    // Step 2: Verify payment
    print('\n2️⃣ Verifying payment...');
    final paymentVerification = await _apiService.verifyPaymentSignature(
      orderId: order.id,
      razorpayOrderId: order.payment.razorpayOrderId!,
      razorpayPaymentId: 'pay_${order.id.toLowerCase()}',
      razorpaySignature: 'verified_signature_${order.id}',
      expectedAmount: order.totalAmount,
    );
    
    if (paymentVerification.isSuccess) {
      print('✅ Payment verified');
      
      // Step 3: Update status to processing
      print('\n3️⃣ Processing order...');
      final processingResponse = await _apiService.updateOrderStatus(
        order.id, 
        OrderStatus.processing
      );
      
      if (processingResponse.isSuccess) {
        print('✅ Order in processing');
        
        // Step 4: Ship order
        print('\n4️⃣ Shipping order...');
        final shippingResponse = await _apiService.updateOrderStatus(
          order.id, 
          OrderStatus.shipped
        );
        
        if (shippingResponse.isSuccess) {
          print('✅ Order shipped');
          
          // Step 5: Deliver order
          print('\n5️⃣ Delivering order...');
          final deliveryResponse = await _apiService.updateOrderStatus(
            order.id, 
            OrderStatus.delivered
          );
          
          if (deliveryResponse.isSuccess) {
            print('✅ Order delivered successfully!');
            print('Order lifecycle completed! 🎉');
          }
        }
      }
    } else {
      print('❌ Payment verification failed: ${paymentVerification.error}');
    }
    
    // Show final order status
    final finalOrder = MockOrderService.getOrderById(order.id);
    if (finalOrder != null) {
      print('\n📊 Final Order Summary:');
      print('Order ID: ${finalOrder.id}');
      print('Final Status: ${finalOrder.status.displayName}');
      print('Progress: ${finalOrder.progressPercentage}%');
      print('Completed: ${finalOrder.completedAt?.toString().split(' ')[0] ?? 'Not completed'}');
      print('Total Items: ${finalOrder.totalItemsCount}');
      print('Customer Tier: ${finalOrder.customer.customerTier}');
    }
    
    print('');
  }
  
  /// Create sample order data for demo
  Map<String, dynamic> _createSampleOrderData() {
    return {
      'userId': 'demo_user_123',
      'items': [
        {
          'product': {
            'id': 'prod_001',
            'name': 'Premium Cotton T-Shirt',
            'currentPrice': 1299.0,
            'originalPrice': 1599.0,
            'category': 'Tops',
            'subcategory': 'T-Shirts',
            'images': ['image1.jpg', 'image2.jpg'],
            'primaryImage': 'image1.jpg',
            'availableSizes': ['S', 'M', 'L', 'XL'],
            'availableColors': ['Blue', 'White', 'Black'],
            'isAvailable': true,
            'isFeatured': true,
            'tags': ['cotton', 'premium', 'casual'],
            'rating': {'average': 4.5, 'count': 150},
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-01T00:00:00Z',
            'metadata': {'brand': 'FashionBrand', 'material': '100% Cotton'},
          },
          'size': 'M',
          'color': 'Blue',
          'quantity': 2,
        },
        {
          'product': {
            'id': 'prod_002',
            'name': 'Slim Fit Jeans',
            'currentPrice': 1999.0,
            'originalPrice': 2499.0,
            'category': 'Bottoms',
            'subcategory': 'Jeans',
            'images': ['jeans1.jpg', 'jeans2.jpg'],
            'primaryImage': 'jeans1.jpg',
            'availableSizes': ['28', '30', '32', '34', '36'],
            'availableColors': ['Dark Blue', 'Black', 'Light Blue'],
            'isAvailable': true,
            'isFeatured': false,
            'tags': ['denim', 'slim-fit', 'casual'],
            'rating': {'average': 4.2, 'count': 89},
            'createdAt': '2024-01-01T00:00:00Z',
            'updatedAt': '2024-01-01T00:00:00Z',
            'metadata': {'brand': 'DenimCo', 'material': 'Stretch Denim'},
          },
          'size': '32',
          'color': 'Dark Blue',
          'quantity': 1,
        }
      ],
      'customer': {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '+911234567890',
        'shippingAddress': {
          'street': '123 Demo Street, Apartment 4B',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'postalCode': '400001',
          'country': 'India',
          'landmark': 'Near Demo Mall',
          'isDefault': true,
        },
        'customerTier': 'VIP',
        'totalOrders': 5,
      },
      'paymentMethod': 'razorpay',
      'source': 'web',
      'promoCode': 'VIP10',
      'isGift': false,
    };
  }
}

/// Main function to run the demo
Future<void> main() async {
  final demo = OrderManagementDemo();
  await demo.runFullDemo();
}

/// Helper class for generating realistic mock data
class MockDataGenerator {
  static final List<String> customerNames = [
    'Alice Johnson', 'Bob Smith', 'Carol Williams', 'David Brown',
    'Emma Davis', 'Frank Miller', 'Grace Wilson', 'Henry Moore',
    'Ivy Taylor', 'Jack Anderson', 'Kate Thomas', 'Liam Jackson'
  ];
  
  static final List<String> productNames = [
    'Premium Cotton T-Shirt', 'Slim Fit Jeans', 'Summer Dress',
    'Casual Hoodie', 'Formal Shirt', 'Yoga Leggings',
    'Leather Jacket', 'Silk Blouse', 'Denim Shorts', 'Wool Sweater'
  ];
  
  static String getRandomCustomerName() {
    return customerNames[DateTime.now().millisecond % customerNames.length];
  }
  
  static String getRandomProductName() {
    return productNames[DateTime.now().millisecond % productNames.length];
  }
  
  static double getRandomPrice() {
    return (500 + (DateTime.now().millisecond % 2000)).toDouble();
  }
  
  static String getRandomOrderId() {
    return 'ORD_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }
}
