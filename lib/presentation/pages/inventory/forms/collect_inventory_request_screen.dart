import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/inventory/inventory_request.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../utils/error_handler.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/inventory/inventory_event.dart';
import '../../../blocs/inventory/inventory_state.dart';
import '../../../blocs/vehicle/vehicle_bloc.dart';
import '../../../blocs/vehicle/vehicle_event.dart';
import '../../../blocs/vehicle/vehicle_state.dart';
import '../../../widgets/inventory/collect/collect_order_items_widget.dart';
import '../../../widgets/selectors/vehicle_selector_dialog.dart';
import '../../../widgets/error_dialog.dart';
import '../../../widgets/professional_snackbar.dart';

class CollectInventoryScreen extends StatefulWidget {
  const CollectInventoryScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<CollectInventoryScreen> createState() => _CollectInventoryScreenState();
}

class _CollectInventoryScreenState extends State<CollectInventoryScreen> {
  late final ApiServiceInterface apiService;

  // Selected data
  String? _selectedVehicle;
  String? _selectedVehicleId;
  String? _selectedVehicleType;
  String? _activeWarehouse;
  int? _activeWarehouseId;

  // State
  bool _isSubmitting = false;
  bool _isLoadingPendingItems = false;
  final List<CollectOrderItem> _selectedItems = [];

  // Data
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic> _pendingDeliveryData = {};

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _loadVehicles();
  }

  @override
  void dispose() {
    _isSubmitting = false;
    super.dispose();
  }

  void _loadVehicles() {
    context.read<VehicleBloc>().add(const LoadVehicles());
  }

  Future<void> _loadPendingDeliveryItems() async {
    if (_selectedVehicleId == null) {
      return;
    }

    setState(() {
      _isLoadingPendingItems = true;
      _selectedItems.clear(); // Clear previously selected items
      _pendingDeliveryData = {};
      _activeWarehouse = null; // Reset active warehouse
      _activeWarehouseId = null; // Reset active warehouse ID
    });

    try {
      // Call API with only vehicleId (no warehouse parameter)
      final pendingItems =
      await apiService.getPendingDeliveryItems(_selectedVehicleId!);

      setState(() {
        _pendingDeliveryData = pendingItems;
        _isLoadingPendingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPendingItems = false;
        _pendingDeliveryData = {};
      });

      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Pending Delivery Items',
          error: e,
          onRetry: _loadPendingDeliveryItems,
        );
      }
    }
  }

  void _showVehicleSelectionDialog() async {
    final selectedVehicle = await VehicleSelectorDialog.show(
      context: context,
      vehicles: _vehicles,
      title: 'Select vehicle',
    );

    if (selectedVehicle != null) {
      setState(() {
        _selectedVehicleId = selectedVehicle['id']?.toString() ?? 'Unknown';
        _selectedVehicle = selectedVehicle['vehicle_number'] ?? 'Unknown';
        _selectedVehicleType =
            selectedVehicle['vehicle_type']?.toString().toUpperCase() ?? '';

        // Clear previous data when vehicle changes
        _selectedItems.clear();
        _pendingDeliveryData = {};
        _activeWarehouse = null;
        _activeWarehouseId = null;
      });

      // Load pending items for selected vehicle
      _loadPendingDeliveryItems();
    }
  }

  void _onWarehouseSelected(String? warehouse, int? warehouseId) {
    setState(() {
      _activeWarehouse = warehouse;
      _activeWarehouseId = warehouseId;
    });
  }

  void _onItemsChanged(List<CollectOrderItem> items) {
    setState(() {
      _selectedItems.clear();
      _selectedItems.addAll(items);
    });
  }

  void _showItemSelectionDialog() {
    if (_pendingDeliveryData.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildItemSelectionPage(),
      ),
    );
  }

  Widget _buildItemSelectionPage() {
    return StatefulBuilder(
      builder: (context, setPageState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Delivery Items'),
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
            actions: [
              if (_selectedItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Center(
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Text(
                        '${_selectedItems.length} items',
                        style: TextStyle(
                          color: const Color(0xFF0E5CA8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: CollectOrderItemsWidget(
                  pendingDeliveryData: _pendingDeliveryData,
                  selectedItems: _selectedItems,
                  activeWarehouse: _activeWarehouse,
                  onItemsChanged: (items) {
                    _onItemsChanged(items);
                    setPageState(() {}); // Update the page immediately
                  },
                  onWarehouseSelected: (warehouse, warehouseId) {
                    _onWarehouseSelected(warehouse, warehouseId);
                    setPageState(() {}); // Update the page immediately
                  },
                ),
              ),
              if (_selectedItems.isNotEmpty)
                _buildBottomSectionWithState(setPageState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSectionWithState(StateSetter setPageState) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Items (${_selectedItems.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                ..._selectedItems.take(3).map((item) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          style: TextStyle(fontSize: 14.sp),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Qty: ${item.metadata['selected_qty'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                )),
                if (_selectedItems.length > 3)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      '... and ${_selectedItems.length - 3} more items',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (_selectedItems.isNotEmpty) ...[
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Quantity:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: const Color(0xFF0E5CA8),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${_selectedItems.fold(0, (sum, item) => sum + (item.metadata['selected_qty'] as int? ?? 0))}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Single Back Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Back to Challan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWarehouseBanner() {
    if (_activeWarehouse == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0E5CA8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: const Color(0xFF0E5CA8).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warehouse,
            color: const Color(0xFF0E5CA8),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collecting from:',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  _activeWarehouse!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E5CA8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              _activeWarehouseId != null
                  ? 'ID: $_activeWarehouseId'
                  : 'ID: Unknown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConfirmCollectionDialog() {
    if (_selectedItems.isEmpty) {
      context.showWarningSnackBar('Please select at least one item');
      return;
    }

    if (_selectedVehicleId == null) {
      context.showWarningSnackBar('Please select a vehicle');
      return;
    }

    final summary = _calculateCollectionSummary();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Confirm Collection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                    'Are you sure you want to submit this collection request?'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle: $_selectedVehicle',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_activeWarehouse != null)
                        Text(
                          'From Warehouse: $_activeWarehouse',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 8),
                      const Text('Items:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ...summary.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• ${e.key}: ${e.value}'),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0E5CA8)),
                          foregroundColor: const Color(0xFF0E5CA8),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _submitCollection();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E5CA8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitCollection() {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true; // Disable the submit button
    });

    final itemsForApi = _selectedItems.map((item) {
      return {
        "item_code": item.itemCode,
        "qty": item.metadata['selected_qty'] ?? 0,
        "sales_order_ref": item.salesOrder,
        "sales_order_detail_ref": item.salesOrderItem,
      };
    }).toList();

    final newRequest = InventoryRequest(
      requestType: 'COLLECT',
      vehicle: _selectedVehicleId ?? '',
      warehouse: _activeWarehouseId?.toString() ?? '',
      items: itemsForApi,
    );

    // Dispatch the request to the InventoryBloc and wait for response via BlocListener
    context.read<InventoryBloc>().add(AddInventoryRequest(request: newRequest));
  }


  void _showSuccessDialog(String requestId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Collection Request Submitted',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Request ID: $requestId',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog first
                        if (mounted) {
                          Navigator.pop(context); // Go back to previous screen
                          // Trigger refresh when we return to the list
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('OK'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, int> _calculateCollectionSummary() {
    Map<String, int> summary = {};

    for (var item in _selectedItems) {
      String itemName = item.displayName;
      int quantity = item.metadata['selected_qty'] ?? 0;
      summary[itemName] = (summary[itemName] ?? 0) + quantity;
    }

    return summary;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
        listener: (context, state) {
          if (state is InventoryLoaded) {
            // Success - request was created successfully
            setState(() {
              _isSubmitting = false;
            });

            // Show success dialog
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final requestId = 'CL-$timestamp';
            _showSuccessDialog(requestId);

          } else if (state is InventoryError) {
            // Error - show error popup
            setState(() {
              _isSubmitting = false;
            });

            if (mounted) {
              // Use the improved error handler to show popup
              ErrorHandler.showErrorPopup(
                context,
                state.message,
                onRetry: _submitCollection, // Optional retry callback
              );
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Challan'),
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: CustomScrollView(
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Collection Type Info Header - More compact
                    Container(
                      margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.withOpacity(0.1),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.insert_page_break,
                              color: Colors.blue,
                              size: 20.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Challan',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Select vehicle to create a new collection challan',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Vehicle Selection Card - More compact
                    BlocBuilder<VehicleBloc, VehicleState>(
                      builder: (context, vehicleState) {
                        if (vehicleState is VehicleLoaded) {
                          _vehicles = vehicleState.vehicles;
                        }

                        return Container(
                          margin:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w, vertical: 4.h),
                            leading: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.local_shipping,
                                  color: const Color(0xFF0E5CA8), size: 18.sp),
                            ),
                            title: Text(
                              _selectedVehicle ?? 'Select Vehicle',
                              style: TextStyle(
                                color: _selectedVehicle != null
                                    ? Colors.black
                                    : Colors.grey,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: _selectedVehicleId != null
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectedVehicleType != null)
                                  Text(
                                    'Type: ${_selectedVehicleType?.toUpperCase()}',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                              ],
                            )
                                : Text(
                              'Tap to select a vehicle',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11.sp,
                              ),
                            ),
                            trailing: vehicleState is VehicleLoading
                                ? SizedBox(
                              width: 16.w,
                              height: 16.h,
                              child:
                              const CircularProgressIndicator(strokeWidth: 2),
                            )
                                : Icon(Icons.arrow_forward_ios,
                                color: const Color(0xFF0E5CA8), size: 16.sp),
                            onTap: vehicleState is VehicleLoaded
                                ? _showVehicleSelectionDialog
                                : null,
                          ),
                        );
                      },
                    ),

                    // Active Warehouse Banner
                    _buildActiveWarehouseBanner(),

                    // Loading or Items Section Header
                    if (_selectedVehicleId != null) ...[
                      if (_isLoadingPendingItems)
                        Container(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            children: [
                              const CircularProgressIndicator(),
                              SizedBox(height: 12.h),
                              Text('Loading pending delivery items...',
                                  style: TextStyle(fontSize: 13.sp)),
                            ],
                          ),
                        )
                      else if (_pendingDeliveryData.isNotEmpty) ...[
                        Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pending Delivery Items',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton.icon(
                                icon: Icon(Icons.add_circle_outline, size: 18.sp),
                                label: Text('SELECT ITEMS',
                                    style: TextStyle(fontSize: 12.sp)),
                                onPressed: _showItemSelectionDialog,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Items List or Empty State
              if (_selectedVehicleId != null && !_isLoadingPendingItems)
                _selectedItems.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 48.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          _pendingDeliveryData.isEmpty
                              ? 'No pending deliveries for this vehicle'
                              : 'No items selected yet',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_pendingDeliveryData.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          ElevatedButton.icon(
                            icon: Icon(Icons.add, size: 18.sp),
                            label: Text('Select Items',
                                style: TextStyle(fontSize: 13.sp)),
                            onPressed: _showItemSelectionDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 8.h),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                    : SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final item = _selectedItems[index];
                      return Container(
                        margin: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          border:
                          Border.all(color: Colors.blue, width: 1.5),
                          borderRadius: BorderRadius.circular(8.r),
                          color: Colors.white,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.local_shipping,
                                      color: Colors.blue,
                                      size: 16.sp,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.displayName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                        SizedBox(height: 3.h),
                                        Text(
                                          'Code: ${item.itemCode} • SO: ${item.salesOrder}',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      'Qty: ${item.metadata['selected_qty'] ?? 0}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 28.h,
                                      child: OutlinedButton(
                                        onPressed: _showItemSelectionDialog,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: const BorderSide(
                                              color: Colors.blue),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(6.r),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text('Edit',
                                            style:
                                            TextStyle(fontSize: 11.sp)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Expanded(
                                    child: SizedBox(
                                      height: 28.h,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedItems.removeAt(index);
                                            // If no items left, clear active warehouse
                                            if (_selectedItems.isEmpty) {
                                              _activeWarehouse = null;
                                              _activeWarehouseId = null;
                                            }
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(6.r),
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text('Remove',
                                            style:
                                            TextStyle(fontSize: 11.sp)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: _selectedItems.length,
                  ),
                )
              else
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48.sp,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'Please select a vehicle first',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          // Bottom Summary and Submit Button (Fixed at bottom) - More compact
          bottomNavigationBar: _selectedItems.isNotEmpty
              ? Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary - More compact
                Container(
                  constraints: BoxConstraints(maxHeight: 120.h),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Collection Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          ..._calculateCollectionSummary()
                              .entries
                              .map((entry) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 1.h),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      entry.key,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12.sp),
                                    ),
                                  ),
                                  Text(
                                    '${entry.value}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_calculateCollectionSummary().isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: const Divider(
                                  thickness: 1,
                                  color: Colors.grey,
                                  height: 1),
                            ),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Quantity:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.sp,
                                    color: const Color(0xFF0E5CA8),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E5CA8),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    '${_calculateCollectionSummary().values.fold(0, (sum, qty) => sum + qty)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                    _isSubmitting ? null : _showConfirmCollectionDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5CA8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      height: 18.h,
                      width: 18.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      'SUBMIT COLLECTION REQUEST',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
              : null,
        )
    );
  }

}