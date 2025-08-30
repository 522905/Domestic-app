import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/all_transactions_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/bank_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/deposit_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/handovers_tab.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/service_provider.dart';
import '../../../core/utils/global_drawer.dart';
import '../../../domain/entities/cash/partner_balance.dart';
import '../../blocs/cash/cash_bloc.dart';
import 'forms/bank_deposit_page.dart';
import 'forms/handover_screen.dart';

class CashPage extends StatefulWidget {
  const CashPage({Key? key}) : super(key: key);

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  late ApiServiceInterface _apiService;
  late TextEditingController _searchController;
  bool _isLoading = true;
  List<String>? userRole;
  String? userName;
  bool _isInitialized = false;

  final currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _initializeApp();
  }

  // Initialize everything in proper order
  Future<void> _initializeApp() async {
    try {
      // First, get user roles
      await _fetchUserRole();

      // Then initialize API service
      _apiService = await ServiceProvider.getApiService();

      setState(() {
        _isLoading = false;
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error initializing app: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized && ModalRoute.of(context)?.isCurrent == true) {
      context.read<CashManagementBloc>().add(RefreshCashData());
    }
  }

  Future<void> _fetchUserRole() async {
    final roles = await User().getUserRoles();
    final username = await User().getUserName();

    setState(() {
      userRole = roles.map((role) => role.role).toList();
      userName = username;
      _tabController?.dispose(); // Dispose old controller if exists
      _tabController = TabController(length: _getTabs().length, vsync: this);
    });
  }

  List<String> _getTabs() {
    if (userRole?.contains('Delivery Boy') ?? false) {
      return ['All Transactions'];
    } else if (userRole?.contains('Cashier') ?? false) {
      return ['Deposits', 'Handovers', 'Bank'];
    } else {
      return [ 'Deposits', 'Handovers', 'Bank'];
    }
  }

  List<Widget> _getTabViews() {
    if (userRole?.contains('Delivery Boy') ?? false) {
      return [AllTransactionsTab()];
    } else if (userRole?.contains('Cashier') ?? false) {
      return [
        DepositsTab(),
        HandoversTab(),
        BankTab()
      ];
    } else {
      return [
        // AllTransactionsTab(),
        DepositsTab(),
        HandoversTab(),
        BankTab()
      ];
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    // Show loading screen until everything is initialized
    if (_isLoading || !_isInitialized || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder<ApiServiceInterface>(
      future: ServiceProvider.getApiService(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text("Error initializing service: ${snapshot.error}"),
            ),
          );
        }

        final apiService = snapshot.data!;

        return BlocProvider(
          create: (context) => CashManagementBloc(apiService: apiService)..add(RefreshCashData()),
          child: Scaffold(
            drawer: GlobalDrawer.getDrawer(context),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E5CA8),
              title: const Text('Cash Data'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white,),
                  onPressed: () async {
                    context.read<CashManagementBloc>().add(RefreshCashData());
                    return await Future.delayed(const Duration(milliseconds: 200));
                  },
                ),
              ],
            ),
            body: BlocConsumer<CashManagementBloc, CashManagementState>(
              listener: (context, state) {
                // Handle success states - just show a simple snackbar
                if (state is TransactionAddedSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }

                // Handle error states with simple dialog
                if (state is CashManagementError) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8.w),
                          Text('Error'),
                        ],
                      ),
                      content: Text(state.message),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<CashManagementBloc>().add(RefreshCashData());
                          },
                          child: Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
              builder: (context, state) {
                // Keep all your existing builder code exactly the same
                if (state is CashManagementLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CashManagementError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading cash data: ${state.message}',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        SizedBox(height: 8.h),
                        ElevatedButton(
                          onPressed: () => context.read<CashManagementBloc>().add(RefreshCashData()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is CashManagementLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CashManagementBloc>().add(RefreshCashData());
                      return await Future.delayed(const Duration(milliseconds: 400));
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (userRole?.contains('Cashier') ?? false) _buildCashInHandCard(state),
                              // if (userRole?.contains('Cashier') ?? false) _buildSearchBar(context),
                              if (userRole?.contains('Delivery Boy') ?? false) _accountsTab(),
                              _buildTabs(),
                            ],
                          ),
                        ),
                        SliverFillRemaining(
                          child: TabBarView(
                            controller: _tabController!,
                            children: _getTabViews(),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: Text('No data available'));
              },
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'cash_fab',
              onPressed: () async {
                _showCashOptionsBottomSheet(userRole);
              },
              backgroundColor: const Color(0xFF0E5CA8),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashInHandCard(CashManagementLoaded state) {
    final formattedDate = DateFormat('MMM dd, HH:mm a').format(state.cashData.lastUpdated);

    if (userRole?.contains('Delivery Boy') ?? false) {
      // For Delivery Boy - show partner data
      if (state.cashData.partners.isNotEmpty) {
        final partner = state.cashData.partners.first;
        return Padding(
          padding: EdgeInsets.all(8.w),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.partnerName,
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'ID: ${partner.partnerId}',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.read<CashManagementBloc>().add(RefreshCashData()),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF0DD),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'REFRESH',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFF7941D),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Show balance data in a compact format
                  ...partner.balanceData.map((balance) => Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          balance.account,
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          currencyFormat.format(balance.availableBalance),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: balance.availableBalance > 0
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),

                  SizedBox(height: 8.h),
                  Text(
                    'Last updated: $formattedDate',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else if (userRole?.contains('Cashier') ?? false) {
      // For Cashier - show cashier account data
      double availableBalance = state.cashData.cashInHand;
      String accountName = 'Cash Account';

      if (state.cashData.cashierAccounts.isNotEmpty) {
        accountName = state.cashData.cashierAccounts[0]['account_name'] ?? 'Cash Account';
      }

      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      accountName,
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                    ),
                    GestureDetector(
                      onTap: () => context.read<CashManagementBloc>().add(RefreshCashData()),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF0DD),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'REFRESH',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF7941D),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Text(
                      currencyFormat.format(availableBalance),
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'as of $formattedDate',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Fallback for other roles
    return const SizedBox.shrink();
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.w),
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
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_searchController.text == value) {
              context.read<CashManagementBloc>().add(SearchCashRequest(query: value));
            }
          });
        },
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = _getTabs();

    return Container(
      margin: EdgeInsets.only(top: 5.h),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.black12, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController!,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 5,
        labelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        tabs: tabs.map((tab) => Tab(text: tab)).toList(),
      ),
    );

  }

  void _showCashOptionsBottomSheet(List<String>? userRole) {
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
              if (userRole?.contains('Delivery Boy') ?? false)
                _buildBottomSheetOption(
                  icon: Icons.inventory,
                  title: 'Cash Deposit',
                  subtitle: 'Deposit cash to bank or Manager',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<CashManagementBloc>(),
                          child: const CashDepositPage(),
                        ),
                      ),
                    );
                    // Handle result - refresh if transaction was added
                    if (result == true && mounted) {
                      // The bloc will automatically update the UI through TransactionAddedSuccess state
                      // No need to manually refresh here as the bloc handles it
                    }
                  },
                ),
              if (userRole?.contains('Cashier') ?? false)
                _buildBottomSheetOption(
                  icon: Icons.inventory_2_rounded,
                  title: 'Handover Cash',
                  subtitle: 'Handover cash to bank or Manager',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<CashManagementBloc>(),
                          child: const HandoverScreen(),
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      _switchToHandoverTab();
                    }
                  },
                ),
              if (!(userRole?.contains('Delivery Boy') ?? false))
                _buildBottomSheetOption(
                  icon: Icons.account_balance,
                  title: 'Bank Deposit',
                  subtitle: 'Deposit cash directly to bank',
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: context.read<CashManagementBloc>(),
                          child: const BankDepositPage(),
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      _switchToBankTab();
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _switchToBankTab() {
    final tabs = _getTabs();
    int bankTabIndex = tabs.indexOf('Ban'
        'k');

    if (bankTabIndex != -1 && bankTabIndex < _tabController!.length) {
      _tabController!.animateTo(bankTabIndex);
    }
  }

  void _switchToHandoverTab() {
    final tabs = _getTabs();
    int handoverTabIndex = tabs.indexOf('Handovers');

    if (handoverTabIndex != -1 && handoverTabIndex < _tabController!.length) {
      _tabController!.animateTo(handoverTabIndex);
    }
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

  Widget _accountsTab() {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      builder: (context, state) {
        if (state is! CashManagementLoaded) {
          return const SizedBox.shrink();
        }

        final partners = state.cashData.partners;

        if (partners.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Balances',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 48.sp,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Data not available',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Pull down to refresh',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Collect all balance data from all partners
        List<AccountBalance> allAccounts = [];
        for (var partner in partners) {
          allAccounts.addAll(partner.balanceData);
        }

        if (allAccounts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 1,
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Center(
                  child: Text(
                    'No account data available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0.0),
          child: _buildAccountsTable(allAccounts),
        );
      },
    );
  }

  Widget _buildAccountsTable(List<AccountBalance> accounts) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 10.h),
        Text(
          'Account Balances ',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Column(
            children: [
              // Table Headers
              Container(
                color: Colors.grey[100],
                child: Row(
                  children: [
                    Expanded(flex: 3, child: _buildTableHeaderCell('Account')),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Ledger')),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Open')),
                    Expanded(flex: 2, child: _buildTableHeaderCell('Available')),
                  ],
                ),
              ),

              // Table Rows
              ...accounts.asMap().entries.map((entry) {
                int index = entry.key;
                AccountBalance account = entry.value;
                return Container(
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTableDataCell(
                         account.account,
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildTableDataCell(
                          _formatCurrency(account.ledgerBalance),
                          color: account.ledgerBalance < 0 ? Colors.red : Colors.grey[800]!,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildTableDataCell(
                          _formatCurrency(account.openSalesOrders),
                          color: Colors.grey[800]!,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: _buildTableDataCell(
                          _formatCurrency(account.availableBalance),
                          color: account.availableBalance > 0
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[800]!,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableDataCell(
      String text, {
        Color? color,
        Alignment alignment = Alignment.center,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!, width: 1),
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Align(
        alignment: alignment,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.grey[800],
          ),
          textAlign: alignment == Alignment.centerLeft
              ? TextAlign.left
              : TextAlign.center,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0.0) {
      return '₹0';
    }
    return currencyFormat.format(amount);
  }
}