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
import '../../widgets/professional_snackbar.dart';

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
      'Incorrect Count',
      'Wrong Items',
      'Deposit Already Processed',
      'Defective item Missing'
      'Other',
    ],
    'COLLECT': [
      'Insufficient Stock',
      'Orders Not Eligible',
      'Vehicle Not Available',
      'Warehouse Closed',
      'Other',
    ],
    'TRANSFER': [
      'Insufficient Stock at Source',
      'Destination Warehouse Full',
      'Vehicle Not Available',
      'Transfer Route Blocked',
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
          context.showWarningSnackBar('Please wait while processing...');
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
                context.showSuccessSnackBar('Request processed successfully');
                Navigator.pop(context, true); // Return true to indicate success
              }
            }

            // Handle errors
            if (state is InventoryError && _isProcessing) {
              if (mounted) {
                setState(() => _isProcessing = false);
                context.showErrorSnackBar('Error: ${state.message}');
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
                      SizedBox(height: 2.h),
                      _buildCommentSection(),
                      SizedBox(height: 2.h),
                      if (request.requestType.toUpperCase() == 'COLLECT')
                        GatepassDialog(request: request),
                      SizedBox(height: 3.h),
                      _buildActionButtons(request),
                      SizedBox(height: 3.h),
                    ]
                    else ...[
                      _buildStatusIndicator(request),
                      SizedBox(height: 2.h),
                        if ( widget.userRole.contains('Warehouse Manager')) ...[
                            if (request.requestType.toUpperCase() == 'COLLECT')
                              GatepassDialog(request: request),
                            SizedBox(height: 3.h),
                        ]
                    ]
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
    List<TableRow> rows = [];



    Map<String, String> details = {
      'Request ID': request.id,
      'Request Type': request.requestType,
      'Warehouse': request.warehouse,
      'Requested By': request.requestedBy,
      'Created At': _formatDateTime(request.timestamp),
      'Status': request.status,
      'Vehicle Number': request.vehicle ?? 'N/A',
      if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
      'Rejection Reason': request.rejectionReason!,

    };

    // if (request.vehicle != null && request.vehicle!.isNotEmpty) {
    //   details['Partner'] = request.vehicle!;
    // }

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
    final items = request.items ?? [];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Extract common SO/MR reference from first item
    final firstItem = items.first;
    final salesOrderRef = firstItem['sales_order_ref']?.toString() ?? '';
    final materialRequestRef = firstItem['material_request_ref']?.toString() ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 4.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5CA8),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Items (${items.length})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E5CA8),
                  ),
                ),
              ],
            ),

            // Common SO/MR reference
            if (salesOrderRef.isNotEmpty || materialRequestRef.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  children: [
                    if (salesOrderRef.isNotEmpty)
                      _buildReferenceRow(Icons.receipt_long, 'Sales Order', salesOrderRef),
                    if (materialRequestRef.isNotEmpty)
                      _buildReferenceRow(Icons.assignment, 'Material Request', materialRequestRef),
                  ],
                ),
              ),
            ],

            SizedBox(height: 12.h),

            // Items Table - FIXED: Header wrapped in TableRow
            Table(
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              columnWidths: const {
                0: FixedColumnWidth(40),
                1: FlexColumnWidth(1),
                2: FixedColumnWidth(50),
              },
              children: [
                // Header Row - FIXED
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5CA8),
                  ),
                  children: [
                    _buildTableHeader('#'),
                    _buildTableHeader('Item Details'),
                    _buildTableHeader('Qty'),
                  ],
                ),

                // Data Rows
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildItemRow(item, index + 1);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildItemRow(Map<String, dynamic> item, int index) {
    final itemCode = item['item_code']?.toString() ?? 'N/A';
    final lineType = item['line_type']?.toString() ?? 'N/A';
    final inventoryDetails = item['inventory_details']?.toString() ??
        item['item_name']?.toString() ??
        'Unknown Item';

    // Parse qty and remove decimals if whole number
    final qtyValue = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
    final qty = qtyValue % 1 == 0 ? qtyValue.toInt().toString() : qtyValue.toString();

    final extra = item['extra'] as Map<String, dynamic>?;
    final isDefective = extra != null && extra.isNotEmpty;

    return TableRow(
      decoration: BoxDecoration(
        color: isDefective ? Colors.orange.shade50 : Colors.white,
      ),
      children: [
        // Index
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Item Details
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name (from inventory_details)
              Text(
                inventoryDetails,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 2.h),

              // Item Code
                Text(
                  'Code: $itemCode  -  $lineType',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              // Defective Details (if defective)
              if (isDefective) ...[
                SizedBox(height: 6.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                  child: Text(
                    'DEFECTIVE  DETAILS ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),

                _buildDefectiveDetail('Cylinder number', extra!['cylinder_number']),
                _buildDefectiveDetail('Tare Wt', extra['tare_weight'] != null ? '${extra['tare_weight']} kg' : null),
                _buildDefectiveDetail('Gross Wt', extra['gross_weight'] != null ? '${extra['gross_weight']} kg' : null),
                _buildDefectiveDetail('Net Wt', extra['net_weight'] != null ? '${extra['net_weight']} kg' : null),
                _buildDefectiveDetail('Fault', extra['fault_type']),

                SizedBox(height: 4.h),
                Divider(color: Colors.orange.shade200, thickness: 1),
                SizedBox(height: 4.h),

                Text(
                  'Consumer Details:',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildDefectiveDetail('Number', extra['consumer_number']),
                _buildDefectiveDetail('Name', extra['consumer_name']),
                _buildDefectiveDetail('Mobile', extra['consumer_mobile_number']),
              ],
            ],
          ),
        ),
        // Quantity
        Padding(
          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              // decoration: BoxDecoration(
              //   color: const Color(0xFF0E5CA8),
              //   borderRadius: BorderRadius.circular(4.r),
              // ),
              child: Text(
                qty,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0E5CA8),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Icon(icon, size: 16.sp, color: Colors.blue.shade700),
          SizedBox(width: 8.w),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectiveDetail(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          SizedBox(
            width: 70.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[900],
              ),
            ),
          ),
        ],
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

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
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
        context.showErrorSnackBar('Failed to approve: $e');
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
        context.showErrorSnackBar('Failed to reject: $e');
      }
    }
  }
}