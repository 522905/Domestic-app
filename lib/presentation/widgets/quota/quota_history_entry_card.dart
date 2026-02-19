import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quota/quota_history_entry.dart';

/// Timeline entry card for a single day's quota history
class QuotaHistoryEntryCard extends StatefulWidget {
  final QuotaHistoryEntry entry;
  final VoidCallback? onTap;
  final bool isFirstItem;
  final bool isLastItem;

  const QuotaHistoryEntryCard({
    Key? key,
    required this.entry,
    this.onTap,
    this.isFirstItem = false,
    this.isLastItem = false,
  }) : super(key: key);

  @override
  State<QuotaHistoryEntryCard> createState() => _QuotaHistoryEntryCardState();
}

class _QuotaHistoryEntryCardState extends State<QuotaHistoryEntryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Debug: Log what we're displaying for Jan 17
    if (widget.entry.entryDate.toString().contains('2026-01-17')) {
      print('QuotaHistoryEntryCard - Displaying Jan 17:');
      print('  Opening: ${widget.entry.openingBalance}');
      print('  Closing: ${widget.entry.closingBalance}');
      print('  Adjustment: ${widget.entry.adjustment}');
      print('  Net Change: ${widget.entry.netChange}');
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator (colored dot + vertical line)
          Expanded(
            flex: 0,
            child: _buildTimelineIndicator(),
          ),
          SizedBox(width: 12.w),

          // Content card
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: _getRatioColor().withOpacity(0.3),
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getRatioColor().withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Colored header
                  _buildHeader(),
                  // Metrics Grid
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
                    child: _buildKeyMetrics(),
                  ),
                  // Expand/Collapse
                  if (_hasExpandableContent())
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                        // Don't call widget.onTap to avoid clearing filters
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 6.h),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isExpanded ? 'Less Details' : 'More Details',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              size: 18.sp,
                              color: AppColors.brandBlue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Expanded Details
                  if (_isExpanded) ...[
                    Padding(
                      padding: EdgeInsets.fromLTRB(8.w, 0, 8.w, 8.w),
                      child: _buildExpandedDetails(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
        ],
      ),
    );
  }

  Widget _buildTimelineIndicator() {
    // Minimum height to cover most cards
    final minHeight = 250.h;

    return SizedBox(
      width: 14.w,
      height: minHeight,
      child: Stack(
        children: [
          // Continuous vertical line through center
          Positioned(
            top: widget.isFirstItem ? 0.h : 0,
            bottom: widget.isLastItem ? 75.h : 0,
            left: (14.w - 2.5) / 2, // Center the line
            child: Container(
              width: 2.5,
              color: AppColors.lightGray,
            ),
          ),
          // Colored circle centered vertically
          Positioned(
            top: (minHeight - 14.w) / 2, // Center the circle
            left: 0,
            child: Container(
              width: 14.w,
              height: 14.w,
              decoration: BoxDecoration(
                color: _getRatioColor(),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.0),
                boxShadow: [
                  BoxShadow(
                    color: _getRatioColor().withOpacity(0.4),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: _getRatioColor().withOpacity(0.05),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12.r),
          topRight: Radius.circular(12.r),
        ),
      ),
      child: Row(
        children: [
          // Date & Item
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.entry.shortDate,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryText,
                  ),
                ),
                Text(
                  widget.entry.itemName,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          // Posting ratio badge - always show
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _getRatioColor().withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '${widget.entry.calculatedPostingRatio?.toStringAsFixed(0) ?? '0'}%',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: _getRatioColor(),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          // Closing balance
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     Text(
          //       'Close',
          //       style: TextStyle(
          //         fontSize: 9.sp,
          //         color: AppColors.secondaryText,
          //       ),
          //     ),
          //     Text(
          //       widget.entry.closingBalance.toString(),
          //       style: TextStyle(
          //         fontSize: 14.sp,
          //         fontWeight: FontWeight.bold,
          //         color: AppColors.primaryText,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      crossAxisSpacing: 6.w,
      mainAxisSpacing: 6.h,
      children: [
        _buildMetricBox(
          icon: Icons.wallet,
          label: 'Open',
          value: widget.entry.openingBalance,
          color: AppColors.brandBlue,
        ),
        _buildMetricBox(
          icon: Icons.local_shipping,
          label: 'Pickups',
          value: widget.entry.pickups,
          color: AppColors.errorRed,
        ),
        _buildMetricBox(
          icon: Icons.keyboard_return,
          label: 'Returns',
          value: widget.entry.returns,
          color: AppColors.successGreen,
        ),
        _buildMetricBox(
          icon: Icons.verified,
          label: 'OTP',
          value: widget.entry.otpSales,
          color: AppColors.successGreen,
        ),
        _buildMetricBox(
          icon: Icons.card_giftcard,
          label: 'Bonus',
          value: widget.entry.bonusConsumed,
          color: AppColors.warningYellow,
        ),
        _buildMetricBox(
          icon: Icons.inventory,
          label: 'Close',
          value: widget.entry.closingBalance,
          color: AppColors.primaryText,
        ),
      ],
    );
  }

  Widget _buildMetricBox({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13.sp, color: color),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetails() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.lightGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Override', widget.entry.overrideSales),
              _buildDetailItem('Blank', widget.entry.blankSales),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('SDMS Sales', widget.entry.sdmsSales),
              _buildDetailItem('Net Change', widget.entry.netChange),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('Net Pickup', widget.entry.netPickups),
              _buildDetailItem('Adjustment', widget.entry.adjustment),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, int value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.secondaryText,
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  bool _hasExpandableContent() {
    // Only show expand button if there's meaningful data to show
    return widget.entry.overrideSales > 0 ||
        widget.entry.blankSales > 0 ||
        widget.entry.sdmsSales > 0 ||
        widget.entry.netChange != 0 ||
        widget.entry.adjustment != 0;
  }

  Color _getRatioColor() {
    switch (widget.entry.ratioColor) {
      case PostingRatioColor.good:
        return AppColors.successGreen;
      case PostingRatioColor.moderate:
        return AppColors.warningYellow;
      case PostingRatioColor.poor:
        return AppColors.errorRed;
      case PostingRatioColor.neutral:
        return AppColors.secondaryText;
    }
  }
}
