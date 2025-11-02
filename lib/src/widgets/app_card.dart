import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// A reusable card component that follows the app's design system
/// 
/// Features:
/// - Consistent elevation and shadow
/// - Rounded corners (majorCardsRadius = 16)
/// - Flexible content slot
/// - Support for tap interactions
/// - Material Design 3 styling
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.elevation,
    this.margin,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.width,
    this.height,
    this.shadowColor,
    this.shape,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double? elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final Color? shadowColor;
  final BoxShape? shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingM),
      child: Card(
        elevation: elevation ?? AppTheme.cardElevation,
        shadowColor: shadowColor ?? AppTheme.shadowColor,
        color: backgroundColor ?? AppTheme.surfaceWhite,
        shape: shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.majorCardsRadius,
              ),
            ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.majorCardsRadius,
          ),
          child: Padding(
            padding:
                padding ?? const EdgeInsets.all(AppTheme.spacingM),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A specialized card for displaying content with header and body sections
/// 
/// Useful for displaying:
/// - Dashboard statistics
/// - Form sections
/// - Content groups
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    this.leadingIcon,
    required this.child,
    this.onTap,
    this.actions,
    this.padding,
  });

  final String title;
  final IconData? leadingIcon;
  final Widget child;
  final VoidCallback? onTap;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon!,
                  color: AppTheme.primaryGreen,
                  size: 24,
                ),
                const SizedBox(width: AppTheme.spacingS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              if (actions != null) ...actions!,
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          child,
        ],
      ),
    );
  }
}

/// A compact card variant for list items and compact content
class CompactCard extends StatelessWidget {
  const CompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      margin:
          margin ?? const EdgeInsets.all(AppTheme.spacingS),
      padding: const EdgeInsets.all(AppTheme.spacingS),
      child: child,
    );
  }
}