import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/cash/widget_transaction_item.dart';
import '../cash_transaction_detail_screen.dart';

class AllTransactionsTab extends StatelessWidget {
  AllTransactionsTab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      builder: (context, state) {
        if (state is CashManagementLoaded) {
          final transactions = state.filteredTransactions;

          if (transactions.isEmpty) {
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
                    'No transactions found',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final groupedTransactions = _groupTransactionsByDate(transactions);

          return RefreshIndicator(
              onRefresh: () async {
                context.read<CashManagementBloc>().add(RefreshCashData());
                return Future.delayed(const Duration(milliseconds: 500));
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
                          .map((transaction) => TransactionItem(
                        transaction: transaction,
                        onTap: () => _navigateToTransactionDetail(context, transaction),
                      ))
                          .toList(),
                    ],
                  );
                },
              )
          );
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

  void _navigateToTransactionDetail(BuildContext context, CashTransaction transaction) async {
    // For delivery boys viewing all transactions, they typically can't approve
    // Only view details
    bool canApprove = false; // Delivery boys can't approve transactions

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

    // If any action was taken, refresh the data
    if (result == true && context.mounted) {
      context.read<CashManagementBloc>().add(RefreshCashData());
    }
  }
}