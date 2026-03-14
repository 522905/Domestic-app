import 'package:flutter/material.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/distribution_point.dart';

class CompactDistributionPointPicker extends StatelessWidget {
  final List<DistributionPoint> points;
  final DistributionPoint? selected;
  final ValueChanged<String> onSelect;

  const CompactDistributionPointPicker({
    Key? key,
    required this.points,
    this.selected,
    required this.onSelect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'No distribution points',
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: points.map((point) => _buildChip(point)).toList(),
      ),
    );
  }

  Widget _buildChip(DistributionPoint point) {
    final isSelected = selected?.id == point.id;

    return Padding(
      padding: EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(point.id),
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white24,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Colors.blue.shade700,
                    ),
                  ),
                Icon(
                  point.isAdhoc ? Icons.local_shipping : Icons.warehouse,
                  size: 15,
                  color: isSelected ? Colors.blue.shade700 : Colors.white70,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  point.name,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.blue.shade700 : Colors.white,
                  ),
                ),
                if (point.todayTokenCount > 0) ...[
                  SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.blue.shade700.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${point.todayTokenCount}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.blue.shade700 : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
