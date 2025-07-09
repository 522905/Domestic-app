// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
//
// import '../../../domain/entities/cash/cash_transaction.dart';
// import '../../blocs/cash/cash_bloc.dart';
//
// class BankDepositApprovalScreen extends StatefulWidget {
//   final CashTransaction transaction;
//
//   const BankDepositApprovalScreen({
//     Key? key,
//     required this.transaction,
//   }) : super(key: key);
//
//   @override
//   State<BankDepositApprovalScreen> createState() => _BankDepositApprovalScreenState();
// }
//
// class _BankDepositApprovalScreenState extends State<BankDepositApprovalScreen> {
//   bool _isStatementVerified = false;
//   String? _selectedRejectionReason;
//   final TextEditingController _rejectionCommentController = TextEditingController();
//
//   final List<String> _rejectionReasons = [
//     'Statement Mismatch',
//     'Incorrect Bank Details',
//     'Missing Bank Receipt',
//     'Other'
//   ];
//
//   @override
//   void dispose() {
//     _rejectionCommentController.dispose();
//     super.dispose();
//   }
//
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(24.w),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircleAvatar(
//                 radius: 32.r,
//                 backgroundColor: Colors.green.shade100,
//                 child: Icon(
//                   Icons.check,
//                   color: Colors.green,
//                   size: 32.sp,
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               Text(
//                 'Bank Deposit Approved',
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 'Cash deposit successfully approved.\nAccount balances updated.',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               SizedBox(height: 24.h),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close dialog
//                   Navigator.of(context).pop(); // Return to previous screen
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF4CAF50),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(24.r),
//                   ),
//                   minimumSize: Size(120.w, 44.h),
//                 ),
//                 child: const Text('DONE'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showRejectionDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16.r),
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(24.w),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CircleAvatar(
//                 radius: 32.r,
//                 backgroundColor: Colors.red.shade100,
//                 child: Icon(
//                   Icons.close,
//                   color: Colors.red,
//                   size: 32.sp,
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               Text(
//                 'Bank Deposit Rejected',
//                 style: TextStyle(
//                   fontSize: 18.sp,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 8.h),
//               Text(
//                 'Reason: ${_selectedRejectionReason}\nInitiator has been notified',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: Colors.grey[700],
//                 ),
//               ),
//               SizedBox(height: 24.h),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.of(context).pop(); // Close dialog
//                   Navigator.of(context).pop(); // Return to previous screen
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF44336),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(24.r),
//                   ),
//                   minimumSize: Size(120.w, 44.h),
//                 ),
//                 child: const Text('DONE'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   void _showRejectionReasonSheet() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
//       ),
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             return Padding(
//               padding: EdgeInsets.all(24.w).copyWith(
//                 bottom: MediaQuery.of(context).viewInsets.bottom + 24.w,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Rejection Reason',
//                     style: TextStyle(
//                       fontSize: 18.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8.h),
//                   Text(
//                     'Specify reason for rejecting bank deposit #${widget.transaction.id}',
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       color: Colors.grey[700],
//                     ),
//                   ),
//                   SizedBox(height: 16.h),
//
//                   // Reason options
//                   ...List.generate(_rejectionReasons.length, (index) {
//                     final reason = _rejectionReasons[index];
//                     return RadioListTile<String>(
//                       title: Text(reason),
//                       value: reason,
//                       groupValue: _selectedRejectionReason,
//                       onChanged: (value) {
//                         setState(() {
//                           _selectedRejectionReason = value;
//                         });
//                       },
//                       activeColor: Theme.of(context).primaryColor,
//                       contentPadding: EdgeInsets.zero,
//                     );
//                   }),
//
//                   SizedBox(height: 16.h),
//                   TextField(
//                     controller: _rejectionCommentController,
//                     maxLines: 2,
//                     decoration: InputDecoration(
//                       hintText: 'Additional Comments (Optional)',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.r),
//                       ),
//                       contentPadding: EdgeInsets.all(12.w),
//                     ),
//                   ),
//                   SizedBox(height: 24.h),
//
//                   // Action buttons
//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () {
//                             Navigator.pop(context);
//                           },
//                           style: OutlinedButton.styleFrom(
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8.r),
//                             ),
//                             side: BorderSide(color: Colors.grey[300]!),
//                             minimumSize: Size(0, 48.h),
//                           ),
//                           child: Text(
//                             'Cancel',
//                             style: TextStyle(
//                               color: Colors.grey[700],
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 16.w),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: _selectedRejectionReason == null
//                               ? null
//                               : () {
//                             Navigator.pop(context);
//
//                             // Update transaction status
//                             final updatedTransaction = CashTransaction(
//                               id: widget.transaction.id,
//                               type: widget.transaction.type,
//                               status: TransactionStatus.rejected,
//                               amount: widget.transaction.amount,
//                               timestamp: widget.transaction.timestamp,
//                               initiator: widget.transaction.initiator,
//                               accountType: widget.transaction.accountType,
//                               selectedAccount: widget.transaction.selectedAccount,
//                               bankDetails: widget.transaction.bankDetails,
//                               notes: widget.transaction.notes,
//                               rejectionReason: _selectedRejectionReason,
//                             );
//
//                             // Update transaction in bloc
//                             context.read<CashManagementBloc>().add(
//                               UpdateTransaction(updatedTransaction),
//                             );
//
//                             // Show rejection confirmation
//                             _showRejectionDialog();
//                           },
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.red,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8.r),
//                             ),
//                             minimumSize: Size(0, 48.h),
//                           ),
//                           child: const Text('Reject'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   void _approveBankDeposit() {
//     if (!_isStatementVerified) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please verify bank statement before approving'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }
//
//     // Update transaction status
//     final updatedTransaction = CashTransaction(
//       id: widget.transaction.id,
//       type: widget.transaction.type,
//       status: TransactionStatus.approved,
//       amount: widget.transaction.amount,
//       timestamp: widget.transaction.timestamp,
//       initiator: widget.transaction.initiator,
//       accountType: widget.transaction.accountType,
//       selectedAccount: widget.transaction.selectedAccount,
//       bankDetails: widget.transaction.bankDetails,
//       notes: widget.transaction.notes,
//     );
//
//     // Update transaction in bloc
//     context.read<CashManagementBloc>().add(
//       UpdateTransaction(updatedTransaction),
//     );
//
//     // Show success dialog
//     _showSuccessDialog();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF0E5CA8),
//         title: const Text('Bank Deposit Approval'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(16.w),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Header with ID and status
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Bank Deposit #${widget.transaction.id}',
//                     style: TextStyle(
//                       fontSize: 16.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFFFF8E1),
//                       borderRadius: BorderRadius.circular(16.r),
//                     ),
//                     child: Text(
//                       'PENDING',
//                       style: TextStyle(
//                         fontSize: 12.sp,
//                         fontWeight: FontWeight.bold,
//                         color: const Color(0xFFFFC107),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               Text(
//                 DateFormat('MMMM d, yyyy • h:mm a').format(widget.transaction.timestamp),
//                 style: TextStyle(
//                   fontSize: 13.sp,
//                   color: Colors.grey[600],
//                 ),
//               ),
//               SizedBox(height: 24.h),
//
//               // Deposit Details Card
//               Card(
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.r),
//                   side: BorderSide(color: Colors.grey.shade200),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(16.w),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Deposit Details',
//                         style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       SizedBox(height: 16.h),
//
//                       _buildDetailRow('Bank:', widget.transaction.bankDetails ?? 'N/A'),
//                       _buildDetailRow('Amount:',
//                           NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
//                               .format(widget.transaction.amount)),
//                       _buildDetailRow('Deposit Date:',
//                           DateFormat('MMMM d, yyyy').format(widget.transaction.timestamp)),
//                       _buildDetailRow('Account Type:', widget.transaction.accountType as String),
//                       _buildDetailRow('Reference No.:', 'HDFC982321'),
//                       _buildDetailRow('Initiator:', 'John Doe (Cashier)'),
//
//                       if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
//                         _buildDetailRow('Remarks:', widget.transaction.notes!),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16.h),
//
//               // Receipt Preview
//               Card(
//                 elevation: 0,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.r),
//                   side: BorderSide(color: Colors.grey.shade200),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(16.w),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             'Bank Receipt',
//                             style: TextStyle(
//                               fontSize: 16.sp,
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           TextButton.icon(
//                             onPressed: () {
//                               // View full receipt
//                             },
//                             icon: Icon(
//                               Icons.fullscreen,
//                               size: 18.sp,
//                               color: Theme.of(context).primaryColor,
//                             ),
//                             label: Text(
//                               'VIEW',
//                               style: TextStyle(
//                                 fontSize: 12.sp,
//                                 color: Theme.of(context).primaryColor,
//                               ),
//                             ),
//                             style: TextButton.styleFrom(
//                               tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                               padding: EdgeInsets.symmetric(horizontal: 8.w),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 8.h),
//                       Center(
//                         child: Container(
//                           width: 200.w,
//                           height: 120.h,
//                           decoration: BoxDecoration(
//                             color: Colors.grey[200],
//                             borderRadius: BorderRadius.circular(8.r),
//                           ),
//                           child: Icon(
//                             Icons.receipt_long,
//                             size: 48.sp,
//                             color: Colors.grey[400],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16.h),
//
//               // Action Required Card
//               Card(
//                 elevation: 0,
//                 color: const Color(0xFFF5F5F5),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.r),
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(16.w),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Action Required',
//                         style: TextStyle(
//                           fontSize: 16.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       SizedBox(height: 16.h),
//
//                       // Action buttons
//                       Row(
//                         children: [
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: () => _showRejectionReasonSheet(),
//                               icon: const Icon(Icons.close, color: Colors.white),
//                               label: const Text('REJECT'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.red,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8.r),
//                                 ),
//                                 padding: EdgeInsets.symmetric(vertical: 12.h),
//                               ),
//                             ),
//                           ),
//                           SizedBox(width: 8.w),
//                           Text(
//                             'SWIPE',
//                             style: TextStyle(
//                               fontSize: 12.sp,
//                               color: Colors.grey[600],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                           SizedBox(width: 8.w),
//                           Expanded(
//                             child: ElevatedButton.icon(
//                               onPressed: _approveBankDeposit,
//                               icon: const Icon(Icons.check, color: Colors.white),
//                               label: const Text('APPROVE'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.green,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(8.r),
//                                 ),
//                                 padding: EdgeInsets.symmetric(vertical: 12.h),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 24.h),
//
//               // Verify Bank Statement Button
//               ElevatedButton(
//                 onPressed: () {
//                   setState(() {
//                     _isStatementVerified = !_isStatementVerified;
//                   });
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _isStatementVerified
//                       ? Colors.green.withOpacity(0.1)
//                       : Colors.grey[200],
//                   foregroundColor: _isStatementVerified
//                       ? Colors.green
//                       : Colors.grey[700],
//                   elevation: 0,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8.r),
//                     side: BorderSide(
//                       color: _isStatementVerified
//                           ? Colors.green
//                           : Colors.grey.shade300,
//                     ),
//                   ),
//                   minimumSize: Size(double.infinity, 48.h),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(
//                       _isStatementVerified ? Icons.check_circle : Icons.check_circle_outline,
//                       size: 20.sp,
//                     ),
//                     SizedBox(width: 8.w),
//                     const Text('VERIFY BANK STATEMENT'),
//                   ],
//                 ),
//               ),
//               SizedBox(height: 32.h),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 12.h),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100.w,
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
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }