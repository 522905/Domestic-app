import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/presentation/pages/dashboard/transfer_details_screen.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/utils/global_drawer.dart';
import '../../widgets/dashboard/approval_card.dart';
import '../../widgets/dashboard/inventory_action_card.dart';
import '../../widgets/dashboard/quick_action_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin  {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  Map<String, dynamic> _userData = {};
  String _userRole = '';
  String _selectedTab = 'All';
  List<String> _tabs = ['All'];
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    if (!_isInitialized) {
      _isInitialized = true;
      _refreshDashboardData();
    };
    _loadDashboardAndInitTabs();
  }

  Future<void> _loadDashboardAndInitTabs() async {
    await _refreshDashboardData();

    // Add null check for user role
    final userRole = MockData.userData['role'] ?? '';

    final List<String> roleTabs = ['All'];

    switch (userRole) {
      case 'delivery_boy':
        roleTabs.addAll(['Driver']);
        break;
      case 'cse':
        roleTabs.addAll(['CSE']);
        break;
      case 'cashier':
        roleTabs.addAll(['Cashier']);
        break;
      case 'warehouse_manager':
        roleTabs.addAll(['Manager']);
        break;
      case 'general_manager':
        roleTabs.addAll(['Manager', 'Cashier', 'CSE']);
        break;
    }

    if (mounted) {
      setState(() {
        _userRole = userRole;
        _tabs = roleTabs;
        _tabController = TabController(length: roleTabs.length, vsync: this);
        _tabController.addListener(() {
          if (!_tabController.indexIsChanging) {
            setState(() {
              _selectedTab = roleTabs[_tabController.index];
            });
          }
        });
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DashboardService().refreshDashboardData();
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      // Optionally show an error message to the user
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Notification action
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: _isLoading
              ? Container(height: 48.h)
              : TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                  tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshDashboardData,
              child:_isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                  controller: _tabController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: _tabs.map((tab) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          SizedBox(height: 16.h),
                          _buildTabContent(tab),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ),
      );
    }

  Widget _buildTabContent(String tab) {
    // Make sure tab is not null
    if (tab == null) {
      return const SizedBox.shrink();  // Return empty widget
    }

    switch (tab) {
      case 'All':
        return _buildAllTabContent();
      case 'Driver':
        return _buildDriverTabContent();
      case 'CSE':
        return _buildCSETabContent();
      case 'Cashier':
        return _buildCashierTabContent();
      case 'Manager':
        return _buildManagerTabContent();
      default:
        return const SizedBox.shrink();  // Return empty widget for unknown tabs
    }
  }

  Widget _buildWelcomeSection() {
    // Get role title from mock data
    String roleTitle = MockData.roleDisplayNames[_userRole] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, ${_userData['name']?.split(' ').first ?? 'User'}',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          roleTitle,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildAllTabContent() {
    if (_userRole == 'warehouse_manager') {
      final stockItems = MockData.stockItems['warehouse_manager'] ?? [];
      final approvalItems = MockData.approvalItems['warehouse_manager'] ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Inventory Management',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: InventoryActionCard(
                  title: 'Collect',
                  icon: Icons.add_circle_outline,
                  iconColor: Colors.green,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  pendingCount: MockData.pendingCounts['collect'] ?? 0,
                  onTap: () {
                    // Navigate to collect screen
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: InventoryActionCard(
                  title: 'Deposit',
                  icon: Icons.arrow_downward,
                  iconColor: Colors.blue,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  pendingCount: MockData.pendingCounts['deposit'] ?? 0,
                  onTap: () {
                    // Navigate to deposit screen
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Stock Status - ${MockData.warehouseName}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          StockStatusCard(
            items: stockItems,
          ),
          SizedBox(height: 16.h),
          Text(
            'Pending Approvals',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          ...approvalItems
              .map((approval) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      // In your InkWell onTap in dashboard_screen.dart
                      onTap: () async {
                        if (approval['type'] == ApprovalType.transfer) {
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransferDetailsScreen(
                                transferId: approval['id'],
                                warehouseFrom: approval['warehouseFrom'] ??
                                    'Warehouse 1 (Ludhiana Central)',
                                warehouseTo: approval['warehouseTo'] ??
                                    'Warehouse 2 (Ludhiana North)',
                                itemDetails: approval['itemDetails'] ??
                                    '10 Filled Cylinders',
                                gatepassNo:
                                    'WH1-TR-${DateTime.now().year}${approval['id'].substring(approval['id'].length > 4 ? approval['id'].length - 4 : 0)}',
                                status: approval['status'] ?? 'Pending',
                              ),
                            ),
                          );

                          // If transfer was approved, refresh the dashboard
                          if (result == true) {
                            setState(() {
                              // This will rebuild the UI with updated data
                            });
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Coming soon...')),
                          );
                        }
                      },
                      child: ApprovalCard(
                        type: approval['type'],
                        id: approval['id'] ?? '', // Add null check
                        details: approval['details'] ?? '', // Add null check
                        time: approval['time'] ?? '', // Add null check
                        status: approval['status'] ?? 'Pending', // Add null check
                        onApprove: () {},
                        onReject: () {},
                      ),
                    ),
                  ))
              .toList()
        ],
      );
    } else if (_userRole == 'general_manager') {
      final statusSummaries = MockData.statusSummaries['general_manager'] ?? [];
      final approvalItems = MockData.approvalItems['general_manager'] ?? [];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'At a Glance',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: statusSummaries
                .map((summary) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: summary == statusSummaries.last ? 0 : 12.w),
                        child: StatusSummaryCard(
                          title: summary['title'],
                          count: summary['count'],
                          icon: summary['icon'],
                          iconColor: summary['iconColor'],
                          backgroundColor: summary['backgroundColor'],
                          trend: summary['trend'],
                          trendUp: summary['trendUp'],
                          critical: summary['critical'] ?? false,
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 16.h),
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: MockData.quickActions
                .map((action) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: action == MockData.quickActions.last
                              ? 0
                              : 12.w),
                      child: QuickActionCard(
                        title: action['title'],
                        icon: action['icon'],
                        iconColor: action['iconColor'],
                        backgroundColor: action['backgroundColor'],
                        onTap: () {
                          // Navigate based on action type
                        },
                      ),
                    ),
                  ))
                .toList(),
          ),
          SizedBox(height: 16.h),
          Text(
            'Pending Approvals',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          ...approvalItems
              .map((approval) => Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      onTap: () {
                        if (approval['type'] == ApprovalType.transfer) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => TransferDetailsScreen(
                                transferId: approval['id'],
                                warehouseFrom: approval['warehouseFrom'] ??
                                    'Warehouse 1 (Ludhiana Central)',
                                warehouseTo: approval['warehouseTo'] ??
                                    'Warehouse 2 (Ludhiana North)',
                                itemDetails: approval['itemDetails'] ??
                                    '10 Filled Cylinders',
                                gatepassNo:
                                    'WH1-TR-${DateTime.now().year}${approval['id'].substring(approval['id'].length > 4 ? approval['id'].length - 4 : 0)}',
                              status: approval['status'] ?? 'Pending',
                              ),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Coming soon...')),
                          );
                        }
                      },
                      child: ApprovalCard(
                        type: approval['type'],
                        id: approval['id'] ?? '', // Add null check
                        details: approval['details'] ?? '', // Add null check
                        time: approval['time'] ?? '', // Add null check
                        status: approval['status'] ?? 'Pending', // Add null check
                        onApprove: () {},
                        onReject: () {},
                      ),
                    ),
                  ))
              .toList()
        ],
      );
    } else {
      // Default view for other roles
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: Text(
                MockData.welcomeMessage,
                style: TextStyle(fontSize: 14.sp),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDriverTabContent() {
    final deliveries = MockData.deliveries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Deliveries',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: deliveries.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final delivery = deliveries[index];
              return ListTile(
                title: Text(
                  delivery['title'],
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  delivery['subtitle'],
                  style: TextStyle(fontSize: 12.sp),
                ),
                trailing: Chip(
                  label: Text(
                    delivery['status'],
                    style: TextStyle(
                        fontSize: 12.sp, color: delivery['statusColor']),
                  ),
                  backgroundColor: delivery['statusColor'].withOpacity(0.1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCashierTabContent() {
    final cashData = MockData.cashierData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Transactions',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Collection',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Text(
                      cashData['collection']!,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Refunds',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    Text(
                      cashData['refunds']!,
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                const Divider(),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      cashData['balance']!,
                      style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0E5CA8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildManagerTabContent() {
    final stockItems = MockData.stockItems['warehouse_manager'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inventory Overview',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        StockStatusCard(
          items: stockItems,
        ),
      ],
    );
  }

  Widget _buildCSETabContent() {
    final customerOrders = MockData.customerOrders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Orders',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12.h),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customerOrders.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final order = customerOrders[index];
              return ListTile(
                title: Text(
                  order['customer'],
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Type: ${order['type']}',
                  style: TextStyle(fontSize: 12.sp),
                ),
                trailing: Chip(
                  label: Text(
                    order['status'],
                    style:
                        TextStyle(fontSize: 12.sp, color: order['statusColor']),
                  ),
                  backgroundColor: order['statusColor'].withOpacity(0.1),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}