// // bank_tab.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
//
// import '../../../../domain/entities/cash/cash_transaction.dart';
// import '../../../blocs/cash/cash_bloc.dart';
// import '../../../widgets/cash/widget_transaction_item.dart';
// import '../bank_deposit_approval_screen.dart';
//
// class BankTab extends StatelessWidget {
//   const BankTab({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<CashManagementBloc, CashManagementState>(
//       builder: (context, state) {
//         if (state is CashManagementLoading) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         if (state is CashManagementError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
//                 SizedBox(height: 16.h),
//                 Text(
//                   'Error loading bank transaction data',
//                   style: TextStyle(fontSize: 16.sp),
//                 ),
//                 SizedBox(height: 8.h),
//                 ElevatedButton(
//                   onPressed: () => context.read<CashManagementBloc>().add(LoadCashData()),
//                   child: const Text('Retry'),
//                 ),
//               ],
//             ),
//           );
//         }
//
//         if (state is CashManagementLoaded) {
//           // Filter only bank transactions
//           final bankTransactions = state.filteredTransactions
//               .where((tx) => tx.type == TransactionType.bank)
//               .toList();
//
//           if (bankTransactions.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.account_balance,
//                     size: 64.sp,
//                     color: Colors.grey[400],
//                   ),
//                   SizedBox(height: 16.h),
//                   Text(
//                     'No bank transactions found',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                   SizedBox(height: 8.h),
//                   Text(
//                     'Use the + button to create a new bank deposit',
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       color: Colors.grey[500],
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           // Group transactions by date
//           final groupedTransactions = _groupTransactionsByDate(bankTransactions);
//
//           return ListView.builder(
//             padding: EdgeInsets.only(top: 16.h, bottom: 80.h),
//             itemCount: groupedTransactions.length,
//             itemBuilder: (context, index) {
//               final date = groupedTransactions.keys.elementAt(index);
//               final dateTransactions = groupedTransactions[date]!;
//
//               return Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
//                     child: Text(
//                       _formatDateHeader(date),
//                       style: TextStyle(
//                         fontSize: 14.sp,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.grey[700],
//                       ),
//                     ),
//                   ),
//                   ...dateTransactions.map((tx) => TransactionItem(
//                     transaction: tx,
//                     onTap: () => _showBankTransactionDetails(context, tx),
//                   )).toList(),
//                 ],
//               );
//             },
//           );
//         }
//
//         return const Center(child: Text('No data available'));
//       },
//     );
//   }
//
//   Map<DateTime, List<CashTransaction>> _groupTransactionsByDate(List<CashTransaction> transactions) {
//     final groupedTransactions = <DateTime, List<CashTransaction>>{};
//
//     for (final transaction in transactions) {
//       final date = DateTime(
//         transaction.timestamp.year,
//         transaction.timestamp.month,
//         transaction.timestamp.day,
//       );
//
//       if (!groupedTransactions.containsKey(date)) {
//         groupedTransactions[date] = [];
//       }
//
//       groupedTransactions[date]!.add(transaction);
//     }
//
//     // Sort dates in descending order (newest first)
//     final sortedDates = groupedTransactions.keys.toList()
//       ..sort((a, b) => b.compareTo(a));
//
//     return {
//       for (var date in sortedDates)
//         date: groupedTransactions[date]!..sort((a, b) => b.timestamp.compareTo(a.timestamp))
//     };
//   }
//
//   String _formatDateHeader(DateTime date) {
//     final now = DateTime.now();
//     final yesterday = DateTime(now.year, now.month, now.day - 1);
//
//     if (date.year == now.year && date.month == now.month && date.day == now.day) {
//       return 'Today';
//     } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
//       return 'Yesterday';
//     } else {
//       return DateFormat('MMMM d, y').format(date);
//     }
//   }
//
//   void _showBankTransactionDetails(BuildContext context, CashTransaction transaction) {
//     if (transaction.status == TransactionStatus.pending) {
//       // Navigate directly to approval screen for pending transactions
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => BankDepositApprovalScreen(transaction: transaction),
//         ),
//       );
//       return;
//     }
//
//     // Show details for already processed transactions
//     final statusColor = transaction.status == TransactionStatus.approved
//         ? const Color(0xFF4CAF50)
//         : transaction.status == TransactionStatus.rejected
//         ? const Color(0xFFF44336)
//         : const Color(0xFFFFC107);
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
//       ),
//       builder: (context) {
//         return Container(
//           padding: EdgeInsets.all(24.w),
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.75,
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Bank Deposit Details',
//                     style: TextStyle(
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
//                     decoration: BoxDecoration(
//                       color: statusColor.withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(12.r),
//                     ),
//                     child: Text(
//                       transaction.statusText,
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.bold,
//                         color: statusColor,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 24.h),
//
//               _buildDetailRow('Deposit ID', transaction.id),
//               _buildDetailRow('Amount',
//                   NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
//                       .format(transaction.amount)),
//               _buildDetailRow('Date & Time',
//                   DateFormat('MMM d, y – h:mm a').format(transaction.timestamp)),
//               _buildDetailRow('Account Type', transaction.accountTypeText),
//
//               if (transaction.bankDetails != null)
//                 _buildDetailRow('Bank', transaction.bankDetails!),
//
//               if (transaction.notes != null && transaction.notes!.isNotEmpty)
//                 _buildDetailRow('Remarks', transaction.notes!),
//
//               if (transaction.status == TransactionStatus.rejected &&
//                   transaction.rejectionReason != null)
//                 _buildDetailRow('Rejection Reason', transaction.rejectionReason!,
//                     textColor: Colors.red),
//
//               SizedBox(height: 24.h),
//
//               // Show bank receipt if available (mock for now)
//               if (transaction.status != TransactionStatus.pending) ...[
//                 Text(
//                   'Bank Receipt',
//                   style: TextStyle(
//                     fontSize: 16.sp,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 SizedBox(height: 8.h),
//                 Center(
//                   child: Container(
//                     width: 200.w,
//                     height: 120.h,
//                     decoration: BoxDecoration(
//                       color: Colors.grey[200],
//                       borderRadius: BorderRadius.circular(8.r),
//                     ),
//                     child: Icon(
//                       Icons.receipt_long,
//                       size: 48.sp,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//               ],
//
//               SizedBox(height: 32.h),
//
//               Center(
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Theme.of(context).primaryColor,
//                     minimumSize: Size(200.w, 48.h),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8.r),
//                     ),
//                   ),
//                   child: const Text('Close'),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value, {Color? textColor}) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 16.h),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120.w,
//             child: Text(
//               label,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w500,
//                 color: textColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }