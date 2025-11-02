/// Data Service
/// 
/// Centralized data management service with CRUD operations,
/// data validation, migration, and cloud synchronization support.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user_profile_model.dart';
import '../models/avatar_data_model.dart';
import '../models/saved_look_model.dart';
import '../models/app_settings_model.dart';
import '../models/user_statistics_model.dart';
import '../models/product_model.dart';
import '../models/avatar_model.dart';

class DataService {
  static const String _databaseName = 'fashion_app.db';
  static const int _databaseVersion = 1;
  
  // SharedPreferences keys
  static const String _prefsUserProfileKey = 'user_profile';
  static const String _prefsAppSettingsKey = 'app_settings';
  static const String _prefsOnboardingKey = 'onboarding_completed';
  static const String _prefsLastSyncKey = 'last_sync_time';
  static const String _prefsDataVersionKey = 'data_version';

  // Database table names
  static const String _tableClosetItems = 'closet_items';
  static const String _tableSavedLooks = 'saved_looks';
  static const String _tableAvatarData = 'avatar_data';
  static const String _tableUserStatistics = 'user_statistics';
  static const String _tableActivityFeed = 'activity_feed';
  static const String _tableSyncQueue = 'sync_queue';
  static const String _tableDataBackup = 'data_backup';

  static DataService? _instance;
  static DataService get instance => _instance ??= DataService._();

  DataService._();

  Database? _database;
  SharedPreferences? _preferences;
  bool _isInitialized = false;
  final Map<String, dynamic> _memoryCache = {};
  final List<Function> _listeners = [];

  // ==================== INITIALIZATION ====================

  /// Initialize the data service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences
      _preferences = await SharedPreferences.getInstance();
      
      // Initialize database
      await _initializeDatabase();
      
      // Perform data migration if needed
      await _performDataMigration();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('DataService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize DataService: $e');
      rethrow;
    }
  }

  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    
    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onDatabaseCreate,
      onUpgrade: _onDatabaseUpgrade,
    );
  }

  Future<void> _onDatabaseCreate(Database db, int version) async {
    // Create closet_items table
    await db.execute('''
      CREATE TABLE $_tableClosetItems (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        product_id TEXT,
        name TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        subcategory TEXT,
        brand TEXT,
        primary_image TEXT,
        images TEXT,
        size TEXT,
        color TEXT,
        original_price REAL,
        current_price REAL,
        currency TEXT DEFAULT 'USD',
        rating TEXT,
        purchase_date TEXT,
        added_to_closet TEXT NOT NULL,
        last_worn TEXT,
        wear_count INTEGER DEFAULT 0,
        times_borrowed INTEGER DEFAULT 0,
        is_favorite INTEGER DEFAULT 0,
        is_available INTEGER DEFAULT 1,
        needs_cleaning INTEGER DEFAULT 0,
        needs_repair INTEGER DEFAULT 0,
        condition TEXT DEFAULT 'good',
        care_instructions TEXT,
        tags TEXT,
        occasions TEXT,
        seasons TEXT,
        notes TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create saved_looks table
    await db.execute('''
      CREATE TABLE $_tableSavedLooks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        items TEXT NOT NULL,
        primary_image TEXT,
        gallery_images TEXT,
        style TEXT,
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_worn TEXT,
        wear_count INTEGER DEFAULT 0,
        rating REAL DEFAULT 0.0,
        is_favorite INTEGER DEFAULT 0,
        is_public INTEGER DEFAULT 0,
        metadata TEXT,
        weather_conditions TEXT,
        occasion TEXT,
        color_scheme TEXT,
        accessories TEXT
      )
    ''');

    // Create avatar_data table
    await db.execute('''
      CREATE TABLE $_tableAvatarData (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        measurements TEXT NOT NULL,
        attributes TEXT NOT NULL,
        metadata TEXT NOT NULL,
        measurement_history TEXT,
        customizations TEXT,
        settings TEXT NOT NULL,
        style_presets TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_used TEXT NOT NULL,
        usage_count INTEGER DEFAULT 0,
        is_default INTEGER DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        custom_data TEXT
      )
    ''');

    // Create user_statistics table
    await db.execute('''
      CREATE TABLE $_tableUserStatistics (
        user_id TEXT PRIMARY KEY,
        join_date TEXT NOT NULL,
        total_spent REAL DEFAULT 0.0,
        total_orders INTEGER DEFAULT 0,
        total_saved_items INTEGER DEFAULT 0,
        total_saved_looks INTEGER DEFAULT 0,
        total_try_ons INTEGER DEFAULT 0,
        total_shares INTEGER DEFAULT 0,
        total_reviews INTEGER DEFAULT 0,
        average_rating REAL DEFAULT 0.0,
        loyalty_tier TEXT DEFAULT 'bronze',
        loyalty_points REAL DEFAULT 0.0,
        favorite_brands TEXT,
        favorite_categories TEXT,
        preferred_colors TEXT,
        days_active INTEGER DEFAULT 0,
        total_app_sessions INTEGER DEFAULT 0,
        total_time_spent INTEGER DEFAULT 0,
        style_consistency REAL DEFAULT 0.0,
        achievements TEXT,
        recent_activity TEXT,
        category_preferences TEXT,
        brand_preferences TEXT,
        color_preferences TEXT,
        sustainability_score REAL DEFAULT 0.0,
        referral_count INTEGER DEFAULT 0,
        referrals_completed INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create activity_feed table
    await db.execute('''
      CREATE TABLE $_tableActivityFeed (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        timestamp TEXT NOT NULL,
        metadata TEXT
      )
    ''');

    // Create sync_queue table
    await db.execute('''
      CREATE TABLE $_tableSyncQueue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_closet_items_user_id ON $_tableClosetItems(user_id)');
    await db.execute('CREATE INDEX idx_saved_looks_user_id ON $_tableSavedLooks(user_id)');
    await db.execute('CREATE INDEX idx_avatar_data_user_id ON $_tableAvatarData(user_id)');
    await db.execute('CREATE INDEX idx_activity_feed_user_id ON $_tableActivityFeed(user_id)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON $_tableSyncQueue(status)');
  }

  Future<void> _onDatabaseUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema migrations here
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
  }

  Future<void> _performDataMigration() async {
    final currentVersion = _preferences?.getString(_prefsDataVersionKey) ?? '0';
    
    if (currentVersion != _databaseVersion.toString()) {
      debugPrint('Performing data migration from version $currentVersion');
      
      // Perform migration steps here
      await _preferences?.setString(_prefsDataVersionKey, _databaseVersion.toString());
    }
  }

  // ==================== USER PROFILE OPERATIONS ====================

  /// Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    await _ensureInitialized();
    
    final cachedProfile = _memoryCache['user_profile_$userId'] as UserProfile?;
    if (cachedProfile != null) return cachedProfile;

    final profileJson = _preferences?.getString(_prefsUserProfileKey);
    if (profileJson == null) return null;

    try {
      final profile = UserProfile.fromJson(jsonDecode(profileJson));
      _memoryCache['user_profile_$userId'] = profile;
      return profile;
    } catch (e) {
      debugPrint('Error parsing user profile: $e');
      return null;
    }
  }

  /// Save user profile
  Future<void> saveUserProfile(UserProfile profile) async {
    await _ensureInitialized();

    try {
      final profileJson = jsonEncode(profile.toJson());
      await _preferences?.setString(_prefsUserProfileKey, profileJson);
      _memoryCache['user_profile_${profile.id}'] = profile;
      
      // Queue for cloud sync
      await _queueForSync('user_profiles', profile.id, 'update', profile.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<UserProfile?> updateUserProfile(String userId, UserProfile updatedProfile) async {
    final currentProfile = await getUserProfile(userId);
    if (currentProfile == null) return null;

    final mergedProfile = currentProfile.copyWith(
      name: updatedProfile.name,
      email: updatedProfile.email,
      avatarUrl: updatedProfile.avatarUrl,
      preferences: updatedProfile.preferences,
      avatarData: updatedProfile.avatarData,
      statistics: updatedProfile.statistics,
      settings: updatedProfile.settings,
      updatedAt: DateTime.now(),
    );

    await saveUserProfile(mergedProfile);
    return mergedProfile;
  }

  // ==================== APP SETTINGS OPERATIONS ====================

  /// Get app settings
  Future<AppSettings?> getAppSettings(String userId) async {
    await _ensureInitialized();

    final cachedSettings = _memoryCache['app_settings_$userId'] as AppSettings?;
    if (cachedSettings != null) return cachedSettings;

    final settingsJson = _preferences?.getString(_prefsAppSettingsKey);
    if (settingsJson == null) return null;

    try {
      final settings = AppSettings.fromJson(jsonDecode(settingsJson));
      _memoryCache['app_settings_$userId'] = settings;
      return settings;
    } catch (e) {
      debugPrint('Error parsing app settings: $e');
      return null;
    }
  }

  /// Save app settings
  Future<void> saveAppSettings(AppSettings settings) async {
    await _ensureInitialized();

    try {
      final settingsJson = jsonEncode(settings.toJson());
      await _preferences?.setString(_prefsAppSettingsKey, settingsJson);
      _memoryCache['app_settings_${settings.userId}'] = settings;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving app settings: $e');
      rethrow;
    }
  }

  /// Update specific setting
  Future<AppSettings> updateAppSetting(
    String userId, 
    String key, 
    dynamic value
  ) async {
    final settings = await getAppSettings(userId);
    if (settings == null) {
      throw Exception('App settings not found for user: $userId');
    }

    final updatedSettings = settings.setSetting(key, value);
    await saveAppSettings(updatedSettings);
    return updatedSettings;
  }

  // ==================== CLOSET ITEM OPERATIONS ====================

  /// Get all closet items for user
  Future<List<ClosetItem>> getClosetItems(String userId) async {
    await _ensureInitialized();

    final cacheKey = 'closet_items_$userId';
    if (_memoryCache[cacheKey] != null) {
      return _memoryCache[cacheKey] as List<ClosetItem>;
    }

    try {
      final items = await _database!.query(
        _tableClosetItems,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final closetItems = items.map((item) {
        final itemMap = Map<String, dynamic>.from(item);
        return ClosetItem.fromJson(_deserializeJsonFields(itemMap));
      }).toList();

      _memoryCache[cacheKey] = closetItems;
      return closetItems;
    } catch (e) {
      debugPrint('Error fetching closet items: $e');
      return [];
    }
  }

  /// Save closet item
  Future<void> saveClosetItem(ClosetItem item) async {
    await _ensureInitialized();

    try {
      final itemMap = _serializeJsonFields(item.toJson());
      itemMap['created_at'] = item.addedToCloset.toIso8601String();
      itemMap['updated_at'] = DateTime.now().toIso8601String();

      await _database!.insert(
        _tableClosetItems,
        itemMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Clear cache and notify listeners
      _memoryCache.remove('closet_items_${item.userId}');
      await _queueForSync(_tableClosetItems, item.id, 'insert', item.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving closet item: $e');
      rethrow;
    }
  }

  /// Update closet item
  Future<void> updateClosetItem(ClosetItem item) async {
    await _ensureInitialized();

    try {
      final itemMap = _serializeJsonFields(item.toJson());
      itemMap['updated_at'] = DateTime.now().toIso8601String();

      await _database!.update(
        _tableClosetItems,
        itemMap,
        where: 'id = ?',
        whereArgs: [item.id],
      );

      _memoryCache.remove('closet_items_${item.userId}');
      await _queueForSync(_tableClosetItems, item.id, 'update', item.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating closet item: $e');
      rethrow;
    }
  }

  /// Delete closet item
  Future<void> deleteClosetItem(String itemId, String userId) async {
    await _ensureInitialized();

    try {
      await _database!.delete(
        _tableClosetItems,
        where: 'id = ? AND user_id = ?',
        whereArgs: [itemId, userId],
      );

      _memoryCache.remove('closet_items_$userId');
      await _queueForSync(_tableClosetItems, itemId, 'delete', {});
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting closet item: $e');
      rethrow;
    }
  }

  // ==================== SAVED LOOK OPERATIONS ====================

  /// Get all saved looks for user
  Future<List<SavedLook>> getSavedLooks(String userId) async {
    await _ensureInitialized();

    final cacheKey = 'saved_looks_$userId';
    if (_memoryCache[cacheKey] != null) {
      return _memoryCache[cacheKey] as List<SavedLook>;
    }

    try {
      final looks = await _database!.query(
        _tableSavedLooks,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final savedLooks = looks.map((look) {
        final lookMap = Map<String, dynamic>.from(look);
        return SavedLook.fromJson(_deserializeJsonFields(lookMap));
      }).toList();

      _memoryCache[cacheKey] = savedLooks;
      return savedLooks;
    } catch (e) {
      debugPrint('Error fetching saved looks: $e');
      return [];
    }
  }

  /// Save saved look
  Future<void> saveSavedLook(SavedLook look) async {
    await _ensureInitialized();

    try {
      final lookMap = _serializeJsonFields(look.toJson());
      lookMap['created_at'] = look.createdAt.toIso8601String();
      lookMap['updated_at'] = DateTime.now().toIso8601String();

      await _database!.insert(
        _tableSavedLooks,
        lookMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _memoryCache.remove('saved_looks_${look.userId}');
      await _queueForSync(_tableSavedLooks, look.id, 'insert', look.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving saved look: $e');
      rethrow;
    }
  }

  /// Delete saved look
  Future<void> deleteSavedLook(String lookId, String userId) async {
    await _ensureInitialized();

    try {
      await _database!.delete(
        _tableSavedLooks,
        where: 'id = ? AND user_id = ?',
        whereArgs: [lookId, userId],
      );

      _memoryCache.remove('saved_looks_$userId');
      await _queueForSync(_tableSavedLooks, lookId, 'delete', {});
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting saved look: $e');
      rethrow;
    }
  }

  // ==================== AVATAR DATA OPERATIONS ====================

  /// Get avatar data for user
  Future<List<AvatarData>> getAvatarData(String userId) async {
    await _ensureInitialized();

    final cacheKey = 'avatar_data_$userId';
    if (_memoryCache[cacheKey] != null) {
      return _memoryCache[cacheKey] as List<AvatarData>;
    }

    try {
      final avatars = await _database!.query(
        _tableAvatarData,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      final avatarDataList = avatars.map((avatar) {
        final avatarMap = Map<String, dynamic>.from(avatar);
        return AvatarData.fromJson(_deserializeJsonFields(avatarMap));
      }).toList();

      _memoryCache[cacheKey] = avatarDataList;
      return avatarDataList;
    } catch (e) {
      debugPrint('Error fetching avatar data: $e');
      return [];
    }
  }

  /// Save avatar data
  Future<void> saveAvatarData(AvatarData avatarData) async {
    await _ensureInitialized();

    try {
      final avatarMap = _serializeJsonFields(avatarData.toJson());
      avatarMap['created_at'] = avatarData.createdAt.toIso8601String();
      avatarMap['updated_at'] = DateTime.now().toIso8601String();

      await _database!.insert(
        _tableAvatarData,
        avatarMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _memoryCache.remove('avatar_data_${avatarData.userId}');
      await _queueForSync(_tableAvatarData, avatarData.id, 'insert', avatarData.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving avatar data: $e');
      rethrow;
    }
  }

  // ==================== USER STATISTICS OPERATIONS ====================

  /// Get user statistics
  Future<UserStatistics?> getUserStatistics(String userId) async {
    await _ensureInitialized();

    final cachedStats = _memoryCache['user_stats_$userId'] as UserStatistics?;
    if (cachedStats != null) return cachedStats;

    try {
      final stats = await _database!.query(
        _tableUserStatistics,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (stats.isEmpty) return null;

      final statsMap = _deserializeJsonFields(Map<String, dynamic>.from(stats.first));
      final userStats = UserStatistics.fromJson(statsMap);
      
      _memoryCache['user_stats_$userId'] = userStats;
      return userStats;
    } catch (e) {
      debugPrint('Error fetching user statistics: $e');
      return null;
    }
  }

  /// Update user statistics
  Future<void> updateUserStatistics(UserStatistics statistics) async {
    await _ensureInitialized();

    try {
      final statsMap = _serializeJsonFields(statistics.toJson());
      statsMap['updated_at'] = DateTime.now().toIso8601String();

      await _database!.insert(
        _tableUserStatistics,
        statsMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      _memoryCache.remove('user_stats_${statistics.userId}');
      await _queueForSync(_tableUserStatistics, statistics.userId, 'update', statistics.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating user statistics: $e');
      rethrow;
    }
  }

  // ==================== ACTIVITY FEED OPERATIONS ====================

  /// Add activity feed item
  Future<void> addActivityItem(ActivityFeedItem item) async {
    await _ensureInitialized();

    try {
      final itemMap = _serializeJsonFields(item.toJson());
      
      await _database!.insert(
        _tableActivityFeed,
        itemMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await _queueForSync(_tableActivityFeed, item.id, 'insert', item.toJson());
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding activity item: $e');
      rethrow;
    }
  }

  /// Get activity feed for user
  Future<List<ActivityFeedItem>> getActivityFeed(String userId, {int? limit}) async {
    await _ensureInitialized();

    try {
      final items = await _database!.query(
        _tableActivityFeed,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      return items.map((item) {
        final itemMap = Map<String, dynamic>.from(item);
        return ActivityFeedItem.fromJson(_deserializeJsonFields(itemMap));
      }).toList();
    } catch (e) {
      debugPrint('Error fetching activity feed: $e');
      return [];
    }
  }

  // ==================== DATA VALIDATION ====================

  /// Validate data before saving
  bool validateUserProfile(UserProfile profile) {
    if (profile.id.isEmpty) return false;
    if (profile.email.isEmpty) return false;
    if (profile.name.isEmpty) return false;
    return true;
  }

  bool validateClosetItem(ClosetItem item) {
    if (item.id.isEmpty) return false;
    if (item.userId.isEmpty) return false;
    if (item.name.isEmpty) return false;
    if (item.category.isEmpty) return false;
    if (item.originalPrice < 0) return false;
    return true;
  }

  bool validateSavedLook(SavedLook look) {
    if (look.id.isEmpty) return false;
    if (look.userId.isEmpty) return false;
    if (look.name.isEmpty) return false;
    if (look.items.isEmpty) return false;
    return true;
  }

  // ==================== DATA EXPORT/IMPORT ====================

  /// Export all user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    await _ensureInitialized();

    final data = {
      'user_profile': await getUserProfile(userId)?.toJson(),
      'app_settings': await getAppSettings(userId)?.toJson(),
      'closet_items': (await getClosetItems(userId)).map((item) => item.toJson()).toList(),
      'saved_looks': (await getSavedLooks(userId)).map((look) => look.toJson()).toList(),
      'avatar_data': (await getAvatarData(userId)).map((avatar) => avatar.toJson()).toList(),
      'user_statistics': await getUserStatistics(userId)?.toJson(),
      'export_timestamp': DateTime.now().toIso8601String(),
      'version': _databaseVersion.toString(),
    };

    return data;
  }

  /// Import user data
  Future<void> importUserData(String userId, Map<String, dynamic> data) async {
    await _ensureInitialized();

    try {
      // Import user profile
      if (data['user_profile'] != null) {
        final profile = UserProfile.fromJson(data['user_profile']);
        if (validateUserProfile(profile)) {
          await saveUserProfile(profile);
        }
      }

      // Import app settings
      if (data['app_settings'] != null) {
        final settings = AppSettings.fromJson(data['app_settings']);
        await saveAppSettings(settings);
      }

      // Import closet items
      if (data['closet_items'] != null) {
        for (final itemData in data['closet_items'] as List) {
          final item = ClosetItem.fromJson(itemData);
          if (validateClosetItem(item)) {
            await saveClosetItem(item);
          }
        }
      }

      // Import saved looks
      if (data['saved_looks'] != null) {
        for (final lookData in data['saved_looks'] as List) {
          final look = SavedLook.fromJson(lookData);
          if (validateSavedLook(look)) {
            await saveSavedLook(look);
          }
        }
      }

      // Import avatar data
      if (data['avatar_data'] != null) {
        for (final avatarData in data['avatar_data'] as List) {
          final avatar = AvatarData.fromJson(avatarData);
          await saveAvatarData(avatar);
        }
      }

      // Import user statistics
      if (data['user_statistics'] != null) {
        final stats = UserStatistics.fromJson(data['user_statistics']);
        await updateUserStatistics(stats);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error importing user data: $e');
      rethrow;
    }
  }

  // ==================== SYNC OPERATIONS ====================

  /// Queue data for cloud synchronization
  Future<void> _queueForSync(String tableName, String recordId, String operation, Map<String, dynamic> data) async {
    if (_database == null) return;

    try {
      final syncItem = {
        'id': '${tableName}_$recordId',
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().toIso8601String(),
        'retry_count': 0,
        'status': 'pending',
      };

      await _database!.insert(
        _tableSyncQueue,
        syncItem,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint('Error queueing for sync: $e');
    }
  }

  /// Perform sync with cloud (placeholder implementation)
  Future<void> syncWithCloud() async {
    if (_database == null) return;

    try {
      final pendingItems = await _database!.query(
        _tableSyncQueue,
        where: 'status = ?',
        whereArgs: ['pending'],
      );

      for (final item in pendingItems) {
        try {
          // Here you would implement actual cloud sync logic
          debugPrint('Syncing item: ${item['table_name']}.${item['record_id']}');
          
          // Update sync status
          await _database!.update(
            _tableSyncQueue,
            {'status': 'completed'},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        } catch (e) {
          debugPrint('Error syncing item: $e');
          
          // Increment retry count
          final retryCount = (item['retry_count'] as int) + 1;
          await _database!.update(
            _tableSyncQueue,
            {'retry_count': retryCount, 'status': retryCount < 3 ? 'pending' : 'failed'},
            where: 'id = ?',
            whereArgs: [item['id']],
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing with cloud: $e');
    }
  }

  // ==================== CLEANUP OPERATIONS ====================

  /// Clear all cached data
  void clearCache() {
    _memoryCache.clear();
  }

  /// Clear all user data
  Future<void> clearAllData(String userId) async {
    await _ensureInitialized();

    try {
      // Clear database tables
      await _database!.delete(_tableClosetItems, where: 'user_id = ?', whereArgs: [userId]);
      await _database!.delete(_tableSavedLooks, where: 'user_id = ?', whereArgs: [userId]);
      await _database!.delete(_tableAvatarData, where: 'user_id = ?', whereArgs: [userId]);
      await _database!.delete(_tableUserStatistics, where: 'user_id = ?', whereArgs: [userId]);
      await _database!.delete(_tableActivityFeed, where: 'user_id = ?', whereArgs: [userId]);

      // Clear preferences
      await _preferences?.remove(_prefsUserProfileKey);
      await _preferences?.remove(_prefsAppSettingsKey);

      // Clear cache
      _memoryCache.clear();

      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      rethrow;
    }
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);
    final file = File(path);
    
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  // ==================== UTILITY METHODS ====================

  Map<String, dynamic> _serializeJsonFields(Map<String, dynamic> data) {
    final serialized = Map<String, dynamic>.from(data);
    
    for (final entry in serialized.entries) {
      if (entry.value is List || entry.value is Map) {
        serialized[entry.key] = jsonEncode(entry.value);
      }
    }
    
    return serialized;
  }

  Map<String, dynamic> _deserializeJsonFields(Map<String, dynamic> data) {
    final deserialized = Map<String, dynamic>.from(data);
    
    for (final entry in deserialized.entries) {
      if (entry.value is String && entry.value != '') {
        try {
          final decoded = jsonDecode(entry.value);
          if (decoded is List || decoded is Map) {
            deserialized[entry.key] = decoded;
          }
        } catch (e) {
          // Keep original string if JSON decoding fails
        }
      }
    }
    
    return deserialized;
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  void addListener(Function listener) {
    _listeners.add(listener);
  }

  void removeListener(Function listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error notifying listener: $e');
      }
    }
  }

  // ==================== DISPOSAL ====================

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
    _preferences = null;
    _memoryCache.clear();
    _listeners.clear();
    _isInitialized = false;
  }
}