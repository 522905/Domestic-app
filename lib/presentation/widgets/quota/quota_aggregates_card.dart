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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (aggregates.overallPostingRatio != null)
                  _buildPostingRatioBadge(),
              ],
            ),
            SizedBox(height: 5.h),

            // Inventory Movement Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric(
                  label: 'Pickup',
                  value: aggregates.totalPickups,
                  icon: Icons.add_circle_outline,
                  isPositive: true,
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'Return',
                  value: aggregates.totalReturns,
                  icon: Icons.remove_circle_outline,
                  isPositive: false,
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'Total Pickup',
                  value: aggregates.totalNetPickups,
                  icon: Icons.inventory_2_outlined,
                  isPositive: aggregates.totalNetPickups >= 0,
                ),
              ],
            ),

            SizedBox(height: 8.h),
            Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.25),
              margin: EdgeInsets.symmetric(horizontal: 12.w),
            ),
            SizedBox(height: 8.h),

            // Performance Metrics Row
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
                  height: 32.h,
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
                  height: 32.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'Tkn Ded',
                  value: aggregates.totalTokenDeductions,
                  icon: Icons.remove_circle_outline,
                  isPositive: false,
                ),
                Container(
                  width: 1,
                  height: 32.h,
                  color: Colors.white.withOpacity(0.3),
                ),
                _buildMetric(
                  label: 'Tkn Cr',
                  value: aggregates.totalTokenCredits,
                  icon: Icons.add_circle_outline,
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
        Icon(icon, size: 12.sp, color: Colors.white),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 15.sp,
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

  /// Builds posting ratio badge with color based on percentage
  Widget _buildPostingRatioBadge() {
    final ratio = aggregates.overallPostingRatio!;
    // Green if >= 90%, Red if < 90%
    final backgroundColor = ratio >= 90.0
        ? AppColors.successGreen.withOpacity(0.9)
        : AppColors.errorRed.withOpacity(0.9);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPostingRatioIcon(ratio),
            size: 14.sp,
            color: Colors.white,
          ),
          SizedBox(width: 4.w),
          Text(
            '${ratio.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns appropriate icon based on posting ratio
  IconData _getPostingRatioIcon(double ratio) {
    if (ratio >= 90.0) return Icons.check_circle;
    if (ratio >= 80.0) return Icons.warning_amber_rounded;
    return Icons.error;
  }

  Color _getRatioColor(double ratio) {
    if (ratio >= 90.0) return AppColors.successGreen;
    if (ratio >= 80.0) return AppColors.warningYellow;
    return AppColors.errorRed;
  }
}
