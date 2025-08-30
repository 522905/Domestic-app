import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_state.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../../utils/swipeButton.dart';
import '../../../utils/gatepass_dialog.dart';
import '../../blocs/inventory/inventory_bloc.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String requestId;
  final List<String> userRole;
  final bool showApprovalButtons;

  const InventoryDetailScreen({
    Key? key,
    required this.requestId,
    required this.userRole,
    this.showApprovalButtons = true,
  }) : super(key: key);

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  final _commentController = TextEditingController();
  bool _isProcessing = false;
  String? _selectedRejectionReason;

  final Map<String, List<String>> _rejectionReasons = {
    'DEPOSIT': [
      'Insufficient Stock',
      'Incorrect Count',
      'Wrong Items',
      'Deposit Already Processed',
      'Documentation Issues',
      'Other',
    ],
    'COLLECT': [
      'Insufficient Stock',
      'Orders Not Eligible',
      'Vehicle Not Available',
      'Warehouse Closed',
      'Documentation Issues',
      'Other',
    ],
    'TRANSFER': [
      'Insufficient Stock at Source',
      'Destination Warehouse Full',
      'Vehicle Not Available',
      'Transfer Route Blocked',
      'Documentation Issues',
      'Other',
    ],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryBloc>().add(
            LoadInventoryRequestDetail(requestId: widget.requestId)
        );
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    // Reset any processing states
    _isProcessing = false;
    _selectedRejectionReason = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If processing, prevent back navigation
        if (_isProcessing) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait while processing...'),
              duration: Duration(seconds: 1),
            ),
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Request Details'),
          backgroundColor: const Color(0xFF0E5CA8),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                if (mounted) {
                  context.read<InventoryBloc>().add(
                      LoadInventoryRequestDetail(requestId: widget.requestId)
                  );
                }
              },
            ),
          ],
        ),
        body: BlocConsumer<InventoryBloc, InventoryState>(
          listener: (context, state) {
            // Handle approval/rejection success
            if (state is InventoryLoaded && _isProcessing) {
              if (mounted) {
                setState(() => _isProcessing = false);
                // Show success message and navigate back
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Request processed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context, true); // Return true to indicate success
              }
            }

            // Handle errors
            if (state is InventoryError && _isProcessing) {
              if (mounted) {
                setState(() => _isProcessing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          buildWhen: (previous, current) {
            // Only rebuild for detail-specific states
            return current is InventoryDetailLoading ||
                current is InventoryDetailLoaded ||
                current is InventoryDetailError;
          },
          builder: (context, state) {
            if (state is InventoryDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is InventoryDetailError) {
              return _buildErrorState(state.message);
            }

            if (state is InventoryDetailLoaded) {
              final request = state.request;
              return RefreshIndicator(
                onRefresh: () async {
                  if (mounted) {
                    context.read<InventoryBloc>().add(
                        LoadInventoryRequestDetail(requestId: widget.requestId)
                    );
                    await Future.delayed(const Duration(milliseconds: 500));
                  }
                },
                child: ListView(
                  padding: EdgeInsets.all(10.w),
                  children: [
                    _buildRequestHeader(request),
                    SizedBox(height: 2.h),
                    _buildRequestDetailsTable(request),
                    SizedBox(height: 2.h),
                    _buildItemsTable(request),
                    SizedBox(height: 2.h),
                    if (_shouldShowTransferDetails(request))
                      _buildTransferDetailsTable(request),
                    if (_shouldShowTransferDetails(request))
                      SizedBox(height: 2.h),
                    if (_shouldShowApprovalButtons(request)) ...[
                      _buildCommentSection(),
                      SizedBox(height: 2.h),
                      _buildActionButtons(request),
                    ]
                    else
                      _buildStatusIndicator(request),
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

  bool _shouldShowApprovalButtons(InventoryRequest request) {
    return widget.showApprovalButtons &&
        request.status.toUpperCase() == 'PENDING' &&
        widget.userRole.contains('Warehouse Manager');
  }

  bool _shouldShowTransferDetails(InventoryRequest request) {
    return request.requestType.toUpperCase() == 'TRANSFER';
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.red,
          ),
          SizedBox(height: 16.h),
          Text(
            'Failed to load request details',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: () {
              if (mounted) {
                context.read<InventoryBloc>().add(
                    LoadInventoryRequestDetail(requestId: widget.requestId)
                );
              }
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestHeader(InventoryRequest request) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: const LinearGradient(
            colors: [Color(0xFF0E5CA8), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Request #${request.id}",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          request.requestType,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  StatusChip(
                    label: request.status,
                    color: _getStatusColor(request.status),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                request.warehouse,
                style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestDetailsTable(InventoryRequest request) {
    List<TableRow> rows = [
      _buildTableHeader('Information'),
    ];

    Map<String, String> details = {
      'Request ID': request.id,
      'Request Type': request.requestType,
      'Warehouse': request.warehouse,
      'Requested By': request.requestedBy,
      'Created At': _formatDateTime(request.timestamp),
      'Status': request.status,
      if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
      'Rejection Reason': request.rejectionReason!,

    };

    if (request.vehicle != null && request.vehicle!.isNotEmpty) {
      details['Partner'] = request.vehicle!;
    }

    if (request.remarks != null && request.remarks!.isNotEmpty) {
      details['Notes'] = request.remarks!;
    }

    details.forEach((key, value) {
      if (value.isNotEmpty) {
        rows.add(_buildTableRow(key, value));
      }
    });

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
          },
          children: rows,
        ),
      ),
    );
  }

  Widget _buildTransferDetailsTable(InventoryRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Transfer Details', Icons.swap_horiz),
            SizedBox(height: 16.h),
            // Source Warehouse
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.outbox, color: Colors.red.shade600),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From (Source)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.sourceWarehouse ?? 'Unknown Warehouse',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Center(
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_downward,
                  color: Colors.blue.shade600,
                  size: 24.sp,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            // Destination Warehouse
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.inbox, color: Colors.green.shade600),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To (Destination)',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.targetWarehouse ?? 'Unknown Warehouse',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTable(InventoryRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Items Details', Icons.inventory_2),
            SizedBox(height: 16.h),
            if (request.items != null && request.items!.isNotEmpty)
              _buildItemsTableView(request.items!)
            else
              _buildEmptyItemsState(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsTableView(List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8.r),
                topRight: Radius.circular(8.r),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
              child: Row(
                children: [
                  SizedBox(
                    width: 40.w,
                    child: Text(
                      '#',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Item Code',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Quantity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Table Rows
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            Map<String, dynamic> item = entry.value;
            bool isEven = index % 2 == 0;

            return Container(
              decoration: BoxDecoration(
                color: isEven ? Colors.white : Colors.grey[50],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40.w,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0E5CA8),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        item['item_code'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          item['qty']?.toString() ?? '0',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyItemsState() {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 12.h),
            Text(
              'No items found',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Remarks', Icons.comment),
            SizedBox(height: 12.h),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add comments for approval/rejection...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(InventoryRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        padding: EdgeInsets.all(16.w),
        child: _isProcessing
            ? const Center(child: CircularProgressIndicator())
            : SwipeActionButton(
          onReject: () => _showRejectionDialog(request),
          onApprove: () => _showApprovalDialog(request),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(InventoryRequest request) {
    String message;
    IconData icon;

    switch (request.status.toUpperCase()) {
      case 'APPROVED':
        message = 'This ${request.requestType.toLowerCase()} request has been approved';
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        message = 'This ${request.requestType.toLowerCase()} request has been rejected';
        icon = Icons.cancel;
        break;
      default:
        message = 'This ${request.requestType.toLowerCase()} request is pending approval';
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _getStatusColor(request.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getStatusColor(request.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: _getStatusColor(request.status),
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                color: _getStatusColor(request.status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: const Color(0xFF0E5CA8),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0E5CA8),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableHeader(String title) {
    return TableRow(
      children: [
        TableCell(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: const Color(0xFF0E5CA8),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0E5CA8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const TableCell(child: SizedBox()),
      ],
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        TableCell(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
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

  String _formatDateTime(String dateTimeString) {
    final dt = DateTime.tryParse(dateTimeString);
    if (dt == null) return dateTimeString; // bad input, just show it
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
  }


  void _showApprovalDialog(InventoryRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
            SizedBox(width: 8.w),
            Text('Approve ${request.requestType}'),
          ],
        ),
        content: Text('Are you sure you want to approve this ${request.requestType.toLowerCase()} request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(InventoryRequest request) {
    List<String> reasons = _rejectionReasons[request.requestType.toUpperCase()] ??
        _rejectionReasons['DEPOSIT']!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 24.sp),
              SizedBox(width: 8.w),
              Text('Reject ${request.requestType}'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Please select a rejection reason:'),
                SizedBox(height: 16.h),
                Container(
                  height: 200.h,
                  child: SingleChildScrollView(
                    child: Column(
                      children: reasons.map((reason) =>
                          RadioListTile<String>(
                            title: Text(reason),
                            value: reason,
                            groupValue: _selectedRejectionReason,
                            onChanged: (value) {
                              setState(() => _selectedRejectionReason = value);
                            },
                          )
                      ).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _selectedRejectionReason = null);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _selectedRejectionReason == null
                  ? null
                  : () {
                Navigator.pop(context);
                _processRejection(request, _selectedRejectionReason!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF44336),
              ),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processApproval(InventoryRequest request) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      context.read<InventoryBloc>().add(
        ApproveInventoryRequest(
          requestId: widget.requestId,
          requestType: request.requestType.toUpperCase(),
        ),
      );
      // Don't navigate here - let the BlocConsumer handle it
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processRejection(InventoryRequest request, String reason) async {
    if (_isProcessing || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final comment = _commentController.text.trim();
      final fullReason = comment.isNotEmpty ? '$reason - $comment' : reason;

      context.read<InventoryBloc>().add(
        RejectInventoryRequest(
          requestId: widget.requestId,
          reason: fullReason,
          requestType: request.requestType.toUpperCase(),
        ),
      );
      // Don't navigate here - let the BlocConsumer handle it
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}