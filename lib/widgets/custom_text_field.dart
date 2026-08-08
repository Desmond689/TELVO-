// lib/widgets/custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:telvo/utils/app_colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
  });
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? maxLength;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = isDark
        ? const Color(0xFF1E293B)
        : AppColors.surfaceMuted;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: TextStyle(
        color: textColor,
        fontSize: 15,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        counterText: '',
        labelStyle: TextStyle(
          color: textColor.withValues(alpha: 0.85),
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: textColor.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
    );
  }
}