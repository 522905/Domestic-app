import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/bonus_list/bonus_list_bloc.dart';
import '../../blocs/bonus_list/bonus_list_event.dart';
import '../../blocs/bonus_list/bonus_list_state.dart';
import '../../widgets/bonus/bonus_list_item_card.dart';
import '../../widgets/bonus/bonus_summary_stats_card.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../../presentation/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';

/// Page to display list of bonuses with filtering and pagination
class BonusListPage extends StatefulWidget {
  final String? initialStatus;

  const BonusListPage({
    Key? key,
    this.initialStatus,
  }) : super(key: key);

  @override
  State<BonusListPage> createState() => _BonusListPageState();
}

class _BonusListPageState extends State<BonusListPage> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  String _selectedStatus = 'all';

  final List<Map<String, String>> _statusTabs = [
    {'status': 'all', 'labelKey': 'bonusFilterAll'},
    {'status': 'active', 'labelKey': 'bonusFilterActive'},
    {'status': 'consumed', 'labelKey': 'bonusFilterConsumed'},
    {'status': 'expired', 'labelKey': 'bonusFilterExpired'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize selected status from widget parameter
    if (widget.initialStatus != null) {
      _selectedStatus = widget.initialStatus!;
    }

    // Find initial tab index
    final initialTabIndex = _statusTabs.indexWhere((tab) => tab['status'] == _selectedStatus);
    _tabController = TabController(
      length: _statusTabs.length,
      vsync: this,
      initialIndex: initialTabIndex >= 0 ? initialTabIndex : 0,
    );

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<BonusListBloc>().add(const LoadMoreBonuses());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onTabChanged(int index) {
    final newStatus = _statusTabs[index]['status']!;
    setState(() {
      _selectedStatus = newStatus;
    });
    context.read<BonusListBloc>().add(UpdateBonusStatus(newStatus));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.bonusListTitle, style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp),
            onPressed: () {
              context.read<BonusListBloc>().add(const RefreshBonusList());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabChanged,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.normal,
          ),
          tabs: _statusTabs.map((tab) => Tab(text: context.l10n.translate(tab['labelKey']!))).toList(),
        ),
      ),
      body: BlocBuilder<BonusListBloc, BonusListState>(
        builder: (context, state) {
          if (state is BonusListLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BonusListError) {
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
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<BonusListBloc>().add(const LoadBonusList());
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text(context.l10n.translate('commonRetryButton')),
                  ),
                ],
              ),
            );
          } else if (state is BonusListLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BonusListBloc>().add(const RefreshBonusList());
              },
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Summary Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: BonusSummaryStatsCard(summary: state.summary),
                    ),
                  ),

                  // Bonus List
                  if (state.allBonuses.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 60.sp, color: Colors.grey),
                            SizedBox(height: 16.h),
                            Text(
                              _getEmptyMessage(context, _selectedStatus),
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index >= state.allBonuses.length) {
                              return _buildLoadingIndicator(state.isLoadingMore);
                            }
                            final bonus = state.allBonuses[index];
                            return BonusListItemCard(
                              bonus: bonus,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.bonusDetail,
                                  arguments: bonus.id,
                                );
                              },
                            );
                          },
                          childCount: state.allBonuses.length + (state.hasMorePages ? 1 : 0),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(bool isLoadingMore) {
    if (!isLoadingMore) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  String _getEmptyMessage(BuildContext context, String status) {
    switch (status) {
      case 'active':
        return context.l10n.translate('bonusEmptyActive');
      case 'consumed':
        return context.l10n.translate('bonusEmptyConsumed');
      case 'expired':
        return context.l10n.translate('bonusEmptyExpired');
      default:
        return context.l10n.translate('bonusEmptyGeneric');
    }
  }
}
