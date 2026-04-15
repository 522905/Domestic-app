import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/quota/quota_history_entry.dart';
import '../../../domain/entities/quota/quota_ledger_detail_entry.dart';
import '../../blocs/quota_history/quota_history_bloc.dart';
import '../../blocs/quota_history/quota_history_event.dart';
import '../../blocs/quota_history/quota_history_state.dart';

/// Expandable timeline entry card for a single day's quota history
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
  List<QuotaLedgerDetailEntry>? _detailEntries;
  bool _isLoadingDetail = false;

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    if (_isExpanded && _detailEntries == null && !_isLoadingDetail) {
      _loadDetail();
    }
  }

  void _loadDetail() {
    setState(() => _isLoadingDetail = true);
    context.read<QuotaHistoryBloc>().add(LoadHistoryDetail(
      entryDate: widget.entry.entryDate,
      itemCode: widget.entry.itemCode,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<QuotaHistoryBloc, QuotaHistoryState>(
      listener: (context, state) {
        if (state is QuotaHistoryDetailLoaded) {
          final dateStr = widget.entry.entryDate.toIso8601String().split('T')[0];
          if (state.entryDate == dateStr && state.itemCode == widget.entry.itemCode) {
            setState(() {
              _detailEntries = state.entries;
              _isLoadingDetail = false;
            });
          }
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot + line
            _buildTimeline(),
            SizedBox(width: 12.w),
            // Content
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return SizedBox(
      width: 16.w,
      child: Column(
        children: [
          if (!widget.isFirstItem)
            Container(width: 2, height: 8.h, color: Colors.grey.shade300),
          Container(
            width: 14.w,
            height: 14.w,
            decoration: BoxDecoration(
              color: _ratioColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: _ratioColor.withOpacity(0.3), blurRadius: 4),
              ],
            ),
          ),
          Container(
            width: 2,
            height: _isExpanded ? null : 8.h,
            constraints: _isExpanded ? null : null,
            color: widget.isLastItem ? Colors.transparent : Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final e = widget.entry;
    return GestureDetector(
      onTap: _toggleExpand,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _ratioColor.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: date + item + posting ratio
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: _ratioColor.withOpacity(0.05),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
              ),
              child: Row(
                children: [
                  Text(
                    e.shortDate,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryText,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    e.itemName,
                    style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _ratioColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '${e.calculatedPostingRatio?.toStringAsFixed(0) ?? '0'}%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: _ratioColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Key numbers row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Column(
                children: [
                  // Row 1: Pickup | SDMS | Net
                  Row(
                    children: [
                      _metric('Pickup', e.pickups, AppColors.errorRed),
                      _divider(),
                      _metric('SDMS', e.sdmsSales, AppColors.brandBlue),
                      _divider(),
                      _metric('Net', e.netChange, e.netChange >= 0 ? AppColors.successGreen : AppColors.errorRed),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Row 2: Token | Return | Adj
                  Row(
                    children: [
                      _metric('Token', e.tokenCredits - e.tokenDeductions,
                          (e.tokenCredits - e.tokenDeductions) >= 0 ? AppColors.successGreen : AppColors.errorRed),
                      _divider(),
                      _metric('Return', e.returns, AppColors.successGreen),
                      _divider(),
                      _metric('Adj', e.adjustment, AppColors.warningYellow),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Opening / Closing row
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Opening', style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText)),
                              SizedBox(height: 2.h),
                              Text(
                                '${e.openingBalance}',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, size: 16.sp, color: AppColors.secondaryText),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Closing', style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText)),
                              SizedBox(height: 2.h),
                              Text(
                                '${e.closingBalance}',
                                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: AppColors.primaryText),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Expand indicator
            InkWell(
              onTap: _toggleExpand,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 18.sp,
                      color: AppColors.brandBlue,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _isExpanded ? 'Hide Details' : 'View Entries',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded drill-down entries
            if (_isExpanded) _buildDetailSection(),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: AppColors.secondaryText),
          ),
          SizedBox(height: 2.h),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: value == 0 ? AppColors.secondaryText : color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 28.h,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildDetailSection() {
    if (_isLoadingDetail) {
      return Padding(
        padding: EdgeInsets.all(16.w),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_detailEntries == null || _detailEntries!.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(12.w),
        child: Text(
          'No detail entries available',
          style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.r)),
      ),
      child: Column(
        children: _detailEntries!.map((entry) => _buildDetailRow(entry)).toList(),
      ),
    );
  }

  Widget _buildDetailRow(QuotaLedgerDetailEntry entry) {
    final isPositive = entry.colorIndicator == EntryTypeColor.positive;
    final isNegative = entry.colorIndicator == EntryTypeColor.negative;
    final color = isPositive
        ? AppColors.successGreen
        : isNegative
            ? AppColors.errorRed
            : AppColors.secondaryText;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Time
              SizedBox(
                width: 44.w,
                child: Text(
                  entry.time.length >= 5 ? entry.time.substring(0, 5) : entry.time,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: AppColors.secondaryText,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              // Type badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  entry.entryTypeDisplay,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              // Quantity
              Text(
                '${entry.quantity > 0 ? '+' : ''}${entry.quantity}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              // Company
              if (entry.company.isNotEmpty) ...[
                SizedBox(width: 8.w),
                SizedBox(
                  width: 24.w,
                  child: Text(
                    _companyShort(entry.company),
                    style: TextStyle(fontSize: 9.sp, color: AppColors.secondaryText),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
          // Order number — tappable
          if (entry.orderNumber != null && entry.orderNumber!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            GestureDetector(
              onTap: () => _showOrderInfoDialog(entry),
              child: Row(
                children: [
                  SizedBox(width: 44.w),
                  Icon(Icons.receipt_long, size: 12.sp, color: AppColors.brandBlue),
                  SizedBox(width: 4.w),
                  Text(
                    entry.orderNumber!,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandBlue,
                      decoration: TextDecoration.underline,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOrderInfoDialog(QuotaLedgerDetailEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: AppColors.brandBlue, size: 22.sp),
            SizedBox(width: 8.w),
            const Text('Order Details'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _orderInfoRow('Order Number', entry.orderNumber ?? ''),
            if (entry.orderDate != null)
              _orderInfoRow('Order Date', entry.orderDate!),
            _orderInfoRow('Type', entry.entryTypeDisplay),
            _orderInfoRow('Quantity', '${entry.quantity > 0 ? '+' : ''}${entry.quantity}'),
            if (entry.company.isNotEmpty)
              _orderInfoRow('Company', entry.company),
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text('Notes', style: TextStyle(fontSize: 11.sp, color: AppColors.secondaryText)),
              SizedBox(height: 2.h),
              Text(
                entry.notes!,
                style: TextStyle(fontSize: 13.sp, color: AppColors.primaryText),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _orderInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(label, style: TextStyle(fontSize: 12.sp, color: AppColors.secondaryText)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: AppColors.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  String _companyShort(String company) {
    if (company.toLowerCase().contains('gas')) return 'AG';
    if (company.toLowerCase().contains('indane')) return 'AI';
    return company.substring(0, 2).toUpperCase();
  }

  Color get _ratioColor {
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
