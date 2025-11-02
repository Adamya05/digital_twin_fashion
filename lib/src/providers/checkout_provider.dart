/// Provider for CheckoutService
/// 
/// Provides checkout flow management for the entire app.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/checkout_service.dart';
import '../../services/payment_service.dart';

/// Provider for PaymentService instance
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

/// Provider for CheckoutService instance
final checkoutServiceProvider = StateNotifierProvider<CheckoutService, CheckoutState>((ref) {
  final paymentService = ref.read(paymentServiceProvider);
  return CheckoutService(paymentService);
});

/// Provider for current cart total
final cartTotalProvider = Provider<double>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.totalAmount;
});

/// Provider for current step in checkout
final checkoutStepProvider = Provider<CheckoutStep>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.step;
});

/// Provider for checkout progress
final checkoutProgressProvider = Provider<double>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.progressPercentage;
});

/// Provider for payment recommendations
final paymentRecommendationsProvider = Provider<List<String>>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.getPaymentRecommendations();
});

/// Provider for order details
final orderDetailsProvider = Provider<Order?>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.createdOrder;
});

/// Provider for checkout validity
final checkoutValidityProvider = Provider<bool>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.canProceed;
});

/// Provider for applied discount
final appliedDiscountProvider = Provider<DiscountInfo?>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.appliedDiscount;
});

/// Provider for selected shipping address
final selectedAddressProvider = Provider<ShippingAddress?>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.selectedAddress;
});

/// Provider for checkout items
final checkoutItemsProvider = Provider<List<CartItem>>((ref) {
  final checkoutState = ref.watch(checkoutServiceProvider);
  return checkoutState.items;
});
