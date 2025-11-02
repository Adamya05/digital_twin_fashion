/// Notification Settings Screen
/// 
/// Comprehensive notification management interface:
/// - Push notification preferences
/// - Email notification settings
/// - SMS notification controls
/// - Notification categories and types
/// - Quiet hours and do not disturb settings
/// - Notification sound and vibration preferences
/// - Delivery schedule settings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';

/// Notification preferences data model
class NotificationPreferences {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final Map<String, bool> categorySettings;
  final Map<String, bool> typeSettings;
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final String soundPreference;
  final bool vibrationEnabled;
  final String notificationDeliverySchedule;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    this.categorySettings = const {},
    this.typeSettings = const {},
    this.quietHoursEnabled = false,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    this.soundPreference = 'default',
    this.vibrationEnabled = true,
    this.notificationDeliverySchedule = 'immediate',
  }) : quietHoursStart = quietHoursStart ?? const TimeOfDay(hour: 22, minute: 0),
       quietHoursEnd = quietHoursEnd ?? const TimeOfDay(hour: 8, minute: 0);
}

/// Notification category model
class NotificationCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isDefaultEnabled;

  const NotificationCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isDefaultEnabled = true,
  });
}

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends ConsumerState<NotificationSettingsScreen> {
  NotificationPreferences _preferences = const NotificationPreferences();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    // Mock data - in real app, this would fetch from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _preferences = const NotificationPreferences(
        pushEnabled: true,
        emailEnabled: true,
        smsEnabled: false,
        categorySettings: {
          'account': true,
          'security': true,
          'orders': true,
          'recommendations': false,
          'marketing': false,
          'system': true,
        },
        typeSettings: {
          'login_alerts': true,
          'password_changes': true,
          'order_updates': true,
          'scan_completion': true,
          'new_features': true,
          'promotional': false,
        },
        quietHoursEnabled: true,
        quietHoursStart: TimeOfDay(hour: 22, minute: 0),
        quietHoursEnd: TimeOfDay(hour: 8, minute: 0),
        soundPreference: 'default',
        vibrationEnabled: true,
        notificationDeliverySchedule: 'immediate',
      );
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        actions: [
          IconButton(
            onPressed: _showNotificationGuide,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Notification Guide',
          ),
          IconButton(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification Status Overview
            _buildNotificationOverview(),
            const SizedBox(height: AppTheme.spacingL),
            
            // General Settings
            _buildGeneralSettingsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Push Notifications
            _buildPushNotificationsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Email Notifications
            _buildEmailNotificationsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // SMS Notifications
            _buildSMSNotificationsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Category-based Settings
            _buildCategorySettingsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Quiet Hours
            _buildQuietHoursSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Sound & Vibration
            _buildSoundVibrationSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationOverview() {
    final enabledChannels = [
      if (_preferences.pushEnabled) 'Push',
      if (_preferences.emailEnabled) 'Email',
      if (_preferences.smsEnabled) 'SMS',
    ].length;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            enabledChannels > 0 ? AppTheme.primaryGreen : Colors.grey,
            enabledChannels > 0 ? AppTheme.primaryGreen.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$enabledChannels channel${enabledChannels != 1 ? 's' : ''} active',
                      style: const TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  enabledChannels > 0 ? 'Active' : 'Disabled',
                  style: TextStyle(
                    color: enabledChannels > 0 ? AppTheme.primaryGreen : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildGeneralSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Settings', Icons.settings),
            const SizedBox(height: AppTheme.spacingM),
            
            // Delivery Schedule
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Delivery Schedule'),
              subtitle: const Text('How notifications are delivered'),
              trailing: DropdownButton<String>(
                value: _preferences.notificationDeliverySchedule,
                items: const [
                  DropdownMenuItem(value: 'immediate', child: Text('Immediate')),
                  DropdownMenuItem(value: 'batched', child: Text('Batched')),
                  DropdownMenuItem(value: 'summary', child: Text('Daily Summary')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: _preferences.typeSettings,
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: _preferences.soundPreference,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: value,
                      );
                    });
                  }
                },
              ),
            ),
            const Divider(height: 1),
            
            // Test Notifications
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Send Test Notifications'),
              subtitle: const Text('Test all notification channels'),
              trailing: ElevatedButton(
                onPressed: _sendTestNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPushNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Push Notifications', Icons.phone_android, color: Colors.blue),
            const SizedBox(height: AppTheme.spacingM),
            
            // Enable/Disable Push
            SwitchListTile(
              title: const Text('Enable Push Notifications'),
              subtitle: const Text('Receive notifications on this device'),
              value: _preferences.pushEnabled,
              onChanged: (enabled) {
                setState(() {
                  _preferences = NotificationPreferences(
                    pushEnabled: enabled,
                    emailEnabled: _preferences.emailEnabled,
                    smsEnabled: _preferences.smsEnabled,
                    categorySettings: _preferences.categorySettings,
                    typeSettings: _preferences.typeSettings,
                    quietHoursEnabled: _preferences.quietHoursEnabled,
                    quietHoursStart: _preferences.quietHoursStart,
                    quietHoursEnd: _preferences.quietHoursEnd,
                    soundPreference: _preferences.soundPreference,
                    vibrationEnabled: _preferences.vibrationEnabled,
                    notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                  );
                });
              },
              secondary: Icon(
                Icons.phone_android,
                color: _preferences.pushEnabled ? Colors.blue : Colors.grey,
              ),
            ),
            
            if (_preferences.pushEnabled) ...[
              const Divider(height: 1),
              
              // Push-specific settings
              ListTile(
                leading: const Icon(Icons.notification_important),
                title: const Text('Priority Notifications'),
                subtitle: const Text('Allow high-priority notifications during quiet hours'),
                trailing: Switch(
                  value: _preferences.typeSettings['priority_notifications'] ?? false,
                  onChanged: (enabled) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: {..._preferences.typeSettings, 'priority_notifications': enabled},
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: _preferences.soundPreference,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                      );
                    });
                  },
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.phone_iphone),
                title: const Text('iOS/Android System Settings'),
                subtitle: const Text('Configure in device settings for full control'),
                trailing: IconButton(
                  onPressed: _openSystemNotificationSettings,
                  icon: const Icon(Icons.open_in_new, size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmailNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Email Notifications', Icons.email, color: Colors.orange),
            const SizedBox(height: AppTheme.spacingM),
            
            // Enable/Disable Email
            SwitchListTile(
              title: const Text('Enable Email Notifications'),
              subtitle: const Text('Receive notifications via email'),
              value: _preferences.emailEnabled,
              onChanged: (enabled) {
                setState(() {
                  _preferences = NotificationPreferences(
                    pushEnabled: _preferences.pushEnabled,
                    emailEnabled: enabled,
                    smsEnabled: _preferences.smsEnabled,
                    categorySettings: _preferences.categorySettings,
                    typeSettings: _preferences.typeSettings,
                    quietHoursEnabled: _preferences.quietHoursEnabled,
                    quietHoursStart: _preferences.quietHoursStart,
                    quietHoursEnd: _preferences.quietHoursEnd,
                    soundPreference: _preferences.soundPreference,
                    vibrationEnabled: _preferences.vibrationEnabled,
                    notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                  );
                });
              },
              secondary: Icon(
                Icons.email,
                color: _preferences.emailEnabled ? Colors.orange : Colors.grey,
              ),
            ),
            
            if (_preferences.emailEnabled) ...[
              const Divider(height: 1),
              
              // Email frequency settings
              ListTile(
                leading: const Icon(Icons.schedule_send),
                title: const Text('Email Frequency'),
                subtitle: const Text('How often to receive email notifications'),
                trailing: DropdownButton<String>(
                  value: 'immediate',
                  items: const [
                    DropdownMenuItem(value: 'immediate', child: Text('Immediate')),
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly Digest')),
                    DropdownMenuItem(value: 'daily', child: Text('Daily Digest')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly Summary')),
                  ],
                  onChanged: (value) {},
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Email Read Tracking'),
                subtitle: const Text('Track when emails are opened'),
                trailing: Switch(
                  value: _preferences.typeSettings['email_tracking'] ?? true,
                  onChanged: (enabled) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: {..._preferences.typeSettings, 'email_tracking': enabled},
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: _preferences.soundPreference,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSMSNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('SMS Notifications', Icons.sms, color: Colors.green),
            const SizedBox(height: AppTheme.spacingM),
            
            // Enable/Disable SMS
            SwitchListTile(
              title: const Text('Enable SMS Notifications'),
              subtitle: const Text('Receive notifications via text message'),
              value: _preferences.smsEnabled,
              onChanged: (enabled) {
                setState(() {
                  _preferences = NotificationPreferences(
                    pushEnabled: _preferences.pushEnabled,
                    emailEnabled: _preferences.emailEnabled,
                    smsEnabled: enabled,
                    categorySettings: _preferences.categorySettings,
                    typeSettings: _preferences.typeSettings,
                    quietHoursEnabled: _preferences.quietHoursEnabled,
                    quietHoursStart: _preferences.quietHoursStart,
                    quietHoursEnd: _preferences.quietHoursEnd,
                    soundPreference: _preferences.soundPreference,
                    vibrationEnabled: _preferences.vibrationEnabled,
                    notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                  );
                });
              },
              secondary: Icon(
                Icons.sms,
                color: _preferences.smsEnabled ? Colors.green : Colors.grey,
              ),
            ),
            
            if (_preferences.smsEnabled) ...[
              const Divider(height: 1),
              
              // SMS settings
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Verified Phone Number'),
                subtitle: const Text('+91 98765 43210'),
                trailing: TextButton(
                  onPressed: _changePhoneNumber,
                  child: const Text('Change'),
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.warning),
                title: const Text('SMS Costs'),
                subtitle: const Text('SMS charges may apply based on your carrier'),
                trailing: Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              
              ListTile(
                leading: const Icon(Icons.settings_remote),
                title: const Text('Emergency Only'),
                subtitle: const Text('Only receive critical security notifications'),
                trailing: Switch(
                  value: _preferences.typeSettings['sms_emergency_only'] ?? false,
                  onChanged: (enabled) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: {..._preferences.typeSettings, 'sms_emergency_only': enabled},
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: _preferences.soundPreference,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySettingsSection() {
    final categories = [
      NotificationCategory(
        id: 'account',
        name: 'Account Updates',
        description: 'Profile changes, login activity',
        icon: Icons.person,
        isDefaultEnabled: true,
      ),
      NotificationCategory(
        id: 'security',
        name: 'Security Alerts',
        description: 'Login attempts, password changes',
        icon: Icons.security,
        isDefaultEnabled: true,
      ),
      NotificationCategory(
        id: 'orders',
        name: 'Orders & Purchases',
        description: 'Order status, payment confirmations',
        icon: Icons.shopping_bag,
        isDefaultEnabled: true,
      ),
      NotificationCategory(
        id: 'recommendations',
        name: 'Recommendations',
        description: 'Personalized product suggestions',
        icon: Icons.lightbulb_outline,
        isDefaultEnabled: false,
      ),
      NotificationCategory(
        id: 'marketing',
        name: 'Marketing & Promotions',
        description: 'Special offers, news updates',
        icon: Icons.campaign,
        isDefaultEnabled: false,
      ),
      NotificationCategory(
        id: 'system',
        name: 'System Updates',
        description: 'App updates, maintenance notices',
        icon: Icons.system_security_update_good,
        isDefaultEnabled: true,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notification Categories', Icons.category),
            const SizedBox(height: AppTheme.spacingM),
            
            ...categories.map((category) => _buildCategoryItem(category)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(NotificationCategory category) {
    final isEnabled = _preferences.categorySettings[category.id] ?? category.isDefaultEnabled;
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: isEnabled ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: isEnabled ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          category.icon,
          color: isEnabled ? AppTheme.primaryGreen : Colors.grey,
        ),
        title: Text(
          category.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isEnabled ? AppTheme.primaryGreen : null,
          ),
        ),
        subtitle: Text(category.description),
        trailing: Switch(
          value: isEnabled,
          onChanged: (enabled) {
            setState(() {
              _preferences = NotificationPreferences(
                pushEnabled: _preferences.pushEnabled,
                emailEnabled: _preferences.emailEnabled,
                smsEnabled: _preferences.smsEnabled,
                categorySettings: {..._preferences.categorySettings, category.id: enabled},
                typeSettings: _preferences.typeSettings,
                quietHoursEnabled: _preferences.quietHoursEnabled,
                quietHoursStart: _preferences.quietHoursStart,
                quietHoursEnd: _preferences.quietHoursEnd,
                soundPreference: _preferences.soundPreference,
                vibrationEnabled: _preferences.vibrationEnabled,
                notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
              );
            });
          },
        ),
      ),
    );
  }

  Widget _buildQuietHoursSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Quiet Hours', Icons.bedtime, color: Colors.purple),
            const SizedBox(height: AppTheme.spacingM),
            
            // Enable/Disable Quiet Hours
            SwitchListTile(
              title: const Text('Enable Quiet Hours'),
              subtitle: const Text('Mute notifications during specified hours'),
              value: _preferences.quietHoursEnabled,
              onChanged: (enabled) {
                setState(() {
                  _preferences = NotificationPreferences(
                    pushEnabled: _preferences.pushEnabled,
                    emailEnabled: _preferences.emailEnabled,
                    smsEnabled: _preferences.smsEnabled,
                    categorySettings: _preferences.categorySettings,
                    typeSettings: _preferences.typeSettings,
                    quietHoursEnabled: enabled,
                    quietHoursStart: _preferences.quietHoursStart,
                    quietHoursEnd: _preferences.quietHoursEnd,
                    soundPreference: _preferences.soundPreference,
                    vibrationEnabled: _preferences.vibrationEnabled,
                    notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                  );
                });
              },
              secondary: Icon(
                Icons.bedtime,
                color: _preferences.quietHoursEnabled ? Colors.purple : Colors.grey,
              ),
            ),
            
            if (_preferences.quietHoursEnabled) ...[
              const Divider(height: 1),
              
              // Time Selection
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Start Time'),
                subtitle: Text(_preferences.quietHoursStart.format(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectTime(true),
              ),
              
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('End Time'),
                subtitle: Text(_preferences.quietHoursEnd.format(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectTime(false),
              ),
              
              ListTile(
                leading: const Icon(Icons.schedule_send),
                title: const Text('Delivery After Quiet Hours'),
                subtitle: const Text('Deliver queued notifications when quiet hours end'),
                trailing: Switch(
                  value: _preferences.typeSettings['deliver_after_quiet'] ?? true,
                  onChanged: (enabled) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: {..._preferences.typeSettings, 'deliver_after_quiet': enabled},
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: _preferences.soundPreference,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                      );
                    });
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoundVibrationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Sound & Vibration', Icons.volume_up, color: Colors.teal),
            const SizedBox(height: AppTheme.spacingM),
            
            // Notification Sound
            ListTile(
              leading: const Icon(Icons.music_note),
              title: const Text('Notification Sound'),
              subtitle: Text(_getSoundDisplayName(_preferences.soundPreference)),
              trailing: DropdownButton<String>(
                value: _preferences.soundPreference,
                items: const [
                  DropdownMenuItem(value: 'default', child: Text('Default')),
                  DropdownMenuItem(value: 'subtle', child: Text('Subtle')),
                  DropdownMenuItem(value: 'alert', child: Text('Alert')),
                  DropdownMenuItem(value: 'silent', child: Text('Silent')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _preferences = NotificationPreferences(
                        pushEnabled: _preferences.pushEnabled,
                        emailEnabled: _preferences.emailEnabled,
                        smsEnabled: _preferences.smsEnabled,
                        categorySettings: _preferences.categorySettings,
                        typeSettings: _preferences.typeSettings,
                        quietHoursEnabled: _preferences.quietHoursEnabled,
                        quietHoursStart: _preferences.quietHoursStart,
                        quietHoursEnd: _preferences.quietHoursEnd,
                        soundPreference: value,
                        vibrationEnabled: _preferences.vibrationEnabled,
                        notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                      );
                    });
                  }
                },
              ),
            ),
            const Divider(height: 1),
            
            // Vibration
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate device when notifications arrive'),
              value: _preferences.vibrationEnabled,
              onChanged: (enabled) {
                setState(() {
                  _preferences = NotificationPreferences(
                    pushEnabled: _preferences.pushEnabled,
                    emailEnabled: _preferences.emailEnabled,
                    smsEnabled: _preferences.smsEnabled,
                    categorySettings: _preferences.categorySettings,
                    typeSettings: _preferences.typeSettings,
                    quietHoursEnabled: _preferences.quietHoursEnabled,
                    quietHoursStart: _preferences.quietHoursStart,
                    quietHoursEnd: _preferences.quietHoursEnd,
                    soundPreference: _preferences.soundPreference,
                    vibrationEnabled: enabled,
                    notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
                  );
                });
              },
              secondary: const Icon(Icons.vibration),
            ),
            const Divider(height: 1),
            
            // Test Sound
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Test Notification Sound'),
              subtitle: const Text('Play a test notification sound'),
              trailing: ElevatedButton(
                onPressed: _testSound,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Test'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getSoundDisplayName(String soundPreference) {
    switch (soundPreference) {
      case 'default':
        return 'Default';
      case 'subtle':
        return 'Subtle';
      case 'alert':
        return 'Alert';
      case 'silent':
        return 'Silent';
      default:
        return 'Default';
    }
  }

  // Event handlers
  void _sendTestNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Test notifications sent')),
    );
  }

  void _openSystemNotificationSettings() {
    // In a real app, this would open system notification settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening system notification settings')),
    );
  }

  void _changePhoneNumber() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'New Phone Number',
                hintText: '+91 XXXXX XXXXX',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Text(
              'You will receive an SMS verification code',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verification code sent')),
              );
            },
            child: const Text('Send Code'),
          ),
        ],
      ),
    );
  }

  void _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _preferences.quietHoursStart : _preferences.quietHoursEnd,
    );
    
    if (picked != null) {
      setState(() {
        _preferences = NotificationPreferences(
          pushEnabled: _preferences.pushEnabled,
          emailEnabled: _preferences.emailEnabled,
          smsEnabled: _preferences.smsEnabled,
          categorySettings: _preferences.categorySettings,
          typeSettings: _preferences.typeSettings,
          quietHoursEnabled: _preferences.quietHoursEnabled,
          quietHoursStart: isStart ? picked : _preferences.quietHoursStart,
          quietHoursEnd: isStart ? _preferences.quietHoursEnd : picked,
          soundPreference: _preferences.soundPreference,
          vibrationEnabled: _preferences.vibrationEnabled,
          notificationDeliverySchedule: _preferences.notificationDeliverySchedule,
        );
      });
    }
  }

  void _testSound() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playing test sound')),
    );
  }

  void _showNotificationGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Understanding Notification Settings:'),
              SizedBox(height: 8),
              Text('• Push: Device notifications when app is active'),
              Text('• Email: Detailed notifications sent to your email'),
              Text('• SMS: Critical alerts via text message'),
              SizedBox(height: 8),
              Text('Privacy:'),
              Text('• Notifications respect your privacy settings'),
              Text('• You can control what information is shared'),
              Text('• All notification data is encrypted'),
              SizedBox(height: 8),
              Text('Tips:'),
              Text('• Enable quiet hours for uninterrupted sleep'),
              Text('• Use email for non-urgent notifications'),
              Text('• Keep SMS for emergency alerts only'),
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

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all notification settings to their default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNotificationSettings(); // Reload default settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings reset to defaults')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}