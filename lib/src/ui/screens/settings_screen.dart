/// Settings Screen
/// 
/// Comprehensive settings interface with privacy controls and data management:
/// - Account settings and profile management
/// - Privacy controls and data management (GDPR/DPDP compliance)
/// - Avatar and scan management
/// - Notification preferences
/// - Security and authentication settings
/// - Compliance and legal information
/// - App preferences (theme, language, currency)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';
import '../../models/privacy_model.dart';
import '../../services/privacy_service.dart';
import 'privacy_settings_screen.dart';
import 'avatar_management_screen.dart';
import 'account_security_screen.dart';
import 'notification_settings_screen.dart';
import 'app_preferences_screen.dart';
import 'compliance_legal_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late PrivacySettings _currentSettings;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final service = PrivacyService.instance;
      await service.initialize();
      final settings = await service.loadPrivacySettings();
      
      if (mounted) {
        setState(() {
          _currentSettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () => _showSettingsInfo(),
            icon: const Icon(Icons.info_outline),
            tooltip: 'About Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Privacy Status
            _buildPrivacyStatusCard(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Account Section
            _buildAccountSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Avatar & Scans Section
            _buildAvatarScansSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Privacy & Data Section
            _buildPrivacyDataSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // App Preferences Section
            _buildAppPreferencesSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Notifications Section
            _buildNotificationsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Security Section
            _buildSecuritySection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Compliance & Legal Section
            _buildComplianceLegalSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // About & Help Section
            _buildAboutHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyStatusCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _currentSettings.allRequiredConsentsGiven 
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            _currentSettings.allRequiredConsentsGiven 
                ? AppTheme.primaryGreen.withOpacity(0.05)
                : Colors.orange.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
        border: Border.all(
          color: _currentSettings.allRequiredConsentsGiven 
              ? AppTheme.primaryGreen.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _currentSettings.allRequiredConsentsGiven 
                    ? Icons.privacy_tip
                    : Icons.warning,
                color: _currentSettings.allRequiredConsentsGiven 
                    ? AppTheme.primaryGreen 
                    : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentSettings.allRequiredConsentsGiven
                          ? 'Your privacy is protected'
                          : 'Review privacy settings required',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _currentSettings.allRequiredConsentsGiven 
                      ? AppTheme.primaryGreen 
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentSettings.allRequiredConsentsGiven ? 'Secure' : 'Review',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account', Icons.person),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.edit,
              title: 'Edit Profile',
              subtitle: 'Update your personal information',
              onTap: () => _navigateToAccountSecurity(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.credit_card,
              title: 'Payment Methods',
              subtitle: 'Manage saved payment options',
              onTap: () => _navigateToAccountSecurity(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.shopping_bag,
              title: 'Order History',
              subtitle: 'View your past orders and purchases',
              onTap: () => _navigateToAccountSecurity(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarScansSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Avatar & Scans', Icons.face),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.face_retouching_natural,
              title: 'Manage Avatars',
              subtitle: 'View, edit, and organize your avatar scans',
              onTap: () => _navigateToAvatarManagement(),
              badge: '3',
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.camera_alt,
              title: 'Scan History',
              subtitle: 'View all your scan sessions with details',
              onTap: () => _navigateToAvatarManagement(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.backup,
              title: 'Backup & Restore',
              subtitle: 'Create backups of your avatar data',
              onTap: () => _navigateToAvatarManagement(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.share,
              title: 'Avatar Sharing',
              subtitle: 'Control who can see your avatars',
              onTap: () => _navigateToAvatarManagement(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyDataSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Privacy & Data', Icons.privacy_tip),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Privacy Settings',
              subtitle: 'Manage data processing and consent preferences',
              onTap: () => _navigateToPrivacySettings(),
              trailing: Icon(
                Icons.verified_user,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.delete_sweep,
              title: 'Delete All Scans',
              subtitle: 'Remove all avatar and scan data permanently',
              onTap: () => _showDeleteAllScansDialog(),
              iconColor: Colors.red,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently delete account and all associated data',
              onTap: () => _showDeleteAccountDialog(),
              iconColor: Colors.red,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.download,
              title: 'Export My Data',
              subtitle: 'Download all your personal data (GDPR/DPDP compliant)',
              onTap: () => _navigateToPrivacySettings(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.schedule,
              title: 'Data Retention',
              subtitle: 'Configure automatic data deletion settings',
              onTap: () => _navigateToPrivacySettings(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.link,
              title: 'Third-party Integrations',
              subtitle: 'Manage API access and data sharing',
              onTap: () => _navigateToPrivacySettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('App Preferences', Icons.apps),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.palette,
              title: 'Theme & Appearance',
              subtitle: 'Customize app theme and visual preferences',
              onTap: () => _navigateToAppPreferences(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.language,
              title: 'Language',
              subtitle: 'Choose your preferred language',
              onTap: () => _navigateToAppPreferences(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.currency_rupee,
              title: 'Currency',
              subtitle: 'Select currency for pricing display',
              onTap: () => _navigateToAppPreferences(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.storage,
              title: 'Storage Management',
              subtitle: 'Manage app storage and cache',
              onTap: () => _navigateToAppPreferences(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Notifications', Icons.notifications),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.notifications_active,
              title: 'Push Notifications',
              subtitle: 'Manage push notification preferences',
              onTap: () => _navigateToNotificationSettings(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Control email notification settings',
              onTap: () => _navigateToNotificationSettings(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.sms,
              title: 'SMS Notifications',
              subtitle: 'Manage SMS notification preferences',
              onTap: () => _navigateToNotificationSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Security', Icons.security),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your account password',
              onTap: () => _navigateToAccountSecurity(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.verified_user,
              title: 'Two-Factor Authentication',
              subtitle: 'Enable 2FA for enhanced security',
              onTap: () => _navigateToAccountSecurity(),
              badge: 'OFF',
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.devices,
              title: 'Login Activity',
              subtitle: 'Monitor and manage logged-in devices',
              onTap: () => _navigateToAccountSecurity(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.devices_other,
              title: 'Device Management',
              subtitle: 'Manage authorized devices',
              onTap: () => _navigateToAccountSecurity(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceLegalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Compliance & Legal', Icons.gavel),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.verified_user,
              title: 'DPDP Act Compliance',
              subtitle: 'Data protection controls for Indian users',
              onTap: () => _navigateToComplianceLegal(),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'IND',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.description,
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              onTap: () => _navigateToComplianceLegal(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.rule,
              title: 'Terms of Service',
              subtitle: 'Terms and conditions',
              onTap: () => _navigateToComplianceLegal(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.request_page,
              title: 'Data Deletion Requests',
              subtitle: 'Submit formal data deletion requests',
              onTap: () => _navigateToComplianceLegal(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.analytics,
              title: 'Compliance Reports',
              subtitle: 'Data usage and sharing transparency',
              onTap: () => _navigateToComplianceLegal(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.contact_support,
              title: 'Data Protection Officer',
              subtitle: 'Contact information for privacy queries',
              onTap: () => _navigateToComplianceLegal(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutHelpSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('About & Help', Icons.help),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildSettingsTile(
              icon: Icons.help_center,
              title: 'Help & Support',
              subtitle: 'Get help and contact support',
              onTap: () => _showHelpDialog(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.feedback,
              title: 'Send Feedback',
              subtitle: 'Share your feedback and suggestions',
              onTap: () => _showFeedbackDialog(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.star,
              title: 'Rate App',
              subtitle: 'Rate us on the app store',
              onTap: () => _showRateAppDialog(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.info,
              title: 'App Information',
              subtitle: 'Version: 1.0.0 • Build: 100',
              onTap: () => _showAppInfoDialog(),
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            _buildSettingsTile(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              onTap: () => _showSignOutDialog(),
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? AppTheme.textDarkGray,
          size: 20,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badge == 'ON' ? Colors.green.shade100 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: badge == 'ON' ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textDarkGray,
          ),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // Navigation methods
  void _navigateToPrivacySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
      ),
    );
  }

  void _navigateToAvatarManagement() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AvatarManagementScreen(),
      ),
    );
  }

  void _navigateToAccountSecurity() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccountSecurityScreen(),
      ),
    );
  }

  void _navigateToNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _navigateToAppPreferences() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AppPreferencesScreen(),
      ),
    );
  }

  void _navigateToComplianceLegal() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ComplianceLegalScreen(),
      ),
    );
  }

  // Dialog methods
  void _showSettingsInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Settings'),
        content: const Text(
          'This settings screen provides comprehensive control over your app experience, '
          'privacy preferences, and data management. All privacy controls are designed '
          'to comply with the Digital Personal Data Protection (DPDP) Act 2023 and '
          'GDPR requirements.',
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

  void _showDeleteAllScansDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Scans'),
        content: const Text(
          'This will permanently delete all your avatar scans and related data. '
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteAllScans();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data including:\n\n'
          '• Avatar scans and profile data\n'
          '• Purchase history\n'
          '• Privacy settings\n'
          '• All personal information\n\n'
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performDeleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _performDeleteAllScans() {
    // Implementation would call privacy service to delete scans
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All scans deleted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _performDeleteAccount() {
    // Implementation would call privacy service to delete account
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account deletion initiated. You will be logged out.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For help and support:\n\n'
          '📧 Email: support@yourapp.com\n'
          '📞 Phone: +91-XXX-XXX-XXXX\n'
          '💬 Live Chat: Available 9 AM - 6 PM IST\n'
          '📱 Help Center: support.yourapp.com',
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

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'We value your feedback! Please rate your experience and let us know how we can improve.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open feedback form
            },
            child: const Text('Send Feedback'),
          ),
        ],
      ),
    );
  }

  void _showRateAppDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate App'),
        content: const Text(
          'If you enjoy using our app, please take a moment to rate it. Your feedback helps us improve!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open app store rating
            },
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            Text('Build: 100'),
            SizedBox(height: 8),
            Text('© 2024 Your App Name'),
            Text('All rights reserved.'),
            SizedBox(height: 8),
            Text(
              'Made with ❤️ in India',
              style: TextStyle(fontStyle: FontStyle.italic),
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

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Handle sign out logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Signed out successfully'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}