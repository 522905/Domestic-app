import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../professional/professional_button.dart';

class InstallationSearchBar extends StatefulWidget {
  final Function(String) onSearchPressed;
  final String? hintText;

  const InstallationSearchBar({
    Key? key,
    required this.onSearchPressed,
    this.hintText,
  }) : super(key: key);

  @override
  State<InstallationSearchBar> createState() => _InstallationSearchBarState();
}

class _InstallationSearchBarState extends State<InstallationSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {}); // Trigger rebuild to hide clear button
    widget.onSearchPressed(''); // Trigger search with empty query to reload all
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColorsEnhanced.background,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColorsEnhanced.border,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) {
                  setState(() {}); // Trigger rebuild to show/hide clear button
                },
                onSubmitted: (value) => widget.onSearchPressed(value),
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: widget.hintText ?? 'Search by name, app#, mobile, Aadhaar...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColorsEnhanced.brandBlue,
                    size: 20.r,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: AppColorsEnhanced.secondaryText,
                            size: 20.r,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          ProfessionalButton(
            text: 'Search',
            variant: ButtonVariant.primary,
            onPressed: () => widget.onSearchPressed(_controller.text),
            size: ButtonSize.medium,
          ),
        ],
      ),
    );
  }
}
