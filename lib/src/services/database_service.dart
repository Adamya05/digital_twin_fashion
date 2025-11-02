/// Database Service
/// 
/// Provides database schema management, migrations, and query optimization
/// for the local SQLite database used by the fashion app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'data_service.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  Database? _database;
  bool _isInitialized = false;

  // Database configuration
  static const String _databaseName = 'fashion_app.db';
  static const int _databaseVersion = 2;
  static const int _pageSize = 4096;
  static const int _cacheSize = 1000;

  // Database paths
  String? _databasePath;

  // ==================== INITIALIZATION ====================

  /// Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final databasesPath = await getDatabasesPath();
      _databasePath = join(databasesPath, _databaseName);

      _database = await openDatabase(
        _databasePath!,
        version: _databaseVersion,
        onCreate: _onDatabaseCreate,
        onUpgrade: _onDatabaseUpgrade,
        onOpen: _onDatabaseOpen,
      );

      // Configure database settings
      await _configureDatabase();

      _isInitialized = true;
      debugPrint('DatabaseService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize DatabaseService: $e');
      rethrow;
    }
  }

  /// Configure database settings for optimal performance
  Future<void> _configureDatabase() async {
    if (_database == null) return;

    try {
      // Set page size for better performance
      await _database!.execute('PRAGMA page_size = $_pageSize');
      
      // Set cache size
      await _database!.execute('PRAGMA cache_size = $_cacheSize');
      
      // Enable foreign key constraints
      await _database!.execute('PRAGMA foreign_keys = ON');
      
      // Set synchronous mode for balance of safety and performance
      await _database!.execute('PRAGMA synchronous = NORMAL');
      
      // Set journal mode to WAL for better concurrency
      await _database!.execute('PRAGMA journal_mode = WAL');
      
      // Set temp store to memory
      await _database!.execute('PRAGMA temp_store = memory');
      
      // Set mmap size for better I/O performance
      await _database!.execute('PRAGMA mmap_size = 268435456'); // 256MB
      
      debugPrint('Database configured successfully');
    } catch (e) {
      debugPrint('Error configuring database: $e');
    }
  }

  // ==================== DATABASE CREATION ====================

  Future<void> _onDatabaseCreate(Database db, int version) async {
    debugPrint('Creating database tables for version $version');
    
    await _createUserTables(db);
    await _createProductTables(db);
    await _createAvatarTables(db);
    await _createAnalyticsTables(db);
    await _createSyncTables(db);
    
    // Create indexes for better query performance
    await _createIndexes(db);
    
    // Insert default data
    await _insertDefaultData(db);
  }

  Future<void> _onDatabaseUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('Upgrading database from version $oldVersion to $newVersion');
    
    final migrations = <int, List<String>>{
      2: [
        _upgradeToVersion2,
      ],
    };
    
    for (int version = oldVersion + 1; version <= newVersion; version++) {
      final migrationScripts = migrations[version];
      if (migrationScripts != null) {
        for (final script in migrationScripts) {
          await db.execute(script);
        }
      }
    }
    
    // Recreate indexes after migration
    await _createIndexes(db);
  }

  Future<void> _onDatabaseOpen(Database db) async {
    debugPrint('Database opened successfully');
  }

  // ==================== TABLE CREATION ====================

  Future<void> _createUserTables(Database db) async {
    // User profiles table
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        avatar_url TEXT,
        preferences TEXT,
        avatar_data TEXT,
        statistics TEXT,
        settings TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_active_at TEXT NOT NULL,
        is_premium INTEGER DEFAULT 0,
        subscription_tier TEXT DEFAULT 'free',
        custom_attributes TEXT
      )
    ''');

    // User preferences table (for quick access)
    await db.execute('''
      CREATE TABLE user_preferences (
        user_id TEXT PRIMARY KEY,
        theme TEXT DEFAULT 'system',
        language TEXT DEFAULT 'en',
        currency TEXT DEFAULT 'USD',
        font_size REAL DEFAULT 1.0,
        layout_preference TEXT DEFAULT 'comfortable',
        haptic_feedback INTEGER DEFAULT 1,
        sound_effects INTEGER DEFAULT 1,
        auto_play_videos INTEGER DEFAULT 1,
        high_quality_images INTEGER DEFAULT 1,
        data_saving_mode INTEGER DEFAULT 0,
        notifications TEXT,
        privacy TEXT,
        category_preferences TEXT,
        brand_preferences TEXT,
        favorite_categories TEXT,
        blocked_tags TEXT,
        size_preferences TEXT,
        last_updated TEXT NOT NULL
      )
    ''');

    // App settings table
    await db.execute('''
      CREATE TABLE app_settings (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        version TEXT DEFAULT '1.0.0',
        last_updated TEXT NOT NULL,
        configuration TEXT,
        ui_settings TEXT,
        performance_settings TEXT,
        privacy_settings TEXT,
        sync_settings TEXT,
        notification_settings TEXT,
        accessibility_settings TEXT,
        feature_flags TEXT,
        custom_settings TEXT,
        backup_history TEXT,
        is_first_launch INTEGER DEFAULT 1,
        onboarding_status TEXT DEFAULT 'not_started'
      )
    ''');
  }

  Future<void> _createProductTables(Database db) async {
    // Closet items table (user's personal items)
    await db.execute('''
      CREATE TABLE closet_items (
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
        purchase_date TEXT NOT NULL,
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
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // Saved looks table (outfit combinations)
    await db.execute('''
      CREATE TABLE saved_looks (
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
        accessories TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // Product cache table (for offline access to product data)
    await db.execute('''
      CREATE TABLE product_cache (
        id TEXT PRIMARY KEY,
        product_data TEXT NOT NULL,
        category TEXT,
        brand TEXT,
        price_range TEXT,
        created_at TEXT NOT NULL,
        last_accessed TEXT NOT NULL,
        access_count INTEGER DEFAULT 0,
        expiry_date TEXT
      )
    ''');
  }

  Future<void> _createAvatarTables(Database db) async {
    // Avatar data table
    await db.execute('''
      CREATE TABLE avatar_data (
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
        custom_data TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // Avatar measurement history table (separate for better querying)
    await db.execute('''
      CREATE TABLE avatar_measurement_history (
        id TEXT PRIMARY KEY,
        avatar_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        measurements TEXT NOT NULL,
        note TEXT,
        source TEXT DEFAULT 'manual',
        confidence REAL DEFAULT 1.0,
        FOREIGN KEY (avatar_id) REFERENCES avatar_data(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createAnalyticsTables(Database db) async {
    // User statistics table
    await db.execute('''
      CREATE TABLE user_statistics (
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
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // Activity feed table
    await db.execute('''
      CREATE TABLE activity_feed (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        timestamp TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');

    // App usage analytics table
    await db.execute('''
      CREATE TABLE app_usage_analytics (
        id TEXT PRIMARY KEY,
        user_id TEXT,
        session_id TEXT NOT NULL,
        screen_name TEXT,
        action TEXT,
        timestamp TEXT NOT NULL,
        duration INTEGER,
        metadata TEXT,
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _createSyncTables(Database db) async {
    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0,
        status TEXT DEFAULT 'pending',
        priority INTEGER DEFAULT 0
      )
    ''');

    // Data backup table
    await db.execute('''
      CREATE TABLE data_backup (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        backup_path TEXT NOT NULL,
        backup_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        size INTEGER,
        checksum TEXT,
        version TEXT,
        status TEXT DEFAULT 'active',
        FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
      )
    ''');
  }

  // ==================== INDEXES ====================

  Future<void> _createIndexes(Database db) async {
    debugPrint('Creating database indexes');
    
    // User table indexes
    await db.execute('CREATE INDEX idx_user_profiles_email ON user_profiles(email)');
    await db.execute('CREATE INDEX idx_user_profiles_last_active ON user_profiles(last_active_at)');
    
    // Closet items indexes
    await db.execute('CREATE INDEX idx_closet_items_user_id ON closet_items(user_id)');
    await db.execute('CREATE INDEX idx_closet_items_category ON closet_items(category)');
    await db.execute('CREATE INDEX idx_closet_items_brand ON closet_items(brand)');
    await db.execute('CREATE INDEX idx_closet_items_favorite ON closet_items(is_favorite)');
    await db.execute('CREATE INDEX idx_closet_items_added ON closet_items(added_to_closet)');
    await db.execute('CREATE INDEX idx_closet_items_worn ON closet_items(last_worn)');
    
    // Saved looks indexes
    await db.execute('CREATE INDEX idx_saved_looks_user_id ON saved_looks(user_id)');
    await db.execute('CREATE INDEX idx_saved_looks_style ON saved_looks(style)');
    await db.execute('CREATE INDEX idx_saved_looks_favorite ON saved_looks(is_favorite)');
    await db.execute('CREATE INDEX idx_saved_looks_created ON saved_looks(created_at)');
    await db.execute('CREATE INDEX idx_saved_looks_worn ON saved_looks(last_worn)');
    
    // Avatar data indexes
    await db.execute('CREATE INDEX idx_avatar_data_user_id ON avatar_data(user_id)');
    await db.execute('CREATE INDEX idx_avatar_data_active ON avatar_data(is_active)');
    await db.execute('CREATE INDEX idx_avatar_data_default ON avatar_data(is_default)');
    await db.execute('CREATE INDEX idx_avatar_data_used ON avatar_data(last_used)');
    
    // Activity feed indexes
    await db.execute('CREATE INDEX idx_activity_feed_user_id ON activity_feed(user_id)');
    await db.execute('CREATE INDEX idx_activity_feed_timestamp ON activity_feed(timestamp)');
    await db.execute('CREATE INDEX idx_activity_feed_type ON activity_feed(type)');
    
    // Sync queue indexes
    await db.execute('CREATE INDEX idx_sync_queue_status ON sync_queue(status)');
    await db.execute('CREATE INDEX idx_sync_queue_priority ON sync_queue(priority)');
    await db.execute('CREATE INDEX idx_sync_queue_timestamp ON sync_queue(timestamp)');
    
    // Product cache indexes
    await db.execute('CREATE INDEX idx_product_cache_category ON product_cache(category)');
    await db.execute('CREATE INDEX idx_product_cache_brand ON product_cache(brand)');
    await db.execute('CREATE INDEX idx_product_cache_accessed ON product_cache(last_accessed)');
    await db.execute('CREATE INDEX idx_product_cache_expiry ON product_cache(expiry_date)');
    
    // Analytics indexes
    await db.execute('CREATE INDEX idx_user_statistics_tier ON user_statistics(loyalty_tier)');
    await db.execute('CREATE INDEX idx_app_usage_user ON app_usage_analytics(user_id)');
    await db.execute('CREATE INDEX idx_app_usage_session ON app_usage_analytics(session_id)');
    await db.execute('CREATE INDEX idx_app_usage_timestamp ON app_usage_analytics(timestamp)');
    
    debugPrint('Database indexes created successfully');
  }

  // ==================== MIGRATION SCRIPTS ====================

  String get _upgradeToVersion2 => '''
    -- Add new columns for enhanced functionality
    ALTER TABLE closet_items ADD COLUMN sustainability_score REAL DEFAULT 0.0;
    ALTER TABLE closet_items ADD COLUMN ethical_rating TEXT;
    ALTER TABLE saved_looks ADD COLUMN seasonal_appropriateness TEXT;
    ALTER TABLE saved_looks ADD COLUMN weather_compatibility TEXT;
    
    -- Create new tables for enhanced features
    CREATE TABLE IF NOT EXISTS style_preferences (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      style_types TEXT,
      color_palettes TEXT,
      pattern_preferences TEXT,
      fabric_preferences TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
    );
    
    CREATE TABLE IF NOT EXISTS recommendation_history (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      recommendation_type TEXT NOT NULL,
      item_id TEXT,
      item_data TEXT,
      feedback TEXT,
      created_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES user_profiles(id) ON DELETE CASCADE
    );
    
    -- Create new indexes for improved performance
    CREATE INDEX IF NOT EXISTS idx_style_preferences_user_id ON style_preferences(user_id);
    CREATE INDEX IF NOT EXISTS idx_recommendation_history_user_id ON recommendation_history(user_id);
    CREATE INDEX IF NOT EXISTS idx_recommendation_history_type ON recommendation_history(recommendation_type);
  ''';

  // ==================== DEFAULT DATA ====================

  Future<void> _insertDefaultData(Database db) async {
    debugPrint('Inserting default data');
    
    // Insert default style preferences
    await db.insert('style_preferences', {
      'id': 'default_styles',
      'user_id': 'default',
      'style_types': jsonEncode(['casual', 'professional', 'athletic']),
      'color_palettes': jsonEncode(['neutrals', 'earth_tones', 'classic_colors']),
      'pattern_preferences': jsonEncode(['solid', 'subtle_patterns']),
      'fabric_preferences': jsonEncode(['cotton', 'blends', 'natural_fibers']),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
    
    debugPrint('Default data inserted successfully');
  }

  // ==================== DATABASE OPERATIONS ====================

  /// Get the database instance
  Database? get database => _database;

  /// Check if database is initialized
  bool get isInitialized => _isInitialized;

  /// Get database file size
  Future<int> getDatabaseSize() async {
    if (_databasePath == null) return 0;
    
    final file = File(_databasePath!);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    if (_database == null) {
      return {'error': 'Database not initialized'};
    }

    final info = <String, dynamic>{};
    
    try {
      // Get database version
      final version = await _database!.getVersion();
      info['version'] = version;
      
      // Get table info
      final tables = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      info['table_count'] = tables.length;
      info['tables'] = tables.map((table) => table['name']).toList();
      
      // Get database size
      info['size_bytes'] = await getDatabaseSize();
      info['size_mb'] = (info['size_bytes'] as int) / (1024 * 1024);
      
      // Get page count and page size
      final pageCount = await _database!.rawQuery('PRAGMA page_count');
      final pageSize = await _database!.rawQuery('PRAGMA page_size');
      info['page_count'] = pageCount.first['page_count'];
      info['page_size'] = pageSize.first['page_size'];
      
      // Get WAL mode status
      final walMode = await _database!.rawQuery('PRAGMA journal_mode');
      info['journal_mode'] = walMode.first['journal_mode'];
      
    } catch (e) {
      info['error'] = e.toString();
    }
    
    return info;
  }

  /// Optimize database performance
  Future<void> optimizeDatabase() async {
    if (_database == null) return;

    try {
      debugPrint('Optimizing database performance');
      
      // Analyze query patterns for optimization
      await _database!.execute('ANALYZE');
      
      // Vacuum to reclaim space
      await _database!.execute('VACUUM');
      
      // Reindex for better performance
      await _database!.execute('REINDEX');
      
      debugPrint('Database optimization completed');
    } catch (e) {
      debugPrint('Error optimizing database: $e');
    }
  }

  /// Clean up expired data
  Future<int> cleanupExpiredData() async {
    if (_database == null) return 0;

    int cleanedCount = 0;
    final now = DateTime.now().toIso8601String();

    try {
      // Clean up expired product cache
      final cacheResult = await _database!.delete(
        'product_cache',
        where: 'expiry_date < ?',
        whereArgs: [now],
      );
      cleanedCount += cacheResult;

      // Clean up old activity feed items (keep last 1000 per user)
      final users = await _database!.rawQuery('SELECT DISTINCT user_id FROM activity_feed');
      for (final user in users) {
        final userId = user['user_id'] as String;
        await _database!.execute('''
          DELETE FROM activity_feed 
          WHERE id IN (
            SELECT id FROM activity_feed 
            WHERE user_id = ? 
            ORDER BY timestamp DESC 
            LIMIT -1 OFFSET 1000
          )
        ''', [userId]);
      }

      debugPrint('Cleaned up $cleanedCount expired records');
    } catch (e) {
      debugPrint('Error cleaning up expired data: $e');
    }

    return cleanedCount;
  }

  /// Backup database to external location
  Future<String?> backupDatabase(String backupPath) async {
    if (_databasePath == null) return null;

    try {
      final source = File(_databasePath!);
      if (!await source.exists()) return null;

      await source.copy(backupPath);
      debugPrint('Database backed up to: $backupPath');
      
      return backupPath;
    } catch (e) {
      debugPrint('Error backing up database: $e');
      return null;
    }
  }

  /// Restore database from backup
  Future<bool> restoreDatabase(String backupPath) async {
    if (_databasePath == null) return false;

    try {
      // Close current database
      await _database?.close();
      
      // Restore from backup
      final backup = File(backupPath);
      if (await backup.exists()) {
        await backup.copy(_databasePath!);
        
        // Reinitialize database
        await initialize();
        
        debugPrint('Database restored from: $backupPath');
        return true;
      }
    } catch (e) {
      debugPrint('Error restoring database: $e');
    }

    return false;
  }

  /// Execute custom SQL query safely
  Future<List<Map<String, dynamic>>> executeQuery(String sql, [List<dynamic>? arguments]) async {
    if (_database == null) throw Exception('Database not initialized');
    
    try {
      return await _database!.rawQuery(sql, arguments);
    } catch (e) {
      debugPrint('Error executing query: $e');
      rethrow;
    }
  }

  /// Execute custom SQL command safely
  Future<int> executeCommand(String sql, [List<dynamic>? arguments]) async {
    if (_database == null) throw Exception('Database not initialized');
    
    try {
      return await _database!.rawExecute(sql, arguments);
    } catch (e) {
      debugPrint('Error executing command: $e');
      rethrow;
    }
  }

  // ==================== DISPOSAL ====================

  Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    _isInitialized = false;
    _databasePath = null;
    debugPrint('DatabaseService disposed');
  }
}