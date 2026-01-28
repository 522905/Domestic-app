import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';

class QuotaFlowTimeline extends StatelessWidget {
  final int opening;
  final int totalAdjustment;
  final int closing;

  const QuotaFlowTimeline({
    Key? key,
    required this.opening,
    required this.totalAdjustment,
    required this.closing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Opening node
          Expanded(
            child: _buildTimelineNode(
              icon: Icons.account_balance,
              label: 'Starting',
              value: opening,
              color: AppColors.brandBlue,
            ),
          ),

          // Arrow
          Icon(
            Icons.arrow_forward,
            size: 32.sp,
            color: Colors.grey.shade400,
          ),

          // Adjustment node
          Expanded(
            child: _buildTimelineNode(
              icon: Icons.swap_vert,
              label: 'Changes',
              value: totalAdjustment,
              color: totalAdjustment >= 0
                  ? AppColors.successGreen
                  : AppColors.errorRed,
              showSign: true,
            ),
          ),

          // Arrow
          Icon(
            Icons.arrow_forward,
            size: 32.sp,
            color: Colors.grey.shade400,
          ),

          // Closing node
          Expanded(
            child: _buildTimelineNode(
              icon: Icons.inventory,
              label: 'Final',
              value: closing,
              color: AppColors.brandBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNode({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool showSign = false,
  }) {
    final String displayValue = showSign && value >= 0 ? '+$value' : '$value';

    return Column(
      children: [
        // Icon in circle
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
        ),

        SizedBox(height: 8.h),

        // Value (BIG)
        Text(
          displayValue,
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
            color: color,
            height: 1.2,
          ),
        ),

        SizedBox(height: 4.h),

        // Label (small)
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
