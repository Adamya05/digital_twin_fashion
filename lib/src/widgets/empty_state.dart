import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';
import 'app_button.dart';

/// Empty state widget for when no content is available
/// 
/// Features:
/// - Icon and message display
/// - Optional action button
/// - Consistent styling
/// - Flexible layout
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.titleStyle,
    this.subtitleStyle,
    this.actionButton,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final double iconSize;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Widget? actionButton;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: AppTheme.outline,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: titleStyle ??
                  Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppTheme.spacingS),
              Text(
                subtitle!,
                style: subtitleStyle ??
                    Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.outline,
                        ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null || actionButton != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              actionButton ??
                  (actionLabel != null
                      ? PrimaryButton(
                          label: actionLabel!,
                          onPressed: onAction,
                        )
                      : const SizedBox.shrink()),
            ],
          ],
        ),
      ),
    );
  }
}

/// Specialized empty state for search results
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({
    super.key,
    this.searchTerm,
    this.onClear,
    this.onRetry,
  });

  final String? searchTerm;
  final VoidCallback? onClear;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No results found',
      subtitle: searchTerm != null
          ? 'No results found for "$searchTerm"'
          : 'Try adjusting your search terms',
      actionLabel: 'Clear Search',
      onAction: onClear,
    );
  }
}

/// Specialized empty state for no data
class DataEmptyState extends StatelessWidget {
  const DataEmptyState({
    super.key,
    this.dataType = 'items',
    this.onAdd,
  });

  final String dataType;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No $dataType yet',
      subtitle: 'Start by adding your first $dataType',
      actionLabel: 'Add $dataType',
      onAction: onAdd,
    );
  }
}

/// Specialized empty state for favorites
class FavoritesEmptyState extends StatelessWidget {
  const FavoritesEmptyState({
    super.key,
    this.onExplore,
  });

  final VoidCallback? onExplore;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.favorite_border,
      title: 'No favorites yet',
      subtitle: 'Items you mark as favorite will appear here',
      actionLabel: 'Explore Items',
      onAction: onExplore,
    );
  }
}

/// Compact empty state for lists
class CompactEmptyState extends StatelessWidget {
  const CompactEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.outline,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.outline,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}