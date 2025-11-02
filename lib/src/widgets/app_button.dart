import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// Reusable button component following the app's design system
/// 
/// Supports multiple button styles:
/// - Elevated (primary action)
/// - Outlined (secondary action)
/// - Text (tertiary action)
/// - Custom styling options
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = ButtonType.elevated,
    this.icon,
    this.fullWidth = false,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.enabled = true,
    this.loadingText,
    this.height,
    this.customColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final ButtonType type;
  final IconData? icon;
  final bool fullWidth;
  final ButtonSize size;
  final bool isLoading;
  final bool enabled;
  final String? loadingText;
  final double? height;
  final Color? customColor;

  @override
  Widget build(BuildContext context) {
    final buttonStyle = _getButtonStyle(context);
    final content = _buildButtonContent();

    switch (type) {
      case ButtonType.elevated:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height ?? _getButtonHeight(),
          child: ElevatedButton(
            onPressed: enabled && !isLoading ? onPressed : null,
            style: buttonStyle,
            child: content,
          ),
        );

      case ButtonType.outlined:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height ?? _getButtonHeight(),
          child: OutlinedButton(
            onPressed: enabled && !isLoading ? onPressed : null,
            style: buttonStyle,
            child: content,
          ),
        );

      case ButtonType.text:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: height ?? _getButtonHeight(),
          child: TextButton(
            onPressed: enabled && !isLoading ? onPressed : null,
            style: buttonStyle,
            child: content,
          ),
        );
    }
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    switch (type) {
      case ButtonType.elevated:
        return ElevatedButton.styleFrom(
          backgroundColor: customColor ?? AppTheme.primaryGreen,
          foregroundColor: AppTheme.onPrimary,
          elevation: enabled ? AppTheme.buttonElevation : 0,
          shadowColor: AppTheme.shadowColor,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.majorCardsRadius),
          ),
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        );

      case ButtonType.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: customColor ?? AppTheme.primaryGreen,
          side: BorderSide(
            color: customColor ?? AppTheme.primaryGreen,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.majorCardsRadius),
          ),
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        );

      case ButtonType.text:
        return TextButton.styleFrom(
          foregroundColor: customColor ?? AppTheme.primaryGreen,
          padding: _getPadding(),
          textStyle: _getTextStyle(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == ButtonType.elevated
                    ? AppTheme.onPrimary
                    : customColor ?? AppTheme.primaryGreen,
              ),
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(width: AppTheme.spacingS),
            Text(
              loadingText!,
              style: _getTextStyle(),
            ),
          ],
        ],
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: AppTheme.spacingS),
          Text(label),
        ],
      );
    }

    return Text(label);
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        );
      case ButtonSize.medium:
        return AppTheme.buttonPadding;
      case ButtonSize.large:
        return const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXl,
          vertical: AppTheme.spacingM,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case ButtonSize.small:
        return const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.fontFamily,
        );
      case ButtonSize.medium:
        return const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          fontFamily: AppTheme.fontFamily,
        );
      case ButtonSize.large:
        return const TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.w600,
          fontFamily: AppTheme.fontFamily,
        );
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }
}

/// Button variants and configuration enum
enum ButtonType { elevated, outlined, text }

enum ButtonSize { small, medium, large }

/// Quick action button for dashboard-like interfaces
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      type: ButtonType.elevated,
      customColor: color,
    );
  }
}

/// Primary action button for CTAs and main actions
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: isLoading,
      fullWidth: fullWidth,
      type: ButtonType.elevated,
    );
  }
}

/// Secondary action button for alternative actions
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      type: ButtonType.outlined,
    );
  }
}