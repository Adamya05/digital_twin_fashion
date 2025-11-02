/// Enhanced Swipe Feed Screen
/// 
/// Main product browsing interface featuring Tinder-style card stack with gesture recognition,
/// visual feedback, persistence, and smart features for fashion discovery.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../../providers/feed_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/closet_provider.dart';
import '../../models/product_model.dart';
import '../../models/swipe_history_model.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/tutorial_overlay.dart';
import '../../widgets/swipe_tutorial_overlay.dart';
import '../../widgets/app_button.dart';
import 'product_detail.dart';

class SwipeFeed extends ConsumerStatefulWidget {
  const SwipeFeed({super.key});

  @override
  ConsumerState<SwipeFeed> createState() => _SwipeFeedState();
}

class _SwipeFeedState extends ConsumerState<SwipeFeed>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  bool _showTutorial = true;
  bool _canUndo = false;
  DateTime? _lastSwipeTime;
  final CardSwiperController _cardSwiperController = CardSwiperController();
  
  // Card stack configuration
  static const int maxCards = 3; // Show 3 cards ahead for smooth experience
  static const double swipeThreshold = 0.3; // 30% of card width for decision
  static const double velocityThreshold = 3000.0; // px/sec for quick swipe
  static const double superLikeThreshold = -0.4; // Upward swipe threshold

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    // Load initial products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedProvider.notifier).refresh();
      _updateUndoState();
      _fadeController.forward();
    });

    // Keyboard shortcuts for desktop/web
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _cardSwiperController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    // Add keyboard shortcuts for testing on desktop/web
    if (MediaQuery.of(context).size.width > 600) {
      // Desktop/Web shortcuts - left/right arrows for swiping, up arrow for super like
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(FocusNode());
      });
    }
  }

  void _updateUndoState() async {
    final canUndo = await ref.read(feedProvider.notifier).canUndo();
    setState(() {
      _canUndo = canUndo;
    });
  }

  Future<void> _onCardSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
  ) async {
    if (currentIndex == null) return;
    
    final feedState = ref.read(feedProvider);
    if (feedState.products.isEmpty) return;

    final swipedProduct = feedState.products[previousIndex];
    
    // Determine swipe action based on direction
    SwipeAction action;
    switch (direction) {
      case CardSwiperDirection.left:
        action = SwipeAction.dislike;
        break;
      case CardSwiperDirection.right:
        action = SwipeAction.like;
        break;
      case CardSwiperDirection.top:
        action = SwipeAction.superLike;
        break;
      case CardSwiperDirection.bottom:
        action = SwipeAction.skip;
        break;
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Handle the swipe action
    await ref.read(feedProvider.notifier).swipeProduct(
      product: swipedProduct,
      action: action,
      velocity: 1000.0, // Default velocity for button swipes
    );

    // Special handling for closet saving on right swipe (like)
    if (direction == CardSwiperDirection.right) {
      await _addToCloset(swipedProduct);
    }

    // Show contextual feedback
    _showSwipeFeedback(action, swipedProduct);

    // Update undo state
    _updateUndoState();

    // Trigger card stack animation
    _animateCardStack();
  }

  void _animateCardStack() {
    _slideController.forward().then((_) {
      _slideController.reverse();
    });
  }

  void _loadMoreProducts() {
    ref.read(feedProvider.notifier).loadMoreProducts();
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final cartState = ref.watch(cartProvider);
    final closetState = ref.watch(closetProvider);
    
    Widget content = Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(cartState, closetState),
                Expanded(
                  child: _buildSwipeContent(feedState),
                ),
                _buildBottomNavigation(),
              ],
            ),
            // Keyboard shortcuts overlay for desktop/web
            if (MediaQuery.of(context).size.width > 600)
              Positioned.fill(
                child: RawKeyboardListener(
                  focusNode: FocusNode(),
                  onKey: (event) {
                    if (event is RawKeyDownEvent) {
                      final feedState = ref.read(feedProvider);
                      if (feedState.products.isEmpty) return;

                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        _cardSwiperController.swipe(CardSwiperDirection.left);
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        _cardSwiperController.swipe(CardSwiperDirection.right);
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _cardSwiperController.swipe(CardSwiperDirection.top);
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _cardSwiperController.swipe(CardSwiperDirection.bottom);
                      }
                    }
                  },
                  child: Container(),
                ),
              ),
          ],
        ),
      ),
    );

    // Handle tutorial overlay
    if (_showTutorial) {
      return SwipeTutorialOverlay(
        onDismiss: () => setState(() => _showTutorial = false),
        child: content,
      );
    }

    return content;
  }

  Widget _buildHeader(CartState cartState, ClosetState closetState) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1B1E),
                  ),
                ),
                Text(
                  '${closetState.closetItems.length} items in closet • Swipe right to save',
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          if (_canUndo)
            _buildUndoButton(),
          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF6366F1),
              size: 24,
            ),
            onPressed: () {
              ref.read(feedProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(
                  Icons.checkroom,
                  color: Color(0xFF6366F1),
                  size: 24,
                ),
                if (ref.read(closetProvider).unreadNotificationCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        ref.read(closetProvider).unreadNotificationCount > 9 
                            ? '9+' 
                            : ref.read(closetProvider).unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: _navigateToCloset,
            tooltip: 'My Closet',
          ),
        ],
      ),
    );
  }

  Widget _buildUndoButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canUndo ? _handleUndo : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.undo,
                  color: const Color(0xFF6366F1),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Undo',
                  style: TextStyle(
                    color: const Color(0xFF6366F1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeContent(FeedState feedState) {
    if (feedState.isLoading && feedState.products.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (feedState.error != null) {
      return ErrorState(
        error: feedState.error!,
        onRetry: () {
          ref.read(feedProvider.notifier).clearError();
          ref.read(feedProvider.notifier).refresh();
        },
      );
    }

    if (feedState.products.isEmpty) {
      return const EmptyState(
        title: 'No more products',
        subtitle: 'You\'ve seen all products. Check back later!',
        icon: Icons.fashion,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        // Infinite scroll trigger
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent * 0.8) {
          if (!feedState.isLoadingMore && !feedState.isLoading) {
            _loadMoreProducts();
          }
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          await ref.read(feedProvider.notifier).refresh();
        },
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Main swipe area with flutter_card_swiper
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: CardSwiper(
                  controller: _cardSwiperController,
                  cardsCount: feedState.products.length,
                  cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                    final product = feedState.products[index];
                    final isTopCard = index == 0;
                    
                    // Calculate scale for card stack effect (cards behind scale down)
                    final scale = 1.0 - (index * 0.03).clamp(0.0, 0.15);
                    final translateY = -index * 8.0;
                    
                    return AnimatedBuilder(
                      animation: _slideController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: _slideAnimation.value + Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale * (1.0 + _slideController.value * 0.02),
                            child: GestureDetector(
                              onTap: isTopCard ? () => _navigateToProductDetail(product) : null,
                              child: _buildProductCard(product),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  onSwipe: _onCardSwipe,
                  onUndo: _onUndo,
                  // Swipe thresholds
                  threshold: swipeThreshold,
                  // Max cards in stack (shows cards ahead for smooth experience)
                  maxStack: maxCards,
                  // Rotation animation settings
                  rotationConstraint: const RotationConstraint.noRotation(),
                  // Scale down cards behind
                  scaleConstraint: const ScaleConstraint.noScale(),
                  // Back card scale for stack effect
                  backCardScale: 0.85,
                  // Animation duration
                  duration: const Duration(milliseconds: 300),
                  // Allowed swipe directions
                  allowedSwipeDirections: const [
                    CardSwiperDirection.left,
                    CardSwiperDirection.right,
                    CardSwiperDirection.top,
                    CardSwipeDirection.bottom,
                  ],
                  // Enable overscroll
                  overscroll: true,
                ),
              ),
              // Action buttons overlay
              if (feedState.products.isNotEmpty) 
                _buildActionButtons(feedState.products.first),
              
              // Loading indicator for pagination
              if (feedState.isLoadingMore)
                Positioned(
                  bottom: 200,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, widget, loadingProgress) {
                      if (loadingProgress == null) return widget!;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                          size: 50,
                        ),
                      );
                    },
                  ),
                  // Gradient overlay for better text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black26,
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildQuickActionsOverlay(),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _buildProductInfo(product),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsOverlay() {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          onSelected: (value) {
            // Handle additional actions
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'save',
              child: Row(
                children: [
                  Icon(Icons.favorite_border, size: 16),
                  SizedBox(width: 8),
                  Text('Save to Wishlist'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share, size: 16),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1B1E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.star,
                color: Colors.amber[400],
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${product.reviewCount} reviews',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.category,
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Product topProduct) {
    return Positioned(
      bottom: 140,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.close,
              color: Colors.red[500]!,
              label: 'Skip',
              onPressed: () => _cardSwiperController.swipe(CardSwiperDirection.left),
            ),
            _buildActionButton(
              icon: Icons.favorite,
              color: Colors.green[500]!,
              label: 'Save',
              onPressed: () => _cardSwiperController.swipe(CardSwiperDirection.right),
            ),
            _buildActionButton(
              icon: Icons.star,
              color: Colors.blue[500]!,
              label: 'Love',
              onPressed: () => _cardSwiperController.swipe(CardSwiperDirection.top),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 35,
            backgroundColor: color.withOpacity(0.1),
            child: IconButton(
              icon: Icon(
                icon,
                color: color,
                size: 28,
              ),
              onPressed: onPressed,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(Icons.home, 'Home', false, () {
            // Navigate to home/feed
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/', 
              (route) => false,
            );
          }),
          _buildBottomNavItem(Icons.swipe, 'Swipe', true, () {
            // Already on swipe screen
          }),
          _buildBottomNavItem(Icons.wardrobe, 'Closet', false, () {
            // Navigate to closet/profile screen
            _navigateToCloset();
          }),
          _buildBottomNavItem(Icons.person, 'Profile', false, () {
            // Navigate to profile screen
            _navigateToProfile();
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive
                ? const Color(0xFF6366F1)
                : const Color(0xFF6B7280),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  bool _onUndo(int? index, CardSwiperDirection direction) {
    // Handle undo functionality
    _handleUndo();
    return true;
  }

  void _handleUndo() async {
    if (!_canUndo) return;

    final success = await ref.read(feedProvider.notifier).undoLastSwipe();
    if (success) {
      setState(() {
        _canUndo = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Swipe undone'),
          backgroundColor: Colors.orange,
        ),
      );
      _updateUndoState();
    }
  }

  void _showSwipeFeedback(SwipeAction action, Product product) {
    String message;
    Color color;
    IconData icon;

    switch (action) {
      case SwipeAction.like:
        message = 'Added ${product.name} to your closet!';
        color = Colors.green;
        icon = Icons.favorite;
        break;
      case SwipeAction.superLike:
        message = 'Super liked ${product.name}! ✨';
        color = Colors.blue;
        icon = Icons.star;
        break;
      case SwipeAction.dislike:
        message = 'Skipped ${product.name}';
        color = Colors.red;
        icon = Icons.close;
        break;
      case SwipeAction.skip:
        message = 'Skipped ${product.name}';
        color = Colors.orange;
        icon = Icons.arrow_downward;
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (action == SwipeAction.like || action == SwipeAction.superLike)
              TextButton(
                onPressed: () {
                  // Navigate to closet
                },
                child: const Text('View Closet', style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: _handleUndo,
        ),
      ),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProductDetail(product: product),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateToCloset() {
    Navigator.pushNamed(context, '/closet');
  }

  /// Add product to closet when user swipes right (likes)
  Future<void> _addToCloset(Product product) async {
    try {
      await ref.read(closetProvider.notifier).addToCloset(
        product,
        size: product.availableSizes.first,
        color: product.availableColors.first,
      );
      
      // Show success notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${product.name} added to your closet!'),
                ),
                TextButton(
                  onPressed: _navigateToCloset,
                  child: const Text('View Closet', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Show error notification if adding to closet fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to closet: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToProfile() {
    // TODO: Implement profile screen navigation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile feature coming soon!'),
        backgroundColor: Color(0xFF6366F1),
      ),
    );
  }
}