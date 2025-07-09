import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../blocs/inventory/inventory_state.dart';
import '../../../../utils/swipeButton.dart';

class DepositRequestApprovalScreen extends StatefulWidget {
  final String requestId;

  const DepositRequestApprovalScreen({
    Key? key,
    required this.requestId,
  }) : super(key: key);

  @override
  State<DepositRequestApprovalScreen> createState() => _DepositRequestApprovalScreenState();
}

class _DepositRequestApprovalScreenState extends State<DepositRequestApprovalScreen> {
  final _commentController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedRejectionReason;

  final List<String> _rejectionReasons = [
    'Insufficient Stock',
    'Incorrect Count',
    'Wrong Items',
    'Deposit Already Processed',
    'Other',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit Approval'),
        backgroundColor: const Color(0xFF0E5CA8),
      ),
      body: FutureBuilder<InventoryRequest>(
        future: _fetchRequestDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Error loading request details'));
          }

          final request = snapshot.data!;
          return ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              _buildRequestDetails(request),
              SizedBox(height: 4.h),
              _buildCylinderSummary(request),
              SizedBox(height: 4.h),
              if (request.status == 'PENDING') ...[
                _buildCommentSection(),
                SizedBox(height: 4.h),
                _buildActionButtons(),
              ] else
                _buildStatusIndicator(request),
            ],
          );
        },
      ),
    );
  }

  Future<InventoryRequest> _fetchRequestDetails() async {
    // In real app, fetch from API using widget.requestId
    // For demo, find in existing state
    final state = context.read<InventoryBloc>().state;
    if (state is InventoryLoaded) {
      return state.requests.firstWhere((r) => r.id == widget.requestId);
    }
    throw Exception('Request not found');
  }

  Widget _buildRequestDetails(InventoryRequest request) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                StatusChip(
                  label: request.status,
                  color: _getStatusColor(request.status),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            _detailRow('Request ID', request.id),
            _detailRow('Warehouse', request.warehouseName),
            _detailRow('Requested By', request.requestedBy),
            _detailRow('Role', request.role),
            _detailRow('Date/Time', request.timestamp),
          ],
        ),
      ),
    );
  }

  Widget _buildCylinderSummary(InventoryRequest request) {
    final total = request.cylinders14kg + request.cylinders19kg + request.smallCylinders;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cylinder Summary',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            _cylinderRow('14.2 kg Cylinders', request.cylinders14kg),
            _cylinderRow('19 kg Cylinders', request.cylinders19kg),
            _cylinderRow('Small Cylinders', request.smallCylinders),
            Divider(height: 16.h),
            _cylinderRow('Total Cylinders', total, isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remarks',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5.h),
            TextField(
              controller: _commentController,
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Add comments for approval/rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Container(
        child: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(),
             )
            : SwipeActionButton(
          onReject: () => _showRejectionDialog(),
          onApprove: () => _showApprovalDialog(),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(InventoryRequest request) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: _getStatusColor(request.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            request.status == 'APPROVED' ? Icons.check_circle : Icons.cancel,
            color: _getStatusColor(request.status),
          ),
          SizedBox(width: 8.w),
          Text(
            request.status == 'APPROVED'
                ? 'This request has been approved'
                : 'This request has been rejected',
            style: TextStyle(
              fontSize: 16.sp,
              color: _getStatusColor(request.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cylinderRow(String type, int count, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFC107);
      case 'APPROVED':
        return const Color(0xFF4CAF50);
      case 'REJECTED':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF2196F3);
    }
  }

  void _showApprovalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Request'),
        content: const Text('Are you sure you want to approve this inventory request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reject Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please select a rejection reason:'),
              SizedBox(height: 16.h),
              ..._rejectionReasons.map((reason) => RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedRejectionReason,
                onChanged: (value) {
                  setState(() => _selectedRejectionReason = value);
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedRejectionReason == null
                  ? null
                  : () {
                Navigator.pop(context);
                _processRejection(_selectedRejectionReason!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
              ),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processApproval() async {
    if (_isProcessing) return; // Prevent multiple submissions
    setState(() => _isProcessing = true);

    try {
      // Dispatch the approval event
      context.read<InventoryBloc>().add(ApproveInventoryRequest(
        requestId: widget.requestId,
        comment: _commentController.text.trim(),
      ));

      // Wait a moment to let BLoC process the event
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if there's an error state after processing
      final currentState = context.read<InventoryBloc>().state;
      if (currentState is InventoryError) {
        // Show error but don't navigate away
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: ${currentState.message}'),
            backgroundColor: Colors.orange,
          ),
        );

        // We'll still navigate away, as the local state was updated
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back after approval
      if (mounted) Navigator.pop(context);
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Approval failed: $e\n$stackTrace');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processRejection(String reason) async {
    if (_isProcessing) return; // Prevent multiple submissions
    setState(() => _isProcessing = true);

    try {
      // Dispatch the rejection event
      context.read<InventoryBloc>().add(RejectInventoryRequest(
        requestId: widget.requestId,
        reason: reason.trim(),
      ));

      // Wait a moment to let BLoC process the event
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if there's an error state after processing
      final currentState = context.read<InventoryBloc>().state;
      if (currentState is InventoryError) {
        // Show error but don't navigate away
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Warning: ${currentState.message}'),
            backgroundColor: Colors.orange,
          ),
        );

        // We'll still navigate away, as the local state was updated
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected successfully'),
          backgroundColor: Colors.red,
        ),
      );

      // Navigate back after rejection
      if (mounted) Navigator.pop(context);
    } catch (e, stackTrace) {
      // Log the error for debugging
      debugPrint('Rejection failed: $e\n$stackTrace');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

}