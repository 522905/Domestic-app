import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/utils/global_drawer.dart';
import '../../blocs/digital_credit/digital_credit_bloc.dart';
import '../../blocs/digital_credit/digital_credit_event.dart';
import '../../blocs/digital_credit/digital_credit_state.dart';
import 'widgets/credit_card_widget.dart';
import 'create_credit_page.dart';
import 'credit_detail_page.dart';
import 'pending_approvals_page.dart';

class DigitalCreditsListPage extends StatefulWidget {
  final int initialTab;

  const DigitalCreditsListPage({
    Key? key,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  State<DigitalCreditsListPage> createState() => _DigitalCreditsListPageState();
}

class _DigitalCreditsListPageState extends State<DigitalCreditsListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
    _loadTabData();
    _startPolling();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final state = context.read<DigitalCreditBloc>().state;
      if (state is DigitalCreditLoaded) {
        final hasProcessing = state.credits.any((c) => c.isProcessing);
        if (hasProcessing) {
          _loadTabData();
        }
      }
    });
  }

  void _onTabChanged() {
    // Fire on any tab change, including swipes
    if (!_tabController.indexIsChanging) {
      // Animation completed - load data for new tab
      _searchController.clear();
      _loadTabData();
    }
  }

  void _loadTabData() {
    final index = _tabController.index;
    final bloc = context.read<DigitalCreditBloc>();

    switch (index) {
      case 0: // All Credits
        bloc.add(const LoadDigitalCredits());
        break;
      case 1: // My Credits
        bloc.add(const FilterDigitalCredits(isMine: true));
        break;
      case 2: // Unclaimed
        bloc.add(const FilterDigitalCredits(claimStatus: 'UNCLAIMED'));
        break;
      case 3: // Pending Approvals
        bloc.add(const LoadPendingTransfers());
        break;
    }
  }

  void _onSearch(String query) {
    if (_tabController.index < 3) {
      // Not on Pending Approvals tab
      context.read<DigitalCreditBloc>().add(SearchDigitalCredits(query));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: const Text('Digital Credits'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Credits'),
            Tab(text: 'My Credits'),
            Tab(text: 'Unclaimed'),
            Tab(text: 'Pending Approvals'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar (not shown on Pending Approvals tab)
          if (_tabController.index < 3)
            Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.grey.shade50,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by order ID or consumer name',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _onSearch,
              ),
            ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreditsListTab(), // All Credits
                _buildCreditsListTab(), // My Credits
                _buildCreditsListTab(), // Unclaimed
                _buildPendingApprovalsTab(), // Pending Approvals
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateCreditPage()),
          );
        },
        backgroundColor: const Color(0xFF0E5CA8),
        label: const Text('Create Credit'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCreditsListTab() {
    return BlocBuilder<DigitalCreditBloc, DigitalCreditState>(
      builder: (context, state) {
        if (state is DigitalCreditLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is DigitalCreditLoaded) {
          // Wrap both empty and loaded states with RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              // Clear search and reload current tab
              _searchController.clear();
              _loadTabData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: state.credits.isEmpty
                ? _buildEmptyStateScrollable()
                : _buildCreditsList(state.credits),
          );
        } else if (state is DigitalCreditError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: _loadTabData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPendingApprovalsTab() {
    return BlocBuilder<DigitalCreditBloc, DigitalCreditState>(
      builder: (context, state) {
        if (state is TransfersLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TransfersLoaded) {
          // Wrap both empty and loaded states with RefreshIndicator
          return RefreshIndicator(
            onRefresh: () async {
              // Reload current tab (Pending Approvals)
              _loadTabData();
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: state.transfers.isEmpty
                ? _buildEmptyTransfersScrollable()
                : _buildTransfersList(state.transfers),
          );
        } else if (state is DigitalCreditError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60.sp, color: Colors.red),
                SizedBox(height: 16.h),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),
                ElevatedButton(
                  onPressed: () {
                    context.read<DigitalCreditBloc>().add(const LoadPendingTransfers());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyTransfersScrollable() {
    // Wrap empty transfers state in ListView to enable pull-to-refresh
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80.sp,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: 16.h),
              Text(
                'No Pending Approvals',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'You\'re all caught up!',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransfersList(List transfers) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: transfers.length + 1,
      itemBuilder: (context, index) {
        if (index == transfers.length) {
          // View all button
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: TextButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PendingApprovalsPage(),
                  ),
                );
                // Reload transfers when returning
                _loadTabData();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Approvals'),
            ),
          );
        }

        final transfer = transfers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Icon(Icons.swap_horiz, color: Colors.purple.shade700),
            ),
            title: Text('Order: ${transfer.orderId}'),
            subtitle: Text('From: ${transfer.toUserName}'),
            trailing: Text(
              '₹${transfer.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0E5CA8),
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingApprovalsPage(),
                ),
              );
              // Reload transfers when returning
              _loadTabData();
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateScrollable() {
    // Wrap empty state in ListView to enable pull-to-refresh
    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        _buildEmptyState(),
      ],
    );
  }

  Widget _buildCreditsList(List credits) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        return CreditCardWidget(
          credit: credit,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreditDetailPage(creditId: credit.id),
              ),
            );
            // Reload current tab data when returning
            _loadTabData();
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    String description;

    switch (_tabController.index) {
      case 0:
        message = 'No Digital Credits';
        description = 'Create a credit after completing a digital payment delivery';
        break;
      case 1:
        message = 'No Credits';
        description = 'Credits you create will appear here';
        break;
      case 2:
        message = 'No Unclaimed Credits';
        description = 'All credits have been claimed';
        break;
      default:
        message = 'No Data';
        description = '';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80.sp,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.w),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
