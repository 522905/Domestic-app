import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../cash_transaction_detail_screen.dart';

class BankTab extends StatelessWidget {

  const BankTab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      builder: (context, state) {
        if (state is CashManagementLoaded) {
          // Filter transactions to show only bank deposits
          final bankTransactions = state.filteredTransactions
              .where((transaction) => transaction.type == TransactionType.bank)
              .toList();

          if (bankTransactions.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CashManagementBloc>().add(RefreshCashData());
            },
            child: ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: bankTransactions.length,
              itemBuilder: (context, index) {
                final transaction = bankTransactions[index];
                return _buildBankTransactionCard(context, transaction);
              },
            ),
          );
        }

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
                Text('Error: ${state.message}'),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () => context.read<CashManagementBloc>().add(RefreshCashData()),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return _buildEmptyState();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No Bank Deposits',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your bank deposit transactions will appear here',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBankTransactionCard(BuildContext context, CashTransaction transaction) {
    final currencyFormat = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () => _navigateToTransactionDetail(context, transaction),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      transaction.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(transaction.status),
                      ),
                    ),
                  ),
                  Text(
                    currencyFormat.format(transaction.amount),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),
              // Bank and Reference info
              if (transaction.selectedAccount != null) ...[
                Row(
                  children: [
                    Icon(Icons.account_balance, size: 16.sp, color: Colors.grey[600]),
                    SizedBox(width: 8.w),
                    Text(
                      'Bank: ${transaction.selectedAccount}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],

              if (transaction.bankReferenceNo != null && transaction.bankReferenceNo!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.receipt_long, size: 16.sp, color: Colors.grey[600]),
                    SizedBox(width: 8.w),
                    Text(
                      'Receipt: ${transaction.bankReferenceNo}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
              ],
              // Initiator and date
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16.sp, color: Colors.grey[600]),
                  SizedBox(width: 8.w),
                  Text(
                    'By: ${transaction.initiator}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              // Notes if available
              if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    transaction.notes!,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],

              // Approval/Rejection info
              if (transaction.status == TransactionStatus.approved && transaction.approvedBy != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 16.sp, color: Colors.green),
                    SizedBox(width: 8.w),
                    Text(
                      'Approved by: ${transaction.approvedBy}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ],

              if (transaction.status == TransactionStatus.rejected && transaction.rejectedBy != null) ...[
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.cancel, size: 16.sp, color: Colors.red),
                    SizedBox(width: 8.w),
                    Text(
                      'Rejected by: ${transaction.rejectedBy}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                if (transaction.rejectionReason != null && transaction.rejectionReason!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Reason: ${transaction.rejectionReason}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.red[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTransactionDetail(BuildContext context, CashTransaction transaction) async {
    // Determine if current user can approve this transaction
    bool canApprove = transaction.status == TransactionStatus.pending;

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

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.pending:
        return const Color(0xFFF7941D); // Orange
      case TransactionStatus.approved:
        return const Color(0xFF4CAF50); // Green
      case TransactionStatus.rejected:
        return const Color(0xFFF44336); // Red
    }
  }
}