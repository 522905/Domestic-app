import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';
import 'metric_display.dart';

class AvailableBalanceCard extends StatelessWidget {
  final int availableBalance;
  final int bonus;
  final int creditLimit;
  final bool isBlocked;

  const AvailableBalanceCard({
    Key? key,
    required this.availableBalance,
    required this.bonus,
    required this.creditLimit,
    required this.isBlocked,
  }) : super(key: key);

  Color _getStatusColor() {
    if (isBlocked) {
      return AppColors.errorRed;
    }
    if (availableBalance == 0) {
      return Colors.grey.shade600;
    }
    if (availableBalance <= 10) {
      return Colors.orange.shade700;
    }
    return AppColors.successGreen;
  }

  List<Color> _getGradientColors() {
    final baseColor = _getStatusColor();
    return [
      baseColor,
      HSLColor.fromColor(baseColor).withLightness(0.35).toColor(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getGradientColors(),
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status icon
          Icon(
            isBlocked ? Icons.block : Icons.check_circle,
            size: 40.sp,
            color: Colors.white,
          ),
          SizedBox(height: 8.h),

          // "Available Balance" label
          Text(
            'Available Balance',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),

          // HUGE balance number
          Text(
            '$availableBalance',
            style: TextStyle(
              fontSize: 56.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),

          // "Cylinders" label
          Text(
            'Cylinders',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),

          SizedBox(height: 16.h),

          // Divider
          Divider(
            color: Colors.white.withOpacity(0.3),
            thickness: 1,
          ),

          SizedBox(height: 16.h),

          // Secondary metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MetricDisplay(
                icon: Icons.card_giftcard,
                label: 'Bonus',
                value: bonus,
                color: Colors.white,
              ),
              Container(
                width: 1,
                height: 60.h,
                color: Colors.white.withOpacity(0.3),
              ),
              MetricDisplay(
                icon: Icons.credit_card,
                label: 'Credit Limit',
                value: creditLimit,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
