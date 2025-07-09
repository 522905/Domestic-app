import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/all_transactions_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/deposit_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/handovers_tab.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/service_provider.dart';
import '../../../core/services/token_manager.dart';
import '../../../domain/entities/cash/cash_transaction.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/cash/cash_bloc.dart';
import 'forms/handover_screen.dart';

class CashPage extends StatefulWidget {
  const CashPage({Key? key}) : super(key: key);

  @override
  State<CashPage> createState() => _CashPageState();
}

class _CashPageState extends State<CashPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiServiceInterface _apiService;
  late TextEditingController _searchController;
  CashManagementBloc? _cashBloc; // Nullable until loaded
  bool _isLoading = true;
  List<String>? userRole;
  String? userName ;

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
      _fetchUserRole();
      _searchController = TextEditingController();
      ServiceProvider.getApiService().then((service) {
        _apiService = service;
        _cashBloc = CashManagementBloc(apiService: _apiService)..add(LoadCashData());
        _updateAccountBalances(); // Call after _apiService is initialized
        setState(() {
          _isLoading = false;
        });
      });
    }

    Future<void> _updateAccountBalances() async {
        try {
          final response = await _apiService.getCashSummary();
          List<dynamic> customerOverview = response['customerOverview'] ?? []; // Correct key

          _accountBalances.clear();
          if (customerOverview.isNotEmpty) {
            for (var item in customerOverview) {
              final accountName = item['account'] ?? '';
              final availableBalance = item['available_balance']?.toDouble() ?? 0.0;

              if (accountName.contains('TV Account')) {
                _accountBalances[AccountType.svTv] = availableBalance;
              } else if (accountName.contains('Debtors')) {
                _accountBalances[AccountType.refill] = availableBalance;
              } else if (accountName.contains('NFR Account')) {
                _accountBalances[AccountType.nfr] = availableBalance;
              }
            }
            setState(() {});
          }
        } catch (e) {
          print('Error updating account balances: $e');
        }
      }

  void _fetchUserRole() async {
    final roles = await TokenManager().getUserRole(); // Fetch roles as a list
    final username = await TokenManager().getUserName();
    setState(() {
      userRole = roles; // Store roles directly as a list
      userName = username;
      _tabController = TabController(length: _getTabs().length, vsync: this);
    });
  }

    List<String> _getTabs() {
      if (userRole?.contains('delivery-boy') ?? false) {
        return ['All Transactions'];
      } else if (userRole?.contains('cashier') ?? false) {
        return ['Deposits', 'Handovers'];
      } else {
        return ['All Transactions', 'Deposits', 'Handovers', 'Bank'];
      }
    }

    List<Widget> _getTabViews() {
      if (userRole?.contains('delivery-boy') ?? false) {
        return [AllTransactionsTab(userName: userName)];
      } else if (userRole?.contains('cashier') ?? false) {
        return [
          DepositsTab(userName: userName),
          HandoversTab(userName: userName)
        ];
      } else {
        return [
          AllTransactionsTab(userName: userName),
          DepositsTab(userName: userName),
          HandoversTab(userName: userName,),
          // BankTab()
        ];
      }
    }

    @override
    void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _cashBloc?.close(); // Don't forget to close the bloc
    super.dispose();
  }

  @override
    Widget build(BuildContext context) {
      return FutureBuilder<ApiServiceInterface>(
        future: ServiceProvider.getApiService(), // Async guard
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(
                  child: CircularProgressIndicator()
              ),
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
              body: BlocBuilder<CashManagementBloc, CashManagementState>(
                builder: (context, state) {
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
                        _updateAccountBalances(); // Refresh account balances
                        return await Future.delayed(const Duration(milliseconds: 400));
                      },
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                              if (userRole!.contains('cashier')) _buildCashInHandCard(state),
                                if (userRole!.contains('cashier')) _buildSearchBar(context),
                                if(userRole!.contains('delivery-boy')) _accountsTab(),
                                _buildTabs(),
                              ],
                            ),
                          ),
                          SliverFillRemaining(
                            child: TabBarView(
                              controller: _tabController,
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
                      final userRole = await TokenManager().getUserRole();
                      _showCashOptionsBottomSheet(userRole); // Pass userRole to the method
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
          : 0.0; // Default to 0.0 if no data is available

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
            // Add debouncing to prevent excessive API calls
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
          controller: _tabController,
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

  void _showCashOptionsBottomSheet(
          List<String>? userRole,
      ) {
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
              if (userRole?.contains('delivery-boy') ?? false)
                _buildBottomSheetOption(
                  icon: Icons.inventory,
                  title: 'Deposit Cash',
                  subtitle: 'Deposit cash to bank or Manager',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CashDepositPage()),
                    );
                  },
                ),
              if (userRole?.contains('cashier') ?? false)
                _buildBottomSheetOption(
                  icon: Icons.inventory_2_rounded,
                  title: 'Handover Cash',
                  subtitle: 'Handover cash to bank or Manager',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HandoverScreen()),
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

    void _handleTransactionAdded(CashTransaction transaction) {
    // Example: Refresh the cash data after a transaction is added
    context.read<CashManagementBloc>().add(RefreshCashData());

    // Optionally, show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction added successfully!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

    Widget _accountsTab() {
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
            ),
          ),
        ),
      );
    }

    Color _getAccountColor(AccountType type) {
      switch (type) {
        case AccountType.svTv:
          return const Color(0xFF0E5CA8); // Brand Blue
        case AccountType.refill:
          return const Color(0xFF4CAF50); // Green
        case AccountType.nfr:
          return const Color(0xFFF7941D); // Brand Orange
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