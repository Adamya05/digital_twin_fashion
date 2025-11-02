import 'package:flutter/material.dart';
import '../../../themes/app_theme.dart';

/// Reusable chip component following the app's design system
/// 
/// Features:
/// - Multiple chip types (choice, filter, action)
/// - Consistent styling with theme
/// - Support for icons and avatars
/// - Custom colors and sizes
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.onSelected,
    this.onDeleted,
    this.isSelected = false,
    this.avatar,
    this.deleteIcon,
    this.backgroundColor,
    this.selectedColor,
    this.deleteIconColor,
    this.labelStyle,
    this.selectedLabelStyle,
    this.shape,
    this.clipBehavior = Clip.none,
    this.visualDensity,
  });

  final String label;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onDeleted;
  final bool isSelected;
  final Widget? avatar;
  final Widget? deleteIcon;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? deleteIconColor;
  final TextStyle? labelStyle;
  final TextStyle? selectedLabelStyle;
  final ShapeBorder? shape;
  final Clip clipBehavior;
  final VisualDensity? visualDensity;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: isSelected
            ? selectedLabelStyle ??
                Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.onPrimary,
                    )
            : labelStyle ??
                Theme.of(context).textTheme.labelMedium,
      ),
      onDeleted: onDeleted,
      onSelected: onSelected,
      isSelected: isSelected,
      avatar: avatar,
      deleteIcon: deleteIcon ?? const Icon(
        Icons.close,
        size: 18,
      ),
      backgroundColor: backgroundColor ?? AppTheme.surfaceVariant,
      selectedColor: selectedColor ?? AppTheme.primaryGreen,
      deleteIconColor: deleteIconColor ?? AppTheme.onPrimary,
      shape: shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            side: BorderSide(
              color: isSelected ? Colors.transparent : AppTheme.outline,
            ),
          ),
      clipBehavior: clipBehavior,
      visualDensity: visualDensity ?? VisualDensity.compact,
    );
  }
}

/// Filter chip for selection options
class FilterChip extends StatelessWidget {
  const FilterChip({
    super.key,
    required this.label,
    required this.onSelected,
    this.isSelected = false,
    this.leadingIcon,
    this.trailingIcon,
    this.selectedColor,
    this.unselectedColor,
  });

  final String label;
  final ValueChanged<bool> onSelected;
  final bool isSelected;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? selectedColor;
  final Color? unselectedColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppTheme.spacingS),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 16,
                color: isSelected
                    ? AppTheme.onPrimary
                    : AppTheme.textDarkGray,
              ),
              const SizedBox(width: AppTheme.spacingXs),
            ],
            Text(label),
            if (trailingIcon != null) ...[
              const SizedBox(width: AppTheme.spacingXs),
              Icon(
                trailingIcon,
                size: 16,
                color: isSelected
                    ? AppTheme.onPrimary
                    : AppTheme.textDarkGray,
              ),
            ],
          ],
        ),
        onSelected: onSelected,
        isSelected: isSelected,
        selectedColor: selectedColor ?? AppTheme.primaryGreen,
        backgroundColor: unselectedColor ?? AppTheme.surfaceVariant,
        labelStyle: TextStyle(
          color: isSelected
              ? AppTheme.onPrimary
              : AppTheme.textDarkGray,
          fontFamily: AppTheme.fontFamily,
          fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        side: BorderSide(
          color: isSelected ? Colors.transparent : AppTheme.outline,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
      ),
    );
  }
}

/// Action chip for triggering specific actions
class ActionChip extends StatelessWidget {
  const ActionChip({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.avatar,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? avatar;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      avatar: avatar,
      backgroundColor:
          backgroundColor ?? AppTheme.surfaceVariant,
      foregroundColor: foregroundColor ?? AppTheme.textDarkGray,
      elevation: elevation ?? 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Input chip for user input selection
class InputChip extends StatelessWidget {
  const InputChip({
    super.key,
    required this.label,
    required this.onDeleted,
    this.avatar,
    this.selected = false,
    this.onSelected,
    this.backgroundColor,
    this.selectedColor,
  });

  final String label;
  final VoidCallback onDeleted;
  final Widget? avatar;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Color? backgroundColor;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      onSelected: onSelected,
      avatar: avatar,
      selected: selected,
      backgroundColor:
          backgroundColor ?? AppTheme.surfaceVariant,
      selectedColor: selectedColor ?? AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.onPrimary
            : AppTheme.textDarkGray,
        fontFamily: AppTheme.fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
      ),
      deleteIconColor: selected ? AppTheme.onPrimary : AppTheme.outline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        side: BorderSide(
          color: selected ? Colors.transparent : AppTheme.outline,
        ),
      ),
    );
  }
}

/// Tag chip for displaying tags and labels
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.color,
    this.textColor,
    this.onTap,
    this.padding,
  });

  final String label;
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ??
            const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingS,
              vertical: AppTheme.spacingXs,
            ),
        decoration: BoxDecoration(
          color: color ?? AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor ?? AppTheme.textDarkGray,
            fontFamily: AppTheme.fontFamily,
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Category chip with icon support
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
    this.iconColor,
    this.selectedIconColor,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? iconColor;
  final Color? selectedIconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor ?? AppTheme.primaryGreen
              : backgroundColor ?? AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? selectedIconColor ?? AppTheme.onPrimary
                  : iconColor ?? AppTheme.textDarkGray,
            ),
            const SizedBox(width: AppTheme.spacingS),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? selectedIconColor ?? AppTheme.onPrimary
                    : textColor ?? AppTheme.textDarkGray,
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color? get textColor => null;
}