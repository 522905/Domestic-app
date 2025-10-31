// lib/presentation/widgets/sdms/transaction_list_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sdms/sdms_transaction.dart';

class TransactionListItem extends StatelessWidget {
  final SDMSTransaction transaction;
  final VoidCallback onTap;

  const TransactionListItem({
    Key? key,
    required this.transaction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID: ${transaction.orderId}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          _formatDate(transaction.orderDate),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    _getActionTypeIcon(),
                    size: 16.sp,
                    color: const Color(0xFF0E5CA8),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      transaction.actionTypeDisplay,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF0E5CA8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Initiated by ${transaction.initiatedByName}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              if (transaction.retryCount > 0) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 16.sp,
                      color: Colors.orange[600],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Retry Count: ${transaction.retryCount}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              if (transaction.resultMessage.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: _getMessageBackgroundColor(),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    transaction.resultMessage,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _getMessageTextColor(),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor(),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        transaction.processStatusDisplay,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (transaction.processStatus.toUpperCase()) {
      case 'QUEUED':
        return const Color(0xFFFFC107); // Warning Yellow
      case 'COMPLETED':
        return const Color(0xFF4CAF50); // Success Green
      case 'FAILED':
        return const Color(0xFFF44336); // Error Red
      case 'INCIDENT':
        return const Color(0xFFFF5722); // Deep Orange
      default:
        return const Color(0xFF2196F3); // Info Blue
    }
  }

  IconData _getActionTypeIcon() {
    switch (transaction.actionType.toUpperCase()) {
      case 'INVOICE_ASSIGN':
        return Icons.receipt_long;
      case 'CREDIT_PAYMENT':
        return Icons.payment;
      default:
        return Icons.assignment;
    }
  }

  Color _getMessageBackgroundColor() {
    if (transaction.processStatus.toUpperCase() == 'FAILED' ||
        transaction.processStatus.toUpperCase() == 'INCIDENT') {
      return Colors.red[50]!;
    } else if (transaction.processStatus.toUpperCase() == 'COMPLETED') {
      return Colors.green[50]!;
    }
    return Colors.blue[50]!;
  }

  Color _getMessageTextColor() {
    if (transaction.processStatus.toUpperCase() == 'FAILED' ||
        transaction.processStatus.toUpperCase() == 'INCIDENT') {
      return Colors.red[700]!;
    } else if (transaction.processStatus.toUpperCase() == 'COMPLETED') {
      return Colors.green[700]!;
    }
    return Colors.blue[700]!;
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

}