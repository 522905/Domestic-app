import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';

class CreditExtensionCard extends StatelessWidget {
  final CreditExtension extension;
  final VoidCallback? onTap;

  const CreditExtensionCard({
    Key? key,
    required this.extension,
    this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (extension.status) {
      case CreditExtensionStatus.pending:
        return Colors.orange;
      case CreditExtensionStatus.approved:
        return Colors.green;
      case CreditExtensionStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (extension.status) {
      case CreditExtensionStatus.pending:
        return 'Awaiting Approval';
      case CreditExtensionStatus.approved:
        return 'Approved';
      case CreditExtensionStatus.rejected:
        return 'Rejected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: _getStatusColor().withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          extension.itemName,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          extension.itemCode,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _getStatusColor(),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),

              // Quantity information
              Row(
                children: [
                  Icon(Icons.numbers, size: 16.sp, color: Colors.grey.shade600),
                  SizedBox(width: 8.w),
                  Text(
                    'Requested: ${extension.requestedQuantity}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (extension.isApproved && extension.approvedQuantity != null) ...[
                    SizedBox(width: 16.w),
                    Icon(Icons.check_circle, size: 16.sp, color: Colors.green.shade600),
                    SizedBox(width: 8.w),
                    Text(
                      'Approved: ${extension.approvedQuantity}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),

              if (extension.isApproved && extension.quantityRemaining != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.inventory_2, size: 16.sp, color: Colors.blue.shade600),
                    SizedBox(width: 8.w),
                    Text(
                      'Remaining: ${extension.quantityRemaining}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (extension.isExpiringSoon) ...[
                      SizedBox(width: 8.w),
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 16.sp,
                        color: Colors.orange.shade700,
                      ),
                      Text(
                        'Expiring Soon',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // Valid until for approved extensions
              if (extension.isApproved && extension.validUntil != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16.sp, color: Colors.grey.shade600),
                    SizedBox(width: 8.w),
                    Text(
                      'Valid until: ${DateFormat('MMM dd, yyyy').format(extension.validUntil!)}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '(${extension.daysUntilExpiry} days left)',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: extension.isExpiringSoon
                            ? Colors.orange.shade700
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],

              // Justification preview (only show if available)
              if (extension.justification.isNotEmpty) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.message,
                            size: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'Justification',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (extension.hasAudio) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade50,
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(color: Colors.purple.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.mic,
                                    size: 10.sp,
                                    color: Colors.purple.shade700,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Audio',
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        extension.justification,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Show audio indicator even if no justification text
              if (extension.justification.isEmpty && extension.hasAudio) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.mic,
                        size: 16.sp,
                        color: Colors.purple.shade700,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Voice justification available',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Rejection reason
              if (extension.isRejected && extension.rejectionReason != null) ...[
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.cancel, size: 16.sp, color: Colors.red.shade700),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rejection Reason:',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              extension.rejectionReason!,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Created at timestamp
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${dateFormat.format(extension.createdAt)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24.sp,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
