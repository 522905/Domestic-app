import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/all_transactions_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/bank_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/deposit_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/handovers_tab.dart';
import 'package:lpg_distribution_app/presentation/widgets/error_dialog.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/service_provider.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/cash/cash_bloc.dart';
import 'forms/bank_deposit_page.dart';
import 'forms/handover_screen.dart';

enum AccountType {
  refill,
  svTv,
  nfr,
}

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

  final Map<AccountType, double> _accountBalances = {
    AccountType.svTv: 0.0,
    AccountType.refill: 0.0,
    AccountType.nfr: 0.0,
  };

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

      // Finally, update account balances
      await _updateAccountBalances();

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
    // Only refresh if already initialized
    if (_isInitialized && ModalRoute.of(context)?.isCurrent == true) {
      context.read<CashManagementBloc>().add(RefreshCashData());
      _updateAccountBalances();
    }
  }

  Future<void> _updateAccountBalances() async {
    try {
      final response = await _apiService.getCashSummary();
      List<dynamic> customerOverview = response['customerOverview'] ?? [];

      _accountBalances.clear();
      if (customerOverview.isNotEmpty) {
        for (var item in customerOverview) {
          final accountName = item['account'] ?? '';
          final availableBalance = item['available_balance']?.toDouble() ?? 0.0;

          // if (accountName.contains('TV Account')) {
          //   _accountBalances[AccountType.svTv] = availableBalance;
          // } else if (accountName.contains('Debtors')) {
          //   _accountBalances[AccountType.refill] = availableBalance;
          // } else if (accountName.contains('NFR Account')) {
          //   _accountBalances[AccountType.nfr] = availableBalance;
          // }
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error updating account balances: $e');
    }
  }

  Future<void> _fetchUserRole() async {
    final roles = await User().getUserRoles();
    final username = await User().getUserName();

    setState(() {
      userRole = roles.map((role) => role.role).toList();
      userName = username;
      // Initialize TabController with proper length after getting user roles
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
          create: (context) => CashManagementBloc(apiService: apiService)..add(LoadCashData()),
          child: Scaffold(
            drawer: GlobalDrawer.getDrawer(context),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E5CA8),
              title: const Text('Cash Data'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  onPressed: () {
                    // Show help dialog
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
                          onPressed: () => context.read<CashManagementBloc>().add(LoadCashData()),
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
                      _updateAccountBalances();
                      return await Future.delayed(const Duration(milliseconds: 400));
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              if (userRole?.contains('Cashier') ?? false) _buildCashInHandCard(state),
                              if (userRole?.contains('Cashier') ?? false) _buildSearchBar(context),
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
    final availableBalance = state.cashData.customerOverview.isNotEmpty
        ? state.cashData.customerOverview[0]['availableBalance']
        : 0.0;

    return Padding(
      padding: EdgeInsets.all(8.w),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cash in Hand',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<CashManagementBloc>().add(RefreshCashData());
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF0DD),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'REFRESH',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFFF7941D),
                            ),
                          ),
                        ],
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
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
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
                      _updateAccountBalances();
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
                      _updateAccountBalances();
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

  void _handleTransactionError(dynamic error) {
    String errorMessage = 'An error occurred';

    if (error is CashManagementError) {
      errorMessage = error.message;
    } else if (error != null) {
      errorMessage = error.toString();
    }

    context.showErrorDialog(
      title: 'Transaction Error',
      error: error,
      onRetry: () {
        context.read<CashManagementBloc>().add(RefreshCashData());
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
    final hasData = _accountBalances.isNotEmpty &&
        _accountBalances.values.any((balance) => balance > 0);

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
              if (!hasData) ...[
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
              ] else ...[
                ..._accountBalances.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14.r,
                          backgroundColor: _getAccountColor(entry.key).withOpacity(0.2),
                          child: Text(
                            _getAccountInitial(entry.key),
                            style: TextStyle(
                              color: _getAccountColor(entry.key),
                              fontWeight: FontWeight.bold,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          _getAccountLabel(entry.key),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          currencyFormat.format(entry.value),
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getAccountColor(AccountType type) {
    switch (type) {
      case AccountType.svTv:
        return const Color(0xFF0E5CA8);
      case AccountType.refill:
        return const Color(0xFF4CAF50);
      case AccountType.nfr:
        return const Color(0xFFF7941D);
    }
  }

  String _getAccountInitial(AccountType type) {
    switch (type) {
      case AccountType.svTv:
        return 'S';
      case AccountType.refill:
        return 'R';
      case AccountType.nfr:
        return 'N';
    }
  }

  String _getAccountLabel(AccountType type) {
    switch (type) {
      case AccountType.svTv:
        return 'SV/TV Account';
      case AccountType.refill:
        return 'Refill Account';
      case AccountType.nfr:
        return 'NFR Account';
      default:
        return 'Unknown Account';
    }
  }
}