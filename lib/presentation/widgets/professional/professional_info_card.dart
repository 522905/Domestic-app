import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/borders.dart';

/// Professional info card for displaying label-value pairs
/// Use for: Profile information, details screens, summary cards
class ProfessionalInfoCard extends StatelessWidget {
  /// Card title (optional)
  final String? title;

  /// List of information items (label-value pairs)
  final List<InfoItem> items;

  /// Optional card action (e.g., edit button)
  final Widget? action;

  /// Optional icon for card header
  final IconData? icon;

  /// Tap callback (makes entire card tappable if provided)
  final VoidCallback? onTap;

  const ProfessionalInfoCard({
    Key? key,
    this.title,
    required this.items,
    this.action,
    this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget cardContent = Container(
      decoration: AppBorders.cardDecoration,
      padding: AppSpacing.cardContentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header (title + action)
          if (title != null || action != null)
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppSpacing.iconMD,
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  SizedBox(width: AppSpacing.sm),
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTextStyles.h3,
                    ),
                  ),
                if (action != null) action!,
              ],
            ),

          if (title != null || action != null) SizedBox(height: AppSpacing.md),

          // Info Items
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == items.length - 1;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoRow(item),
                if (!isLast) SizedBox(height: AppSpacing.md),
              ],
            );
          }).toList(),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppSpacing.roundedLG,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  Widget _buildInfoRow(InfoItem item) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (item.label != null)
          Expanded(
            flex: 2,
            child: Text(
              item.label!,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          ),

        // Spacing
        if (item.label != null) SizedBox(width: AppSpacing.md),

        // Value
        Expanded(
          flex: 3,
          child: item.customValue ??
              Text(
                item.value ?? '-',
                style: AppTextStyles.bodyMedium,
                textAlign: item.label != null ? TextAlign.end : TextAlign.start,
              ),
        ),
      ],
    );
  }
}

/// Information item model
class InfoItem {
  /// Label text (left side)
  final String? label;

  /// Value text (right side)
  final String? value;

  /// Custom value widget (overrides value text)
  final Widget? customValue;

  const InfoItem({
    this.label,
    this.value,
    this.customValue,
  }) : assert(value != null || customValue != null, 'Either value or customValue must be provided');
}
