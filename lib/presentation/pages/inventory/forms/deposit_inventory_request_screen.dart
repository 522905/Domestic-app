import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/models/inventory/inventory_request.dart';
import '../../../../core/models/deposit/deposit_data.dart';
import '../../../../core/models/deposit/unlinked_deposit_data.dart';
import '../../../../core/models/deposit/sales_order_deposit_data.dart';
import '../../../../core/models/deposit/material_request_deposit_data.dart';
import '../../../../core/models/deposit/selectable_deposit_item.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../blocs/inventory/inventory_bloc.dart';
import '../../../blocs/inventory/inventory_event.dart';
import '../../../blocs/vehicle/vehicle_bloc.dart';
import '../../../blocs/vehicle/vehicle_state.dart';
import '../../../blocs/vehicle/vehicle_event.dart';
import '../../../widgets/inventory/deposit/material_request_items_widget.dart';
import '../../../widgets/inventory/deposit/SalesOrderItemsWidget/sales_order_items_widget.dart';
import '../../../widgets/inventory/deposit/unlinked_items_widget.dart';
import '../../../widgets/selectors/vehicle_selector_dialog.dart';
import '../../../widgets/selectors/warehouse_selector_dialog.dart';
import '../../../widgets/error_dialog.dart';

class DepositInventoryScreen extends StatefulWidget {
  final String depositType;

  const DepositInventoryScreen({
    Key? key,
    required this.depositType,
  }) : super(key: key);

  @override
  State<DepositInventoryScreen> createState() => _DepositInventoryScreenState();
}

class _DepositInventoryScreenState extends State<DepositInventoryScreen> {
  late final ApiServiceInterface apiService;

  // Selected data
  String? _selectedVehicle;
  String? _selectedVehicleId;
  String? _selectedVehicleType;
  String? _selectedWarehouse;
  String? _selectedWarehouseId;
  String? _selectedWarehouseName;
  bool _isSubmitting = false;
  bool _isLoadingData = true;
  final List<SelectableDepositItem> _selectedItems = [];
  final List<SelectedReturn> _selectedReturns = [];

  // Data
  DepositData? _depositData;
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _loadData();
    _loadVehicles();
  }

  @override
  void dispose() {
    _isSubmitting = false;
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load warehouses with deposit type filter
      final warehouses = await apiService.getWarehouses(depositType: widget.depositType);

      // Load deposit-specific data
      Map<String, dynamic> itemData;
      switch (widget.depositType) {
        case DepositData.unlinked:
          itemData = await apiService.getUnlinkedItemList();
          break;
        case DepositData.salesOrder:
          itemData = await apiService.getPendingSaleOrderList();
          break;
        case DepositData.materialRequest:
          itemData = await apiService.getMaterialRequestList();
          break;
        default:
          throw Exception('Unknown deposit type: ${widget.depositType}');
      }

      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(warehouses);
        _depositData = _createDepositData(itemData);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });

      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Data',
          error: e,
          onRetry: _loadData,
        );
      }
    }
  }

  void _loadVehicles() {
    context.read<VehicleBloc>().add(const LoadVehicles());
  }

  DepositData _createDepositData(Map<String, dynamic> itemData) {
    switch (widget.depositType) {
      case DepositData.unlinked:
        return UnlinkedDepositData(
          rawData: itemData,
          warehouses: _warehouses,
          vehicles: _vehicles,
        );
      case DepositData.salesOrder:
        return SalesOrderDepositData(
          rawData: itemData,
          warehouses: _warehouses,
          vehicles: _vehicles,
        );
      case DepositData.materialRequest:
        return MaterialRequestDepositData(
          rawData: itemData,
          warehouses: _warehouses,
          vehicles: _vehicles,
        );
      default:
        throw Exception('Unknown deposit type: ${widget.depositType}');
    }
  }

  String get _depositTypeDisplayName {
    switch (widget.depositType) {
      case DepositData.unlinked:
        return 'Unlinked';
      case DepositData.salesOrder:
        return 'Sales Order';
      case DepositData.materialRequest:
        return 'Material Request';
      default:
        return 'Unknown';
    }
  }

  IconData get _depositTypeIcon {
    switch (widget.depositType) {
      case DepositData.unlinked:
        return Icons.inventory_2;
      case DepositData.salesOrder:
        return Icons.receipt_long;
      case DepositData.materialRequest:
        return Icons.assignment;
      default:
        return Icons.inventory;
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
        _selectedVehicleType = selectedVehicle['vehicle_type']?.toString().toUpperCase() ?? '';
      });
    }
  }

  void _showWarehouseSelectionDialog() async {
    final selectedWarehouse = await WarehouseSelectorDialog.show(
      context: context,
      warehouses: _warehouses,
      title: 'Select Warehouse',
    );

    if (selectedWarehouse != null) {
      setState(() {
        _selectedWarehouseName = selectedWarehouse['warehouse_label'] ?? 'Unknown';
        _selectedWarehouseId = selectedWarehouse['id']?.toString() ?? 'Unknown';
        _selectedWarehouse = selectedWarehouse['location']?.toString().isNotEmpty == true
            ? selectedWarehouse['location'].toString()
            : selectedWarehouse['warehouse_type']?.toString().toUpperCase() ?? 'FIXED';
      });
    }
  }

  void _showItemSelectionDialog() {
    if (_depositData == null) return;

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
            title: Text('Select $_depositTypeDisplayName Items'),
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
            actions: [
              if (_selectedItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
                child: _buildItemSelectionWidgetWithState(setPageState),
              ),
              if (_selectedItems.isNotEmpty)
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
                      'Back to Deposit Screen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              //   _buildBottomSectionWithState(setPageState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemSelectionWidgetWithState(StateSetter setPageState) {
    if (_depositData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (widget.depositType) {
      case DepositData.unlinked:
        return UnlinkedItemsWidget(
          depositData: _depositData as UnlinkedDepositData,
          selectedItems: _selectedItems,
          onItemsChanged: (items) {
            setState(() {
              _selectedItems.clear();
              _selectedItems.addAll(items);
            });
            setPageState(() {}); // Update the page immediately
          },
        );
      case DepositData.salesOrder:
        return SalesOrderItemsWidget(
          depositData: _depositData as SalesOrderDepositData,
          onReturnsChanged: (returns) { // Changed from onItemsChanged
            setState(() {
              _selectedReturns.clear();
              _selectedReturns.addAll(returns);
            });
            setPageState(() {});
          },
        );
      case DepositData.materialRequest:
        return MaterialRequestItemsWidget(
          depositData: _depositData as MaterialRequestDepositData,
          selectedItems: _selectedItems,
          onItemsChanged: (items) {
            setState(() {
              _selectedItems.clear();
              _selectedItems.addAll(items);
            });
            setPageState(() {}); // Update the page immediately
          },
        );
      default:
        return Center(
          child: Text('Unknown deposit type: ${widget.depositType}'),
        );
    }
  }



  void _showConfirmDepositDialog() {

    bool hasItems = widget.depositType == DepositData.salesOrder
        ? _selectedReturns.isNotEmpty
        : _selectedItems.isNotEmpty;

    if (!hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    if (widget.depositType == DepositData.salesOrder
        ? _selectedReturns.isEmpty
        : _selectedItems.isEmpty)

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a warehouse')),
      );
      return;
    }

    if (_selectedVehicleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    final summary = _calculateDepositSummary();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    Text(
                      'Confirm $_depositTypeDisplayName Deposit',
                      style: const TextStyle(
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
                    'Are you sure you want to submit this deposit request?'
                ),
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
                        'Warehouse: $_selectedWarehouseName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Vehicle: $_selectedVehicle',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Type: $_depositTypeDisplayName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          _submitDeposit();
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

  void _submitDeposit() {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final requestId = 'DP-$timestamp';

      List<Map<String, dynamic>> itemsForApi;

      if (widget.depositType == DepositData.salesOrder) {
        // Convert SelectedReturn to API payload
        itemsForApi = _selectedReturns.map((returnItem) {
          Map<String, dynamic> payload = {
            'item_code': returnItem.returnItemCode,
            'item_name': returnItem.returnItemDescription,
            'qty': returnItem.qty.toInt(),
            'return_type': "Deposit",
            'sales_order_ref': returnItem.againstSalesOrder,
            'sales_order_detail_ref': returnItem.againstSalesOrderItem,
            'line_type': returnItem.returnType[0].toUpperCase() + returnItem.returnType.substring(1)
          };

          // Add defective-specific fields if applicable
          if (returnItem.isDefective) {
            payload['extra'] = {
              'cylinder_number': returnItem.cylinderNumber,
              'tare_weight': returnItem.tareWeight,
              'gross_weight': returnItem.grossWeight,
              'net_weight': returnItem.netWeight,
              'fault_type': returnItem.faultType,
              'consumer_number': returnItem.consumerNumber,
              'consumer_name': returnItem.consumerName,
              'consumer_mobile_number': returnItem.consumerMobileNumber,
            };
          }

          return payload;
        }).toList();
      } else {
        // Handle other deposit types (existing logic)
        itemsForApi = _selectedItems.map((item) {
          return item.toApiPayload(item.metadata['selected_qty'] ?? 0);
        }).toList();
      }

      final newRequest = InventoryRequest(
        requestType: 'DEPOSIT',
        vehicle: _selectedVehicleId ?? '',
        warehouse: _selectedWarehouseId ?? 'Unknown',
        items: itemsForApi,
      );

      context.read<InventoryBloc>().add(
          AddInventoryRequest(request: newRequest)
      );

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      'Deposit Request Submitted',
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
                          context.read<InventoryBloc>().add(LoadInventoryRequests());
                          Navigator.pop(dialogContext);
                          Navigator.pop(context);
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
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (mounted) {
        context.showErrorDialog(
          title: 'Submission Failed',
          error: e,
          onRetry: _submitDeposit,
        );
      }
    }
  }

  Map<String, int> _calculateDepositSummary() {
    Map<String, int> summary = {};

    if (widget.depositType == DepositData.salesOrder) {
      // Handle sales order returns
      for (var returnItem in _selectedReturns) {
        String itemName = '${returnItem.returnItemCode} - ${returnItem.returnItemDescription}';
        int quantity = returnItem.qty.toInt();
        summary[itemName] = (summary[itemName] ?? 0) + quantity;
      }
    } else {
      // Handle other deposit types
      for (var item in _selectedItems) {
        String itemName = item.displayName;
        int quantity = item.metadata['selected_qty'] ?? 0;
        summary[itemName] = (summary[itemName] ?? 0) + quantity;
      }
    }

    return summary;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text('$_depositTypeDisplayName Deposit'),
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$_depositTypeDisplayName Deposit'),
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
                // Deposit Type Info Header
                Container(
                  margin: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0E5CA8).withOpacity(0.1),
                        const Color(0xFF0E5CA8).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF0E5CA8).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _depositTypeIcon,
                          color: const Color(0xFF0E5CA8),
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_depositTypeDisplayName Deposit',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0E5CA8),
                              ),
                            ),
                            Text(
                              'Complete the form below to submit your deposit request',
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

                // Vehicle Selection Card
                BlocBuilder<VehicleBloc, VehicleState>(
                  builder: (context, vehicleState) {
                    if (vehicleState is VehicleLoaded) {
                      _vehicles = vehicleState.vehicles;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        leading: Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5CA8).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              Icons.local_shipping,
                              color: const Color(0xFF0E5CA8),
                              size: 18.sp
                          ),
                        ),
                        title: Text(
                          _selectedVehicle ?? 'Select Vehicle',
                          style: TextStyle(
                            color: _selectedVehicle != null ? Colors.black : Colors.grey,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8), size: 16.sp),
                        onTap: vehicleState is VehicleLoaded ? _showVehicleSelectionDialog : null,
                      ),
                    );
                  },
                ),

                // Warehouse Selection Card
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    leading: Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          Icons.warehouse,
                          color: const Color(0xFF0E5CA8),
                          size: 18.sp
                      ),
                    ),
                    title: Text(
                      _selectedWarehouseName ?? 'Select Warehouse',
                      style: TextStyle(
                        color: _selectedWarehouseName != null ? Colors.black : Colors.grey,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      _selectedWarehouseId != null
                          ? 'ID: $_selectedWarehouseId • $_selectedWarehouse'
                          : 'Tap to select a warehouse',
                      style: TextStyle(
                        color: _selectedWarehouseId != null ? Colors.black54 : Colors.grey,
                        fontSize: 11.sp,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8), size: 16.sp),
                    onTap: _showWarehouseSelectionDialog,
                  ),
                ),

                // Items Section Header
                if (_selectedWarehouseId != null && _selectedVehicleId != null)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deposit Items',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.add_circle_outline, size: 18.sp),
                          label: Text('ADD ITEM', style: TextStyle(fontSize: 12.sp)),
                          onPressed: _showItemSelectionDialog,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Items List or Empty State
          if (_selectedWarehouseId != null && _selectedVehicleId != null)
            (widget.depositType == DepositData.salesOrder ? _selectedReturns.isEmpty : _selectedItems.isEmpty)
                ? SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _depositTypeIcon,
                      size: 48.sp,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No items added yet',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add, size: 18.sp),
                      label: Text('Add Items', style: TextStyle(fontSize: 13.sp)),
                      onPressed: _showItemSelectionDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      ),
                    ),
                  ],
                ),
              ),
            )
                : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (widget.depositType == DepositData.salesOrder) {
                        // Group similar returns before displaying
                        final groupedReturns = <String, List<SelectedReturn>>{};

                        for (final returnItem in _selectedReturns) {
                          String groupKey = '${returnItem.returnItemCode}_${returnItem.returnType}_${returnItem.againstSalesOrderItem}';
                          if (returnItem.isDefective) {
                            groupKey += '_${returnItem.cylinderNumber}_${returnItem.faultType}';
                          }
                          groupedReturns.putIfAbsent(groupKey, () => []).add(returnItem);
                        }

                        final returnGroup = groupedReturns.values.elementAt(index);
                        final firstReturn = returnGroup.first;
                        final totalQty = returnGroup.fold(0.0, (sum, item) => sum + item.qty);

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF0E5CA8), width: 1.5),
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
                                        color: firstReturn.isEmpty
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        firstReturn.isEmpty ? Icons.inventory_2_outlined : Icons.inventory,
                                        color: Colors.orange,
                                        size: 16.sp,
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${firstReturn.returnItemCode} - ${firstReturn.returnItemDescription}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          SizedBox(height: 3.h),
                                          Text(
                                            'Against: ${firstReturn.againstItemCode} (${firstReturn.againstSalesOrder})',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        'Qty: ${totalQty.toInt()}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF0E5CA8),
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
                                            foregroundColor: const Color(0xFF0E5CA8),
                                            side: BorderSide(color: const Color(0xFF0E5CA8)),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Text('Edit', style: TextStyle(fontSize: 11.sp)),
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
                                              // Remove all items in the group
                                              for (final returnItem in returnGroup) {
                                                _selectedReturns.removeWhere((item) => item.id == returnItem.id);
                                                (_depositData as SalesOrderDepositData).removeSelectedReturn(returnItem.id);
                                              }
                                            });
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Text('Remove', style: TextStyle(fontSize: 11.sp)),
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
                  else {
                    // Existing code for other deposit types
                    final item = _selectedItems[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF0E5CA8), width: 1.5),
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
                                    color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _depositTypeIcon,
                                    color: const Color(0xFF0E5CA8),
                                    size: 16.sp,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        'Sale order: ${item.metadata['sales_order']}',
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    'Qty: ${item.metadata['selected_qty'] ?? 0}',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: const Color(0xFF0E5CA8),
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
                                        foregroundColor: const Color(0xFF0E5CA8),
                                        side: const BorderSide(color: Color(0xFF0E5CA8)),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text('Edit', style: TextStyle(fontSize: 11.sp)),
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
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(6.r),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text('Remove', style: TextStyle(fontSize: 11.sp)),
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
                },
                childCount: widget.depositType == DepositData.salesOrder
                    ? _getGroupedReturnsCount()
                    : _selectedItems.length,
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
                      'Please select vehicle and warehouse first',
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
      // Bottom Summary and Submit Button
      bottomNavigationBar: (widget.depositType == DepositData.salesOrder ? _selectedReturns.isNotEmpty : _selectedItems.isNotEmpty)
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
            // Summary
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
                        'Summary',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ..._calculateDepositSummary().entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      if (_calculateDepositSummary().isNotEmpty) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: const Divider(thickness: 1, color: Colors.grey, height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E5CA8),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                '${_calculateDepositSummary().values.fold(0, (sum, qty) => sum + qty)}',
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
                onPressed: _isSubmitting ? null : _showConfirmDepositDialog,
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
                  'SUBMIT DEPOSIT REQUEST',
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
    );
  }

  int _getGroupedReturnsCount() {
    final groupedReturns = <String, List<SelectedReturn>>{};

    for (final returnItem in _selectedReturns) {
      String groupKey = '${returnItem.returnItemCode}_${returnItem.returnType}_${returnItem.againstSalesOrderItem}';
      if (returnItem.isDefective) {
        groupKey += '_${returnItem.cylinderNumber}_${returnItem.faultType}';
      }
      groupedReturns.putIfAbsent(groupKey, () => []).add(returnItem);
    }

    return groupedReturns.length;
  }

}