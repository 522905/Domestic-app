import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quota/quota_history_aggregates.dart';

/// Summary card showing aggregated totals for filtered quota history
class QuotaAggregatesCard extends StatelessWidget {
  final QuotaHistoryAggregates aggregates;

  const QuotaAggregatesCard({
    Key? key,
    required this.aggregates,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.brandBlue,
            AppColors.brandBlue.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range header
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 16.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 6.w),
                Text(
                  _formatDateRange(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Key metrics in a row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'Net',
                  value: aggregates.totalNetChange,
                  icon: Icons.swap_vert,
                  isPositive: aggregates.totalNetChange >= 0,
                ),
                Container(
                  width: 1,
                  height: 35.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'OTP',
                  value: aggregates.totalOtpSales,
                  icon: Icons.verified,
                  isPositive: true,
                ),
                Container(
                  width: 1,
                  height: 35.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'Bonus',
                  value: aggregates.totalBonusConsumed,
                  icon: Icons.card_giftcard,
                  isPositive: true,
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildMetric({
    required String label,
    required int value,
    required IconData icon,
    required bool isPositive,
  }) {
    return Column(
      children: [
        Icon(icon, size: 18.sp, color: Colors.white),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  String _formatDateRange() {
    final dateFormat = DateFormat('d MMM');
    return '${dateFormat.format(aggregates.dateFrom)} - ${dateFormat.format(aggregates.dateTo)}';
  }

  Color _getRatioColor(double ratio) {
    if (ratio >= 90.0) return AppColors.successGreen;
    if (ratio >= 80.0) return AppColors.warningYellow;
    return AppColors.errorRed;
  }
}
