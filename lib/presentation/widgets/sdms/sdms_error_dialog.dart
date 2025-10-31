// lib/presentation/widgets/sdms_error_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/models/sdms/sdms_error_response.dart';

class SDMSErrorDialog extends StatelessWidget {
  final SDMSErrorResponse errorResponse;

  const SDMSErrorDialog({Key? key, required this.errorResponse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(),
            SizedBox(height: 16.h),
            Text(
              _getTitle(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: _getColor(),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              errorResponse.error,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            _buildDetails(),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getColor(),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text('OK', style: TextStyle(fontSize: 16.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    switch (errorResponse.reason) {
      case 'PREVIOUS_REJECTION':
        icon = Icons.block;
        break;
      case 'TRANSACTION_IN_PROGRESS':
        icon = Icons.pending;
        break;
      case 'DUPLICATE_CREDIT':
        icon = Icons.done_all;
        break;
      default:
        icon = Icons.error;
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 48.sp, color: _getColor()),
    );
  }

  Widget _buildDetails() {
    switch (errorResponse.reason) {
      case 'PREVIOUS_REJECTION':
        return _buildRejectionDetails();
      case 'TRANSACTION_IN_PROGRESS':
        return _buildInProgressDetails();
      case 'DUPLICATE_CREDIT':
        return _buildDuplicateDetails();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildRejectionDetails() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Rejected By', errorResponse.details['rejected_by'] ?? 'N/A'),
          _detailRow('Reason', errorResponse.details['rejection_reason'] ?? 'N/A'),
          _detailRow('Rejected At', _formatDate(errorResponse.details['rejected_at'])),
        ],
      ),
    );
  }

  Widget _buildInProgressDetails() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Status', errorResponse.details['status'] ?? 'N/A'),
          _detailRow('Created At', _formatDate(errorResponse.details['created_at'])),
        ],
      ),
    );
  }

  Widget _buildDuplicateDetails() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Partner', errorResponse.details['partner_name'] ?? 'N/A'),
          _detailRow('Partner ID', errorResponse.details['partner_id'] ?? 'N/A'),
          _detailRow('Amount', '₹${errorResponse.details['amount'] ?? 0}'),
          _detailRow('Credited Date', errorResponse.details['credited_date'] ?? 'N/A'),
          _detailRow('Voucher', errorResponse.details['erp_voucher_number'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (errorResponse.reason) {
      case 'PREVIOUS_REJECTION':
        return 'Previous Transaction Rejected';
      case 'TRANSACTION_IN_PROGRESS':
        return 'Transaction In Progress';
      case 'DUPLICATE_CREDIT':
        return 'Credit Already Processed';
      default:
        return 'Error';
    }
  }

  Color _getColor() {
    switch (errorResponse.reason) {
      case 'PREVIOUS_REJECTION':
        return Colors.red;
      case 'TRANSACTION_IN_PROGRESS':
        return Colors.orange;
      case 'DUPLICATE_CREDIT':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
    } catch (_) {
      return date.toString();
    }
  }
}