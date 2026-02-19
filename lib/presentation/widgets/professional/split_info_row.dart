import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';

/// Split info row widget with 60/40 left/right layout
/// Use for: Displaying two related pieces of information side by side
class SplitInfoRow extends StatelessWidget {
  final String leftLabel;
  final String leftValue;
  final IconData? leftIcon;
  final Color? leftIconColor;
  final String rightLabel;
  final String rightValue;
  final IconData? rightIcon;
  final Color? rightIconColor;

  const SplitInfoRow({
    Key? key,
    required this.leftLabel,
    required this.leftValue,
    this.leftIcon,
    this.leftIconColor,
    required this.rightLabel,
    required this.rightValue,
    this.rightIcon,
    this.rightIconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (60%)
        Expanded(
          flex: 6,
          child: _buildInfoColumn(
            label: leftLabel,
            value: leftValue,
            icon: leftIcon,
            iconColor: leftIconColor,
            align: CrossAxisAlignment.start,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Vertical divider
        Container(
          width: 1,
          height: 35.h,
          color: AppColorsEnhanced.border.withOpacity(0.3),
        ),
        SizedBox(width: AppSpacing.sm),
        // Right column (40%)
        Expanded(
          flex: 4,
          child: _buildInfoColumn(
            label: rightLabel,
            value: rightValue,
            icon: rightIcon,
            iconColor: rightIconColor,
            align: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoColumn({
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
    required CrossAxisAlignment align,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColorsEnhanced.secondaryText,
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: AppSpacing.xs / 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: iconColor ?? AppColorsEnhanced.secondaryText,
              ),
              SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
