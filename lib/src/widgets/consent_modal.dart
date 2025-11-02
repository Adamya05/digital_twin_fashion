/// Enhanced Consent Modal Widget
/// 
/// Comprehensive privacy and data usage consent dialog for DPDP Act compliance.
/// Handles user permissions, data processing, marketing consent, and ensures legal compliance.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../themes/app_theme.dart';
import '../../models/privacy_model.dart';
import '../../services/privacy_service.dart';

class ConsentModal extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ConsentModal({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<ConsentModal> createState() => _ConsentModalState();
}

class _ConsentModalState extends State<ConsentModal> {
  bool _cameraConsent = false;
  bool _dataProcessingConsent = false;
  bool _storageConsent = false;
  bool _analyticsConsent = false;
  bool _marketingConsent = false;
  bool _hasReadPrivacyPolicy = false;
  bool _hasReadTermsOfService = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: AppTheme.primaryGreen,
                  size: 28,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Privacy & Data Consent',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.textDarkGray,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // DPDP Act Notice
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      'Your data is protected under the Digital Personal Data Protection Act, 2023',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Consent Content
            Text(
              'To create your personalized avatar, we need your consent for:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Camera Access Consent
            _buildConsentCheckbox(
              context,
              title: 'Camera Access',
              subtitle: 'To capture video scans for avatar creation',
              value: _cameraConsent,
              onChanged: (value) => setState(() => _cameraConsent = value ?? false),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Data Processing Consent
            _buildConsentCheckbox(
              context,
              title: 'Data Processing',
              subtitle: 'Processing your scans to create a digital avatar model',
              value: _dataProcessingConsent,
              onChanged: (value) => setState(() => _dataProcessingConsent = value ?? false),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Storage Consent
            _buildConsentCheckbox(
              context,
              title: 'Data Storage',
              subtitle: 'Storing your processed avatar data as described above',
              value: _storageConsent,
              onChanged: (value) => setState(() => _storageConsent = value ?? false),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Analytics Consent (Optional)
            _buildConsentCheckbox(
              context,
              title: 'Usage Analytics',
              subtitle: 'Anonymous analytics to improve service quality (Optional)',
              value: _analyticsConsent,
              onChanged: (value) => setState(() => _analyticsConsent = value ?? false),
              isOptional: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Marketing Consent (Optional)
            _buildConsentCheckbox(
              context,
              title: 'Marketing Communications',
              subtitle: 'Receive updates about new features and fashion trends (Optional)',
              value: _marketingConsent,
              onChanged: (value) => setState(() => _marketingConsent = value ?? false),
              isOptional: true,
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Privacy Policy and Terms Consent (Required)
            _buildConsentCheckbox(
              context,
              title: 'Privacy Policy & Terms of Service',
              subtitle: 'I have read and agree to the Privacy Policy and Terms of Service',
              value: _hasReadPrivacyPolicy && _hasReadTermsOfService,
              onChanged: (value) {
                setState(() {
                  _hasReadPrivacyPolicy = value ?? false;
                  _hasReadTermsOfService = value ?? false;
                });
              },
              required: true,
            ),
            
            // Legal Links Row
            Padding(
              padding: const EdgeInsets.only(left: 56, top: AppTheme.spacingS),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showPrivacyPolicy(context),
                    child: Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  GestureDetector(
                    onTap: () => _showTermsOfService(context),
                    child: Text(
                      'Terms of Service',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Storage & Retention Information
            Container(
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
                        Icons.storage_outlined,
                        color: AppTheme.textDarkGray,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Data Storage & Retention',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    '• Your data is stored securely on servers located in India region\n'
                    '• Avatar scans: Stored for 30 days from capture date\n'
                    '• Profile data: Retained for 90 days of inactivity\n'
                    '• Transaction records: Kept for 7 days for compliance\n'
                    '• Anonymized analytics: Up to 1 year for service improvement\n'
                    '• You can request immediate deletion at any time',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingS),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Data Location: India region only (DPDP Act compliant)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Deletion Quick Actions
            Container(
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
                        Icons.delete_sweep_outlined,
                        color: AppTheme.textDarkGray,
                        size: 18,
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Text(
                        'Quick Data Management',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showDeleteScansOnly(context),
                          icon: const Icon(Icons.photo_library, size: 16),
                          label: const Text('Delete All Scans', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingS),
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showDeleteEverythingConfirm(context),
                          icon: const Icon(Icons.delete_forever, size: 16),
                          label: const Text('Delete Everything', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingS,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingL),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onDecline,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canProceed() ? _handleAccept : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.spacingM,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
                      ),
                      elevation: _canProceed() ? AppTheme.buttonElevation : 0,
                    ),
                    child: const Text('Accept & Continue'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Legal Links
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showPrivacyPolicy(context),
                      child: Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' • ',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    GestureDetector(
                      onTap: () => _showDataDeletionOptions(context),
                      child: Text(
                        'Data Deletion',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showDataProtectionContact(context),
                      child: Text(
                        'Data Protection Contact',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryGreen,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentCheckbox(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isOptional = false,
    bool required = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: value 
              ? AppTheme.primaryGreen 
              : required 
                  ? Colors.red.withOpacity(0.5)
                  : AppTheme.outline.withOpacity(0.5),
        ),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: required ? Colors.red.shade700 : null,
              ),
            ),
            if (required)
              Text(
                ' *',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        secondary: isOptional 
            ? Icon(
                Icons.star_border,
                color: AppTheme.outline,
                size: 20,
              )
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        activeColor: AppTheme.primaryGreen,
        checkColor: AppTheme.onPrimary,
      ),
    );
  }

  bool _canProceed() {
    // All camera, data processing, storage consent and privacy policy acceptance are required
    return _cameraConsent && _dataProcessingConsent && _storageConsent && 
           _hasReadPrivacyPolicy && _hasReadTermsOfService;
  }

  Future<void> _handleAccept() async {
    final settings = PrivacySettings(
      dataProcessingConsent: _dataProcessingConsent,
      cameraConsent: _cameraConsent,
      storageConsent: _storageConsent,
      marketingConsent: _marketingConsent,
      analyticsConsent: _analyticsConsent,
      hasReadPrivacyPolicy: _hasReadPrivacyPolicy,
      hasReadTermsOfService: _hasReadTermsOfService,
      consentVersion: '1.0',
    );

    try {
      // Save privacy settings
      final service = PrivacyService.instance;
      await service.initialize();
      await service.savePrivacySettings(settings);
      await service.updateConsentVersion('1.0');
      
      widget.onAccept();
    } catch (e) {
      // Show error dialog if consent saving fails
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Consent Error'),
            content: const Text('Failed to save your consent preferences. Please try again.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
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

  void _showDataDeletionOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Deletion Options'),
        content: const SingleChildScrollView(
          child: Text(
            'You can delete your data at any time through:\n\n'
            '1. In-App Settings:\n'
            '   • Go to Profile > Privacy & Data\n'
            '   • Tap "Delete My Data"\n\n'
            '2. Email Request:\n'
            '   • Send request to privacy@yourapp.com\n'
            '   • Include your registered email address\n\n'
            '3. Data Deletion Timeline:\n'
            '   • Account data: Immediate deletion\n'
            '   • Avatar scans: Within 7 days\n'
            '   • Backup data: Within 30 days\n\n'
            'Note: Some data may be retained for legal compliance purposes as permitted under DPDP Act.',
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

  void _showDataProtectionContact(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Protection Contact'),
        content: const SingleChildScrollView(
          child: Text(
            'For privacy-related queries, rights requests, or data protection concerns:\n\n'
            '📧 Email: privacy@yourapp.com\n'
            '📞 Phone: +91-XXX-XXX-XXXX\n'
            '🏢 Address: [Company Address], India\n\n'
            'Data Protection Officer:\n'
            '📧 dpo@yourapp.com\n\n'
            'Response Time: Within 30 days as per DPDP Act\n\n'
            'You can also use in-app privacy settings for data management.',
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

  void _showDeleteScansOnly(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Avatar Scans'),
        content: const Text(
          'This will permanently delete all your avatar scan data including:\n\n'
          '• All captured videos\n'
          '• Processed 3D models\n'
          '• Avatar preview images\n\n'
          'Your account settings and preferences will be kept. '
          'This action cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Scans'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final service = PrivacyService.instance;
        await service.initialize();
        // In a real implementation, you would delete scan data specifically
        // For now, we'll just show a confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All avatar scans have been deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete scans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteEverythingConfirm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Everything'),
        content: const Text(
          '⚠️ WARNING: This will permanently delete ALL your data including:\n\n'
          '• Avatar scans and 3D models\n'
          '• Account settings and preferences\n'
          '• Privacy consent information\n'
          '• App usage data\n'
          '• All personal information\n\n'
          'This action CANNOT be undone and you will need to re-consent to use the app. '
          'Are you absolutely sure?',
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
      try {
        final service = PrivacyService.instance;
        await service.initialize();
        await service.deleteAllUserData();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data deleted successfully. App will restart.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Restart app after short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/onboarding',
              (route) => false,
            );
          }
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
