/// 3D Try-On Viewer Demo
/// 
/// Demonstrates the complete 3D Try-On system with model_viewer_plus integration
/// including model loading, avatar-product composite rendering, user controls,
/// and performance optimization
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/avatar_model.dart';
import '../../models/product_model.dart';
import '../../widgets/advanced_3d_tryon_viewer.dart';
import '../../services/model_cache_service.dart';
import '../../services/model_loading_service.dart';
import '../../services/tryon_model_renderer.dart';
import '../../services/tryon_api_service.dart';
import '../../services/api_service.dart';

class TryOnViewerDemo extends StatefulWidget {
  const TryOnViewerDemo({super.key});

  @override
  State<TryOnViewerDemo> createState() => _TryOnViewerDemoState();
}

class _TryOnViewerDemoState extends State<TryOnViewerDemo> {
  // Sample data for demonstration
  final Product _sampleProduct = Product(
    id: 'demo_product_1',
    name: 'Premium Cotton T-Shirt',
    description: 'High-quality cotton blend t-shirt with modern fit',
    originalPrice: 2999.0,
    currentPrice: 1999.0,
    images: [
      'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
      'https://images.unsplash.com/photo-1571945153237-4929e783af4a?w=400',
    ],
    primaryImage: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400',
    category: 'Tops',
    subcategory: 'T-Shirts',
    tags: ['cotton', 'casual', 'modern-fit'],
    sizeInfo: ProductSizeInfo(
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      sizeDetails: {
        'XS': ProductSize(name: 'XS', stock: 10, isAvailable: true),
        'S': ProductSize(name: 'S', stock: 25, isAvailable: true),
        'M': ProductSize(name: 'M', stock: 30, isAvailable: true),
        'L': ProductSize(name: 'L', stock: 20, isAvailable: true),
        'XL': ProductSize(name: 'XL', stock: 15, isAvailable: true),
      },
      colors: {'Blue': 50, 'White': 30, 'Black': 20},
    ),
    vendor: ProductVendor(
      id: 'vendor_1',
      name: 'Fashion Forward',
      logo: 'https://via.placeholder.com/50x50',
      rating: 4.5,
      reviewCount: 1200,
      isVerified: true,
      location: 'Mumbai, India',
      description: 'Premium fashion brand',
    ),
    pricing: ProductPricing(
      originalPrice: 2999.0,
      currentPrice: 1999.0,
      discountPercentage: 33.3,
      currency: 'INR',
      isOnSale: true,
      taxes: {'GST': 18.0},
      shippingCost: 0.0,
      isFreeShipping: true,
    ),
    compatibility: ProductCompatibility(
      compatibleBodyTypes: ['Slim', 'Regular', 'Athletic'],
      compatibleGenders: ['Male', 'Female', 'Non-binary'],
      compatibilityScores: {'Slim': 0.8, 'Regular': 0.9, 'Athletic': 0.8},
      sizeRecommendations: ['S', 'M', 'L'],
      fitDescription: 'Regular fit, true to size',
    ),
    shipping: ProductShipping(
      shippingMethod: 'Express',
      estimatedDays: 2,
      shippingCost: 0.0,
      isFreeShipping: true,
      isExpedited: false,
      availableRegions: ['India'],
    ),
    inventory: ProductInventory(
      totalStock: 100,
      inStock: true,
      lowStock: false,
      lowStockThreshold: 5,
      stockBySize: {'XS': 10, 'S': 25, 'M': 30, 'L': 20, 'XL': 15},
      stockByColor: {'Blue': 50, 'White': 30, 'Black': 20},
      lastRestocked: DateTime.now().subtract(Duration(days: 2)),
      restockStatus: 'In Stock',
    ),
    rating: ProductRating(
      average: 4.3,
      totalReviews: 450,
      ratingDistribution: {5: 200, 4: 150, 3: 80, 2: 15, 1: 5},
      reviews: [],
      fitRating: 4.2,
      qualityRating: 4.5,
      valueRating: 4.4,
    ),
    createdAt: DateTime.now().subtract(Duration(days: 30)),
    updatedAt: DateTime.now().subtract(Duration(days: 1)),
    isAvailable: true,
    isFeatured: true,
    careInstructions: ['Machine wash cold', 'Do not bleach', 'Tumble dry low'],
    metadata: ProductMetadata(
      sku: 'TSH-001-BLU-M',
      material: '100% Cotton',
      pattern: 'Solid',
      style: 'Casual',
      careInstructions: ['Machine wash cold', 'Do not bleach', 'Tumble dry low'],
      features: ['Breathable', 'Comfortable fit', 'Premium quality'],
      specifications: {'material': '100% Cotton', 'care': 'Machine washable'},
      createdAt: DateTime.now().subtract(Duration(days: 30)),
      updatedAt: DateTime.now().subtract(Duration(days: 1)),
      tags: ['cotton', 'casual', 'premium'],
      season: 'All Season',
      occasion: 'Casual',
      // 3D Model support
      has3DModel: true,
      tryOnModelUrl: 'https://example.com/models/demo_product_1_tryon.glb',
      modelFormat: 'glb',
      modelFileSize: 2.5, // MB
      isOptimizedForMobile: true,
      availableQualities: [
        ModelQuality(
          name: 'low',
          label: 'Fast',
          resolutionMultiplier: 0.5,
          maxPolygonCount: 10000,
          fileSize: 1.0,
          isMobileOptimized: true,
          modelUrl: 'https://example.com/models/demo_product_1_low.glb',
        ),
        ModelQuality(
          name: 'medium',
          label: 'Balanced',
          resolutionMultiplier: 1.0,
          maxPolygonCount: 25000,
          fileSize: 2.5,
          isMobileOptimized: true,
          modelUrl: 'https://example.com/models/demo_product_1_medium.glb',
        ),
        ModelQuality(
          name: 'high',
          label: 'Premium',
          resolutionMultiplier: 2.0,
          maxPolygonCount: 50000,
          fileSize: 5.0,
          isMobileOptimized: false,
          modelUrl: 'https://example.com/models/demo_product_1_high.glb',
        ),
      ],
      qualityModelUrls: {
        'low': 'https://example.com/models/demo_product_1_low.glb',
        'medium': 'https://example.com/models/demo_product_1_medium.glb',
        'high': 'https://example.com/models/demo_product_1_high.glb',
      },
    ),
  );

  final Avatar _sampleAvatar = Avatar(
    id: 'demo_avatar_1',
    name: 'John Doe',
    modelUrl: 'https://example.com/avatars/demo_avatar_1.glb',
    thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    createdAt: DateTime.now().subtract(Duration(days: 7)),
    updatedAt: DateTime.now(),
    measurements: AvatarMeasurements(
      height: 175.0,
      weight: 70.0,
      chest: 95.0,
      waist: 80.0,
      hips: 95.0,
      shoulders: 45.0,
      arms: 65.0,
      legs: 85.0,
    ),
    attributes: AvatarAttributes(
      bodyType: 'Regular',
      ethnicity: 'Caucasian',
      skinTone: 'Medium',
      hairColor: 'Brown',
      hairStyle: 'Short',
      eyeColor: 'Brown',
      gender: 'Male',
      age: 28,
    ),
    metadata: AvatarMetadata(
      fileSize: 10485760, // 10MB
      fileFormat: 'glb',
      polyCount: 25000,
      modelVersion: '1.2',
      textures: ['diffuse', 'normal', 'roughness'],
      isOptimized: true,
      qualityLevel: 'High',
      lastUsed: DateTime.now(),
    ),
    isDefault: true,
    isFavorite: true,
    usageCount: 15,
    tags: ['featured', 'recent'],
    description: 'Sample avatar for demonstration',
    state: AvatarState.ready,
    heightAdjust: 0.0,
    chestSize: 1.0,
    waistSize: 1.0,
    hipSize: 1.0,
    lighting: LightingPreset.neutral,
  );

  // State management
  ModelQualityLevel _selectedQuality = ModelQualityLevel.medium;
  bool _enableAutoRotate = true;
  bool _enableScreenshot = true;
  bool _enableFullscreen = true;
  bool _showControls = true;
  
  // Services (would be properly initialized in real app)
  ModelCacheService? _cacheService;
  ModelLoadingService? _modelLoadingService;
  TryOnModelRenderer? _renderer;
  TryOnAPIService? _tryOnAPIService;
  
  // Performance tracking
  String _performanceLog = '';
  List<String> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  void _initializeServices() async {
    try {
      // Initialize cache service
      final prefs = await SharedPreferences.getInstance();
      _cacheService = ModelCacheService(prefs);
      
      // Initialize model loading service
      final apiService = ApiService();
      _modelLoadingService = ModelLoadingService(apiService._client, prefs);
      
      // Initialize try-on API service
      _tryOnAPIService = TryOnAPIService(
        apiService._client,
        _cacheService!,
        _modelLoadingService!,
      );
      
      _logEvent('Services initialized successfully');
      
    } catch (e) {
      _logEvent('Service initialization failed: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('3D Try-On Viewer Demo'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: _showPerformanceDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Product info card
          _buildProductInfoCard(),
          
          // Avatar selector
          _buildAvatarSelector(),
          
          // Quality selector
          _buildQualitySelector(),
          
          // 3D Try-On Viewer
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildTryOnViewer(),
              ),
            ),
          ),
          
          // Control panel
          _buildControlPanel(),
        ],
      ),
    );
  }
  
  Widget _buildProductInfoCard() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(_sampleProduct.primaryImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SizedBox(width: 16),
          
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sampleProduct.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₹${_sampleProduct.currentPrice.toInt()}',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${_sampleProduct.averageRating.toStringAsFixed(1)} (${_sampleProduct.rating.totalReviews} reviews)',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 3D model indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _sampleProduct.has3DModel ? Colors.green : Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _sampleProduct.has3DModel ? Icons.view_in_ar : Icons.image,
                  color: Colors.white,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  _sampleProduct.has3DModel ? '3D Available' : '2D Only',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAvatarSelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: Colors.blue, size: 20),
          SizedBox(width: 8),
          Text(
            'Avatar: ${_sampleAvatar.name}',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_sampleAvatar.attributes.bodyType}',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQualitySelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.tune, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Quality:',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ModelQualityLevel.values.map((quality) {
                final isSelected = _selectedQuality == quality;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedQuality = quality),
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      padding: EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey[700],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        quality.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[300],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTryOnViewer() {
    return Advanced3DTryOnViewer(
      product: _sampleProduct,
      avatar: _sampleAvatar,
      initialQuality: _selectedQuality,
      enableAutoRotate: _enableAutoRotate,
      enableScreenshot: _enableScreenshot,
      enableFullscreen: _enableFullscreen,
      showControls: _showControls,
      onError: _handleError,
      onModelLoaded: _handleModelLoaded,
      onQualityChanged: _handleQualityChanged,
      onScreenshotCaptured: _handleScreenshotCaptured,
    );
  }
  
  Widget _buildControlPanel() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Demo Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToggleButton(
                'Auto Rotate',
                _enableAutoRotate,
                Icons.rotate_right,
                (value) => setState(() => _enableAutoRotate = value),
              ),
              _buildToggleButton(
                'Screenshot',
                _enableScreenshot,
                Icons.camera,
                (value) => setState(() => _enableScreenshot = value),
              ),
              _buildToggleButton(
                'Fullscreen',
                _enableFullscreen,
                Icons.fullscreen,
                (value) => setState(() => _enableFullscreen = value),
              ),
              _buildToggleButton(
                'Controls',
                _showControls,
                Icons.tune,
                (value) => setState(() => _showControls = value),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testAPIIntegration,
                  icon: Icon(Icons.api, size: 16),
                  label: Text('Test API'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _clearCache,
                  icon: Icon(Icons.clear, size: 16),
                  label: Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleButton(
    String label,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: value ? Colors.blue : Colors.grey[400],
          size: 20,
        ),
        SizedBox(height: 4),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.blue,
        ),
        Text(
          label,
          style: TextStyle(
            color: value ? Colors.blue : Colors.grey[400],
            fontSize: 10,
          ),
        ),
      ],
    );
  }
  
  // ==================== EVENT HANDLERS ====================
  
  void _handleError(String error) {
    setState(() {
      _events.add('Error: $error');
    });
    _logEvent('Error: $error');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $error'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _handleModelLoaded() {
    setState(() {
      _events.add('Model loaded successfully');
    });
    _logEvent('Model loaded successfully');
  }
  
  void _handleQualityChanged(double quality) {
    _logEvent('Quality changed to: ${ModelQualityLevel.values[quality.toInt()].label}');
  }
  
  void _handleScreenshotCaptured(ScreenshotResult result) {
    if (result.isSuccess) {
      _showSuccess('Screenshot saved: ${result.fileName}');
      _logEvent('Screenshot captured: ${result.fileName} (${result.fileSizeInMB.toStringAsFixed(1)} MB)');
    } else {
      _handleError(result.error ?? 'Screenshot failed');
    }
  }
  
  // ==================== DEMO ACTIONS ====================
  
  Future<void> _testAPIIntegration() async {
    if (_tryOnAPIService == null) {
      _handleError('Services not initialized');
      return;
    }
    
    _logEvent('Testing API integration...');
    
    try {
      // Test service availability
      final availability = await _tryOnAPIService!.checkServiceAvailability();
      _logEvent('Service available: ${availability.isAvailable}');
      
      if (availability.isAvailable) {
        // Test render request
        final renderResult = await _tryOnAPIService!.requestTryOnRender(
          productId: _sampleProduct.id,
          productName: _sampleProduct.name,
          avatar: _sampleAvatar,
          quality: _selectedQuality,
        );
        
        if (renderResult.isSuccess) {
          _logEvent('Render successful: ${renderResult.modelSizeInMB.toStringAsFixed(1)} MB');
          _showSuccess('API test successful!');
        } else {
          _handleError(renderResult.error ?? 'Render failed');
        }
      }
      
    } catch (e) {
      _handleError('API test failed: $e');
    }
  }
  
  Future<void> _clearCache() async {
    if (_cacheService == null) {
      _handleError('Cache service not initialized');
      return;
    }
    
    await _cacheService.disposeUnusedModels();
    _logEvent('Cache cleared');
    _showSuccess('Cache cleared successfully');
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text('Viewer Settings', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Demo Configuration', style: TextStyle(color: Colors.grey[300])),
            SizedBox(height: 16),
            Text('Product: ${_sampleProduct.name}'),
            Text('Avatar: ${_sampleAvatar.name}'),
            Text('Quality: ${_selectedQuality.label}'),
            Text('3D Support: ${_sampleProduct.has3DModel ? "Yes" : "No"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  void _showPerformanceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[800],
        title: Text('Performance Log', style: TextStyle(color: Colors.white)),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[_events.length - 1 - index]; // Reverse order
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• $event',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(() => _events.clear()),
            child: Text('Clear Log', style: TextStyle(color: Colors.orange)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  void _logEvent(String message) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    final logMessage = '[$timestamp] $message';
    
    setState(() {
      _performanceLog = '$_performanceLog\n$logMessage';
    });
    
    debugPrint(logMessage);
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}