import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Progress bar widget to show bonus consumption percentage
class BonusProgressBar extends StatelessWidget {
  final double consumptionPercentage;
  final bool isExpiringSoon;

  const BonusProgressBar({
    Key? key,
    required this.consumptionPercentage,
    this.isExpiringSoon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Consumption',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
            Text(
              '${consumptionPercentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: LinearProgressIndicator(
            value: consumptionPercentage / 100,
            minHeight: 6.h,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    if (isExpiringSoon && consumptionPercentage < 50) {
      return Colors.orange; // Expiring but not used much
    } else if (consumptionPercentage >= 80) {
      return Colors.red; // Almost consumed
    } else if (consumptionPercentage >= 50) {
      return Colors.orange; // Half consumed
    } else {
      return Colors.green; // Fresh bonus
    }
  }
}
