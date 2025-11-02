import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product_model.dart';
import '../models/avatar_model.dart';
import 'avatar_canvas.dart';

/// Product swipe card with avatar composite system
/// Displays product information with user avatar overlay and Material Design 3 styling
class ProductSwipeCard extends StatefulWidget {
  final Product product;
  final Avatar? avatar;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final bool showAvatar;
  final bool enableSwipe;
  final bool enablePreview;
  final CardVariant variant;
  final double height;
  final double? width;

  const ProductSwipeCard({
    Key? key,
    required this.product,
    this.avatar,
    this.onTap,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.onFavorite,
    this.onShare,
    this.showAvatar = true,
    this.enableSwipe = true,
    this.enablePreview = true,
    this.variant = CardVariant.normal,
    this.height = 480,
    this.width,
  }) : super(key: key);

  @override
  State<ProductSwipeCard> createState() => _ProductSwipeCardState();
}

class _ProductSwipeCardState extends State<ProductSwipeCard>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _swipeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _swipeAnimation;
  
  Offset _startPosition = Offset.zero;
  bool _isAnimating = false;
  bool _isImageLoading = false;
  ui.Image? _compositeImage;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _swipeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));
    
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeInOut));

    _fadeController.forward();
    _scaleController.forward();
    
    if (widget.showAvatar && widget.avatar != null) {
      _generateCompositeImage();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _swipeController.dispose();
    _compositeImage?.dispose();
    super.dispose();
  }

  Future<void> _generateCompositeImage() async {
    if (widget.avatar == null || widget.product.imageUrl.isEmpty) return;

    setState(() {
      _isImageLoading = true;
    });

    try {
      // Load product image
      final productImage = await _loadImage(widget.product.imageUrl);
      if (productImage == null) return;

      // Load avatar thumbnail
      final avatarImage = await _loadImage(widget.avatar!.thumbnailUrl);
      if (avatarImage == null) {
        setState(() {
          _isImageLoading = false;
        });
        return;
      }

      // Create composite image
      final compositeImage = await _createComposite(
        productImage,
        avatarImage,
      );

      if (mounted) {
        setState(() {
          _compositeImage = compositeImage;
          _isImageLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error generating composite image: $e');
      setState(() {
        _isImageLoading = false;
      });
    }
  }

  Future<ui.Image?> _loadImage(String url) async {
    try {
      if (url.startsWith('http')) {
        final response = await HttpClient().getUrl(Uri.parse(url));
        final request = await response.close();
        final bytes = await request.expand((e) => e).toList();
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
        final frame = await codec.getNextFrame();
        return frame.image;
      } else {
        // Handle local asset or file path
        return null; // Implementation for local images
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return null;
    }
  }

  Future<ui.Image?> _createComposite(ui.Image productImage, ui.Image avatarImage) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Calculate composite dimensions
    final productRect = Rect.fromLTWH(0, 0, productImage.width.toDouble(), productImage.height.toDouble());
    final avatarSize = math.min(avatarImage.width, avatarImage.height).toDouble();
    final avatarRect = Rect.fromCenter(
      center: Offset(productImage.width.toDouble() - 60, 60),
      width: avatarSize,
      height: avatarSize,
    );

    // Draw product image
    canvas.drawImage(productImage, Offset.zero, Paint());

    // Create circular clip for avatar
    canvas.save();
    canvas.clipPath(Path()..addOval(avatarRect));

    // Draw avatar with some opacity for overlay effect
    final avatarPaint = Paint()..color = Colors.white.withOpacity(0.9);
    canvas.drawImage(avatarImage, avatarRect.topLeft, avatarPaint);
    canvas.restore();

    // Add border to avatar
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawOval(avatarRect, borderPaint);

    // Create final image
    final image = await pictureRecorder.endRecording().toImage(
      productImage.width,
      productImage.height,
    );

    return image;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              height: widget.height,
              width: widget.width ?? MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                onTap: widget.enablePreview ? _handleTap : null,
                onPanStart: widget.enableSwipe ? _handlePanStart : null,
                onPanUpdate: widget.enableSwipe ? _handlePanUpdate : null,
                onPanEnd: widget.enableSwipe ? _handlePanEnd : null,
                child: Transform.translate(
                  offset: _swipeAnimation.value,
                  child: _buildCard(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard() {
    return Material(
      elevation: _getElevation(),
      borderRadius: BorderRadius.circular(24),
      shadowColor: Theme.of(context).colorScheme.shadow,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant,
            ],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Section
              Expanded(
                flex: 3,
                child: _buildProductImage(),
              ),
              
              // Product Information Section
              Expanded(
                flex: 2,
                child: _buildProductInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Stack(
      children: [
        // Main product image
        Positioned.fill(
          child: _isImageLoading
              ? _buildImagePlaceholder()
              : _compositeImage != null
                  ? _buildCompositeImage()
                  : _buildNetworkImage(),
        ),
        
        // Action buttons overlay
        Positioned(
          top: 16,
          right: 16,
          child: _buildActionButtons(),
        ),
        
        // Favorite button
        Positioned(
          top: 16,
          left: 16,
          child: _buildFavoriteButton(),
        ),
        
        // Category badge
        Positioned(
          bottom: 16,
          left: 16,
          child: _buildCategoryBadge(),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildCompositeImage() {
    return CustomPaint(
      painter: ImagePainter(_compositeImage!),
      size: Size.infinite,
    );
  }

  Widget _buildNetworkImage() {
    return CachedNetworkImage(
      imageUrl: widget.product.imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (context, url) => _buildImagePlaceholder(),
      errorWidget: (context, url, error) => _buildImageError(),
      fadeInDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 48,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Share button
        _buildActionButton(
          icon: Icons.share,
          color: Theme.of(context).colorScheme.primary,
          onTap: widget.onShare,
        ),
        const SizedBox(width: 8),
        // Preview button
        if (widget.enablePreview)
          _buildActionButton(
            icon: Icons.fullscreen,
            color: Theme.of(context).colorScheme.secondary,
            onTap: _handleTap,
          ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleController.value,
          child: Material(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                _animateFavorite();
                widget.onFavorite?.call();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        widget.product.category,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // Price and rating row
          Row(
            children: [
              // Price
              Text(
                '₹${widget.product.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const Spacer(),
              
              // Rating
              if (widget.product.rating > 0) ...[
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.product.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.product.reviewCount > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '(${widget.product.reviewCount})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            widget.product.description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Vendor/Brand info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Brand',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Stock indicator
              if (widget.product.stock <= 5 && widget.product.stock > 0)
                Text(
                  'Only ${widget.product.stock} left!',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else if (widget.product.stock == 0)
                Text(
                  'Out of stock',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  double _getElevation() {
    switch (widget.variant) {
      case CardVariant.elevated:
        return 8.0;
      case CardVariant.outlined:
        return 2.0;
      default:
        return 4.0;
    }
  }

  void _handleTap() {
    if (_isAnimating) return;
    
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handlePanStart(DragStartDetails details) {
    if (_isAnimating) return;
    
    _startPosition = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_isAnimating) return;
    
    final offset = details.localPosition - _startPosition;
    final swipeThreshold = MediaQuery.of(context).size.width * 0.3;
    
    double swipeIntensity = 0.0;
    if (offset.dx.abs() > swipeThreshold) {
      swipeIntensity = (offset.dx.abs() - swipeThreshold) / swipeThreshold;
      swipeIntensity = swipeIntensity.clamp(0.0, 1.0);
    }
    
    setState(() {
      _swipeAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(offset.dx * 0.5, 0),
      ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeOut));
      
      _swipeController.value = swipeIntensity;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return;
    
    final swipeThreshold = MediaQuery.of(context).size.width * 0.3;
    final currentOffset = _swipeAnimation.value.dx;
    
    if (currentOffset.abs() > swipeThreshold) {
      _isAnimating = true;
      
      if (currentOffset > 0) {
        widget.onSwipeRight?.call();
      } else {
        widget.onSwipeLeft?.call();
      }
      
      // Reset animation
      _swipeAnimation = Tween<Offset>(
        begin: _swipeAnimation.value,
        end: Offset(currentOffset > 0 ? 500 : -500, 0),
      ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.easeIn));
      
      _swipeController.forward().then((_) {
        if (mounted) {
          setState(() {
            _isAnimating = false;
            _swipeAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: Offset.zero,
            ).animate(_swipeController);
            _swipeController.reset();
          });
        }
      });
    } else {
      // Reset to center
      _swipeAnimation = Tween<Offset>(
        begin: _swipeAnimation.value,
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _swipeController, curve: Curves.elasticOut));
      
      _swipeController.forward();
    }
  }

  void _animateFavorite() {
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }
}

/// Custom painter for rendering composite images
class ImagePainter extends CustomPainter {
  final ui.Image image;

  ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Card variant enum for different styling options
enum CardVariant {
  normal,
  elevated,
  outlined,
}

/// Avatar composite widget for displaying avatar overlay on product
class AvatarComposite extends StatelessWidget {
  final Product product;
  final Avatar? avatar;
  final double size;
  final bool showBorder;

  const AvatarComposite({
    Key? key,
    required this.product,
    this.avatar,
    this.size = 60,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (avatar == null) {
      return _buildFallbackAvatar();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 3,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatar!.thumbnailUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        border: showBorder
            ? Border.all(
                color: Colors.white,
                width: 3,
              )
            : null,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 30,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: const Icon(
        Icons.person_outline,
        color: Colors.grey,
        size: 30,
      ),
    );
  }
}

/// Product card list widget for displaying multiple cards
class ProductSwipeCardList extends StatelessWidget {
  final List<Product> products;
  final List<Avatar>? avatars;
  final Function(Product)? onProductTap;
  final Function(Product)? onSwipeRight;
  final Function(Product)? onSwipeLeft;
  final ScrollPhysics? physics;

  const ProductSwipeCardList({
    Key? key,
    required this.products,
    this.avatars,
    this.onProductTap,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.physics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: physics,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final avatar = avatars != null && avatars!.length > index ? avatars![index] : null;
        
        return ProductSwipeCard(
          product: product,
          avatar: avatar,
          onTap: () => onProductTap?.call(product),
          onSwipeRight: () => onSwipeRight?.call(product),
          onSwipeLeft: () => onSwipeLeft?.call(product),
        );
      },
    );
  }
}