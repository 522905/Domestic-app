import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';

/// Card for weight inputs (tare, gross, net)
class WeightInputCard extends StatelessWidget {
  final TextEditingController tareController;
  final TextEditingController grossController;
  final String? tareError;
  final String? grossError;
  final VoidCallback? onWeightChanged;

  const WeightInputCard({
    super.key,
    required this.tareController,
    required this.grossController,
    this.tareError,
    this.grossError,
    this.onWeightChanged,
  });

  double get netWeight {
    final tare = double.tryParse(tareController.text) ?? 0;
    final gross = double.tryParse(grossController.text) ?? 0;
    return gross - tare;
  }

  bool get isWeightValid {
    final tare = double.tryParse(tareController.text) ?? 0;
    final gross = double.tryParse(grossController.text) ?? 0;
    return tare > 0 && gross > tare;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.scale,
                  color: AppColorsEnhanced.brandBlue,
                  size: 20.sp,
                ),
                SizedBox(width: AppSpacing.xs.w),
                Text(
                  'Weight Information',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColorsEnhanced.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),

            // Tare Weight Input
            _buildWeightInput(
              label: 'Tare Weight (kg) *',
              controller: tareController,
              errorText: tareError,
              icon: Icons.fitness_center,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Gross Weight Input
            _buildWeightInput(
              label: 'Gross Weight (kg) *',
              controller: grossController,
              errorText: grossError,
              icon: Icons.monitor_weight,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Net Weight Display
            Container(
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: isWeightValid
                    ? AppColorsEnhanced.successGreen.withOpacity(0.1)
                    : AppColorsEnhanced.lightGray.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isWeightValid
                      ? AppColorsEnhanced.successGreen
                      : AppColorsEnhanced.lightGray,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calculate,
                        color: isWeightValid
                            ? AppColorsEnhanced.successGreen
                            : AppColorsEnhanced.darkGray.withOpacity(0.5),
                        size: 20.sp,
                      ),
                      SizedBox(width: AppSpacing.sm.w),
                      Text(
                        'Net Weight',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColorsEnhanced.darkGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${netWeight.toStringAsFixed(2)} kg',
                    style: AppTextStyles.h2.copyWith(
                      color: isWeightValid
                          ? AppColorsEnhanced.successGreen
                          : AppColorsEnhanced.darkGray.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeightInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: AppColorsEnhanced.brandBlue,
              size: 20.sp,
            ),
            hintText: '0.00',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppColorsEnhanced.lightGray,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColorsEnhanced.errorRed
                    : AppColorsEnhanced.lightGray,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: errorText != null
                    ? AppColorsEnhanced.errorRed
                    : AppColorsEnhanced.brandBlue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide(
                color: AppColorsEnhanced.errorRed,
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md.w,
              vertical: AppSpacing.md.h,
            ),
            errorText: errorText,
            errorStyle: AppTextStyles.labelMedium.copyWith(
              color: AppColorsEnhanced.errorRed,
            ),
          ),
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w500,
          ),
          onChanged: (_) => onWeightChanged?.call(),
        ),
      ],
    );
  }
}
