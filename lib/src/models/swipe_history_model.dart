/// Swipe History Model
///
/// Tracks user swipe actions for analytics and preference learning.
import 'product_model.dart';

enum SwipeAction {
  like,
  dislike,
  superLike,
  skip,
}

class SwipeHistory {
  final String id;
  final String productId;
  final SwipeAction action;
  final DateTime timestamp;
  final double swipeVelocity;
  final String? feedback;

  SwipeHistory({
    required this.id,
    required this.productId,
    required this.action,
    required this.timestamp,
    required this.swipeVelocity,
    this.feedback,
  });

  factory SwipeHistory.fromJson(Map<String, dynamic> json) {
    return SwipeHistory(
      id: json['id'] as String,
      productId: json['productId'] as String,
      action: SwipeAction.values.byName(json['action'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      swipeVelocity: (json['swipeVelocity'] as num).toDouble(),
      feedback: json['feedback'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'action': action.name,
      'timestamp': timestamp.toIso8601String(),
      'swipeVelocity': swipeVelocity,
      'feedback': feedback,
    };
  }

  SwipeHistory copyWith({
    String? id,
    String? productId,
    SwipeAction? action,
    DateTime? timestamp,
    double? swipeVelocity,
    String? feedback,
  }) {
    return SwipeHistory(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      swipeVelocity: swipeVelocity ?? this.swipeVelocity,
      feedback: feedback ?? this.feedback,
    );
  }
}

class UserSwipePreferences {
  final String userId;
  final Map<String, int> categoryPreferences;
  final Map<String, double> brandPreferences;
  final double swipeSensitivity;
  final bool hapticFeedbackEnabled;
  final bool soundEffectsEnabled;
  final bool analyticsEnabled;
  final DateTime lastUpdated;

  UserSwipePreferences({
    required this.userId,
    required this.categoryPreferences,
    required this.brandPreferences,
    required this.swipeSensitivity,
    required this.hapticFeedbackEnabled,
    required this.soundEffectsEnabled,
    required this.analyticsEnabled,
    required this.lastUpdated,
  });

  factory UserSwipePreferences.fromJson(Map<String, dynamic> json) {
    return UserSwipePreferences(
      userId: json['userId'] as String,
      categoryPreferences: Map<String, int>.from(json['categoryPreferences'] as Map),
      brandPreferences: Map<String, double>.from(json['brandPreferences'] as Map),
      swipeSensitivity: (json['swipeSensitivity'] as num).toDouble(),
      hapticFeedbackEnabled: json['hapticFeedbackEnabled'] as bool,
      soundEffectsEnabled: json['soundEffectsEnabled'] as bool,
      analyticsEnabled: json['analyticsEnabled'] as bool,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'categoryPreferences': categoryPreferences,
      'brandPreferences': brandPreferences,
      'swipeSensitivity': swipeSensitivity,
      'hapticFeedbackEnabled': hapticFeedbackEnabled,
      'soundEffectsEnabled': soundEffectsEnabled,
      'analyticsEnabled': analyticsEnabled,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  UserSwipePreferences copyWith({
    String? userId,
    Map<String, int>? categoryPreferences,
    Map<String, double>? brandPreferences,
    double? swipeSensitivity,
    bool? hapticFeedbackEnabled,
    bool? soundEffectsEnabled,
    bool? analyticsEnabled,
    DateTime? lastUpdated,
  }) {
    return UserSwipePreferences(
      userId: userId ?? this.userId,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      brandPreferences: brandPreferences ?? this.brandPreferences,
      swipeSensitivity: swipeSensitivity ?? this.swipeSensitivity,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      soundEffectsEnabled: soundEffectsEnabled ?? this.soundEffectsEnabled,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class SavedItem {
  final String id;
  final Product product;
  final DateTime savedAt;
  final String? notes;
  final List<String> tags;
  final int wearCount;
  final bool isFavorited;

  SavedItem({
    required this.id,
    required this.product,
    required this.savedAt,
    this.notes,
    this.tags = const [],
    this.wearCount = 0,
    this.isFavorited = false,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
      tags: List<String>.from(json['tags'] as List),
      wearCount: json['wearCount'] as int? ?? 0,
      isFavorited: json['isFavorited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'notes': notes,
      'tags': tags,
      'wearCount': wearCount,
      'isFavorited': isFavorited,
    };
  }

  SavedItem copyWith({
    String? id,
    Product? product,
    DateTime? savedAt,
    String? notes,
    List<String>? tags,
    int? wearCount,
    bool? isFavorited,
  }) {
    return SavedItem(
      id: id ?? this.id,
      product: product ?? this.product,
      savedAt: savedAt ?? this.savedAt,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      wearCount: wearCount ?? this.wearCount,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}