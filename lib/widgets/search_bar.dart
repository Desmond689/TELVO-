import 'package:flutter/material.dart';
import 'package:telvo/utils/app_colors.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final String? hintText;

  const CustomSearchBar({
    super.key,
    this.onSearch,
    this.hintText = 'Search professionals...',
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF334155).withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          controller: _controller,
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.textPrimary,
            fontSize: 15,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: isDark
                  ? const Color(0xFF64748B)
                  : AppColors.textHint,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : AppColors.textSecondary,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onSearch?.call('');
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            widget.onSearch?.call(value);
            setState(() {});
          },
          onSubmitted: (value) {
            widget.onSearch?.call(value);
          },
        ),
      ),
    );
  }
}