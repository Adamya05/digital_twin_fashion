import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';
import '../../src/widgets/app_button.dart';
import '../../src/widgets/app_card.dart';

/// Item Detail Screen - View and Manage Individual Closet Items
/// 
/// Provides comprehensive item management including:
/// - View item details, images, and specifications
/// - Try on functionality
/// - Mark as worn
/// - Edit item information
/// - Add to cart
/// - Remove from closet
class ItemDetailScreen extends ConsumerStatefulWidget {
  final ClosetItem closetItem;

  const ItemDetailScreen({
    super.key,
    required this.closetItem,
  });

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen>
    with TickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // UI state
  bool _isEditMode = false;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  bool _showFullDescription = false;
  
  // Edit state
  String _editNotes = '';
  String _editSize = '';
  String _editColor = '';
  List<String> _editTags = [];
  ItemCondition _editCondition = ItemCondition.newItem;

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
      _editNotes = widget.closetItem.notes ?? '';
      _editSize = widget.closetItem.selectedSize;
      _editColor = widget.closetItem.selectedColor;
      _editTags = List.from(widget.closetItem.customTags);
      _editCondition = widget.closetItem.condition;
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
              // Favorite toggle
              IconButton(
                icon: Icon(
                  widget.closetItem.isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: widget.closetItem.isFavorited 
                      ? Theme.of(context).colorScheme.error 
                      : null,
                ),
                onPressed: _toggleFavorite,
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
                    value: 'add_to_outfit',
                    child: ListTile(
                      leading: Icon(Icons.style),
                      title: Text('Add to Outfit'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Remove from Closet', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                onSelected: (value) => _handleMenuAction(value as String),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.closetItem.product.name,
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
        // Product images
        if (widget.closetItem.product.images.isNotEmpty)
          PageView.builder(
            itemCount: widget.closetItem.product.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                widget.closetItem.product.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackImage();
                },
              );
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
        if (widget.closetItem.product.images.length > 1)
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
                '${_currentImageIndex + 1}/${widget.closetItem.product.images.length}',
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
          Icons.checkroom,
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
          // Basic info
          _buildBasicInfoSection(),
          
          const SizedBox(height: 24),
          
          // Description
          _buildDescriptionSection(),
          
          const SizedBox(height: 24),
          
          // Product details
          _buildProductDetailsSection(),
          
          const SizedBox(height: 24),
          
          // Custom info
          _buildCustomInfoSection(),
          
          const SizedBox(height: 24),
          
          // Usage history
          _buildUsageHistorySection(),
          
          const SizedBox(height: 24),
          
          // Purchase info
          _buildPurchaseInfoSection(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.closetItem.product.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        widget.closetItem.product.vendor.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          Chip(
                            label: Text(widget.closetItem.selectedSize),
                            avatar: const Icon(Icons.straighten, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(widget.closetItem.selectedColor),
                            avatar: const Icon(Icons.palette, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_getConditionDisplayName(widget.closetItem.condition)),
                            avatar: const Icon(Icons.grade, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${widget.closetItem.purchasePrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    if (widget.closetItem.isOnSale) ...[
                      const SizedBox(height: 4),
                      Text(
                        '₹${widget.closetItem.salePrice.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
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
                    initialValue: _editNotes,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Add your notes about this item',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    onChanged: (value) {
                      setState(() {
                        _editNotes = value;
                      });
                    },
                  )
                : Text(
                    widget.closetItem.notes?.isNotEmpty == true
                        ? widget.closetItem.notes!
                        : widget.closetItem.product.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: _showFullDescription ? null : 3,
                    overflow: _showFullDescription 
                        ? TextOverflow.visible 
                        : TextOverflow.ellipsis,
                  ),
            
            if (widget.closetItem.notes?.isNotEmpty == true && 
                widget.closetItem.product.description.length > 100)
              TextButton(
                onPressed: () {
                  setState(() {
                    _showFullDescription = !_showFullDescription;
                  });
                },
                child: Text(_showFullDescription ? 'Show Less' : 'Show More'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetailsSection() {
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
                  'Product Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailItem('Category', widget.closetItem.product.category),
            _buildDetailItem('Subcategory', widget.closetItem.product.subcategory),
            _buildDetailItem('Material', widget.closetItem.product.metadata.material),
            _buildDetailItem('Pattern', widget.closetItem.product.metadata.pattern),
            _buildDetailItem('Style', widget.closetItem.product.metadata.style),
            _buildDetailItem('SKU', widget.closetItem.product.metadata.sku),
            
            if (widget.closetItem.product.metadata.careInstructions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Care Instructions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...widget.closetItem.product.metadata.careInstructions.map((instruction) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(instruction)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note),
                const SizedBox(width: 8),
                Text(
                  'Your Customization',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Size and Color editing
            if (_isEditMode) ...[
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _editSize,
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.closetItem.product.availableSizes.map((size) {
                        return DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _editSize = value;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _editColor,
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.closetItem.product.availableColors.map((color) {
                        return DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _editColor = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Condition selector
              DropdownButtonFormField<ItemCondition>(
                value: _editCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: ItemCondition.values.map((condition) {
                  return DropdownMenuItem<ItemCondition>(
                    value: condition,
                    child: Text(_getConditionDisplayName(condition)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _editCondition = value;
                    });
                  }
                },
              ),
            ] else ...[
              _buildDetailItem('Size', widget.closetItem.selectedSize),
              _buildDetailItem('Color', widget.closetItem.selectedColor),
              _buildDetailItem('Condition', _getConditionDisplayName(widget.closetItem.condition)),
            ],
            
            const SizedBox(height: 16),
            
            // Custom tags
            Text(
              'Custom Tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...widget.closetItem.customTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: _isEditMode ? () {
                      setState(() {
                        widget.closetItem.customTags.remove(tag);
                      });
                    } : null,
                  );
                }).toList(),
                ..._editTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: _isEditMode ? () {
                      setState(() {
                        _editTags.remove(tag);
                      });
                    } : null,
                  );
                }).toList(),
                
                if (_isEditMode)
                  ActionChip(
                    label: const Text('Add Tag'),
                    avatar: const Icon(Icons.add, size: 16),
                    onPressed: _addCustomTag,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 8),
                Text(
                  'Usage History',
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
                    widget.closetItem.wearCount.toString(),
                    Icons.check_circle,
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
            
            const SizedBox(height: 16),
            
            if (widget.closetItem.lastWornDate != null)
              Text(
                'Last worn on ${_formatDate(widget.closetItem.lastWornDate!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            
            const SizedBox(height: 8),
            
            if (widget.closetItem.usageHistory.isNotEmpty) ...[
              Text(
                'Recent Usage:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              
              ...widget.closetItem.usageHistory.take(3).map((usage) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_formatDate(usage.wornDate)),
                            if (usage.notes != null && usage.notes!.isNotEmpty)
                              Text(
                                usage.notes!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              
              if (widget.closetItem.usageHistory.length > 3)
                TextButton(
                  onPressed: () => _showFullUsageHistory(),
                  child: Text('View all ${widget.closetItem.usageHistory.length} usage records'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag),
                const SizedBox(width: 8),
                Text(
                  'Purchase Information',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildDetailItem('Added to Closet', _formatDate(widget.closetItem.savedAt)),
            
            if (widget.closetItem.purchaseDate != null)
              _buildDetailItem('Purchase Date', _formatDate(widget.closetItem.purchaseDate!)),
            
            _buildDetailItem('Purchase Price', '₹${widget.closetItem.purchasePrice.toStringAsFixed(0)}'),
            
            if (widget.closetItem.wearCount > 0)
              _buildDetailItem('Cost Per Wear', '₹${_calculateCostPerWear().toStringAsFixed(0)}'),
            
            if (widget.closetItem.isOnSale)
              _buildDetailItem('Sale Price', '₹${widget.closetItem.salePrice.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
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
              onPressed: _isEditMode ? _saveChanges : _tryOn,
              icon: Icon(_isEditMode ? Icons.save : Icons.person),
              label: Text(_isEditMode ? 'Save Changes' : 'Try On'),
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
        _duplicateItem();
        break;
      case 'add_to_outfit':
        _addToOutfit();
        break;
      case 'remove':
        _showRemoveConfirmation();
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
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedItem = widget.closetItem.copyWith(
        notes: _editNotes.trim().isEmpty ? null : _editNotes.trim(),
        selectedSize: _editSize,
        selectedColor: _editColor,
        customTags: _editTags,
        condition: _editCondition,
      );
      
      await ref.read(closetProvider.notifier).updateClosetItem(updatedItem);
      
      if (mounted) {
        setState(() {
          _isEditMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleFavorite() {
    ref.read(closetProvider.notifier).toggleFavorite(widget.closetItem.id);
  }

  void _markAsWorn() {
    ref.read(closetProvider.notifier).markAsWorn(
      widget.closetItem.id,
      notes: 'Marked as worn',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${widget.closetItem.product.name}" marked as worn')),
    );
  }

  void _tryOn() {
    // Navigate to try-on screen
    Navigator.pushNamed(
      context,
      '/tryon-viewer',
      arguments: widget.closetItem.product,
    );
  }

  void _addToOutfit() {
    Navigator.pushNamed(
      context,
      '/outfit-builder',
      arguments: widget.closetItem,
    );
  }

  void _duplicateItem() {
    // Duplicate item logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Duplicate feature coming soon')),
    );
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Closet'),
        content: Text('Are you sure you want to remove "${widget.closetItem.product.name}" from your closet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(closetProvider.notifier).removeFromCloset(widget.closetItem.id);
              
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item removed from closet')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addCustomTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Tag'),
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

  void _showFullUsageHistory() {
    // Show full usage history
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Full usage history view coming soon')),
    );
  }

  // ==================== UTILITY METHODS ====================

  double _calculateCostPerWear() {
    if (widget.closetItem.wearCount == 0) return widget.closetItem.purchasePrice;
    return widget.closetItem.purchasePrice / widget.closetItem.wearCount;
  }

  int _calculateDaysSinceLastWorn() {
    if (widget.closetItem.lastWornDate == null) return -1;
    return DateTime.now().difference(widget.closetItem.lastWornDate!).inDays;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getConditionDisplayName(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.newItem:
        return 'New';
      case ItemCondition.excellent:
        return 'Excellent';
      case ItemCondition.good:
        return 'Good';
      case ItemCondition.fair:
        return 'Fair';
      case ItemCondition.poor:
        return 'Poor';
      case ItemCondition.wornOut:
        return 'Worn Out';
    }
  }
}