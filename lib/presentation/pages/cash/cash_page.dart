import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/all_transactions_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/bank_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/deposit_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/handovers_tab.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/tabs/pending_tab.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/service_provider.dart';
import '../../../core/utils/global_drawer.dart';
import '../../../domain/entities/cash/cash_transaction.dart';
import '../../../domain/entities/cash/partner_balance.dart';
import '../../blocs/cash/cash_bloc.dart';
import 'forms/bank_deposit_page.dart';
import 'forms/handover_screen.dart';
import 'general_ledger_detail_page.dart';
import '../../widgets/professional_snackbar.dart';

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
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
  bool _isSearching = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('🔵 cash_page: Loading initial cash data');
        context.read<CashManagementBloc>().add(RefreshCashData());
      }
    });

    WidgetsBinding.instance.addObserver(_AppLifecycleObserver(
      onResume: () {
        if (mounted && _isInitialized) {
          print('🔵 cash_page: App resumed, refreshing data');
          context.read<CashManagementBloc>().add(RefreshCashData());
        }
      },
    ));
  }

  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //
  //   // More reliable way to detect when page becomes active
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     if (mounted && _isInitialized) {
  //       final route = ModalRoute.of(context);
  //       if (route?.isCurrent == true && !route!.isFirst) {
  //         // We're returning from another screen - refresh data
  //         context.read<CashManagementBloc>().add(RefreshCashData());
  //       }
  //     }
  //   });
  // }

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

  Future<void> _fetchUserRole() async {
    final roles = await User().getUserRoles();
    final username = await User().getUserName();

    setState(() {
      userRole = roles.map((role) => role.role).toList();
      userName = username;
      _tabController?.dispose();

      int tabCount;
      if (userRole?.contains('Delivery Boy') ?? false) {
        tabCount = 1; // Only 'All Transactions'
      } else {
        tabCount = 4; // 'Pending', 'Deposits', 'Handovers', 'Bank'
      }
      _tabController = TabController(length: tabCount, vsync: this);
      _tabController!.addListener(_onTabChanged);
    });
  }

  List<String> _getTabs(List<CashTransaction> allTransactions, List<CashTransaction> filteredTransactions, bool isSearching) {
    if (userRole?.contains('Delivery Boy') ?? false) {
      final allCount = allTransactions.length;
      final filteredCount = filteredTransactions.length;

      if (isSearching && filteredCount != allCount) {
        return ['All Transactions ($filteredCount/$allCount)'];
      }
      return ['All Transactions ($allCount)'];
    } else if (userRole?.contains('Cashier') ?? false) {
      // Count in ALL transactions (total)
      final pendingCountTotal = allTransactions
          .where((tx) => tx.status == TransactionStatus.pending)
          .length;
      final depositCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.deposit)
          .length;
      final handoverCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.handover)
          .length;
      final bankCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.bank)
          .length;

      // Count in FILTERED transactions (search results)
      final pendingCountFiltered = filteredTransactions
          .where((tx) => tx.status == TransactionStatus.pending)
          .length;
      final depositCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.deposit)
          .length;
      final handoverCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.handover)
          .length;
      final bankCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.bank)
          .length;

      if (isSearching && filteredTransactions.length != allTransactions.length) {
        return [
          'Pending ($pendingCountFiltered/$pendingCountTotal)',
          'Deposits ($depositCountFiltered/$depositCountTotal)',
          'Handovers ($handoverCountFiltered/$handoverCountTotal)',
          'Bank ($bankCountFiltered/$bankCountTotal)'
        ];
      }

      return [
        'Pending ($pendingCountTotal)',
        'Deposits ($depositCountTotal)',
        'Handovers ($handoverCountTotal)',
        'Bank ($bankCountTotal)'
      ];
    } else {
      // Same logic for managers
      final pendingCountTotal = allTransactions
          .where((tx) => tx.status == TransactionStatus.pending)
          .length;
      final depositCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.deposit)
          .length;
      final handoverCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.handover)
          .length;
      final bankCountTotal = allTransactions
          .where((tx) => tx.type == TransactionType.bank)
          .length;

      final pendingCountFiltered = filteredTransactions
          .where((tx) => tx.status == TransactionStatus.pending)
          .length;
      final depositCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.deposit)
          .length;
      final handoverCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.handover)
          .length;
      final bankCountFiltered = filteredTransactions
          .where((tx) => tx.type == TransactionType.bank)
          .length;

      if (isSearching && filteredTransactions.length != allTransactions.length) {
        return [
          'Pending ($pendingCountFiltered/$pendingCountTotal)',
          'Deposits ($depositCountFiltered/$depositCountTotal)',
          'Handovers ($handoverCountFiltered/$handoverCountTotal)',
          'Bank ($bankCountFiltered/$bankCountTotal)'
        ];
      }

      return [
        'Pending ($pendingCountTotal)',
        'Deposits ($depositCountTotal)',
        'Handovers ($handoverCountTotal)',
        'Bank ($bankCountTotal)'
      ];
    }
  }

  List<Widget> _getTabViews() {
    if (userRole?.contains('Delivery Boy') ?? false) {
      return [AllTransactionsTab()];
    } else if (userRole?.contains('Cashier') ?? false) {
      return [
        PendingTab(),
        DepositsTab(),
        HandoversTab(),
        BankTab()
      ];
    } else {
      return [
        PendingTab(),
        DepositsTab(),
        HandoversTab(),
        BankTab()
      ];
    }
  }

  // NEW: Handle tab changes - reset search
  void _onTabChanged() {
    if (_tabController!.indexIsChanging) {
      _resetSearch();
    }
  }

// NEW: Reset search state
  void _resetSearch() {
    if (_isSearching || _searchController.text.isNotEmpty) {
      setState(() {
        _isSearching = false;
        _searchController.clear();
      });
      context.read<CashManagementBloc>().add(SearchCashRequest(query: ''));
    }
  }

// NEW: Toggle search mode
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<CashManagementBloc>().add(SearchCashRequest(query: ''));
      }
    });
  }

// NEW: Perform search
  void _performSearch(String query) {
    context.read<CashManagementBloc>().add(SearchCashRequest(query: query));
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0E5CA8),
      title: _isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Search by ID, name, reference...',
          hintStyle: TextStyle(color: Colors.white70),
          border: InputBorder.none,
        ),
        onChanged: _performSearch,
      )
          : const Text('Cash'),
      centerTitle: !_isSearching,
      actions: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _toggleSearch,
          )
        else ...[
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
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

                context.read<CashManagementBloc>().add(RefreshCashData());

                await Future.delayed(const Duration(milliseconds: 500));

                if (mounted) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              }
            },
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen until everything is initialized
    if (_isLoading || !_isInitialized || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ NO FutureBuilder, NO BlocProvider
    // Just use the existing bloc from app level (main.dart)
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      // appBar: AppBar(
      //   backgroundColor: const Color(0xFF0E5CA8),
      //   title: const Text('Cash'),
      //   centerTitle: true,
      //   actions: [
      //     IconButton(
      //       icon: const Icon(
      //           Icons.refresh,
      //           color: Colors.white
      //       ),
      //       onPressed: () async {
      //         if (mounted) {
      //           showDialog(
      //             context: context,
      //             barrierDismissible: false,
      //             builder: (BuildContext context) {
      //               return const Center(
      //                 child: CircularProgressIndicator(),
      //               );
      //             },
      //           );
      //           Future.delayed(const Duration(milliseconds: 500), () {
      //             Navigator.of(context).pop(); // Close the dialog
      //             context.read<CashManagementBloc>().add(RefreshCashData());
      //           });
      //         }
      //       },
      //     ),
      //   ],
      // ),
      appBar: _buildAppBar(),
      body: BlocConsumer<CashManagementBloc, CashManagementState>(
        listener: (context, state) {
          // Handle success states - just show a simple snackbar
          if (state is TransactionAddedSuccess) {
            context.showSuccessSnackBar(state.message);
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
          // ✅ NEW: Auto-refresh if we detect TransactionDetailsLoaded state
          // This happens when returning from transaction detail screen
          if (state is TransactionDetailsLoaded) {
            print('🔄 cash_page: Detected TransactionDetailsLoaded, auto-refreshing...');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.read<CashManagementBloc>().add(RefreshCashData());
              }
            });
            return const Center(child: CircularProgressIndicator());
          }

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
                        if (userRole?.contains('Cashier') ?? false)
                          _buildCashInHandCard(state),
                        if (userRole?.contains('Delivery Boy') ?? false)
                          _accountsTab(),
                        _buildTabs(),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    child: BlocBuilder<CashManagementBloc, CashManagementState>(
                      builder: (context, state) {
                        return TabBarView(
                          controller: _tabController!,
                          key: ValueKey('tabview_${state.hashCode}'),
                          children: _getTabViews(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator()
          );
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
          'Account Balances',
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
              // Table Rows - NOW TAPPABLE
              ...accounts.asMap().entries.map((entry) {
                int index = entry.key;
                AccountBalance account = entry.value;
                return InkWell(
                  onTap: () {
                    List<String> allAccountNames = accounts.map((a) => a.accountName).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GeneralLedgerDetailPage(
                          accountNames: account.accountName, // Full name like "Load Account - AG"
                          accountLabel: account.account.replaceAll(' - AG', ''), // Display name
                        ),
                      ),
                    );
                  },
                  child: Container(
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
                            alignment: Alignment.centerRight,
                            color: account.ledgerBalance < 0 ? Colors.red : Colors.grey[800]!,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableDataCell(
                            _formatCurrency(account.openSalesOrders),
                            alignment: Alignment.centerRight,
                            color: account.openSalesOrders < 0 ? Colors.red : Colors.grey[800]!,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: _buildTableDataCell(
                            _formatCurrency(account.availableBalance),
                            alignment: Alignment.centerRight,
                            color: account.availableBalance > 0
                                ? const Color(0xFF4CAF50)
                                : Colors.grey[800]!,
                          ),
                        ),
                      ],
                    ),
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
              : alignment == Alignment.centerRight
              ? TextAlign.right
              : TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCashInHandCard(CashManagementLoaded state) {
    final formattedDate = DateFormat('MMM dd, HH:mm a').format(state.cashData.lastUpdated);

    if (userRole?.contains('Cashier') ?? false) {
      double availableBalance = state.cashData.cashInHand;
      String accountName = 'Cash Account';
      String? fullAccountName; // For API call

      if (state.cashData.cashierAccounts.isNotEmpty) {
        accountName = state.cashData.cashierAccounts[0]['account_label'] ?? 'Cash Account';
        fullAccountName = state.cashData.cashierAccounts[0]['account_name']; // Assuming this exists
      }

      return Padding(
        padding: EdgeInsets.all(8.w),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Column(
            children: [
              Padding(
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
                          onTap: () {
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
                                Navigator.of(context).pop();
                                context.read<CashManagementBloc>().add(RefreshCashData());
                              });
                            }
                          },
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
              Divider(height: 1, thickness: 1),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GeneralLedgerDetailPage(
                        accountNames: fullAccountName, // Can be null for all accounts
                        accountLabel: accountName,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View Transaction History',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0E5CA8),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14.sp,
                        color: Color(0xFF0E5CA8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Keep existing delivery boy logic unchanged
    return const SizedBox.shrink();
  }

  Widget _buildTabs() {
    return BlocBuilder<CashManagementBloc, CashManagementState>(
      buildWhen: (previous, current) {
        return current is CashManagementLoaded ||
            (previous is CashManagementLoaded && current is CashManagementLoaded);
      },
      builder: (context, state) {
        List<String> tabs;

        if (state is CashManagementLoaded) {
          tabs = _getTabs(
              state.allTransactions,
              state.filteredTransactions,
              _isSearching  // Pass search state
          );
        } else {
          if (userRole?.contains('Delivery Boy') ?? false) {
            tabs = ['All Transactions (...)'];
          } else {
            tabs = ['Pending (...)', 'Deposits (...)', 'Handovers (...)', 'Bank (...)'];
          }
        }

        return Container(
          key: ValueKey('tabs_${tabs.hashCode}'),
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
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w400),
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        );
      },
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
                  subtitle: 'Deposit cash to Manager',
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet

                    // Capture bloc BEFORE async navigation to avoid context issues
                    final bloc = context.read<CashManagementBloc>();

                    print('🔵 Navigating to Cash Deposit page');
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: const CashDepositPage(),
                        ),
                      ),
                    );
                    print('🔵 Returned from Cash Deposit page with result: $result');
                    // Only refresh if deposit was successful
                    if (result == true && mounted) {
                      print('🔄 Refreshing cash data after successful deposit');
                      bloc.add(RefreshCashData()); // Use captured bloc reference
                    } else {
                      print('⚠️ Not refreshing - result: $result, mounted: $mounted');
                    }
                  },
                ),
              if (userRole?.contains('Cashier') ?? false)
                _buildBottomSheetOption(
                  icon: Icons.inventory_2_rounded,
                  title: 'Handover Cash',
                  subtitle: 'Handover cash to  Manager',
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet

                    // Capture bloc BEFORE async navigation
                    final bloc = context.read<CashManagementBloc>();

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: const HandoverScreen(),
                        ),
                      ),
                    );
                    // Only refresh if handover was successful
                    if (result == true && mounted) {
                      bloc.add(RefreshCashData()); // Use captured bloc reference
                    }
                  },
                ),
              if (!(userRole?.contains('Delivery Boy') ?? false))
                _buildBottomSheetOption(
                  icon: Icons.account_balance,
                  title: 'Bank Deposit',
                  subtitle: 'Deposit cash directly to bank',
                  onTap: () async {
                    Navigator.pop(context); // Close bottom sheet

                    // Capture bloc BEFORE async navigation
                    final bloc = context.read<CashManagementBloc>();

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: bloc,
                          child: const BankDepositScreen(),
                        ),
                      ),
                    );
                    // Only refresh if bank deposit was successful
                    if (result == true && mounted) {
                      bloc.add(RefreshCashData()); // Use captured bloc reference
                    }
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

  String _formatCurrency(double amount) {
    if (amount == 0.0) {
      return '₹0';
    }
    return currencyFormat.format(amount);
  }

}