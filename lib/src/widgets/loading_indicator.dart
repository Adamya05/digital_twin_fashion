import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// Loading indicator component with app theme integration
/// 
/// Supports multiple loading states:
/// - Circular progress (default)
/// - Linear progress
/// - Spinner with custom message
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.type = LoadingType.circular,
    this.color,
    this.backgroundColor,
    this.size = 48,
    this.strokeWidth = 4,
    this.message,
    this.messageStyle,
  });

  final LoadingType type;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final String? message;
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == LoadingType.circular)
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppTheme.primaryGreen,
                ),
                backgroundColor: backgroundColor,
                strokeWidth: strokeWidth,
              ),
            )
          else
            SizedBox(
              width: size * 2,
              height: size / 4,
              child: LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  color ?? AppTheme.primaryGreen,
                ),
                backgroundColor: backgroundColor,
              ),
            ),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingM),
            Text(
              message!,
              style: messageStyle ??
                  theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textDarkGray,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full-screen loading overlay for blocking operations
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message = 'Loading...',
    this.progress,
    this.backgroundColor = Colors.black54,
  });

  final bool isLoading;
  final String message;
  final double? progress;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !isLoading,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isLoading ? backgroundColor : Colors.transparent,
        child: Center(
          child: isLoading
              ? Container(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(
                      AppTheme.majorCardsRadius,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Text(
                        message,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: AppTheme.spacingS),
                        LinearProgressIndicator(
                          value: progress,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Inline loading widget for use within cards or lists
class InlineLoading extends StatelessWidget {
  const InlineLoading({
    super.key,
    this.size = 24,
    this.color,
    this.message,
  });

  final double size;
  final Color? color;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppTheme.primaryGreen,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: AppTheme.spacingS),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );
  }
}

/// Pull-to-refresh loading indicator
class PullToRefreshIndicator extends StatelessWidget {
  const PullToRefreshIndicator({
    super.key,
    this.message = 'Pull to refresh',
    this.animatingToRefreshMessage = 'Refreshing...',
  });

  final String message;
  final String animatingToRefreshMessage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.refresh,
            color: AppTheme.primaryGreen,
            size: 32,
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum LoadingType { circular, linear }