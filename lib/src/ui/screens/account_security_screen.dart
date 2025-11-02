/// Account Security Screen
/// 
/// Comprehensive account security and management interface:
/// - Profile editing functionality
/// - Password change options
/// - Two-factor authentication setup
/// - Login activity monitoring
/// - Device management (logged in devices)
/// - Session management tools
/// - Security notifications and alerts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';

/// Device session data model
class DeviceSession {
  final String id;
  final String deviceName;
  final String deviceType;
  final String location;
  final DateTime lastActive;
  final String ipAddress;
  final bool isCurrentDevice;
  final String status;

  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.location,
    required this.lastActive,
    required this.ipAddress,
    this.isCurrentDevice = false,
    this.status = 'active',
  });
}

/// Login activity data model
class LoginActivity {
  final String id;
  final DateTime timestamp;
  final String action;
  final String deviceName;
  final String location;
  final String ipAddress;
  final String status;

  const LoginActivity({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.deviceName,
    required this.location,
    required this.ipAddress,
    required this.status,
  });
}

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  ConsumerState<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends ConsumerState<AccountSecurityScreen> {
  bool _isLoading = false;
  bool _twoFactorEnabled = false;
  List<DeviceSession> _deviceSessions = [];
  List<LoginActivity> _loginActivities = [];

  @override
  void initState() {
    super.initState();
    _loadSecurityData();
  }

  Future<void> _loadSecurityData() async {
    setState(() => _isLoading = true);

    // Mock data - in real app, this would fetch from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _deviceSessions = [
        DeviceSession(
          id: '1',
          deviceName: 'iPhone 14 Pro',
          deviceType: 'iOS',
          location: 'Mumbai, India',
          lastActive: DateTime.now().subtract(const Duration(minutes: 5)),
          ipAddress: '192.168.1.100',
          isCurrentDevice: true,
          status: 'active',
        ),
        DeviceSession(
          id: '2',
          deviceName: 'MacBook Pro',
          deviceType: 'macOS',
          location: 'Mumbai, India',
          lastActive: DateTime.now().subtract(const Duration(hours: 2)),
          ipAddress: '192.168.1.101',
          isCurrentDevice: false,
          status: 'active',
        ),
        DeviceSession(
          id: '3',
          deviceName: 'iPad',
          deviceType: 'iPadOS',
          location: 'Delhi, India',
          lastActive: DateTime.now().subtract(const Duration(days: 1)),
          ipAddress: '192.168.1.102',
          isCurrentDevice: false,
          status: 'idle',
        ),
      ];

      _loginActivities = [
        LoginActivity(
          id: '1',
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          action: 'Login',
          deviceName: 'iPhone 14 Pro',
          location: 'Mumbai, India',
          ipAddress: '192.168.1.100',
          status: 'successful',
        ),
        LoginActivity(
          id: '2',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          action: 'Password Changed',
          deviceName: 'MacBook Pro',
          location: 'Mumbai, India',
          ipAddress: '192.168.1.101',
          status: 'successful',
        ),
        LoginActivity(
          id: '3',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          action: 'Login',
          deviceName: 'iPad',
          location: 'Delhi, India',
          ipAddress: '192.168.1.102',
          status: 'successful',
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Security'),
        actions: [
          IconButton(
            onPressed: _showSecurityTips,
            icon: const Icon(Icons.info_outline),
            tooltip: 'Security Tips',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Information Section
            _buildProfileSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Security Settings Section
            _buildSecuritySettingsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Device Management Section
            _buildDeviceManagementSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Login Activity Section
            _buildLoginActivitySection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Account Actions Section
            _buildAccountActionsSection(),
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

  Widget _buildProfileSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Profile Information', Icons.person),
            const SizedBox(height: AppTheme.spacingM),
            
            // Profile Avatar and Basic Info
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showChangePhotoOptions,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppTheme.spacingL),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'John Doe',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'john.doe@example.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textDarkGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Member since Jan 2024',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Profile',
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Profile Fields
            _buildProfileField('Full Name', 'John Doe'),
            const SizedBox(height: AppTheme.spacingS),
            _buildProfileField('Email', 'john.doe@example.com'),
            const SizedBox(height: AppTheme.spacingS),
            _buildProfileField('Phone', '+91 98765 43210'),
            const SizedBox(height: AppTheme.spacingS),
            _buildProfileField('Date of Birth', '15 March 1990'),
            const SizedBox(height: AppTheme.spacingS),
            _buildProfileField('Gender', 'Male'),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Edit Profile Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textDarkGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSecuritySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Security Settings', Icons.security),
            const SizedBox(height: AppTheme.spacingM),
            
            // Password Section
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text('Password'),
              subtitle: const Text('Last changed 30 days ago'),
              trailing: ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Change'),
              ),
            ),
            const Divider(height: 1),
            
            // Two-Factor Authentication
            SwitchListTile(
              title: const Text('Two-Factor Authentication'),
              subtitle: const Text('Add an extra layer of security'),
              value: _twoFactorEnabled,
              onChanged: _toggleTwoFactor,
              secondary: Icon(
                _twoFactorEnabled ? Icons.verified_user : Icons.security,
                color: _twoFactorEnabled ? AppTheme.primaryGreen : Colors.grey,
              ),
            ),
            const Divider(height: 1),
            
            // Security Notifications
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Security Notifications'),
              subtitle: const Text('Get alerts for suspicious activity'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _manageSecurityNotifications,
            ),
            const Divider(height: 1),
            
            // Login Alerts
            SwitchListTile(
              title: const Text('Login Alerts'),
              subtitle: const Text('Get notified of new logins'),
              value: true,
              onChanged: (value) {},
              secondary: const Icon(Icons.login),
            ),
            const Divider(height: 1),
            
            // Backup Codes
            ListTile(
              leading: const Icon(Icons.qr_code),
              title: const Text('Backup Codes'),
              subtitle: const Text('Generate backup codes for 2FA'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _manageBackupCodes,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Device Management', Icons.devices),
            const SizedBox(height: AppTheme.spacingM),
            
            // Device Sessions Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.devices_other,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_deviceSessions.length} Device${_deviceSessions.length != 1 ? 's' : ''} Connected',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_deviceSessions.where((d) => d.status == 'active').length} currently active',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textDarkGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Device List
            ..._deviceSessions.map((device) => _buildDeviceItem(device)),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showAllDevices,
                    icon: const Icon(Icons.list),
                    label: const Text('View All'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _signOutAllDevices,
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceItem(DeviceSession device) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: device.isCurrentDevice ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: device.isCurrentDevice ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(device.deviceType),
            color: device.isCurrentDevice ? AppTheme.primaryGreen : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: device.isCurrentDevice ? AppTheme.primaryGreen : null,
                      ),
                    ),
                    if (device.isCurrentDevice) ...[
                      const SizedBox(width: AppTheme.spacingS),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Current',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.deviceType} • ${device.location}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textDarkGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last active: ${_formatTimeAgo(device.lastActive)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleDeviceAction(action, device),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'details',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('View Details'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (!device.isCurrentDevice)
                const PopupMenuItem(
                  value: 'signout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.orange),
                    title: Text('Sign Out', style: TextStyle(color: Colors.orange)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Rename Device'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoginActivitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Login Activity', Icons.history),
            const SizedBox(height: AppTheme.spacingM),
            
            // Recent Activity Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'All activities look normal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                        Text(
                          'No suspicious activity detected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Activity List
            ..._loginActivities.take(5).map((activity) => _buildActivityItem(activity)),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // View All Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showAllActivity,
                child: const Text('View All Activity'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(LoginActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activity.status == 'successful' ? Colors.green.shade100 : Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity.status == 'successful' ? Icons.check_circle : Icons.error,
              color: activity.status == 'successful' ? Colors.green.shade700 : Colors.red.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.action,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${activity.deviceName} • ${activity.location}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textDarkGray,
                  ),
                ),
                Text(
                  '${_formatTimeAgo(activity.timestamp)} • ${activity.ipAddress}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            activity.status == 'successful' ? Icons.check : Icons.close,
            color: activity.status == 'successful' ? Colors.green.shade600 : Colors.red.shade600,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account Actions', Icons.admin_panel_settings, color: Colors.red),
            const SizedBox(height: AppTheme.spacingM),
            
            // Danger Zone
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Danger Zone',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'These actions are irreversible. Please proceed with caution.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Account Actions
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.orange),
              title: const Text('Sign Out Everywhere'),
              subtitle: const Text('Sign out from all devices except this one'),
              trailing: ElevatedButton(
                onPressed: _signOutAllDevices,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign Out'),
              ),
            ),
            const Divider(height: 1),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Account'),
              subtitle: const Text('Permanently delete your account and all data'),
              onTap: _deleteAccount,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'ios':
      case 'iphone':
        return Icons.phone_iphone;
      case 'android':
        return Icons.phone_android;
      case 'macos':
        return Icons.laptop_mac;
      case 'windows':
        return Icons.laptop_windows;
      case 'ipad':
        return Icons.tablet_mac;
      default:
        return Icons.devices_other;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Event handlers
  void _editProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
              ),
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
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
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
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  void _toggleTwoFactor(bool enabled) {
    setState(() => _twoFactorEnabled = enabled);
    
    if (enabled) {
      _showTwoFactorSetupDialog();
    } else {
      _showDisableTwoFactorDialog();
    }
  }

  void _showTwoFactorSetupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Up Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Scan this QR code with your authenticator app:'),
            SizedBox(height: 16),
            Container(
              height: 200,
              width: 200,
              color: Colors.grey,
              child: Icon(Icons.qr_code_scanner, size: 80, color: Colors.white),
            ),
            SizedBox(height: 16),
            Text('Or enter this code manually:'),
            SizedBox(height: 8),
            Text(
              '123456',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
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
                const SnackBar(content: Text('Two-factor authentication enabled')),
              );
            },
            child: const Text('Verify & Enable'),
          ),
        ],
      ),
    );
  }

  void _showDisableTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Two-Factor Authentication'),
        content: const Text('Are you sure you want to disable two-factor authentication? Your account will be less secure.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() => _twoFactorEnabled = true); // Re-enable
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Two-factor authentication disabled')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _manageSecurityNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Security notification settings')),
    );
  }

  void _manageBackupCodes() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup codes management')),
    );
  }

  void _showChangePhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Profile Photo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new photo'),
              onTap: () {
                Navigator.of(context).pop();
                // Open camera
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from existing photos'),
              onTap: () {
                Navigator.of(context).pop();
                // Open gallery
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Remove Photo'),
              subtitle: const Text('Remove current profile photo'),
              onTap: () {
                Navigator.of(context).pop();
                // Remove photo
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeviceAction(String action, DeviceSession device) {
    switch (action) {
      case 'details':
        _showDeviceDetails(device);
        break;
      case 'signout':
        _signOutDevice(device);
        break;
      case 'rename':
        _renameDevice(device);
        break;
    }
  }

  void _showDeviceDetails(DeviceSession device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Device Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Device Name', device.deviceName),
            _buildDetailRow('Device Type', device.deviceType),
            _buildDetailRow('Location', device.location),
            _buildDetailRow('IP Address', device.ipAddress),
            _buildDetailRow('Last Active', _formatTimeAgo(device.lastActive)),
            _buildDetailRow('Status', device.status),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textDarkGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _signOutDevice(DeviceSession device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out Device'),
        content: Text('Are you sure you want to sign out from "${device.deviceName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _deviceSessions.remove(device);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device signed out successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _renameDevice(DeviceSession device) {
    final controller = TextEditingController(text: device.deviceName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final index = _deviceSessions.indexOf(device);
                _deviceSessions[index] = device.copyWith(
                  deviceName: controller.text,
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Device renamed successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _signOutAllDevices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out All Devices'),
        content: const Text('Are you sure you want to sign out from all devices except this one?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _deviceSessions.removeWhere((device) => !device.isCurrentDevice);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out from all other devices')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out All'),
          ),
        ],
      ),
    );
  }

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. Your account and all associated data will be permanently deleted.',
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
                const SnackBar(content: Text('Account deletion initiated')),
              );
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

  void _showAllDevices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View all devices')),
    );
  }

  void _showAllActivity() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('View all activity')),
    );
  }

  void _showSecurityTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Tips'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Best practices for account security:'),
              SizedBox(height: 8),
              Text('• Use a strong, unique password'),
              Text('• Enable two-factor authentication'),
              Text('• Regularly review login activity'),
              Text('• Sign out from shared devices'),
              Text('• Keep your contact information updated'),
              Text('• Monitor your account for suspicious activity'),
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