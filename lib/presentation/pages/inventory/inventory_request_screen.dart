import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/utils/status_chip.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/inventory/inventory_event.dart';
import '../../blocs/inventory/inventory_state.dart';
import 'collect_Inventory/collect_inventory_screen.dart';
import 'collect_Inventory/collection_request_approval_screen.dart';
import 'deposit_inventory/deposit_inventory_screen.dart';
import 'deposit_inventory/deposit_request_approval_screen.dart';
import 'inventory_request_detials_screen.dart';
import 'inventory_transfer_screen/InventoryTransferScreen.dart';

class InventoryRequestsPage extends StatefulWidget {
  final int? initialTabIndex;

  const InventoryRequestsPage({
    Key? key,
    this.initialTabIndex,
  }) : super(key: key);

  @override
  State<InventoryRequestsPage> createState() => _InventoryRequestsPageState();
}

class _InventoryRequestsPageState extends State<InventoryRequestsPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late TextEditingController _searchController;
  final List<String> _statusTabs = ['All', 'Pending', 'Approved', 'Rejected'];
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _tabController = TabController(length: _statusTabs.length, vsync: this);
    _searchController = TextEditingController();

    // Set initial tab if specified
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

    // Load data immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryBloc>().add(const LoadInventoryRequests());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes back to foreground
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

  void _filterRequests(String status) {
    if (status == 'All') {
      context.read<InventoryBloc>().add(const FilterInventoryRequests(status: null));
    } else {
      context.read<InventoryBloc>().add(FilterInventoryRequests(status: status.toUpperCase()));
    }
  }

  bool _isUserManager() {
    return true; // Change based on user role from API
  }

  // Navigate to action screens with result handling
  Future<void> _navigateToActionScreen(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // If result indicates success, refresh the list
    if (result == true || result == 'success') {
      context.read<InventoryBloc>().add(const RefreshInventoryRequests());
    }
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
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<InventoryBloc>().add(const RefreshInventoryRequests()),
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
                context.read<InventoryBloc>().add(SearchInventoryRequests(query: value));
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

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statusTabs.map((status) {
                return BlocBuilder<InventoryBloc, InventoryState>(
                  builder: (context, state) {
                    if (state is InventoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InventoryLoaded) {
                      final requests = status == 'All'
                          ? state.requests
                          : state.requests.where((r) => r.status == status.toUpperCase()).toList();

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
                                'No requests with this status',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          context.read<InventoryBloc>().add(const RefreshInventoryRequests());
                          return Future.delayed(const Duration(milliseconds: 800));
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
                    } else if (state is InventoryError) {
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
                              onPressed: () => context.read<InventoryBloc>().add(const LoadInventoryRequests()),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
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

          final pending = state.requests.where((r) => r.status == 'PENDING').length;
          final approved = state.requests.where((r) => r.status == 'APPROVED').length;
          final rejected = state.requests.where((r) => r.status == 'REJECTED').length;

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
              children: [
                _summaryCard('Pending', pending, const Color(0xFFFFC107)),
                _summaryCard('Approved', approved, const Color(0xFF4CAF50)),
                _summaryCard('Rejected', rejected, const Color(0xFFF44336)),
              ],
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
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
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

    final isCollectionRequest = request.id.startsWith('CL-');

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          if (request.status == 'PENDING') {
            if (isCollectionRequest) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CollectionApprovalScreen(
                    requestId: request.id,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DepositRequestApprovalScreen(
                    requestId: request.id,
                  ),
                ),
              );
            }
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryRequestDetailsPage(
                  requestId: request.id,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCollectionRequest ? Icons.upload : Icons.download,
                        size: 16.sp,
                        color: isCollectionRequest
                            ? const Color(0xFFF7941D)
                            : const Color(0xFF0E5CA8),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        request.id,
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
              SizedBox(height: 12.h),
              Text(
                request.warehouseName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
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
              SizedBox(height: 12.h),
              Row(
                children: [
                  _cylinderInfo('14.2kg', request.cylinders14kg),
                  SizedBox(width: 16.w),
                  _cylinderInfo('19kg', request.cylinders19kg),
                  if (request.smallCylinders > 0) ...[
                    SizedBox(width: 16.w),
                    _cylinderInfo('Small', request.smallCylinders),
                  ],
                ],
              ),
              SizedBox(height: 12.h),
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
                        request.timestamp,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (_isUserManager() && request.status == 'PENDING')
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
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
                  else
                    FavoriteButton(
                      requestId: request.id,
                      initialValue: request.isFavorite,
                      onToggle: (value) {
                        context.read<InventoryBloc>().add(ToggleFavoriteRequest(
                          requestId: request.id,
                          isFavorite: value,
                        ));
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cylinderInfo(String type, int count) {
    return Row(
      children: [
        Icon(
          Icons.local_fire_department,
          size: 16.sp,
          color: const Color(0xFFF7941D),
        ),
        SizedBox(width: 4.w),
        Text(
          '$type: $count',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              _buildBottomSheetOption(
                icon: Icons.inventory,
                title: 'Collect Inventory',
                subtitle: 'Collect items from warehouse',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToActionScreen(const CollectInventoryScreen());
                },
              ),
              _buildBottomSheetOption(
                icon: Icons.inventory_2_rounded,
                title: 'Deposit Inventory',
                subtitle: 'Deposit items for warehouse',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToActionScreen(const DepositInventoryScreen());
                },
              ),
              _buildBottomSheetOption(
                icon: Icons.transfer_within_a_station,
                title: 'Inventory Transfer',
                subtitle: 'Transfer items to another warehouse',
                onTap: () {
                  Navigator.pop(context);
                  _navigateToActionScreen(const InventoryTransferScreen());
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
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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

class FavoriteButton extends StatefulWidget {
  final String requestId;
  final bool initialValue;
  final Function(bool) onToggle;

  const FavoriteButton({
    Key? key,
    required this.requestId,
    required this.initialValue,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isFavorite ? Icons.star : Icons.star_border,
        color: _isFavorite ? const Color(0xFFF7941D) : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          _isFavorite = !_isFavorite;
        });
        widget.onToggle(_isFavorite);
      },
    );
  }
}