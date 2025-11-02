/// Profile Screen
/// 
/// Comprehensive user profile interface with avatar snapshot,
/// saved looks management, user statistics, and engagement features.
/// Includes privacy settings access for DPDP Act compliance.
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../../../themes/app_theme.dart';
import '../../models/avatar_model.dart';
import '../../models/saved_look_model.dart';
import '../../models/user_statistics_model.dart';
import '../../widgets/avatar_canvas.dart';
import 'privacy_settings_screen.dart';
import 'scan_wizard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Mock data for demonstration
  final Avatar _currentAvatar = _getMockAvatar();
  final List<SavedLook> _savedLooks = _getMockSavedLooks();
  final UserStatistics _userStats = _getMockUserStatistics();
  final ProfileCompletion _profileCompletion = ProfileCompletion(
    overallPercentage: 75.0,
    sectionCompletion: {
      'avatar': 100.0,
      'basic_info': 80.0,
      'preferences': 60.0,
      'saved_items': 90.0,
      'saved_looks': 100.0,
      'reviews': 50.0,
    },
    missingItems: ['preferences', 'reviews'],
    suggestions: [
      'Set your style preferences for personalized recommendations',
      'Leave reviews to help other users',
    ],
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: AppTheme.onPrimary,
        elevation: AppTheme.appBarElevation,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Profile'),
            Tab(icon: Icon(Icons.favorite), text: 'Saved Looks'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProfileTab(),
          _buildSavedLooksTab(),
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: AppTheme.spacingL),
          _buildProfileCompletion(),
          const SizedBox(height: AppTheme.spacingL),
          _buildAvatarSection(),
          const SizedBox(height: AppTheme.spacingL),
          _buildQuickActions(),
          const SizedBox(height: AppTheme.spacingL),
          _buildRecentActivity(),
          const SizedBox(height: AppTheme.spacingL),
          _buildProfileOptions(),
          const SizedBox(height: AppTheme.spacingL),
          _buildPrivacySection(),
          const SizedBox(height: AppTheme.spacingL),
          _buildAccountSettings(),
        ],
      ),
    );
  }

  Widget _buildSavedLooksHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text(
            'Saved Looks',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _filterLooks,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter looks',
          ),
          IconButton(
            onPressed: _createNewLook,
            icon: const Icon(Icons.add),
            tooltip: 'Create new look',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyLooksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.style,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No saved looks yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Start creating outfit combinations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          ElevatedButton.icon(
            onPressed: _createNewLook,
            icon: const Icon(Icons.add),
            label: const Text('Create Your First Look'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedLooksGrid() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingL),
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _savedLooks.length,
        itemBuilder: (context, index) {
          final look = _savedLooks[index];
          return _buildLookCard(look);
        },
      ),
    );
  }

  Widget _buildLookCard(SavedLook look) {
    return Card(
      elevation: AppTheme.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.mediumRadius),
                ),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: look.thumbnailUrl != null
                      ? Image.network(
                          look.thumbnailUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.style,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    _buildMetricChip(
                      '${look.performance.tryOnCount}',
                      Icons.photo_camera,
                      Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    if (look.isFavorite)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    look.category.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  look.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${look.totalPrice.toStringAsFixed(0)} • ${look.items.length} items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(look.updatedAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLookActions(look),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookActions(SavedLook look) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLookAction(
          'Edit',
          Icons.edit,
          Colors.blue,
          () => _editLook(look),
        ),
        _buildLookAction(
          'Try',
          Icons.photo_camera,
          Colors.green,
          () => _tryOnLook(look),
        ),
        _buildLookAction(
          'Share',
          Icons.share,
          Colors.orange,
          () => _shareLook(look),
        ),
        _buildLookAction(
          'More',
          Icons.more_vert,
          Colors.grey,
          () => _showLookOptions(look),
        ),
      ],
    );
  }

  Widget _buildLookAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltySection() {
    final tier = _userStats.loyaltyTier;
    final nextTier = _userStats.nextTier;
    final pointsToNext = _userStats.pointsToNextTier;

    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Color(tier.primaryColor),
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tier.emoji} ${tier.displayName} Member',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_userStats.loyaltyPoints.toInt()} loyalty points',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(tier.secondaryColor),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tier ${tier.name}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(tier.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
            if (tier != LoyaltyTier.diamond) ...[
              const SizedBox(height: AppTheme.spacingM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${nextTier.emoji} ${nextTier.displayName} Progress',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '${pointsToNext.toInt()} points to go',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Color(tier.primaryColor),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _userStats.loyaltyPoints / nextTier.minPoints,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(Color(tier.primaryColor)),
              ),
            ],
            const SizedBox(height: AppTheme.spacingM),
            _buildLoyaltyBenefits(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyBenefits() {
    final benefits = [
      'Free shipping on orders over ₹999',
      'Early access to sales',
      'Exclusive member discounts',
      'Birthday rewards',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits:',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...benefits.map((benefit) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                benefit,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Journey',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Spent',
                  '₹${_userStats.totalSpent.toStringAsFixed(0)}',
                  Icons.shopping_cart,
                  Colors.green,
                  'Avg: ₹${_userStats.averageOrderValue.toStringAsFixed(0)}/order',
                ),
                _buildStatCard(
                  'Items Saved',
                  '${_userStats.totalSavedItems}',
                  Icons.favorite,
                  Colors.pink,
                  'in your closet',
                ),
                _buildStatCard(
                  'Looks Created',
                  '${_userStats.totalSavedLooks}',
                  Icons.style,
                  Colors.purple,
                  'outfit combinations',
                ),
                _buildStatCard(
                  'Try Ons',
                  '${_userStats.totalTryOns}',
                  Icons.photo_camera,
                  Colors.blue,
                  'virtual try-ons',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection() {
    final achievements = _getMockAchievements();

    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${achievements.where((a) => a.isUnlocked).length}/${achievements.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: AppTheme.spacingS,
                mainAxisSpacing: AppTheme.spacingS,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementBadge(achievement);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementBadge(AchievementBadge badge) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: badge.isUnlocked ? Colors.amber.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
        border: Border.all(
          color: badge.isUnlocked ? Colors.amber : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: badge.isUnlocked ? Colors.amber : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                badge.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            badge.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (!badge.isUnlocked)
            Text(
              '${badge.currentCount}/${badge.requirementCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferencesBreakdown() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildPreferenceSection(
              'Favorite Brands',
              _userStats.favoriteBrands,
              Icons.store,
              Colors.blue,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildPreferenceSection(
              'Preferred Categories',
              _userStats.favoriteCategories,
              Icons.category,
              Colors.green,
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildPreferenceSection(
              'Preferred Colors',
              _userStats.preferredColors,
              Icons.palette,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSection(String title, List<String> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.take(5).map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildActivityFeed() {
    final activities = _userStats.recentActivity;

    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Feed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            if (activities.isEmpty)
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              )
            else
              ...List.generate(
                activities.length.clamp(0, 10),
                (index) => _buildFeedItem(activities[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(ActivityFeedItem activity) {
    final icons = {
      'purchase': Icons.shopping_bag,
      'save_look': Icons.favorite,
      'try_on': Icons.photo_camera,
      'review': Icons.rate_review,
      'share': Icons.share,
    };

    final icon = icons[activity.type] ?? Icons.info;
    final colors = {
      'purchase': Colors.green,
      'save_look': Colors.pink,
      'try_on': Colors.blue,
      'review': Colors.orange,
      'share': Colors.purple,
    };

    final color = colors[activity.type] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatRelativeTime(activity.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: AppTheme.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.primaryGreen.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _showAvatarPreview,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(
                        'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150&h=150&fit=crop&crop=face',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sarah Johnson',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'sarah.j@email.com',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Member since Mar 2024',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildLoyaltyBadge(),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildUserStatsRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyBadge() {
    final tier = _userStats.loyaltyTier;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tier.emoji,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 4),
          Text(
            tier.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMiniStat('Items', '${_userStats.totalSavedItems}', Icons.favorite),
        _buildMiniStat('Looks', '${_userStats.totalSavedLooks}', Icons.style),
        _buildMiniStat('Orders', '${_userStats.totalOrders}', Icons.shopping_bag),
        _buildMiniStat('Points', '${_userStats.loyaltyPoints.toInt()}', Icons.stars),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCompletion() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Profile Completion',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_profileCompletion.overallPercentage.toInt()}%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            LinearProgressIndicator(
              value: _profileCompletion.overallPercentage / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            if (_profileCompletion.suggestions.isNotEmpty) ...[
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Suggestions:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              ..._profileCompletion.suggestions.map((suggestion) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.face,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Text(
                    'Digital Avatar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _rescanAvatar,
                  icon: const Icon(Icons.photo_camera, size: 16),
                  label: const Text('Re-scan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                GestureDetector(
                  onTap: _showAvatarPreview,
                  child: Container(
                    width: 100,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=200&h=200&fit=crop',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentAvatar.name.isNotEmpty ? _currentAvatar.name : 'Current Avatar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Last updated: ${_formatDate(_currentAvatar.updatedAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quality Score: ${_currentAvatar.metadata.qualityLevel}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingS),
                      Row(
                        children: [
                          _buildAvatarMetric('Height', '${_currentAvatar.measurements.height.toInt()}cm'),
                          const SizedBox(width: 8),
                          _buildAvatarMetric('Weight', '${_currentAvatar.measurements.weight.toInt()}kg'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            _buildAvatarVersionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarMetric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarVersionHistory() {
    final versions = _getMockAvatarVersions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version History',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingS),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: versions.length,
            itemBuilder: (context, index) {
              final version = versions[index];
              return GestureDetector(
                onTap: () => _showAvatarComparison(version),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 60,
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: version.isActive 
                                ? AppTheme.primaryGreen 
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            version.thumbnailUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        version.name,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: AppTheme.spacingM,
              mainAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 1.2,
              children: [
                _buildQuickActionButton(
                  'Edit Profile',
                  Icons.edit,
                  Colors.blue,
                  _editProfile,
                ),
                _buildQuickActionButton(
                  'Try On',
                  Icons.photo_camera,
                  Colors.purple,
                  _tryOnSavedLook,
                ),
                _buildQuickActionButton(
                  'Scan Avatar',
                  Icons.face_scanning,
                  Colors.green,
                  _rescanAvatar,
                ),
                _buildQuickActionButton(
                  'Share Profile',
                  Icons.share,
                  Colors.orange,
                  _shareProfile,
                ),
                _buildQuickActionButton(
                  'Invite Friends',
                  Icons.group_add,
                  Colors.teal,
                  _inviteFriends,
                ),
                _buildQuickActionButton(
                  'Support',
                  Icons.help,
                  Colors.red,
                  _contactSupport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
    return Card(
      elevation: AppTheme.cardElevation,
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.favorite,
            title: 'Saved Looks',
            subtitle: '${_savedLooks.length} outfit combinations',
            onTap: () => _tabController.animateTo(1),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.shopping_bag,
            title: 'Purchase History',
            subtitle: '${_userStats.totalOrders} orders • ₹${_userStats.totalSpent.toStringAsFixed(0)} spent',
            onTap: () {
              // Navigate to purchase history
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.inventory,
            title: 'My Closet',
            subtitle: '${_userStats.totalSavedItems} items saved',
            onTap: () {
              // Navigate to closet
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.settings,
            title: 'Preferences',
            subtitle: 'Style preferences and settings',
            onTap: () {
              // Navigate to app preferences
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: AppTheme.cardElevation,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timeline,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _tabController.animateTo(2),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ...List.generate(5, (index) => _buildActivityItem(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(int index) {
    final activities = [
      {'icon': Icons.favorite, 'title': 'Liked an outfit', 'time': '2h ago', 'color': Colors.pink},
      {'icon': Icons.shopping_bag, 'title': 'Made a purchase', 'time': '1d ago', 'color': Colors.green},
      {'icon': Icons.photo_camera, 'title': 'Tried on 3 items', 'time': '2d ago', 'color': Colors.blue},
      {'icon': Icons.style, 'title': 'Created new look', 'time': '3d ago', 'color': Colors.purple},
      {'icon': Icons.share, 'title': 'Shared an outfit', 'time': '1w ago', 'color': Colors.orange},
    ];
    
    final activity = activities[index % activities.length];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  activity['time'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  }

  Widget _buildPrivacySection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                Icon(
                  Icons.privacy_tip,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingM),
                Text(
                  'Privacy & Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Privacy Settings',
            subtitle: 'Manage your data and privacy preferences',
            onTap: () => _navigateToPrivacySettings(),
            trailing: Icon(
              Icons.verified_user,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.delete,
            title: 'Data Deletion',
            subtitle: 'Request deletion of your personal data',
            onTap: () => _navigateToPrivacySettings(),
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.download,
            title: 'Export My Data',
            subtitle: 'Download your personal data',
            onTap: () => _navigateToPrivacySettings(),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingS),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data is protected under DPDP Act 2023',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // Navigate to help
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.rate_review,
            title: 'Rate App',
            subtitle: 'Share your feedback',
            onTap: () {
              // Navigate to app rating
            },
          ),
          const Divider(height: 1),
          _buildListTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () => _showSignOutDialog(),
            iconColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppTheme.textDarkGray,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Profile Actions
  void _showAvatarPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvatarPreviewModal(),
    );
  }

  Widget _buildAvatarPreviewModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: AvatarCanvas(
              avatar: _currentAvatar,
              onStateChanged: (state) => print('Avatar state: $state'),
            ),
          ),
          _buildAvatarControls(),
        ],
      ),
    );
  }

  Widget _buildAvatarControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _shareAvatar,
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rescanAvatar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ScanWizard(),
      ),
    );
  }

  void _shareAvatar() {
    // Implement avatar sharing
  }

  void _showAvatarComparison(AvatarVersion version) {
    // Show before/after comparison
  }

  void _editProfile() {
    // Navigate to edit profile
  }

  void _tryOnSavedLook() {
    _tabController.animateTo(1);
  }

  void _shareProfile() {
    // Implement profile sharing
  }

  void _inviteFriends() {
    // Implement invite friends
  }

  void _contactSupport() {
    // Navigate to support
  }

  void _openSettings() {
    // Navigate to settings
  }

  // Saved Look Actions
  void _createNewLook() {
    // Navigate to create look flow
  }

  void _filterLooks() {
    // Show filter options
  }

  void _editLook(SavedLook look) {
    // Navigate to edit look
  }

  void _tryOnLook(SavedLook look) {
    // Navigate to try-on with this look
  }

  void _shareLook(SavedLook look) {
    // Share this look
  }

  void _showLookOptions(SavedLook look) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildLookOptionsSheet(look),
    );
  }

  Widget _buildLookOptionsSheet(SavedLook look) {
    final actions = [
      {'icon': Icons.edit, 'label': 'Edit', 'color': Colors.blue},
      {'icon': Icons.copy, 'label': 'Duplicate', 'color': Colors.green},
      {'icon': Icons.favorite, 'label': 'Favorite', 'color': Colors.pink},
      {'icon': Icons.share, 'label': 'Share', 'color': Colors.orange},
      {'icon': Icons.delete, 'label': 'Delete', 'color': Colors.red},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            look.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...actions.map((action) => ListTile(
            leading: Icon(
              action['icon'] as IconData,
              color: action['color'] as Color,
            ),
            title: Text(action['label'] as String),
            onTap: () {
              Navigator.pop(context);
              _handleLookAction(look, action['label'] as String);
            },
          )),
        ],
      ),
    );
  }

  void _handleLookAction(SavedLook look, String action) {
    switch (action.toLowerCase()) {
      case 'edit':
        _editLook(look);
        break;
      case 'duplicate':
        // Duplicate look
        break;
      case 'favorite':
        // Toggle favorite
        break;
      case 'share':
        _shareLook(look);
        break;
      case 'delete':
        _deleteLook(look);
        break;
    }
  }

  void _deleteLook(SavedLook look) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Look'),
        content: const Text('Are you sure you want to delete this look?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Delete look logic
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

  // Navigation and Settings
  void _navigateToPrivacySettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacySettingsScreen(),
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

  // Helper Methods
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 7) {
      return _formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Mock Data Methods
  static Avatar _getMockAvatar() {
    return Avatar(
      id: '1',
      name: 'Sarah\'s Avatar',
      modelUrl: '',
      thumbnailUrl: 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=200&h=200&fit=crop',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      measurements: const AvatarMeasurements(
        height: 165,
        weight: 60,
        chest: 86,
        waist: 68,
        hips: 92,
        shoulders: 38,
        arms: 25,
        legs: 75,
      ),
      attributes: const AvatarAttributes(
        bodyType: 'Athletic',
        ethnicity: 'Caucasian',
        skinTone: 'Light',
        hairColor: 'Brown',
        hairStyle: 'Long',
        eyeColor: 'Brown',
        gender: 'Female',
        age: 28,
      ),
      metadata: const AvatarMetadata(
        fileSize: 2.5,
        fileFormat: 'glb',
        polyCount: 15000,
        modelVersion: '2.1',
        textures: [],
        isOptimized: true,
        qualityLevel: 'High',
        lastUsed: Duration(),
      ),
      isDefault: true,
      isFavorite: true,
      usageCount: 42,
      tags: ['summer', 'casual', 'work'],
      description: 'Summer casual wear specialist',
      state: AvatarState.ready,
      heightAdjust: 0.1,
      chestSize: 1.05,
      waistSize: 0.95,
      hipSize: 1.0,
      lighting: LightingPreset.day,
    );
  }

  static List<SavedLook> _getMockSavedLooks() {
    return [
      SavedLook(
        id: '1',
        name: 'Casual Office Look',
        description: 'Professional yet comfortable for daily office wear',
        items: [],
        category: LookCategory.work,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        isFavorite: true,
        isPublic: false,
        tags: ['office', 'professional', 'comfortable'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=300&h=400&fit=crop',
        performance: const LookPerformanceMetrics(
          tryOnCount: 8,
          purchaseCount: 2,
          shareCount: 3,
          likeCount: 12,
          averageRating: 4.5,
          occasionWearCount: {'work': 5, 'casual': 2, 'meeting': 1},
        ),
        totalPrice: 2999.0,
        timesWorn: 8,
        notes: 'Perfect for client meetings',
        metadata: {'season': 'all', 'weather': 'moderate'},
      ),
      SavedLook(
        id: '2',
        name: 'Weekend Brunch',
        description: 'Chic and comfortable for weekend outings',
        items: [],
        category: LookCategory.casual,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        isFavorite: false,
        isPublic: true,
        tags: ['weekend', 'brunch', 'comfortable'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=300&h=400&fit=crop',
        performance: const LookPerformanceMetrics(
          tryOnCount: 5,
          purchaseCount: 1,
          shareCount: 7,
          likeCount: 18,
          averageRating: 4.2,
          occasionWearCount: {'brunch': 3, 'shopping': 2},
        ),
        totalPrice: 1899.0,
        timesWorn: 5,
        notes: '',
        metadata: {'season': 'summer', 'weather': 'sunny'},
      ),
      SavedLook(
        id: '3',
        name: 'Date Night Elegance',
        description: 'Sophisticated look for special occasions',
        items: [],
        category: LookCategory.date,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
        isFavorite: true,
        isPublic: false,
        tags: ['date', 'elegant', 'evening'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300&h=400&fit=crop',
        performance: const LookPerformanceMetrics(
          tryOnCount: 3,
          purchaseCount: 1,
          shareCount: 2,
          likeCount: 25,
          averageRating: 4.8,
          occasionWearCount: {'date': 2, 'party': 1},
        ),
        totalPrice: 4599.0,
        timesWorn: 3,
        notes: 'Got lots of compliments!',
        metadata: {'season': 'all', 'weather': 'indoor'},
      ),
      SavedLook(
        id: '4',
        name: 'Winter Warmth',
        description: 'Cozy winter outfit for cold days',
        items: [],
        category: LookCategory.winter,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 8)),
        isFavorite: false,
        isPublic: false,
        tags: ['winter', 'warm', 'cozy'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1506629905607-8e7f2bbd7f2f?w=300&h=400&fit=crop',
        performance: const LookPerformanceMetrics(
          tryOnCount: 12,
          purchaseCount: 3,
          shareCount: 1,
          likeCount: 8,
          averageRating: 3.9,
          occasionWearCount: {'work': 8, 'casual': 4},
        ),
        totalPrice: 3899.0,
        timesWorn: 12,
        notes: 'Very practical for Delhi winters',
        metadata: {'season': 'winter', 'weather': 'cold'},
      ),
    ];
  }

  static UserStatistics _getMockUserStatistics() {
    return const UserStatistics(
      userId: 'user123',
      joinDate: Duration(days: 30),
      totalSpent: 24750.0,
      totalOrders: 23,
      totalSavedItems: 156,
      totalSavedLooks: 4,
      totalTryOns: 89,
      totalShares: 15,
      totalReviews: 12,
      averageRating: 4.3,
      loyaltyTier: LoyaltyTier.gold,
      loyaltyPoints: 8650.0,
      favoriteBrands: ['Zara', 'H&M', 'Nike', 'Mango', 'Uniqlo'],
      favoriteCategories: ['Tops', 'Pants', 'Dresses', 'Shoes', 'Accessories'],
      preferredColors: ['Black', 'Navy', 'White', 'Beige', 'Burgundy'],
      daysActive: 25,
      totalAppSessions: 78,
      totalTimeSpent: Duration(hours: 15),
      styleConsistency: 0.85,
      achievements: [],
      recentActivity: [],
      categoryPreferences: {'tops': 35, 'bottoms': 28, 'dresses': 22, 'shoes': 15},
      brandPreferences: {'zara': 25, 'h&m': 20, 'nike': 18, 'mango': 15},
      colorPreferences: {'black': 30, 'navy': 25, 'white': 20, 'beige': 15},
      sustainabilityScore: 0.72,
      referralCount: 8,
      referralsCompleted: 3,
    );
  }

  static List<AvatarVersion> _getMockAvatarVersions() {
    return [
      AvatarVersion(
        id: '1',
        name: 'Current',
        thumbnailUrl: 'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=100&h=100&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        measurements: const AvatarMeasurements(
          height: 165,
          weight: 60,
          chest: 86,
          waist: 68,
          hips: 92,
          shoulders: 38,
          arms: 25,
          legs: 75,
        ),
        qualityScore: 0.95,
        isActive: true,
      ),
      AvatarVersion(
        id: '2',
        name: 'Version 2.1',
        thumbnailUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&h=100&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        measurements: const AvatarMeasurements(
          height: 164,
          weight: 61,
          chest: 85,
          waist: 69,
          hips: 91,
          shoulders: 37,
          arms: 24,
          legs: 74,
        ),
        qualityScore: 0.88,
        isActive: false,
      ),
      AvatarVersion(
        id: '3',
        name: 'Version 2.0',
        thumbnailUrl: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100&h=100&fit=crop',
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        measurements: const AvatarMeasurements(
          height: 166,
          weight: 59,
          chest: 87,
          waist: 67,
          hips: 93,
          shoulders: 39,
          arms: 26,
          legs: 76,
        ),
        qualityScore: 0.82,
        isActive: false,
      ),
    ];
  }

  static List<AchievementBadge> _getMockAchievements() {
    return [
      AchievementBadge(
        id: '1',
        name: 'First Purchase',
        description: 'Made your first purchase',
        icon: '🛍️',
        earnedAt: DateTime.now().subtract(const Duration(days: 25)),
        isUnlocked: true,
        category: 'spending',
      ),
      AchievementBadge(
        id: '2',
        name: 'Style Explorer',
        description: 'Tried on 50 items',
        icon: '👗',
        earnedAt: DateTime.now().subtract(const Duration(days: 10)),
        isUnlocked: true,
        progress: 1.0,
        category: 'activity',
      ),
      AchievementBadge(
        id: '3',
        name: 'Look Creator',
        description: 'Created 10 outfit combinations',
        icon: '🎨',
        earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        isUnlocked: true,
        progress: 1.0,
        category: 'activity',
      ),
      AchievementBadge(
        id: '4',
        name: 'Loyal Customer',
        description: 'Purchased from 10 different brands',
        icon: '💎',
        isUnlocked: false,
        progress: 0.7,
        currentCount: 7,
        requirementCount: 10,
        category: 'spending',
      ),
      AchievementBadge(
        id: '5',
        name: 'Social Star',
        description: 'Shared 20 outfits',
        icon: '⭐',
        isUnlocked: false,
        progress: 0.75,
        currentCount: 15,
        requirementCount: 20,
        category: 'social',
      ),
      AchievementBadge(
        id: '6',
        name: 'Early Adopter',
        description: 'Joined during beta',
        icon: '🚀',
        earnedAt: DateTime.now().subtract(const Duration(days: 45)),
        isUnlocked: true,
        category: 'special',
      ),
    ];
  }
}
