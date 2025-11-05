import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../core/models/deposit/deposit_data.dart';
import '../../../core/services/User.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/inventory/inventory_event.dart';
import '../../blocs/inventory/inventory_state.dart';
import 'Inventory_detail_screen.dart';
import 'forms/collect_inventory_request_screen.dart';
import 'forms/deposit_inventory_request_screen.dart';
import 'forms/transfer_inventory_request_screen.dart';
import '../../widgets/professional_snackbar.dart';

class InventoryPage extends StatefulWidget {
  final int? initialTabIndex;

  const InventoryPage({
    Key? key,
    this.initialTabIndex,
  }) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late TextEditingController _searchController;
  final List<String> _statusTabs = ['All', 'Pending', 'Approved', 'Rejected'];
  String _currentFilter = 'All';
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> vehicles = [];
  // TODO remove this simply
  List<Map<String, dynamic>> warehousesItemData = [];


  List<String> _userRole = [];
  String? _userName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _searchController = TextEditingController();

    if (widget.initialTabIndex != null &&
        widget.initialTabIndex! < _statusTabs.length) {
      _tabController.index = widget.initialTabIndex!;
      _currentFilter = _statusTabs[widget.initialTabIndex!];
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentFilter = _statusTabs[_tabController.index];
        });
        _filterRequests(_currentFilter);
      }
    });

    // Load requests immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryBloc>().add(const RefreshInventoryRequests());
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Always refresh when app comes back to foreground
      context.read<InventoryBloc>().add(const RefreshInventoryRequests());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final apiService = context.read<InventoryBloc>().apiService;
      var _warehouses = await apiService.getWarehouses();
      final userRole = await User().getUserRoles();
      var userName = await User().getUserName();

      setState(() {
        warehouses = List<Map<String, dynamic>>.from(_warehouses);
        _userRole = userRole.map((userRole) => userRole.role).toList();
        _userName = userName;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _filterRequests(String status) {
    if (status == 'All') {
      context
          .read<InventoryBloc>()
          .add(const FilterInventoryRequests(status: null));
    } else {
      context
          .read<InventoryBloc>()
          .add(FilterInventoryRequests(status: status.toUpperCase()));
    }
  }

  Future<void> _navigateToActionScreen(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _refreshOnFocus();
  }

  void _refreshOnFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryBloc>().add(const RefreshInventoryRequests());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: const Text('Inventory'),
        backgroundColor: const Color(0xFF0E5CA8),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh,
                color: Colors.white
            ),
            onPressed: () {
              _loadData().then((_) {
                if (mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.of(context).pop(); // Close the dialog after 1 second
                    context.read<InventoryBloc>().add(const RefreshInventoryRequests());
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status summary cards
          _buildStatusSummaryCards(),
          // Search bar
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Requests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (value) {
                context
                    .read<InventoryBloc>()
                    .add(SearchInventoryRequests(query: value));
              },
            ),
          ),
          // Tab controller
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              indicatorWeight: 3,
              tabs: _statusTabs.map((status) => Tab(text: status)).toList(),
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusTabs.map((status) {
                return BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    // Handle loading state
                    if (state is InventoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Handle loaded state
                    else if (state is InventoryLoaded) {
                      // Filter by status
                      final requests = status == 'All'
                          ? state.requests
                          : state.requests
                          .where((r) => r.status == status.toUpperCase())
                          .toList();

                      if (requests.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 64.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No $status requests found',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                status == 'All'
                                    ? 'No requests available'
                                    : 'No $status requests found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context
                              .read<InventoryBloc>()
                              .add(const RefreshInventoryRequests());
                          return Future.delayed(const Duration(milliseconds: 200));
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final request = requests[index];
                            return _buildInventoryRequestCard(request);
                          },
                        ),
                      );
                    }

                    // Handle error state
                    else if (state is InventoryError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64.sp,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Failed to load requests',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8.h),
                            Text(state.message),
                            SizedBox(height: 24.h),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<InventoryBloc>()
                                  .add(const RefreshInventoryRequests()),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Handle detail states (when coming back from approval screen)
                    else if (state is InventoryDetailLoaded || state is InventoryDetailLoading || state is InventoryDetailError) {
                      // If we're in a detail state but on the list screen, reload the list
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          context.read<InventoryBloc>().add(const RefreshInventoryRequests());
                        }
                      });
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Default loading state
                    return const Center(child: CircularProgressIndicator());
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'createInventoryRequest',
        onPressed: _showInventoryOptionsBottomSheet,
        backgroundColor: const Color(0xFF0E5CA8),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Inventory Options',
      ),
    );
  }

  Widget _buildStatusSummaryCards() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final statusCounts = {
            'PENDING':
                state.requests.where((r) => r.status == 'PENDING').length,
            'APPROVED':
                state.requests.where((r) => r.status == 'APPROVED').length,
            'REJECTED':
                state.requests.where((r) => r.status == 'REJECTED').length,
          };

          // Filter statuses with non-zero counts
          final filteredStatuses =
              statusCounts.entries.where((entry) => entry.value > 0).toList();

          if (state.requests.isEmpty) {
            return Container(
              padding: EdgeInsets.all(16.w),
              child: Center(
                child: Text(
                  'No requests found',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }
          return Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: filteredStatuses.map((status) {
                return _summaryCard(
                  status.key,
                  status.value,
                  status.key == 'PENDING'
                      ? const Color(0xFFFFC107)
                      : status.key == 'APPROVED'
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF44336),
                );
              }).toList(),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Container(
      width: 100.w,
      padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              color: color,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryRequestCard(InventoryRequest request) {
    Color statusColor;
    switch (request.status) {
      case 'PENDING':
        statusColor = const Color(0xFFFFC107);
        break;
      case 'APPROVED':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFF44336);
        break;
      default:
        statusColor = const Color(0xFF2196F3);
    }

    final isCollectionRequest = request.requestType == 'COLLECT';
    final isDepositRequest = request.requestType == 'DEPOSIT';
    final isTransferRequest = request.requestType == 'TRANSFER';

    final dtLocal = DateTime.parse(request.timestamp).toLocal();
    return Card(
      margin: EdgeInsets.only(bottom: 5.h, top: 4.h),
      child: InkWell(
        onTap: () {
          if (request.status.toUpperCase() == 'PENDING' &&
              _userRole.contains('Warehouse Manager')) {
            // Show unified approval screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(
                  requestId: request.id,
                  userRole: _userRole,
                  showApprovalButtons: true,
                ),
              ),
            );
            if (mounted) {
              context.read<InventoryBloc>().add(const RefreshInventoryRequests());
            }
          } else {
            // Show your existing details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(
                  requestId: request.id,
                  userRole: _userRole,
                ),
              ),
            );
          }
          if (mounted) {
            context.read<InventoryBloc>().add(const RefreshInventoryRequests());
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 16.sp,
                        color: isCollectionRequest
                            ? const Color(0xFFF7941D)
                            : const Color(0xFF0E5CA8),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "${request.id} - {${request.requestType}}",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(
                    label: request.status,
                    color: statusColor,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.warehouse,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Warehouse: ${request.warehouse}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Requested by: ${request.requestedBy}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.fire_truck,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Vehicle Number: ${request.vehicle}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                          Text(
                              DateFormat('dd-MM-yyyy hh:mm').format(dtLocal),
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        )
                    ],
                  ),
                  if (request.status == 'PENDING')
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.priority_high,
                            size: 12.sp,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'Needs Approval',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (request.status == 'APPROVED')
                    Icon(
                      Icons.check_circle,
                      size: 20.sp,
                      color: Colors.green,
                    )
                  else
                    Icon(
                      Icons.cancel,
                      size: 20.sp,
                      color: Colors.red,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInventoryOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 2.h,
                margin: EdgeInsets.only(bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Inventory Options',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_userRole.contains('Delivery Boy')) ...[
                _buildBottomSheetOption(
                  icon: Icons.inventory_2_rounded,
                  title: 'Deposit Inventory (Unlinked)',
                  subtitle: 'Deposit items for warehouse',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToActionScreen(
                      const DepositInventoryScreen(
                        depositType: DepositData.unlinked,
                      ),
                    );
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.receipt_long,
                  title: 'Deposit Inventory (Sale Order)',
                  subtitle: 'Deposit items against sale orders',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToActionScreen(
                      const DepositInventoryScreen(
                        depositType: DepositData.salesOrder,
                      ),
                    );
                  },
                ),
                _buildBottomSheetOption(
                  icon: Icons.assignment,
                  title: 'Deposit Inventory (Material Request)',
                  subtitle: 'Deposit items against material requests',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToActionScreen(
                      const DepositInventoryScreen(
                        depositType: DepositData.materialRequest,
                      ),
                    );
                  },
                ),
              ],
              if (_userRole.contains('Delivery Boy'))
                _buildBottomSheetOption(
                  icon: Icons.inventory,
                  title: 'Create Challan',
                  subtitle: 'Create a inventory challan',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToActionScreen(
                      const CollectInventoryScreen(),
                    );
                  },
                ),
              if (_userRole.contains('Warehouse Manager'))
                _buildBottomSheetOption(
                  icon: Icons.transfer_within_a_station,
                  title: 'Inventory Transfer',
                  subtitle: 'Transfer items to another warehouse',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToActionScreen(
                      InventoryTransferScreen(
                        warehouses: warehouses,
                        warehousesItemList: warehousesItemData,
                        userName: _userName,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: const Color(0xFF0E5CA8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF0E5CA8),
          size: 24.sp,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
      onTap: onTap,
    );
  }

}
