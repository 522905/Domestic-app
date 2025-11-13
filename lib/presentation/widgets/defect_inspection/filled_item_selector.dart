import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/master_data.dart';

/// Dropdown selector for filled items with stock availability display
class FilledItemSelector extends StatelessWidget {
  final List<FilledItemMasterData> items;
  final FilledItemMasterData? selectedItem;
  final ValueChanged<FilledItemMasterData?> onChanged;
  final String? errorText;
  final bool enabled;

  const FilledItemSelector({
    super.key,
    required this.items,
    required this.selectedItem,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filled Item *',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : AppColorsEnhanced.lightGray,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: errorText != null
                  ? AppColorsEnhanced.errorRed
                  : AppColorsEnhanced.lightGray,
              width: 1.5,
            ),
          ),
          child: DropdownButtonFormField<FilledItemMasterData>(
            value: selectedItem,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.sm.h,
              ),
              border: InputBorder.none,
              hintText: 'Select filled item',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColorsEnhanced.darkGray.withOpacity(0.5),
              ),
            ),
            dropdownColor: Colors.white,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColorsEnhanced.brandBlue,
              size: 28.sp,
            ),
            isExpanded: true,
            items: items.map((item) {
              return DropdownMenuItem<FilledItemMasterData>(
                value: item,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.sourceItemName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColorsEnhanced.darkGray,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    Text(
                      'Stock: ${item.availableStock.toStringAsFixed(0)}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: item.availableStock > 0
                            ? AppColorsEnhanced.successGreen
                            : AppColorsEnhanced.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
          ),
        ),
        if (selectedItem != null) ...[
          SizedBox(height: AppSpacing.xs.h),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.infoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16.sp,
                  color: AppColorsEnhanced.infoBlue,
                ),
                SizedBox(width: AppSpacing.xs.w),
                Expanded(
                  child: Text(
                    'Available: ${selectedItem!.availableStock.toStringAsFixed(0)} units in stock',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColorsEnhanced.infoBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (errorText != null) ...[
          SizedBox(height: AppSpacing.xs.h),
          Text(
            errorText!,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColorsEnhanced.errorRed,
            ),
          ),
        ],
      ],
    );
  }
}
