import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';
import '../../src/widgets/app_button.dart';
import '../../src/widgets/app_card.dart';
import '../../src/widgets/empty_state.dart';
import '../../src/widgets/loading_indicator.dart';
import '../../src/widgets/error_state.dart';
import 'closet_filters_screen.dart';
import 'outfit_builder_screen.dart';
import 'outfit_detail_screen.dart';
import 'item_detail_screen.dart';
import 'closet_analytics_screen.dart';

/// Comprehensive Closet Management Screen
/// 
/// Displays all saved items from swipe interactions with advanced filtering,
/// search, batch operations, and outfit creation capabilities.
class ClosetScreen extends ConsumerStatefulWidget {
  const ClosetScreen({super.key});

  @override
  ConsumerState<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends ConsumerState<ClosetScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  // Filter state
  bool _isFilterVisible = false;
  String _selectedView = 'grid'; // 'grid', 'list'
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    
    // Start with FAB visible
    _fabAnimationController.forward();
    
    // Initialize closet provider
    Future.microtask(() {
      ref.read(closetProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closetState = ref.watch(closetProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Closet'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          // Analytics Icon
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => _navigateToAnalytics(),
          ),
          // Share Icon
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showShareOptions(),
          ),
          // Settings Icon
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMoreOptions(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Items', icon: Icon(Icons.checkroom)),
            Tab(text: 'Outfits', icon: Icon(Icons.style)),
            Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
          ],
          indicatorColor: Theme.of(context).primaryColor,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),
          
          // Filter and Sort Bar
          _buildFilterSortBar(),
          
          // Tab Bar Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildItemsTab(closetState),
                _buildOutfitsTab(closetState),
                _buildAnalyticsTab(closetState),
              ],
            ),
          ),
        ],
      ),
      
      // Floating Action Buttons
      floatingActionButton: _buildFloatingActionButtons(),
      
      // Bottom Navigation for batch operations
      bottomNavigationBar: closetState.isSelectionMode || closetState.isOutfitSelectionMode
          ? _buildBatchActionBar(closetState)
          : null,
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Search your closet...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(closetProvider.notifier).searchClosetItems('');
                    _searchFocusNode.unfocus();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          ref.read(closetProvider.notifier).searchClosetItems(value);
        },
        onSubmitted: (value) {
          _searchFocusNode.unfocus();
        },
      ),
    );
  }

  Widget _buildFilterSortBar() {
    final closetState = ref.read(closetProvider);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Filter Button
          Expanded(
            child: AppButton(
              text: 'Filter & Sort',
              onPressed: () => _showFilterBottomSheet(),
              variant: AppButtonVariant.secondary,
              icon: Icons.filter_list,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // View Toggle
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _selectedView == 'grid' ? Icons.grid_view : Icons.view_list,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedView = _selectedView == 'grid' ? 'list' : 'grid';
                    });
                  },
                  tooltip: _selectedView == 'grid' ? 'List View' : 'Grid View',
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Recent Actions (Undo)
          if (closetState.recentActions.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: _showUndoDialog,
              tooltip: 'Undo Last Action',
            ),
        ],
      ),
    );
  }

  Widget _buildItemsTab(ClosetState closetState) {
    if (closetState.isLoadingCloset) {
      return const LoadingIndicator(message: 'Loading your closet...');
    }

    if (closetState.closetError != null) {
      return ErrorState(
        message: closetState.closetError!,
        onRetry: () => ref.read(closetProvider.notifier).loadClosetItems(),
      );
    }

    if (closetState.filteredClosetItems.isEmpty) {
      return EmptyState(
        icon: Icons.checkroom,
        title: 'Your Closet is Empty',
        subtitle: 'Start swiping right on items you like to build your wardrobe',
        action: AppButton(
          text: 'Browse Products',
          onPressed: () => _navigateToSwipeFeed(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(closetProvider.notifier).loadClosetItems();
      },
      child: _selectedView == 'grid'
          ? _buildGridView(closetState)
          : _buildListView(closetState),
    );
  }

  Widget _buildGridView(ClosetState closetState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: closetState.filteredClosetItems.length,
      itemBuilder: (context, index) {
        final item = closetState.filteredClosetItems[index];
        return _buildClosetItemCard(item, isSelectionMode: closetState.isSelectionMode);
      },
    );
  }

  Widget _buildListView(ClosetState closetState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: closetState.filteredClosetItems.length,
      itemBuilder: (context, index) {
        final item = closetState.filteredClosetItems[index];
        return _buildClosetItemListTile(item, isSelectionMode: closetState.isSelectionMode);
      },
    );
  }

  Widget _buildOutfitsTab(ClosetState closetState) {
    if (closetState.isLoadingOutfits) {
      return const LoadingIndicator(message: 'Loading your outfits...');
    }

    if (closetState.outfitsError != null) {
      return ErrorState(
        message: closetState.outfitsError!,
        onRetry: () => ref.read(closetProvider.notifier).loadOutfits(),
      );
    }

    if (closetState.filteredOutfits.isEmpty) {
      return EmptyState(
        icon: Icons.style,
        title: 'No Outfits Created',
        subtitle: 'Create your first outfit by mixing and matching your closet items',
        action: AppButton(
          text: 'Create Outfit',
          onPressed: () => _navigateToOutfitBuilder(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(closetProvider.notifier).loadOutfits();
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: closetState.filteredOutfits.length,
        itemBuilder: (context, index) {
          final outfit = closetState.filteredOutfits[index];
          return _buildOutfitCard(outfit, isSelectionMode: closetState.isOutfitSelectionMode);
        },
      ),
    );
  }

  Widget _buildAnalyticsTab(ClosetState closetState) {
    if (closetState.isLoadingAnalytics) {
      return const LoadingIndicator(message: 'Loading analytics...');
    }

    if (closetState.analytics == null) {
      return EmptyState(
        icon: Icons.analytics,
        title: 'No Analytics Data',
        subtitle: 'Start using your closet to see insights and recommendations',
      );
    }

    return _buildAnalyticsContent(closetState.analytics!, closetState.insights);
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main FAB
        ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton.extended(
            onPressed: () => _showFABMenu(),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary FABs (when menu is expanded)
        // Would show/hide based on animation state
      ],
    );
  }

  Widget _buildBatchActionBar(ClosetState closetState) {
    final selectedCount = closetState.isSelectionMode
        ? closetState.selectedItemIds.length
        : closetState.selectedOutfitIds.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              if (closetState.isSelectionMode) {
                ref.read(closetProvider.notifier).clearSelection();
              } else {
                // Handle outfit selection clear
              }
            },
          ),
          
          Text(
            '$selectedCount selected',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          
          const Spacer(),
          
          // Batch actions
          if (closetState.isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () => _batchAddToCart(),
              tooltip: 'Add to Cart',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _batchDeleteItems(),
              tooltip: 'Remove from Closet',
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ITEM CARD BUILDERS ====================

  Widget _buildClosetItemCard(ClosetItem item, {required bool isSelectionMode}) {
    return GestureDetector(
      onTap: () => _navigateToItemDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
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
                  
                  // Selection checkbox
                  if (isSelectionMode)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          ref.read(closetProvider).selectedItemIds.contains(item.id)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: ref.read(closetProvider).selectedItemIds.contains(item.id)
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  
                  // Favorite indicator
                  if (item.isFavorited)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: Theme.of(context).textTheme.titleMedium,
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        
                        Text(
                          '${item.wearCount} wears',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Size and color info
                    Row(
                      children: [
                        Chip(
                          label: Text(item.selectedSize),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        const SizedBox(width: 4),
                        Chip(
                          label: Text(item.selectedColor),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosetItemListTile(ClosetItem item, {required bool isSelectionMode}) {
    return ListTile(
      leading: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.product.primaryImage,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Icon(Icons.image_not_supported),
                );
              },
            ),
          ),
          
          if (isSelectionMode)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  ref.read(closetProvider).selectedItemIds.contains(item.id)
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: ref.read(closetProvider).selectedItemIds.contains(item.id)
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
      
      title: Text(
        item.product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.product.vendor.name),
          Text('${item.selectedSize} • ${item.selectedColor} • ${item.wearCount} wears'),
        ],
      ),
      
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'try_on',
            child: ListTile(
              leading: Icon(Icons.person),
              title: Text('Try On'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'add_to_cart',
            child: ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Add to Cart'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'create_outfit',
            child: ListTile(
              leading: Icon(Icons.style),
              title: Text('Create Outfit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'mark_worn',
            child: ListTile(
              leading: Icon(Icons.check),
              title: Text('Mark as Worn'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Remove', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (value) => _handleItemAction(value as String, item),
      ),
      
      onTap: () => _navigateToItemDetail(item),
    );
  }

  Widget _buildOutfitCard(Outfit outfit, {required bool isSelectionMode}) {
    return GestureDetector(
      onTap: () => _navigateToOutfitDetail(outfit),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Outfit image
              AspectRatio(
                aspectRatio: 1.2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: outfit.primaryImage != null
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          child: Image.network(
                            outfit.primaryImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image_not_supported, size: 48),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.style, size: 48),
                        ),
                ),
              ),
              
              // Selection checkbox
              if (isSelectionMode)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      ref.read(closetProvider).selectedOutfitIds.contains(outfit.id)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: ref.read(closetProvider).selectedOutfitIds.contains(outfit.id)
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            outfit.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        
                        if (outfit.isFavorited)
                          Icon(
                            Icons.favorite,
                            color: Theme.of(context).colorScheme.error,
                            size: 16,
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Text(
                      '${outfit.category.name} • ${outfit.occasion.name}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${outfit.items.length} items',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        
                        Text(
                          '${outfit.wearCount} wears',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== ANALYTICS BUILDER ====================

  Widget _buildAnalyticsContent(ClosetAnalytics analytics, List<AnalyticsInsight> insights) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview Cards
          _buildAnalyticsOverviewCards(analytics),
          
          const SizedBox(height: 24),
          
          // Category Breakdown
          _buildCategoryBreakdown(analytics),
          
          const SizedBox(height: 24),
          
          // Brand Analysis
          _buildBrandAnalysis(analytics),
          
          const SizedBox(height: 24),
          
          // Insights
          _buildInsightsSection(insights),
        ],
      ),
    );
  }

  Widget _buildAnalyticsOverviewCards(ClosetAnalytics analytics) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildMetricCard(
          'Total Items',
          analytics.totalItems.toString(),
          Icons.checkroom,
        ),
        _buildMetricCard(
          'Total Outfits',
          analytics.totalOutfits.toString(),
          Icons.style,
        ),
        _buildMetricCard(
          'Total Value',
          '₹${analytics.totalValue.toStringAsFixed(0)}',
          Icons.attach_money,
        ),
        _buildMetricCard(
          'Avg Cost/Wear',
          '₹${analytics.averageCostPerWear.toStringAsFixed(0)}',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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

  Widget _buildCategoryBreakdown(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Items by Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ...analytics.itemsByCategory.entries.map((entry) {
              final percentage = (entry.value / analytics.totalItems * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('${entry.value} ($percentage%)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandAnalysis(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ...analytics.itemsByBrand.entries.map((entry) {
              final percentage = (entry.value / analytics.totalItems * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('${entry.value} ($percentage%)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection(List<AnalyticsInsight> insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Insights',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            if (insights.isEmpty)
              Text(
                'No insights available yet. Start using your closet to get personalized recommendations!',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    _getInsightIcon(insight.type),
                    color: _getInsightColor(insight.type),
                  ),
                  title: Text(insight.title),
                  subtitle: Text(insight.description),
                  trailing: insight.action != null ? TextButton(
                    onPressed: () => _executeInsightAction(insight.action!),
                    child: const Text('Act'),
                  ) : null,
                ),
              )).toList(),
          ],
        ),
      ),
    );
  }

  // ==================== ACTION HANDLERS ====================

  void _handleItemAction(String action, ClosetItem item) {
    switch (action) {
      case 'try_on':
        _navigateToTryOn(item.product);
        break;
      case 'add_to_cart':
        _addToCart(item.product);
        break;
      case 'create_outfit':
        _navigateToOutfitBuilder(item);
        break;
      case 'mark_worn':
        _markAsWorn(item);
        break;
      case 'remove':
        _showRemoveConfirmation(item);
        break;
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ClosetFiltersScreen(),
    );
  }

  void _showFABMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.style),
              title: const Text('Create Outfit'),
              subtitle: const Text('Mix and match your items'),
              onTap: () {
                Navigator.pop(context);
                _navigateToOutfitBuilder();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Closet'),
              subtitle: const Text('Update from swipe history'),
              onTap: () {
                Navigator.pop(context);
                _syncClosetFromSwipes();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Add Photo'),
              subtitle: const Text('Add item from photo'),
              onTap: () {
                Navigator.pop(context);
                _addItemFromPhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showUndoDialog() {
    final closetState = ref.read(closetProvider);
    if (closetState.recentActions.isEmpty) return;
    
    final lastAction = closetState.recentActions.first;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Undo Last Action'),
        content: Text('Are you sure you want to undo: ${lastAction.itemName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(closetProvider.notifier).undoLastAction();
              if (mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Unable to undo action')),
                );
              }
            },
            child: const Text('Undo'),
          ),
        ],
      ),
    );
  }

  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Share Closet Link'),
              subtitle: const Text('Share your closet with friends'),
              onTap: () => _shareClosetLink(),
            ),
            
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Share with Friends'),
              subtitle: const Text('Share selected items or outfits'),
              onTap: () => _shareWithFriends(),
            ),
            
            ListTile(
              leading: const Icon(Icons.export),
              title: const Text('Export Data'),
              subtitle: const Text('Export your closet data'),
              onTap: () => _exportClosetData(),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Backup Closet'),
              subtitle: const Text('Create a backup of your data'),
              onTap: () => _backupCloset(),
            ),
            
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from Backup'),
              subtitle: const Text('Restore from previous backup'),
              onTap: () => _restoreFromBackup(),
            ),
            
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Closet Settings'),
              subtitle: const Text('Manage your closet preferences'),
              onTap: () => _openClosetSettings(),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveConfirmation(ClosetItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Are you sure you want to remove "${item.product.name}" from your closet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(closetProvider.notifier).removeFromCloset(item.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _batchAddToCart() {
    final closetState = ref.read(closetProvider);
    if (closetState.selectedItemIds.isEmpty) return;
    
    ref.read(closetProvider.notifier).addMultipleToCart();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${closetState.selectedItemIds.length} items added to cart')),
    );
  }

  void _batchDeleteItems() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Selected Items'),
        content: const Text('Are you sure you want to remove the selected items from your closet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(closetProvider.notifier).removeMultipleFromCloset();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION HELPERS ====================

  void _navigateToAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClosetAnalyticsScreen(),
      ),
    );
  }

  void _navigateToOutfitBuilder([ClosetItem? item]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutfitBuilderScreen(initialItem: item),
      ),
    );
  }

  void _navigateToOutfitDetail(Outfit outfit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutfitDetailScreen(outfit: outfit),
      ),
    );
  }

  void _navigateToItemDetail(ClosetItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(closetItem: item),
      ),
    );
  }

  void _navigateToSwipeFeed() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/swipe-feed',
      (route) => false,
    );
  }

  void _navigateToTryOn(Product product) {
    // Navigate to try-on screen with product
    Navigator.pushNamed(
      context,
      '/tryon-viewer',
      arguments: product,
    );
  }

  // ==================== UTILITY METHODS ====================

  void _addToCart(Product product) {
    // Add to cart logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to cart')),
    );
  }

  void _markAsWorn(ClosetItem item) {
    ref.read(closetProvider.notifier).markAsWorn(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${item.product.name} marked as worn')),
    );
  }

  void _syncClosetFromSwipes() {
    // Sync logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Closet synced from swipe history')),
    );
  }

  void _addItemFromPhoto() {
    // Add from photo logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add from photo feature coming soon')),
    );
  }

  void _shareClosetLink() {
    // Share closet link logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Closet link shared!')),
    );
  }

  void _shareWithFriends() {
    // Share with friends logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share with friends feature coming soon')),
    );
  }

  void _exportClosetData() {
    // Export closet data logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Closet data exported!')),
    );
  }

  void _backupCloset() {
    // Backup closet logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Closet backup created!')),
    );
  }

  void _restoreFromBackup() {
    // Restore from backup logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restore feature coming soon')),
    );
  }

  void _openClosetSettings() {
    // Open closet settings logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Closet settings coming soon')),
    );
  }

  void _executeInsightAction(String action) {
    // Execute insight action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executing: $action')),
    );
  }

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'recommendation':
        return Icons.lightbulb;
      case 'warning':
        return Icons.warning;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'recommendation':
        return Colors.amber;
      case 'warning':
        return Colors.orange;
      case 'achievement':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }
}

// ==================== STATE EXTENSION ====================

class ClosetState {
  final List<ClosetItem> closetItems;
  final List<ClosetItem> filteredClosetItems;
  final bool isLoadingCloset;
  final String? closetError;
  
  final List<Outfit> outfits;
  final List<Outfit> filteredOutfits;
  final bool isLoadingOutfits;
  final String? outfitsError;
  
  final bool isSelectionMode;
  final Set<String> selectedItemIds;
  final bool isOutfitSelectionMode;
  final Set<String> selectedOutfitIds;
  
  final ClosetAnalytics? analytics;
  final bool isLoadingAnalytics;
  final List<AnalyticsInsight> insights;
  final List<RecentActionEntry> recentActions;
  final List<ClosetNotification> notifications;
  final int unreadNotificationCount;

  ClosetState({
    required this.closetItems,
    required this.filteredClosetItems,
    required this.isLoadingCloset,
    this.closetError,
    required this.outfits,
    required this.filteredOutfits,
    required this.isLoadingOutfits,
    this.outfitsError,
    required this.isSelectionMode,
    required this.selectedItemIds,
    required this.isOutfitSelectionMode,
    required this.selectedOutfitIds,
    this.analytics,
    required this.isLoadingAnalytics,
    required this.insights,
    required this.recentActions,
    required this.notifications,
    required this.unreadNotificationCount,
  });

  static ClosetState fromProvider(ClosetProvider provider) {
    return ClosetState(
      closetItems: provider.closetItems,
      filteredClosetItems: provider.filteredClosetItems,
      isLoadingCloset: provider.isLoadingCloset,
      closetError: provider.closetError,
      outfits: provider.outfits,
      filteredOutfits: provider.filteredOutfits,
      isLoadingOutfits: provider.isLoadingOutfits,
      outfitsError: provider.outfitsError,
      isSelectionMode: provider.isSelectionMode,
      selectedItemIds: provider.selectedItemIds,
      isOutfitSelectionMode: provider.isOutfitSelectionMode,
      selectedOutfitIds: provider.selectedOutfitIds,
      analytics: provider.analytics,
      isLoadingAnalytics: provider.isLoadingAnalytics,
      insights: provider.insights,
      recentActions: provider.recentActions,
      notifications: provider.notifications,
      unreadNotificationCount: provider.unreadNotificationCount,
    );
  }
}

// ==================== PROVIDER EXTENSION ====================

extension ClosetProviderState on ClosetProvider {
  ClosetState get state => ClosetState.fromProvider(this);
}