// lib/presentation/widgets/orders/quota_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/order/selectable_order_item.dart';
// import '../../theme/app_colors.dart';
/// Widget that displays a color-coded badge showing quota status
class QuotaBadge extends StatelessWidget {
  final QuotaInfo quota;

  const QuotaBadge({
    super.key,
    required this.quota,
  });

  @override
  Widget build(BuildContext context) {
    final status = quota.status;
    final config = _getBadgeConfig(status);

    // Check if extension indicator should be shown
    if (quota.hasActiveExtension && quota.extensionAvailable > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Regular quota badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(
                color: config.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  config.icon,
                  size: 12.sp,
                  color: config.textColor,
                ),
                SizedBox(width: 4.w),
                Text(
                  config.text,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: config.textColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4.w),
          // Extension indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.purple.shade700,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.card_giftcard, color: Colors.white, size: 10.sp),
                SizedBox(width: 3.w),
                Text(
                  '+${quota.extensionAvailable}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Regular badge without extension
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(
          color: config.borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 12.sp,
            color: config.textColor,
          ),
          SizedBox(width: 4.w),
          Text(
            config.text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _BadgeConfig _getBadgeConfig(QuotaStatus status) {
    switch (status) {
      case QuotaStatus.unlimited:
        // Check which bypass mode is active
        if (quota.isQuotaDisabled) {
          return _BadgeConfig(
            text: 'Q: Disabled',
            icon: Icons.block,
            textColor: Colors.grey[700]!,
            backgroundColor: Colors.grey[100]!,
            borderColor: Colors.grey[300]!,
          );
        } else if (quota.isSdmsDown) {
          return _BadgeConfig(
            text: 'SDMS Down',
            icon: Icons.warning_amber,
            textColor: Colors.amber[900]!,
            backgroundColor: Colors.amber[50]!,
            borderColor: Colors.amber[300]!,
          );
        } else if (quota.isPartnerExempt) {
          return _BadgeConfig(
            text: 'Q: Exempt',
            icon: Icons.verified,
            textColor: Colors.blue[700]!,
            backgroundColor: Colors.blue[50]!,
            borderColor: Colors.blue[300]!,
          );
        } else {
          // Item not in quota system
          return _BadgeConfig(
            text: 'No Limit',
            icon: Icons.check_circle,
            textColor: Colors.grey[600]!,
            backgroundColor: Colors.grey[50]!,
            borderColor: Colors.grey[200]!,
          );
        }

      case QuotaStatus.available:
        // Available quota > 10
        return _BadgeConfig(
          text: 'Q: ${quota.available}',
          icon: Icons.check_circle,
          textColor: Colors.green[800]!,
          backgroundColor: Colors.green[50]!,
          borderColor: Colors.green[300]!,
        );

      case QuotaStatus.low:
        // Low quota (1-10)
        return _BadgeConfig(
          text: 'Q: ${quota.available}',
          icon: Icons.warning,
          textColor: Colors.orange[800]!,
          backgroundColor: Colors.orange[50]!,
          borderColor: Colors.orange[300]!,
        );

      case QuotaStatus.zero:
        // Zero quota
        return _BadgeConfig(
          text: 'Q: 0',
          icon: Icons.cancel,
          textColor: Colors.red[800]!,
          backgroundColor: Colors.red[50]!,
          borderColor: Colors.red[300]!,
        );

      case QuotaStatus.blocked:
        // Over quota (negative balance)
        return _BadgeConfig(
          text: 'Over Quota',
          icon: Icons.block,
          textColor: Colors.red[900]!,
          backgroundColor: Colors.red[100]!,
          borderColor: Colors.red[400]!,
        );
    }
  }
}

/// Configuration for badge appearance
class _BadgeConfig {
  final String text;
  final IconData icon;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  _BadgeConfig({
    required this.text,
    required this.icon,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });
}
