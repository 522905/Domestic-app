import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum ApprovalType { collect, deposit, refill, cashDeposit, transfer }

class ApprovalCard extends StatelessWidget {
  final ApprovalType type;
  final String id;
  final String details;
  final String time;
  final String status;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool nfr;

  const ApprovalCard({
    Key? key,
    required this.type,
    required this.id,
    required this.details,
    required this.time,
    required this.status,
    required this.onApprove,
    required this.onReject,
    this.nfr = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(12.sp),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTitle(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    final backgroundColor = _getIconBackgroundColor();
    final iconData = _getIconData();
    final String letter = _getIconLetter();

    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (type) {
      case ApprovalType.collect:
        return 'Collect Request #$id';
      case ApprovalType.deposit:
        return 'Deposit Request #$id';
      case ApprovalType.refill:
        return 'Refill Order #$id';
      case ApprovalType.cashDeposit:
        return 'Cash Deposit #$id';
      case ApprovalType.transfer:
        return 'Transfer #$id';
    }
  }

  String _getIconLetter() {
    switch (type) {
      case ApprovalType.collect:
        return 'C';
      case ApprovalType.deposit:
        return 'D';
      case ApprovalType.refill:
        return '!';
      case ApprovalType.cashDeposit:
        return '\$';
      case ApprovalType.transfer:
        return 'T';
    }
  }

  IconData _getIconData() {
    switch (type) {
      case ApprovalType.collect:
        return Icons.add_circle_outline;
      case ApprovalType.deposit:
        return Icons.arrow_downward;
      case ApprovalType.refill:
        return Icons.local_fire_department;
      case ApprovalType.cashDeposit:
        return Icons.account_balance_wallet;
      case ApprovalType.transfer:
        return Icons.transfer_within_a_station;
    }
  }

  Color _getIconBackgroundColor() {
    switch (type) {
      case ApprovalType.collect:
        return Colors.green;
      case ApprovalType.deposit:
        return Colors.blue;
      case ApprovalType.refill:
        return Colors.amber;
      case ApprovalType.cashDeposit:
        return Colors.purple;
      case ApprovalType.transfer:
        return Colors.orange;
    }
  }

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'review':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class StatusSummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final int? trend;
  final bool? trendUp;
  final bool? critical;

  const StatusSummaryCard({
    Key? key,
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.trend,
    this.trendUp,
    this.critical = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            if (trend != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: (trendUp ?? true) ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      (trendUp ?? true) ? Icons.arrow_upward : Icons.arrow_downward,
                      color: (trendUp ?? true) ? Colors.green : Colors.red,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      trend.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: (trendUp ?? true) ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            if (critical == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Critical',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}