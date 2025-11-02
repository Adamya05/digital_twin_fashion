/// Compliance & Legal Screen
/// 
/// Comprehensive legal and compliance interface:
/// - DPDP Act 2023 compliance controls
/// - Privacy policy and terms of service
/// - Data deletion requests system
/// - Compliance reports and transparency
/// - Data protection officer contact information
/// - Regulatory compliance status
/// - Rights request forms and procedures
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';

/// Data rights request model
class DataRightsRequest {
  final String id;
  final String type;
  final String status;
  final DateTime submittedAt;
  final DateTime? processedAt;
  final String description;
  final List<String> dataTypes;
  final String contactInfo;

  const DataRightsRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.submittedAt,
    this.processedAt,
    required this.description,
    required this.dataTypes,
    required this.contactInfo,
  });
}

/// Compliance report model
class ComplianceReport {
  final String id;
  final String type;
  final String title;
  final DateTime generatedAt;
  final String status;
  final String summary;
  final Map<String, dynamic> details;

  const ComplianceReport({
    required this.id,
    required this.type,
    required this.title,
    required this.generatedAt,
    required this.status,
    required this.summary,
    required this.details,
  });
}

/// Data protection officer information
class DataProtectionOfficer {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String qualifications;
  final List<String> responsibilities;

  const DataProtectionOfficer({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.qualifications,
    required this.responsibilities,
  });
}

class ComplianceLegalScreen extends ConsumerStatefulWidget {
  const ComplianceLegalScreen({super.key});

  @override
  ConsumerState<ComplianceLegalScreen> createState() => _ComplianceLegalScreenState();
}

class _ComplianceLegalScreenState extends ConsumerState<ComplianceLegalScreen> {
  bool _isLoading = true;
  List<DataRightsRequest> _requests = [];
  List<ComplianceReport> _reports = [];
  DataProtectionOfficer _dpo = const DataProtectionOfficer(
    name: 'Dr. Priya Sharma',
    email: 'dpo@yourapp.com',
    phone: '+91-98765-43210',
    address: 'Data Protection Office, Company Name, Bangalore, Karnataka, India',
    qualifications: 'Certified Data Protection Professional (CDPP), PhD in Data Law',
    responsibilities: [
      'Supervising compliance with DPDP Act 2023',
      'Managing data protection impact assessments',
      'Handling data subject rights requests',
      'Cooperating with regulatory authorities',
      'Training staff on data protection principles'
    ],
  );

  @override
  void initState() {
    super.initState();
    _loadComplianceData();
  }

  Future<void> _loadComplianceData() async {
    // Mock data - in real app, this would fetch from API
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _requests = [
        DataRightsRequest(
          id: 'REQ-001',
          type: 'Data Access',
          status: 'Completed',
          submittedAt: DateTime.now().subtract(const Duration(days: 5)),
          processedAt: DateTime.now().subtract(const Duration(days: 2)),
          description: 'Requested copy of personal data',
          dataTypes: ['Profile Information', 'Scan Data', 'Usage Analytics'],
          contactInfo: 'john.doe@example.com',
        ),
        DataRightsRequest(
          id: 'REQ-002',
          type: 'Data Deletion',
          status: 'Processing',
          submittedAt: DateTime.now().subtract(const Duration(days: 1)),
          description: 'Request to delete marketing data',
          dataTypes: ['Marketing Preferences', 'Communication History'],
          contactInfo: 'john.doe@example.com',
        ),
      ];

      _reports = [
        ComplianceReport(
          id: 'RPT-2024-Q1',
          type: 'Quarterly Compliance Report',
          title: 'Q1 2024 Data Protection Compliance Report',
          generatedAt: DateTime.now().subtract(const Duration(days: 30)),
          status: 'Published',
          summary: 'Quarterly report on data protection activities, incidents, and compliance metrics.',
          details: {
            'data_subjects_affected': 1247,
            'requests_processed': 15,
            'incidents_reported': 0,
            'compliance_score': 98.5,
            'key_improvements': [
              'Enhanced data encryption',
              'Improved consent management',
              'Staff training completion'
            ]
          },
        ),
        ComplianceReport(
          id: 'RPT-2024-DPIA',
          type: 'Data Protection Impact Assessment',
          title: 'Avatar Processing DPIA',
          generatedAt: DateTime.now().subtract(const Duration(days: 45)),
          status: 'Under Review',
          summary: 'Impact assessment for avatar processing activities.',
          details: {
            'risk_level': 'Medium',
            'mitigation_measures': 8,
            'recommendations': 3,
            'approval_status': 'Pending'
          },
        ),
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compliance & Legal'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compliance & Legal'),
        actions: [
          IconButton(
            onPressed: _showComplianceGuide,
            icon: const Icon(Icons.help_outline),
            tooltip: 'Compliance Guide',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compliance Status Overview
            _buildComplianceOverview(),
            const SizedBox(height: AppTheme.spacingL),
            
            // DPDP Act Compliance Section
            _buildDPDPComplianceSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Rights Section
            _buildDataRightsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Legal Documents Section
            _buildLegalDocumentsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Compliance Reports Section
            _buildComplianceReportsSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Data Protection Officer Section
            _buildDataProtectionOfficerSection(),
            const SizedBox(height: AppTheme.spacingL),
            
            // Contact & Support Section
            _buildContactSupportSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceOverview() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade400,
            Colors.green.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Compliance Status',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'DPDP Act 2023 Compliant',
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
                  'COMPLIANT',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewStat('Compliance Score', '98.5%'),
              _buildOverviewStat('Active Requests', _requests.length.toString()),
              _buildOverviewStat('Reports Generated', _reports.length.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
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

  Widget _buildDPDPComplianceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('DPDP Act 2023 Compliance', Icons.gavel, color: Colors.blue),
            const SizedBox(height: AppTheme.spacingM),
            
            // Compliance Certificate
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
                    Icons.verified,
                    color: Colors.blue.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DPDP Act 2023 Certified',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        Text(
                          'Full compliance with Digital Personal Data Protection Act 2023',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Key Principles
            const Text(
              'Data Protection Principles:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ...[
              'Consent-based processing',
              'Purpose limitation',
              'Data minimization',
              'Accuracy maintenance',
              'Storage limitation',
              'Security safeguards',
              'Accountability and transparency'
            ].map((principle) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(principle)),
                ],
              ),
            )),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Compliance Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDPDPRequirements,
                    icon: const Icon(Icons.description),
                    label: const Text('View Requirements'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showComplianceDocumentation,
                    icon: const Icon(Icons.folder),
                    label: const Text('Documentation'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Subject Rights', Icons.shield),
            const SizedBox(height: AppTheme.spacingM),
            
            // Rights Summary
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Data Rights Under DPDP Act 2023:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildRightItem('Right to Access', 'Know what personal data we have about you'),
                  _buildRightItem('Right to Correction', 'Correct inaccurate personal data'),
                  _buildRightItem('Right to Erasure', 'Request deletion of your personal data'),
                  _buildRightItem('Right to Data Portability', 'Export your data in machine-readable format'),
                  _buildRightItem('Right to Grievance', 'File complaints about data processing'),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Submit Request Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitDataRightsRequest,
                icon: const Icon(Icons.send),
                label: const Text('Submit Rights Request'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Recent Requests
            if (_requests.isNotEmpty) ...[
              const Text(
                'Recent Requests:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ..._requests.take(2).map((request) => _buildRequestItem(request)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRightItem(String right, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  right,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestItem(DataRightsRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.type} Request',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: request.status == 'Completed' 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: request.status == 'Completed' 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ID: ${request.id} • Submitted ${_formatDate(request.submittedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            request.description,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalDocumentsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Legal Documents', Icons.description),
            const SizedBox(height: AppTheme.spacingM),
            
            // Document List
            _buildDocumentTile(
              'Privacy Policy',
              'How we collect, use, and protect your personal data',
              Icons.privacy_tip,
              () => _showPrivacyPolicy(),
            ),
            const Divider(height: 1),
            _buildDocumentTile(
              'Terms of Service',
              'Terms and conditions for using our services',
              Icons.rule,
              () => _showTermsOfService(),
            ),
            const Divider(height: 1),
            _buildDocumentTile(
              'DPDP Act Compliance',
              'Data protection compliance documentation',
              Icons.gavel,
              () => _showDPDPCompliance(),
            ),
            const Divider(height: 1),
            _buildDocumentTile(
              'Cookie Policy',
              'Information about our use of cookies',
              Icons.cookie,
              () => _showCookiePolicy(),
            ),
            const Divider(height: 1),
            _buildDocumentTile(
              'Data Processing Agreement',
              'Legal agreement for data processing activities',
              Icons.assignment,
              () => _showDataProcessingAgreement(),
            ),
            const Divider(height: 1),
            _buildDocumentTile(
              'User Consent Forms',
              'Consent forms for data collection and processing',
              Icons.check_circle,
              () => _showConsentForms(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildComplianceReportsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Compliance Reports', Icons.analytics),
            const SizedBox(height: AppTheme.spacingM),
            
            // Reports List
            ..._reports.map((report) => _buildReportTile(report)),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Generate Report Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generateCustomReport,
                icon: const Icon(Icons.add),
                label: const Text('Generate Custom Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile(ComplianceReport report) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: report.status == 'Published' 
                      ? Colors.green.shade100 
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: report.status == 'Published' 
                        ? Colors.green.shade700 
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            report.summary,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Generated: ${_formatDate(report.generatedAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _viewReport(report),
                  child: const Text('View Report'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _downloadReport(report),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Download'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataProtectionOfficerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Data Protection Officer', Icons.person),
            const SizedBox(height: AppTheme.spacingM),
            
            // DPO Info
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _dpo.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _dpo.qualifications,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textDarkGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Contact Information
            _buildContactInfo('Email', _dpo.email, Icons.email),
            const SizedBox(height: AppTheme.spacingS),
            _buildContactInfo('Phone', _dpo.phone, Icons.phone),
            const SizedBox(height: AppTheme.spacingS),
            _buildContactInfo('Address', _dpo.address, Icons.location_on),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Responsibilities
            const Text(
              'Key Responsibilities:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingS),
            ..._dpo.responsibilities.map((responsibility) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(responsibility)),
                ],
              ),
            )),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Contact Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _contactDPO('email'),
                    icon: const Icon(Icons.email),
                    label: const Text('Email DPO'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _contactDPO('phone'),
                    icon: const Icon(Icons.phone),
                    label: const Text('Call DPO'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildContactSupportSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Contact & Support', Icons.contact_support),
            const SizedBox(height: AppTheme.spacingM),
            
            // Emergency Contact
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emergency,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Breach Hotline',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        Text(
                          '+91-XXX-XXX-XXXX (24/7)',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Support Channels
            _buildSupportChannel('Email Support', 'compliance@yourapp.com', Icons.email),
            const Divider(height: 1),
            _buildSupportChannel('Phone Support', '+91-XXX-XXX-XXXX', Icons.phone),
            const Divider(height: 1),
            _buildSupportChannel('Live Chat', 'Available 9 AM - 6 PM IST', Icons.chat),
            const Divider(height: 1),
            _buildSupportChannel('Help Center', 'help.yourapp.com', Icons.help_center),
            
            const SizedBox(height: AppTheme.spacingM),
            
            // Response Times
            const Text(
              'Expected Response Times:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingS),
            _buildResponseTime('Data Rights Requests', 'Within 30 days (DPDP Act requirement)'),
            _buildResponseTime('Privacy Complaints', 'Within 30 days'),
            _buildResponseTime('Data Breach Reports', 'Within 72 hours'),
            _buildResponseTime('General Inquiries', 'Within 48 hours'),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportChannel(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Implement channel-specific actions
      },
    );
  }

  Widget _buildResponseTime(String request, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              request,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              time,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // Event handlers
  void _showDPDPRequirements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('DPDP Act Requirements'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Digital Personal Data Protection Act 2023 Requirements:'),
              SizedBox(height: 8),
              Text('• Obtain valid consent before processing personal data'),
              Text('• Ensure data is used only for specified purposes'),
              Text('• Implement appropriate security measures'),
              Text('• Provide data subject rights as specified in the Act'),
              Text('• Maintain records of processing activities'),
              Text('• Report data breaches within 72 hours'),
              Text('• Cooperate with the Data Protection Board'),
              Text('• Conduct Data Protection Impact Assessments when required'),
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

  void _showComplianceDocumentation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening compliance documentation')),
    );
  }

  void _submitDataRightsRequest() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submit Data Rights Request',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            // Form fields would go here
            const TextField(
              decoration: InputDecoration(
                labelText: 'Request Type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Contact Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request submitted successfully')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Our Privacy Policy'),
              SizedBox(height: 16),
              Text(
                'We are committed to protecting your privacy and ensuring compliance with the Digital Personal Data Protection Act, 2023 (DPDP Act). This policy explains how we collect, use, store, and protect your personal data.',
              ),
              SizedBox(height: 16),
              Text(
                'Key Points:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Data is processed only with your consent'),
              Text('• You have the right to access, correct, and delete your data'),
              Text('• Data is stored securely in India'),
              Text('• We do not sell your personal information'),
              Text('• You can withdraw consent at any time'),
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

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Terms of Service'),
              SizedBox(height: 16),
              Text(
                'These terms govern your use of our Virtual Try-On application and services.',
              ),
              SizedBox(height: 16),
              Text(
                'Key Terms:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• You must be 18+ or have guardian consent'),
              Text('• You own your personal data'),
              Text('• Service is provided "as is"'),
              Text('• Fair use policies apply'),
              Text('• Indian law governs these terms'),
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

  void _showDPDPCompliance() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening DPDP compliance documentation')),
    );
  }

  void _showCookiePolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening cookie policy')),
    );
  }

  void _showDataProcessingAgreement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening data processing agreement')),
    );
  }

  void _showConsentForms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening consent forms')),
    );
  }

  void _generateCustomReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating custom compliance report')),
    );
  }

  void _viewReport(ComplianceReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Report Details:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(report.summary),
              const SizedBox(height: 16),
              Text(
                'Generated: ${_formatDate(report.generatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...report.details.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${entry.key}: ${entry.value}'),
              )),
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

  void _downloadReport(ComplianceReport report) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report downloaded successfully')),
    );
  }

  void _contactDPO(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${method} to contact DPO')),
    );
  }

  void _showComplianceGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compliance Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Data Protection Compliance Guide'),
              SizedBox(height: 16),
              Text(
                'This section helps you understand your rights and our compliance obligations under the DPDP Act 2023.',
              ),
              SizedBox(height: 16),
              Text(
                'Quick Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Submit data rights requests'),
              View compliance reports'),
              Text('• Contact our Data Protection Officer'),
              Text('• Access legal documentation'),
              SizedBox(height: 16),
              Text(
                'Need Help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Contact our support team for assistance with data protection matters.'),
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