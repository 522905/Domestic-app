import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../domain/entities/bonus/bonus.dart';

/// Badge widget to display expiry urgency
class BonusUrgencyBadge extends StatelessWidget {
  final ExpiryUrgency urgency;

  const BonusUrgencyBadge({
    Key? key,
    required this.urgency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12.sp,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Text(
            _getLabel(),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (urgency) {
      case ExpiryUrgency.expiringToday:
        return Colors.red;
      case ExpiryUrgency.expiringTomorrow:
        return Colors.orange;
      case ExpiryUrgency.expiringSoon:
        return Colors.yellow[700]!;
    }
  }

  String _getLabel() {
    switch (urgency) {
      case ExpiryUrgency.expiringToday:
        return 'Today';
      case ExpiryUrgency.expiringTomorrow:
        return 'Tomorrow';
      case ExpiryUrgency.expiringSoon:
        return 'Soon';
    }
  }
}
