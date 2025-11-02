import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// Specialized container for 3D canvas with enhanced styling
/// 
/// Features:
/// - Large corner radius (24px) for modern look
/// - High elevation for depth perception
/// - Flexible dimensions for different canvas types
/// - Consistent padding and spacing
class CanvasContainer extends StatelessWidget {
  const CanvasContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.shadowColor,
    this.border,
  });

  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? elevation;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? shadowColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.all(AppTheme.spacingM),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.canvasContainerRadius,
        ),
        border: border,
        boxShadow: [
          BoxShadow(
            color: shadowColor ?? AppTheme.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.canvasContainerRadius,
        ),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(AppTheme.spacingM),
          child: child,
        ),
      ),
    );
  }
}

/// Extended canvas container with header and footer support
class CanvasPanel extends StatelessWidget {
  const CanvasPanel({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.width,
    this.height,
    this.headerHeight = 60,
    this.footerHeight = 80,
    this.padding,
    this.margin,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;
  final double? width;
  final double? height;
  final double headerHeight;
  final double footerHeight;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return CanvasContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      child: Column(
        children: [
          if (header != null)
            SizedBox(
              height: headerHeight,
              child: header,
            ),
          if (header != null) const Divider(),
          Expanded(
            child: child,
          ),
          if (footer != null) const Divider(),
          if (footer != null)
            SizedBox(
              height: footerHeight,
              child: footer,
            ),
        ],
      ),
    );
  }
}

/// Compact canvas container for smaller 3D elements
class CompactCanvas extends StatelessWidget {
  const CompactCanvas({
    super.key,
    required this.child,
    this.size = 120,
    this.padding,
  });

  final Widget child;
  final double size;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return CanvasContainer(
      width: size,
      height: size,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingS),
      child: Center(child: child),
    );
  }
}

/// Full-screen canvas container for immersive experiences
class FullScreenCanvas extends StatelessWidget {
  const FullScreenCanvas({
    super.key,
    required this.child,
    this.header,
    this.footer,
    this.padding,
  });

  final Widget child;
  final Widget? header;
  final Widget? footer;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      body: CanvasPanel(
        width: mediaQuery.size.width,
        height: mediaQuery.size.height,
        padding: padding,
        header: header,
        footer: footer,
        child: child,
      ),
    );
  }
}