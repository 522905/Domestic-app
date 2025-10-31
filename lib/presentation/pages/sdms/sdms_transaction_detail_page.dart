// lib/presentation/pages/sdms/sdms_transaction_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../data/models/sdms/sdms_transaction.dart';
import '../../../utils/error_handler.dart';
import '../../blocs/sdms/transaction/sdms_transaction_bloc.dart';
import '../../blocs/sdms/transaction/sdms_transaction_event.dart';
import '../../blocs/sdms/transaction/sdms_transaction_state.dart';

class SDMSTransactionDetailPage extends StatefulWidget {
  final String transactionId;

  const SDMSTransactionDetailPage({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<SDMSTransactionDetailPage> createState() => _SDMSTransactionDetailPageState();
}

class _SDMSTransactionDetailPageState extends State<SDMSTransactionDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<SDMSTransactionBloc>().add(
      LoadTransactionDetailEvent(transactionId: widget.transactionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => context.read<SDMSTransactionBloc>().add(
              LoadTransactionDetailEvent(transactionId: widget.transactionId),
            ),
          ),
        ],
      ),
      body: BlocConsumer<SDMSTransactionBloc, SDMSTransactionState>(
        listener: (context, state) {
          if (state is SDMSTransactionError) {
            ErrorHandler.showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is SDMSTransactionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SDMSTransactionDetailLoaded) {
            return _buildTransactionDetail(state.transaction);
          }

          if (state is SDMSTransactionError) {
            return _buildErrorState(state.message);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTransactionDetail(SDMSTransaction transaction) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(transaction),
          SizedBox(height: 16.h),
          _buildBasicInfoCard(transaction),
          SizedBox(height: 16.h),
          _buildProcessInfoCard(transaction),
          SizedBox(height: 16.h),
          _buildTimestampCard(transaction),
          if (transaction.resultMessage.isNotEmpty || transaction.errorDetails != null) ...[
            SizedBox(height: 16.h),
            _buildMessageCard(transaction),
          ],
          if (_shouldShowRetryButton(transaction)) ...[
            SizedBox(height: 24.h),
            _buildRetryButton(transaction),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(SDMSTransaction transaction) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                _buildStatusBadge(transaction),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Icon(
                  _getActionTypeIcon(transaction.actionType),
                  size: 20.sp,
                  color: const Color(0xFF0E5CA8),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    transaction.actionTypeDisplay,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: const Color(0xFF0E5CA8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoCard(SDMSTransaction transaction) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Transaction ID', transaction.id),
            _buildInfoRow('Order ID', transaction.orderId),
            _buildInfoRow('Order Date', _formatDate(transaction.orderDate)),
            _buildInfoRow('Company', transaction.companyName),
            _buildInfoRow('Initiated By', transaction.initiatedByName),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessInfoCard(SDMSTransaction transaction) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Process Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Process Status', transaction.processStatusDisplay),
            if (transaction.camundaProcessId != null)
              _buildInfoRow('Camunda Process ID', transaction.camundaProcessId!),
            _buildInfoRow('Retry Count', transaction.retryCount.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildTimestampCard(SDMSTransaction transaction) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Timestamps',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            _buildInfoRow('Created At', _formatDateTime(transaction.createdAt)),
            _buildInfoRow('Updated At', _formatDateTime(transaction.updatedAt)),
            if (transaction.completedAt != null)
              _buildInfoRow('Completed At', _formatDateTime(transaction.completedAt!)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(SDMSTransaction transaction) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages & Details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            if (transaction.resultMessage.isNotEmpty) ...[
              _buildMessageSection('Result Message', transaction.resultMessage, false),
              if (transaction.errorDetails != null) SizedBox(height: 12.h),
            ],
            if (transaction.errorDetails != null)
              _buildErrorDetailsSection(transaction.errorDetails!),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDetailsSection(Map<String, dynamic> errorDetails) {
    // Convert map to formatted string
    final formattedError = errorDetails.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Error Details',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.red[700],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Text(
            formattedError,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.red[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageSection(String title, String message, bool isError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: isError ? Colors.red[700] : Colors.green[700],
          ),
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: isError ? Colors.red[50] : Colors.green[50],
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isError ? Colors.red[200]! : Colors.green[200]!,
            ),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: isError ? Colors.red[700] : Colors.green[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SDMSTransaction transaction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _getStatusColor(transaction.processStatus),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Text(
        transaction.processStatusDisplay,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRetryButton(SDMSTransaction transaction) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showRetryDialog(transaction),
        icon: const Icon(Icons.refresh),
        label: const Text('Retry Task'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFF7941D), // Brand Orange
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Error loading transaction',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: () => context.read<SDMSTransactionBloc>().add(
              LoadTransactionDetailEvent(transactionId: widget.transactionId),
            ),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'QUEUED':
        return const Color(0xFFFFC107);
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'FAILED':
        return const Color(0xFFF44336);
      case 'INCIDENT':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getActionTypeIcon(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'INVOICE_ASSIGN':
        return Icons.receipt_long;
      case 'CREDIT_PAYMENT':
        return Icons.payment;
      default:
        return Icons.assignment;
    }
  }

  bool _shouldShowRetryButton(SDMSTransaction transaction) {
    return transaction.processStatus.toUpperCase() == 'FAILED' ||
        transaction.processStatus.toUpperCase() == 'INCIDENT';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  void _showRetryDialog(SDMSTransaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.refresh, color: Color(0xFFF7941D)),
              SizedBox(width: 8),
              Text('Retry Task'),
            ],
          ),
          content: Text(
            'Are you sure you want to retry this ${transaction.actionTypeDisplay.toLowerCase()}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _retryTask(transaction.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF7941D),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        );
      },
    );
  }

  void _retryTask(String transactionId) {
    // Note: Since you mentioned for now you don't want retry functionality,
    // this is a placeholder. When ready, implement the retry API call here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retry functionality will be implemented later'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}