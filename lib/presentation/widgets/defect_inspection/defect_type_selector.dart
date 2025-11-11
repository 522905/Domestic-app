import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/master_data.dart';

/// Dropdown selector for defective item types
class DefectTypeSelector extends StatelessWidget {
  final List<DefectiveOption> options;
  final DefectiveOption? selectedOption;
  final ValueChanged<DefectiveOption?> onChanged;
  final String? errorText;
  final bool enabled;

  const DefectTypeSelector({
    super.key,
    required this.options,
    required this.selectedOption,
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
          'Defect Type *',
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
          child: DropdownButtonFormField<DefectiveOption>(
            value: selectedOption,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w,
                vertical: AppSpacing.sm.h,
              ),
              border: InputBorder.none,
              hintText: options.isEmpty ? 'Select filled item first' : 'Select defect type',
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
            items: options.map((option) {
              return DropdownMenuItem<DefectiveOption>(
                value: option,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.itemName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorsEnhanced.darkGray,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.description.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        option.description,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColorsEnhanced.darkGray.withOpacity(0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            onChanged: enabled && options.isNotEmpty ? onChanged : null,
          ),
        ),
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
