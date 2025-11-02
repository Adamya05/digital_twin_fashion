import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';
import 'app_button.dart';

/// Error state widget for displaying error messages
/// 
/// Features:
/// - Error icon and message display
/// - Optional retry action
/// - Consistent styling with theme
/// - Support for different error types
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    this.subtitle,
    this.onRetry,
    this.retryLabel = 'Try Again',
    this.icon = Icons.error_outline,
    this.iconColor,
    this.backgroundColor,
    this.retryButton,
    this.showRetryButton = true,
  });

  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final Widget? retryButton;
  final bool showRetryButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.majorCardsRadius),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 48,
            color: iconColor ?? AppTheme.error,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppTheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
          if (showRetryButton && (onRetry != null || retryButton != null)) ...[
            const SizedBox(height: AppTheme.spacingL),
            retryButton ??
                (onRetry != null
                    ? SecondaryButton(
                        label: retryLabel,
                        onPressed: onRetry,
                      )
                    : const SizedBox.shrink()),
          ],
        ],
      ),
    );
  }
}

/// Network error state widget
class NetworkErrorState extends StatelessWidget {
  const NetworkErrorState({
    super.key,
    this.onRetry,
    this.onGoOffline,
  });

  final VoidCallback? onRetry;
  final VoidCallback? onGoOffline;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.wifi_off,
      message: 'Connection Error',
      subtitle:
          'Please check your internet connection and try again',
      onRetry: onRetry,
      retryButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SecondaryButton(
            label: 'Retry',
            onPressed: onRetry,
          ),
          const SizedBox(width: AppTheme.spacingS),
          if (onGoOffline != null)
            TextButton(
              onPressed: onGoOffline,
              child: const Text('Go Offline'),
            ),
        ],
      ),
    );
  }
}

/// Server error state widget
class ServerErrorState extends StatelessWidget {
  const ServerErrorState({
    super.key,
    this.onRetry,
    this.contactSupport = false,
  });

  final VoidCallback? onRetry;
  final bool contactSupport;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.server_error,
      message: 'Server Error',
      subtitle: contactSupport
          ? 'Please contact support if the problem persists'
          : 'Something went wrong on our end. Please try again later.',
      onRetry: onRetry,
    );
  }
}

/// Permission error state widget
class PermissionErrorState extends StatelessWidget {
  const PermissionErrorState({
    super.key,
    required this.permissionType,
    this.onGrantPermission,
    this.onOpenSettings,
  });

  final String permissionType;
  final VoidCallback? onGrantPermission;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      icon: Icons.security,
      message: 'Permission Required',
      subtitle:
          'Please grant $permissionType permission to continue',
      retryButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onGrantPermission != null)
            PrimaryButton(
              label: 'Grant Permission',
              onPressed: onGrantPermission,
            ),
          if (onOpenSettings != null) ...[
            const SizedBox(width: AppTheme.spacingS),
            SecondaryButton(
              label: 'Open Settings',
              onPressed: onOpenSettings,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact error state for inline use
class CompactErrorState extends StatelessWidget {
  const CompactErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.1),
        border: Border.all(color: AppTheme.error.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppTheme.error,
            size: 20,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.error,
                  ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: onRetry,
              iconSize: 16,
              color: AppTheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onDismiss,
              iconSize: 16,
              color: AppTheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
            ),
        ],
      ),
    );
  }
}