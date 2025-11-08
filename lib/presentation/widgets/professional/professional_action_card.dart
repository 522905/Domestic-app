import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/borders.dart';

/// Professional action card with large icon and subtitle
/// Use for: Dashboard quick actions, navigation cards
class ProfessionalActionCard extends StatelessWidget {
  /// Card title
  final String title;

  /// Card subtitle/description
  final String subtitle;

  /// Icon to display
  final IconData icon;

  /// Tap callback
  final VoidCallback? onTap;

  /// Optional badge count (shows in top-right corner)
  final int? badgeCount;

  /// Optional icon background color
  final Color? iconColor;

  /// Optional icon background gradient
  final Gradient? iconGradient;

  /// Whether card is disabled
  final bool disabled;

  const ProfessionalActionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.badgeCount,
    this.iconColor,
    this.iconGradient,
    this.disabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: AppSpacing.roundedLG,
          child: Container(
            decoration: AppBorders.cardDecoration,
            padding: AppSpacing.cardContentPadding,
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon Container
                    Container(
                      padding: AppSpacing.paddingMD,
                      decoration: BoxDecoration(
                        color: iconColor,
                        gradient: iconGradient ?? AppColorsEnhanced.primaryGradient,
                        borderRadius: AppSpacing.roundedMD,
                        boxShadow: AppBorders.shadowLight,
                      ),
                      child: Icon(
                        icon,
                        size: AppSpacing.iconLG,
                        color: AppColorsEnhanced.inverseText,
                      ),
                    ),

                    SizedBox(height: AppSpacing.md),

                    // Title
                    Text(
                      title,
                      style: AppTextStyles.h4,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Badge (if count provided)
                if (badgeCount != null && badgeCount! > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsEnhanced.badgeBackground,
                        borderRadius: AppSpacing.roundedCircular,
                        boxShadow: AppBorders.shadowLight,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20.w,
                        minHeight: 20.h,
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : badgeCount.toString(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.badgeText,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
