import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MetricDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  const MetricDisplay({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayColor = color ?? Colors.white;

    return Column(
      children: [
        Icon(
          icon,
          size: 28.sp,
          color: displayColor,
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: displayColor.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: displayColor,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
