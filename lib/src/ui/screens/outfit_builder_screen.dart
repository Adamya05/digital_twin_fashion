import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';
import '../../src/widgets/app_button.dart';
import '../../src/widgets/app_card.dart';
import '../../src/widgets/loading_indicator.dart';

/// Outfit Builder Screen - Create and Edit Outfits
/// 
/// Allows users to:
/// - Mix and match closet items to create outfits
/// - Save and name outfits
/// - Apply categories, seasons, and occasions
/// - Add tags and descriptions
/// - Preview outfits
class OutfitBuilderScreen extends ConsumerStatefulWidget {
  final ClosetItem? initialItem;
  final Outfit? existingOutfit;

  const OutfitBuilderScreen({
    super.key,
    this.initialItem,
    this.existingOutfit,
  });

  @override
  ConsumerState<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends ConsumerState<OutfitBuilderScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  // Outfit state
  final List<OutfitItem> _outfitItems = [];
  String _outfitName = '';
  String _outfitDescription = '';
  OutfitCategory _selectedCategory = OutfitCategory.casual;
  Season _selectedSeason = Season.all;
  Occasion _selectedOccasion = Occasion.everyday;
  List<String> _tags = [];
  bool _isPublic = false;
  
  // Filter and search state
  String _searchQuery = '';
  String _selectedCategoryFilter = '';
  List<String> _selectedTags = [];
  
  // UI state
  bool _isPreviewMode = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Initialize with existing outfit or add initial item
    if (widget.existingOutfit != null) {
      _loadExistingOutfit(widget.existingOutfit!);
    } else if (widget.initialItem != null) {
      _addItemToOutfit(widget.initialItem!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closetState = ref.watch(closetProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingOutfit != null ? 'Edit Outfit' : 'Create Outfit'),
        actions: [
          if (_outfitItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.visibility),
              onPressed: _togglePreviewMode,
              tooltip: _isPreviewMode ? 'Edit Mode' : 'Preview Mode',
            ),
          
          if (_outfitItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveOutfit,
              tooltip: 'Save Outfit',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Items', icon: Icon(Icons.checkroom)),
            Tab(text: 'Details', icon: Icon(Icons.edit)),
            Tab(text: 'Preview', icon: Icon(Icons.preview)),
          ],
        ),
      ),
      
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildItemsTab(closetState),
          _buildDetailsTab(),
          _buildPreviewTab(),
        ],
      ),
      
      // Floating Action Button for quick actions
      floatingActionButton: _buildFAB(),
    );
  }

  // ==================== TAB BUILDERS ====================

  Widget _buildItemsTab(ClosetState closetState) {
    if (closetState.isLoadingCloset) {
      return const LoadingIndicator(message: 'Loading closet items...');
    }

    return Column(
      children: [
        // Search and filter bar
        _buildSearchFilterBar(),
        
        // Category tabs for quick filtering
        _buildCategoryTabs(),
        
        // Items grid
        Expanded(
          child: _buildItemsGrid(closetState.filteredClosetItems),
        ),
      ],
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outfit name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Outfit Name *',
              hintText: 'Enter a name for your outfit',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _outfitName = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Description
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Add a description for your outfit',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              setState(() {
                _outfitDescription = value;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Category selector
          _buildSelectorTile(
            'Category',
            _selectedCategory.name,
            Icons.category,
            () => _showCategorySelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Season selector
          _buildSelectorTile(
            'Season',
            _selectedSeason.name,
            Icons.wb_sunny,
            () => _showSeasonSelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Occasion selector
          _buildSelectorTile(
            'Occasion',
            _selectedOccasion.name,
            Icons.event,
            () => _showOccasionSelector(),
          ),
          
          const SizedBox(height: 24),
          
          // Tags
          Text(
            'Tags',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ..._tags.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
              )),
              
              ActionChip(
                label: const Text('Add Tag'),
                avatar: const Icon(Icons.add, size: 16),
                onPressed: _addTag,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Privacy setting
          SwitchListTile(
            title: const Text('Make Public'),
            subtitle: const Text('Allow others to see and like this outfit'),
            value: _isPublic,
            onChanged: (value) {
              setState(() {
                _isPublic = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_outfitItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.style, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Add items to see outfit preview'),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Outfit overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _outfitName.isEmpty ? 'Untitled Outfit' : _outfitName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  
                  if (_outfitDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _outfitDescription,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Chip(
                        label: Text(_selectedCategory.name),
                        avatar: const Icon(Icons.category, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_selectedSeason.name),
                        avatar: const Icon(Icons.wb_sunny, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(_selectedOccasion.name),
                        avatar: const Icon(Icons.event, size: 16),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '${_outfitItems.length} items • ₹${_calculateTotalValue().toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Outfit items preview
          Text(
            'Outfit Items',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _outfitItems.length,
            itemBuilder: (context, index) {
              final item = _outfitItems[index];
              return _buildOutfitItemPreviewCard(item, index);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareOutfit,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveOutfit,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Outfit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search field
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search closet items...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter buttons
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: const Text('Favorites'),
                  selected: _selectedTags.contains('favorite'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add('favorite');
                      } else {
                        _selectedTags.remove('favorite');
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('On Sale'),
                  selected: _selectedTags.contains('sale'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add('sale');
                      } else {
                        _selectedTags.remove('sale');
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('New'),
                  selected: _selectedTags.contains('new'),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add('new');
                      } else {
                        _selectedTags.remove('new');
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', 'Tops', 'Bottoms', 'Dresses', 'Outerwear', 'Shoes', 'Accessories'];
    
    return Container(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = (category == 'All' && _selectedCategoryFilter.isEmpty) ||
                           (category == _selectedCategoryFilter);
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategoryFilter = selected && category != 'All' ? category : '';
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemsGrid(List<ClosetItem> items) {
    final filteredItems = items.where((item) {
      // Apply search filter
      if (_searchQuery.isNotEmpty && !item.matchesSearch(_searchQuery)) {
        return false;
      }
      
      // Apply category filter
      if (_selectedCategoryFilter.isNotEmpty && 
          item.product.category != _selectedCategoryFilter) {
        return false;
      }
      
      // Apply tag filters
      for (final tag in _selectedTags) {
        switch (tag) {
          case 'favorite':
            if (!item.isFavorited) return false;
            break;
          case 'sale':
            if (!item.isOnSale) return false;
            break;
          case 'new':
            if (item.wearCount > 0) return false;
            break;
        }
      }
      
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(closetProvider.notifier).loadClosetItems();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: filteredItems.length,
        itemBuilder: (context, index) {
          final item = filteredItems[index];
          final isInOutfit = _outfitItems.any((outfitItem) => outfitItem.closetItem.id == item.id);
          
          return GestureDetector(
            onTap: () => _addItemToOutfit(item),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isInOutfit ? Theme.of(context).primaryColor : Colors.transparent,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _buildClosetItemCard(item, isInOutfit: isInOutfit),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClosetItemCard(ClosetItem item, {required bool isInOutfit}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          AspectRatio(
            aspectRatio: 1,
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
          
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  item.product.vendor.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${item.purchasePrice.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    
                    if (isInOutfit)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Text(
                  '${item.selectedSize} • ${item.selectedColor}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitItemPreviewCard(OutfitItem outfitItem, int index) {
    final item = outfitItem.closetItem;
    
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with order indicator
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
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
              
              // Remove button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => _removeItemFromOutfit(index),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorTile(String label, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
      trailing: const Icon(Icons.arrow_drop_down),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  Widget _buildFAB() {
    if (_isPreviewMode) return null;
    
    return FloatingActionButton(
      onPressed: () => _showQuickActions(),
      child: const Icon(Icons.add),
    );
  }

  // ==================== OUTFIT ITEM MANAGEMENT ====================

  void _addItemToOutfit(ClosetItem item) {
    setState(() {
      final outfitItem = OutfitItem(
        id: 'outfit_item_${DateTime.now().millisecondsSinceEpoch}',
        closetItem: item,
        order: _outfitItems.length,
      );
      
      _outfitItems.add(outfitItem);
    });
  }

  void _removeItemFromOutfit(int index) {
    setState(() {
      _outfitItems.removeAt(index);
      
      // Reorder remaining items
      for (int i = 0; i < _outfitItems.length; i++) {
        _outfitItems[i] = _outfitItems[i].copyWith(order: i);
      }
    });
  }

  void _loadExistingOutfit(Outfit outfit) {
    setState(() {
      _outfitItems.addAll(outfit.items);
      _outfitName = outfit.name;
      _outfitDescription = outfit.description ?? '';
      _selectedCategory = outfit.category;
      _selectedSeason = outfit.season;
      _selectedOccasion = outfit.occasion;
      _tags = List.from(outfit.tags);
      _isPublic = outfit.isPublic;
    });
  }

  double _calculateTotalValue() {
    return _outfitItems.fold(0.0, (sum, item) => sum + item.closetItem.purchasePrice);
  }

  // ==================== SELECTION DIALOGS ====================

  void _showCategorySelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: OutfitCategory.values.map((category) {
            return RadioListTile<OutfitCategory>(
              title: Text(category.name),
              value: category,
              groupValue: _selectedCategory,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSeasonSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Season'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Season.values.map((season) {
            return RadioListTile<Season>(
              title: Text(season.name),
              value: season,
              groupValue: _selectedSeason,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  setState(() {
                    _selectedSeason = value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showOccasionSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Occasion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: Occasion.values.map((occasion) {
            return RadioListTile<Occasion>(
              title: Text(occasion.name),
              value: occasion,
              groupValue: _selectedOccasion,
              onChanged: (value) {
                Navigator.pop(context);
                if (value != null) {
                  setState(() {
                    _selectedOccasion = value;
                  });
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tag name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    _tags.add(value.trim());
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.auto_fix_high),
              title: const Text('AI Suggestion'),
              subtitle: const Text('Get AI-powered outfit suggestions'),
              onTap: () {
                Navigator.pop(context);
                _generateAISuggestion();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Random Outfit'),
              subtitle: const Text('Generate a random outfit from your closet'),
              onTap: () {
                Navigator.pop(context);
                _generateRandomOutfit();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Clear Outfit'),
              subtitle: const Text('Remove all items from current outfit'),
              onTap: () {
                Navigator.pop(context);
                _clearOutfit();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== OUTFIT ACTIONS ====================

  Future<void> _saveOutfit() async {
    if (_outfitItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add items to outfit before saving')),
      );
      return;
    }
    
    if (_outfitName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an outfit name')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final closetProvider = ref.read(closetProvider.notifier);
      
      if (widget.existingOutfit != null) {
        // Update existing outfit
        final updatedOutfit = widget.existingOutfit!.copyWith(
          name: _outfitName.trim(),
          description: _outfitDescription.trim().isEmpty ? null : _outfitDescription.trim(),
          items: _outfitItems,
          category: _selectedCategory,
          season: _selectedSeason,
          occasion: _selectedOccasion,
          tags: _tags,
          isPublic: _isPublic,
          lastModified: DateTime.now(),
        );
        
        await closetProvider.updateOutfit(updatedOutfit);
      } else {
        // Create new outfit
        await closetProvider.createOutfit(
          name: _outfitName.trim(),
          description: _outfitDescription.trim().isEmpty ? null : _outfitDescription.trim(),
          items: _outfitItems,
          category: _selectedCategory,
          season: _selectedSeason,
          occasion: _selectedOccasion,
          tags: _tags,
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving outfit: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _shareOutfit() {
    // Share outfit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share outfit functionality coming soon')),
    );
  }

  void _togglePreviewMode() {
    setState(() {
      _isPreviewMode = !_isPreviewMode;
      if (_isPreviewMode) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  // ==================== UTILITY METHODS ====================

  void _generateAISuggestion() {
    // AI suggestion logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI suggestion feature coming soon')),
    );
  }

  void _generateRandomOutfit() {
    // Random outfit generation logic
    final closetState = ref.read(closetProvider);
    final items = closetState.filteredClosetItems;
    
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items available for random outfit')),
      );
      return;
    }
    
    setState(() {
      _outfitItems.clear();
      
      // Add 3-5 random items
      final itemCount = (items.length > 5) ? 3 + (DateTime.now().millisecond % 3) : items.length;
      final randomItems = items.take(itemCount).toList();
      
      for (int i = 0; i < randomItems.length; i++) {
        _addItemToOutfit(randomItems[i]);
      }
    });
    
    _tabController.animateTo(2); // Go to preview tab
  }

  void _clearOutfit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Outfit'),
        content: const Text('Are you sure you want to remove all items from this outfit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _outfitItems.clear();
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}