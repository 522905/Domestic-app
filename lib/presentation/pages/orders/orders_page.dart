import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/services/User.dart';
import '../../../core/utils/global_drawer.dart';
import '../../../utils/currency_utils.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../blocs/orders/orders_event.dart';
import '../../blocs/orders/orders_state.dart';
import '../../../domain/entities/order.dart';
import 'forms/create_sale_order_page.dart';
import 'order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<String> _userRole = [];
  // Filter selections
  String? _selectedVehicle;
  String? _selectedWarehouse;
  String? _selectedStatus;
  String? _selectedDeliveryStatus = 'Not Delivered';
  bool _isInitialLoad = true;
  // Static delivery status options
  final List<String> _deliveryStatusOptions = [
    'Not Delivered',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);

    // Apply default filter only on initial load
    if (_isInitialLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyFilters();
        _isInitialLoad = false; // Mark as not initial load anymore
      });
      context.read<OrdersBloc>().add(const LoadOrders());
    } else {
      context.read<OrdersBloc>().add(const LoadOrders());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userRole = await User().getUserRoles();
      setState(() {
        _userRole = userRole.map((userRole) => userRole.role).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      context.read<OrdersBloc>().add(const LoadMoreOrders());
    }
  }

  bool _isGeneralManager() {
    return _userRole.contains('General Manager');
  }

  void _applyFilters() {
    final filters = <String, String>{};

    if (_selectedVehicle != null && _selectedVehicle!.isNotEmpty) {
      filters['vehicle'] = _selectedVehicle!;
    }
    if (_selectedWarehouse != null && _selectedWarehouse!.isNotEmpty) {
      filters['warehouse'] = _selectedWarehouse!;
    }
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      filters['status'] = _selectedStatus!;
    }
    if (_selectedDeliveryStatus != null && _selectedDeliveryStatus!.isNotEmpty) {
      filters['delivery_status'] = _selectedDeliveryStatus!;
    }

    context.read<OrdersBloc>().add(ApplyFilters(filters));
  }

  void _clearAllFilters() {
    setState(() {
      _selectedVehicle = null;
      _selectedWarehouse = null;
      _selectedStatus = null;
      _selectedDeliveryStatus = null;
      _searchController.clear();
    });
    context.read<OrdersBloc>().add(const ClearFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: const Text(
          'Orders',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDeliveryStatus = null; // Clear delivery status on refresh
              });
              context.read<OrdersBloc>().add(const RefreshOrders());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: BlocBuilder<OrdersBloc, OrdersState>(
              builder: (context, state) {
                if (state is OrdersLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is OrdersLoaded) {
                  return _buildOrdersList(state);
                } else if (state is OrdersLoadedWithResponse) {
                  // Handle the response state but show the orders list
                  final ordersState = OrdersLoaded(
                    orders: state.orders,
                    hasMore: false,
                    currentOffset: 0,
                    availableFilters: const {},
                    appliedFilters: const {},
                  );
                  return _buildOrdersList(ordersState);
                } else if (state is OrderDetailsLoaded) {  // ADD THIS BLOCK
                  final ordersState = OrdersLoaded(
                    orders: state.orders,
                    hasMore: state.hasMore,
                    currentOffset: state.currentOffset,
                    availableFilters: state.availableFilters,
                    appliedFilters: state.appliedFilters,
                    searchQuery: state.searchQuery,
                  );
                  return _buildOrdersList(ordersState);
                } else if (state is OrdersError) {
                  return _buildErrorState(state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (_userRole.contains('Delivery Boy') || _userRole.contains('General Manager'))
          ? FloatingActionButton(
        heroTag: 'order_page_screen',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<OrdersBloc>(context),
                child: const CreateSaleOrderScreen(),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF0E5CA8),
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  Widget _buildSearchAndFilterSection() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        // Convert OrderDetailsLoaded to OrdersLoaded for UI consistency
        OrdersLoaded? ordersState;
        if (state is OrdersLoaded) {
          ordersState = state;
        } else if (state is OrderDetailsLoaded) {  // ADD THIS BLOCK
          ordersState = OrdersLoaded(
            orders: state.orders,
            hasMore: state.hasMore,
            currentOffset: state.currentOffset,
            availableFilters: state.availableFilters,
            appliedFilters: state.appliedFilters,
            searchQuery: state.searchQuery,
          );
        }

        return Container(
          color: Colors.white,
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search orders...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16.sp),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  onChanged: (value) {
                    context.read<OrdersBloc>().add(SearchOrders(value));
                  },
                ),
              ),
              // Filter Section - UPDATE THE CONDITION
              if (ordersState != null && ordersState.availableFilters.isNotEmpty)
                _buildFilters(ordersState),

              // Applied Filters Display - UPDATE THE CONDITION
              if (ordersState != null && ordersState.hasFiltersApplied)
                _buildAppliedFilters(ordersState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(OrdersLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [

            _buildStaticFilterChip(
              label: 'Delivery Status',
              value: _selectedDeliveryStatus,
              options: _deliveryStatusOptions,
              onSelected: (value) {
                setState(() {
                  _selectedDeliveryStatus = value;
                });
                _applyFilters();
              },
            ),

            SizedBox(width: 8.w),

            // Vehicle Filter - Show for GM or if vehicle options exist
            if ((_isGeneralManager() || state.availableFilters.containsKey('vehicle')) &&
                state.availableFilters['vehicle']?.isNotEmpty == true)
              _buildFilterChip(
                label: 'Vehicle',
                value: _selectedVehicle,
                options: state.availableFilters['vehicle'] ?? [],
                onSelected: (value) {
                  setState(() {
                    _selectedVehicle = value;
                  });
                  _applyFilters();
                },
              ),

            SizedBox(width: 8.w),

            // Warehouse Filter
            if (state.availableFilters.containsKey('warehouse') &&
                state.availableFilters['warehouse']?.isNotEmpty == true)
              _buildFilterChip(
                label: 'Warehouse',
                value: _selectedWarehouse,
                options: state.availableFilters['warehouse'] ?? [],
                onSelected: (value) {
                  setState(() {
                    _selectedWarehouse = value;
                  });
                  _applyFilters();
                },
              ),

            SizedBox(width: 8.w),

            // Status Filter
            if (state.availableFilters.containsKey('status') &&
                state.availableFilters['status']?.isNotEmpty == true)
              _buildFilterChip(
                label: 'Status',
                value: _selectedStatus,
                options: state.availableFilters['status'] ?? [],
                onSelected: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                  _applyFilters();
                },
              ),

            SizedBox(width: 8.w),

            if (state.availableFilters.containsKey('delivery_status') &&
                state.availableFilters['delivery_status']?.isNotEmpty == true)
              _buildFilterChip(
                label: 'Delivery Status',
                value: _selectedDeliveryStatus,
                options: state.availableFilters['delivery_status'] ?? [],
                onSelected: (value) {
                  setState(() {
                    _selectedDeliveryStatus = value;
                  });
                  _applyFilters();
                },
              ),

          ],
        ),
      ),
    );
  }

  Widget _buildStaticFilterChip({
    required String label,
    required String? value,
    required List<String> options,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value ?? label,
            style: TextStyle(
              fontSize: 12.sp,
              color: value != null ? Colors.white : Colors.grey[800],
            ),
          ),
          SizedBox(width: 4.w),
          Icon(
            Icons.arrow_drop_down,
            size: 16.sp,
            color: value != null ? Colors.white : Colors.grey[800],
          ),
        ],
      ),
      selected: value != null,
      selectedColor: const Color(0xFF0E5CA8),
      backgroundColor: Colors.grey[200],
      onSelected: (_) {
        _showStaticFilterDialog(label, options, onSelected);
      },
    );
  }

  void _showStaticFilterDialog(String filterType, List<String> options, Function(String?) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $filterType'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(  // ADD THIS
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All'),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: _selectedDeliveryStatus,
                    onChanged: (value) {
                      Navigator.pop(context);
                      onSelected(value);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(null);
                  },
                ),
                ...options.map((option) => ListTile(
                  title: Text(option),
                  leading: Radio<String>(
                    value: option,
                    groupValue: _selectedDeliveryStatus,
                    onChanged: (value) {
                      Navigator.pop(context);
                      onSelected(value);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(option);
                  },
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? value,
    required List<FilterOption> options,
    required Function(String?) onSelected,
  }) {
    return FilterChip(
      label: SingleChildScrollView(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                fontSize: 12.sp,
                color: value != null ? Colors.white : Colors.grey[800],
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.arrow_drop_down,
              size: 16.sp,
              color: value != null ? Colors.white : Colors.grey[800],
            ),
          ],
        ),
      ),
      selected: value != null,
      selectedColor: const Color(0xFF0E5CA8),
      backgroundColor: Colors.grey[200],
      onSelected: (_) {
        _showFilterDialog(label, options, onSelected);
      },
    );
  }

  Widget _buildAppliedFilters(OrdersLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                if (state.searchQuery?.isNotEmpty == true)
                  _buildAppliedFilterChip('Search: ${state.searchQuery}'),
                ...state.appliedFilters.entries.map(
                      (entry) {
                    // Format the key nicely
                    final formattedKey = _formatFilterKey(entry.key);
                    return _buildAppliedFilterChip('$formattedKey: ${entry.value}');
                  },
                ),
              ],
            ),
          ),
          TextButton.icon(
            icon: Icon(Icons.clear, size: 16.sp),
            label: Text('Clear All', style: TextStyle(fontSize: 12.sp)),
            onPressed: _clearAllFilters,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44336),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            ),
          ),
        ],
      ),
    );
  }

// Add this helper method
  String _formatFilterKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildAppliedFilterChip(String label) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
      backgroundColor: const Color(0xFF0E5CA8).withOpacity(0.8),
      deleteIcon: Icon(Icons.close, size: 14.sp, color: Colors.white),
      onDeleted: () {
        _removeSingleFilter(label);
      },
    );
  }

  void _removeSingleFilter(String label) {
    if (label.startsWith('Search: ')) {
      _searchController.clear();
      context.read<OrdersBloc>().add(const SearchOrders(''));
    } else if (label.contains(': ')) {
      final parts = label.split(': ');
      final filterType = parts[0].toLowerCase();

      setState(() {
        switch (filterType) {
          case 'vehicle':
            _selectedVehicle = null;
            break;
          case 'warehouse':
            _selectedWarehouse = null;
            break;
          case 'status':
            _selectedStatus = null;
            break;
          case 'delivery status':  // Now matches the formatted key
            _selectedDeliveryStatus = null;
            break;
        }
      });

      _applyFilters();
    }
  }

  void _showFilterDialog(String filterType, List<FilterOption> options, Function(String?) onSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select $filterType'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(  // ADD THIS
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('All'),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: filterType == 'Vehicle' ? _selectedVehicle :
                    filterType == 'Warehouse' ? _selectedWarehouse : _selectedStatus,
                    onChanged: (value) {
                      Navigator.pop(context);
                      onSelected(value);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(null);
                  },
                ),
                ...options.map((option) => ListTile(
                  title: Text('${option.value} (${option.count})'),
                  leading: Radio<String>(
                    value: option.value,
                    groupValue: filterType == 'Vehicle' ? _selectedVehicle :
                    filterType == 'Warehouse' ? _selectedWarehouse : _selectedStatus,
                    onChanged: (value) {
                      Navigator.pop(context);
                      onSelected(value);
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onSelected(option.value);
                  },
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrdersLoaded state) {
    final orders = state.filteredOrders;

    if (orders.isEmpty && !state.hasFiltersApplied) {
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _selectedDeliveryStatus = null;
          });
          context.read<OrdersBloc>().add(const RefreshOrders());
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200.h,
            child: _buildEmptyState(),
          ),
        ),
      );
    } else if (orders.isEmpty && state.hasFiltersApplied) {
      return RefreshIndicator(
        onRefresh: () async {
            setState(() {
              _selectedDeliveryStatus = null; // Clear delivery status on pull refresh
            });
          context.read<OrdersBloc>().add(const RefreshOrders());
          await Future.delayed(const Duration(milliseconds: 200));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200.h,
            child: _buildNoResultsState(),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrdersBloc>().add(const RefreshOrders());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(), // ADD THIS LINE
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        itemCount: orders.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == orders.length) {
            return Container(
              padding: EdgeInsets.all(16.h),
              child: Center(
                child: state.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            );
          }
          return _buildOrderCard(orders[index]);
        },
      ),
    );
  }

  String formatUpdatedAtAbsolute(DateTime? dt) {
    if (dt == null) return 'Unknown';
    return DateFormat('MMM dd, yyyy • h:mm a').format(dt.toLocal());
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor = _getStatusColor(order.status);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<OrdersBloc>(context),
              child: OrderDetailsPage(order: order),
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.only(bottom: 8.h),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Req By: ${order.customerName}',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[1000],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                order.orderNumber,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 14.sp, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(
                        order.vehicle.isEmpty ? 'No Vehicle' : order.vehicle,  // Handle empty vehicle
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.warehouse, size: 14.sp, color: Colors.grey[600]),
                      SizedBox(width: 4.w),
                      Text(
                        order.warehouse.isEmpty ? 'No Warehouse' : order.warehouse.split(' - ').first,  // Handle empty warehouse
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Qty: ${order.totalQty}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[900],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Created: ${formatUpdatedAtAbsolute(order.creationDate)}',  // CHANGED: Show creation date
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹ ${formatIndianNumber(order.grandTotal.toInt().toString())}',
                      // '₹ ${order.grandTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'to deliver and bill':
        return const Color(0xFFF9A825); // Yellow
      case 'on hold':
        return const Color(0xFFF44336); // Red
      case 'completed':
      case 'delivered':
        return const Color(0xFF4CAF50); // Green
      case 'draft':
        return const Color(0xFF9E9E9E); // Grey
      default:
        return const Color(0xFF2196F3); // Blue
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Create a new order using the + button',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'No orders match your filters',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: _clearAllFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(OrdersError state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64.sp,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16.h),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              state.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (state.canRetry) ...[
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<OrdersBloc>().add(const RefreshOrders());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}