import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/product_swipe_card.dart';
import '../../models/product_model.dart';
import '../../models/avatar_model.dart';
import '../../widgets/avatar_composite_renderer.dart';
import '../../../themes/app_theme.dart';

/// Product feed screen showcasing swipe cards with avatar composites
/// Integrates with the main FitTwin app navigation system
class ProductFeedScreen extends ConsumerStatefulWidget {
  final String? category;
  final bool showAvatar;

  const ProductFeedScreen({
    Key? key,
    this.category,
    this.showAvatar = true,
  }) : super(key: key);

  @override
  ConsumerState<ProductFeedScreen> createState() => _ProductFeedScreenState();
}

class _ProductFeedScreenState extends ConsumerState<ProductFeedScreen> {
  late List<Product> _products;
  late List<Avatar> _avatars;
  bool _isLoading = false;
  bool _showAvatar = true;
  String _selectedCategory = 'All';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _showAvatar = widget.showAvatar;
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeData() {
    setState(() {
      _isLoading = true;
    });

    // Sample product data - in real app, this would come from your data source
    _products = _getSampleProducts();
    _avatars = _getSampleAvatars();

    // Preload composites for better performance
    _preloadComposites();

    setState(() {
      _isLoading = false;
    });
  }

  List<Product> _getSampleProducts() {
    final baseProducts = [
      Product(
        id: '1',
        name: 'Premium Cotton T-Shirt',
        description: 'Comfortable and stylish cotton t-shirt perfect for casual wear',
        price: 1299.00,
        imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
        category: 'Fashion',
        stock: 15,
        rating: 4.5,
        reviewCount: 234,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '2',
        name: 'Wireless Bluetooth Headphones',
        description: 'High-quality wireless headphones with noise cancellation',
        price: 5499.00,
        imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
        category: 'Electronics',
        stock: 8,
        rating: 4.8,
        reviewCount: 567,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '3',
        name: 'Running Shoes - Men',
        description: 'Lightweight running shoes with superior comfort and style',
        price: 3499.00,
        imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400',
        category: 'Footwear',
        stock: 3,
        rating: 4.3,
        reviewCount: 189,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '4',
        name: 'Leather Handbag - Women',
        description: 'Elegant leather handbag crafted from premium materials',
        price: 7899.00,
        imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400',
        category: 'Accessories',
        stock: 5,
        rating: 4.7,
        reviewCount: 89,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '5',
        name: 'Smart Fitness Watch',
        description: 'Advanced fitness tracking with heart rate monitoring',
        price: 12999.00,
        imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400',
        category: 'Electronics',
        stock: 12,
        rating: 4.6,
        reviewCount: 445,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '6',
        name: 'Denim Jacket - Vintage',
        description: 'Classic vintage-style denim jacket with modern fit',
        price: 4299.00,
        imageUrl: 'https://images.unsplash.com/photo-1544966503-7cc5ac882d5b?w=400',
        category: 'Fashion',
        stock: 7,
        rating: 4.4,
        reviewCount: 156,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Filter by category if specified
    if (widget.category != null && widget.category != 'All') {
      return baseProducts.where((p) => p.category == widget.category).toList();
    }

    return baseProducts;
  }

  List<Avatar> _getSampleAvatars() {
    return List.generate(6, (index) {
      final avatarNames = ['Alex', 'Sarah', 'Mike', 'Emma', 'David', 'Lisa'];
      final avatarImages = [
        'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        'https://images.unsplash.com/photo-1494790108755-2616b9a67b5b?w=150',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        'https://images.unsplash.com/photo-1489424731084-a5d8b219a5bb?w=150',
      ];

      return Avatar.empty().copyWith(
        id: 'avatar_${index + 1}',
        name: avatarNames[index],
        thumbnailUrl: avatarImages[index],
      );
    });
  }

  Future<void> _preloadComposites() async {
    if (!_showAvatar) return;

    try {
      await AvatarCompositeRenderer().preloadComposites(
        products: _products,
        avatars: _avatars,
        options: const CompositeOptions(
          avatarPosition: AvatarPosition.topRight,
          avatarSize: 60.0,
        ),
      );
    } catch (e) {
      debugPrint('Error preloading composites: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Feed'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          // Toggle avatar display
          IconButton(
            icon: Icon(_showAvatar ? Icons.visibility : Icons.visibility_off),
            onPressed: _toggleAvatarDisplay,
            tooltip: _showAvatar ? 'Hide Avatars' : 'Show Avatars',
          ),
          // Filter menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: _filterProducts,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Categories'),
              ),
              const PopupMenuItem(
                value: 'Fashion',
                child: Text('Fashion'),
              ),
              const PopupMenuItem(
                value: 'Electronics',
                child: Text('Electronics'),
              ),
              const PopupMenuItem(
                value: 'Footwear',
                child: Text('Footwear'),
              ),
              const PopupMenuItem(
                value: 'Accessories',
                child: Text('Accessories'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProductFeed(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildProductFeed() {
    final filteredProducts = _selectedCategory == 'All'
        ? _products
        : _products.where((p) => p.category == _selectedCategory).toList();

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _initializeData();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: filteredProducts.length,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final avatar = _showAvatar && index < _avatars.length ? _avatars[index] : null;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ProductSwipeCard(
              key: ValueKey('${product.id}_${_showAvatar}'),
              product: product,
              avatar: avatar,
              showAvatar: _showAvatar,
              onTap: () => _handleProductTap(product),
              onSwipeRight: () => _handleProductLiked(product),
              onSwipeLeft: () => _handleProductPassed(product),
              onFavorite: () => _handleProductFavorite(product),
              onShare: () => _handleProductShare(product),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _scrollToTop,
      backgroundColor: AppTheme.primaryBlue,
      child: const Icon(Icons.arrow_upward, color: Colors.white),
    );
  }

  void _toggleAvatarDisplay() {
    setState(() {
      _showAvatar = !_showAvatar;
    });

    if (_showAvatar) {
      _preloadComposites();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _showAvatar ? 'Avatars enabled' : 'Avatars disabled',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _filterProducts(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleProductTap(Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductDetailSheet(product),
    );
  }

  void _handleProductLiked(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Liked: ${product.name}')),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'View Details',
          textColor: Colors.white,
          onPressed: () => _handleProductTap(product),
        ),
      ),
    );
  }

  void _handleProductPassed(Product product) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.close, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Passed: ${product.name}')),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleProductFavorite(Product product) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite_border, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Added to favorites: ${product.name}')),
          ],
        ),
        backgroundColor: Colors.pink,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleProductShare(Product product) {
    HapticFeedback.lightImpact();
    
    // In a real app, you would implement actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Sharing: ${product.name}')),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildProductDetailSheet(Product product) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Product image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 4/3,
                  child: Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, size: 48),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Product details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Product name and price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '₹${product.price.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Rating and reviews
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.category,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Stock info
                      if (product.stock > 0) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2,
                              color: product.stock <= 5 ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              product.stock <= 5 
                                  ? 'Only ${product.stock} left in stock!'
                                  : 'In stock (${product.stock} available)',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: product.stock <= 5 ? Colors.orange : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleProductFavorite(product),
                              icon: const Icon(Icons.favorite_border),
                              label: const Text('Add to Favorites'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _handleProductShare(product),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Navigation extension for ProductFeedScreen
extension ProductFeedNavigation on BuildContext {
  /// Navigate to product feed screen
  void navigateToProductFeed({String? category, bool showAvatar = true}) {
    Navigator.of(this).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ProductFeedScreen(
          category: category,
          showAvatar: showAvatar,
        ),
      ),
    );
  }
}