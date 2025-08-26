import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/User.dart';
import '../../../blocs/orders/orders_event.dart';
import '../../../widgets/orders/order_items_widget.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../core/models/order/selectable_order_item.dart';
import '../../../../core/models/order/order_data.dart';
import '../../../blocs/vehicle/vehicle_bloc.dart';
import '../../../blocs/vehicle/vehicle_state.dart';
import '../../../blocs/vehicle/vehicle_event.dart';
import '../../../blocs/orders/orders_bloc.dart';
import '../../../widgets/selectors/vehicle_selector_dialog.dart';
import '../../../widgets/selectors/warehouse_selector_dialog.dart';
import '../../../widgets/error_dialog.dart';

class CreateSaleOrderScreen extends StatefulWidget {
  const CreateSaleOrderScreen({Key? key}) : super(key: key);

  @override
  State<CreateSaleOrderScreen> createState() => _CreateSaleOrderScreenState();
}

class _CreateSaleOrderScreenState extends State<CreateSaleOrderScreen> {
  late final ApiServiceInterface apiService;

  String _orderType = 'Refill';
  String? _selectedVehicle;
  String? _selectedVehicleId;
  String? _selectedVehicleDriver;
  String? _selectedWarehouse;
  String? _selectedWarehouseId;
  String? _selectedWarehouseName;
  String? _selectedCustomer;
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;
  bool _isLoadingData = true;
  List<String>? userRole;
  String? _selectedPartner;
  String? _selectedPartnerId;
  String? _selectedPartnerName;
  List<Map<String, dynamic>> _partners = [];
  final List<SelectableOrderItem> _selectedItems = [];
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _vehicles = [];

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _loadVehicles();
    _loadWarehouses();
    _fetchUserRole().then((_) {
      if (_isGeneralManager()) {
        _loadPartners();
      }
    });
  }

    Future<void> _fetchUserRole() async {
      final roles = await User().getUserRoles();

      setState(() {
        userRole = roles.map((role) => role.role).toList();
      });
  }

  bool _isGeneralManager() {
    return userRole?.contains('General Manager') == true;
  }

  void _loadVehicles() {
    context.read<VehicleBloc>().add(const LoadVehicles());
  }

  Future<void> _loadWarehouses() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final warehousesData = await apiService.getWarehouses();
      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(warehousesData);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });

      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Warehouses',
          error: e,
          onRetry: _loadWarehouses,
        );
      }
    }
  }

  Future<OrderData?> _loadOrderItems() async {
    if (_selectedWarehouseId == null) return null;

    try {
      final itemData = await apiService.getOrderItems(
          orderType: _orderType,
          warehouseId: _selectedWarehouseId!
      );

      return OrderData(
        rawData: itemData,
        warehouses: _warehouses,
        vehicles: _vehicles,
        orderType: _orderType,
      );
    } catch (e) {
      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Items',
          error: e,
          onRetry: () => _loadOrderItems(),
        );
      }
      return null;
    }
  }

  Future<void> _loadPartners() async {
    if (!_isGeneralManager()) return;

    setState(() {
      _isLoadingData = true;
    });

    try {
      final partnersData = await apiService.getPartnerList(); // You'll need to implement this in your API service
      setState(() {
        _partners = List<Map<String, dynamic>>.from(partnersData);
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });

      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Partners',
          error: e,
          onRetry: _loadPartners,
        );
      }
    }
  }

  String get _orderTypeDisplayName => _orderType;

  IconData get _orderTypeIcon {
    switch (_orderType) {
      case 'Refill':
        return Icons.propane_tank_sharp;
      case 'NFR':
        return Icons.propane_tank_sharp;
      default:
        return Icons.shopping_cart;
    }
  }

  void _showVehicleSelectionDialog() async {
    final selectedVehicle = await VehicleSelectorDialog.show(
      context: context,
      vehicles: _vehicles,
      title: 'Select Vehicle',
    );

    if (selectedVehicle != null) {
      setState(() {
        _selectedVehicleId = selectedVehicle['id']?.toString() ?? 'Unknown';
        _selectedVehicle = selectedVehicle['vehicle_number'] ?? 'Unknown';
        _selectedVehicleDriver = selectedVehicle['name'] ?? '';
        _selectedItems.clear();
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
        _selectedWarehouseName = selectedWarehouse['name'] ?? 'Unknown';
        _selectedWarehouseId = selectedWarehouse['id']?.toString() ?? 'Unknown';
        _selectedWarehouse = selectedWarehouse['name'] ?? 'Unknown';
        _selectedCustomer = selectedWarehouse['warehouse_type'] ?? '';
        // Clear selected items when warehouse changes
        _selectedItems.clear();
      });
    }
  }

  void _showItemSelectionDialog() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Always load items fresh - no caching
    final orderData = await _loadOrderItems();

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (orderData == null) {
      return; // Failed to load items
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildItemSelectionPage(orderData),
      ),
    );
  }

  void _showPartnerSelectionDialog() async {
    final selectedPartner = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Partner',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _partners.length,
                    itemBuilder: (context, index) {
                      final partner = _partners[index];
                      return ListTile(
                        title: Text(partner['partner_id'] ?? 'Unknown'),
                        subtitle: Text(partner['partner_name'] ?? ''),
                        onTap: () {
                          Navigator.pop(context, partner);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedPartner != null) {
      setState(() {
        _selectedPartnerId = selectedPartner['id']?.toString() ?? 'Unknown';
        _selectedPartner = selectedPartner['partner_name'] ?? 'Unknown';
        _selectedPartnerName = selectedPartner['partner_id'] ?? 'Unknown';
      });
    }
  }

  Widget _buildItemSelectionPage(OrderData orderData) {
    return StatefulBuilder(
      builder: (context, setPageState) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Select $_orderTypeDisplayName Items'),
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
                child: _buildItemSelectionWidgetWithState(setPageState, orderData),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
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
                    'Done',
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
      },
    );
  }

  Widget _buildItemSelectionWidgetWithState(StateSetter setPageState, OrderData orderData) {
    return OrderItemsWidget(
      orderData: orderData,
      selectedItems: _selectedItems,
      onItemsChanged: (items) {
        setState(() {
          _selectedItems.clear();
          _selectedItems.addAll(items);
        });
        setPageState(() {}); // Update the page immediately
      },
    );
  }

  void _submitOrder() async {
    // Validation
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

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

    if (_isGeneralManager() && _selectedPartnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a partner')),
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final orderNumber = 'SO-$timestamp';

      final itemsForApi = _selectedItems.map((item) {
        return item.toApiPayload(item.metadata['selected_qty'] ?? 0);
      }).toList();

      final formattedDeliveryDate = DateFormat('yyyy-MM-dd').format(_deliveryDate);

      final orderData = {
        "delivery_date": formattedDeliveryDate,
        "items": itemsForApi,
        "order_type": _orderType,
        "vehicle_number": _selectedVehicle!,
        "warehouse": _selectedWarehouseId!,
        if (_isGeneralManager() && _selectedPartnerId != null)
          "partner": _selectedPartnerId!,
      };

      final response = await apiService.createOrder(orderData);

      if (response['success'] == false) {
        final errorMessage = response['message'] ?? 'An unknown error occurred';
        throw Exception(errorMessage);
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext dialogContext) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(5.0),
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
                      'Order Created Successfully',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order Number: ${response['order_number'] ?? orderNumber}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Refresh orders list
                          context.read<OrdersBloc>().add(LoadOrders());
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
          title: 'Order Creation Failed',
          error: e,
          onRetry: _submitOrder,
        );
      }
    }
  }

  Map<String, int> _calculateOrderSummary() {
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
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Order'),
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
        title: const Text('Create Order'),
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
                // Delivery Date Selection
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    leading: Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          Icons.calendar_today,
                          color: const Color(0xFF0E5CA8),
                          size: 20.sp
                      ),
                    ),
                    title: Text(
                      'Delivery Date',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(_deliveryDate),
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8), size: 16.sp),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _deliveryDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date != null) {
                        setState(() {
                          _deliveryDate = date;
                        });
                      }
                    },
                  ),
                ),
                // Order Type Selection
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                  child: _buildOrderTypeSelector(),
                ),
                // Vehicle Selection Card
                BlocBuilder<VehicleBloc, VehicleState>(
                  builder: (context, vehicleState) {
                    if (vehicleState is VehicleLoaded) {
                      _vehicles = vehicleState.vehicles;
                    }

                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                        leading: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5CA8).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              Icons.local_shipping,
                              color: const Color(0xFF0E5CA8),
                              size: 20.sp
                          ),
                        ),
                        title: Text(
                          _selectedVehicle ?? ' Tap to Select Vehicle',
                          style: TextStyle(
                            color: _selectedVehicle != null ? Colors.black : Colors.grey,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: vehicleState is VehicleLoading
                            ? SizedBox(
                          width: 20.w,
                          height: 20.h,
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
                  margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                    leading: Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                          Icons.warehouse,
                          color: const Color(0xFF0E5CA8),
                          size: 20.sp
                      ),
                    ),
                    title: Text(
                      _selectedWarehouseName ?? 'Select Warehouse',
                      style: TextStyle(
                        color: _selectedWarehouseName != null ? Colors.black : Colors.grey,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8), size: 16.sp),
                    onTap: _showWarehouseSelectionDialog,
                  ),
                ),
                //Partner Selection Card
                if (_isGeneralManager()) ...[
                  // Partner Selection Card
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                      leading: Container(
                        padding: EdgeInsets.all(5.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.business,
                          color: const Color(0xFF0E5CA8),
                          size: 20.sp,
                        ),
                      ),
                      title: Text(
                        _selectedPartnerName ?? 'Select Partner *',
                        style: TextStyle(
                          color: _selectedPartnerName != null ? Colors.black : Colors.grey,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Color(0xFF0E5CA8), size: 16.sp),
                      onTap: _showPartnerSelectionDialog,
                    ),
                  ),
                ],
                // Items Section
                if (_selectedWarehouseId != null && _selectedVehicleId != null) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Items',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                '${_selectedItems.length} items',
                                style: TextStyle(
                                  color: const Color(0xFF0E5CA8),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.add_circle_outline, size: 18.sp),
                            label: Text(
                              _selectedItems.isEmpty ? 'Add Items' : 'Modify Items',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                            onPressed: _showItemSelectionDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Selected Items Display
          if (_selectedItems.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final item = _selectedItems[index];
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: const Color(0xFF0E5CA8).withOpacity(0.3)),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      leading: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _orderTypeIcon,
                          color: const Color(0xFF0E5CA8),
                          size: 16.sp,
                        ),
                      ),
                      title: Text(
                        item.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                      subtitle: Text(
                        'Code: ${item.itemCode}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E5CA8),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Qty: ${item.metadata['selected_qty'] ?? 0}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _selectedItems.length,
              ),
            )
          else if (_selectedWarehouseId != null && _selectedVehicleId != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _orderTypeIcon,
                      size: 48.sp,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No items added yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Tap "Add Items" button to select items',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
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
                    SizedBox(height: 16.h),
                    Text(
                      'Please select vehicle and warehouse first',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Bottom Submit Button
      bottomNavigationBar: _selectedItems.isNotEmpty
          ? Container(
        padding: EdgeInsets.all(5.w),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: const Color(0xFF0E5CA8),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ..._calculateOrderSummary().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              entry.key,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_calculateOrderSummary().isNotEmpty) ...[
                    Divider(thickness: 1, height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                            color: const Color(0xFF0E5CA8),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5CA8),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${_calculateOrderSummary().values.fold(0, (sum, qty) => sum + qty)}',
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  disabledBackgroundColor: Colors.grey.shade400,
                ),
                child: _isSubmitting
                    ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'CREATE SALE ORDER',
                  style: TextStyle(
                    fontSize: 16.sp,
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

  Widget _buildOrderTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildOrderTypeRadio(
            title: 'Refill',
            value: 'Refill',
            groupValue: _orderType,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _buildOrderTypeRadio(
            title: 'NFR',
            value: 'NFR',
            groupValue: _orderType,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderTypeRadio({
    required String title,
    required String value,
    required String groupValue,
  }) {
    final isSelected = groupValue == value;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: isSelected ? const Color(0xFF0E5CA8).withOpacity(0.1) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RadioListTile<String>(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey[700],
          ),
        ),
        value: value,
        groupValue: groupValue,
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _orderType = value;
              _selectedItems.clear();
            });
          }
        },
        activeColor: const Color(0xFF0E5CA8),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      ),
    );
  }
}