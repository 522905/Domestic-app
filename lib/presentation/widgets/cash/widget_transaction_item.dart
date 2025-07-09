import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/cash/cash_transaction.dart';

class TransactionItem extends StatelessWidget {
  final CashTransaction transaction;
  final VoidCallback onTap;
  final bool isFromDepositsTab;

  const TransactionItem({
    Key? key,
    required this.transaction,
    required this.onTap,
    this.isFromDepositsTab = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildInitiatorCircle(),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          NumberFormat.currency(
                            symbol: '₹',
                            decimalDigits: 0,
                            locale: 'en_IN',
                          ).format(transaction.amount),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          transaction.accountTypeText, // Use the accountTypeText getter!
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isFromDepositsTab ? '  From:  ' : '  To:  ',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        isFromDepositsTab? transaction.createdBy! : transaction.paidTo!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatTime(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Divider(
                height: 16.h,
                thickness: 1,
                color: Colors.grey[300],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitiatorCircle() {
    Color backgroundColor;
    Color textColor;

    switch (transaction.type) {
      case TransactionType.deposit:
        backgroundColor = const Color(0xFFE8F5E9); // Light green
        textColor = const Color(0xFF4CAF50); // Green
        break;
      case TransactionType.handover:
        backgroundColor = const Color(0xFFE3F2FD); // Light blue
        textColor = const Color(0xFF2196F3); // Blue
        break;
      case TransactionType.bank:
        backgroundColor = const Color(0xFFFFF3E0); // Light orange
        textColor = const Color(0xFFF7941D); // Brand Orange
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return CircleAvatar(
      radius: 25.r,
      backgroundColor: backgroundColor,
      child: Text(
        transaction.id,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (transaction.status) {
      case TransactionStatus.pending:
        backgroundColor = const Color(0xFFFFF8E1); // Light yellow
        textColor = const Color(0xFFFFC107); // Warning Yellow
        break;
      case TransactionStatus.approved:
        backgroundColor = const Color(0xFFE8F5E9); // Light green
        textColor = const Color(0xFF4CAF50); // Success Green
        break;
      case TransactionStatus.rejected:
        backgroundColor = const Color(0xFFFFEBEE); // Light red
        textColor = const Color(0xFFF44336); // Error Red
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[700]!;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        transaction.statusText,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();

    // If the transaction was today
    if (time.day == now.day && time.month == now.month && time.year == now.year) {
      return '${DateFormat('h:mm a').format(time)}';
    }

    // If the transaction was yesterday
    if (time.day == now.day - 1 && time.month == now.month && time.year == now.year) {
      return '${DateFormat('h:mm a').format(time)}';
    }

    // For older transactions
    return '${DateFormat('MMM d, h:mm a').format(time)}';
  }
}