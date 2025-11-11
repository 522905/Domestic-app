import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/borders.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/app_icons.dart';

/// Professional status badge with icon and colored background
/// Automatically styles based on status (approved, pending, rejected, etc.)
class ProfessionalStatusBadge extends StatelessWidget {
  /// Status text to display
  final String status;

  /// Optional custom icon (auto-selected if null)
  final IconData? icon;

  /// Optional custom color (auto-selected if null)
  final Color? color;

  /// Badge size (small, medium, large)
  final BadgeSize size;

  /// Whether to show icon
  final bool showIcon;

  const ProfessionalStatusBadge({
    Key? key,
    required this.status,
    this.icon,
    this.color,
    this.size = BadgeSize.medium,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = color ?? AppColorsEnhanced.getStatusColor(status);
    final statusIcon = icon ?? AppIcons.getStatusIcon(status);

    return Container(
      padding: _getPadding(),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.lighten(statusColor, 0.85),
        borderRadius: AppSpacing.roundedCircular,
        border: Border.all(
          color: statusColor,
          width: AppBorders.thin,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              statusIcon,
              size: _getIconSize(),
              color: statusColor,
            ),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            status,
            style: _getTextStyle().copyWith(
              color: AppColorsEnhanced.darken(statusColor, 0.3),
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case BadgeSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        );
      case BadgeSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case BadgeSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case BadgeSize.small:
        return AppTextStyles.labelSmall;
      case BadgeSize.medium:
        return AppTextStyles.labelMedium;
      case BadgeSize.large:
        return AppTextStyles.labelLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case BadgeSize.small:
        return AppSpacing.iconXS;
      case BadgeSize.medium:
        return AppSpacing.iconSM;
      case BadgeSize.large:
        return AppSpacing.iconMD;
    }
  }
}

/// Badge size enum
enum BadgeSize {
  small,
  medium,
  large,
}
