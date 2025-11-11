import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/dir_item.dart';

/// Widget to display a DIR item in a list
class DIRItemRow extends StatelessWidget {
  final DIRItem item;
  final int index;
  final VoidCallback? onRemove;
  final VoidCallback? onEdit;
  final bool showActions;

  const DIRItemRow({
    super.key,
    required this.item,
    required this.index,
    this.onRemove,
    this.onEdit,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with item number and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm.w,
                    vertical: AppSpacing.xs.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.brandBlue,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Item ${index + 1}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showActions)
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: AppColorsEnhanced.brandBlue,
                            size: 20.sp,
                          ),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (onRemove != null) ...[
                        SizedBox(width: AppSpacing.sm.w),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColorsEnhanced.errorRed,
                            size: 20.sp,
                          ),
                          onPressed: onRemove,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),

            // Filled Item
            _buildInfoRow(
              icon: Icons.propane_tank,
              label: 'Filled Item',
              value: item.sourceItemName,
              iconColor: AppColorsEnhanced.brandBlue,
            ),
            SizedBox(height: AppSpacing.sm.h),

            // Defect Type
            _buildInfoRow(
              icon: Icons.error_outline,
              label: 'Defect Type',
              value: item.targetItemName,
              iconColor: AppColorsEnhanced.warningYellow,
            ),
            SizedBox(height: AppSpacing.sm.h),

            // Cylinder Serial
            _buildInfoRow(
              icon: Icons.qr_code,
              label: 'Serial',
              value: item.cylinderNumber,
              iconColor: AppColorsEnhanced.infoBlue,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Weight Information
            Container(
              padding: EdgeInsets.all(AppSpacing.sm.w),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColorsEnhanced.successGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeightChip(
                    label: 'Tare',
                    value: item.tareWeight,
                    icon: Icons.fitness_center,
                  ),
                  _buildWeightChip(
                    label: 'Gross',
                    value: item.grossWeight,
                    icon: Icons.monitor_weight,
                  ),
                  _buildWeightChip(
                    label: 'Net',
                    value: item.netWeight,
                    icon: Icons.calculate,
                    highlight: true,
                  ),
                ],
              ),
            ),

            // Fault Description (if provided)
            if (item.faultType != null && item.faultType!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.sm.h),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm.w),
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.lightGray.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description,
                      size: 16.sp,
                      color: AppColorsEnhanced.darkGray,
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    Expanded(
                      child: Text(
                        item.faultType!,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColorsEnhanced.darkGray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: iconColor,
        ),
        SizedBox(width: AppSpacing.sm.w),
        Text(
          '$label: ',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.darkGray,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightChip({
    required String label,
    required double value,
    required IconData icon,
    bool highlight = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: highlight
              ? AppColorsEnhanced.successGreen
              : AppColorsEnhanced.darkGray.withOpacity(0.7),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
            fontSize: 10.sp,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '${value.toStringAsFixed(2)} kg',
          style: AppTextStyles.bodyMedium.copyWith(
            color: highlight
                ? AppColorsEnhanced.successGreen
                : AppColorsEnhanced.darkGray,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
