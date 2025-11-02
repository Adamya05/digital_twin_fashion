/// Data Backup and Restore Service
/// 
/// Handles comprehensive data backup, restore, and cross-session recovery
/// for all app data including preferences, saved items, and user data.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';

import 'data_service.dart';
import 'user_preferences_service.dart';
import '../models/user_profile_model.dart';
import '../models/app_settings_model.dart';

class DataBackupService {
  static DataBackupService? _instance;
  static DataBackupService get instance => _instance ??= DataBackupService._();

  DataBackupService._();

  final DataService _dataService = DataService.instance;
  final UserPreferencesService _preferencesService = UserPreferencesService.instance;

  // Backup file naming
  static const String _backupPrefix = 'fashion_app_backup';
  static const String _backupExtension = '.fab'; // Fashion App Backup
  static const String _tempBackupDir = 'temp_backups';

  // Maximum backup size (50MB)
  static const int _maxBackupSize = 50 * 1024 * 1024;

  // ==================== BACKUP CREATION ====================

  /// Create a complete backup of all user data
  Future<BackupResult> createBackup(String userId, {String? customName}) async {
    try {
      await _dataService.initialize();
      await _preferencesService.initialize();

      debugPrint('Starting data backup for user: $userId');

      // Create backup metadata
      final backupMetadata = BackupMetadata(
        userId: userId,
        timestamp: DateTime.now(),
        version: await _getAppVersion(),
        backupType: BackupType.full,
        dataVersion: 1,
      );

      // Export all user data
      final userData = await _dataService.exportUserData(userId);
      
      // Export preferences
      final preferencesData = _preferencesService.exportPreferences();
      
      // Create backup package
      final backupPackage = BackupPackage(
        metadata: backupMetadata,
        userData: userData,
        preferencesData: preferencesData,
      );

      // Generate backup filename
      final backupName = customName ?? _generateBackupName(userId);
      final backupPath = await _saveBackup(backupPackage, backupName);

      // Verify backup integrity
      final isValid = await _verifyBackup(backupPath);
      if (!isValid) {
        throw Exception('Backup verification failed');
      }

      final backupInfo = BackupInfo(
        path: backupPath,
        name: backupName,
        size: await _getFileSize(backupPath),
        createdAt: backupMetadata.timestamp,
        type: backupType.full,
      );

      debugPrint('Backup created successfully: $backupName');
      return BackupResult.success(backupInfo);

    } catch (e) {
      debugPrint('Error creating backup: $e');
      return BackupResult.error(e.toString());
    }
  }

  /// Create an incremental backup (only changes since last backup)
  Future<BackupResult> createIncrementalBackup(String userId) async {
    try {
      await _dataService.initialize();

      final lastBackup = await getLastBackup(userId);
      final lastBackupTime = lastBackup?.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

      // Only backup data modified since last backup
      final userData = await _dataService.exportUserData(userId);
      
      // Filter data by modification time
      final filteredData = _filterDataByTimestamp(userData, lastBackupTime);
      
      if (filteredData.isEmpty) {
        return BackupResult.info('No changes since last backup');
      }

      final backupMetadata = BackupMetadata(
        userId: userId,
        timestamp: DateTime.now(),
        version: await _getAppVersion(),
        backupType: BackupType.incremental,
        dataVersion: 1,
        previousBackup: lastBackup?.path,
      );

      final preferencesData = _preferencesService.exportPreferences();
      
      final backupPackage = BackupPackage(
        metadata: backupMetadata,
        userData: filteredData,
        preferencesData: preferencesData,
      );

      final backupName = _generateIncrementalBackupName(userId);
      final backupPath = await _saveBackup(backupPackage, backupName);

      final backupInfo = BackupInfo(
        path: backupPath,
        name: backupName,
        size: await _getFileSize(backupPath),
        createdAt: backupMetadata.timestamp,
        type: backupType.incremental,
      );

      debugPrint('Incremental backup created successfully');
      return BackupResult.success(backupInfo);

    } catch (e) {
      debugPrint('Error creating incremental backup: $e');
      return BackupResult.error(e.toString());
    }
  }

  // ==================== BACKUP RESTORATION ====================

  /// Restore data from backup
  Future<RestoreResult> restoreBackup(String backupPath, String userId) async {
    try {
      await _dataService.initialize();

      debugPrint('Starting data restoration from: $backupPath');

      // Load and verify backup
      final backupPackage = await _loadBackup(backupPath);
      if (backupPackage == null) {
        return RestoreResult.error('Invalid or corrupted backup file');
      }

      // Verify backup compatibility
      final compatibilityResult = await _verifyCompatibility(backupPackage);
      if (!compatibilityResult.compatible) {
        return RestoreResult.error(compatibilityResult.reason ?? 'Incompatible backup version');
      }

      // Create restore point before restoration
      final restorePoint = await _createRestorePoint(userId);
      
      try {
        // Clear existing data
        await _dataService.clearAllData(userId);
        
        // Restore user data
        if (backupPackage.userData != null) {
          await _dataService.importUserData(userId, backupPackage.userData!);
        }
        
        // Restore preferences
        if (backupPackage.preferencesData != null) {
          await _preferencesService.importPreferences(backupPackage.preferencesData!);
        }

        // Mark backup as used
        await _markBackupAsUsed(backupPath);

        debugPrint('Data restoration completed successfully');
        return RestoreResult.success(restorePoint);

      } catch (e) {
        // Restore from restore point if restoration fails
        debugPrint('Restoration failed, creating rollback: $e');
        await _restoreFromRestorePoint(restorePoint, userId);
        return RestoreResult.error('Restoration failed: $e');
      }

    } catch (e) {
      debugPrint('Error restoring backup: $e');
      return RestoreResult.error(e.toString());
    }
  }

  /// Restore only preferences from backup
  Future<RestoreResult> restorePreferences(String backupPath) async {
    try {
      final backupPackage = await _loadBackup(backupPath);
      if (backupPackage?.preferencesData == null) {
        return RestoreResult.error('No preferences data found in backup');
      }

      await _preferencesService.importPreferences(backupPackage.preferencesData!);
      
      debugPrint('Preferences restored successfully');
      return RestoreResult.success(null);

    } catch (e) {
      debugPrint('Error restoring preferences: $e');
      return RestoreResult.error(e.toString());
    }
  }

  // ==================== BACKUP MANAGEMENT ====================

  /// Get all available backups
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final directory = await _getBackupDirectory();
      final files = await directory.list().toList();
      
      final backups = <BackupInfo>[];
      
      for (final file in files) {
        if (file is File && file.path.endsWith(_backupExtension)) {
          final backupInfo = await _analyzeBackupFile(file.path);
          if (backupInfo != null) {
            backups.add(backupInfo);
          }
        }
      }
      
      // Sort by creation date (newest first)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return backups;
    } catch (e) {
      debugPrint('Error getting available backups: $e');
      return [];
    }
  }

  /// Get last backup for user
  Future<BackupInfo?> getLastBackup(String userId) async {
    final allBackups = await getAvailableBackups();
    return allBackups.where((backup) => backup.userId == userId).firstOrNull;
  }

  /// Delete backup file
  Future<bool> deleteBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Backup deleted: $backupPath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting backup: $e');
      return false;
    }
  }

  /// Clean up old backups (keep last 10)
  Future<int> cleanupOldBackups(String userId) async {
    final backups = await getAvailableBackups();
    final userBackups = backups.where((backup) => backup.userId == userId).toList();
    
    if (userBackups.length <= 10) return 0;
    
    final toDelete = userBackups.skip(10).toList();
    int deletedCount = 0;
    
    for (final backup in toDelete) {
      if (await deleteBackup(backup.path)) {
        deletedCount++;
      }
    }
    
    debugPrint('Cleaned up $deletedCount old backups');
    return deletedCount;
  }

  // ==================== CROSS-SESSION RECOVERY ====================

  /// Check if data recovery is needed on app start
  Future<RecoveryCheckResult> checkRecoveryStatus() async {
    try {
      await _dataService.initialize();
      await _preferencesService.initialize();

      final userProfile = await _dataService.getUserProfile('current_user');
      final appSettings = await _dataService.getAppSettings('current_user');
      final closetItems = await _dataService.getClosetItems('current_user');
      final savedLooks = await _dataService.getSavedLooks('current_user');

      final needsRecovery = userProfile == null && 
                           closetItems.isEmpty && 
                           savedLooks.isEmpty &&
                           _preferencesService.wasRecentlyUsed;

      final recoverySuggestions = <String>[];
      
      if (needsRecovery) {
        final lastBackup = await getLastBackup('current_user');
        if (lastBackup != null) {
          recoverySuggestions.add('Restore from backup created on ${_formatDate(lastBackup.createdAt)}');
        }
        recoverySuggestions.add('Start fresh with default settings');
        recoverySuggestions.add('Re-import data from external source');
      }

      return RecoveryCheckResult(
        needsRecovery: needsRecovery,
        hasData: userProfile != null || closetItems.isNotEmpty || savedLooks.isNotEmpty,
        lastBackup: lastBackup,
        suggestions: recoverySuggestions,
      );

    } catch (e) {
      debugPrint('Error checking recovery status: $e');
      return RecoveryCheckResult(needsRecovery: false, hasData: false);
    }
  }

  /// Auto-recover data if possible and user consented
  Future<AutoRecoveryResult> autoRecoverIfPossible() async {
    try {
      final recoveryCheck = await checkRecoveryStatus();
      
      if (!recoveryCheck.needsRecovery || recoveryCheck.lastBackup == null) {
        return AutoRecoveryResult.noActionNeeded();
      }

      // Auto-recovery would require user consent in a real implementation
      // For now, we'll just return the suggestion
      return AutoRecoveryResult.suggested(
        recoveryCheck.lastBackup!,
        'Auto-recovery available from backup created on ${_formatDate(recoveryCheck.lastBackup!.createdAt)}',
      );

    } catch (e) {
      debugPrint('Error in auto-recovery: $e');
      return AutoRecoveryResult.failed(e.toString());
    }
  }

  // ==================== UTILITY METHODS ====================

  String _generateBackupName(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${_backupPrefix}_${userId}_$timestamp$_backupExtension';
  }

  String _generateIncrementalBackupName(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${_backupPrefix}_inc_${userId}_$timestamp$_backupExtension';
  }

  Future<String> _getAppVersion() async {
    // In a real app, you would get this from package_info
    return '1.0.0';
  }

  Future<Directory> _getBackupDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${directory.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  Future<Directory> _getTempDirectory() async {
    final directory = await getTemporaryDirectory();
    final tempDir = Directory('${directory.path}/$_tempBackupDir');
    
    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    
    return tempDir;
  }

  Map<String, dynamic> _filterDataByTimestamp(Map<String, dynamic> data, DateTime since) {
    // Filter data based on modification timestamps
    // This is a simplified implementation
    return data;
  }

  Future<String> _saveBackup(BackupPackage backup, String backupName) async {
    final backupDir = await _getBackupDirectory();
    final backupPath = '${backupDir.path}/$backupName';
    
    // Serialize backup to JSON
    final backupJson = jsonEncode(backup.toJson());
    
    // Compress the JSON data
    final jsonBytes = utf8.encode(backupJson);
    final compressed = gzip.encode(jsonBytes);
    
    // Write to file
    final file = File(backupPath);
    await file.writeAsBytes(compressed);
    
    return backupPath;
  }

  Future<BackupPackage?> _loadBackup(String backupPath) async {
    try {
      final file = File(backupPath);
      if (!await file.exists()) return null;
      
      // Read compressed data
      final compressed = await file.readAsBytes();
      final jsonBytes = gzip.decode(compressed);
      final backupJson = utf8.decode(jsonBytes);
      
      // Parse JSON
      final backupData = jsonDecode(backupJson);
      return BackupPackage.fromJson(backupData);
      
    } catch (e) {
      debugPrint('Error loading backup: $e');
      return null;
    }
  }

  Future<bool> _verifyBackup(String backupPath) async {
    try {
      final backup = await _loadBackup(backupPath);
      return backup != null && backup.metadata.userId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<BackupInfo?> _analyzeBackupFile(String backupPath) async {
    try {
      final backup = await _loadBackup(backupPath);
      if (backup == null) return null;
      
      final file = File(backupPath);
      return BackupInfo(
        path: backupPath,
        name: Uri.file(backupPath).pathSegments.last,
        size: await file.length(),
        createdAt: backup.metadata.timestamp,
        type: backup.metadata.backupType,
        userId: backup.metadata.userId,
        version: backup.metadata.version,
      );
    } catch (e) {
      return null;
    }
  }

  Future<CompatibilityResult> _verifyCompatibility(BackupPackage backup) async {
    // Check version compatibility
    final currentVersion = await _getAppVersion();
    if (backup.metadata.version != currentVersion) {
      return CompatibilityResult(
        compatible: true, // Allow restoration with version warning
        reason: 'Version mismatch: ${backup.metadata.version} vs $currentVersion',
      );
    }
    
    return CompatibilityResult(compatible: true);
  }

  Future<String> _createRestorePoint(String userId) async {
    // Create a temporary backup before restoration
    final tempBackup = await createBackup(userId, customName: 'restore_point_${DateTime.now().millisecondsSinceEpoch}');
    
    if (tempBackup is BackupResultSuccess) {
      return tempBackup.backupInfo.path;
    }
    
    throw Exception('Failed to create restore point');
  }

  Future<void> _restoreFromRestorePoint(String restorePointPath, String userId) async {
    await restoreBackup(restorePointPath, userId);
  }

  Future<void> _markBackupAsUsed(String backupPath) async {
    // Mark backup as used (could be stored in SharedPreferences)
    // This is a placeholder implementation
  }

  Future<int> _getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}

// ==================== DATA CLASSES ====================

enum BackupType { full, incremental, preferences }

class BackupMetadata {
  final String userId;
  final DateTime timestamp;
  final String version;
  final BackupType backupType;
  final int dataVersion;
  final String? previousBackup;

  const BackupMetadata({
    required this.userId,
    required this.timestamp,
    required this.version,
    required this.backupType,
    this.dataVersion = 1,
    this.previousBackup,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'timestamp': timestamp.toIso8601String(),
    'version': version,
    'backupType': backupType.name,
    'dataVersion': dataVersion,
    'previousBackup': previousBackup,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => BackupMetadata(
    userId: json['userId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    version: json['version'] as String,
    backupType: BackupType.values.firstWhere(
      (e) => e.name == json['backupType'],
      orElse: () => BackupType.full,
    ),
    dataVersion: json['dataVersion'] as int? ?? 1,
    previousBackup: json['previousBackup'] as String?,
  );
}

class BackupPackage {
  final BackupMetadata metadata;
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? preferencesData;

  const BackupPackage({
    required this.metadata,
    required this.userData,
    required this.preferencesData,
  });

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'userData': userData,
    'preferencesData': preferencesData,
  };

  factory BackupPackage.fromJson(Map<String, dynamic> json) => BackupPackage(
    metadata: BackupMetadata.fromJson(json['metadata']),
    userData: json['userData'] as Map<String, dynamic>?,
    preferencesData: json['preferencesData'] as Map<String, dynamic>?,
  );
}

class BackupInfo {
  final String path;
  final String name;
  final int size;
  final DateTime createdAt;
  final BackupType type;
  final String userId;
  final String version;

  const BackupInfo({
    required this.path,
    required this.name,
    required this.size,
    required this.createdAt,
    required this.type,
    this.userId = '',
    this.version = '',
  });
}

// ==================== RESULT CLASSES ====================

class BackupResult {
  final bool success;
  final String? error;
  final BackupInfo? backupInfo;

  const BackupResult._(this.success, this.error, this.backupInfo);

  factory BackupResult.success(BackupInfo backupInfo) => BackupResult._(true, null, backupInfo);
  factory BackupResult.error(String error) => BackupResult._(false, error, null);
  factory BackupResult.info(String message) => BackupResult._(true, message, null);
}

class RestoreResult {
  final bool success;
  final String? error;
  final String? restorePointPath;

  const RestoreResult._(this.success, this.error, this.restorePointPath);

  factory RestoreResult.success(String? restorePointPath) => RestoreResult._(true, null, restorePointPath);
  factory RestoreResult.error(String error) => RestoreResult._(false, error, null);
}

class RecoveryCheckResult {
  final bool needsRecovery;
  final bool hasData;
  final BackupInfo? lastBackup;
  final List<String> suggestions;

  const RecoveryCheckResult({
    required this.needsRecovery,
    required this.hasData,
    this.lastBackup,
    required this.suggestions,
  });
}

class AutoRecoveryResult {
  final AutoRecoveryStatus status;
  final String? message;
  final BackupInfo? suggestedBackup;

  const AutoRecoveryResult._(this.status, this.message, this.suggestedBackup);

  factory AutoRecoveryResult.noActionNeeded() => AutoRecoveryResult._(
    AutoRecoveryStatus.noActionNeeded,
    null,
    null,
  );

  factory AutoRecoveryResult.suggested(BackupInfo backup, String message) => AutoRecoveryResult._(
    AutoRecoveryStatus.suggested,
    message,
    backup,
  );

  factory AutoRecoveryResult.failed(String error) => AutoRecoveryResult._(
    AutoRecoveryStatus.failed,
    error,
    null,
  );
}

enum AutoRecoveryStatus {
  noActionNeeded,
  suggested,
  failed,
}

class CompatibilityResult {
  final bool compatible;
  final String? reason;

  const CompatibilityResult({
    required this.compatible,
    this.reason,
  });
}

// ==================== EXTENSIONS ====================

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}