import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusBadgeWidget extends StatelessWidget {
  final String status;
  final String statusDisplay;
  final String type; // 'data', 'claim', or 'dpr'

  const StatusBadgeWidget({
    Key? key,
    required this.status,
    required this.statusDisplay,
    this.type = 'data',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14.sp,
            color: colors['text'],
          ),
          SizedBox(width: 4.w),
          Text(
            statusDisplay,
            style: TextStyle(
              color: colors['text'],
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (status.toUpperCase()) {
      case 'QUEUED':
      case 'RPA_PROCESSING':
        return {
          'background': Colors.blue.shade50,
          'text': Colors.blue.shade700,
        };
      case 'COMPLETE':
        return {
          'background': Colors.green.shade50,
          'text': Colors.green.shade700,
        };
      case 'FAILED':
        return {
          'background': Colors.red.shade50,
          'text': Colors.red.shade700,
        };
      case 'INCIDENT':
      case 'REJECTED':
        return {
          'background': Colors.orange.shade50,
          'text': Colors.orange.shade700,
        };
      case 'UNCLAIMED':
        return {
          'background': Colors.yellow.shade50,
          'text': Colors.yellow.shade900,
        };
      case 'PENDING_TRANSFER':
        return {
          'background': Colors.purple.shade50,
          'text': Colors.purple.shade700,
        };
      case 'CLAIMED':
        return {
          'background': Colors.green.shade50,
          'text': Colors.green.shade700,
        };
      case 'SETTLED':
        return {
          'background': Colors.teal.shade50,
          'text': Colors.teal.shade700,
        };
      case 'PENDING':
        return {
          'background': Colors.grey.shade50,
          'text': Colors.grey.shade700,
        };
      default:
        return {
          'background': Colors.grey.shade50,
          'text': Colors.grey.shade700,
        };
    }
  }

  IconData _getIcon() {
    switch (status.toUpperCase()) {
      case 'QUEUED':
      case 'RPA_PROCESSING':
        return Icons.hourglass_empty;
      case 'COMPLETE':
      case 'CLAIMED':
      case 'SETTLED':
        return Icons.check_circle;
      case 'FAILED':
        return Icons.error;
      case 'INCIDENT':
      case 'REJECTED':
        return Icons.warning;
      case 'UNCLAIMED':
        return Icons.circle_outlined;
      case 'PENDING_TRANSFER':
        return Icons.swap_horiz;
      case 'PENDING':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }
}
