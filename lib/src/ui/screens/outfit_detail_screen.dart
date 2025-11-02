import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';
import '../../src/widgets/app_button.dart';
import '../../src/widgets/app_card.dart';

/// Outfit Detail Screen - View and Manage Individual Outfits
/// 
/// Provides comprehensive outfit management including:
/// - View outfit details and items
/// - Mark outfit as worn
/// - Edit outfit information
/// - Share outfit with others
/// - Delete outfit
class OutfitDetailScreen extends ConsumerStatefulWidget {
  final Outfit outfit;

  const OutfitDetailScreen({
    super.key,
    required this.outfit,
  });

  @override
  ConsumerState<OutfitDetailScreen> createState() => _OutfitDetailScreenState();
}

class _OutfitDetailScreenState extends ConsumerState<OutfitDetailScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // UI state
  bool _isEditMode = false;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  
  // Edit state
  String _editName = '';
  String _editDescription = '';
  OutfitCategory _editCategory = OutfitCategory.casual;
  Season _editSeason = Season.all;
  Occasion _editOccasion = Occasion.everyday;
  List<String> _editTags = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    // Initialize edit state
    _loadEditState();
    
    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadEditState() {
    setState(() {
      _editName = widget.outfit.name;
      _editDescription = widget.outfit.description ?? '';
      _editCategory = widget.outfit.category;
      _editSeason = widget.outfit.season;
      _editOccasion = widget.outfit.occasion;
      _editTags = List.from(widget.outfit.tags);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            actions: [
              // Share button
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareOutfit,
              ),
              
              // More options
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.download),
                      title: Text('Export'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(value as String),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.outfit.name,
                style: const TextStyle(color: Colors.white),
              ),
              background: _buildHeaderImage(),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildContent(),
              ),
            ),
          ),
        ],
      ),
      
      // Bottom action bar
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildHeaderImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Primary image
        if (widget.outfit.images.isNotEmpty)
          Image.network(
            widget.outfit.images[_currentImageIndex].imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage();
            },
          )
        else if (widget.outfit.primaryImage != null)
          Image.network(
            widget.outfit.primaryImage!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildFallbackImage();
            },
          )
        else
          _buildFallbackImage(),
        
        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black54,
              ],
            ),
          ),
        ),
        
        // Image indicators
        if (widget.outfit.images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${widget.outfit.images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.style,
          size: 64,
          color: Colors.white54,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outfit overview
          _buildOutfitOverview(),
          
          const SizedBox(height: 24),
          
          // Description
          _buildDescriptionSection(),
          
          const SizedBox(height: 24),
          
          // Metadata
          _buildMetadataSection(),
          
          const SizedBox(height: 24),
          
          // Tags
          if (_editTags.isNotEmpty) _buildTagsSection(),
          
          const SizedBox(height: 24),
          
          // Items
          _buildItemsSection(),
          
          const SizedBox(height: 24),
          
          // Stats
          _buildStatsSection(),
          
          const SizedBox(height: 24),
          
          // Reviews (if public)
          if (widget.outfit.isPublic && widget.outfit.rating.reviews.isNotEmpty)
            _buildReviewsSection(),
        ],
      ),
    );
  }

  Widget _buildOutfitOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _isEditMode
                      ? TextFormField(
                          initialValue: _editName,
                          decoration: const InputDecoration(
                            labelText: 'Outfit Name',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _editName = value;
                            });
                          },
                        )
                      : Text(
                          widget.outfit.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                ),
                
                const SizedBox(width: 8),
                
                if (widget.outfit.isFavorited)
                  Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Category, Season, Occasion
            Row(
              children: [
                Chip(
                  label: Text(_getCategoryDisplayName(widget.outfit.category)),
                  avatar: const Icon(Icons.category, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_getSeasonDisplayName(widget.outfit.season)),
                  avatar: const Icon(Icons.wb_sunny, size: 16),
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text(_getOccasionDisplayName(widget.outfit.occasion)),
                  avatar: const Icon(Icons.event, size: 16),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Stats row
            Row(
              children: [
                _buildStatItem('${widget.outfit.items.length} items'),
                const SizedBox(width: 16),
                _buildStatItem('₹${_calculateTotalValue().toStringAsFixed(0)}'),
                const SizedBox(width: 16),
                _buildStatItem('${widget.outfit.wearCount} wears'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _isEditMode
                ? TextFormField(
                    initialValue: _editDescription,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _editDescription = value;
                      });
                    },
                  )
                : Text(
                    widget.outfit.description?.isNotEmpty == true
                        ? widget.outfit.description!
                        : 'No description added yet.',
                    style: widget.outfit.description?.isNotEmpty == true
                        ? Theme.of(context).textTheme.bodyMedium
                        : Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 8),
                Text(
                  'Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildMetadataItem('Created', _formatDate(widget.outfit.createdAt)),
            _buildMetadataItem('Last Modified', _formatDate(widget.outfit.lastModified)),
            
            if (widget.outfit.lastWornDate != null)
              _buildMetadataItem('Last Worn', _formatDate(widget.outfit.lastWornDate!)),
            
            _buildMetadataItem('Visibility', widget.outfit.isPublic ? 'Public' : 'Private'),
            
            if (widget.outfit.totalLikes != null && widget.outfit.totalLikes! > 0)
              _buildMetadataItem('Likes', widget.outfit.totalLikes.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tag),
                const SizedBox(width: 8),
                Text(
                  'Tags',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _editTags.map((tag) {
                return Chip(
                  label: Text(tag),
                  onDeleted: _isEditMode ? () {
                    setState(() {
                      _editTags.remove(tag);
                    });
                  } : null,
                );
              }).toList(),
            ),
            
            if (_isEditMode)
              const SizedBox(height: 8),
            
            if (_isEditMode)
              ActionChip(
                label: const Text('Add Tag'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: _addTag,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checkroom),
                const SizedBox(width: 8),
                Text(
                  'Outfit Items',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.outfit.items.length,
              itemBuilder: (context, index) {
                final outfitItem = widget.outfit.items[index];
                return _buildOutfitItemCard(outfitItem, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart),
                const SizedBox(width: 8),
                Text(
                  'Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Times Worn',
                    widget.outfit.wearCount.toString(),
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Cost Per Wear',
                    '₹${_calculateCostPerWear().toStringAsFixed(0)}',
                    Icons.trending_up,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Value',
                    '₹${_calculateTotalValue().toStringAsFixed(0)}',
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    'Days Since Last Worn',
                    _calculateDaysSinceLastWorn().toString(),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review),
                const SizedBox(width: 8),
                Text(
                  'Reviews',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 8),
                Text(
                  '(${widget.outfit.rating.totalLikes} likes)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...widget.outfit.rating.reviews.take(3).map((review) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(review.userAvatar),
                          radius: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.userName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                _formatDate(review.createdAt),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(review.comment),
                  ],
                ),
              );
            }).toList(),
            
            if (widget.outfit.rating.reviews.length > 3)
              TextButton(
                onPressed: () => _showAllReviews(),
                child: Text('View all ${widget.outfit.rating.reviews.length} reviews'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutfitItemCard(OutfitItem outfitItem, int index) {
    final item = outfitItem.closetItem;
    
    return GestureDetector(
      onTap: () => _navigateToItemDetail(item),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with order indicator
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.network(
                      item.product.primaryImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
                
                // Order number
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    width: 24,
                    height: 24,
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const Spacer(),
                    
                    Text(
                      '${item.selectedSize} • ${item.selectedColor}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    
                    Text(
                      item.product.vendor.name,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetadataItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _markAsWorn,
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Worn'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isEditMode ? _saveChanges : _enterEditMode,
              icon: Icon(_isEditMode ? Icons.save : Icons.edit),
              label: Text(_isEditMode ? 'Save Changes' : 'Edit Outfit'),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ACTION HANDLERS ====================

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _enterEditMode();
        break;
      case 'duplicate':
        _duplicateOutfit();
        break;
      case 'export':
        _exportOutfit();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  void _enterEditMode() {
    setState(() {
      _isEditMode = true;
    });
    _loadEditState();
  }

  void _saveChanges() async {
    if (_editName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an outfit name')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedOutfit = widget.outfit.copyWith(
        name: _editName.trim(),
        description: _editDescription.trim().isEmpty ? null : _editDescription.trim(),
        category: _editCategory,
        season: _editSeason,
        occasion: _editOccasion,
        tags: _editTags,
        lastModified: DateTime.now(),
      );
      
      await ref.read(closetProvider.notifier).updateOutfit(updatedOutfit);
      
      // Update local outfit reference
      // This would normally be handled by the provider
      if (mounted) {
        setState(() {
          _isEditMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Outfit updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating outfit: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _markAsWorn() {
    ref.read(closetProvider.notifier).markOutfitAsWorn(widget.outfit.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${widget.outfit.name}" marked as worn')),
    );
  }

  void _shareOutfit() {
    // Share outfit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share outfit functionality coming soon')),
    );
  }

  void _duplicateOutfit() {
    ref.read(closetProvider.notifier).createOutfit(
      name: '${widget.outfit.name} (Copy)',
      description: widget.outfit.description,
      items: widget.outfit.items.map((item) {
        return item.copyWith(
          id: 'copy_${DateTime.now().millisecondsSinceEpoch}_${item.id}',
        );
      }).toList(),
      category: widget.outfit.category,
      season: widget.outfit.season,
      occasion: widget.outfit.occasion,
      tags: widget.outfit.tags,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit duplicated successfully')),
    );
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _exportOutfit() {
    // Export outfit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Outfit'),
        content: Text('Are you sure you want to delete "${widget.outfit.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(closetProvider.notifier).deleteOutfit(widget.outfit.id);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Outfit deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Tag name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _editTags.add(value.trim());
              });
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAllReviews() {
    // Show all reviews dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full reviews view coming soon')),
    );
  }

  // ==================== UTILITY METHODS ====================

  double _calculateTotalValue() {
    return widget.outfit.items.fold(0.0, (sum, item) => sum + item.closetItem.purchasePrice);
  }

  double _calculateCostPerWear() {
    if (widget.outfit.wearCount == 0) return _calculateTotalValue();
    return _calculateTotalValue() / widget.outfit.wearCount;
  }

  int _calculateDaysSinceLastWorn() {
    if (widget.outfit.lastWornDate == null) return -1;
    return DateTime.now().difference(widget.outfit.lastWornDate!).inDays;
  }

  void _navigateToItemDetail(ClosetItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(closetItem: item),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getCategoryDisplayName(OutfitCategory category) {
    switch (category) {
      case OutfitCategory.casual:
        return 'Casual';
      case OutfitCategory.formal:
        return 'Formal';
      case OutfitCategory.business:
        return 'Business';
      case OutfitCategory.sporty:
        return 'Sporty';
      case OutfitCategory.party:
        return 'Party';
      case OutfitCategory.date:
        return 'Date';
      case OutfitCategory.work:
        return 'Work';
      case OutfitCategory.weekend:
        return 'Weekend';
      case OutfitCategory.travel:
        return 'Travel';
      case OutfitCategory.special:
        return 'Special';
    }
  }

  String _getSeasonDisplayName(Season season) {
    switch (season) {
      case Season.spring:
        return 'Spring';
      case Season.summer:
        return 'Summer';
      case Season.fall:
        return 'Fall';
      case Season.winter:
        return 'Winter';
      case Season.all:
        return 'All Seasons';
    }
  }

  String _getOccasionDisplayName(Occasion occasion) {
    switch (occasion) {
      case Occasion.everyday:
        return 'Everyday';
      case Occasion.work:
        return 'Work';
      case Occasion.formal:
        return 'Formal';
      case Occasion.casual:
        return 'Casual';
      case Occasion.party:
        return 'Party';
      case Occasion.date:
        return 'Date';
      case Occasion.exercise:
        return 'Exercise';
      case Occasion.travel:
        return 'Travel';
      case Occasion.interview:
        return 'Interview';
      case Occasion.wedding:
        return 'Wedding';
    }
  }
}