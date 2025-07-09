// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:intl/intl.dart';
// import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
//
// class DepositDetailsPage extends StatelessWidget {
//   const DepositDetailsPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // Get the transaction from route arguments
//     final transaction = ModalRoute.of(context)?.settings.arguments as CashTransaction?;
//
//     if (transaction == null) {
//       return Scaffold(
//         appBar: AppBar(
//           title: const Text('Deposit Details'),
//           centerTitle: true,
//         ),
//         body: const Center(
//           child: Text('Transaction details not found'),
//         ),
//       );
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Deposit Details'),
//         centerTitle: true,
//         actions: [
//           if (transaction.status == TransactionStatus.pending)
//             PopupMenuButton<String>(
//               icon: const Icon(Icons.more_vert),
//               onSelected: (value) {
//                 if (value == 'approve') {
//                   _showApprovalDialog(context, transaction);
//                 } else if (value == 'reject') {
//                   _showRejectionDialog(context, transaction);
//                 }
//               },
//               itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
//                 const PopupMenuItem<String>(
//                   value: 'approve',
//                   child: Text('Approve'),
//                 ),
//                 const PopupMenuItem<String>(
//                   value: 'reject',
//                   child: Text('Reject'),
//                 ),
//               ],
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16.w),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Status Card
//             _buildStatusCard(context, transaction),
//             SizedBox(height: 24.h),
//
//             // Transaction details
//             _buildSectionHeader(context, 'Transaction Details'),
//             SizedBox(height: 16.h),
//
//             _buildDetailRow('ID', transaction.id),
//             _buildDetailRow('Type', 'Deposit'),
//             _buildDetailRow('Account', transaction.accountTypeText),
//             _buildDetailRow('Date & Time',
//                 DateFormat('MMM d, y • h:mm a').format(transaction.timestamp)),
//
//             if (transaction.notes != null && transaction.notes!.isNotEmpty)
//               _buildDetailRow('Notes', transaction.notes!),
//
//             SizedBox(height: 24.h),
//
//             // Amount Section
//             _buildSectionHeader(context, 'Amount'),
//             SizedBox(height: 16.h),
//
//             Text(
//               NumberFormat.currency(
//                 symbol: '₹',
//                 decimalDigits: 0,
//                 locale: 'en_IN',
//               ).format(transaction.amount),
//               style: TextStyle(
//                 fontSize: 28.sp,
//                 fontWeight: FontWeight.bold,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//
//             SizedBox(height: 24.h),
//
//             // Approval Section (if applicable)
//             if (transaction.status == TransactionStatus.approved ||
//                 transaction.status == TransactionStatus.rejected)
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildSectionHeader(
//                       context,
//                       transaction.status == TransactionStatus.approved
//                           ? 'Approval Details'
//                           : 'Rejection Details'
//                   ),
//                   SizedBox(height: 16.h),
//
//                   // Show mock approval details
//                   _buildDetailRow(
//                     transaction.status == TransactionStatus.approved
//                         ? 'Approved by'
//                         : 'Rejected by',
//                     'Anand Sharma (GM)',
//                   ),
//                   _buildDetailRow(
//                     transaction.status == TransactionStatus.approved
//                         ? 'Approved on'
//                         : 'Rejected on',
//                     DateFormat('MMM d, y • h:mm a').format(
//                         transaction.timestamp.add(const Duration(minutes: 30))
//                     ),
//                   ),
//                   if (transaction.status == TransactionStatus.rejected &&
//                       transaction.rejectionReason != null)
//                     _buildDetailRow('Reason', transaction.rejectionReason!),
//
//                   SizedBox(height: 24.h),
//                 ],
//               ),
//
//             // Action Buttons (if pending)
//             if (transaction.status == TransactionStatus.pending)
//               Row(
//                 children: [
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.check_circle),
//                       label: Text(
//                         'APPROVE',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFF4CAF50), // Success Green
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 12.h),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8.r),
//                         ),
//                       ),
//                       onPressed: () => _showApprovalDialog(context, transaction),
//                     ),
//                   ),
//                   SizedBox(width: 16.w),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       icon: const Icon(Icons.cancel),
//                       label: Text(
//                         'REJECT',
//                         style: TextStyle(
//                           fontSize: 14.sp,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFF44336), // Error Red
//                         foregroundColor: Colors.white,
//                         padding: EdgeInsets.symmetric(vertical: 12.h),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8.r),
//                         ),
//                       ),
//                       onPressed: () => _showRejectionDialog(context, transaction),
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusCard(BuildContext context, CashTransaction transaction) {
//     Color backgroundColor;
//     Color textColor;
//     String message;
//     IconData icon;
//
//     switch (transaction.status) {
//       case TransactionStatus.pending:
//         backgroundColor = const Color(0xFFFFF8E1); // Light yellow
//         textColor = const Color(0xFFFFC107); // Warning Yellow
//         message = 'This deposit is awaiting approval';
//         icon = Icons.hourglass_top;
//         break;
//       case TransactionStatus.approved:
//         backgroundColor = const Color(0xFFE8F5E9); // Light green
//         textColor = const Color(0xFF4CAF50); // Success Green
//         message = 'This deposit has been approved';
//         icon = Icons.check_circle;
//         break;
//       case TransactionStatus.rejected:
//         backgroundColor = const Color(0xFFFFEBEE); // Light red
//         textColor = const Color(0xFFF44336); // Error Red
//         message = 'This deposit has been rejected';
//         icon = Icons.cancel;
//         break;
//       default:
//         backgroundColor = const Color(0xFFEEEEEE);
//         textColor = const Color(0xFF757575);
//         message = 'Unknown status';
//         icon = Icons.help_outline;
//     }
//
//     return Container(
//       width: double.infinity,
//       padding: EdgeInsets.all(16.w),
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(12.r),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             icon,
//             color: textColor,
//             size: 24.sp,
//           ),
//           SizedBox(width: 12.w),
//           Expanded(
//             child: Text(
//               message,
//               style: TextStyle(
//                 fontSize: 16.sp,
//                 fontWeight: FontWeight.w500,
//                 color: textColor,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(BuildContext context, String title) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 18.sp,
//             fontWeight: FontWeight.bold,
//             color: Theme.of(context).primaryColor,
//           ),
//         ),
//         SizedBox(height: 4.h),
//         Container(
//           width: 40.w,
//           height: 3.h,
//           decoration: BoxDecoration(
//             color: Theme.of(context).colorScheme.secondary, // Brand Orange
//             borderRadius: BorderRadius.circular(1.5.r),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
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
//                 fontWeight: FontWeight.w500,
//                 color: Colors.grey[700],
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: TextStyle(
//                 fontSize: 14.sp,
//                 fontWeight: FontWeight.w400,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showApprovalDialog(BuildContext context, CashTransaction transaction) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Confirm Approval'),
//         content: const Text('Are you sure you want to approve this deposit?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CANCEL'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50), // Success Green
//             ),
//             onPressed: () {
//               // In a real app, dispatch an approval event to the BLoC
//               Navigator.pop(context); // Close dialog
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Deposit approved successfully'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//
//               Navigator.pop(context); // Go back to previous screen
//             },
//             child: const Text('APPROVE'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showRejectionDialog(BuildContext context, CashTransaction transaction) {
//     final TextEditingController reasonController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Rejection Reason'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text('Please provide a reason for rejecting this deposit:'),
//             SizedBox(height: 16.h),
//             TextField(
//               controller: reasonController,
//               maxLines: 3,
//               decoration: InputDecoration(
//                 hintText: 'Enter rejection reason',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8.r),
//                 ),
//                 contentPadding: EdgeInsets.all(12.w),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('CANCEL'),
//           ),
//           ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFFF44336), // Error Red
//             ),
//             onPressed: () {
//               if (reasonController.text.isEmpty) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Please provide a rejection reason'),
//                     backgroundColor: Colors.orange,
//                   ),
//                 );
//                 return;
//               }
//
//               // In a real app, dispatch a rejection event to the BLoC
//               Navigator.pop(context); // Close dialog
//
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('Deposit rejected'),
//                   backgroundColor: Colors.red,
//                 ),
//               );
//
//               Navigator.pop(context); // Go back to previous screen
//             },
//             child: const Text('REJECT'),
//           ),
//         ],
//       ),
//     );
//   }
// }