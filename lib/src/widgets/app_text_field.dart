import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../themes/app_theme.dart';

/// Reusable text field component following the app's design system
/// 
/// Features:
/// - Consistent input decoration
/// - Support for various input types
/// - Validation handling
/// - Icon support
/// - Custom styling options
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.initialValue,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.onTap,
    this.filled = true,
    this.fillColor,
    this.borderRadius,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool readOnly;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final String? initialValue;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final bool autocorrect;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final bool filled;
  final Color? fillColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: AppTheme.spacingS),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          onChanged: onChanged,
          validator: validator,
          onSaved: onSaved,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          readOnly: readOnly,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          prefixText: prefixText,
          suffixText: suffixText,
          enabled: enabled,
          autofocus: autofocus,
          autocorrect: autocorrect,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onTap: onTap,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            filled: filled,
            fillColor: fillColor ?? AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.mediumRadius,
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.mediumRadius,
              ),
              borderSide: const BorderSide(
                color: AppTheme.outline,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.mediumRadius,
              ),
              borderSide: const BorderSide(
                color: AppTheme.primaryGreen,
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.mediumRadius,
              ),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 1.0,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                borderRadius ?? AppTheme.mediumRadius,
              ),
              borderSide: const BorderSide(
                color: AppTheme.error,
                width: 2.0,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingM,
              vertical: AppTheme.spacingM,
            ),
            hintStyle: const TextStyle(
              color: AppTheme.outline,
              fontFamily: AppTheme.fontFamily,
            ),
            counterStyle: const TextStyle(
              color: AppTheme.outline,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ),
      ],
    );
  }
}

/// Search-specific text field with search icon
class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hintText = 'Search...',
    this.focusNode,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final FocusNode? focusNode;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      enabled: enabled,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: AppTheme.surfaceVariant,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          borderSide: const BorderSide(
            color: AppTheme.outline,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
          borderSide: const BorderSide(
            color: AppTheme.primaryGreen,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingM,
        ),
        hintStyle: const TextStyle(
          color: AppTheme.outline,
          fontFamily: AppTheme.fontFamily,
        ),
      ),
    );
  }
}

/// Multi-line text field for long-form input
class TextArea extends StatelessWidget {
  const TextArea({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.minLines = 4,
    this.maxLines = 6,
    this.maxLength,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int minLines;
  final int maxLines;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
    );
  }
}

/// Password input field with visibility toggle
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.onChanged,
    this.validator,
    this.onSaved,
  });

  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      hintText: widget.hintText,
      controller: widget.controller,
      onChanged: widget.onChanged,
      validator: widget.validator,
      onSaved: widget.onSaved,
      obscureText: _obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility : Icons.visibility_off,
        ),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
    );
  }
}