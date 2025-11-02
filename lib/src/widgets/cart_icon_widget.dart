/// Cart Icon Widget with Item Count Badge
/// 
/// Displays a shopping cart icon with a badge showing the number of items in cart.
/// Includes animations for adding/removing items and haptic feedback.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/cart_provider.dart';

class CartIconWidget extends ConsumerWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;
  final bool showBadge;

  const CartIconWidget({
    super.key,
    this.onTap,
    this.iconColor,
    this.iconSize,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.itemCount;

    return Stack(
      children: [
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            onTap?.call() ?? Navigator.of(context).pushNamed('/cart');
          },
          icon: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: itemCount > 0 ? 1.1 : 1.0,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: iconColor ?? Theme.of(context).iconTheme.color,
              size: iconSize ?? 24,
            ),
          ),
        ),
        
        if (showBadge && itemCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              scale: 1.0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    itemCount > 99 ? '99+' : itemCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Cart FAB (Floating Action Button) with quick access
class CartFAB extends ConsumerWidget {
  final VoidCallback? onPressed;

  const CartFAB({
    super.key,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final itemCount = cartState.itemCount;

    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.heavyImpact();
        onPressed?.call() ?? Navigator.of(context).pushNamed('/cart');
      },
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.shopping_cart),
          if (itemCount > 0)
            Positioned(
              right: -8,
              top: -8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    itemCount > 9 ? '9+' : itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
      label: Text(
        itemCount > 0 
          ? 'Cart (${itemCount})'
          : 'Cart',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Quick Add to Cart Button with Animation
class QuickAddToCartButton extends ConsumerWidget {
  final String productId;
  final VoidCallback? onSuccess;
  final VoidCallback? onError;
  final Widget? child;
  final ButtonSize size;

  const QuickAddToCartButton({
    super.key,
    required this.productId,
    this.onSuccess,
    this.onError,
    this.child,
    this.size = ButtonSize.small,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.read(cartProvider.notifier);

    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        
        try {
          // TODO: Get product details from product provider
          // For now, we'll just add a placeholder
          final cartItem = CartItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            product: Product(
              id: productId,
              name: 'Sample Product',
              description: 'Sample description',
              originalPrice: 1000.0,
              currentPrice: 1000.0,
              images: [],
              primaryImage: '',
              category: '',
              subcategory: '',
              tags: [],
              sizeInfo: const ProductSizeInfo(),
              vendor: const ProductVendor(),
              pricing: const ProductPricing(),
              compatibility: const ProductCompatibility(),
              shipping: const ProductShipping(),
              inventory: const ProductInventory(),
              rating: const ProductRating(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              metadata: const ProductMetadata(),
            ),
            quantity: 1,
            addedAt: DateTime.now(),
          );
          
          cartNotifier.addMultipleItems([cartItem]);
          onSuccess?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Added to cart!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          onError?.call();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.small ? 12 : 16,
          vertical: size == AppButtonSize.small ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child ?? Icon(
          Icons.add_shopping_cart,
          size: size == AppButtonSize.small ? 16 : 20,
          color: Colors.white,
        ),
      ),
    );
  }
}