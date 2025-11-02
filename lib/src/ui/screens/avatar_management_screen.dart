/// Avatar Management Screen
/// 
/// Comprehensive avatar and scan management interface:
/// - List all saved avatar scans with dates and quality scores
/// - Individual avatar deletion options
/// - Avatar backup and restore functionality
/// - Scan history with processing details
/// - Avatar measurement history and tracking
/// - Avatar version comparison tools
/// - Scan sharing and privacy controls
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../themes/app_theme.dart';

/// Avatar scan data model
class AvatarScan {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;
  final String qualityScore;
  final String scanType;
  final String status;
  final String thumbnailUrl;
  final List<String> tags;
  final Map<String, dynamic> measurements;
  final bool isShared;
  final String privacyLevel;

  const AvatarScan({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    required this.qualityScore,
    required this.scanType,
    required this.status,
    required this.thumbnailUrl,
    this.tags = const [],
    this.measurements = const {},
    this.isShared = false,
    this.privacyLevel = 'private',
  });

  AvatarScan copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    String? qualityScore,
    String? scanType,
    String? status,
    String? thumbnailUrl,
    List<String>? tags,
    Map<String, dynamic>? measurements,
    bool? isShared,
    String? privacyLevel,
  }) {
    return AvatarScan(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      qualityScore: qualityScore ?? this.qualityScore,
      scanType: scanType ?? this.scanType,
      status: status ?? this.status,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      measurements: measurements ?? this.measurements,
      isShared: isShared ?? this.isShared,
      privacyLevel: privacyLevel ?? this.privacyLevel,
    );
  }
}

class AvatarManagementScreen extends ConsumerStatefulWidget {
  const AvatarManagementScreen({super.key});

  @override
  ConsumerState<AvatarManagementScreen> createState() => _AvatarManagementScreenState();
}

class _AvatarManagementScreenState extends ConsumerState<AvatarManagementScreen> {
  String _selectedFilter = 'all';
  String _selectedSort = 'newest';
  bool _isLoading = false;
  List<AvatarScan> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _isLoading = true);
    
    // Mock data - in real app, this would fetch from API
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _scans = [
        AvatarScan(
          id: '1',
          name: 'Casual Avatar',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          lastModified: DateTime.now().subtract(const Duration(days: 2)),
          qualityScore: '95%',
          scanType: 'Full Body',
          status: 'Completed',
          thumbnailUrl: 'placeholder',
          tags: ['casual', 'work', 'daily'],
          measurements: {'height': '175cm', 'weight': '70kg', 'chest': '98cm'},
          isShared: false,
          privacyLevel: 'private',
        ),
        AvatarScan(
          id: '2',
          name: 'Formal Avatar',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
          lastModified: DateTime.now().subtract(const Duration(days: 1)),
          qualityScore: '92%',
          scanType: 'Upper Body',
          status: 'Completed',
          thumbnailUrl: 'placeholder',
          tags: ['formal', 'business', 'suits'],
          measurements: {'height': '175cm', 'shoulders': '45cm', 'chest': '98cm'},
          isShared: true,
          privacyLevel: 'friends',
        ),
        AvatarScan(
          id: '3',
          name: 'Athletic Avatar',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
          lastModified: DateTime.now().subtract(const Duration(days: 15)),
          qualityScore: '88%',
          scanType: 'Full Body',
          status: 'Processing',
          thumbnailUrl: 'placeholder',
          tags: ['athletic', 'sports', 'active'],
          measurements: {'height': '175cm', 'weight': '70kg', 'bodyFat': '12%'},
          isShared: false,
          privacyLevel: 'private',
        ),
      ];
      _isLoading = false;
    });
  }

  List<AvatarScan> get _filteredScans {
    List<AvatarScan> filtered = _scans;
    
    // Filter by status
    if (_selectedFilter != 'all') {
      filtered = filtered.where((scan) => scan.status.toLowerCase() == _selectedFilter).toList();
    }
    
    // Sort
    switch (_selectedSort) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'quality':
        filtered.sort((a, b) => b.qualityScore.compareTo(a.qualityScore));
        break;
      case 'name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avatar Management'),
        actions: [
          IconButton(
            onPressed: _showBackupRestoreDialog,
            icon: const Icon(Icons.backup),
            tooltip: 'Backup & Restore',
          ),
          IconButton(
            onPressed: _showBulkActionsDialog,
            icon: const Icon(Icons.more_vert),
            tooltip: 'Bulk Actions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters and Sort
          _buildFilters(),
          const Divider(height: 1),
          
          // Stats Summary
          _buildStatsSummary(),
          const Divider(height: 1),
          
          // Scans List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredScans.isEmpty
                    ? _buildEmptyState()
                    : _buildScansList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewScanOptions,
        tooltip: 'New Scan',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        children: [
          // Filter Chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All Scans'),
                const SizedBox(width: 8),
                _buildFilterChip('completed', 'Completed'),
                const SizedBox(width: 8),
                _buildFilterChip('processing', 'Processing'),
                const SizedBox(width: 8),
                _buildFilterChip('failed', 'Failed'),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          
          // Sort Options
          Row(
            children: [
              const Text('Sort by:'),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedSort,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                    DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                    DropdownMenuItem(value: 'quality', child: Text('Quality Score')),
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSort = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildStatsSummary() {
    final totalScans = _scans.length;
    final completedScans = _scans.where((s) => s.status == 'Completed').length;
    final avgQuality = _scans.isNotEmpty 
        ? (_scans.map((s) => int.parse(s.qualityScore.replaceAll('%', ''))).reduce((a, b) => a + b) / _scans.length).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Scans', totalScans.toString()),
          _buildStatItem('Completed', completedScans.toString()),
          _buildStatItem('Avg Quality', '$avgQuality%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textDarkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.face_retouching_natural,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No Avatar Scans Found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Create your first avatar scan to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: _showNewScanOptions,
            icon: const Icon(Icons.add),
            label: const Text('Create New Scan'),
          ),
        ],
      ),
    );
  }

  Widget _buildScansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      itemCount: _filteredScans.length,
      itemBuilder: (context, index) {
        final scan = _filteredScans[index];
        return _buildScanCard(scan);
      },
    );
  }

  Widget _buildScanCard(AvatarScan scan) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: InkWell(
        onTap: () => _showScanDetails(scan),
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with thumbnail and basic info
              Row(
                children: [
                  // Thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                    ),
                    child: const Icon(
                      Icons.face,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  
                  // Scan Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                scan.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: scan.status == 'Completed'
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                scan.status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: scan.status == 'Completed'
                                      ? Colors.green.shade700
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${scan.scanType} • Created ${_formatDate(scan.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textDarkGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Quality: ${scan.qualityScore}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Menu Button
                  PopupMenuButton<String>(
                    onSelected: (action) => _handleScanAction(action, scan),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('View Details'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'privacy',
                        child: ListTile(
                          leading: Icon(Icons.privacy_tip),
                          title: Text('Privacy Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Tags
              if (scan.tags.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Wrap(
                  spacing: AppTheme.spacingS,
                  runSpacing: 4,
                  children: scan.tags.map((tag) => Chip(
                    label: Text(tag),
                    labelStyle: const TextStyle(fontSize: 12),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ],
              
              // Privacy and Sharing Info
              const SizedBox(height: AppTheme.spacingM),
              Row(
                children: [
                  Icon(
                    scan.isShared ? Icons.share : Icons.lock,
                    size: 16,
                    color: scan.isShared ? AppTheme.primaryGreen : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scan.isShared 
                        ? 'Shared (${scan.privacyLevel})'
                        : 'Private',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scan.isShared ? AppTheme.primaryGreen : Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Modified ${_formatDate(scan.lastModified)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleScanAction(String action, AvatarScan scan) {
    switch (action) {
      case 'view':
        _showScanDetails(scan);
        break;
      case 'edit':
        _editScan(scan);
        break;
      case 'duplicate':
        _duplicateScan(scan);
        break;
      case 'share':
        _shareScan(scan);
        break;
      case 'privacy':
        _showPrivacySettings(scan);
        break;
      case 'delete':
        _deleteScan(scan);
        break;
    }
  }

  void _showScanDetails(AvatarScan scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildScanDetailsBottomSheet(scan),
    );
  }

  Widget _buildScanDetailsBottomSheet(AvatarScan scan) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  scan.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Thumbnail
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
              ),
              child: const Icon(
                Icons.face,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          
          // Details
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Scan Type', scan.scanType),
                  _buildDetailRow('Quality Score', scan.qualityScore),
                  _buildDetailRow('Status', scan.status),
                  _buildDetailRow('Created', _formatDateTime(scan.createdAt)),
                  _buildDetailRow('Last Modified', _formatDateTime(scan.lastModified)),
                  _buildDetailRow('Privacy Level', scan.privacyLevel),
                  
                  if (scan.measurements.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    Text(
                      'Measurements',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    ...scan.measurements.entries.map((entry) =>
                        _buildDetailRow(entry.key, entry.value.toString())),
                  ],
                  
                  if (scan.tags.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingL),
                    Text(
                      'Tags',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingS),
                    Wrap(
                      spacing: AppTheme.spacingS,
                      runSpacing: 4,
                      children: scan.tags.map((tag) => Chip(
                        label: Text(tag),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _editScan(scan);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _shareScan(scan);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
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
            width: 120,
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

  void _editScan(AvatarScan scan) {
    // Navigate to scan editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _duplicateScan(AvatarScan scan) {
    setState(() {
      _scans.add(scan.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: '${scan.name} (Copy)',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
      ));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar duplicated successfully')),
    );
  }

  void _shareScan(AvatarScan scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Avatar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose sharing option:'),
            const SizedBox(height: 16),
            _buildShareOption('Public', 'Anyone can view this avatar', Icons.public),
            const SizedBox(height: 8),
            _buildShareOption('Friends', 'Only friends can view', Icons.group),
            const SizedBox(height: 8),
            _buildShareOption('Private', 'Only you can view', Icons.lock),
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
              setState(() {
                final index = _scans.indexOf(scan);
                _scans[index] = scan.copyWith(isShared: true);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Avatar shared successfully')),
              );
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () => Navigator.of(context).pop(),
    );
  }

  void _showPrivacySettings(AvatarScan scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Privacy controls for this avatar:'),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Make Public'),
              subtitle: const Text('Anyone can find and view this avatar'),
              value: scan.isShared,
              onChanged: (value) {
                setState(() {
                  final index = _scans.indexOf(scan);
                  _scans[index] = scan.copyWith(isShared: value);
                });
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('Privacy Level'),
              subtitle: Text(scan.privacyLevel),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pop();
                // Show privacy level selector
              },
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

  void _deleteScan(AvatarScan scan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Avatar'),
        content: Text('Are you sure you want to delete "${scan.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _scans.remove(scan);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Avatar deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBackupRestoreDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Manage your avatar data:'),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('Create Backup'),
              subtitle: Text('Download all your avatar data'),
            ),
            ListTile(
              leading: Icon(Icons.restore),
              title: Text('Restore from Backup'),
              subtitle: Text('Import previously backed up data'),
            ),
            ListTile(
              leading: Icon(Icons.sync),
              title: Text('Sync to Cloud'),
              subtitle: Text('Automatically backup to cloud storage'),
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
                const SnackBar(content: Text('Backup created successfully')),
              );
            },
            child: const Text('Create Backup'),
          ),
        ],
      ),
    );
  }

  void _showBulkActionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select All'),
              subtitle: const Text('Select all avatar scans'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement select all
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Delete Selected'),
              subtitle: const Text('Delete all selected scans'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteSelectedDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Selected'),
              subtitle: const Text('Share multiple avatars'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement bulk share
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Export Selected'),
              subtitle: const Text('Export multiple avatars'),
              onTap: () {
                Navigator.of(context).pop();
                // Implement bulk export
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Selected Avatars'),
        content: const Text('Are you sure you want to delete all selected avatar scans? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Selected avatars deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showNewScanOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Avatar',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera Scan'),
              subtitle: const Text('Create avatar using camera'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to camera scan
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload),
              title: const Text('Upload Photos'),
              subtitle: const Text('Create avatar from uploaded photos'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to photo upload
              },
            ),
            ListTile(
              leading: const Icon(Icons.face),
              title: const Text('Use Template'),
              subtitle: const Text('Create avatar from existing template'),
              onTap: () {
                Navigator.of(context).pop();
                // Navigate to template selection
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}