import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';
import 'package:lpg_distribution_app/domain/entities/quota/quota_item.dart';
import 'transaction_row.dart';

class QuotaChangeBreakdown extends StatelessWidget {
  final QuotaItem item;
  final bool isExpanded;

  const QuotaChangeBreakdown({
    Key? key,
    required this.item,
    required this.isExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18.sp,
                color: AppColors.brandBlue,
              ),
              SizedBox(width: 8.w),
              Text(
                'What Changed',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          // Transaction rows in specific order
          TransactionRow(
            icon: Icons.shopping_cart,
            label: 'Bookings',
            value: item.orders,
            isAddition: false,
          ),

          TransactionRow(
            icon: Icons.local_shipping,
            label: 'Pickups',
            value: item.pickups,
            isAddition: false,
          ),

          TransactionRow(
            icon: Icons.keyboard_return,
            label: 'Returns',
            value: item.returns,
            isAddition: true,
          ),

          TransactionRow(
            icon: Icons.point_of_sale,
            label: 'Direct Sales',
            value: item.sdmsSales,
            isAddition: true,
          ),

          TransactionRow(
            icon: Icons.card_giftcard,
            label: 'Bonus',
            value: item.bonus,
            isAddition: true,
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(
              color: Colors.grey.shade400,
              thickness: 2,
            ),
          ),

          // Total adjustment
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: item.totalAdjustment >= 0
                  ? AppColors.successGreen.withOpacity(0.1)
                  : AppColors.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: item.totalAdjustment >= 0
                    ? AppColors.successGreen
                    : AppColors.errorRed,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calculate,
                      size: 20.sp,
                      color: item.totalAdjustment >= 0
                          ? AppColors.successGreen
                          : AppColors.errorRed,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Net Change',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
                Text(
                  item.formattedAdjustment,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: item.totalAdjustment >= 0
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
