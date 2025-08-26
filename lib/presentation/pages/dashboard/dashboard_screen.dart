import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:lpg_distribution_app/presentation/pages/orders/forms/create_sale_order_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
import '../../../core/services/dashboard_service.dart';
import '../../../core/services/User.dart';
import '../../../core/utils/global_drawer.dart';
import '../inventory/inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _userName;
  List<String> _userRoles = [];

  // Dashboard Statistics
  final Map<String, dynamic> _dashboardStats = {
    'today_orders': 12,
    'pending_deliveries': 5,
    'total_cash_collected': 25000,
    'active_users': 45,
  };

  // Pending Approval Counts
  int _pendingInventoryApprovals = 8;
  int _pendingCashApprovals = 3;
  int _pendingOrderApprovals = 2;
  int _pendingCSETickets = 15;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    await _loadUserData();
    await _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final userName = await User().getUserName();
      final userRole = await User().getUserRoles();

      if (mounted) {
        setState(() {
          _userName = userName?.isNotEmpty == true ? userName : 'User';
          _userRoles = userRole.map((userRole) => userRole.role).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load user information');
      }
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call - replace with actual API calls
      await Future.delayed(const Duration(seconds: 1));

      // Load pending counts based on user role
      await _loadPendingCounts();

      // Load dashboard statistics
      await _loadStatistics();

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load dashboard data');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPendingCounts() async {
    // Mock data - replace with actual data from your lists/state
    if (_userRoles.contains('Warehouse Manager') || _userRoles.contains('General Manager')) {
      // Load from inventory list
      setState(() {
        _pendingInventoryApprovals = 8; // Get from your inventory list where status = 'pending'
      });
    }

    if (_userRoles.contains('Cashier') || _userRoles.contains('General Manager')) {
      // Load from cash list
      setState(() {
        _pendingCashApprovals = 3; // Get from your cash list where status = 'pending'
      });
    }

    if (_userRoles.contains('General Manager')) {
      setState(() {
        _pendingOrderApprovals = 2; // Get from your orders list where status = 'pending'
      });
    }

    if (_userRoles.contains('cse') || _userRoles.contains('General Manager')) {
      setState(() {
        _pendingCSETickets = 15; // Get from your CSE tickets
      });
    }
  }

  Future<void> _loadStatistics() async {
    // Update stats based on your actual data lists
    setState(() {
      _dashboardStats['today_orders'] = 12; // Calculate from orders list
      _dashboardStats['pending_deliveries'] = 5; // Calculate from delivery list
      _dashboardStats['total_cash_collected'] = 25000; // Calculate from cash list
      _dashboardStats['active_users'] = 45; // Get from user management
    });
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDashboardData();
      if (mounted) {
        _showSuccessSnackBar('Dashboard refreshed');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to refresh dashboard');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildDashboardBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Dashboard',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF0E5CA8),
      elevation: 0,
      actions: [
        IconButton(
          icon: _isRefreshing
              ? SizedBox(
            width: 20.w,
            height: 20.h,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.refresh, color: Colors.white),
          onPressed: _isRefreshing ? null : _refreshDashboard,
          tooltip: 'Refresh Dashboard',
        ),
        IconButton(
          icon: Stack(
            children: [
              const Icon(Icons.notifications, color: Colors.white),
              if (_getTotalPendingCount() > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2.w),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.h,
                    ),
                    child: Text(
                      _getTotalPendingCount().toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: _showNotificationsBottomSheet,
          tooltip: 'Notifications',
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E5CA8).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: const Color(0xFF0E5CA8),
              strokeWidth: 3.w,
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading dashboard...',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0E5CA8).withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: const Color(0xFF0E5CA8),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              SizedBox(height: 24.h),
              ..._buildRoleBasedContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    String greeting = _getTimeBasedGreeting();
    String userName = _userName?.split(' ').first ?? 'User';
    String roleDisplay = _formatUserRoles();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0E5CA8).withOpacity(0.1),
            const Color(0xFF0E5CA8).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF0E5CA8).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5CA8).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E5CA8).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0E5CA8).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF0E5CA8),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $userName!',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      roleDisplay,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF0E5CA8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_getTotalPendingCount() > 0) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.withOpacity(0.2),
                    Colors.orange.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: Colors.orange[800],
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    '${_getTotalPendingCount()} pending approval${_getTotalPendingCount() > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRoleBasedContent() {
    List<Widget> sections = [];

    // Delivery Boy Content
    if (_userRoles.contains('Delivery Boy')) {
      sections.add(_buildDeliveryBoySection());
      sections.add(SizedBox(height: 24.h));
    }

    // Warehouse Manager Content
    if (_userRoles.contains('Warehouse Manager')) {
      sections.add(_buildWarehouseManagerSection());
      sections.add(SizedBox(height: 24.h));
    }

    // Cashier Content
    if (_userRoles.contains('Cashier')) {
      sections.add(_buildCashierSection());
      sections.add(SizedBox(height: 24.h));
    }

    // CSE Content
    if (_userRoles.contains('cse')) {
      sections.add(_buildCSESection());
      sections.add(SizedBox(height: 24.h));
    }

    // General Manager Content
    if (_userRoles.contains('General Manager')) {
      sections.add(_buildGeneralManagerSection());
      sections.add(SizedBox(height: 24.h));
    }

    // Default content if no specific role content
    if (sections.isEmpty) {
      sections.add(_buildDefaultSection());
    }

    return sections;
  }

  Widget _buildDeliveryBoySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Quick Actions', Icons.flash_on),
        SizedBox(height: 16.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.1,
          children: [
            _buildActionCard(
              title: 'Create Order',
              subtitle: 'New sale order',
              icon: Icons.add_shopping_cart,
              color: const Color(0xFF0E5CA8),
              onTap: () => _navigateToCreateOrder(),
            ),
            _buildActionCard(
              title: 'Cash Deposit',
              subtitle: 'Deposit collections',
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              onTap: () => _navigateToCashDeposit(),
            ),
            _buildActionCard(
              title: 'Collect Items',
              subtitle: 'Pick up inventory',
              icon: Icons.add_circle_outline,
              color: Colors.orange,
              onTap: () => _navigateToInventoryCollect(),
            ),
            _buildActionCard(
              title: 'Deposit Items',
              subtitle: 'Return inventory',
              icon: Icons.remove_circle_outline,
              color: Colors.blue,
              onTap: () => _navigateToInventoryDeposit(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWarehouseManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Inventory Management', Icons.warehouse),
        SizedBox(height: 16.h),
        _buildApprovalCard(
          title: 'Inventory Approvals',
          subtitle: 'Review pending requests',
          count: _pendingInventoryApprovals,
          icon: Icons.inventory,
          color: Colors.blue,
          onTap: () => _navigateToInventoryApprovals(),
          showViewAll: true,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                title: 'Today\'s Transfers',
                value: '24',
                icon: Icons.swap_horiz,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                title: 'Low Stock Items',
                value: '5',
                icon: Icons.warning,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCashierSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Cash Management', Icons.account_balance_wallet),
        SizedBox(height: 16.h),
        _buildApprovalCard(
          title: 'Cash Approvals',
          subtitle: 'Review pending deposits',
          count: _pendingCashApprovals,
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          onTap: () => _navigateToCashApprovals(),
          showViewAll: true,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                title: 'Today\'s Cash',
                value: '₹${(_dashboardStats['total_cash_collected'] / 1000).toStringAsFixed(0)}k',
                icon: Icons.currency_rupee,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                title: 'Transactions',
                value: '18',
                icon: Icons.receipt_long,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCSESection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Customer Support', Icons.support_agent),
        SizedBox(height: 16.h),
        _buildApprovalCard(
          title: 'Open Tickets',
          subtitle: 'Customer support requests',
          count: _pendingCSETickets,
          icon: Icons.support_agent,
          color: Colors.purple,
          onTap: () => _navigateToCSETickets(),
          showViewAll: true,
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                title: 'Resolved Today',
                value: '12',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                title: 'Avg Response',
                value: '2h',
                icon: Icons.schedule,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGeneralManagerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('System Overview', Icons.dashboard),
        SizedBox(height: 16.h),

        // Quick Stats Row
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                title: 'Today\'s Orders',
                value: _dashboardStats['today_orders'].toString(),
                icon: Icons.shopping_cart,
                color: const Color(0xFF0E5CA8),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                title: 'Active Users',
                value: _dashboardStats['active_users'].toString(),
                icon: Icons.people,
                color: Colors.green,
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Approvals Overview
        _buildSectionHeader('All Approvals', Icons.approval, size: 16),
        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: _buildApprovalSummaryCard(
                title: 'Inventory',
                count: _pendingInventoryApprovals,
                color: Colors.blue,
                onTap: () => _navigateToInventoryApprovals(),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildApprovalSummaryCard(
                title: 'Cash',
                count: _pendingCashApprovals,
                color: Colors.green,
                onTap: () => _navigateToCashApprovals(),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildApprovalSummaryCard(
                title: 'Orders',
                count: _pendingOrderApprovals,
                color: Colors.orange,
                onTap: () => _navigateToOrderApprovals(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Getting Started', Icons.info),
        SizedBox(height: 16.h),
        _buildActionCard(
          title: 'View Profile',
          subtitle: 'Personal information',
          icon: Icons.person,
          color: const Color(0xFF0E5CA8),
          onTap: () => Navigator.pushNamed(context, '/profile'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {double? size}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5CA8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0E5CA8),
            size: (size ?? 20).sp,
          ),
        ),
        SizedBox(width: 12.w),
        Text(
          title,
          style: TextStyle(
            fontSize: (size ?? 18).sp,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28.sp,
                color: color,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalCard({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showViewAll = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: count > 0 ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: count > 0 ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: (count > 0 ? color : Colors.grey).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.sp,
                color: count > 0 ? color : Colors.grey,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: count > 0 ? Colors.black87 : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                if (count > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (showViewAll) ...[
                  SizedBox(height: 4.h),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12.sp,
                    color: Colors.grey[400],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
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
              Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSummaryCard({
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: count > 0 ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: count > 0 ? color : Colors.grey,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Container(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_getTotalPendingCount() > 0)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${_getTotalPendingCount()} pending',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Notifications list
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        if (_pendingInventoryApprovals > 0)
                          _buildNotificationItem(
                            'Inventory Approvals',
                            '$_pendingInventoryApprovals items need approval',
                            Icons.inventory,
                            Colors.blue,
                                () {
                              Navigator.pop(context);
                              _navigateToInventoryApprovals();
                            },
                          ),
                        if (_pendingCashApprovals > 0)
                          _buildNotificationItem(
                            'Cash Approvals',
                            '$_pendingCashApprovals deposits need approval',
                            Icons.account_balance_wallet,
                            Colors.green,
                                () {
                              Navigator.pop(context);
                              _navigateToCashApprovals();
                            },
                          ),
                        if (_pendingOrderApprovals > 0)
                          _buildNotificationItem(
                            'Order Approvals',
                            '$_pendingOrderApprovals orders need approval',
                            Icons.shopping_cart,
                            Colors.orange,
                                () {
                              Navigator.pop(context);
                              _navigateToOrderApprovals();
                            },
                          ),
                        if (_pendingCSETickets > 0)
                          _buildNotificationItem(
                            'CSE Tickets',
                            '$_pendingCSETickets tickets need attention',
                            Icons.support_agent,
                            Colors.purple,
                                () {
                              Navigator.pop(context);
                              _navigateToCSETickets();
                            },
                          ),
                        if (_getTotalPendingCount() == 0)
                          Container(
                            padding: EdgeInsets.all(32.w),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 48.sp,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  'No pending notifications',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: Colors.grey[600],
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
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationItem(
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _navigateToCreateOrder() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSaleOrderScreen()),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToCashDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CashPage(), // Navigate to cash page with deposit mode
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToInventoryCollect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryPage(), // Navigate to inventory with collect mode
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToInventoryDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryPage(), // Navigate to inventory with deposit mode
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToInventoryApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InventoryPage(), // Navigate to inventory approvals
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToCashApprovals() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CashPage(), // Navigate to cash approvals
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToOrderApprovals() {
    // Navigate to order approvals screen
    _showSuccessSnackBar('Order approvals feature coming soon');
  }

  void _navigateToCSETickets() {
    // Navigate to CSE tickets screen
    _showSuccessSnackBar('CSE tickets feature coming soon');
  }

  // Helper methods
  int _getTotalPendingCount() {
    int total = 0;

    // Add counts based on user roles
    if (_userRoles.contains('Warehouse Manager') || _userRoles.contains('General Manager')) {
      total += _pendingInventoryApprovals;
    }

    if (_userRoles.contains('Cashier') || _userRoles.contains('General Manager')) {
      total += _pendingCashApprovals;
    }

    if (_userRoles.contains('General Manager')) {
      total += _pendingOrderApprovals;
    }

    if (_userRoles.contains('cse') || _userRoles.contains('General Manager')) {
      total += _pendingCSETickets;
    }

    return total;
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatUserRoles() {
    if (_userRoles.isEmpty) return 'User';

    List<String> formattedRoles = _userRoles.map((role) {
      switch (role.toLowerCase()) {
        case 'delivery boy':
          return 'Delivery Executive';
        case 'warehouse manager':
          return 'Warehouse Manager';
        case 'general manager':
          return 'General Manager';
        case 'cse':
          return 'Customer Service Executive';
        case 'cashier':
          return 'Cashier';
        default:
          return role.split(' ').map((word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          ).join(' ');
      }
    }).toList();

    if (formattedRoles.length == 1) {
      return formattedRoles.first;
    } else if (formattedRoles.length == 2) {
      return formattedRoles.join(' & ');
    } else {
      return '${formattedRoles.first} + ${formattedRoles.length - 1} more';
    }
  }

  // Method to simulate count updates (call this when lists update)
  void updatePendingCounts({
    int? inventoryCount,
    int? cashCount,
    int? orderCount,
    int? cseCount,
  }) {
    setState(() {
      if (inventoryCount != null) _pendingInventoryApprovals = inventoryCount;
      if (cashCount != null) _pendingCashApprovals = cashCount;
      if (orderCount != null) _pendingOrderApprovals = orderCount;
      if (cseCount != null) _pendingCSETickets = cseCount;
    });
  }

  // Method to handle WebSocket updates (call this from your WebSocket listener)
  void handleWebSocketUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    try {
      // Example WebSocket data structure:
      // {
      //   "type": "approval_update",
      //   "module": "inventory", // or "cash", "orders", "cse"
      //   "count": 5,
      //   "action": "new_pending" // or "approved", "rejected"
      // }

      final String? type = data['type'];
      final String? module = data['module'];
      final int? count = data['count'];

      if (type == 'approval_update' && module != null && count != null) {
        switch (module) {
          case 'inventory':
            setState(() => _pendingInventoryApprovals = count);
            break;
          case 'cash':
            setState(() => _pendingCashApprovals = count);
            break;
          case 'orders':
            setState(() => _pendingOrderApprovals = count);
            break;
          case 'cse':
            setState(() => _pendingCSETickets = count);
            break;
        }

        // Show notification if new pending items
        if (data['action'] == 'new_pending') {
          _showSuccessSnackBar('New $module approval pending');
        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket update: $e');
    }
  }
}