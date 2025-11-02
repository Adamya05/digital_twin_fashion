import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../src/providers/closet_provider.dart';
import '../../src/models/closet_model.dart';
import '../../src/widgets/app_button.dart';
import '../../src/widgets/app_card.dart';

/// Closet Analytics Screen - Comprehensive Insights and Analytics
/// 
/// Provides detailed analytics including:
/// - Wardrobe statistics and metrics
/// - Category and brand analysis
/// - Wearing frequency patterns
/// - Cost analysis and ROI
/// - Seasonal usage trends
/// - Smart insights and recommendations
class ClosetAnalyticsScreen extends ConsumerStatefulWidget {
  const ClosetAnalyticsScreen({super.key});

  @override
  ConsumerState<ClosetAnalyticsScreen> createState() => _ClosetAnalyticsScreenState();
}

class _ClosetAnalyticsScreenState extends ConsumerState<ClosetAnalyticsScreen>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // UI state
  bool _isLoading = false;
  int _timeframeIndex = 0; // 0: All time, 1: Last year, 2: Last 6 months, 3: Last 3 months
  
  // Chart data state
  Map<String, dynamic> _categoryData = {};
  Map<String, dynamic> _brandData = {};
  Map<String, dynamic> _wearingData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    // Start animations
    _animationController.forward();
    
    // Load analytics data
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final closetState = ref.watch(closetProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh Analytics',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAnalytics,
            tooltip: 'Share Analytics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Brands', icon: Icon(Icons.store)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb)),
          ],
        ),
      ),
      
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Timeframe selector
            _buildTimeframeSelector(),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(closetState),
                  _buildCategoriesTab(closetState),
                  _buildBrandsTab(closetState),
                  _buildInsightsTab(closetState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildTimeframeSelector() {
    final timeframes = ['All Time', 'Last Year', 'Last 6 Months', 'Last 3 Months'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Time Period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timeframes.asMap().entries.map((entry) {
                final index = entry.key;
                final timeframe = entry.value;
                final isSelected = _timeframeIndex == index;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(timeframe),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _timeframeIndex = index;
                        });
                        _loadAnalyticsData();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(ClosetState closetState) {
    if (closetState.isLoadingAnalytics) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (closetState.analytics == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No analytics data available'),
          ],
        ),
      );
    }
    
    final analytics = closetState.analytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key metrics
          _buildKeyMetricsSection(analytics),
          
          const SizedBox(height: 24),
          
          // Quick insights
          _buildQuickInsightsSection(analytics),
          
          const SizedBox(height: 24),
          
          // Usage patterns
          _buildUsagePatternsSection(analytics),
          
          const SizedBox(height: 24),
          
          // Financial overview
          _buildFinancialOverviewSection(analytics),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(ClosetState closetState) {
    if (closetState.analytics == null) {
      return const Center(child: Text('No data available'));
    }
    
    final analytics = closetState.analytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category overview
          _buildCategoryOverviewSection(analytics),
          
          const SizedBox(height: 24),
          
          // Category details
          _buildCategoryDetailsSection(analytics),
          
          const SizedBox(height: 24),
          
          // Category recommendations
          _buildCategoryRecommendationsSection(analytics),
        ],
      ),
    );
  }

  Widget _buildBrandsTab(ClosetState closetState) {
    if (closetState.analytics == null) {
      return const Center(child: Text('No data available'));
    }
    
    final analytics = closetState.analytics!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand overview
          _buildBrandOverviewSection(analytics),
          
          const SizedBox(height: 24),
          
          // Brand performance
          _buildBrandPerformanceSection(analytics),
          
          const SizedBox(height: 24),
          
          // Brand recommendations
          _buildBrandRecommendationsSection(analytics),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(ClosetState closetState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smart insights
          _buildSmartInsightsSection(closetState),
          
          const SizedBox(height: 24),
          
          // Recommendations
          _buildRecommendationsSection(closetState),
          
          const SizedBox(height: 24),
          
          // Trends
          _buildTrendsSection(closetState),
        ],
      ),
    );
  }

  // ==================== SECTION BUILDERS ====================

  Widget _buildKeyMetricsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart),
                const SizedBox(width: 8),
                Text(
                  'Key Metrics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'Total Items',
                  analytics.totalItems.toString(),
                  Icons.checkroom,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Total Value',
                  '₹${analytics.totalValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Total Outfits',
                  analytics.totalOutfits.toString(),
                  Icons.style,
                  Colors.purple,
                ),
                _buildMetricCard(
                  'Avg Cost/Wear',
                  '₹${analytics.averageCostPerWear.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInsightsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb),
                const SizedBox(width: 8),
                Text(
                  'Quick Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Top category
            _buildInsightItem(
              'Most Owned Category',
              '${analytics.itemsByCategory.entries.first.key} (${analytics.itemsByCategory.entries.first.value} items)',
              Icons.category,
            ),
            
            const Divider(),
            
            // Top brand
            _buildInsightItem(
              'Top Brand',
              '${analytics.itemsByBrand.entries.first.key} (${analytics.itemsByBrand.entries.first.value} items)',
              Icons.store,
            ),
            
            const Divider(),
            
            // Most worn item
            if (analytics.mostWornItem > 0)
              _buildInsightItem(
                'Most Worn Item',
                '${analytics.mostWornItem} times worn',
                Icons.trending_up,
              ),
            
            if (analytics.mostWornItem == 0)
              _buildInsightItem(
                'No Wear Data',
                'Start wearing items to get insights',
                Icons.info,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsagePatternsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule),
                const SizedBox(width: 8),
                Text(
                  'Usage Patterns',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Wearing frequency (mock data for now)
            _buildPatternItem(
              'Most Active Days',
              'Weekends (40% of wears)',
              Icons.calendar_view_week,
            ),
            
            const Divider(),
            
            _buildPatternItem(
              'Seasonal Preference',
              'Summer items worn 45% more',
              Icons.wb_sunny,
            ),
            
            const Divider(),
            
            _buildPatternItem(
              'Time of Day',
              'Morning outfits (60% preference)',
              Icons.bedtime,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialOverviewSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet),
                const SizedBox(width: 8),
                Text(
                  'Financial Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildFinancialItem(
              'Total Investment',
              '₹${analytics.totalValue.toStringAsFixed(0)}',
              Icons.monetization_on,
            ),
            
            const Divider(),
            
            _buildFinancialItem(
              'Cost Efficiency',
              '₹${analytics.averageCostPerWear.toStringAsFixed(0)} per wear',
              Icons.trending_down,
            ),
            
            const Divider(),
            
            _buildFinancialItem(
              'Best Value Category',
              '${analytics.itemsByCategory.entries.first.key}',
              Icons.local_offer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryOverviewSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ...analytics.itemsByCategory.entries.map((entry) {
              final percentage = (entry.value / analytics.totalItems * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key),
                        Text('${entry.value} ($percentage%)'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: entry.value / analytics.totalItems,
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDetailsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Mock performance data
            _buildPerformanceItem('Tops', '85% utilization', Icons.check_circle, Colors.green),
            _buildPerformanceItem('Bottoms', '72% utilization', Icons.check_circle, Colors.green),
            _buildPerformanceItem('Dresses', '45% utilization', Icons.warning, Colors.orange),
            _buildPerformanceItem('Shoes', '68% utilization', Icons.check_circle, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRecommendationsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildRecommendationItem(
              'Consider expanding your dress collection',
              'You have fewer dresses compared to tops and bottoms',
              Icons.add_circle,
            ),
            
            const Divider(),
            
            _buildRecommendationItem(
              'Your shoe collection is well-balanced',
              'Good variety of shoes for different occasions',
              Icons.check_circle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandOverviewSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Distribution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ...analytics.itemsByBrand.entries.map((entry) {
              final percentage = (entry.value / analytics.totalItems * 100).round();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text('${entry.value} ($percentage%)'),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandPerformanceSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Performance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Mock brand performance data
            _buildPerformanceItem('Zara', '80% satisfaction rate', Icons.star, Colors.amber),
            _buildPerformanceItem('H&M', '75% satisfaction rate', Icons.star, Colors.amber),
            _buildPerformanceItem('Uniqlo', '85% satisfaction rate', Icons.star, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandRecommendationsSection(ClosetAnalytics analytics) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildRecommendationItem(
              'Try exploring sustainable brands',
              'Consider eco-friendly options for your next purchase',
              Icons.eco,
            ),
            
            const Divider(),
            
            _buildRecommendationItem(
              'Your current brand mix is diverse',
              'Good variety across different price points',
              Icons.balance,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsightsSection(ClosetState closetState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology),
                const SizedBox(width: 8),
                Text(
                  'Smart Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (closetState.insights.isEmpty)
              Column(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Use your closet more to get personalized insights!',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              ...closetState.insights.map((insight) {
                return _buildInsightCard(insight);
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(ClosetState closetState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personalized Recommendations',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildRecommendationItem(
              'Complete your wardrobe',
              'You\'re missing accessories that would work with your current items',
              Icons.sentiment_very_satisfied,
            ),
            
            const Divider(),
            
            _buildRecommendationItem(
              'Seasonal planning',
              'Consider adding fall items to prepare for the season',
              Icons.wb_cloudy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsSection(ClosetState closetState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Style Trends',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            _buildTrendItem(
              'Trending Categories',
              'Sustainable fashion items are becoming more popular',
              Icons.trending_up,
            ),
            
            const Divider(),
            
            _buildTrendItem(
              'Color Trends',
              'Earth tones and pastels are in style this season',
              Icons.palette,
            ),
            
            const Divider(),
            
            _buildTrendItem(
              'Occasion Trends',
              'Versatile pieces that work for multiple occasions are preferred',
              Icons.grade,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== CARD BUILDERS ====================

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }

  Widget _buildPatternItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(value, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceItem(String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _buildRecommendationItem(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildInsightCard(AnalyticsInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          _getInsightIcon(insight.type),
          color: _getInsightColor(insight.type),
        ),
        title: Text(insight.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.description),
            const SizedBox(height: 4),
            Text(
              _formatDate(insight.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: insight.action != null
            ? TextButton(
                onPressed: () => _executeInsightAction(insight.action!),
                child: const Text('Act'),
              )
            : null,
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(value),
    );
  }

  // ==================== ACTION HANDLERS ====================

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await ref.read(closetProvider.notifier).loadAnalytics();
      
      // Load chart data based on timeframe
      await _loadChartData();
    } catch (e) {
      debugPrint('Error loading analytics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadChartData() async {
    // This would load data for charts based on selected timeframe
    // For now, using mock data
    setState(() {
      _categoryData = {
        'labels': ['Tops', 'Bottoms', 'Dresses', 'Shoes', 'Accessories'],
        'values': [25, 20, 15, 12, 8],
      };
      
      _brandData = {
        'labels': ['Zara', 'H&M', 'Uniqlo', 'Mango', 'Others'],
        'values': [20, 18, 15, 10, 7],
      };
      
      _wearingData = {
        'labels': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        'values': [5, 8, 12, 10, 15, 20, 18],
      };
    });
  }

  void _shareAnalytics() {
    // Share analytics functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share analytics feature coming soon')),
    );
  }

  void _executeInsightAction(String action) {
    // Execute insight action
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executing: $action')),
    );
  }

  // ==================== UTILITY METHODS ====================

  IconData _getInsightIcon(String type) {
    switch (type) {
      case 'recommendation':
        return Icons.lightbulb;
      case 'warning':
        return Icons.warning;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.info;
    }
  }

  Color _getInsightColor(String type) {
    switch (type) {
      case 'recommendation':
        return Colors.amber;
      case 'warning':
        return Colors.orange;
      case 'achievement':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}