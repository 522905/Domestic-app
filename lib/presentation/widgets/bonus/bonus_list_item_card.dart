import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/bonus/bonus.dart';
import 'bonus_urgency_badge.dart';
import 'bonus_progress_bar.dart';

/// Card widget for displaying a bonus item in a list
class BonusListItemCard extends StatelessWidget {
  final Bonus bonus;
  final VoidCallback onTap;

  const BonusListItemCard({
    Key? key,
    required this.bonus,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline indicator
                  Column(
                    children: [
                      Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor(),
                        ),
                      ),
                      if (bonus.isActive || bonus.isExpiringSoon)
                        Container(
                          width: 2.w,
                          height: 30.h,
                          color: _getStatusColor().withOpacity(0.3),
                        ),
                    ],
                  ),
                  SizedBox(width: 12.w),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bonus.itemName,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (bonus.expiryUrgency != null)
                              BonusUrgencyBadge(urgency: bonus.expiryUrgency!),
                          ],
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          bonus.itemCode,
                          style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                        ),
                        SizedBox(height: 8.h),

                        // Quantity Info
                        Row(
                          children: [
                            _buildQuantityInfo(
                              'Remaining',
                              bonus.quantityRemaining,
                              Colors.blue,
                            ),
                            SizedBox(width: 12.w),
                            _buildQuantityInfo(
                              'Earned',
                              bonus.quantityEarned,
                              Colors.green,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),

                        // Progress Bar
                        BonusProgressBar(
                          consumptionPercentage: bonus.consumptionPercentage,
                          isExpiringSoon: bonus.isExpiringSoon,
                        ),
                        SizedBox(height: 8.h),

                        // Dates
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Earned: ${DateFormat('dd MMM yyyy').format(bonus.earnedDate)}',
                              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                            ),
                            Text(
                              'Expires: ${DateFormat('dd MMM yyyy').format(bonus.expiryDate)}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: bonus.isExpiringSoon ? Colors.red : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Arrow icon
                  Icon(Icons.chevron_right, size: 20.sp, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityInfo(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        SizedBox(width: 4.w),
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 11.sp),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    if (bonus.isExpired) return Colors.grey;
    if (bonus.isFullyConsumed) return Colors.orange;
    if (bonus.isExpiringSoon) return Colors.red;
    return Colors.green;
  }
}
