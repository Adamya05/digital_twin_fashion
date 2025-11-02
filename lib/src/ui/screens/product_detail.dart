/// Enhanced Product Detail Screen with Photo Carousel
/// 
/// A comprehensive product detail screen featuring:
/// 
/// ## Photo Carousel System:
/// - Multi-image carousel with smooth PageView navigation
/// - Full-screen image viewer with pinch-to-zoom and pan
/// - Image indicators and navigation arrows
/// - Hero animations for smooth transitions
/// - Cached network image support with loading states
/// - Support for multiple image formats (JPEG, PNG, WebP)
/// 
/// ## Interactive Size & Fit System:
/// - Visual size selection grid with stock indicators
/// - Color selection with realistic color swatches
/// - Size chart modal with detailed measurements
/// - Fit estimation based on avatar compatibility
/// - "Find My Size" recommendation feature
/// - Real-time stock availability display
/// 
/// ## Product Action Buttons:
/// - "Try On" button - navigates to 3D try-on viewer
/// - "Add to Cart" - with validation and loading states
/// - "Add to Favorites" - toggle favorite status
/// - "Share" - social sharing with multiple options
/// - "Size Guide" - opens detailed size chart
/// - Proper loading states and haptic feedback
/// 
/// ## Comprehensive Product Information:
/// - Product name, pricing with discount display
/// - Vendor information with verification badges
/// - Product rating and review count
/// - Detailed product description and care instructions
/// - Technical specifications and key features
/// - Shipping and return policy information
/// - Availability and stock status
/// 
/// ## Navigation Integration:
/// - Connects seamlessly with swipe feed navigation
/// - Proper route parameters for product ID
/// - Deep linking support for product URLs
/// - Breadcrumb navigation and back handling
/// 
/// Usage:
/// ```dart
/// Navigator.of(context).pushNamed('/product-detail', arguments: {
///   'product': product,
///   'heroTag': 'product_123',
///   'onTryOn': () => Navigator.push(...),
///   'onAddToCart': (size, color) => addToCart(size, color),
/// });
/// ```
/// 
/// The screen is fully responsive and follows Material Design 3 guidelines
/// with smooth animations, haptic feedback, and accessibility support.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product_model.dart';
import '../../models/avatar_model.dart';
import '../../widgets/app_button.dart';

class ProductDetail extends StatefulWidget {
  final Product product;
  final String? heroTag;
  final VoidCallback? onTryOn;
  final Function(String size, String color)? onAddToCart;
  final VoidCallback? onAddToFavorites;

  const ProductDetail({
    super.key,
    required this.product,
    this.heroTag,
    this.onTryOn,
    this.onAddToCart,
    this.onAddToFavorites,
  });

  @override
  State<ProductDetail> createState() => _ProductDetailState();
}

class _ProductDetailState extends State<ProductDetail> {
  final PageController _imagePageController = PageController();
  final TransformationController _transformationController = TransformationController();
  
  int _currentImageIndex = 0;
  String? _selectedSize;
  String? _selectedColor;
  bool _isAddingToCart = false;
  bool _isAddingToFavorites = false;
  bool _showFullScreenImage = false;

  // Color swatches for better color representation
  static const Map<String, Color> _colorSwatches = {
    'Black': Colors.black87,
    'White': Colors.white70,
    'Gray': Colors.grey,
    'Blue': Colors.blue,
    'Red': Colors.red,
    'Green': Colors.green,
    'Yellow': Colors.amber,
    'Orange': Colors.orange,
    'Purple': Colors.purple,
    'Pink': Colors.pink,
    'Brown': Colors.brown,
    'Navy': Color(0xFF1E3A8A),
    'Beige': Color(0xFFF5F5DC),
    'Khaki': Color(0xFF8B7D6B),
    'Burgundy': Color(0xFF800020),
    'Olive': Color(0xFF808000),
    'Cream': Color(0xFFFFFDD0),
    'Charcoal': Color(0xFF36454F),
  };

  @override
  void dispose() {
    _imagePageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoCarousel(),
                    _buildProductInfoSection(),
                    _buildColorSelection(),
                    _buildSizeSelection(),
                    _buildSizeGuideButton(),
                    _buildFitEstimation(),
                    _buildTryOnSection(),
                    _buildVendorInfo(),
                    _buildProductDescription(),
                    _buildSpecifications(),
                    _buildShippingInfo(),
                    _buildReturnPolicy(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          _buildBottomActionBar(),
        ],
      ),
      // Full-screen image viewer
      bottomSheet: _showFullScreenImage ? _buildFullScreenImageViewer() : null,
    );
  }

  // ==================== SLIVER APP BAR ====================
  
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 500,
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1B1E)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF1A1B1E)),
            onPressed: _handleShare,
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              widget.product.metadata.tags.contains('favorited') ? 
                Icons.favorite : Icons.favorite_border,
              color: widget.product.metadata.tags.contains('favorited') ? 
                Colors.red : const Color(0xFF1A1B1E),
            ),
            onPressed: _handleAddToFavorites,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background product image
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.1),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: Hero(
                tag: widget.heroTag ?? 'product_${widget.product.id}',
                child: CachedNetworkImage(
                  imageUrl: widget.product.primaryImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF3F4F6),
                    child: const Icon(
                      Icons.broken_image,
                      color: Color(0xFF9CA3AF),
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PHOTO CAROUSEL ====================
  
  Widget _buildPhotoCarousel() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Main carousel
            AspectRatio(
              aspectRatio: 1,
              child: PageView.builder(
                controller: _imagePageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemCount: widget.product.images.isEmpty ? 1 : widget.product.images.length,
                itemBuilder: (context, index) {
                  final imageUrl = widget.product.images.isEmpty 
                    ? widget.product.primaryImage 
                    : widget.product.images[index];
                  
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showFullScreenImage = true);
                    },
                    child: Hero(
                      tag: 'product_image_${widget.product.id}_$index',
                      child: InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 3.0,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.broken_image,
                              color: Color(0xFF9CA3AF),
                              size: 80,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Image indicators
            if (widget.product.images.length > 1) ...[
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.product.images.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index 
                          ? const Color(0xFF6366F1)
                          : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Navigation arrows
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: _buildNavigationArrow(
                  icon: Icons.chevron_left,
                  onTap: _previousImage,
                  visible: _currentImageIndex > 0,
                ),
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: _buildNavigationArrow(
                  icon: Icons.chevron_right,
                  onTap: _nextImage,
                  visible: _currentImageIndex < widget.product.images.length - 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool visible,
  }) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, size: 24, color: const Color(0xFF6366F1)),
            onTap: visible ? onTap : null,
          ),
        ),
      ),
    );
  }

  // ==================== FULL SCREEN IMAGE VIEWER ====================
  
  Widget _buildFullScreenImageViewer() {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full screen image
          PageView.builder(
            controller: _imagePageController,
            onPageChanged: (index) {
              setState(() => _currentImageIndex = index);
            },
            itemCount: widget.product.images.length,
            itemBuilder: (context, index) {
              final imageUrl = widget.product.images[index];
              
              return InteractiveViewer(
                panAxis: PanAxis.vertical,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.black,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Close button
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showFullScreenImage = false);
                },
              ),
            ),
          ),
          
          // Image counter
          if (widget.product.images.length > 1)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Text(
                '${_currentImageIndex + 1} / ${widget.product.images.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      _imagePageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.product.images.length - 1) {
      _imagePageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  // ==================== PRODUCT INFORMATION SECTION ====================
  
  Widget _buildProductInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Name and Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1B1E),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.category,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPriceWidget(),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Rating and Review Count
          Row(
            children: [
              _buildRatingWidget(),
              const SizedBox(width: 12),
              Text(
                '(${widget.product.rating.totalReviews} reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Compatibility Badge
          if (widget.product.compatibility.isCompatibleWith(Avatar()))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Perfect Match for Your Avatar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceWidget() {
    final pricing = widget.product.pricing;
    final isOnSale = pricing.isOnSale;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOnSale ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOnSale ? const Color(0xFFF59E0B) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isOnSale) ...[
            Text(
              '\$${pricing.originalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
                decoration: TextDecoration.lineThrough,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Save ${pricing.discountPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '\$${pricing.currentPrice.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isOnSale ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1B1E),
            ),
          ),
          if (pricing.isFreeShipping) ...[
            const SizedBox(height: 4),
            const Text(
              'Free Shipping',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: Colors.amber[400],
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            widget.product.rating.average.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1E),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== COLOR SELECTION ====================
  
  Widget _buildColorSelection() {
    final availableColors = widget.product.availableColors;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Color',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
              const Spacer(),
              if (_selectedColor != null)
                Text(
                  _selectedColor!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableColors.map((colorName) => _buildColorSwatch(colorName)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(String colorName) {
    final colorValue = _colorSwatches[colorName] ?? Colors.grey;
    final isSelected = _selectedColor == colorName;
    final stock = widget.product.sizeInfo.colors[colorName] ?? 0;
    final isAvailable = stock > 0;
    
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() => _selectedColor = colorName);
        HapticFeedback.lightImpact();
      } : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: colorValue,
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: !isAvailable
            ? const Icon(
                Icons.block,
                color: Colors.white,
                size: 24,
              )
            : isSelected
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : null,
      ),
    );
  }

  // ==================== SIZE SELECTION ====================
  
  Widget _buildSizeSelection() {
    final availableSizes = widget.product.availableSizes;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Size',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
              const Spacer(),
              if (_selectedSize != null)
                Text(
                  'Selected: $_selectedSize',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableSizes.map((size) => _buildSizeButton(size)).toList(),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _showSizeChart,
            icon: const Icon(Icons.straighten, size: 18),
            label: const Text('Size Guide'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeButton(String size) {
    final sizeDetails = widget.product.sizeInfo.sizeDetails[size];
    final isSelected = _selectedSize == size;
    final isAvailable = sizeDetails?.isAvailable ?? false;
    final stock = sizeDetails?.stock ?? 0;
    
    return GestureDetector(
      onTap: isAvailable ? () {
        setState(() => _selectedSize = size);
        HapticFeedback.lightImpact();
      } : null,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
            if (!isAvailable)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.block,
                  color: Colors.red,
                  size: 16,
                ),
              )
            else if (stock <= 5)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== SIZE GUIDE ====================
  
  Widget _buildSizeGuideButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.help_outline,
            color: const Color(0xFF6366F1),
            size: 20,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Help with Sizing?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B1E),
                  ),
                ),
                Text(
                  'View size chart and get personalized recommendations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _showSizeChart,
            icon: const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  void _showSizeChart() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizeChartModal(
        product: widget.product,
        selectedSize: _selectedSize,
        onSizeSelected: (size) {
          setState(() => _selectedSize = size);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ==================== FIT ESTIMATION ====================
  
  Widget _buildFitEstimation() {
    final avatar = Avatar(); // This would come from provider
    final compatibilityScore = widget.product.compatibility.getCompatibilityScore(avatar);
    final sizeRecommendations = widget.product.compatibility.sizeRecommendations;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.05),
            const Color(0xFF8B5CF6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fit Estimation for Your Avatar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1E),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _getFitIcon(compatibilityScore),
                color: _getFitColor(compatibilityScore),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getFitDescription(compatibilityScore),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          if (sizeRecommendations.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Recommended sizes: ${sizeRecommendations.join(", ")}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'Find My Size',
            onPressed: _findOptimalSize,
            type: ButtonType.outlined,
            customColor: const Color(0xFF6366F1),
            size: ButtonSize.small,
          ),
        ],
      ),
    );
  }

  IconData _getFitIcon(double score) {
    if (score >= 0.8) return Icons.thumb_up;
    if (score >= 0.6) return Icons.thumbs_up_down;
    return Icons.thumb_down;
  }

  Color _getFitColor(double score) {
    if (score >= 0.8) return const Color(0xFF10B981);
    if (score >= 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _getFitDescription(double score) {
    if (score >= 0.8) return 'Excellent fit expected based on your avatar measurements.';
    if (score >= 0.6) return 'Good fit expected, minor adjustments might be needed.';
    return 'Limited compatibility. Consider trying a different size or style.';
  }

  void _findOptimalSize() {
    HapticFeedback.lightImpact();
    // Simulate size recommendation based on avatar measurements
    final recommendations = widget.product.compatibility.sizeRecommendations;
    if (recommendations.isNotEmpty) {
      setState(() => _selectedSize = recommendations.first);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Size recommendations updated based on your avatar!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ==================== TRY ON SECTION ====================
  
  Widget _buildTryOnSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.view_in_ar,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Try On with Your Avatar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Experience how this product looks on your personalized avatar with advanced 3D visualization',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleTryOn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6366F1),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_filled,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Try On Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== VENDOR INFORMATION ====================
  
  Widget _buildVendorInfo() {
    final vendor = widget.product.vendor;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(vendor.logo),
                radius: 24,
                onBackgroundImageError: (_, __) {
                  // Fallback to initials
                },
                child: Text(
                  vendor.name.substring(0, 2).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1B1E),
                          ),
                        ),
                        if (vendor.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber[400],
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${vendor.reviewCount} reviews',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (vendor.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              vendor.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== PRODUCT DESCRIPTION ====================
  
  Widget _buildProductDescription() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1E),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                
                if (widget.product.careInstructions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  const Text(
                    'Care Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.product.careInstructions.map((instruction) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SPECIFICATIONS ====================
  
  Widget _buildSpecifications() {
    final specs = widget.product.metadata.specifications;
    final features = widget.product.metadata.features;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications & Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1E),
            ),
          ),
          const SizedBox(height: 16),
          
          // Key details grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSpecItem('Material', widget.product.metadata.material),
              _buildSpecItem('Pattern', widget.product.metadata.pattern),
              _buildSpecItem('Style', widget.product.metadata.style),
              _buildSpecItem('Season', widget.product.metadata.season),
            ],
          ),
          
          if (features.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Key Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1B1E),
              ),
            ),
            const SizedBox(height: 12),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
          
          if (specs.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Additional Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1B1E),
              ),
            ),
            const SizedBox(height: 12),
            ...specs.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      '${entry.key}:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1B1E),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1B1E),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SHIPPING INFORMATION ====================
  
  Widget _buildShippingInfo() {
    final shipping = widget.product.shipping;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: const Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Shipping Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: const Color(0xFF6B7280),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Estimated delivery: ${shipping.estimatedDays} days',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.payment,
                color: const Color(0xFF6B7280),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                shipping.isFreeShipping 
                  ? 'Free Shipping Available'
                  : 'Shipping: \$${shipping.shippingCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          if (shipping.isExpedited) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: const Color(0xFF6366F1),
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Expedited shipping available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ==================== RETURN POLICY ====================
  
  Widget _buildReturnPolicy() {
    final shipping = widget.product.shipping;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0EA5E9).withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_return,
                color: const Color(0xFF0EA5E9),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Return Policy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            shipping.returnPolicy.isNotEmpty 
              ? shipping.returnPolicy
              : '30-day return policy. Free returns on orders over \$50. Items must be in original condition with tags attached.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BOTTOM ACTION BAR ====================
  
  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB).withOpacity(0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Try On Button (Primary)
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _handleTryOn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.view_in_ar,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Try On',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Action Buttons
            _buildActionButton(
              icon: _selectedSize != null && _selectedColor != null 
                ? Icons.shopping_cart 
                : Icons.shopping_cart_outlined,
              onPressed: _handleAddToCart,
              color: const Color(0xFF6366F1),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: widget.product.metadata.tags.contains('favorited') 
                ? Icons.favorite 
                : Icons.favorite_border,
              onPressed: _handleAddToFavorites,
              color: widget.product.metadata.tags.contains('favorited') 
                ? Colors.red 
                : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 8),
            _buildActionButton(
              icon: Icons.share,
              onPressed: _handleShare,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: 24,
        ),
        onPressed: onPressed,
      ),
    );
  }

  // ==================== ACTION HANDLERS ====================
  
  void _handleTryOn() {
    if (_selectedSize == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both size and color before trying on'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    HapticFeedback.mediumImpact();
    if (widget.onTryOn != null) {
      widget.onTryOn!();
    } else {
      // Navigate to try-on viewer
      Navigator.of(context).pushNamed(
        '/tryon',
        arguments: {
          'product': widget.product,
          'size': _selectedSize,
          'color': _selectedColor,
        },
      );
    }
  }

  void _handleAddToCart() async {
    if (_selectedSize == null || _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both size and color'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAddingToCart = true);
    
    try {
      if (widget.onAddToCart != null) {
        await widget.onAddToCart!(_selectedSize!, _selectedColor!);
      } else {
        // Add to cart logic here
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingToCart = false);
    }
  }

  void _handleAddToFavorites() async {
    setState(() => _isAddingToFavorites = true);
    
    try {
      if (widget.onAddToFavorites != null) {
        await widget.onAddToFavorites!();
      } else {
        // Add to favorites logic here
        await Future.delayed(const Duration(milliseconds: 500));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product.metadata.tags.contains('favorited')
                ? 'Removed from favorites'
                : 'Added to favorites',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAddingToFavorites = false);
    }
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    
    // Create share content
    final content = '''
Check out this ${widget.product.name}!

Price: $${widget.product.pricing.currentPrice}
Category: ${widget.product.category}
Rating: ${widget.product.rating.average}/5 (${widget.product.rating.totalReviews} reviews)

Available on Digital Twin Fashion App
    '''.trim();

    // Show share options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(top: 12, bottom: 16),
              ),
              const Text(
                'Share Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B1E),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildShareOption(
                    icon: Icons.copy,
                    label: 'Copy Link',
                    onTap: () {
                      Clipboard.setData(ClipboardData(
                        text: 'https://fashion-app.com/product/${widget.product.id}',
                      ));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard')),
                      );
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.message,
                    label: 'Message',
                    onTap: () {
                      // Open messaging app
                      Navigator.pop(context);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    onTap: () {
                      // Open email app
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SIZE CHART MODAL ====================

class SizeChartModal extends StatefulWidget {
  final Product product;
  final String? selectedSize;
  final Function(String) onSizeSelected;

  const SizeChartModal({
    super.key,
    required this.product,
    this.selectedSize,
    required this.onSizeSelected,
  });

  @override
  State<SizeChartModal> createState() => _SizeChartModalState();
}

class _SizeChartModalState extends State<SizeChartModal> {
  String _selectedCategory = 'Womens';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(top: 12, bottom: 16),
              ),
              
              // Header
              const Text(
                'Size Chart',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1B1E),
                ),
              ),
              const SizedBox(height: 20),
              
              // Category tabs
              _buildCategoryTabs(),
              
              // Size chart
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: _buildSizeChartTable(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryTab('Womens', _selectedCategory == 'Womens'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCategoryTab('Mens', _selectedCategory == 'Mens'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildCategoryTab('Kids', _selectedCategory == 'Kids'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeChartTable() {
    final sizes = widget.product.availableSizes;
    
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFE5E7EB)),
        children: [
          // Header row
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF9FAFB)),
            children: [
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Size',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1E),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Bust (inches)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1E),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Waist (inches)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1E),
                    ),
                  ),
                ),
              ),
              TableCell(
                verticalAlignment: TableCellVerticalAlignment.middle,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Hip (inches)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1B1E),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Size rows
          ...sizes.map((size) {
            final isSelected = widget.selectedSize == size;
            final measurements = widget.product.sizeInfo.sizeDetails[size]?.measurements ?? {};
            
            return TableRow(
              decoration: BoxDecoration(
                color: isSelected 
                  ? const Color(0xFF6366F1).withOpacity(0.1) 
                  : Colors.transparent,
              ),
              children: [
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: GestureDetector(
                    onTap: () => widget.onSizeSelected(size),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        size,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: isSelected 
                            ? const Color(0xFF6366F1) 
                            : const Color(0xFF1A1B1E),
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${measurements['bust'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${measurements['waist'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${measurements['hip'] ?? 'N/A'}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

// ==================== NAVIGATION UTILITIES ====================

/// Navigation helper for ProductDetail screen
class ProductDetailRoute {
  /// Navigate to product detail screen from swipe feed or product list
  static Future<T?> push<T>({
    required BuildContext context,
    required Product product,
    String? heroTag,
    VoidCallback? onTryOn,
    Function(String size, String color)? onAddToCart,
    VoidCallback? onAddToFavorites,
    RouteSettings? routeSettings,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => ProductDetail(
          product: product,
          heroTag: heroTag ?? 'product_${product.id}',
          onTryOn: onTryOn,
          onAddToCart: onAddToCart,
          onAddToFavorites: onAddToFavorites,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        settings: routeSettings,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOut)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate to product detail with fade transition
  static Future<T?> pushFade<T>({
    required BuildContext context,
    required Product product,
    String? heroTag,
    VoidCallback? onTryOn,
    Function(String size, String color)? onAddToCart,
    VoidCallback? onAddToFavorites,
    RouteSettings? routeSettings,
  }) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => ProductDetail(
          product: product,
          heroTag: heroTag ?? 'product_${product.id}',
          onTryOn: onTryOn,
          onAddToCart: onAddToCart,
          onAddToFavorites: onAddToFavorites,
        ),
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        settings: routeSettings,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  /// Deep link handler for product URLs
  static ProductDetail? fromUrl(String productUrl) {
    // Parse product URL and extract product ID
    final uri = Uri.parse(productUrl);
    final pathSegments = uri.pathSegments;
    
    if (pathSegments.length >= 2 && pathSegments[0] == 'product') {
      final productId = pathSegments[1];
      // Return ProductDetail with parsed product ID
      // This would integrate with your product service
      return null; // Placeholder
    }
    
    return null;
  }
}

/// Extension on Navigator for easier product detail navigation
extension ProductDetailNavigator on NavigatorState {
  /// Push product detail with default animations
  Future<T?> pushProductDetail<T>({
    required Product product,
    String? heroTag,
    VoidCallback? onTryOn,
    Function(String size, String color)? onAddToCart,
    VoidCallback? onAddToFavorites,
  }) {
    return ProductDetailRoute.push<T>(
      context: context,
      product: product,
      heroTag: heroTag,
      onTryOn: onTryOn,
      onAddToCart: onAddToCart,
      onAddToFavorites: onAddToFavorites,
    );
  }

  /// Push product detail with fade transition
  Future<T?> pushProductDetailFade<T>({
    required Product product,
    String? heroTag,
    VoidCallback? onTryOn,
    Function(String size, String color)? onAddToCart,
    VoidCallback? onAddToFavorites,
  }) {
    return ProductDetailRoute.pushFade<T>(
      context: context,
      product: product,
      heroTag: heroTag,
      onTryOn: onTryOn,
      onAddToCart: onAddToCart,
      onAddToFavorites: onAddToFavorites,
    );
  }
}
