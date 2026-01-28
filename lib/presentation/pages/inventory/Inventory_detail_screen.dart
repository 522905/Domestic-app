import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_state.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../../utils/swipeButton.dart';
import '../../../l10n/app_localizations.dart';
import '../../../utils/gatepass_dialog.dart';
import '../../blocs/inventory/inventory_bloc.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/cancel_request_dialog.dart';
import '../../../core/services/User.dart';

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
  String? _currentUserName;

  Map<String, List<String>> _getRejectionReasons(BuildContext context) {
    return {
      'DEPOSIT': [
        AppLocalizations.of(context)!.rejectionReasonIncorrectCount,
        AppLocalizations.of(context)!.rejectionReasonWrongItems,
        AppLocalizations.of(context)!.rejectionReasonDepositProcessed,
        AppLocalizations.of(context)!.rejectionReasonDefectiveMissing,
        AppLocalizations.of(context)!.rejectionReasonOther,
      ],
      'COLLECT': [
        AppLocalizations.of(context)!.rejectionReasonInsufficientStock,
        AppLocalizations.of(context)!.rejectionReasonOrdersNotEligible,
        AppLocalizations.of(context)!.rejectionReasonVehicleNotAvailable,
        AppLocalizations.of(context)!.rejectionReasonWarehouseClosed,
        AppLocalizations.of(context)!.rejectionReasonOther,
      ],
      'TRANSFER': [
        AppLocalizations.of(context)!.rejectionReasonInsufficientStockSource,
        AppLocalizations.of(context)!.rejectionReasonDestinationFull,
        AppLocalizations.of(context)!.rejectionReasonVehicleNotAvailable,
        AppLocalizations.of(context)!.rejectionReasonTransferBlocked,
        AppLocalizations.of(context)!.rejectionReasonOther,
      ],
    };
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryBloc>().add(
            LoadInventoryRequestDetail(requestId: widget.requestId)
        );
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final userName = await User().getUserName();
    if (mounted) {
      setState(() {
        _currentUserName = userName;
      });
    }
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
          context.showWarningSnackBar(AppLocalizations.of(context)!.messagePleaseWait);
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.inventoryRequestDetailsTitle),
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
            if (state is InventoryActionSuccess) {
              if (mounted) {
                // Show success message
                if (state.action == 'approve') {
                  context.showSuccessSnackBar(state.message);
                } else {
                  context.showInfoSnackBar(state.message);
                }

                // Don't navigate away - let the detail refresh happen
                setState(() {
                  _isProcessing = false;
                });
              }
            }

            // Handle cancellation success
            if (state is InventoryCancelSuccess) {
              if (mounted) {
                // Show success message
                context.showInfoSnackBar(state.message);

                // Reset processing state
                setState(() {
                  _isProcessing = false;
                });

                // Navigate back to list after successful cancellation
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                });
              }
            }

            // Handle detail loaded after approval
            if (state is InventoryDetailLoaded && !_isProcessing) {
              if (mounted) {
                // Detail refreshed successfully, update UI
                setState(() {
                  // Force rebuild to show new status
                });
              }
            }

            // Handle errors
            if (state is InventoryError) {
              if (mounted) {
                setState(() => _isProcessing = false);
                context.showErrorSnackBar(state.message);
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
                      if (request.requestType.toUpperCase() == 'COLLECT' ||
                          request.requestType.toUpperCase() == 'DEPOSIT')
                        GatepassDialog(request: request),
                      SizedBox(height: 3.h),
                      _buildActionButtons(request),
                      SizedBox(height: 3.h),
                    ]
                    else ...[
                      _buildStatusIndicator(request),
                      SizedBox(height: 2.h),
                      // Show cancel button if user is the requester and status is PENDING
                      if (_shouldShowCancelButton(request)) ...[
                        _buildCancelButton(request),
                        SizedBox(height: 2.h),
                      ],
                      if ( widget.userRole.contains('Warehouse Manager')) ...[
                        if (request.requestType.toUpperCase() == 'COLLECT' ||
                            request.requestType.toUpperCase() == 'DEPOSIT')
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
            AppLocalizations.of(context)!.inventoryFailedToLoadDetails,
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
            child: Text(AppLocalizations.of(context)!.buttonTryAgain),
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
      AppLocalizations.of(context)!.inventoryRequestID: request.id,
      AppLocalizations.of(context)!.inventoryRequestType: request.requestType,
      AppLocalizations.of(context)!.profileWarehouseLabel: request.warehouse,
      AppLocalizations.of(context)!.inventoryRequestedBy: request.requestedBy,
      AppLocalizations.of(context)!.inventoryCreatedAt: _formatDateTime(request.timestamp),
      AppLocalizations.of(context)!.orderStatusLabel: request.status,
      AppLocalizations.of(context)!.inventoryVehicleNumber: request.vehicle ?? 'N/A',
      if (request.rejectionReason != null && request.rejectionReason!.isNotEmpty)
      AppLocalizations.of(context)!.inventoryRejectionReason: request.rejectionReason!,

    };

    // if (request.vehicle != null && request.vehicle!.isNotEmpty) {
    //   details['Partner'] = request.vehicle!;
    // }

    if (request.remarks != null && request.remarks!.isNotEmpty) {
      details[AppLocalizations.of(context)!.inventoryNotesLabel] = request.remarks!;
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
            _sectionHeader(AppLocalizations.of(context)!.inventoryTransferDetailsTitle, Icons.swap_horiz),
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
                          AppLocalizations.of(context)!.inventoryFromSource,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.sourceWarehouse ?? AppLocalizations.of(context)!.inventoryUnknownWarehouse,
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
                          AppLocalizations.of(context)!.inventoryToDestination,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.green.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          request.targetWarehouse ?? AppLocalizations.of(context)!.inventoryUnknownWarehouse,
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
                  '${AppLocalizations.of(context)!.inventoryItemsLabel} (${items.length})',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E5CA8),
                  ),
                ),
              ],
            ),

            // Common SO/MR reference
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: (salesOrderRef.isEmpty && materialRequestRef.isEmpty)
                    ? Colors.orange.shade50
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: (salesOrderRef.isEmpty && materialRequestRef.isEmpty)
                      ? Colors.orange.shade300
                      : Colors.blue.shade200,
                ),
              ),
              child: (salesOrderRef.isEmpty && materialRequestRef.isEmpty)
                  ? Row(
                      children: [
                        Icon(
                          Icons.link_off,
                          size: 16.sp,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          AppLocalizations.of(context)!.inventoryUnlinkedLabel,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        if (salesOrderRef.isNotEmpty)
                          _buildReferenceRow(Icons.receipt_long, AppLocalizations.of(context)!.inventorySalesOrderLabel, salesOrderRef),
                        if (materialRequestRef.isNotEmpty)
                          _buildReferenceRow(Icons.assignment, AppLocalizations.of(context)!.inventoryMaterialRequestLabel, materialRequestRef),
                      ],
                    ),
            ),

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
                    _buildTableHeader(AppLocalizations.of(context)!.inventoryItemDetailsHeader),
                    _buildTableHeader(AppLocalizations.of(context)!.inventoryQtyHeader),
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
                  '${AppLocalizations.of(context)!.inventoryCodeLabel}: $itemCode  -  $lineType',
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
                    AppLocalizations.of(context)!.inventoryDefectiveDetailsLabel,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),

                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryCylinderNumber, extra!['cylinder_number']),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryTareWeight, extra['tare_weight'] != null ? '${extra['tare_weight']} kg' : null),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryGrossWeight, extra['gross_weight'] != null ? '${extra['gross_weight']} kg' : null),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryNetWeight, extra['net_weight'] != null ? '${extra['net_weight']} kg' : null),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryFaultType, extra['fault_type']),

                SizedBox(height: 4.h),
                Divider(color: Colors.orange.shade200, thickness: 1),
                SizedBox(height: 4.h),

                Text(
                  AppLocalizations.of(context)!.inventoryConsumerDetailsLabel,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 4.h),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryConsumerNumber, extra['consumer_number']),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryConsumerName, extra['consumer_name']),
                _buildDefectiveDetail(AppLocalizations.of(context)!.inventoryConsumerMobile, extra['consumer_mobile_number']),
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
            _sectionHeader(AppLocalizations.of(context)!.inventoryRemarksLabel, Icons.comment),
            SizedBox(height: 12.h),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.inventoryAddCommentsHint,
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
        message = AppLocalizations.of(context)!.inventoryStatusApprovedMessage(request.requestType.toLowerCase());
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        message = AppLocalizations.of(context)!.inventoryStatusRejectedMessage(request.requestType.toLowerCase());
        icon = Icons.cancel;
        break;
      default:
        message = AppLocalizations.of(context)!.inventoryStatusPendingMessage(request.requestType.toLowerCase());
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
            Text('${AppLocalizations.of(context)!.buttonApprove} ${request.requestType}'),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.inventoryApproveConfirmMessage(request.requestType.toLowerCase())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processApproval(request);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: Text(AppLocalizations.of(context)!.buttonApprove, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(InventoryRequest request) {
    List<String> reasons = _getRejectionReasons(context)[request.requestType.toUpperCase()] ??
        _getRejectionReasons(context)['DEPOSIT']!;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 24.sp),
              SizedBox(width: 8.w),
              Text('${AppLocalizations.of(context)!.buttonReject} ${request.requestType}'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.inventorySelectRejectionReason),
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
              child: Text(AppLocalizations.of(context)!.buttonCancel),
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
              child: Text(AppLocalizations.of(context)!.buttonReject, style: const TextStyle(color: Colors.white)),
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

  bool _shouldShowCancelButton(InventoryRequest request) {
    return request.status.toUpperCase() == 'PENDING';
  }

  Widget _buildCancelButton(InventoryRequest request) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _handleCancelRequest(request),
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            gradient: LinearGradient(
              colors: [Colors.red.shade400, Colors.red.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cancel_outlined,
                color: Colors.white,
                size: 24.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                AppLocalizations.of(context)!.inventoryCancelRequestButton,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancelRequest(InventoryRequest request) async {
    final confirmed = await CancelRequestDialog.show(context, request.id);

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      try {
        context.read<InventoryBloc>().add(
          CancelInventoryRequest(requestId: request.id),
        );
        // Don't navigate here - let the BlocConsumer handle it
      } catch (e) {
        if (mounted) {
          setState(() => _isProcessing = false);
          context.showErrorSnackBar('Failed to cancel request: $e');
        }
      }
    }
  }
}