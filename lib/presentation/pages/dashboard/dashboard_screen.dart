import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpg_distribution_app/presentation/pages/orders/forms/create_sale_order_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/utils/global_drawer.dart';
import '../../widgets/notification/inbox.dart';
import '../../widgets/warehouse_stock_card_screen.dart';
import '../../widgets/dashboard/quota_dashboard_widget.dart';
import '../../widgets/professional_snackbar.dart';
import '../cash/forms/cash_deposit_page.dart';
import '../inventory/forms/collect_inventory_request_screen.dart';
import '../inventory/forms/deposit_inventory_request_screen.dart';
import '../inventory/inventory_screen.dart';
import '../purchase_invoice/purchase_invoice_screen.dart';
import '../credit_extension/gm_pending_approvals_page.dart';
import '../orders/orders_page.dart';
import 'package:lpg_distribution_app/l10n/app_localizations.dart';
import 'package:lpg_distribution_app/l10n/l10n_extensions.dart';

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
  UserCompany? activeCompany;
  String? novuAppId;
  String? novuSubscriberId;
  String? _photoUrl;

  // Dashboard Statistics
  final Map<String, dynamic> _dashboardStats = {
    'today_orders': 12,
    'pending_deliveries': 5,
    'total_cash_collected': 25000,
    'active_users': 45,
  };

  // Pending Approval Counts
  int _pendingInventoryApprovals = 0;
  int _pendingCashApprovals = 0;  // Changed from 3 to 0 (will show actual count)
  int _pendingOrderApprovals = 0;  // Changed from 2 to 0 (will show actual count)
  int _pendingCSETickets = 15;
  int _pendingCreditExtensions = 0;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
    loadNovuData();
  }

  Future<void> _initializeDashboard() async {
    await _loadUserData();
    await _loadDashboardData();
  }

  Future<void> _loadUserData() async {
    try {
      final userName = await User().getUserName();
      final userRole = await User().getUserRoles();
      final _activeCompany = await User().getActiveCompany();
      final photoUrl = await User().getPhotoUrl();

      if (mounted) {
        setState(() {
          _userName = userName?.isNotEmpty == true ? userName : null;
          _userRoles = userRole.map((userRole) => userRole.role).toList();
          activeCompany = _activeCompany;
          _photoUrl = photoUrl;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('dashboardUserLoadFailure'));
      }
    }
  }

  Future<void> loadNovuData() async {
    final appId = await User().getNovuApplicationIdentifier();
    final subscriberId = await User().getNovuSubscriberId();

    setState(() {
      novuAppId = appId;
      novuSubscriberId = subscriberId;
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call - replace with actual API calls
      await Future.delayed(const Duration(seconds: 1));

      // Load dashboard statistics
      await _loadStatistics();

    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('dashboardDataLoadFailure'));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    // Fetch credit extension pending count for GM
    if (_userRoles.contains('General Manager')) {
      try {
        final apiService = context.read<ApiServiceInterface>();
        final response = await apiService.getPendingCreditExtensions();
        final count = (response['results'] as List?)?.length ?? 0;
        if (mounted) {
          setState(() {
            _pendingCreditExtensions = count;
          });
        }
      } catch (e) {
        debugPrint('Error loading credit extension count: $e');
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      await _loadDashboardData();
      if (mounted) {
        _showSuccessSnackBar(context.l10n.translate('dashboardRefreshSuccess'));
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(context.l10n.translate('dashboardRefreshFailure'));
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
    if (!mounted) return;
    context.showErrorSnackBar(
      message,
      duration: const Duration(seconds: 3),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    context.showSuccessSnackBar(
      message,
      duration: const Duration(seconds: 3),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    context.showWarningSnackBar(
      message,
      duration: const Duration(seconds: 3),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    context.showInfoSnackBar(
      message,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context, userRoles: _userRoles.toSet()),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingWidget() : _buildDashboardBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        context.l10n.translate('dashboardTitle'),
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
          tooltip: context.l10n.translate('dashboardRefreshTooltip'),
        ),
        Inbox(),
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
              context.l10n.translate('dashboardLoadingLabel'),
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
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuotaDashboardWidget(
                greetingLine: _buildGreetingLine(context),
                roleLine: _buildRoleLine(context),
                pendingCount: _getTotalPendingCount(),
                pendingLabel: _pendingApprovalLabel(context),
                photoUrl: _photoUrl,
                userName: _userName,
              ),
              SizedBox(height: 16.h),
              ..._buildRoleBasedContent(),
            ],
          ),
        ),
      ),
    );
  }

  String _buildGreetingLine(BuildContext context) {
    final String greeting = _getTimeBasedGreeting(context);
    final String fallbackName = context.l10n.translate('dashboardUserFallback');
    final String userName = _userName?.split(' ').first ?? fallbackName;
    return context.l10n.translate(
      'dashboardGreetingMessage',
      params: [greeting, userName],
    );
  }

  String _buildRoleLine(BuildContext context) {
    final String roleDisplay = _formatUserRoles(context);
    final String? companyCode = activeCompany?.shortCode;
    return companyCode != null
        ? context.l10n.translate(
            'dashboardRoleWithCompany',
            params: [roleDisplay, companyCode],
          )
        : roleDisplay;
  }

  List<Widget> _buildRoleBasedContent() {
    List<Widget> sections = [];

    // Delivery Boy Content
    if (_userRoles.contains('Delivery Boy')) {
      sections.add(_buildDeliveryBoySection());
      sections.add(SizedBox(height: 8.h));
    }

    // Cashier Content
    if (_userRoles.contains('Cashier')) {
      sections.add(_buildCashierSection());
      sections.add(SizedBox(height: 8.h));
    }

    // Warehouse Manager Content
    if (_userRoles.contains('Warehouse Manager')) {
      sections.add(_buildWarehouseManagerSection());
      sections.add(SizedBox(height: 16.h));
    }

    // CSE Content
    if (_userRoles.contains('cse')) {
      sections.add(_buildCSESection());
      sections.add(SizedBox(height: 16.h));
    }

    // General Manager Content
    if (_userRoles.contains('General Manager')) {
      sections.add(_buildGeneralManagerSection());
      sections.add(SizedBox(height: 16.h));
    }

    // Default content if no specific role content
    if (sections.isEmpty) {
      sections.add(_buildDefaultSection());
    }

    return sections;
  }

  Widget _buildDeliveryBoySection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.translate('dashboardQuickActionsTitle'), Icons.flash_on),
        SizedBox(height: 12.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8.w,
          mainAxisSpacing: 8.h,
          childAspectRatio: 1.3,
          children: [
            _buildActionCard(
              title: l10n.translate('dashboardCreateOrderTitle'),
              subtitle: l10n.translate('dashboardCreateOrderSubtitle'),
              icon: Icons.add_shopping_cart,
              color: const Color(0xFF0E5CA8),
              onTap: () => _navigateToCreateOrder(),
            ),
            _buildActionCard(
              title: l10n.translate('dashboardDepositItemsTitle'),
              subtitle: l10n.translate('dashboardDepositItemsSubtitle'),
              icon: Icons.remove_circle_outline,
              color: Colors.blue,
              onTap: () => _navigateToInventoryDeposit(),
            ),
            _buildActionCard(
              title: l10n.translate('dashboardCashDepositTitle'),
              subtitle: l10n.translate('dashboardCashDepositSubtitle'),
              icon: Icons.account_balance_wallet,
              color: Colors.green,
              onTap: () => _navigateToCashDeposit(),
            ),
            _buildActionCard(
              title: l10n.translate('dashboardChallanTitle'),
              subtitle: l10n.translate('dashboardChallanSubtitle'),
              icon: Icons.add_circle_outline,
              color: Colors.orange,
              onTap: () => _navigateToInventoryCollect(),
            ),
            _buildActionCard(
              title: 'SDMS Claims',
              subtitle: 'Manage order claims',
              icon: Icons.receipt_long,
              color: const Color(0xFF6C63FF),
              onTap: () => _navigateToSdmsClaims(),
            ),
            _buildActionCard(
              title: 'My Performance',
              subtitle: 'Track quota & bonuses',
              icon: Icons.trending_up,
              color: const Color(0xFF2ECC71),
              onTap: () => _navigateToQuotaStatus(),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        // Warehouse stock card
        const WarehouseStockCard(),
      ],
    );
  }

  Widget _buildWarehouseManagerSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.translate('dashboardInventoryManagementTitle'), Icons.warehouse),
        SizedBox(height: 12.h),
        _buildApprovalCard(
          title: l10n.translate('dashboardProcurementTitle'),
          subtitle: l10n.translate('dashboardProcurementSubtitle'),
          count: _pendingInventoryApprovals,
          icon: Icons.add,
          color: Colors.orangeAccent,
          onTap: () {
            Navigator.push(
              GlobalDrawer.navigatorContext!,
              MaterialPageRoute(builder: (context) => const PurchaseInvoiceScreen()),
            );
          },
          showViewAll: true,
        ),
        SizedBox(height: 10.h),
        _buildApprovalCard(
          title: l10n.translate('dashboardInventoryApprovalsTitle'),
          subtitle: l10n.translate('dashboardInventoryApprovalsSubtitle'),
          count: _pendingInventoryApprovals,
          icon: Icons.inventory,
          color: Colors.blue,
          onTap: () => _navigateToInventoryApprovals(),
          showViewAll: true,
        ),
        SizedBox(height: 10.h),
        _buildApprovalCard(
          title: 'Defect Inspection',
          subtitle: 'Manage defective cylinder reports',
          count: 0,
          icon: Icons.error_outline,
          color: Colors.red,
          onTap: () => _navigateToDefectInspection(),
          showViewAll: true,
        ),
        SizedBox(height: 10.h),
        // Warehouse stock card
        const WarehouseStockCard(),
      ],
    );
  }

  Widget _buildCashierSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.translate('dashboardCashManagementTitle'), Icons.account_balance_wallet),
        SizedBox(height: 12.h),
        _buildApprovalCard(
          title: l10n.translate('dashboardCashApprovalsTitle'),
          subtitle: l10n.translate('dashboardCashApprovalsSubtitle'),
          count: _pendingCashApprovals,
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          onTap: () => _navigateToCashApprovals(),
          showViewAll: true,
        ),
      ],
    );
  }

  Widget _buildCSESection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.translate('dashboardCustomerSupportTitle'), Icons.support_agent),
        SizedBox(height: 12.h),
        _buildApprovalCard(
          title: l10n.translate('dashboardOpenTicketsTitle'),
          subtitle: l10n.translate('dashboardOpenTicketsSubtitle'),
          count: _pendingCSETickets,
          icon: Icons.support_agent,
          color: Colors.purple,
          onTap: () => _navigateToCSETickets(),
          showViewAll: true,
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _buildStatsCard(
                title: l10n.translate('dashboardResolvedTodayLabel'),
                value: '12',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildStatsCard(
                title: l10n.translate('dashboardAverageResponseLabel'),
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
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('GM Dashboard', Icons.dashboard),
        SizedBox(height: 12.h),

        // Reports Section
        _buildSectionHeader('Reports', Icons.assessment, size: 16),
        SizedBox(height: 10.h),

        // Row 1: Cash Report, Inventory Report
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                title: 'Cash Report',
                icon: Icons.account_balance_wallet,
                color: Colors.green,
                isComingSoon: true,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildReportCard(
                title: 'Inventory Report',
                icon: Icons.inventory_2,
                color: Colors.blue,
                isComingSoon: true,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.h),

        // Row 2: EOD Report, Credit Extension
        Row(
          children: [
            Expanded(
              child: _buildReportCard(
                title: 'EOD Report',
                icon: Icons.today,
                color: Colors.orange,
                isComingSoon: true,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildReportCard(
                title: 'Credit Extension',
                icon: Icons.card_giftcard,
                color: Colors.purple,
                isComingSoon: false,
                onTap: () => _navigateToCreditExtensions(),
              ),
            ),
          ],
        ),

        SizedBox(height: 16.h),

        // Management Section
        _buildSectionHeader('Management', Icons.settings, size: 16),
        SizedBox(height: 10.h),

        // Procurement
        _buildApprovalCard(
          title: 'Procurement',
          subtitle: 'Purchase Orders & Invoices',
          count: 0,
          icon: Icons.shopping_bag,
          color: Colors.indigo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PurchaseInvoiceScreen()),
            );
          },
          showViewAll: true,
        ),

        SizedBox(height: 10.h),

        // Warehouse Stock
        const WarehouseStockCard(),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    bool isComingSoon = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isComingSoon
          ? () => _showSuccessSnackBar('$title - Coming Soon!')
          : onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(icon, color: color, size: 20.sp),
                ),
                Spacer(),
                if (isComingSoon)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultSection() {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n.translate('dashboardGettingStartedTitle'), Icons.info),
        SizedBox(height: 12.h),
        _buildActionCard(
          title: l10n.translate('dashboardViewProfileTitle'),
          subtitle: l10n.translate('dashboardViewProfileSubtitle'),
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
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5CA8).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0E5CA8),
            size: (size ?? 18).sp,
          ),
        ),
        SizedBox(width: 10.w),
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
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
                fontSize: 10.sp,
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.sp,
                color: color,
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
                      color: Colors.black87,
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
            if (showViewAll)
              Icon(
                Icons.arrow_forward_ios,
                size: 12.sp,
                color: Colors.grey[400],
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
      padding: EdgeInsets.all(12.w),
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
            color: color.withOpacity(0.3),
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
                color: color,
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
    final l10n = context.l10n;
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
                        l10n.translate('dashboardNotificationsTitle'),
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
                            l10n.translate(
                              'dashboardPendingCountLabel',
                              params: [_getTotalPendingCount().toString()],
                            ),
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
                            l10n.translate('dashboardInventoryApprovalsTitle'),
                            l10n.translate(
                              'dashboardInventoryPendingSubtitle',
                              params: [_pendingInventoryApprovals.toString()],
                            ),
                            Icons.inventory,
                            Colors.blue,
                                () {
                              Navigator.pop(context);
                              _navigateToInventoryApprovals();
                            },
                          ),
                        if (_pendingCashApprovals > 0)
                          _buildNotificationItem(
                            l10n.translate('dashboardCashApprovalsTitle'),
                            l10n.translate(
                              'dashboardCashPendingSubtitle',
                              params: [_pendingCashApprovals.toString()],
                            ),
                            Icons.account_balance_wallet,
                            Colors.green,
                                () {
                              Navigator.pop(context);
                              _navigateToCashApprovals();
                            },
                          ),
                        if (_pendingOrderApprovals > 0)
                          _buildNotificationItem(
                            l10n.translate('dashboardOrderApprovalsTitle'),
                            l10n.translate(
                              'dashboardOrdersPendingSubtitle',
                              params: [_pendingOrderApprovals.toString()],
                            ),
                            Icons.shopping_cart,
                            Colors.orange,
                                () {
                              Navigator.pop(context);
                              _navigateToOrderApprovals();
                            },
                          ),
                        if (_pendingCSETickets > 0)
                          _buildNotificationItem(
                            l10n.translate('dashboardCseTicketsTitle'),
                            l10n.translate(
                              'dashboardTicketsPendingSubtitle',
                              params: [_pendingCSETickets.toString()],
                            ),
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
                                  l10n.translate('dashboardNoPendingNotifications'),
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
        builder: (context) => CashDepositPage(), // Navigate to cash page with deposit mode
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToInventoryCollect() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CollectInventoryScreen(), // Navigate to inventory with collect mode
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToInventoryDeposit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DepositInventoryScreen(
          depositType: "sales_order",
        ),// Navigate to inventory with deposit mode
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

  void _navigateToDefectInspection() {
    Navigator.pushNamed(context, '/defects/inspections').then((_) => _refreshDashboard());
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OrdersPage(),
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToCSETickets() {
    // Navigate to CSE tickets screen
    _showSuccessSnackBar(context.l10n.translate('dashboardCseTicketsComingSoon'));
  }

  void _navigateToCreditExtensions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GmPendingApprovalsPage(),
      ),
    ).then((_) => _refreshDashboard());
  }

  void _navigateToSdmsClaims() {
    Navigator.pushNamed(context, '/sdms-claims/entry').then((_) => _refreshDashboard());
  }

  void _navigateToQuotaStatus() {
    Navigator.pushNamed(context, '/quota').then((_) => _refreshDashboard());
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
      total += _pendingCreditExtensions;
    }

    if (_userRoles.contains('cse') || _userRoles.contains('General Manager')) {
      total += _pendingCSETickets;
    }

    return total;
  }

  String _pendingApprovalLabel(BuildContext context) {
    final int pendingCount = _getTotalPendingCount();
    final String countString = pendingCount.toString();
    return pendingCount == 1
        ? context.l10n
        .translate('dashboardPendingApprovalSingle', params: [countString])
        : context.l10n.translate(
      'dashboardPendingApprovalsMultiple',
      params: [countString],
    );
  }

  String _getTimeBasedGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return context.l10n.translate('dashboardGreetingMorning');
    }
    if (hour < 17) {
      return context.l10n.translate('dashboardGreetingAfternoon');
    }
    return context.l10n.translate('dashboardGreetingEvening');
  }

  String _formatUserRoles(BuildContext context) {
    if (_userRoles.isEmpty) {
      return context.l10n.translate('dashboardUserFallback');
    }

    List<String> formattedRoles = _userRoles.map((role) {
      switch (role.toLowerCase()) {
        case 'delivery boy':
          return context.l10n.translate('dashboardRoleDeliveryBoy');
        case 'warehouse manager':
          return context.l10n.translate('dashboardRoleWarehouseManager');
        case 'general manager':
          return context.l10n.translate('dashboardRoleGeneralManager');
        case 'cse':
          return context.l10n.translate('dashboardRoleCustomerServiceExecutive');
        case 'cashier':
          return context.l10n.translate('dashboardRoleCashier');
        default:
          return role.split(' ').map((word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
          ).join(' ');
      }
    }).toList();

    if (formattedRoles.length == 1) {
      return formattedRoles.first;
    } else if (formattedRoles.length == 2) {
      final String separator = context.l10n.translate('dashboardRolesSeparator');
      return '${formattedRoles.first}$separator${formattedRoles.last}';
    } else {
      return context.l10n.translate(
        'dashboardAdditionalRoles',
        params: [formattedRoles.first, (formattedRoles.length - 1).toString()],
      );
    }
  }

  String _localizedModuleName(String module) {
    switch (module) {
      case 'inventory':
        return context.l10n.translate('dashboardModuleInventory');
      case 'cash':
        return context.l10n.translate('dashboardModuleCash');
      case 'orders':
        return context.l10n.translate('dashboardModuleOrders');
      case 'cse':
        return context.l10n.translate('dashboardModuleCse');
      default:
        return module;
    }
  }

  // Method to simulate count updates (call this when lists update)
  void updatePendingCounts({
    int? inventoryCount,
    int? cashCount,
    int? orderCount,
    int? cseCount,
    int? creditExtensionCount,
  }) {
    setState(() {
      if (inventoryCount != null) _pendingInventoryApprovals = inventoryCount;
      if (cashCount != null) _pendingCashApprovals = cashCount;
      if (orderCount != null) _pendingOrderApprovals = orderCount;
      if (cseCount != null) _pendingCSETickets = cseCount;
      if (creditExtensionCount != null) _pendingCreditExtensions = creditExtensionCount;
    });
  }

  // Method to handle WebSocket updates (call this from your WebSocket listener)
  void handleWebSocketUpdate(Map<String, dynamic> data) {
    if (!mounted) return;

    try {

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
          case 'credit_extension':
            setState(() => _pendingCreditExtensions = count);
            break;
        }

        // Show notification if new pending items
        if (data['action'] == 'new_pending') {
          final String moduleName = _localizedModuleName(module);
          _showSuccessSnackBar(
            context.l10n.translate(
              'dashboardNewApprovalPending',
              params: [moduleName],
            ),
          );        }
      }
    } catch (e) {
      debugPrint('Error handling WebSocket update: $e');
    }
  }
}