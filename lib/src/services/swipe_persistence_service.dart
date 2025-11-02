/// Swipe Persistence Service
///
/// Handles storage and retrieval of swipe history, user preferences, and saved items.
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/swipe_history_model.dart';

class SwipePersistenceService {
  static const String _swipeHistoryKey = 'swipe_history';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _savedItemsKey = 'saved_items';
  static const String _undoActionKey = 'undo_action';
  static const int _maxHistorySize = 1000;
  static const int _undoTimeoutSeconds = 5;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Swipe History Operations
  Future<List<SwipeHistory>> getSwipeHistory() async {
    if (_prefs == null) await init();
    
    final historyJson = _prefs!.getStringList(_swipeHistoryKey) ?? [];
    return historyJson
        .map((json) => SwipeHistory.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addSwipeAction(SwipeHistory swipe) async {
    if (_prefs == null) await init();
    
    final history = await getSwipeHistory();
    history.insert(0, swipe);
    
    // Keep history size manageable
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }
    
    final historyJson = history.map((swipe) => jsonEncode(swipe.toJson())).toList();
    await _prefs!.setStringList(_swipeHistoryKey, historyJson);
    
    // Update user preferences based on this action
    await _updatePreferencesFromSwipe(swipe);
  }

  Future<void> clearSwipeHistory() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_swipeHistoryKey);
  }

  // User Preferences Operations
  Future<UserSwipePreferences?> getUserPreferences(String userId) async {
    if (_prefs == null) await init();
    
    final prefsJson = _prefs!.getString(_userPreferencesKey);
    if (prefsJson == null) return null;
    
    final preferences = UserSwipePreferences.fromJson(jsonDecode(prefsJson));
    
    // Update userId if it doesn't match
    if (preferences.userId != userId) {
      return preferences.copyWith(userId: userId);
    }
    
    return preferences;
  }

  Future<void> saveUserPreferences(UserSwipePreferences preferences) async {
    if (_prefs == null) await init();
    
    final prefsJson = jsonEncode(preferences.toJson());
    await _prefs!.setString(_userPreferencesKey, prefsJson);
  }

  Future<UserSwipePreferences> getOrCreateDefaultPreferences(String userId) async {
    var preferences = await getUserPreferences(userId);
    
    if (preferences == null) {
      preferences = UserSwipePreferences(
        userId: userId,
        categoryPreferences: {},
        brandPreferences: {},
        swipeSensitivity: 0.5,
        hapticFeedbackEnabled: true,
        soundEffectsEnabled: false,
        analyticsEnabled: true,
        lastUpdated: DateTime.now(),
      );
      await saveUserPreferences(preferences);
    }
    
    return preferences;
  }

  // Saved Items Operations
  Future<List<SavedItem>> getSavedItems() async {
    if (_prefs == null) await init();
    
    final savedItemsJson = _prefs!.getStringList(_savedItemsKey) ?? [];
    return savedItemsJson
        .map((json) => SavedItem.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveItem(SavedItem item) async {
    if (_prefs == null) await init();
    
    final savedItems = await getSavedItems();
    
    // Remove existing item with same ID if present
    savedItems.removeWhere((saved) => saved.id == item.id);
    savedItems.insert(0, item);
    
    final savedItemsJson = savedItems.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs!.setStringList(_savedItemsKey, savedItemsJson);
    
    // Store for potential undo
    await _storeUndoAction({'type': 'save', 'item': item.toJson()});
  }

  Future<void> removeSavedItem(String itemId) async {
    if (_prefs == null) await init();
    
    final savedItems = await getSavedItems();
    final itemToRemove = savedItems.firstWhere((item) => item.id == itemId);
    
    savedItems.removeWhere((item) => item.id == itemId);
    
    final savedItemsJson = savedItems.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs!.setStringList(_savedItemsKey, savedItemsJson);
    
    // Store for potential undo
    await _storeUndoAction({'type': 'remove', 'item': itemToRemove.toJson()});
  }

  Future<void> updateSavedItem(SavedItem updatedItem) async {
    if (_prefs == null) await init();
    
    final savedItems = await getSavedItems();
    final index = savedItems.indexWhere((item) => item.id == updatedItem.id);
    
    if (index != -1) {
      savedItems[index] = updatedItem;
      final savedItemsJson = savedItems.map((item) => jsonEncode(item.toJson())).toList();
      await _prefs!.setStringList(_savedItemsKey, savedItemsJson);
    }
  }

  // Undo Functionality
  Future<Map<String, dynamic>?> getUndoAction() async {
    if (_prefs == null) await init();
    
    final undoJson = _prefs!.getString(_undoActionKey);
    if (undoJson == null) return null;
    
    final action = jsonDecode(undoJson);
    
    // Check if undo action has expired
    final timestamp = DateTime.parse(action['timestamp']);
    if (DateTime.now().difference(timestamp).inSeconds > _undoTimeoutSeconds) {
      await clearUndoAction();
      return null;
    }
    
    return action;
  }

  Future<void> clearUndoAction() async {
    if (_prefs == null) await init();
    await _prefs!.remove(_undoActionKey);
  }

  Future<bool> canUndo() async {
    final undoAction = await getUndoAction();
    return undoAction != null;
  }

  Future<Map<String, dynamic>?> performUndo() async {
    final undoAction = await getUndoAction();
    if (undoAction == null) return null;
    
    switch (undoAction['type']) {
      case 'save':
        final item = SavedItem.fromJson(undoAction['item']);
        await removeSavedItem(item.id);
        break;
      case 'remove':
        final item = SavedItem.fromJson(undoAction['item']);
        await saveItem(item);
        break;
    }
    
    await clearUndoAction();
    return undoAction;
  }

  // Analytics and Insights
  Future<Map<String, dynamic>> getSwipeAnalytics() async {
    final history = await getSwipeHistory();
    final savedItems = await getSavedItems();
    
    final analytics = {
      'totalSwipes': history.length,
      'likes': history.where((swipe) => swipe.action == SwipeAction.like).length,
      'dislikes': history.where((swipe) => swipe.action == SwipeAction.dislike).length,
      'superLikes': history.where((swipe) => swipe.action == SwipeAction.superLike).length,
      'skips': history.where((swipe) => swipe.action == SwipeAction.skip).length,
      'savedItems': savedItems.length,
      'averageSwipeVelocity': history.isNotEmpty 
          ? history.fold<double>(0.0, (sum, swipe) => sum + swipe.swipeVelocity) / history.length
          : 0.0,
      'mostLikedCategories': await _getMostLikedCategories(),
      'recentActivity': history.take(10).toList(),
    };
    
    return analytics;
  }

  Future<List<String>> _getMostLikedCategories() async {
    final history = await getSwipeHistory();
    final categoryCounts = <String, int>{};
    
    // This would need access to product data to get categories
    // For now, return empty list
    return [];
  }

  Future<void> _updatePreferencesFromSwipe(SwipeHistory swipe) async {
    // This would update category and brand preferences based on swipe action
    // Implementation depends on having access to product data
  }

  Future<void> _storeUndoAction(Map<String, dynamic> action) async {
    action['timestamp'] = DateTime.now().toIso8601String();
    final actionJson = jsonEncode(action);
    await _prefs!.setString(_undoActionKey, actionJson);
  }

  // Clear all data (for testing or logout)
  Future<void> clearAllData() async {
    if (_prefs == null) await init();
    
    await _prefs!.remove(_swipeHistoryKey);
    await _prefs!.remove(_userPreferencesKey);
    await _prefs!.remove(_savedItemsKey);
    await _prefs!.remove(_undoActionKey);
  }
}