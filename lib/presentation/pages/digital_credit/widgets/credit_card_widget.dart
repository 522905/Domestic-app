import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/digital_credit/digital_credit.dart';
import 'status_badge_widget.dart';

class CreditCardWidget extends StatelessWidget {
  final DigitalCredit credit;
  final VoidCallback onTap;

  const CreditCardWidget({
    Key? key,
    required this.credit,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with order ID and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order: ${credit.orderId}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          DateFormat('dd MMM yyyy').format(credit.orderDate),
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (credit.amount != null)
                    Text(
                      '₹${credit.amount!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              // Consumer name if available
              if (credit.consumerName != null) ...[
                Row(
                  children: [
                    Icon(Icons.person_outline, size: 16.sp, color: Colors.grey.shade600),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        credit.consumerName!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              // Delivery boy info
              if (credit.originalDeliveryBoyName != null) ...[
                Row(
                  children: [
                    Icon(
                      credit.isMine ? Icons.check_circle : Icons.info_outline,
                      size: 16.sp,
                      color: credit.isMine ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                    SizedBox(width: 6.w),
                    Expanded(
                      child: Text(
                        credit.isMine
                            ? 'You are the delivery boy'
                            : 'Delivery by: ${credit.originalDeliveryBoyName}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: credit.isMine ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
              ],
              // Status badges
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  StatusBadgeWidget(
                    status: credit.dataStatus,
                    statusDisplay: credit.dataStatusDisplay,
                    type: 'data',
                  ),
                  StatusBadgeWidget(
                    status: credit.claimStatus,
                    statusDisplay: credit.claimStatusDisplay,
                    type: 'claim',
                  ),
                  if (credit.isSettled)
                    StatusBadgeWidget(
                      status: credit.dprStatus,
                      statusDisplay: 'Settled',
                      type: 'dpr',
                    ),
                ],
              ),
              // Processing indicator
              if (credit.isProcessing) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Processing will complete in 1-5 minutes',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
