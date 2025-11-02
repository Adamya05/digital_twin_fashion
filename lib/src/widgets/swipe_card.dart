/// Enhanced Swipe Card Widget
/// 
/// Advanced draggable card component with gesture recognition, visual feedback,
/// and haptic responses for product feed interface.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product_model.dart';
import '../models/swipe_history_model.dart';

class SwipeCard extends StatefulWidget {
  final Product? product;
  final Widget child;
  final Function(SwipeAction action, double velocity, Offset position)? onSwipe;
  final VoidCallback? onTap;
  final bool isTopCard;

  const SwipeCard({
    super.key,
    this.product,
    required this.child,
    this.onSwipe,
    this.onTap,
    this.isTopCard = false,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  Offset _position = Offset.zero;
  bool _isAnimating = false;
  
  // Swipe thresholds and velocities
  static const double swipeThreshold = 120.0;
  static const double swipeVelocityThreshold = 1000.0;
  static const Duration animationDuration = Duration(milliseconds: 200);

  // Visual feedback colors
  final Color _likeColor = Colors.green.withOpacity(0.8);
  final Color _dislikeColor = Colors.red.withOpacity(0.8);
  final Color _superLikeColor = Colors.blue.withOpacity(0.8);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: animationDuration,
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.isTopCard ? 0.95 : 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _triggerHapticFeedback(HapticFeedbackType type) {
    HapticFeedback.lightImpact();
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  SwipeAction _determineSwipeAction(Offset position) {
    final swipeDistance = position.distance;
    final velocity = swipeDistance / (animationDuration.inMilliseconds / 1000);
    
    // Super like condition (upward swipe with high velocity)
    if (position.dy < -swipeThreshold && velocity > swipeVelocityThreshold * 1.5) {
      return SwipeAction.superLike;
    }
    
    // Like condition (right swipe)
    if (position.dx > swipeThreshold) {
      return SwipeAction.like;
    }
    
    // Dislike condition (left swipe)
    if (position.dx < -swipeThreshold) {
      return SwipeAction.dislike;
    }
    
    // Skip condition (downward swipe)
    if (position.dy > swipeThreshold) {
      return SwipeAction.skip;
    }
    
    // Default to like for right swipes, dislike for left swipes
    return position.dx > 0 ? SwipeAction.like : SwipeAction.dislike;
  }

  void _onPanStart(DragStartDetails details) {
    if (_isAnimating || !widget.isTopCard) return;
    
    setState(() {
      _position = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details, Size cardSize) {
    if (_isAnimating || !widget.isTopCard) return;

    setState(() {
      _position = Offset(
        _position.dx + details.delta.dx,
        _position.dy + details.delta.dy,
      );
    });

    // Update rotation based on horizontal movement
    final rotation = _position.dx / cardSize.width * 0.5;
    _rotationAnimation = Tween<double>(
      begin: _rotationAnimation.value,
      end: rotation,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Update scale for visual feedback
    final distance = _position.distance;
    final scale = 1.0 - (distance / 500).clamp(0.0, 0.1);
    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: scale,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isAnimating || !widget.isTopCard) return;

    final swipeDistance = _position.distance;
    final velocity = swipeDistance / (animationDuration.inMilliseconds / 1000);

    if (swipeDistance > swipeThreshold || velocity > swipeVelocityThreshold) {
      final action = _determineSwipeAction(_position);
      _performSwipe(action, velocity);
    } else {
      _resetPosition();
    }
  }

  void _performSwipe(SwipeAction action, double velocity) {
    if (_isAnimating) return;
    
    _isAnimating = true;
    _triggerHapticFeedback(HapticFeedbackType.mediumImpact);

    // Calculate final position based on action
    Offset finalPosition;
    switch (action) {
      case SwipeAction.like:
        finalPosition = Offset(
          MediaQuery.of(context).size.width * 1.5,
          _position.dy,
        );
        _showToast('Added to closet!', Colors.green);
        widget.onSwipe?.call(action, velocity, _position);
        break;
      case SwipeAction.dislike:
        finalPosition = Offset(
          -MediaQuery.of(context).size.width * 1.5,
          _position.dy,
        );
        _showToast('Product skipped', Colors.red);
        widget.onSwipe?.call(action, velocity, _position);
        break;
      case SwipeAction.superLike:
        finalPosition = Offset(
          _position.dx,
          -MediaQuery.of(context).size.height * 1.5,
        );
        _showToast('Super liked! ✨', Colors.blue);
        widget.onSwipe?.call(action, velocity, _position);
        break;
      case SwipeAction.skip:
        finalPosition = Offset(
          _position.dx,
          MediaQuery.of(context).size.height * 1.5,
        );
        _showToast('Product skipped', Colors.red);
        widget.onSwipe?.call(action, velocity, _position);
        break;
    }

    _animateToPosition(finalPosition, () {
      setState(() {
        _isAnimating = false;
        _position = Offset.zero;
      });
    });
  }

  void _resetPosition() {
    if (_isAnimating) return;
    
    _isAnimating = true;

    _slideAnimation = Tween<Offset>(
      begin: _position,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: _rotationAnimation.value,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: widget.isTopCard ? 0.95 : 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward().then((_) {
      setState(() {
        _isAnimating = false;
        _position = Offset.zero;
      });
    });
  }

  void _animateToPosition(Offset target, VoidCallback onComplete) {
    _slideAnimation = Tween<Offset>(
      begin: _position,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _rotationAnimation = Tween<double>(
      begin: _rotationAnimation.value,
      end: target.dx > 0 ? 0.5 : -0.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _scaleAnimation = Tween<double>(
      begin: _scaleAnimation.value,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward().then((_) {
      onComplete();
    });
  }

  Widget _buildSwipeIndicator(SwipeAction action) {
    Color color;
    String text;
    IconData icon;

    switch (action) {
      case SwipeAction.like:
        color = _likeColor;
        text = 'LIKE';
        icon = Icons.favorite;
        break;
      case SwipeAction.dislike:
        color = _dislikeColor;
        text = 'NOPE';
        icon = Icons.close;
        break;
      case SwipeAction.superLike:
        color = _superLikeColor;
        text = 'SUPER LIKE';
        icon = Icons.star;
        break;
      case SwipeAction.skip:
        color = _dislikeColor;
        text = 'SKIP';
        icon = Icons.arrow_downward;
        break;
    }

    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 3),
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: widget.isTopCard ? _onPanStart : null,
          onPanUpdate: widget.isTopCard 
              ? (details) => _onPanUpdate(details, constraints.biggest)
              : null,
          onPanEnd: widget.isTopCard ? _onPanEnd : null,
          onTap: widget.isTopCard ? widget.onTap : null,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: _slideAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        widget.child,
                        if (widget.isTopCard) ...[
                          // Like indicator (right side)
                          if (_position.dx > swipeThreshold * 0.3)
                            Positioned(
                              top: 20,
                              right: 20,
                              child: Transform.rotate(
                                angle: 0.3,
                                child: _buildSwipeIndicator(SwipeAction.like),
                              ),
                            ),
                          // Dislike indicator (left side)
                          if (_position.dx < -swipeThreshold * 0.3)
                            Positioned(
                              top: 20,
                              left: 20,
                              child: Transform.rotate(
                                angle: -0.3,
                                child: _buildSwipeIndicator(SwipeAction.dislike),
                              ),
                            ),
                          // Super like indicator (top)
                          if (_position.dy < -swipeThreshold * 0.3)
                            Positioned(
                              top: 20,
                              left: 20,
                              right: 20,
                              child: _buildSwipeIndicator(SwipeAction.superLike),
                            ),
                          // Skip indicator (bottom)
                          if (_position.dy > swipeThreshold * 0.3)
                            Positioned(
                              bottom: 20,
                              left: 20,
                              right: 20,
                              child: Transform.rotate(
                                angle: 3.14,
                                child: _buildSwipeIndicator(SwipeAction.skip),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Trigger haptic feedback for decision
  void triggerHapticFeedback() {
    HapticFeedback.heavyImpact();
  }
}

/// Quick Action Buttons for Card
class SwipeCardActions extends StatelessWidget {
  final Product? product;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;

  const SwipeCardActions({
    super.key,
    this.product,
    required this.onLike,
    required this.onDislike,
    required this.onSuperLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.close,
            color: Colors.red,
            onTap: onDislike,
            tooltip: 'Skip',
          ),
          _buildActionButton(
            icon: Icons.favorite,
            color: Colors.green,
            onTap: onLike,
            tooltip: 'Save to Closet',
          ),
          _buildActionButton(
            icon: Icons.star,
            color: Colors.blue,
            onTap: onSuperLike,
            tooltip: 'Super Like',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
