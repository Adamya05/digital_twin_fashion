import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/avatar_model.dart';
import 'api_service.dart';

/// Comprehensive avatar management service
/// Handles avatar storage, persistence, favorites, sharing, and backup/restore
class AvatarService {
  static const String _avatarsKey = 'user_avatars';
  static const String _favoritesKey = 'favorite_avatars';
  static const String _avatarHistoryKey = 'avatar_history';
  static const String _currentAvatarKey = 'current_avatar_id';
  
  final ApiService _apiService = ApiService();
  final SharedPreferences _prefs;

  AvatarService(this._prefs);

  /// Get current active avatar ID
  String? get currentAvatarId => _prefs.getString(_currentAvatarKey);

  /// Set current active avatar
  Future<bool> setCurrentAvatar(String avatarId) async {
    return await _prefs.setString(_currentAvatarKey, avatarId);
  }

  /// Get all user avatars
  List<Avatar> getAllAvatars() {
    final avatarsJson = _prefs.getString(_avatarsKey);
    if (avatarsJson == null) return [];
    
    try {
      final List<dynamic> avatarsList = jsonDecode(avatarsJson);
      return avatarsList.map((json) => Avatar.fromJson(json)).toList();
    } catch (e) {
      print('Error parsing avatars: $e');
      return [];
    }
  }

  /// Save avatar to local storage
  Future<bool> saveAvatar(Avatar avatar) async {
    final avatars = getAllAvatars();
    final existingIndex = avatars.indexWhere((a) => a.id == avatar.id);
    
    if (existingIndex >= 0) {
      avatars[existingIndex] = avatar;
    } else {
      avatars.add(avatar);
    }
    
    final avatarsJson = jsonEncode(avatars.map((a) => a.toJson()).toList());
    return await _prefs.setString(_avatarsKey, avatarsJson);
  }

  /// Delete avatar with confirmation
  Future<bool> deleteAvatar(String avatarId, {bool force = false}) async {
    if (!force) {
      final confirm = await _confirmDeletion();
      if (!confirm) return false;
    }

    final avatars = getAllAvatars();
    final avatarToDelete = avatars.firstWhere(
      (a) => a.id == avatarId, 
      orElse: () => Avatar.empty(),
    );
    
    if (avatarToDelete.id.isEmpty) return false;

    // Remove from avatars list
    avatars.removeWhere((a) => a.id == avatarId);
    final avatarsJson = jsonEncode(avatars.map((a) => a.toJson()).toList());
    final avatarsResult = await _prefs.setString(_avatarsKey, avatarsJson);

    // Remove from favorites
    await removeFromFavorites(avatarId);

    // Remove from history
    await removeFromHistory(avatarId);

    // Reset current avatar if it was deleted
    if (currentAvatarId == avatarId) {
      await setCurrentAvatar('');
    }

    // Archive deletion in history
    await _archiveDeletion(avatarToDelete);

    return avatarsResult;
  }

  /// Get favorites list
  List<String> getFavoriteIds() {
    return _prefs.getStringList(_favoritesKey) ?? [];
  }

  /// Add avatar to favorites
  Future<bool> addToFavorites(String avatarId) async {
    final favorites = getFavoriteIds();
    if (!favorites.contains(avatarId)) {
      favorites.add(avatarId);
      return await _prefs.setStringList(_favoritesKey, favorites);
    }
    return true;
  }

  /// Remove avatar from favorites
  Future<bool> removeFromFavorites(String avatarId) async {
    final favorites = getFavoriteIds();
    favorites.remove(avatarId);
    return await _prefs.setStringList(_favoritesKey, favorites);
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(String avatarId) async {
    final favorites = getFavoriteIds();
    if (favorites.contains(avatarId)) {
      return await removeFromFavorites(avatarId);
    } else {
      return await addToFavorites(avatarId);
    }
  }

  /// Get avatar history
  List<String> getAvatarHistory() {
    return _prefs.getStringList(_avatarHistoryKey) ?? [];
  }

  /// Add to avatar history
  Future<bool> addToHistory(String avatarId) async {
    final history = getAvatarHistory();
    
    // Remove if already exists
    history.remove(avatarId);
    
    // Add to beginning
    history.insert(0, avatarId);
    
    // Keep only last 20 entries
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    return await _prefs.setStringList(_avatarHistoryKey, history);
  }

  /// Remove from history
  Future<bool> removeFromHistory(String avatarId) async {
    final history = getAvatarHistory();
    history.remove(avatarId);
    return await _prefs.setStringList(_avatarHistoryKey, history);
  }

  /// Get avatar by ID
  Avatar? getAvatarById(String id) {
    return getAllAvatars().firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => Avatar.empty(),
    );
  }

  /// Get favorites avatars
  List<Avatar> getFavoriteAvatars() {
    final favoriteIds = getFavoriteIds();
    final allAvatars = getAllAvatars();
    return allAvatars.where((avatar) => favoriteIds.contains(avatar.id)).toList();
  }

  /// Search avatars by name or tags
  List<Avatar> searchAvatars(String query) {
    final allAvatars = getAllAvatars();
    final lowercaseQuery = query.toLowerCase();
    
    return allAvatars.where((avatar) {
      return avatar.name.toLowerCase().contains(lowercaseQuery) ||
             avatar.description?.toLowerCase().contains(lowercaseQuery) == true ||
             avatar.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  /// Filter avatars by attributes
  List<Avatar> filterAvatars({
    String? bodyType,
    String? ethnicity,
    String? gender,
    int? minAge,
    int? maxAge,
    bool? isFavorite,
  }) {
    final allAvatars = getAllAvatars();
    
    return allAvatars.where((avatar) {
      if (bodyType != null && avatar.attributes.bodyType != bodyType) {
        return false;
      }
      if (ethnicity != null && avatar.attributes.ethnicity != ethnicity) {
        return false;
      }
      if (gender != null && avatar.attributes.gender != gender) {
        return false;
      }
      if (minAge != null && avatar.attributes.age < minAge) {
        return false;
      }
      if (maxAge != null && avatar.attributes.age > maxAge) {
        return false;
      }
      if (isFavorite != null) {
        final isFav = getFavoriteIds().contains(avatar.id);
        if (isFavorite != isFav) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Backup all avatars
  Map<String, dynamic> exportAvatarData() {
    return {
      'avatars': getAllAvatars().map((a) => a.toJson()).toList(),
      'favorites': getFavoriteIds(),
      'history': getAvatarHistory(),
      'currentAvatar': currentAvatarId,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }

  /// Restore avatars from backup
  Future<bool> importAvatarData(Map<String, dynamic> data) async {
    try {
      // Clear existing data
      await _prefs.remove(_avatarsKey);
      await _prefs.remove(_favoritesKey);
      await _prefs.remove(_avatarHistoryKey);

      // Import avatars
      final avatarsJson = jsonEncode(data['avatars'] ?? []);
      final avatarsResult = await _prefs.setString(_avatarsKey, avatarsJson);

      // Import favorites
      final favoritesResult = await _prefs.setStringList(
        _favoritesKey, 
        List<String>.from(data['favorites'] ?? []),
      );

      // Import history
      final historyResult = await _prefs.setStringList(
        _avatarHistoryKey,
        List<String>.from(data['history'] ?? []),
      );

      // Import current avatar
      final currentAvatarResult = await _prefs.setString(
        _currentAvatarKey,
        data['currentAvatar'] as String? ?? '',
      );

      return avatarsResult && favoritesResult && historyResult && currentAvatarResult;
    } catch (e) {
      print('Error importing avatar data: $e');
      return false;
    }
  }

  /// Share avatar via JSON export
  String exportAvatarAsJson(String avatarId) {
    final avatar = getAvatarById(avatarId);
    if (avatar == null || avatar.id.isEmpty) {
      throw Exception('Avatar not found');
    }
    
    final shareData = {
      'avatar': avatar.toJson(),
      'sharedDate': DateTime.now().toIso8601String(),
      'sharedBy': 'user', // Could be extended to include user info
      'version': '1.0',
    };
    
    return jsonEncode(shareData);
  }

  /// Import avatar from shared JSON
  Avatar? importAvatarFromJson(String jsonData) {
    try {
      final data = jsonDecode(jsonData);
      final avatar = Avatar.fromJson(data['avatar']);
      
      // Ensure unique ID
      final newId = '${avatar.id}_imported_${DateTime.now().millisecondsSinceEpoch}';
      final importedAvatar = avatar.copyWith(id: newId);
      
      saveAvatar(importedAvatar);
      return importedAvatar;
    } catch (e) {
      print('Error importing avatar from JSON: $e');
      return null;
    }
  }

  /// Clean up old avatars (older than specified days)
  Future<int> cleanupOldAvatars({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    final allAvatars = getAllAvatars();
    final favorites = getFavoriteIds();
    final current = currentAvatarId;
    
    int deletedCount = 0;
    
    for (final avatar in List.from(allAvatars)) {
      // Don't delete favorites, current avatar, or recent avatars
      if (favorites.contains(avatar.id) || 
          avatar.id == current || 
          avatar.updatedAt.isAfter(cutoffDate)) {
        continue;
      }
      
      await deleteAvatar(avatar.id, force: true);
      deletedCount++;
    }
    
    return deletedCount;
  }

  /// Get storage statistics
  Map<String, dynamic> getStorageStats() {
    final allAvatars = getAllAvatars();
    final favorites = getFavoriteIds();
    final history = getAvatarHistory();
    
    return {
      'totalAvatars': allAvatars.length,
      'favoriteCount': favorites.length,
      'historyCount': history.length,
      'totalSizeBytes': allAvatars.fold(0, (sum, avatar) => sum + avatar.metadata.fileSize.toInt()),
      'averageFileSize': allAvatars.isNotEmpty 
          ? allAvatars.fold(0, (sum, avatar) => sum + avatar.metadata.fileSize) / allAvatars.length
          : 0,
      'oldestAvatar': allAvatars.isNotEmpty 
          ? allAvatars.map((a) => a.createdAt).reduce((a, b) => a.isBefore(b) ? a : b).toIso8601String()
          : null,
      'newestAvatar': allAvatars.isNotEmpty 
          ? allAvatars.map((a) => a.createdAt).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
          : null,
    };
  }

  // Private helper methods
  Future<bool> _confirmDeletion() async {
    // In a real implementation, this would show a dialog
    // For now, we'll return true (always confirm in test/mock mode)
    return true;
  }

  Future<void> _archiveDeletion(Avatar avatar) async {
    // Archive deletion for potential recovery
    final history = getAvatarHistory();
    final deletionArchive = 'deleted_${avatar.id}_${DateTime.now().millisecondsSinceEpoch}';
    history.insert(0, deletionArchive);
    
    // Keep only last 10 deletions
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await _prefs.setStringList(_avatarHistoryKey, history);
  }
}