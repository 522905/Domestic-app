import 'dart:ffi';
import 'package:flutter/material.dart' hide Size;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:photo_view/photo_view.dart';
import '../../../core/services/User.dart';
import '../../../domain/entities/cash/cash_transaction.dart';
import '../../blocs/cash/cash_bloc.dart';
import '../../../utils/swipeButton.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionId;
  final bool canApprove; // Whether current user can approve this transaction

  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.canApprove = false,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isCashReceived = false;
  String? _selectedRejectionReason;
  final TextEditingController _rejectionCommentController = TextEditingController();
  CashTransaction? _currentTransaction; // Keep track of current transaction
  String? _userName;
  bool _isTransactionUpdated = false; // Track if transaction was updated
 Int? _userId;

  final List<String> _rejectionReasons = [
    'Incorrect Amount',
    'Cash Amount Mismatch',
    'Missing Receipt',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    // Load transaction details when screen opens
    context.read<CashManagementBloc>().add(
        LoadTransactionDetails(transactionId: widget.transactionId)
    );
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final userName = await User().getUserName();
    final userId = await User().getUserId();
    setState(() {
      _userName = userName;
      _userId = userId as Int?;
    });
  }

  @override
  void dispose() {
    _rejectionCommentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_isTransactionUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF0E5CA8),
          title: const Text('Transaction Details'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // ✅ SIMPLE: Just pop, no refresh
              Navigator.of(context).pop(_isTransactionUpdated);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                // Refresh transaction details
                context.read<CashManagementBloc>().add(
                    LoadTransactionDetails(transactionId: widget.transactionId)
                );
              },
            ),
          ],
        ),
        body: BlocConsumer<CashManagementBloc, CashManagementState>(
          listener: (context, state) {
            if (state is TransactionActionSuccess) {

              // Mark that transaction was updated
              _isTransactionUpdated = true;

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: state.action == 'approve' ? Colors.green : Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );

              // Refresh the transaction details after a short delay
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  context.read<CashManagementBloc>().add(
                      LoadTransactionDetails(transactionId: widget.transactionId)
                  );
                }
              });
            }

            if (state is TransactionDetailsLoaded) {
              // Update current transaction when new details are loaded
              _currentTransaction = state.transaction;
            }
          },
          builder: (context, state) {
            if (state is TransactionDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TransactionActionLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    Text(
                      state.action == 'approve' ? 'Approving transaction...' : 'Rejecting transaction...',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                  ],
                ),
              );
            }

            if (state is TransactionDetailsLoaded) {
              return _buildTransactionDetails(state.transaction);
            }

            // Show current transaction if we have it, even during loading states
            if (_currentTransaction != null) {
              return _buildTransactionDetails(_currentTransaction!);
            }

            if (state is CashManagementError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      'Error loading transaction details',
                      style: TextStyle(fontSize: 16.sp),
                    ),
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Text(
                        state.message,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CashManagementBloc>().add(
                            LoadTransactionDetails(transactionId: widget.transactionId)
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildTransactionDetails(CashTransaction transaction) {
    final statusColor = _getStatusColor(transaction.status);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with ID and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${_getTransactionTypeName(transaction.type)} #${transaction.id}',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    transaction.status.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              formatUpdatedAtAbsoluteDT(transaction.createdAt),
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),

            SizedBox(height: 16.h),

            // Amount Card with words
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
                side: BorderSide(color: const Color(0xFF0E5CA8).withOpacity(0.2)),
              ),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0E5CA8).withOpacity(0.05),
                      Colors.white,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Transaction Amount',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsetsGeometry.fromLTRB(5, 0, 0, 0),
                      child: Text(
                        NumberFormat.currency(
                          symbol: '₹',
                          decimalDigits: 0,
                          locale: 'en_IN',
                        ).format(transaction.amount),
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0E5CA8),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(2.w),
                      // decoration: BoxDecoration(
                      //   color: Colors.grey[100],
                      //   borderRadius: BorderRadius.circular(8.r),
                      // ),
                      child: Text(
                        _amountToWords(transaction.amount),
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),
            // Transaction Details Card
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
                      'Transaction Details',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),

                    _buildDetailRow('Amount:',
                        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN')
                            .format(transaction.amount)),

                    _buildDetailRow('Type:', _getTransactionTypeName(transaction.type)),

                    if (transaction.fromAccount.isNotEmpty)
                      _buildDetailRow('From Account:', transaction.fromAccount),

                    if (transaction.selectedAccount != null && transaction.selectedAccount!.isNotEmpty)
                      _buildDetailRow('To Account:', transaction.selectedAccount!),

                    if (transaction.selectedBank != null && transaction.selectedBank!.isNotEmpty)
                      _buildDetailRow('Bank:', transaction.selectedBank!),

                    _buildDetailRow('Initiator:', transaction.requestedByName ?? transaction.initiator),

                    if (transaction.notes != null && transaction.notes!.isNotEmpty)
                      _buildDetailRow('Remarks:', transaction.notes!),

                    if (transaction.bankReferenceNo != null && transaction.bankReferenceNo!.isNotEmpty)
                      _buildDetailRow('Bank Reference:', transaction.bankReferenceNo!),

                    if (transaction.erpPostingStatus != null && transaction.erpPostingStatus!.isNotEmpty)
                      _buildDetailRow('ERP Status:', transaction.erpPostingStatus!),

                    // Last updated info
                    if (transaction.updatedAt != null) ...[
                      SizedBox(height: 8.h),
                      if (transaction.updatedAt != null)
                        Text(
                          'Last updated: ${formatUpdatedAtAbsoluteDT(transaction.updatedAt)}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Add this after the receipt image section or wherever appropriate
            if (transaction.type == TransactionType.bank)
              _buildBankDepositSlipSection(transaction),

            // Receipt Preview (if available)
            if (transaction.receiptImagePath != null) ...[
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
                          TextButton.icon(
                            onPressed: () => _viewFullReceiptImage(transaction),
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
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Center(
                        child: InkWell(
                          onTap: () => _viewFullReceiptImage(transaction),
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
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Action buttons for pending transactions
            if (transaction.status == TransactionStatus.pending &&
                widget.canApprove &&
                _userName != transaction.initiator) ...[
              // Cash verification for handover transactions
              if (transaction.type == TransactionType.handover) ...[
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
                    // minimumSize: Size(double.infinity, 48.h),
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
                SizedBox(height: 16.h),
              ],

              // Approve/Reject action buttons
              if (
                // show card if it's not a bank transaction
                transaction.type != TransactionType.bank &&
                  (
                      // if it's deposit, always show
                      transaction.type == TransactionType.deposit ||
                          // if it's handover, show only if username matches
                          (transaction.type == TransactionType.handover &&
                              transaction.toAccountId != _userId)
                      )
                  ) ...[
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
                        Text(
                          'Action Required',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          height: 60.h,
                          margin: EdgeInsets.symmetric(vertical: 8.h),
                          child: SwipeActionButton(
                            onReject: () => _showRejectionReasonSheet(transaction),
                            onApprove: () => _approveTransaction(transaction),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            SizedBox(height: 15.h),
            _buildStatusInfoCard(transaction),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  String formatUpdatedAtAbsoluteDT(DateTime? dt, {String locale = 'en_US'}) {
    if (dt == null) return 'Unknown';
    final local = dt.toLocal();
    return DateFormat('MMM dd, yyyy • h:mm a', locale).format(local);
  }


  Widget _buildStatusInfoCard(CashTransaction transaction) {
    if (transaction.status == TransactionStatus.approved) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.green.shade200),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 20.sp, color: Colors.green),
                  SizedBox(width: 8.w),
                  Text(
                    'Approved',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              if (transaction.approvedByName != null && transaction.approvedByName!.isNotEmpty)
                _buildDetailRow('Approved by:', transaction.approvedByName!)
              else if (transaction.approvedBy != null)
                _buildDetailRow('Approved by:', 'User ID: ${transaction.approvedBy}')
              else
                _buildDetailRow('Approved by:', 'System'),

              if (transaction.approvedAt != null)
                _buildDetailRow('Approved on:', formatUpdatedAtAbsoluteDT(transaction.approvedAt)),

              if (transaction.rejectedAt != null)
                _buildDetailRow('Rejected on:', formatUpdatedAtAbsoluteDT(transaction.rejectedAt)),

              if (transaction.approvedAsRole != null && transaction.approvedAsRole!.isNotEmpty)
                _buildDetailRow('Approved as:', transaction.approvedAsRole!),

              if (transaction.approvedUsingAccount != null && transaction.approvedUsingAccount!.isNotEmpty)
                _buildDetailRow('Account used:', transaction.approvedUsingAccount!),

              SizedBox(height: 12.h),
              closeButton()
            ],
          ),
        ),
      );
    }

    if (transaction.status == TransactionStatus.rejected) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.red.shade200),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, size: 20.sp, color: Colors.red),
                  SizedBox(width: 8.w),
                  Text(
                    'Rejected',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              if (transaction.rejectedByName != null && transaction.rejectedByName!.isNotEmpty)
                _buildDetailRow('Rejected by:', transaction.rejectedByName!)
              else if (transaction.rejectedBy != null)
                _buildDetailRow('Rejected by:', 'User ID: ${transaction.rejectedBy}')
              else
                _buildDetailRow('Rejected by:', 'System'),

              if (transaction.rejectedAt != null)
                _buildDetailRow('Rejected on:',
                    DateFormat('MMM dd, yyyy • h:mm a').format(transaction.rejectedAt!)),

              if (transaction.rejectionReason != null && transaction.rejectionReason!.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rejection Reason:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        transaction.rejectionReason!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.red[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
                closeButton(),
              ],
            ],
          ),
        ),
      );
    }

    // Pending status
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending, size: 20.sp, color: Colors.orange),
                SizedBox(width: 8.w),
                Text(
                  'Pending Approval',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'This transaction is awaiting approval from an authorized user.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.orange[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveTransaction(CashTransaction transaction) async {
    if (transaction.type == TransactionType.handover && !_isCashReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify cash received before approving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    context.read<CashManagementBloc>().add(
        ApproveTransaction(transactionId: transaction.id)
    );
    // The WillPopScope callback will handle the refresh

    Navigator.pop(context);
  }

  void _showRejectionReasonSheet(CashTransaction transaction) {
    // Reset selection when opening
    _selectedRejectionReason = null;
    _rejectionCommentController.clear();

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
                    'Specify reason for rejecting transaction #${transaction.id}',
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
                            // minimumSize: Size(20, 48.h),
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
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _selectedRejectionReason == null ? null : () async {
                            Navigator.pop(context); // Close the bottom sheet

                            context.read<CashManagementBloc>().add(
                                RejectTransaction(
                                  transactionId: transaction.id,
                                  reason: _selectedRejectionReason!,
                                  comment: _rejectionCommentController.text.trim().isNotEmpty
                                      ? _rejectionCommentController.text.trim()
                                      : null,
                                )
                            );

                            // The WillPopScope callback will handle the refresh
                            Navigator.pop(context); // Go back to cash_page
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            // minimumSize: Size(20, 48.h)
                          ),
                          child: const Text('Reject'),
                        ),
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

  void _viewFullReceiptImage(CashTransaction transaction) {
    if (transaction.receiptImagePath == null) return;

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
              imageProvider: FileImage(File(transaction.receiptImagePath!)),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDepositSlipSection(CashTransaction transaction) {
    if (transaction.bankDepositDetails == null) return const SizedBox.shrink();

    final bankSlipUrl = transaction.bankDepositDetails!['bank_deposit_slip'] as String? ??
        transaction.bankDepositDetails!['bank_deposit_slip_url'] as String?;

    if (bankSlipUrl == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Text(
          'Bank Deposit Slip',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _viewFullBankDepositSlip(bankSlipUrl),
          child: Container(
            height: 200.h,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.network(
                bankSlipUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                        SizedBox(height: 8.h),
                        Text('Failed to load image', style: TextStyle(fontSize: 12.sp)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Center(
          child: Text(
            'Tap to view full image',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  void _viewFullBankDepositSlip(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF0E5CA8),
            title: const Text('Bank Deposit Slip'),
          ),
          body: Container(
            color: Colors.black,
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              backgroundDecoration: const BoxDecoration(
                color: Colors.black,
              ),
              loadingBuilder: (context, event) => Center(
                child: CircularProgressIndicator(
                  value: event == null
                      ? 0
                      : event.cumulativeBytesLoaded / (event.expectedTotalBytes ?? 1),
                ),
              ),
              errorBuilder: (context, error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64.sp, color: Colors.red),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load image',
                      style: TextStyle(fontSize: 16.sp, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget closeButton() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // ✅ SIMPLE: Just pop, no refresh
          Navigator.of(context).pop(_isTransactionUpdated);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          // minimumSize: Size(200.w, 48.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: const Text(
          'Close',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
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

  String _amountToWords(double amount) {
    final int wholeAmount = amount.toInt();

    if (wholeAmount == 0) return 'Zero Rupees';

    final ones = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine'];
    final teens = ['Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convertHundreds(int num) {
      String result = '';
      if (num >= 100) {
        result += '${ones[num ~/ 100]} Hundred ';
        num %= 100;
      }
      if (num >= 20) {
        result += '${tens[num ~/ 10]} ';
        num %= 10;
      }
      if (num >= 10) {
        result += '${teens[num - 10]} ';
        num = 0;
      }
      if (num > 0) {
        result += '${ones[num]} ';
      }
      return result.trim();
    }

    String result = '';

    if (wholeAmount >= 10000000) {
      result += '${convertHundreds(wholeAmount ~/ 10000000)} Crore ';
      final remaining = wholeAmount % 10000000;
      if (remaining >= 100000) result += '${convertHundreds(remaining ~/ 100000)} Lakh ';
      if (remaining % 100000 >= 1000) result += '${convertHundreds((remaining % 100000) ~/ 1000)} Thousand ';
      if (remaining % 1000 > 0) result += convertHundreds(remaining % 1000);
    } else if (wholeAmount >= 100000) {
      result += '${convertHundreds(wholeAmount ~/ 100000)} Lakh ';
      final remaining = wholeAmount % 100000;
      if (remaining >= 1000) result += '${convertHundreds(remaining ~/ 1000)} Thousand ';
      if (remaining % 1000 > 0) result += convertHundreds(remaining % 1000);
    } else if (wholeAmount >= 1000) {
      result += '${convertHundreds(wholeAmount ~/ 1000)} Thousand ';
      if (wholeAmount % 1000 > 0) result += convertHundreds(wholeAmount % 1000);
    } else {
      result = convertHundreds(wholeAmount);
    }

    return '${result.trim()} Rupees Only';
  }

}