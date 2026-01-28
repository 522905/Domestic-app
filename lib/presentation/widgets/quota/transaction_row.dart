import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';

class TransactionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final bool isAddition;

  const TransactionRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.isAddition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isZero = value == 0;
    final displayValue = value.abs();
    final color = isZero
        ? Colors.grey
        : (isAddition ? AppColors.successGreen : AppColors.errorRed);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Direction indicator
          Icon(
            isAddition ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 24.sp,
          ),

          SizedBox(width: 12.w),

          // Transaction icon in colored box
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20.sp,
            ),
          ),

          SizedBox(width: 12.w),

          // Label
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),

          // Value with sign
          Text(
            '${isAddition ? '+' : '-'}$displayValue',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
