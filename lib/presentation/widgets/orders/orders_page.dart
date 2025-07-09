import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/services/token_manager.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/orders/orders_bloc.dart';
import '../../../domain/entities/order.dart';
import '../../pages/orders/create_order_page.dart';
import '../../pages/orders/order_details_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<String>? userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Initial load of pending orders
    context.read<OrdersBloc>().add(const LoadOrders(statusFilter: 'Pending'));
  }

  Future<void> _loadUserRole() async {
    final roles = await TokenManager().getUserRole();
    setState(() {
      userRole = roles;
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      final String statusFilter = _tabController.index == 0 ? 'Pending' : 'Completed';
      context.read<OrdersBloc>().add(LoadOrders(statusFilter: statusFilter));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:GlobalDrawer.getDrawer(context),
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
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {
              // Navigation or action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0E5CA8),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFF7941D),
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Completed'),
              ],
            ),
          ),

          // Search Bar and Filter section
          _buildSearchAndFilterSection(),

          // Orders List with TabBarView for swiping
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const AlwaysScrollableScrollPhysics(), // Enable swipe navigation
              children: [
                // Pending Orders Tab
                _buildOrdersTab(),

                // Completed Orders Tab
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
      // In the OrdersPage where you navigate to CreateOrderPage:
      floatingActionButton: FloatingActionButton(
        heroTag: 'order_page_screen',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<OrdersBloc>(context),
                child: const CreateOrderPage(),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF0E5CA8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search orders...',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: 16.sp,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12.h),
            ),
            onChanged: (value) {
              context.read<OrdersBloc>().add(FilterOrders(searchQuery: value));
            },
          ),
        ),

        // Filter Buttons
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                if (!(userRole?.contains('delivery-boy') ?? false)) ...[
                  _buildFilterButton('Date', Icons.arrow_drop_down),
                  SizedBox(width: 8.w),
                  _buildFilterButton('Type', Icons.arrow_drop_down),
                  SizedBox(width: 8.w),
                  _buildFilterButton('Status', Icons.arrow_drop_down),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        if (state is OrdersInitial || state is OrdersLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is OrdersLoaded) {
          return state.orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
              onRefresh: () async {
                final statusFilter = _tabController.index == 0 ? 'Pending' : 'Completed';

                context.read<OrdersBloc>().add(LoadOrders(statusFilter: statusFilter));
              },
              child: _buildOrdersList(state.orders),
            );
          } else if (state is OrdersError) {
            return Center(
              child: Text(
                'Error: ${state.message}',
                style: TextStyle(
                  color: const Color(0xFFF44336),
                  fontSize: 16.sp,
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
      },
    );
  }

  Widget _buildFilterButton(String label, IconData icon) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          // Show filter options
          _showFilterDialog(label);
        },
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          side: const BorderSide(color: Colors.grey),
          padding: EdgeInsets.symmetric(vertical: 12.h),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14.sp,
              ),
            ),
            Icon(icon, color: Colors.grey[800], size: 20.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    // Format date
    String formattedDate;
    final now = DateTime.now();
    final orderDate = order.createdAt;

    if (orderDate.year == now.year &&
        orderDate.month == now.month &&
        orderDate.day == now.day) {
      formattedDate = 'Today, ${DateFormat('h:mm a').format(orderDate)}';
    } else if (orderDate.year == now.year &&
        orderDate.month == now.month &&
        orderDate.day == now.day - 1) {
      formattedDate = 'Yesterday, ${DateFormat('h:mm a').format(orderDate)}';
    } else {
      formattedDate = DateFormat('MMM d, h:mm a').format(orderDate);
    }

    // Get order items description
    String itemsDescription = order.items.map((item) {
      return '${item.name} × ${item.quantity}';
    }).join(',  \n');

    // Status color mapping
    Color statusColor;
    switch (order.status) {
      case 'Pending':
        statusColor = const Color(0xFFFFC107);
        break;
      case 'Processing':
        statusColor = const Color(0xFF2196F3);
        break;
      case 'Completed':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'Rejected':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        // Navigate to order details page when card is tapped
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
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[1000],
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
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                itemsDescription,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd-MM-yyyy').format(order.createdAt),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.grandTotal,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14.sp,
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

  void _showFilterDialog(String filterType) {
    List<String> options = [];

    switch (filterType) {
      case 'Date':
        options = ['Today', 'Yesterday', 'Last 7 days', 'Last 30 days', 'Custom range'];
        break;
      case 'Type':
        options = ['Refill', 'NFR', 'SV', 'TV'];
        break;
      case 'Status':
        options = ['Pending', 'Processing', 'Completed', 'Rejected'];
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by $filterType'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(options[index]),
                onTap: () {
                  Navigator.pop(context);

                  // Apply the selected filter
                  switch (filterType) {
                    case 'Date':
                      context.read<OrdersBloc>().add(FilterOrders(dateFilter: options[index]));
                      break;
                    case 'Type':
                      context.read<OrdersBloc>().add(FilterOrders(typeFilter: options[index]));
                      break;
                    case 'Status':
                      context.read<OrdersBloc>().add(FilterOrders(statusFilter: options[index]));
                      break;
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // Clear this filter
              switch (filterType) {
                case 'Date':
                  context.read<OrdersBloc>().add(const FilterOrders(dateFilter: ''));
                  break;
                case 'Type':
                  context.read<OrdersBloc>().add(const FilterOrders(typeFilter: ''));
                  break;
                case 'Status':
                // For status, we need to respect the tab selection
                  final statusFilter = _tabController.index == 0 ? 'Pending' : 'Completed';
                  context.read<OrdersBloc>().add(FilterOrders(statusFilter: statusFilter));
                  break;
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

}