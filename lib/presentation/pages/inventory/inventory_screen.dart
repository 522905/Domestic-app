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
import '../../../l10n/app_localizations.dart';
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
  final List<String> _statusTabs = ['All', 'Pending', 'Collect', 'Deposit'];
  String _currentFilter = 'All';
  String _searchQuery = '';
  List<Map<String, dynamic>> warehouses = [];
  List<Map<String, dynamic>> vehicles = [];
  // TODO remove this simply
  List<Map<String, dynamic>> warehousesItemData = [];


  List<String> _userRole = [];
  String? _userName = '';

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
          // Clear search when changing tabs
          _searchController.clear();
          _searchQuery = '';
        });
        _filterRequests(_currentFilter);
      }
    });

    // Load requests immediately
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<InventoryBloc>().add(const RefreshInventoryRequests());
        // Wait for refresh to complete, then apply current filter
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _filterRequests(_currentFilter);
        }
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed && mounted) {
      // Always refresh when app comes back to foreground
      context.read<InventoryBloc>().add(const RefreshInventoryRequests());
      // Wait for refresh to complete, then apply current filter
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        _filterRequests(_currentFilter);
      }
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
      });
    } catch (e) {
      context.showErrorSnackBar('Failed to load data: $e');
    }
  }

  void _filterRequests(String tabName) {
    if (tabName == 'All') {
      // Show all requests
      context
          .read<InventoryBloc>()
          .add(const FilterInventoryRequests(status: null));
    } else if (tabName == 'Pending') {
      // Show only pending requests (excluding TRANSFER)
      context
          .read<InventoryBloc>()
          .add(const FilterInventoryRequestsByStatusAndType(
            status: 'PENDING',
            excludeTransfer: true,
          ));
    } else if (tabName == 'Collect') {
      // Show all COLLECT requests
      context
          .read<InventoryBloc>()
          .add(const FilterInventoryRequestsByType(
            requestType: 'COLLECT',
          ));
    } else if (tabName == 'Deposit') {
      // Show all DEPOSIT requests
      context
          .read<InventoryBloc>()
          .add(const FilterInventoryRequestsByType(
            requestType: 'DEPOSIT',
          ));
    }
  }

  Future<void> _navigateToActionScreen(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
    _refreshOnFocus();
  }

  void _refreshOnFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        context.read<InventoryBloc>().add(const RefreshInventoryRequests());
        // Wait for refresh to complete, then apply current filter
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          _filterRequests(_currentFilter);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.inventoryPageTitle),
        backgroundColor: const Color(0xFF0E5CA8),
        actions: [
          IconButton(
            icon: const Icon(
                Icons.refresh,
                color: Colors.white
            ),
            onPressed: () async {
              if (!mounted) return;

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

              try {
                // Load data first
                await _loadData();

                // Refresh requests
                if (mounted) {
                  context.read<InventoryBloc>().add(const RefreshInventoryRequests());
                }

                // Wait for data to load
                await Future.delayed(const Duration(milliseconds: 600));

                // Re-apply current tab filter
                if (mounted) {
                  _filterRequests(_currentFilter);
                }

                // Close loading dialog
                await Future.delayed(const Duration(milliseconds: 100));
                if (mounted) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop();
                }
              }
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
                hintText: AppLocalizations.of(context)!.inventorySearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
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
              tabs: [
                Tab(
                  icon: Icon(Icons.list_alt, size: 20.sp),
                  text: AppLocalizations.of(context)!.dialogOptionAll,
                ),
                Tab(
                  icon: Icon(Icons.pending_actions, size: 20.sp),
                  text: AppLocalizations.of(context)!.statusPending,
                ),
                Tab(
                  icon: Icon(Icons.add_chart, size: 20.sp),
                  text: AppLocalizations.of(context)!.dashboardChallanTitle,
                ),
                Tab(
                  icon: Icon(Icons.call_received, size: 20.sp),
                  text: AppLocalizations.of(context)!.inventoryDepositMaterialRequestTitle.split(' (')[0],
                ),
              ],
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
                      // BLoC already filtered the requests based on tab selection
                      var requests = state.requests;

                      // Apply search filter on top of tab filter
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        requests = requests.where((request) {
                          return request.id.toLowerCase().contains(query) ||
                              request.warehouse.toLowerCase().contains(query) ||
                              request.requestedBy.toLowerCase().contains(query) ||
                              request.status.toLowerCase().contains(query);
                        }).toList();
                      }

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
                                AppLocalizations.of(context)!.inventoryEmptyRequests,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                AppLocalizations.of(context)!.inventoryEmptyRequests,
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
                          // Wait longer for data to load before re-applying filter
                          await Future.delayed(const Duration(milliseconds: 500));

                          // Re-apply current tab filter after refresh
                          if (mounted) {
                            _filterRequests(_currentFilter);
                          }
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
                              AppLocalizations.of(context)!.dialogFailedToLoadDataTitle,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(height: 8.h),
                            Text(state.message),
                            SizedBox(height: 24.h),
                            ElevatedButton(
                              onPressed: () => context
                                  .read<InventoryBloc>()
                                  .add(const RefreshInventoryRequests()),
                              child: Text(AppLocalizations.of(context)!.buttonTryAgain),
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
        tooltip: AppLocalizations.of(context)!.inventoryPageTitle,
      ),
    );
  }

  Widget _buildStatusSummaryCards() {
    return BlocBuilder<InventoryBloc, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final pendingCount = state.requests.where((r) => r.status == 'PENDING' && r.requestType != 'TRANSFER').length;
          final collectCount = state.requests.where((r) => r.requestType == 'COLLECT').length;
          final depositCount = state.requests.where((r) => r.requestType == 'DEPOSIT').length;

          if (state.requests.isEmpty) {
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.inventoryEmptyRequests,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            );
          }

          // Build list of count rows based on current filter/tab
          final summaryRows = <Widget>[];

          // Show only relevant stats based on active tab
          if (_currentFilter == 'All') {
            // Show all non-zero counts
            if (pendingCount > 0) {
              summaryRows.add(_buildSummaryRow(
                icon: Icons.pending_actions,
                label: AppLocalizations.of(context)!.statusPending,
                count: pendingCount,
                color: Colors.amber,
              ));
            }

            if (collectCount > 0) {
              if (summaryRows.isNotEmpty) {
                summaryRows.add(Divider(height: 16.h, color: Colors.grey[300]));
              }
              summaryRows.add(_buildSummaryRow(
                icon: Icons.call_received,
                label: AppLocalizations.of(context)!.dashboardChallanTitle,
                count: collectCount,
                color: const Color(0xFFF7941D),
              ));
            }

            if (depositCount > 0) {
              if (summaryRows.isNotEmpty) {
                summaryRows.add(Divider(height: 16.h, color: Colors.grey[300]));
              }
              summaryRows.add(_buildSummaryRow(
                icon: Icons.call_made,
                label: AppLocalizations.of(context)!.dashboardDepositItemsTitle.split(' ')[0],
                count: depositCount,
                color: const Color(0xFF0E5CA8),
              ));
            }
          } else if (_currentFilter == 'Pending') {
            // Show only Pending count
            summaryRows.add(_buildSummaryRow(
              icon: Icons.pending_actions,
              label: AppLocalizations.of(context)!.statusPending,
              count: pendingCount,
              color: Colors.amber,
            ));
          } else if (_currentFilter == 'Collect') {
            // Show only Collect count
            summaryRows.add(_buildSummaryRow(
              icon: Icons.call_received,
              label: AppLocalizations.of(context)!.dashboardChallanTitle,
              count: collectCount,
              color: const Color(0xFFF7941D),
            ));
          } else if (_currentFilter == 'Deposit') {
            // Show only Deposit count
            summaryRows.add(_buildSummaryRow(
              icon: Icons.call_made,
              label: AppLocalizations.of(context)!.dashboardDepositItemsTitle.split(' ')[0],
              count: depositCount,
              color: const Color(0xFF0E5CA8),
            ));
          }

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: summaryRows,
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _getRequestTypeColor(String requestType) {
    switch (requestType) {
      case 'COLLECT':
        return const Color(0xFFF7941D); // Orange for Collect
      case 'DEPOSIT':
        return const Color(0xFF0E5CA8); // Blue for Deposit
      case 'TRANSFER':
        return const Color(0xFF9C27B0); // Purple for Transfer
      default:
        return Colors.grey;
    }
  }

  Widget _buildInventoryRequestCard(InventoryRequest request) {
    // Debug: Check if cancel button should be visible

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
      case 'CANCELLED':
        statusColor = const Color(0xFF9E9E9E);
        break;
      default:
        statusColor = const Color(0xFF2196F3);
    }

    final dtLocal = DateTime.parse(request.timestamp).toLocal();
    return Card(
      margin: EdgeInsets.only(bottom: 5.h, top: 4.h),
      child: InkWell(
        onTap: () async {
          if (request.status.toUpperCase() == 'PENDING' &&
              _userRole.contains('Warehouse Manager')) {
            // Show unified approval screen
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(
                  requestId: request.id,
                  userRole: _userRole,
                  showApprovalButtons: true,
                ),
              ),
            );
          } else {
            // Show your existing details page
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => InventoryDetailScreen(
                  requestId: request.id,
                  userRole: _userRole,
                ),
              ),
            );
          }
          // Refresh and re-apply filter after returning from detail screen
          if (mounted) {
            context.read<InventoryBloc>().add(const RefreshInventoryRequests());
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              _filterRequests(_currentFilter);
            }
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
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.w),
                          decoration: BoxDecoration(
                            color: _getRequestTypeColor(request.requestType).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            size: 20.sp,
                            color: _getRequestTypeColor(request.requestType),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Row(
                            children: [
                              // ID Text
                              Text(
                                request.id,
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              // Inline Type Badge
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: _getRequestTypeColor(request.requestType).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: _getRequestTypeColor(request.requestType),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  request.requestType,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _getRequestTypeColor(request.requestType),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  StatusChip(
                    label: request.status,
                    color: statusColor,
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${AppLocalizations.of(context)!.inventoryRequestedBy}: ${request.requestedBy}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16.sp,
                      color: Colors.deepOrange[300],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(
                    Icons.warehouse,
                    size: 16.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${AppLocalizations.of(context)!.profileWarehouseLabel}: ${request.warehouse}',
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
                    '${AppLocalizations.of(context)!.inventoryVehicleNumber}: ${request.vehicle ?? 'N/A'}',
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
                  Row(
                    children: [
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
                                AppLocalizations.of(context)!.notificationApprovalRequired.split(' ').last,
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
                      else if (request.status == 'CANCELLED')
                        Row(
                          children: [
                            Icon(
                              Icons.cancel,
                              size: 18.sp,
                              color: Colors.grey,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              AppLocalizations.of(context)!.statusCancelled,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
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
                AppLocalizations.of(context)!.inventoryPageTitle,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_userRole.contains('Delivery Boy')) ...[
                _buildBottomSheetOption(
                  icon: Icons.inventory_2_rounded,
                  title: AppLocalizations.of(context)!.inventoryDepositUnlinkedTitle,
                  subtitle: AppLocalizations.of(context)!.inventoryDepositUnlinkedSubtitle,
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
                  title: AppLocalizations.of(context)!.inventoryDepositSaleOrderTitle,
                  subtitle: AppLocalizations.of(context)!.inventoryDepositSaleOrderSubtitle,
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
                  title: AppLocalizations.of(context)!.inventoryDepositMaterialRequestTitle,
                  subtitle: AppLocalizations.of(context)!.inventoryDepositMaterialRequestSubtitle,
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
                  title: AppLocalizations.of(context)!.inventoryCreateChallanTitle,
                  subtitle: AppLocalizations.of(context)!.inventoryCreateChallanSubtitle,
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
                  title: AppLocalizations.of(context)!.inventoryTransferTitle,
                  subtitle: AppLocalizations.of(context)!.inventoryTransferSubtitle,
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
