import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/distribution_point.dart';

class DistributionPointPicker extends StatelessWidget {
  final List<DistributionPoint> points;
  final DistributionPoint? selected;
  final ValueChanged<String> onSelect;

  const DistributionPointPicker({
    Key? key,
    required this.points,
    this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Text(
          'No distribution points available',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColorsEnhanced.secondaryText,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            'Distribution Point',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        ...points.map((point) => _buildPointCard(point)),
      ],
    );
  }

  Widget _buildPointCard(DistributionPoint point) {
    final isSelected = selected?.id == point.id;

    return GestureDetector(
      onTap: () => onSelect(point.id),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsEnhanced.brandBlue.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              point.isAdhoc ? Icons.local_shipping : Icons.warehouse,
              color: isSelected
                  ? AppColorsEnhanced.brandBlue
                  : AppColorsEnhanced.secondaryText,
              size: 24,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    point.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColorsEnhanced.brandBlue
                          : null,
                    ),
                  ),
                  if (point.physicalSiteName != null)
                    Text(
                      point.physicalSiteName!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            if (point.todayTokenCount > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${point.todayTokenCount}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.brandBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (isSelected)
              Padding(
                padding: EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(
                  Icons.check_circle,
                  color: AppColorsEnhanced.brandBlue,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
