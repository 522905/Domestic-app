import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/cash/widget_transaction_item.dart';
import '../cash_transaction_detail_screen.dart';

class PendingTab extends StatelessWidget {
  PendingTab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<CashManagementBloc, CashManagementState>(
      listener: (context, state) {
        // Listen for transaction updates and automatically refresh
        if (state is TransactionActionSuccess) {
          // Transaction was approved/rejected, data will be refreshed automatically
          // No need to do anything here, just let the UI rebuild
        }
      },
      child: BlocBuilder<CashManagementBloc, CashManagementState>(
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
                    'Error loading pending data',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                  SizedBox(height: 8.h),
                  ElevatedButton(
                    onPressed: () => context.read<CashManagementBloc>().add(RefreshCashData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CashManagementLoaded) {
            // Filter only pending transactions
            final pendingTransactions = state.filteredTransactions
                .where((tx) => tx.status == TransactionStatus.pending)
                .toList();

            if (pendingTransactions.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending_actions_outlined,
                      size: 64.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No pending transactions',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            // Group transactions by date
            final groupedPending = _groupTransactionsByDate(pendingTransactions);

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CashManagementBloc>().add(RefreshCashData());
                return await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16.h, bottom: 80.h),
                itemCount: groupedPending.length,
                itemBuilder: (context, index) {
                  final date = groupedPending.keys.elementAt(index);
                  final datePending = groupedPending[date]!;

                  if (datePending.isEmpty) {
                    return const SizedBox.shrink();
                  }

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
                      ...datePending
                          .map((transaction) => TransactionItem(
                        transaction: transaction,
                        onTap: () => _navigateToTransactionDetail(context, transaction),
                        isFromTab: true,
                      ))
                          .toList(),
                    ],
                  );
                },
              ),
            );
          }
          return const Center(child: Text('No data available'));
        },
      ),
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

  void _navigateToTransactionDetail(BuildContext context, CashTransaction transaction) async {
    // Determine if current user can approve this transaction
    // This logic should be based on user role and transaction type
    bool canApprove = _canUserApproveTransaction(context, transaction);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: context.read<CashManagementBloc>(),
          child: TransactionDetailScreen(
            transactionId: transaction.id,
            canApprove: canApprove,
          ),
        ),
      ),
    );

    // If any action was taken (approve/reject), refresh the data
    if (result == true && context.mounted) {
      context.read<CashManagementBloc>().add(RefreshCashData());
    }
  }

  bool _canUserApproveTransaction(BuildContext context, CashTransaction transaction) {
    return transaction.status == TransactionStatus.pending;
  }
}
