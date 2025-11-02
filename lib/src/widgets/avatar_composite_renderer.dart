import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/avatar_model.dart';
import '../models/product_model.dart';

/// Avatar composite renderer utility for creating optimized avatar + product composites
/// Handles caching, lazy loading, and performance optimization
class AvatarCompositeRenderer {
  static final AvatarCompositeRenderer _instance = AvatarCompositeRenderer._internal();
  factory AvatarCompositeRenderer() => _instance;
  AvatarCompositeRenderer._internal();

  // Cache for composite images
  final Map<String, ui.Image> _compositeCache = {};
  final Map<String, Completer<ui.Image>> _loadingCache = {};
  
  // Maximum cache size to prevent memory issues
  static const int _maxCacheSize = 50;

  /// Generate composite image for product + avatar combination
  Future<ui.Image?> generateComposite({
    required Product product,
    required Avatar avatar,
    CompositeOptions options = const CompositeOptions(),
  }) async {
    final cacheKey = _generateCacheKey(product.id, avatar.id, options);
    
    // Return cached image if available
    if (_compositeCache.containsKey(cacheKey)) {
      return _compositeCache[cacheKey];
    }
    
    // Return existing loading task if in progress
    if (_loadingCache.containsKey(cacheKey)) {
      return _loadingCache[cacheKey]?.future;
    }
    
    // Start new composite generation
    final completer = Completer<ui.Image>();
    _loadingCache[cacheKey] = completer;
    
    try {
      final compositeImage = await _createCompositeImage(product, avatar, options);
      
      if (compositeImage != null) {
        _cacheImage(cacheKey, compositeImage);
        completer.complete(compositeImage);
      } else {
        completer.completeError('Failed to create composite image');
      }
    } catch (e) {
      completer.completeError(e);
    }
    
    _loadingCache.remove(cacheKey);
    return completer.future;
  }

  /// Preload composite images for better performance
  Future<void> preloadComposites({
    required List<Product> products,
    required List<Avatar> avatars,
    CompositeOptions options = const CompositeOptions(),
  }) async {
    final futures = <Future>[];
    
    for (int i = 0; i < math.min(products.length, avatars.length); i++) {
      futures.add(generateComposite(
        product: products[i],
        avatar: avatars[i],
        options: options,
      ));
    }
    
    await Future.wait(futures);
  }

  /// Clear composite image cache
  void clearCache() {
    _compositeCache.clear();
    _loadingCache.clear();
  }

  /// Get cache size
  int get cacheSize => _compositeCache.length;

  /// Clean up old cache entries
  void _cacheImage(String key, ui.Image image) {
    // Remove oldest entries if cache is full
    if (_compositeCache.length >= _maxCacheSize) {
      final oldestKey = _compositeCache.keys.first;
      _compositeCache[oldestKey]?.dispose();
      _compositeCache.remove(oldestKey);
    }
    
    _compositeCache[key] = image;
  }

  String _generateCacheKey(String productId, String avatarId, CompositeOptions options) {
    return '${productId}_${avatarId}_${options.hashCode}';
  }

  Future<ui.Image?> _createCompositeImage(
    Product product,
    Avatar avatar,
    CompositeOptions options,
  ) async {
    try {
      // Load product image
      final productImage = await _loadImageFromUrl(product.imageUrl);
      if (productImage == null) return null;

      // Load avatar image
      final avatarImage = await _loadImageFromUrl(avatar.thumbnailUrl);
      if (avatarImage == null) return null;

      // Create composite canvas
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      
      // Set canvas size based on product image
      final canvasSize = Size(
        productImage.width.toDouble(),
        productImage.height.toDouble(),
      );
      
      // Draw background product image
      canvas.drawImage(productImage, Offset.zero, Paint());
      
      // Calculate avatar positioning based on options
      final avatarPosition = _calculateAvatarPosition(
        canvasSize,
        options.avatarPosition,
        options.avatarSize,
      );
      
      // Create avatar circular clip
      final avatarRect = Rect.fromCircle(
        center: avatarPosition,
        radius: options.avatarSize / 2,
      );
      
      canvas.save();
      canvas.clipPath(Path()..addOval(avatarRect));
      
      // Draw avatar image
      canvas.drawImage(
        avatarImage,
        Offset(
          avatarPosition.dx - (avatarImage.width / 2),
          avatarPosition.dy - (avatarImage.height / 2),
        ),
        Paint()..color = options.avatarOpacity,
      );
      
      canvas.restore();
      
      // Draw border if enabled
      if (options.showBorder) {
        final borderPaint = Paint()
          ..color = options.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = options.borderWidth;
        
        canvas.drawOval(avatarRect, borderPaint);
      }
      
      // Add shadow effect if enabled
      if (options.showShadow) {
        final shadowPaint = Paint()
          ..color = options.shadowColor.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, options.shadowBlur);
        
        canvas.drawOval(avatarRect, shadowPaint);
      }
      
      // Create final image
      final compositeImage = await pictureRecorder.endRecording().toImage(
        productImage.width,
        productImage.height,
      );
      
      return compositeImage;
    } catch (e) {
      debugPrint('Error creating composite image: $e');
      return null;
    }
  }

  Offset _calculateAvatarPosition(
    Size canvasSize,
    AvatarPosition position,
    double avatarSize,
  ) {
    final padding = 16.0;
    
    switch (position) {
      case AvatarPosition.topRight:
        return Offset(
          canvasSize.width - (avatarSize / 2) - padding,
          (avatarSize / 2) + padding,
        );
      case AvatarPosition.topLeft:
        return Offset(
          (avatarSize / 2) + padding,
          (avatarSize / 2) + padding,
        );
      case AvatarPosition.bottomRight:
        return Offset(
          canvasSize.width - (avatarSize / 2) - padding,
          canvasSize.height - (avatarSize / 2) - padding,
        );
      case AvatarPosition.bottomLeft:
        return Offset(
          (avatarSize / 2) + padding,
          canvasSize.height - (avatarSize / 2) - padding,
        );
      case AvatarPosition.center:
        return Offset(
          canvasSize.width / 2,
          canvasSize.height / 2,
        );
    }
  }

  Future<ui.Image?> _loadImageFromUrl(String url) async {
    if (url.isEmpty) return null;
    
    try {
      if (url.startsWith('http')) {
        final response = await HttpClient().getUrl(Uri.parse(url));
        final request = await response.close();
        final bytes = await request.expand((e) => e).toList();
        final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
        final frame = await codec.getNextFrame();
        return frame.image;
      } else {
        // Handle local assets or file paths
        // This would need implementation based on your asset system
        return null;
      }
    } catch (e) {
      debugPrint('Error loading image from URL: $e');
      return null;
    }
  }
}

/// Configuration options for avatar composite generation
class CompositeOptions {
  final AvatarPosition avatarPosition;
  final double avatarSize;
  final double avatarOpacity;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;
  final bool showShadow;
  final Color shadowColor;
  final double shadowBlur;

  const CompositeOptions({
    this.avatarPosition = AvatarPosition.topRight,
    this.avatarSize = 60.0,
    this.avatarOpacity = 1.0,
    this.showBorder = true,
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.showShadow = true,
    this.shadowColor = Colors.black,
    this.shadowBlur = 8.0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositeOptions &&
          other.avatarPosition == avatarPosition &&
          other.avatarSize == avatarSize &&
          other.avatarOpacity == avatarOpacity &&
          other.showBorder == showBorder &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.showShadow == showShadow &&
          other.shadowColor == shadowColor &&
          other.shadowBlur == shadowBlur;

  @override
  int get hashCode => Object.hash(
    avatarPosition,
    avatarSize,
    avatarOpacity,
    showBorder,
    borderColor,
    borderWidth,
    showShadow,
    shadowColor,
    shadowBlur,
  );
}

/// Avatar position options for composite rendering
enum AvatarPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

/// Widget for displaying cached composite images with lazy loading
class CachedCompositeImage extends StatelessWidget {
  final Product product;
  final Avatar avatar;
  final CompositeOptions options;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object)? errorWidget;
  final String? cacheKey;

  const CachedCompositeImage({
    Key? key,
    required this.product,
    required this.avatar,
    this.options = const CompositeOptions(),
    this.placeholder,
    this.errorWidget,
    this.cacheKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ui.Image?>(
      future: AvatarCompositeRenderer().generateComposite(
        product: product,
        avatar: avatar,
        options: options,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return CustomPaint(
            painter: CompositeImagePainter(snapshot.data!),
            size: Size.infinite,
          );
        } else if (snapshot.hasError) {
          return errorWidget?.call(context, snapshot.error!) ??
              _buildDefaultError();
        } else {
          return placeholder ?? _buildDefaultPlaceholder();
        }
      },
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.error_outline,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}

/// Custom painter for rendering cached composite images
class CompositeImagePainter extends CustomPainter {
  final ui.Image image;

  CompositeImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! CompositeImagePainter || 
           oldDelegate.image != image;
  }
}

/// Performance monitoring utility for avatar composites
class CompositePerformanceMonitor {
  static final CompositePerformanceMonitor _instance = CompositePerformanceMonitor._internal();
  factory CompositePerformanceMonitor() => _instance;
  CompositePerformanceMonitor._internal();

  final Map<String, int> _generationTimes = {};
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};

  /// Track composite generation time
  void trackGenerationTime(String key, int milliseconds) {
    _generationTimes[key] = milliseconds;
  }

  /// Track cache hit
  void trackCacheHit(String key) {
    _cacheHits[key] = (_cacheHits[key] ?? 0) + 1;
  }

  /// Track cache miss
  void trackCacheMiss(String key) {
    _cacheMisses[key] = (_cacheMisses[key] ?? 0) + 1;
  }

  /// Get average generation time
  double getAverageGenerationTime() {
    if (_generationTimes.isEmpty) return 0.0;
    
    final total = _generationTimes.values.reduce((a, b) => a + b);
    return total / _generationTimes.length;
  }

  /// Get cache hit rate
  double getCacheHitRate() {
    final total = _cacheHits.values.fold(0, (a, b) => a + b) + 
                  _cacheMisses.values.fold(0, (a, b) => a + b);
    
    if (total == 0) return 0.0;
    
    final hits = _cacheHits.values.fold(0, (a, b) => a + b);
    return hits / total;
  }

  /// Clear all performance metrics
  void clearMetrics() {
    _generationTimes.clear();
    _cacheHits.clear();
    _cacheMisses.clear();
  }

  /// Print performance report
  void printReport() {
    print('=== Avatar Composite Performance Report ===');
    print('Average generation time: ${getAverageGenerationTime().toStringAsFixed(2)}ms');
    print('Cache hit rate: ${(getCacheHitRate() * 100).toStringAsFixed(1)}%');
    print('Cache size: ${AvatarCompositeRenderer().cacheSize}');
    print('Total generations: ${_generationTimes.length}');
    print('==========================================');
  }
}