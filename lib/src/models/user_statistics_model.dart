/// User Statistics Model
///
/// Tracks comprehensive user engagement, loyalty points, achievements,
/// and activity feed for the profile dashboard.
import 'product_model.dart';
import 'avatar_model.dart';
import 'saved_look_model.dart';
import 'order_model.dart';

/// User loyalty tier system
enum LoyaltyTier {
  bronze('Bronze', '🥉', 0, 999, 0xFF8D6E63, 0xFFBCAAA4),
  silver('Silver', '🥈', 1000, 4999, 0xFF757575, 0xFFBDBDBD),
  gold('Gold', '🥇', 5000, 19999, 0xFFFFD700, 0xFFFFECB3),
  platinum('Platinum', '💎', 20000, 49999, 0xFFE5E4E2, 0xFFF5F5F5),
  diamond('Diamond', '💎', 50000, double.infinity, 0xFFB9F2FF, 0xFFE1F5FE);

  const LoyaltyTier(
    this.displayName,
    this.emoji,
    this.minPoints,
    this.maxPoints,
    this.primaryColor,
    this.secondaryColor,
  );

  final String displayName;
  final String emoji;
  final double minPoints;
  final double maxPoints;
  final int primaryColor;
  final int secondaryColor;

  /// Get tier for given points
  static LoyaltyTier getTier(double points) {
    for (final tier in values) {
      if (points >= tier.minPoints && points <= tier.maxPoints) {
        return tier;
      }
    }
    return bronze;
  }
}

/// Achievement badge system
class AchievementBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime earnedAt;
  final bool isUnlocked;
  final double progress; // 0.0 to 1.0
  final int requirementCount;
  final int currentCount;
  final String category; // 'spending', 'activity', 'social', etc.

  const AchievementBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.earnedAt,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.requirementCount = 1,
    this.currentCount = 0,
    required this.category,
  });

  /// Factory constructor from JSON
  factory AchievementBadge.fromJson(Map<String, dynamic> json) {
    return AchievementBadge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      requirementCount: json['requirementCount'] as int? ?? 1,
      currentCount: json['currentCount'] as int? ?? 0,
      category: json['category'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'earnedAt': earnedAt.toIso8601String(),
      'isUnlocked': isUnlocked,
      'progress': progress,
      'requirementCount': requirementCount,
      'currentCount': currentCount,
      'category': category,
    };
  }
}

/// Activity feed item
class ActivityFeedItem {
  final String id;
  final String userId;
  final String type; // 'purchase', 'save_look', 'try_on', 'review', etc.
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Factory constructor from JSON
  factory ActivityFeedItem.fromJson(Map<String, dynamic> json) {
    return ActivityFeedItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Comprehensive user statistics
class UserStatistics {
  final String userId;
  final DateTime joinDate;
  final double totalSpent;
  final int totalOrders;
  final int totalSavedItems;
  final int totalSavedLooks;
  final int totalTryOns;
  final int totalShares;
  final int totalReviews;
  final double averageRating;
  final LoyaltyTier loyaltyTier;
  final double loyaltyPoints;
  final List<String> favoriteBrands;
  final List<String> favoriteCategories;
  final List<String> preferredColors;
  final int daysActive;
  final int totalAppSessions;
  final Duration totalTimeSpent;
  final double styleConsistency; // 0.0 to 1.0
  final List<AchievementBadge> achievements;
  final List<ActivityFeedItem> recentActivity;
  final Map<String, int> categoryPreferences;
  final Map<String, int> brandPreferences;
  final Map<String, int> colorPreferences;
  final double sustainabilityScore; // Based on eco-friendly purchases
  final int referralCount;
  final int referralsCompleted;

  const UserStatistics({
    required this.userId,
    required this.joinDate,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    this.totalSavedItems = 0,
    this.totalSavedLooks = 0,
    this.totalTryOns = 0,
    this.totalShares = 0,
    this.totalReviews = 0,
    this.averageRating = 0.0,
    LoyaltyTier? loyaltyTier,
    this.loyaltyPoints = 0.0,
    this.favoriteBrands = const [],
    this.favoriteCategories = const [],
    this.preferredColors = const [],
    this.daysActive = 0,
    this.totalAppSessions = 0,
    Duration? totalTimeSpent,
    this.styleConsistency = 0.0,
    this.achievements = const [],
    this.recentActivity = const [],
    this.categoryPreferences = const {},
    this.brandPreferences = const {},
    this.colorPreferences = const {},
    this.sustainabilityScore = 0.0,
    this.referralCount = 0,
    this.referralsCompleted = 0,
  }) : loyaltyTier = loyaltyTier ?? LoyaltyTier.getTier(loyaltyPoints),
       totalTimeSpent = totalTimeSpent ?? Duration.zero;

  /// Calculate days since join
  int get daysSinceJoin => DateTime.now().difference(joinDate).inDays;

  /// Get engagement score (0-100)
  double get engagementScore {
    final weights = {
      'spending': 0.3,
      'activity': 0.2,
      'social': 0.2,
      'loyalty': 0.3,
    };

    // Normalize spending (assume $5000 as max for normalization)
    final spendingScore = (totalSpent / 5000).clamp(0.0, 1.0) * 100;

    // Activity score based on app usage and interactions
    final activityScore = ((totalTryOns + totalSavedItems + totalSavedLooks) / 100).clamp(0.0, 1.0) * 100;

    // Social score based on shares and reviews
    final socialScore = ((totalShares + totalReviews) / 50).clamp(0.0, 1.0) * 100;

    // Loyalty score based on points and tier
    final loyaltyScore = (loyaltyPoints / 10000).clamp(0.0, 1.0) * 100;

    return (spendingScore * weights['spending']! +
            activityScore * weights['activity']! +
            socialScore * weights['social']! +
            loyaltyScore * weights['loyalty']!);
  }

  /// Get next tier info
  LoyaltyTier get nextTier {
    final tiers = LoyaltyTier.values;
    final currentIndex = tiers.indexOf(loyaltyTier);
    
    if (currentIndex < tiers.length - 1) {
      return tiers[currentIndex + 1];
    }
    
    return loyaltyTier; // Already at highest tier
  }

  /// Get points needed for next tier
  double get pointsToNextTier {
    if (loyaltyTier == LoyaltyTier.diamond) return 0.0;
    
    return nextTier.minPoints - loyaltyPoints;
  }

  /// Get spending streak (consecutive days with activity)
  int get spendingStreak {
    // This would be calculated from activity data
    // Placeholder implementation
    return 7; // Mock 7-day streak
  }

  /// Get average order value
  double get averageOrderValue {
    if (totalOrders == 0) return 0.0;
    return totalSpent / totalOrders;
  }

  /// Factory constructor from JSON
  factory UserStatistics.fromJson(Map<String, dynamic> json) {
    return UserStatistics(
      userId: json['userId'] as String,
      joinDate: DateTime.parse(json['joinDate'] as String),
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSavedItems: json['totalSavedItems'] as int? ?? 0,
      totalSavedLooks: json['totalSavedLooks'] as int? ?? 0,
      totalTryOns: json['totalTryOns'] as int? ?? 0,
      totalShares: json['totalShares'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      loyaltyTier: LoyaltyTier.values.firstWhere(
        (tier) => tier.name == json['loyaltyTier'],
        orElse: () => LoyaltyTier.bronze,
      ),
      loyaltyPoints: (json['loyaltyPoints'] as num?)?.toDouble() ?? 0.0,
      favoriteBrands: (json['favoriteBrands'] as List<dynamic>?)?.cast<String>() ?? [],
      favoriteCategories: (json['favoriteCategories'] as List<dynamic>?)?.cast<String>() ?? [],
      preferredColors: (json['preferredColors'] as List<dynamic>?)?.cast<String>() ?? [],
      daysActive: json['daysActive'] as int? ?? 0,
      totalAppSessions: json['totalAppSessions'] as int? ?? 0,
      totalTimeSpent: Duration(minutes: json['totalTimeSpent'] as int? ?? 0),
      styleConsistency: (json['styleConsistency'] as num?)?.toDouble() ?? 0.0,
      achievements: (json['achievements'] as List<dynamic>?)
          ?.map((badge) => AchievementBadge.fromJson(badge as Map<String, dynamic>))
          .toList() ?? [],
      recentActivity: (json['recentActivity'] as List<dynamic>?)
          ?.map((activity) => ActivityFeedItem.fromJson(activity as Map<String, dynamic>))
          .toList() ?? [],
      categoryPreferences: Map<String, int>.from(json['categoryPreferences'] ?? {}),
      brandPreferences: Map<String, int>.from(json['brandPreferences'] ?? {}),
      colorPreferences: Map<String, int>.from(json['colorPreferences'] ?? {}),
      sustainabilityScore: (json['sustainabilityScore'] as num?)?.toDouble() ?? 0.0,
      referralCount: json['referralCount'] as int? ?? 0,
      referralsCompleted: json['referralsCompleted'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'joinDate': joinDate.toIso8601String(),
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'totalSavedItems': totalSavedItems,
      'totalSavedLooks': totalSavedLooks,
      'totalTryOns': totalTryOns,
      'totalShares': totalShares,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'loyaltyTier': loyaltyTier.name,
      'loyaltyPoints': loyaltyPoints,
      'favoriteBrands': favoriteBrands,
      'favoriteCategories': favoriteCategories,
      'preferredColors': preferredColors,
      'daysActive': daysActive,
      'totalAppSessions': totalAppSessions,
      'totalTimeSpent': totalTimeSpent.inMinutes,
      'styleConsistency': styleConsistency,
      'achievements': achievements.map((badge) => badge.toJson()).toList(),
      'recentActivity': recentActivity.map((activity) => activity.toJson()).toList(),
      'categoryPreferences': categoryPreferences,
      'brandPreferences': brandPreferences,
      'colorPreferences': colorPreferences,
      'sustainabilityScore': sustainabilityScore,
      'referralCount': referralCount,
      'referralsCompleted': referralsCompleted,
    };
  }
}

/// Avatar version history for comparison
class AvatarVersion {
  final String id;
  final String name;
  final String thumbnailUrl;
  final DateTime createdAt;
  final AvatarMeasurements measurements;
  final double qualityScore;
  final bool isActive;

  const AvatarVersion({
    required this.id,
    required this.name,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.measurements,
    this.qualityScore = 0.0,
    this.isActive = false,
  });

  factory AvatarVersion.fromJson(Map<String, dynamic> json) {
    return AvatarVersion(
      id: json['id'] as String,
      name: json['name'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      measurements: AvatarMeasurements.fromJson(json['measurements']),
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}