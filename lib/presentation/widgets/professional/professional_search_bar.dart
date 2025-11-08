import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/borders.dart';

/// Professional search bar with icon, clear button, and filter action
/// Responsive and accessible with proper theming
class ProfessionalSearchBar extends StatefulWidget {
  /// Hint text for search input
  final String hintText;

  /// Callback when search text changes
  final ValueChanged<String>? onChanged;

  /// Callback when search is submitted
  final ValueChanged<String>? onSubmitted;

  /// Initial search value
  final String? initialValue;

  /// Optional filter button callback
  final VoidCallback? onFilter;

  /// Whether search bar is enabled
  final bool enabled;

  /// Text controller (optional, creates one if not provided)
  final TextEditingController? controller;

  /// Auto focus on mount
  final bool autoFocus;

  const ProfessionalSearchBar({
    Key? key,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.initialValue,
    this.onFilter,
    this.enabled = true,
    this.controller,
    this.autoFocus = false,
  }) : super(key: key);

  @override
  State<ProfessionalSearchBar> createState() => _ProfessionalSearchBarState();
}

class _ProfessionalSearchBarState extends State<ProfessionalSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ??
        TextEditingController(text: widget.initialValue);
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppBorders.inputDecoration,
      child: Row(
        children: [
          // Search Icon
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
            child: Icon(
              AppIcons.search,
              size: AppSpacing.iconMD,
              color: AppColorsEnhanced.secondaryText,
            ),
          ),

          // Text Input
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: widget.enabled,
              autofocus: widget.autoFocus,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTextStyles.hint,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                ),
                isDense: true,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),

          // Clear Button (shown when text is present)
          if (_hasText)
            IconButton(
              icon: Icon(
                AppIcons.close,
                size: AppSpacing.iconSM,
                color: AppColorsEnhanced.secondaryText,
              ),
              onPressed: _clearSearch,
              padding: EdgeInsets.all(AppSpacing.sm),
              constraints: const BoxConstraints(),
            ),

          // Filter Button (optional)
          if (widget.onFilter != null)
            Container(
              margin: EdgeInsets.only(left: AppSpacing.xs),
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: AppColorsEnhanced.border,
                    width: AppBorders.thin,
                  ),
                ),
              ),
              child: IconButton(
                icon: Icon(
                  AppIcons.filter,
                  size: AppSpacing.iconMD,
                  color: AppColorsEnhanced.brandBlue,
                ),
                onPressed: widget.onFilter,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
