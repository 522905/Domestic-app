import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';
import 'package:lpg_distribution_app/core/services/service_provider.dart';
import 'package:lpg_distribution_app/domain/entities/quota/quota_item.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota_history/quota_history_bloc.dart';
import 'package:lpg_distribution_app/presentation/pages/quota/quota_history_page.dart';
import 'quota_flow_timeline.dart';
import 'quota_change_breakdown.dart';

class SimplifiedQuotaItemCard extends StatefulWidget {
  final QuotaItem item;

  const SimplifiedQuotaItemCard({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<SimplifiedQuotaItemCard> createState() => _SimplifiedQuotaItemCardState();
}

class _SimplifiedQuotaItemCardState extends State<SimplifiedQuotaItemCard> {
  bool _isExpanded = false;

  Color _getBorderColor() {
    if (widget.item.isBlocked) {
      return AppColors.errorRed;
    }
    if (widget.item.availableBalance == 0) {
      return Colors.grey.shade400;
    }
    if (widget.item.isLowBalance) {
      return Colors.orange.shade600;
    }
    return AppColors.brandBlue;
  }

  void _navigateToHistory(BuildContext context) {
    final apiService = context.read<ServiceProvider>().apiService;

    // Get available items for filtering (just this item and others if available)
    final Map<String, String> availableItems = {
      widget.item.itemCode: widget.item.itemName,
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => QuotaHistoryBloc(
            apiService: apiService,
            initialItemCode: widget.item.itemCode, // Pre-filter by this item
          ),
          child: QuotaHistoryPage(
            pageTitle: '${widget.item.itemName} - Stock History',
            initialAvailableItems: availableItems,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getBorderColor().withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getBorderColor().withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Item name + badges
                _buildHeader(),

                SizedBox(height: 16.h),

                // Timeline flow
                QuotaFlowTimeline(
                  opening: widget.item.opening,
                  totalAdjustment: widget.item.totalAdjustment,
                  closing: widget.item.closing,
                ),

                SizedBox(height: 12.h),

                // Expand/Collapse indicator
                _buildExpandIndicator(),

                // Breakdown (expandable)
                QuotaChangeBreakdown(
                  item: widget.item,
                  isExpanded: _isExpanded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Item icon
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: _getBorderColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            Icons.inventory_2,
            color: _getBorderColor(),
            size: 24.sp,
          ),
        ),

        SizedBox(width: 12.w),

        // Item name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item.itemName,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: widget.item.isBlocked
                      ? AppColors.errorRed
                      : AppColors.primaryText,
                ),
              ),
              SizedBox(height: 4.h),
              GestureDetector(
                onTap: () => _navigateToHistory(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 14.sp,
                      color: AppColors.brandBlue,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'View History',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.brandBlue,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Status badges
        if (widget.item.isBlocked)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.errorRed,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 14.sp, color: Colors.white),
                SizedBox(width: 4.w),
                Text(
                  'BLOCKED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        else if (widget.item.availableBalance == 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'NO STOCK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildExpandIndicator() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: AppColors.brandBlue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isExpanded ? 'Hide Details' : 'Show Details',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              size: 18.sp,
              color: AppColors.brandBlue,
            ),
          ],
        ),
      ),
    );
  }
}
