import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quota/quota_snapshot.dart';
import '../../../domain/entities/quota/active_bonus.dart';

/// Bonus summary card widget showing bonus status and posting ratio
class BonusSummaryCard extends StatefulWidget {
  final QuotaSnapshot snapshot;

  const BonusSummaryCard({
    Key? key,
    required this.snapshot,
  }) : super(key: key);

  @override
  State<BonusSummaryCard> createState() => _BonusSummaryCardState();
}

class _BonusSummaryCardState extends State<BonusSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final totalBonus = _calculateTotalBonus();
    final postingRatio = _calculatePostingRatio();
    final activeBonusesCount = _getActiveBonusesCount();
    final earliestExpiring = _getEarliestExpiringBonus();
    final isQualified = postingRatio != null && postingRatio >= 90.0;

    return Container(
      margin: EdgeInsets.only(bottom: 5.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.amber.shade200.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.card_giftcard,
                    size: 20.sp,
                    color: Colors.amber.shade700,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bonus Summary',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                const Spacer(),
                // Qualification badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isQualified
                        ? AppColors.successGreen.withOpacity(0.1)
                        : AppColors.errorRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: isQualified
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isQualified ? 'Qualified' : 'Not Qualified',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isQualified
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Main content - Total bonus and posting ratio
            Row(
              children: [
                // Total bonus
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Bonus',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Text(
                            totalBonus.toString(),
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Qty',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: AppColors.secondaryText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '$activeBonusesCount active bonuses',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

                // Posting ratio gauge
                if (postingRatio != null)
                  SizedBox(
                    width: 100.w,
                    height: 100.w,
                    child: CustomPaint(
                      painter: _CircularProgressPainter(
                        progress: (postingRatio / 100).clamp(0.0, 1.0),
                        progressColor: _getPostingColor(postingRatio),
                        backgroundColor: AppColors.lightGray,
                        strokeWidth: 8.w,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${postingRatio.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: _getPostingColor(postingRatio),
                              ),
                            ),
                            Text(
                              'Posting',
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Expiry warning
            if (earliestExpiring != null &&
                earliestExpiring.isExpiringSoon) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.errorRed.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 18.sp,
                      color: AppColors.errorRed,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Bonus expiring in ${earliestExpiring.daysUntilExpiry} days',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Target info
            SizedBox(height: 12.h),
            Divider(color: AppColors.lightGray, height: 1),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14.sp,
                  color: AppColors.secondaryText,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Maintain 90% posting ratio to qualify for bonus',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),

            // Expandable section
            if (activeBonusesCount > 0) ...[
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isExpanded ? 'Hide Details' : 'View Active Bonuses',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _isExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18.sp,
                        color: AppColors.brandBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Active bonuses list
            if (_isExpanded) ...[
              SizedBox(height: 8.h),
              ..._buildActiveBonusesList(),
            ],

            // Navigation buttons
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/bonus-schemes');
                      },
                      icon: Icon(Icons.school_outlined, size: 18.sp),
                      label: Text(
                        'Learn More',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30.h,
                    color: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/bonus-list',
                        );
                      },
                      icon: Icon(Icons.visibility_outlined, size: 18.sp),
                      label: Text(
                        'View All',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.brandBlue,
                        padding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveBonusesList() {
    final allBonuses = widget.snapshot.items
        .expand((item) => item.activeBonuses.map((bonus) => {
              'item': item.itemName,
              'bonus': bonus,
            }))
        .toList();

    // Sort by expiry date
    allBonuses.sort((a, b) => (a['bonus'] as ActiveBonus)
        .expiryDate
        .compareTo((b['bonus'] as ActiveBonus).expiryDate));

    return allBonuses.map((data) {
      final itemName = data['item'] as String;
      final bonus = data['bonus'] as ActiveBonus;
      final daysLeft = bonus.daysUntilExpiry;

      return Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: AppColors.lightGray.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    bonus.strategyName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${bonus.quantityRemaining} Qty',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.warningYellow,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: daysLeft <= 2
                        ? AppColors.errorRed
                        : AppColors.secondaryText,
                    fontWeight: daysLeft <= 2 ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  int _calculateTotalBonus() {
    return widget.snapshot.items.fold(0, (sum, item) => sum + item.bonus);
  }

  int _getActiveBonusesCount() {
    return widget.snapshot.items
        .expand((item) => item.activeBonuses)
        .length;
  }

  ActiveBonus? _getEarliestExpiringBonus() {
    final allBonuses = widget.snapshot.items
        .expand((item) => item.activeBonuses)
        .toList();

    if (allBonuses.isEmpty) return null;

    return allBonuses.reduce(
      (a, b) => a.expiryDate.isBefore(b.expiryDate) ? a : b,
    );
  }

  double? _calculatePostingRatio() {
    // Calculate overall posting ratio: (total SDMS sales) / (total pickups - total returns) * 100
    final totalPickups = widget.snapshot.items
        .fold<int>(0, (sum, item) => sum + item.pickups.abs());
    final totalReturns = widget.snapshot.items
        .fold<int>(0, (sum, item) => sum + item.returns);
    final totalSdms = widget.snapshot.items
        .fold<int>(0, (sum, item) => sum + item.sdmsSales);

    final netPickups = totalPickups - totalReturns;
    if (netPickups <= 0) return null;

    return (totalSdms / netPickups) * 100;
  }

  Color _getPostingColor(double ratio) {
    if (ratio >= 90.0) return AppColors.successGreen;
    if (ratio >= 80.0) return AppColors.warningYellow;
    return AppColors.errorRed;
  }
}

/// Custom painter for circular progress indicator
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
