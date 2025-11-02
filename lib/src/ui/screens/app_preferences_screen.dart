/// App Preferences Screen
/// 
/// Comprehensive app preferences and customization interface:
/// - Theme and appearance settings
/// - Language and localization options
/// - Currency and regional settings
/// - Storage management and cache control
/// - Performance and accessibility settings
/// - Feature flags and beta options
/// - Auto-update and download preferences
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';

/// App preferences data model
class AppPreferences {
  final String themeMode;
  final String language;
  final String currency;
  final String region;
  final bool autoUpdate;
  final bool autoDownload;
  final bool dataSaver;
  final bool reduceAnimations;
  final bool highContrast;
  final double fontScale;
  final bool screenReader;
  final bool hapticFeedback;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> customSettings;

  const AppPreferences({
    this.themeMode = 'system',
    this.language = 'en',
    this.currency = 'INR',
    this.region = 'IN',
    this.autoUpdate = true,
    this.autoDownload = true,
    this.dataSaver = false,
    this.reduceAnimations = false,
    this.highContrast = false,
    this.fontScale = 1.0,
    this.screenReader = false,
    this.hapticFeedback = true,
    this.featureFlags = const {},
    this.customSettings = const {},
  });

  AppPreferences copyWith({
    String? themeMode,
    String? language,
    String? currency,
    String? region,
    bool? autoUpdate,
    bool? autoDownload,
    bool? dataSaver,
    bool? reduceAnimations,
    bool? highContrast,
    double? fontScale,
    bool? screenReader,
    bool? hapticFeedback,
    Map<String, bool>? featureFlags,
    Map<String, dynamic>? customSettings,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      currency: currency ?? this.currency,
      region: region ?? this.region,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      autoDownload: autoDownload ?? this.autoDownload,
      dataSaver: dataSaver ?? this.dataSaver,
      reduceAnimations: reduceAnimations ?? this.reduceAnimations,
      highContrast: highContrast ?? this.highContrast,
      fontScale: fontScale ?? this.fontScale,
      screenReader: screenReader ?? this.screenReader,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      featureFlags: featureFlags ?? this.featureFlags,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

/// Language option model
class LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final bool isRTL;
  final bool isPopular;

  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    this.isRTL = false,
    this.isPopular = false,
  });
}

/// Currency option model
class CurrencyOption {
  final String code;
  final String name;
  final String symbol;
  final String country;

  const CurrencyOption({
    required this.code,
    required this.name,
    required this.symbol,
    required this.country,
  });
}

class AppPreferencesScreen extends ConsumerStatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  ConsumerState<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends ConsumerState<AppPreferencesScreen> {
  AppPreferences _preferences = const AppPreferences();
  bool _isLoading = true;
  double _storageUsed = 0;
  double _storageTotal = 1000; // MB

  @override
  void initState() {
    super.initState();
    _loadAppPreferences();
    _calculateStorageUsage();
  }

  Future<void> _loadAppPreferences() async {
    // Mock data - in real app, this would fetch from API/shared preferences
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _preferences = const AppPreferences(
        themeMode: 'light',
        language: 'en',
        currency: 'INR',
        region: 'IN',
        autoUpdate: true,
        autoDownload: true,
        dataSaver: false,
        reduceAnimations: false,
        highContrast: false,
        fontScale: 1.0,
        screenReader: false,
        hapticFeedback: true,
        featureFlags: {
          'new_ui': true,
          'beta_features': false,
          'advanced_analytics': false,
          'experimental_camera': false,
        },
      );
      _isLoading = false;
    });
  }

  Future<void> _calculateStorageUsage() async {
    // Mock storage calculation - in real app, this would scan actual files
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _storageUsed = 156.7; // MB
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('App Preferences'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Preferences'),
        actions: [
          IconButton(
            onPressed: _showPreferencesGuide,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Preferences Guide',
          ),
          IconButton(
            onPressed: _exportPreferences,
            icon: const Icon(Icons.download),
            tooltip: 'Export Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance Section
            _buildAppearanceSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Language & Region Section
            _buildLanguageRegionSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Storage & Data Section
            _buildStorageDataSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Performance Section
            _buildPerformanceSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Accessibility Section
            _buildAccessibilitySection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Feature Flags Section
            _buildFeatureFlagsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Advanced Settings Section
            _buildAdvancedSettingsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(
          icon,
          color: color ?? AppTheme.primaryGreen,
          size: 20,
        ),
        const SizedBox(width: AppTheme.spacingS),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Theme & Appearance', Icons.palette),
            const SizedBox(height: AppTheme.spacingM),
            
            // Theme Mode
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Theme Mode'),
              subtitle: const Text('Choose how the app looks'),
              trailing: DropdownButton<String>(
                value: _preferences.themeMode,
                items: const [
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'system', child: Text('System')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = _preferences.copyWith(themeMode: value);
                    });
                  }
                },
              ),
            ),
            const Divider(height: 1),
            
            // Color Scheme Preview
            ListTile(
              leading: const Icon(Icons.color_lens),
              title: const Text('Color Scheme'),
              subtitle: const Text('Primary Green'),
              trailing: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
              onTap: _showColorSchemeOptions,
            ),
            const Divider(height: 1),
            
            // Font Size
            ListTile(
              leading: const Icon(Icons.text_fields),
              title: const Text('Font Size'),
              subtitle: Text(_getFontSizeLabel(_preferences.fontScale)),
              trailing: Slider(
                value: _preferences.fontScale,
                min: 0.8,
                max: 1.4,
                divisions: 6,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences.copyWith(fontScale: value);
                  });
                },
              ),
            ),
            const Divider(height: 1),
            
            // Card Density
            ListTile(
              leading: const Icon(Icons.view_stream),
              title: const Text('Card Density'),
              subtitle: const Text('Normal spacing'),
              trailing: DropdownButton<String>(
                value: 'normal',
                items: const [
                  DropdownMenuItem(value: 'compact', child: Text('Compact')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  DropdownMenuItem(value: 'spacious', child: Text('Spacious')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageRegionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Language & Region', Icons.language),
            const SizedBox(height: AppTheme.spacingM),
            
            // Language
            ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showLanguageSelector,
            ),
            const Divider(height: 1),
            
            // Currency
            ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text('Currency'),
              subtitle: const Text('Indian Rupee (INR)'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showCurrencySelector,
            ),
            const Divider(height: 1),
            
            // Region
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Region'),
              subtitle: const Text('India'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showRegionSelector,
            ),
            const Divider(height: 1),
            
            // Date Format
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date Format'),
              subtitle: const Text('DD/MM/YYYY'),
              trailing: DropdownButton<String>(
                value: 'dd/mm/yyyy',
                items: const [
                  DropdownMenuItem(value: 'dd/mm/yyyy', child: Text('DD/MM/YYYY')),
                  DropdownMenuItem(value: 'mm/dd/yyyy', child: Text('MM/DD/YYYY')),
                  DropdownMenuItem(value: 'yyyy-mm-dd', child: Text('YYYY-MM-DD')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageDataSection() {
    final storagePercentage = (_storageUsed / _storageTotal * 100);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Storage & Data', Icons.storage),
            const SizedBox(height: AppTheme.spacingM),
            
            // Storage Usage
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Storage Used'),
                      Text(
                        '${_storageUsed.toStringAsFixed(1)} MB of ${_storageTotal} MB',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  LinearProgressIndicator(
                    value: storagePercentage / 100,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      storagePercentage > 80 ? Colors.red : AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '${storagePercentage.toStringAsFixed(1)}% used',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Cache Management
            ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Clear Cache'),
              subtitle: const Text('Remove temporary files'),
              trailing: ElevatedButton(
                onPressed: _clearCache,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear'),
              ),
            ),
            const Divider(height: 1),
            
            // Downloaded Content
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Manage Downloads'),
              subtitle: const Text('View and delete downloaded content'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _manageDownloads,
            ),
            const Divider(height: 1),
            
            // Offline Data
            SwitchListTile(
              title: const Text('Offline Mode'),
              subtitle: const Text('Save content for offline use'),
              value: _preferences.customSettings['offline_mode'] ?? false,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    customSettings: {..._preferences.customSettings, 'offline_mode': enabled},
                  );
                });
              },
              secondary: const Icon(Icons.wifi_off),
            ),
            const Divider(height: 1),
            
            // Data Saver
            SwitchListTile(
              title: const Text('Data Saver'),
              subtitle: const Text('Reduce data usage'),
              value: _preferences.dataSaver,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(dataSaver: enabled);
                });
              },
              secondary: const Icon(Icons.data_usage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Performance', Icons.speed),
            const SizedBox(height: AppTheme.spacingM),
            
            // Auto Update
            SwitchListTile(
              title: const Text('Auto Update'),
              subtitle: const Text('Automatically download app updates'),
              value: _preferences.autoUpdate,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(autoUpdate: enabled);
                });
              },
              secondary: const Icon(Icons.system_update),
            ),
            const Divider(height: 1),
            
            // Auto Download
            SwitchListTile(
              title: const Text('Auto Download'),
              subtitle: const Text('Download content automatically'),
              value: _preferences.autoDownload,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(autoDownload: enabled);
                });
              },
              secondary: const Icon(Icons.download),
            ),
            const Divider(height: 1),
            
            // Reduce Animations
            SwitchListTile(
              title: const Text('Reduce Animations'),
              subtitle: const Text('Minimize motion for better performance'),
              value: _preferences.reduceAnimations,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(reduceAnimations: enabled);
                });
              },
              secondary: const Icon(Icons.animation),
            ),
            const Divider(height: 1),
            
            // Low Power Mode
            SwitchListTile(
              title: const Text('Low Power Mode'),
              subtitle: const Text('Optimize for battery life'),
              value: _preferences.customSettings['low_power_mode'] ?? false,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    customSettings: {..._preferences.customSettings, 'low_power_mode': enabled},
                  );
                });
              },
              secondary: const Icon(Icons.battery_alert),
            ),
            const Divider(height: 1),
            
            // Background Sync
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Background Sync'),
              subtitle: const Text('Sync data in background'),
              trailing: Switch(
                value: _preferences.customSettings['background_sync'] ?? true,
                onChanged: (enabled) {
                  setState(() {
                    _preferences = _preferences.copyWith(
                      customSettings: {..._preferences.customSettings, 'background_sync': enabled},
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Accessibility', Icons.accessibility),
            const SizedBox(height: AppTheme.spacingM),
            
            // Screen Reader Support
            SwitchListTile(
              title: const Text('Screen Reader Support'),
              subtitle: const Text('Enable for assistive technology'),
              value: _preferences.screenReader,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(screenReader: enabled);
                });
              },
              secondary: const Icon(Icons.screen_reader_passed),
            ),
            const Divider(height: 1),
            
            // High Contrast
            SwitchListTile(
              title: const Text('High Contrast'),
              subtitle: const Text('Increase contrast for better visibility'),
              value: _preferences.highContrast,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(highContrast: enabled);
                });
              },
              secondary: const Icon(Icons.contrast),
            ),
            const Divider(height: 1),
            
            // Haptic Feedback
            SwitchListTile(
              title: const Text('Haptic Feedback'),
              subtitle: const Text('Vibration for interactions'),
              value: _preferences.hapticFeedback,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(hapticFeedback: enabled);
                });
              },
              secondary: const Icon(Icons.vibration),
            ),
            const Divider(height: 1),
            
            // Voice Instructions
            SwitchListTile(
              title: const Text('Voice Instructions'),
              subtitle: const Text('Audio guidance for actions'),
              value: _preferences.customSettings['voice_instructions'] ?? false,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    customSettings: {..._preferences.customSettings, 'voice_instructions': enabled},
                  );
                });
              },
              secondary: const Icon(Icons.record_voice_over),
            ),
            const Divider(height: 1),
            
            // Color Blind Support
            ListTile(
              leading: const Icon(Icons.colorize),
              title: const Text('Color Blind Support'),
              subtitle: const Text('Optimize colors for color blindness'),
              trailing: DropdownButton<String>(
                value: 'none',
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'protanopia', child: Text('Protanopia')),
                  DropdownMenuItem(value: 'deuteranopia', child: Text('Deuteranopia')),
                  DropdownMenuItem(value: 'tritanopia', child: Text('Tritanopia')),
                ],
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Beta Features', Icons.explore),
            const SizedBox(height: AppTheme.spacingM),
            
            // Warning
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Beta features may be unstable and are for testing purposes only.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Feature Flags
            _buildFeatureFlag('new_ui', 'New User Interface', 'Try the updated UI design', true),
            const Divider(height: 1),
            _buildFeatureFlag('beta_features', 'Beta Features', 'Enable experimental features', false),
            const Divider(height: 1),
            _buildFeatureFlag('advanced_analytics', 'Advanced Analytics', 'Detailed usage analytics', false),
            const Divider(height: 1),
            _buildFeatureFlag('experimental_camera', 'Experimental Camera', 'New camera capabilities', false),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureFlag(String key, String title, String description, bool defaultValue) {
    final isEnabled = _preferences.featureFlags[key] ?? defaultValue;
    
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(description),
      value: isEnabled,
      onChanged: (enabled) {
        setState(() {
          _preferences = _preferences.copyWith(
            featureFlags: {..._preferences.featureFlags, key: enabled},
          );
        });
      },
    );
  }

  Widget _buildAdvancedSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Advanced Settings', Icons.code),
            const SizedBox(height: AppTheme.spacingM),
            
            // Developer Mode
            SwitchListTile(
              title: const Text('Developer Mode'),
              subtitle: const Text('Enable advanced debugging options'),
              value: _preferences.customSettings['developer_mode'] ?? false,
              onChanged: (enabled) {
                setState(() {
                  _preferences = _preferences.copyWith(
                    customSettings: {..._preferences.customSettings, 'developer_mode': enabled},
                  );
                });
              },
              secondary: const Icon(Icons.developer_mode),
            ),
            const Divider(height: 1),
            
            // Debug Logs
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Debug Logs'),
              subtitle: const Text('Generate debug report'),
              trailing: ElevatedButton(
                onPressed: _generateDebugLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Generate'),
              ),
            ),
            const Divider(height: 1),
            
            // Reset Preferences
            ListTile(
              leading: const Icon(Icons.restore, color: Colors.orange),
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Restore all settings to default values'),
              onTap: _resetToDefaults,
            ),
            const Divider(height: 1),
            
            // Export/Import Settings
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Backup & Restore'),
              subtitle: const Text('Export or import your preferences'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showBackupRestoreOptions,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getFontSizeLabel(double scale) {
    if (scale <= 0.9) return 'Small';
    if (scale <= 1.1) return 'Normal';
    if (scale <= 1.3) return 'Large';
    return 'Extra Large';
  }

  // Event handlers
  void _showColorSchemeOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Color Scheme'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(backgroundColor: Color(0xFF2EB86C)),
              title: Text('Primary Green'),
              subtitle: Text('Current'),
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue),
              title: Text('Blue'),
              subtitle: Text('Coming Soon'),
              enabled: false,
            ),
            ListTile(
              leading: CircleAvatar(backgroundColor: Colors.purple),
              title: Text('Purple'),
              subtitle: Text('Coming Soon'),
              enabled: false,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector() {
    final languages = [
      LanguageOption(code: 'en', name: 'English', nativeName: 'English', isPopular: true),
      LanguageOption(code: 'hi', name: 'Hindi', nativeName: 'हिंदी', isPopular: true),
      LanguageOption(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', isPopular: true),
      LanguageOption(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', isPopular: true),
      LanguageOption(code: 'bn', name: 'Bengali', nativeName: 'বাংলা'),
      LanguageOption(code: 'mr', name: 'Marathi', nativeName: 'मराठी'),
      LanguageOption(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી'),
      LanguageOption(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ'),
      LanguageOption(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final language = languages[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: language.isPopular ? AppTheme.primaryGreen : Colors.grey.shade300,
                      child: Text(
                        language.code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: language.isPopular ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    title: Text(language.name),
                    subtitle: Text(language.nativeName),
                    trailing: language.code == _preferences.language
                        ? Icon(Icons.check, color: AppTheme.primaryGreen)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _preferences = _preferences.copyWith(language: language.code);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Language changed to ${language.name}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencySelector() {
    final currencies = [
      CurrencyOption(code: 'INR', name: 'Indian Rupee', symbol: '₹', country: 'India'),
      CurrencyOption(code: 'USD', name: 'US Dollar', symbol: '$', country: 'United States'),
      CurrencyOption(code: 'EUR', name: 'Euro', symbol: '€', country: 'European Union'),
      CurrencyOption(code: 'GBP', name: 'British Pound', symbol: '£', country: 'United Kingdom'),
      CurrencyOption(code: 'JPY', name: 'Japanese Yen', symbol: '¥', country: 'Japan'),
      CurrencyOption(code: 'AUD', name: 'Australian Dollar', symbol: 'A$', country: 'Australia'),
      CurrencyOption(code: 'CAD', name: 'Canadian Dollar', symbol: 'C$', country: 'Canada'),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Currency',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: currency.code == _preferences.currency 
                          ? AppTheme.primaryGreen 
                          : Colors.grey.shade300,
                      child: Text(
                        currency.symbol,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: currency.code == _preferences.currency ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    title: Text('${currency.symbol} ${currency.name}'),
                    subtitle: Text(currency.country),
                    trailing: currency.code == _preferences.currency
                        ? Icon(Icons.check, color: AppTheme.primaryGreen)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _preferences = _preferences.copyWith(
                          currency: currency.code,
                          region: currency.code == 'INR' ? 'IN' : currency.code,
                        );
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Currency changed to ${currency.name}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRegionSelector() {
    final regions = [
      {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
      {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
      {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
      {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
      {'code': 'AU', 'name': 'Australia', 'flag': '🇦🇺'},
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Region',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Expanded(
              child: ListView.builder(
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final region = regions[index];
                  return ListTile(
                    leading: Text(
                      region['flag'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(region['name'] as String),
                    trailing: region['code'] == _preferences.region
                        ? Icon(Icons.check, color: AppTheme.primaryGreen)
                        : null,
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _preferences = _preferences.copyWith(region: region['code'] as String);
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Region changed to ${region['name']}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files and may log you out of the app. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Simulate cache clearing
              setState(() => _isLoading = true);
              await Future.delayed(const Duration(seconds: 2));
              setState(() {
                _storageUsed = 50.0; // Simulated reduction
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _manageDownloads() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Downloads',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Avatar Models'),
              subtitle: const Text('75.2 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Cached Images'),
              subtitle: const Text('45.1 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text('Video Content'),
              subtitle: const Text('36.4 MB'),
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Clear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generateDebugLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Debug log generated and ready for export')),
    );
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all app preferences to their default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadAppPreferences(); // Reload default settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showBackupRestoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Export Settings'),
              subtitle: const Text('Download your preferences as JSON'),
              onTap: () {
                Navigator.of(context).pop();
                _exportPreferences();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Import Settings'),
              subtitle: const Text('Upload preferences from file'),
              onTap: () {
                Navigator.of(context).pop();
                _importPreferences();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Settings'),
              subtitle: const Text('Share preferences with another device'),
              onTap: () {
                Navigator.of(context).pop();
                _sharePreferences();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings exported successfully')),
    );
  }

  void _importPreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import settings functionality')),
    );
  }

  void _sharePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share settings functionality')),
    );
  }

  void _showPreferencesGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preferences Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('App Preferences Guide:'),
              SizedBox(height: 8),
              Text('• Theme: Customize the app appearance'),
              Text('• Language: Change app language and region'),
              Text('• Storage: Manage app data and cache'),
              Text('• Performance: Optimize app behavior'),
              Text('• Accessibility: Enhance usability'),
              Text('• Beta Features: Try experimental features'),
              SizedBox(height: 8),
              Text('Tips:'),
              Text('• Restart the app after major changes'),
              Text('• Export settings before resetting'),
              Text('• Beta features may be unstable'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}