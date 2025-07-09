import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/cash/widget_transaction_item.dart';
import '../approvals/handover_approval_screen.dart';

class AllTransactionsTab extends StatelessWidget {
  String ? userName ;
    AllTransactionsTab({
     Key? key,
     this.userName
   }) : super(key: key);

  // In AllTransactionsTab and other tabs
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      builder: (context, state) {
        if (state is CashManagementLoaded) {
          final transactions = state.filteredTransactions;

          // Group transactions by date
          final groupedTransactions = _groupTransactionsByDate(transactions);

          return RefreshIndicator(
              onRefresh: () async {
                context.read<CashManagementBloc>().add(RefreshCashData());
                return Future.delayed(const Duration(milliseconds: 800));
              },
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16.h, bottom: 80.h),
                itemCount: groupedTransactions.length,
                itemBuilder: (context, index) {
                  final date = groupedTransactions.keys.elementAt(index);
                  final dateTransactions = groupedTransactions[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        child: Text(
                          _formatDateHeader(date),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      ...dateTransactions
                        .where((transaction) => transaction.createdBy == userName) // Filter transactions
                          .map((transaction) => TransactionItem(
                            transaction: transaction,
                            onTap: () => _showTransactionDetails(context, transaction),
                          ))
                        .toList(),
                    ],
                  );
                },
              ));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Map<DateTime, List<CashTransaction>> _groupTransactionsByDate(List<CashTransaction> transactions) {
    final groupedTransactions = <DateTime, List<CashTransaction>>{};

    for (final transaction in transactions) {
      final date = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );

      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }

      groupedTransactions[date]!.add(transaction);
    }

    // Sort dates in descending order (newest first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return {
      for (var date in sortedDates)
        date: groupedTransactions[date]!..sort((a, b) => b.createdAt.compareTo(a.createdAt))
    };
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, y').format(date);
    }
  }

  void _showTransactionDetails(BuildContext context, CashTransaction transaction) {
    // For pending transactions, navigate to appropriate approval screen
    if (transaction.status == TransactionStatus.pending) {
      switch (transaction.type) {
        case TransactionType.handover:
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HandoverApprovalScreen(transaction: transaction),
            ),
          );
          return;
        // case TransactionType.bank:
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => BankDepositApprovalScreen(transaction: transaction),
        //     ),
        //   );
          return;
        default:
          break;
      }
    }

    // For non-pending or deposit transactions, show details in modal
    final statusColor = transaction.status == TransactionStatus.approved
        ? const Color(0xFF4CAF50)
        : transaction.status == TransactionStatus.rejected
        ? const Color(0xFFF44336)
        : const Color(0xFFFFC107);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24.w),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getTransactionTypeName(transaction.type)} Details',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      transaction.statusText,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              _buildDetailRow('ID', transaction.id),
              _buildDetailRow('Amount',
                  NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
                      .format(transaction.amount)),
              _buildDetailRow('Date & Time',
                  DateFormat('MMM d, y – h:mm a').format(transaction.createdAt)),
              _buildDetailRow('Account Type', transaction.accountTypeText),

              if (transaction.selectedAccount != null)
                _buildDetailRow('Paid To', transaction.selectedAccount!),

              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('Remarks', transaction.notes!),

              if(transaction.modeOfPayment != null)
                _buildDetailRow('Mode of Payment  ', transaction.modeOfPayment!),

              if(transaction.approved == true)
                _buildDetailRow('Approved By', transaction.approvedBy!),

              if(transaction.rejected ==true )
                _buildDetailRow('Rejected By', transaction.rejectedBy!),

              if (transaction.status == TransactionStatus.rejected &&
                  transaction.rejectionReason != null)
                _buildDetailRow('Rejection Reason', transaction.rejectionReason!,
                    textColor: Colors.red),

              SizedBox(height: 24.h),

              // Show receipt if available
              if (transaction.receiptImagePath != null) ...[
                Text(
                  'Receipt',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: InkWell(
                    onTap: () => _viewFullImage(context, transaction),
                    child: Container(
                      width: 200.w,
                      height: 120.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.r),
                        image: DecorationImage(
                          image: FileImage(File(transaction.receiptImagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 32.h),

              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: Size(200.w, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      )),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.handover:
        return 'Handover';
      case TransactionType.bank:
        return 'Bank Deposit';
      default:
        return 'Transaction';
    }
  }

  void _viewFullImage(BuildContext context, CashTransaction transaction) {
    if (transaction.receiptImagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E5CA8),
            title: Text('Receipt Image'),
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: FileImage(File(transaction.receiptImagePath!)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}