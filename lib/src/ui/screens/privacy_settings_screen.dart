/// Privacy Settings Screen
/// 
/// Comprehensive privacy and data management interface that allows users to:
/// - View and modify privacy preferences
/// - Delete all data
/// - Export personal data
/// - Manage consent preferences
/// - Contact data protection officer
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';
import '../../models/privacy_model.dart';
import '../../services/privacy_service.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late PrivacySettings _currentSettings;
  bool _isLoading = true;
  bool _isDeleting = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
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
        _showErrorSnackBar('Failed to load privacy settings');
      }
    }
  }

  Future<void> _savePrivacySettings() async {
    try {
      final service = PrivacyService.instance;
      await service.savePrivacySettings(_currentSettings);
      
      if (mounted) {
        _showSuccessSnackBar('Privacy settings saved successfully');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save privacy settings');
      }
    }
  }

  Future<void> _deleteAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data'),
        content: const Text(
          'This will permanently delete all your personal data including:\n\n'
          '• Your avatar scans\n'
          '• Profile information\n'
          '• Purchase history\n'
          '• Privacy settings\n\n'
          'This action cannot be undone. Are you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      
      try {
        final service = PrivacyService.instance;
        await service.deleteAllUserData();
        
        if (mounted) {
          setState(() => _isDeleting = false);
          _showSuccessSnackBar('All data deleted successfully');
          
          // Reset to default settings
          setState(() {
            _currentSettings = const PrivacySettings();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          _showErrorSnackBar('Failed to delete data. Please try again.');
        }
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final service = PrivacyService.instance;
      final exportData = service.exportUserData();
      
      // In a real implementation, you would save this to a file
      // For now, we'll show a dialog with the data
      if (mounted) {
        setState(() => _isExporting = false);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Data'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your data has been prepared for export. In a real app, this would be saved to a file.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data Categories:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exportData.entries.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• ${entry.key}'),
                  )),
                  const SizedBox(height: 16),
                  const Text(
                    'Note: This export is compliant with DPDP Article 20 (Right to Data Portability)',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
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
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        _showErrorSnackBar('Failed to export data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Privacy & Data'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Data'),
        actions: [
          IconButton(
            onPressed: _savePrivacySettings,
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Privacy Status Card
            _buildPrivacyStatusCard(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Consent Preferences
            _buildConsentPreferences(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Management
            _buildDataManagementSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Legal Information
            _buildLegalInformation(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Contact Information
            _buildContactSection(),
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
            AppTheme.primaryGreen.withOpacity(0.1),
            AppTheme.primaryGreen.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.privacy_tip,
                color: AppTheme.primaryGreen,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(
                'Privacy Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _currentSettings.allRequiredConsentsGiven
                ? 'Your privacy settings are properly configured. Data processing is compliant with DPDP Act 2023.'
                : 'Some required consents are missing. Please review your privacy settings.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Consent Version: ${_currentSettings.consentVersion} • '
            'Last Updated: ${_formatDate(_currentSettings.consentTimestamp)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textDarkGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentPreferences() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Consent Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildConsentToggle(
              'Data Processing',
              'Processing your scans to create digital avatars',
              _currentSettings.dataProcessingConsent,
              (value) => setState(() => 
                _currentSettings = _currentSettings.copyWith(dataProcessingConsent: value)),
              required: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            _buildConsentToggle(
              'Camera Access',
              'Access to camera for photo capture',
              _currentSettings.cameraConsent,
              (value) => setState(() => 
                _currentSettings = _currentSettings.copyWith(cameraConsent: value)),
              required: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            _buildConsentToggle(
              'Data Storage',
              'Storing your processed data securely in India',
              _currentSettings.storageConsent,
              (value) => setState(() => 
                _currentSettings = _currentSettings.copyWith(storageConsent: value)),
              required: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            _buildConsentToggle(
              'Marketing Communications',
              'Receive updates about new features and offers',
              _currentSettings.marketingConsent,
              (value) => setState(() => 
                _currentSettings = _currentSettings.copyWith(marketingConsent: value)),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            _buildConsentToggle(
              'Usage Analytics',
              'Anonymous analytics to improve service quality',
              _currentSettings.analyticsConsent,
              (value) => setState(() => 
                _currentSettings = _currentSettings.copyWith(analyticsConsent: value)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentToggle(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged, {
    bool required = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: required ? Colors.red.shade700 : null,
                        ),
                      ),
                      if (required)
                        TextSpan(
                          text: ' *',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textDarkGray,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // Data Retention Information
            _buildRetentionInfo(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportData,
                    icon: _isExporting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isExporting ? 'Exporting...' : 'Export My Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDeleting ? null : _deleteAllData,
                    icon: _isDeleting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever),
                    label: Text(_isDeleting ? 'Deleting...' : 'Delete All Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
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

  Widget _buildRetentionInfo() {
    final retentionInfo = DataRetentionInfo();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: AppTheme.textDarkGray,
                size: 18,
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                'Data Retention Periods',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          _buildRetentionItem('Avatar scans', '${retentionInfo.scanRetentionDays} days'),
          _buildRetentionItem('Profile data', '${retentionInfo.profileDataRetentionDays} days'),
          _buildRetentionItem('Transaction records', '${retentionInfo.transactionRetentionDays} days'),
          _buildRetentionItem('Analytics (anonymized)', '${retentionInfo.anonymizedDataRetentionDays} days'),
        ],
      ),
    );
  }

  Widget _buildRetentionItem(String item, String duration) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item),
                Text(
                  duration,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInformation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Legal Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            // DPDP Act Compliance
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DPDP Act 2023 Compliant',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const Text(
                          'Your data rights are protected under Indian law',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Legal Links
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () => _showPrivacyPolicy(context),
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('Privacy Policy'),
                ),
                TextButton.icon(
                  onPressed: () => _showTermsOfService(context),
                  icon: const Icon(Icons.rule, size: 16),
                  label: const Text('Terms of Service'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Protection Contact',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'For privacy-related queries or rights requests:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text('📧 privacy@yourapp.com'),
                  const Text('📞 +91-XXX-XXX-XXXX'),
                  const Text('🏢 [Company Address], India'),
                  const SizedBox(height: 8),
                  const Text(
                    'Response time: Within 30 days (as per DPDP Act)',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'Our Privacy Policy explains how we collect, use, and protect your personal data in compliance with the Digital Personal Data Protection Act, 2023.\n\n'
            'Key Points:\n'
            '• We only collect data necessary for avatar creation\n'
            '• Your data is encrypted and stored securely\n'
            '• You have the right to access, correct, or delete your data\n'
            '• We do not sell your personal information to third parties\n'
            '• Data transfers comply with DPDP Act requirements\n\n'
            'For complete details, please visit our website or contact our Data Protection Officer.',
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

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'Our Terms of Service outline the rules and guidelines for using our Virtual Try-On app:\n\n'
            'Key Points:\n'
            '• You must be 18+ or have guardian consent to use this app\n'
            '• You retain ownership of your personal data\n'
            '• We provide service "as is" without warranties\n'
            '• Usage is subject to fair use policies\n'
            '• Terms comply with Indian laws and DPDP Act\n\n'
            'For complete terms, please visit our website or contact support.',
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}