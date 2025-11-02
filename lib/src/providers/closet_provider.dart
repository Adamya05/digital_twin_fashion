import 'package:flutter/foundation.dart';
import '../models/closet_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

/// Comprehensive Closet Management Provider
/// 
/// Manages all closet functionality including:
/// - Saved items from swipe actions
/// - Closet items organization and filtering
/// - Outfit creation and management
/// - Closet analytics and insights
/// - Integration with swipe system
class ClosetProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ==================== CLOSET ITEMS ====================
  
  List<ClosetItem> _closetItems = [];
  List<ClosetItem> _filteredClosetItems = [];
  bool _isLoadingCloset = false;
  String? _closetError;
  
  // ==================== OUTFITS ====================
  
  List<Outfit> _outfits = [];
  List<Outfit> _filteredOutfits = [];
  bool _isLoadingOutfits = false;
  String? _outfitsError;
  
  // ==================== FILTERS & SORTING ====================
  
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedBrand = '';
  String _selectedSize = '';
  String _selectedColor = '';
  ItemCondition _selectedCondition = ItemCondition.newItem;
  bool _showOnlyFavorited = false;
  bool _showOnlyOnSale = false;
  bool _showOnlyInOutfits = false;
  String _sortBy = 'dateAdded';
  bool _sortAscending = false;
  
  // Outfit filters
  String _outfitSearchQuery = '';
  OutfitCategory _selectedOutfitCategory = OutfitCategory.casual;
  Season _selectedSeason = Season.all;
  Occasion _selectedOccasion = Occasion.everyday;
  bool _showOnlyFavoritedOutfits = false;
  String _outfitSortBy = 'dateCreated';
  bool _sortOutfitsAscending = false;
  
  // ==================== BATCH OPERATIONS ====================
  
  Set<String> _selectedItemIds = {};
  bool _isSelectionMode = false;
  
  Set<String> _selectedOutfitIds = {};
  bool _isOutfitSelectionMode = false;
  
  // ==================== ANALYTICS ====================
  
  ClosetAnalytics? _analytics;
  bool _isLoadingAnalytics = false;
  List<AnalyticsInsight> _insights = [];
  
  // ==================== RECENT ACTIONS ====================
  
  List<RecentAction> _recentActions = [];
  static const int maxRecentActions = 20;
  
  // ==================== NOTIFICATIONS ====================
  
  List<ClosetNotification> _notifications = [];
  int _unreadNotificationCount = 0;
  
  // ==================== INITIALIZATION ====================
  
  /// Initialize closet provider
  Future<void> initialize() async {
    await loadClosetItems();
    await loadOutfits();
    await loadAnalytics();
    await loadNotifications();
    await loadRecentActions();
  }
  
  // ==================== CLOSET ITEMS MANAGEMENT ====================
  
  /// Load all closet items
  Future<void> loadClosetItems() async {
    if (_isLoadingCloset) return;
    
    _isLoadingCloset = true;
    _closetError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getClosetItems();
      
      if (response.isSuccess && response.data != null) {
        _closetItems = response.data!;
        _filteredClosetItems = _closetItems;
        _applyFilters();
      } else {
        _closetError = response.error ?? 'Failed to load closet items';
        _closetItems = _getMockClosetItems(); // Fallback to mock data
        _filteredClosetItems = _closetItems;
        _applyFilters();
      }
    } catch (e) {
      _closetError = 'Network error: $e';
      _closetItems = _getMockClosetItems(); // Fallback to mock data
      _filteredClosetItems = _closetItems;
      _applyFilters();
    }
    
    _isLoadingCloset = false;
    notifyListeners();
  }
  
  /// Add item to closet (called when user swipes right)
  Future<void> addToCloset(Product product, {
    String? size,
    String? color,
    String? notes,
  }) async {
    final closetItem = ClosetItem(
      id: 'closet_${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      savedAt: DateTime.now(),
      selectedSize: size ?? product.availableSizes.first,
      selectedColor: color ?? product.availableColors.first,
      notes: notes,
      purchasePrice: product.currentPrice,
    );
    
    _closetItems.insert(0, closetItem);
    _filteredClosetItems = _closetItems;
    _applyFilters();
    
    try {
      await _apiService.saveClosetItem(closetItem);
      _addRecentAction(RecentAction.addedToCloset, closetItem.product.name);
      _addNotification(
        ClosetNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.itemAdded,
          title: 'Item Added to Closet',
          message: '${closetItem.product.name} has been added to your closet',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error saving closet item: $e');
    }
    
    notifyListeners();
  }
  
  /// Remove item from closet
  Future<void> removeFromCloset(String closetItemId) async {
    final item = _closetItems.firstWhere((item) => item.id == closetItemId);
    
    _closetItems.removeWhere((item) => item.id == closetItemId);
    _filteredClosetItems = _closetItems;
    _applyFilters();
    
    try {
      await _apiService.removeClosetItem(closetItemId);
      _addRecentAction(RecentAction.removedFromCloset, item.product.name);
      _addNotification(
        ClosetNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.itemRemoved,
          title: 'Item Removed',
          message: '${item.product.name} has been removed from your closet',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error removing closet item: $e');
    }
    
    notifyListeners();
  }
  
  /// Update closet item
  Future<void> updateClosetItem(ClosetItem updatedItem) async {
    final index = _closetItems.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      _closetItems[index] = updatedItem;
      _filteredClosetItems = _closetItems;
      _applyFilters();
      
      try {
        await _apiService.updateClosetItem(updatedItem);
      } catch (e) {
        debugPrint('Error updating closet item: $e');
      }
      
      notifyListeners();
    }
  }
  
  /// Toggle favorite status
  Future<void> toggleFavorite(String closetItemId) async {
    final item = _closetItems.firstWhere((item) => item.id == closetItemId);
    final updatedItem = item.copyWith(isFavorited: !item.isFavorited);
    await updateClosetItem(updatedItem);
  }
  
  /// Mark item as worn
  Future<void> markAsWorn(String closetItemId, {
    DateTime? wornDate,
    String? notes,
  }) async {
    final item = _closetItems.firstWhere((item) => item.id == closetItemId);
    final updatedItem = item.copyWith(
      wearCount: item.wearCount + 1,
      lastWornDate: wornDate ?? DateTime.now(),
    );
    
    await updateClosetItem(updatedItem);
    _addRecentAction(RecentAction.markedAsWorn, item.product.name);
  }
  
  // ==================== OUTFIT MANAGEMENT ====================
  
  /// Load all outfits
  Future<void> loadOutfits() async {
    if (_isLoadingOutfits) return;
    
    _isLoadingOutfits = true;
    _outfitsError = null;
    notifyListeners();
    
    try {
      final response = await _apiService.getOutfits();
      
      if (response.isSuccess && response.data != null) {
        _outfits = response.data!;
        _filteredOutfits = _outfits;
        _applyOutfitFilters();
      } else {
        _outfitsError = response.error ?? 'Failed to load outfits';
        _outfits = _getMockOutfits(); // Fallback to mock data
        _filteredOutfits = _outfits;
        _applyOutfitFilters();
      }
    } catch (e) {
      _outfitsError = 'Network error: $e';
      _outfits = _getMockOutfits(); // Fallback to mock data
      _filteredOutfits = _outfits;
      _applyOutfitFilters();
    }
    
    _isLoadingOutfits = false;
    notifyListeners();
  }
  
  /// Create new outfit
  Future<void> createOutfit({
    required String name,
    required List<OutfitItem> items,
    String? description,
    OutfitCategory category = OutfitCategory.casual,
    Season season = Season.all,
    Occasion occasion = Occasion.everyday,
    List<String> tags = const [],
  }) async {
    final outfit = Outfit(
      id: 'outfit_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      items: items,
      createdAt: DateTime.now(),
      lastModified: DateTime.now(),
      category: category,
      season: season,
      occasion: occasion,
      tags: tags,
    );
    
    _outfits.insert(0, outfit);
    _filteredOutfits = _outfits;
    _applyOutfitFilters();
    
    try {
      await _apiService.saveOutfit(outfit);
      _addRecentAction(RecentAction.outfitCreated, outfit.name);
      _addNotification(
        ClosetNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.outfitCreated,
          title: 'Outfit Created',
          message: 'Your outfit "$name" has been created successfully',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error saving outfit: $e');
    }
    
    notifyListeners();
  }
  
  /// Update outfit
  Future<void> updateOutfit(Outfit updatedOutfit) async {
    final index = _outfits.indexWhere((outfit) => outfit.id == updatedOutfit.id);
    if (index != -1) {
      final outfitWithTimestamp = updatedOutfit.copyWith(lastModified: DateTime.now());
      _outfits[index] = outfitWithTimestamp;
      _filteredOutfits = _outfits;
      _applyOutfitFilters();
      
      try {
        await _apiService.updateOutfit(outfitWithTimestamp);
      } catch (e) {
        debugPrint('Error updating outfit: $e');
      }
      
      notifyListeners();
    }
  }
  
  /// Delete outfit
  Future<void> deleteOutfit(String outfitId) async {
    final outfit = _outfits.firstWhere((outfit) => outfit.id == outfitId);
    
    _outfits.removeWhere((outfit) => outfit.id == outfitId);
    _filteredOutfits = _outfits;
    _applyOutfitFilters();
    
    try {
      await _apiService.deleteOutfit(outfitId);
      _addRecentAction(RecentAction.outfitDeleted, outfit.name);
    } catch (e) {
      debugPrint('Error deleting outfit: $e');
    }
    
    notifyListeners();
  }
  
  /// Mark outfit as worn
  Future<void> markOutfitAsWorn(String outfitId, {
    DateTime? wornDate,
    String? notes,
  }) async {
    final outfit = _outfits.firstWhere((outfit) => outfit.id == outfitId);
    final updatedOutfit = outfit.copyWith(
      wearCount: outfit.wearCount + 1,
      lastWornDate: wornDate ?? DateTime.now(),
    );
    
    await updateOutfit(updatedOutfit);
    _addRecentAction(RecentAction.outfitWorn, outfit.name);
  }
  
  // ==================== BATCH OPERATIONS ====================
  
  /// Select item for batch operations
  void selectItem(String itemId) {
    _selectedItemIds.add(itemId);
    _isSelectionMode = true;
    notifyListeners();
  }
  
  /// Deselect item
  void deselectItem(String itemId) {
    _selectedItemIds.remove(itemId);
    if (_selectedItemIds.isEmpty) {
      _isSelectionMode = false;
    }
    notifyListeners();
  }
  
  /// Select all visible items
  void selectAllVisibleItems() {
    _selectedItemIds = _filteredClosetItems.map((item) => item.id).toSet();
    _isSelectionMode = true;
    notifyListeners();
  }
  
  /// Clear selection
  void clearSelection() {
    _selectedItemIds.clear();
    _isSelectionMode = false;
    notifyListeners();
  }
  
  /// Remove multiple items from closet
  Future<void> removeMultipleFromCloset() async {
    if (_selectedItemIds.isEmpty) return;
    
    final itemsToRemove = _closetItems.where((item) => _selectedItemIds.contains(item.id)).toList();
    
    for (final item in itemsToRemove) {
      _closetItems.removeWhere((closetItem) => closetItem.id == item.id);
    }
    
    _filteredClosetItems = _closetItems;
    _applyFilters();
    
    try {
      await _apiService.removeMultipleClosetItems(_selectedItemIds.toList());
      _addRecentAction(RecentAction.itemsRemoved, '${itemsToRemove.length} items');
    } catch (e) {
      debugPrint('Error removing multiple items: $e');
    }
    
    clearSelection();
    notifyListeners();
  }
  
  /// Add multiple items to cart
  Future<void> addMultipleToCart() async {
    if (_selectedItemIds.isEmpty) return;
    
    final itemsToAdd = _closetItems.where((item) => _selectedItemIds.contains(item.id)).toList();
    
    try {
      await _apiService.addMultipleToCart(itemsToAdd.map((item) => item.product).toList());
      _addRecentAction(RecentAction.itemsMovedToCart, '${itemsToAdd.length} items');
      _addNotification(
        ClosetNotification(
          id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
          type: NotificationType.itemsMovedToCart,
          title: 'Items Moved to Cart',
          message: '${itemsToAdd.length} items have been added to your cart',
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('Error moving multiple items to cart: $e');
    }
    
    clearSelection();
    notifyListeners();
  }
  
  // ==================== SEARCH & FILTERING ====================
  
  /// Search closet items
  void searchClosetItems(String query) {
    _searchQuery = query;
    _filteredClosetItems = _closetItems.where((item) => item.matchesSearch(query)).toList();
    _applyFilters();
    notifyListeners();
  }
  
  /// Set category filter
  void setCategoryFilter(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }
  
  /// Set brand filter
  void setBrandFilter(String brand) {
    _selectedBrand = brand;
    _applyFilters();
    notifyListeners();
  }
  
  /// Set condition filter
  void setConditionFilter(ItemCondition condition) {
    _selectedCondition = condition;
    _applyFilters();
    notifyListeners();
  }
  
  /// Set sorting
  void setSorting(String sortBy, bool ascending) {
    _sortBy = sortBy;
    _sortAscending = ascending;
    _applyFilters();
    notifyListeners();
  }
  
  /// Toggle filter flags
  void toggleShowOnlyFavorited() {
    _showOnlyFavorited = !_showOnlyFavorited;
    _applyFilters();
    notifyListeners();
  }
  
  void toggleShowOnlyOnSale() {
    _showOnlyOnSale = !_showOnlyOnSale;
    _applyFilters();
    notifyListeners();
  }
  
  void toggleShowOnlyInOutfits() {
    _showOnlyInOutfits = !_showOnlyInOutfits;
    _applyFilters();
    notifyListeners();
  }
  
  /// Clear all filters
  void clearAllFilters() {
    _searchQuery = '';
    _selectedCategory = '';
    _selectedBrand = '';
    _selectedSize = '';
    _selectedColor = '';
    _selectedCondition = ItemCondition.newItem;
    _showOnlyFavorited = false;
    _showOnlyOnSale = false;
    _showOnlyInOutfits = false;
    _sortBy = 'dateAdded';
    _sortAscending = false;
    
    _filteredClosetItems = _closetItems;
    notifyListeners();
  }
  
  // ==================== ANALYTICS ====================
  
  /// Load closet analytics
  Future<void> loadAnalytics() async {
    if (_isLoadingAnalytics) return;
    
    _isLoadingAnalytics = true;
    notifyListeners();
    
    try {
      final response = await _apiService.getClosetAnalytics();
      
      if (response.isSuccess && response.data != null) {
        _analytics = response.data!;
        _insights = _analytics!.insights;
      } else {
        _analytics = _getMockAnalytics();
        _insights = _analytics!.insights;
      }
    } catch (e) {
      _analytics = _getMockAnalytics();
      _insights = _analytics!.insights;
    }
    
    _isLoadingAnalytics = false;
    notifyListeners();
  }
  
  // ==================== RECENT ACTIONS ====================
  
  void _addRecentAction(RecentAction action, String itemName) {
    final recentAction = RecentActionEntry(
      id: 'action_${DateTime.now().millisecondsSinceEpoch}',
      action: action,
      itemName: itemName,
      timestamp: DateTime.now(),
    );
    
    _recentActions.insert(0, recentAction);
    if (_recentActions.length > maxRecentActions) {
      _recentActions = _recentActions.take(maxRecentActions).toList();
    }
  }
  
  /// Undo last action
  Future<bool> undoLastAction() async {
    if (_recentActions.isEmpty) return false;
    
    final lastAction = _recentActions.first;
    
    try {
      switch (lastAction.action) {
        case RecentAction.addedToCloset:
          await removeFromClosetByProductName(lastAction.itemName);
          break;
        case RecentAction.removedFromCloset:
          // Could implement restore functionality here
          break;
        case RecentAction.outfitCreated:
          await deleteOutfitByName(lastAction.itemName);
          break;
        case RecentAction.outfitDeleted:
          // Could implement restore functionality here
          break;
        default:
          break;
      }
      
      _recentActions.removeAt(0);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error undoing action: $e');
      return false;
    }
  }
  
  Future<void> loadRecentActions() async {
    // Load from persistent storage
    // Implementation would depend on storage strategy
  }
  
  // ==================== NOTIFICATIONS ====================
  
  void _addNotification(ClosetNotification notification) {
    _notifications.insert(0, notification);
    _unreadNotificationCount++;
    
    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }
  }
  
  /// Mark notification as read
  void markNotificationAsRead(String notificationId) {
    final notification = _notifications.firstWhere((notif) => notif.id == notificationId);
    notification.markAsRead();
    _unreadNotificationCount = _notifications.where((notif) => !notif.isRead).length;
    notifyListeners();
  }
  
  /// Mark all notifications as read
  void markAllNotificationsAsRead() {
    for (final notification in _notifications) {
      if (!notification.isRead) {
        notification.markAsRead();
      }
    }
    _unreadNotificationCount = 0;
    notifyListeners();
  }
  
  Future<void> loadNotifications() async {
    // Load from persistent storage
    // Implementation would depend on storage strategy
  }
  
  // ==================== PRIVATE HELPERS ====================
  
  void _applyFilters() {
    _filteredClosetItems = _closetItems.where((item) {
      // Category filter
      if (_selectedCategory.isNotEmpty && item.product.category != _selectedCategory) {
        return false;
      }
      
      // Brand filter
      if (_selectedBrand.isNotEmpty && item.product.vendor.name != _selectedBrand) {
        return false;
      }
      
      // Size filter
      if (_selectedSize.isNotEmpty && item.selectedSize != _selectedSize) {
        return false;
      }
      
      // Color filter
      if (_selectedColor.isNotEmpty && item.selectedColor != _selectedColor) {
        return false;
      }
      
      // Favorited filter
      if (_showOnlyFavorited && !item.isFavorited) {
        return false;
      }
      
      // On sale filter
      if (_showOnlyOnSale && !item.isOnSale) {
        return false;
      }
      
      // In outfits filter
      if (_showOnlyInOutfits && !item.isInOutfit) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    _filteredClosetItems.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'name':
          comparison = a.product.name.compareTo(b.product.name);
          break;
        case 'price':
          comparison = a.purchasePrice.compareTo(b.purchasePrice);
          break;
        case 'wearCount':
          comparison = a.wearCount.compareTo(b.wearCount);
          break;
        case 'lastWorn':
          if (a.lastWornDate == null && b.lastWornDate == null) comparison = 0;
          else if (a.lastWornDate == null) comparison = 1;
          else if (b.lastWornDate == null) comparison = -1;
          else comparison = a.lastWornDate!.compareTo(b.lastWornDate!);
          break;
        case 'dateAdded':
        default:
          comparison = a.savedAt.compareTo(b.savedAt);
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }
  
  void _applyOutfitFilters() {
    _filteredOutfits = _outfits.where((outfit) {
      // Search filter
      if (_outfitSearchQuery.isNotEmpty && !outfit.matchesSearch(_outfitSearchQuery)) {
        return false;
      }
      
      // Category filter
      if (outfit.category != _selectedOutfitCategory) {
        return false;
      }
      
      // Season filter
      if (outfit.season != _selectedSeason) {
        return false;
      }
      
      // Occasion filter
      if (outfit.occasion != _selectedOccasion) {
        return false;
      }
      
      // Favorited filter
      if (_showOnlyFavoritedOutfits && !outfit.isFavorited) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Apply sorting
    _filteredOutfits.sort((a, b) {
      int comparison = 0;
      
      switch (_outfitSortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'wearCount':
          comparison = a.wearCount.compareTo(b.wearCount);
          break;
        case 'lastWorn':
          if (a.lastWornDate == null && b.lastWornDate == null) comparison = 0;
          else if (a.lastWornDate == null) comparison = 1;
          else if (b.lastWornDate == null) comparison = -1;
          else comparison = a.lastWornDate!.compareTo(b.lastWornDate!);
          break;
        case 'dateCreated':
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      
      return _sortOutfitsAscending ? comparison : -comparison;
    });
  }
  
  // ==================== UTILITY METHODS ====================
  
  Future<void> removeFromClosetByProductName(String productName) async {
    final item = _closetItems.firstWhere((item) => item.product.name == productName);
    await removeFromCloset(item.id);
  }
  
  Future<void> deleteOutfitByName(String outfitName) async {
    final outfit = _outfits.firstWhere((outfit) => outfit.name == outfitName);
    await deleteOutfit(outfit.id);
  }
  
  /// Get outfit by ID
  Outfit? getOutfitById(String outfitId) {
    try {
      return _outfits.firstWhere((outfit) => outfit.id == outfitId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get closet item by ID
  ClosetItem? getClosetItemById(String itemId) {
    try {
      return _closetItems.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }
  
  // ==================== GETTERS ====================
  
  List<ClosetItem> get closetItems => _closetItems;
  List<ClosetItem> get filteredClosetItems => _filteredClosetItems;
  bool get isLoadingCloset => _isLoadingCloset;
  String? get closetError => _closetError;
  
  List<Outfit> get outfits => _outfits;
  List<Outfit> get filteredOutfits => _filteredOutfits;
  bool get isLoadingOutfits => _isLoadingOutfits;
  String? get outfitsError => _outfitsError;
  
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedBrand => _selectedBrand;
  String get selectedSize => _selectedSize;
  String get selectedColor => _selectedColor;
  ItemCondition get selectedCondition => _selectedCondition;
  bool get showOnlyFavorited => _showOnlyFavorited;
  bool get showOnlyOnSale => _showOnlyOnSale;
  bool get showOnlyInOutfits => _showOnlyInOutfits;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItemIds => _selectedItemIds;
  
  ClosetAnalytics? get analytics => _analytics;
  bool get isLoadingAnalytics => _isLoadingAnalytics;
  List<AnalyticsInsight> get insights => _insights;
  
  List<RecentActionEntry> get recentActions => _recentActions;
  
  List<ClosetNotification> get notifications => _notifications;
  int get unreadNotificationCount => _unreadNotificationCount;
  
  // ==================== MOCK DATA ====================
  
  List<ClosetItem> _getMockClosetItems() {
    return [
      // Mock data would be populated here for testing
    ];
  }
  
  List<Outfit> _getMockOutfits() {
    return [
      // Mock data would be populated here for testing
    ];
  }
  
  ClosetAnalytics _getMockAnalytics() {
    return ClosetAnalytics(
      totalItems: _closetItems.length,
      totalOutfits: _outfits.length,
      itemsByCategory: {'Tops': 10, 'Bottoms': 8, 'Dresses': 5},
      itemsByBrand: {'Zara': 5, 'H&M': 8, 'Uniqlo': 10},
      totalValue: _closetItems.fold(0.0, (sum, item) => sum + item.purchasePrice),
      averageCostPerWear: 25.0,
      mostWornItem: 0,
      wearingFrequency: {},
      seasonalUsage: {},
      insights: [],
    );
  }
  
  @override
  void dispose() {
    // Clean up resources
    super.dispose();
  }
}

// ==================== SUPPORTING CLASSES ====================

/// Recent action tracking
enum RecentAction {
  addedToCloset,
  removedFromCloset,
  outfitCreated,
  outfitDeleted,
  outfitWorn,
  markedAsWorn,
  itemsRemoved,
  itemsMovedToCart,
}

class RecentActionEntry {
  final String id;
  final RecentAction action;
  final String itemName;
  final DateTime timestamp;
  
  RecentActionEntry({
    required this.id,
    required this.action,
    required this.itemName,
    required this.timestamp,
  });
}

/// Notification types
enum NotificationType {
  itemAdded,
  itemRemoved,
  outfitCreated,
  outfitDeleted,
  itemsMovedToCart,
  closetSyncComplete,
  newRecommendation,
  priceDrop,
}

class ClosetNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  bool isRead;
  
  ClosetNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
  
  void markAsRead() {
    isRead = true;
  }
}