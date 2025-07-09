import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/cash/widget_transaction_item.dart';
import '../../../../utils/swipeButton.dart';

class DepositsTab extends StatelessWidget {
  String? userName;
    DepositsTab({
      Key? key,
      this.userName,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      builder: (context, state) {
        if (state is CashManagementLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CashManagementError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  'Error loading deposit data',
                  style: TextStyle(fontSize: 16.sp),
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: () => context.read<CashManagementBloc>().add(LoadCashData()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is CashManagementLoaded) {
          // Filter only deposit transactions
          final deposits = state.filteredTransactions
              .where((tx) => tx.type == TransactionType.deposit)
              .toList();

          if (deposits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No deposits found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/cash/deposit');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Deposit'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Group transactions by date
          final groupedDeposits = _groupTransactionsByDate(deposits);

          return ListView.builder(
            padding: EdgeInsets.only(top: 16.h, bottom: 80.h),
            itemCount: groupedDeposits.length,
            itemBuilder: (context, index) {
              final date = groupedDeposits.keys.elementAt(index);
              final dateDeposits = groupedDeposits[date]!;

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
                  ...dateDeposits
                    .where((deposit) => deposit.paidTo == userName)
                    .map((deposit) => TransactionItem(
                      transaction: deposit,
                      onTap: () => _showDepositDetails(context, deposit),
                      isFromDepositsTab: true,
                    ))
                    .toList(),
                ],
              );
            },
          );
        }

        return const Center(child: Text('No data available'));
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

  void _showDepositDetails(BuildContext context, CashTransaction transaction) {
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
                    'Deposit Details',
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

              _buildDetailRow('Deposit ID', transaction.id),
              _buildDetailRow('Amount',
                  NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
                      .format(transaction.amount)),
              _buildDetailRow('Date & Time',
                  DateFormat('MMM d, y – h:mm a').format(transaction.createdAt)),
              _buildDetailRow('Account Type', transaction.accountTypeText),

              if (transaction.notes != null && transaction.notes!.isNotEmpty)
                _buildDetailRow('Remarks', transaction.notes!),

              if (transaction.status == TransactionStatus.rejected &&
                  transaction.rejectionReason != null)

              _buildDetailRow('createdBy', transaction.createdBy!),

              if (transaction.status == TransactionStatus.rejected &&
                  transaction.rejectionReason != null)
                _buildDetailRow('Rejection Reason', transaction.rejectionReason!),

              SizedBox(height: 32.h),
              // Action buttons (approve/reject for pending, close for others)
              if (transaction.status == TransactionStatus.pending) ...[
                Container(
                  height: 60.h,
                  margin: EdgeInsets.symmetric(vertical: 8.h),
                  child: SwipeActionButton(
                    onReject: () {
                      Navigator.pop(context);
                      _showRejectDialog(context, transaction);
                    },
                    onApprove: () {
                      Navigator.pop(context);
                      _approveDeposit(context, transaction);
                    },
                  ),
                )
              ] else
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
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showRejectDialog(BuildContext context, CashTransaction transaction) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Deposit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            SizedBox(height: 16.h),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a rejection reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              else{
                Navigator.pop(context);
                _rejectDeposit(context, transaction, reasonController);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

    void _approveDeposit(BuildContext context, CashTransaction transaction) async {
      try {
        final bloc = context.read<CashManagementBloc>();
        final apiService = bloc.apiService;

        final result = await apiService.approveTransaction(transaction.id);

        if (result != null && result['success'] == true) {
          // Dispatch RefreshCashData to update the list
          bloc.add(RefreshCashData());

          // Show success SnackBar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Deposit approved successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // Handle failure case
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result?['message'] ?? 'Failed to approve deposit'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Handle exception
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Approval failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    void _rejectDeposit(BuildContext context, CashTransaction transaction, TextEditingController rejectionReasonController) async {
      try {
        final bloc = context.read<CashManagementBloc>();
        final apiService = bloc.apiService;

        // Ensure rejection reason is not empty
        final rejectionReason = rejectionReasonController.text.trim();
        if (rejectionReason.isEmpty) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rejection reason cannot be empty'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Call the API to reject the transaction
        final result = await apiService.rejectTransaction(transaction.id, {'reason': rejectionReason});

        if (result != null && result['success'] == true) {
          // Dispatch RefreshCashData to update the list
          bloc.add(RefreshCashData());

          // Show success SnackBar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Deposit rejected successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
          Navigator.pop(context);
        } else {
          // Handle failure case
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result?['message'] ?? 'Failed to reject deposit'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Handle exception
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rejection failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        Navigator.pop(context);
      }
    }

  Widget _buildDetailRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
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