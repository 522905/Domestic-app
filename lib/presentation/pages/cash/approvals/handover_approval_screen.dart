import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';

import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../../utils/swipeButton.dart';

class HandoverApprovalScreen extends StatefulWidget {
  final CashTransaction transaction;

  const HandoverApprovalScreen({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<HandoverApprovalScreen> createState() => _HandoverApprovalScreenState();
}

class _HandoverApprovalScreenState extends State<HandoverApprovalScreen> {
  bool _isCashReceived = false;
  String? _selectedRejectionReason;
  final TextEditingController _rejectionCommentController = TextEditingController();

  final List<String> _rejectionReasons = [
    'Incorrect Amount',
    'Cash Amount Mismatch',
    'Missing Receipt',
    'Other'
  ];

  @override
  void dispose() {
    _rejectionCommentController.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Handover Approved',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Cash handover successfully approved.\nAccount balances updated.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  minimumSize: Size(120.w, 44.h),
                ),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32.r,
                backgroundColor: Colors.red.shade100,
                child: Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Handover Rejected',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Reason: ${_selectedRejectionReason}\nInitiator has been notified',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to previous screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                  minimumSize: Size(120.w, 44.h),
                ),
                child: const Text('DONE'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRejectionReasonSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.all(24.w).copyWith(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.w,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Reason',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Specify reason for rejecting handover #${widget.transaction.id}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Reason options
                  ...List.generate(_rejectionReasons.length, (index) {
                    final reason = _rejectionReasons[index];
                    return RadioListTile<String>(
                      title: Text(reason),
                      value: reason,
                      groupValue: _selectedRejectionReason,
                      onChanged: (value) {
                        setState(() {
                          _selectedRejectionReason = value;
                        });
                      },
                      activeColor: Theme.of(context).primaryColor,
                      contentPadding: EdgeInsets.zero,
                    );
                  }),

                  // Additional comments
                  if (_selectedRejectionReason == 'Cash Amount Mismatch') ...[
                    Text(
                      'Cash count shows ₹24,500 only',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontStyle: FontStyle.italic,
                        color: Colors.red[700],
                      ),
                    ),
                  ],

                  SizedBox(height: 16.h),
                  TextField(
                    controller: _rejectionCommentController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Additional Comments (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.all(12.w),
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            side: BorderSide(color: Colors.grey[300]!),
                            minimumSize: Size(0, 48.h),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                        ElevatedButton(
                          onPressed: _selectedRejectionReason == null ? null : () async {
                          Navigator.pop(context);

                            try {
                            final bloc = context.read<CashManagementBloc>();
                            final apiService = bloc.apiService;

                            // Call API to reject
                            await apiService.rejectTransaction(widget.transaction.id, {
                              'reason': _selectedRejectionReason,
                              'comment': _rejectionCommentController.text,
                            });

                            // Update local state
                            final updatedTransaction = CashTransaction(
                                id: widget.transaction.id,
                                type: widget.transaction.type,
                                status: TransactionStatus.rejected,
                                amount: widget.transaction.amount,
                                createdAt: widget.transaction.createdAt,
                                initiator: widget.transaction.initiator,
                                accountType: widget.transaction.accountType,
                                selectedAccount: widget.transaction.selectedAccount,
                                selectedBank: widget.transaction.selectedBank,
                                notes: widget.transaction.notes,
                                rejectionReason: _selectedRejectionReason,
                                receiptImagePath: widget.transaction.receiptImagePath,
                            );

                              bloc.add(UpdateTransaction(updatedTransaction));
                              _showRejectionDialog();

                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Rejection failed: $e')),
                                );
                              }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            minimumSize: Size(0, 48.h),
                          ),
                          child: const Text('Reject'),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _approveHandover() async {
    if (!_isCashReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify cash received before approving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final bloc = context.read<CashManagementBloc>();
      final apiService = bloc.apiService;

      final result = await apiService.approveTransaction(widget.transaction.id);

      if (result != null && result['success'] == true) {
        // Dispatch RefreshCashData to update the list
        bloc.add(RefreshCashData());
        // Show success SnackBar
        if (context.mounted) {
          // Close the approval screen
          Navigator.of(context).pop();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approval failed: $e')),
      );
    }
  }

  void _viewFullReceiptImage() {
    if (widget.transaction.receiptImagePath == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E5CA8),
            title: const Text('Receipt Image'),
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: FileImage(File(widget.transaction.receiptImagePath!)),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: const Text('Handover Approval'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with ID and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Handover #${widget.transaction.id}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Text(
                      'PENDING',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFC107),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMMM d, yyyy • h:mm a').format(widget.transaction.createdAt),
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 10.h),
              // Handover Details Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handover Details',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 16.h),

                      _buildDetailRow('Type:', 'Cashier to ${widget.transaction.selectedAccount != null ? 'Manager' : 'Bank'}'),
                      _buildDetailRow('Amount:',
                          NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
                              .format(widget.transaction.amount)),

                      if (widget.transaction.selectedAccount != null)
                        _buildDetailRow('Recipient:', widget.transaction.selectedAccount!),

                      if (widget.transaction.selectedBank != null)
                        _buildDetailRow('Bank:', widget.transaction.selectedBank!),

                      _buildDetailRow('Initiator:', 'John Doe (Cashier)'),

                      if (widget.transaction.notes != null && widget.transaction.notes!.isNotEmpty)
                        _buildDetailRow('Remarks:', widget.transaction.notes!),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Receipt Preview
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Receipt',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.transaction.receiptImagePath != null)
                            TextButton.icon(
                              onPressed: _viewFullReceiptImage,
                              icon: Icon(
                                Icons.fullscreen,
                                size: 18.sp,
                                color: Theme.of(context).primaryColor,
                              ),
                              label: Text(
                                'VIEW',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: EdgeInsets.symmetric(horizontal: 8.w),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      // Center(
                      //   child: widget.transaction.receiptImagePath != null
                      //       ? InkWell(
                      //     onTap: _viewFullReceiptImage,
                      //     child: Container(
                      //       width: 200.w,
                      //       height: 120.h,
                      //       decoration: BoxDecoration(
                      //         color: Colors.grey[200],
                      //         borderRadius: BorderRadius.circular(8.r),
                      //         image: DecorationImage(
                      //           image: FileImage(File(widget.transaction.receiptImagePath!)),
                      //           fit: BoxFit.cover,
                      //         ),
                      //       ),
                      //     ),
                      //   )
                      //       : Container(
                      //     width: 200.w,
                      //     height: 120.h,
                      //     decoration: BoxDecoration(
                      //       color: Colors.grey[200],
                      //       borderRadius: BorderRadius.circular(8.r),
                      //     ),
                      //     child: Icon(
                      //       Icons.receipt_long,
                      //       size: 48.sp,
                      //       color: Colors.grey[400],
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              // Verify Cash Received Button
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isCashReceived = !_isCashReceived;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isCashReceived
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey[200],
                  foregroundColor: _isCashReceived
                      ? Colors.green
                      : Colors.grey[700],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    side: BorderSide(
                      color: _isCashReceived
                          ? Colors.green
                          : Colors.grey.shade300,
                    ),
                  ),
                  minimumSize: Size(double.infinity, 48.h),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isCashReceived ? Icons.check_circle : Icons.check_circle_outline,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    const Text('VERIFY CASH RECEIVED'),
                  ],
                ),
              ),
              SizedBox(height: 10.h),
              // Action Required Card
              Card(
                elevation: 0,
                color: const Color(0xFFF5F5F5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60.h,
                        margin: EdgeInsets.symmetric(vertical: 8.h),
                        child: SwipeActionButton(
                          onReject: () => _showRejectionReasonSheet(),
                          onApprove: () => _approveHandover(),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}