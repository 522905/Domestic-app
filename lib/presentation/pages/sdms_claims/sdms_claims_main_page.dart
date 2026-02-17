import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/sdms_claims/sdms_order.dart';
import '../../blocs/sdms_claims/sdms_claims_bloc.dart';
import '../../blocs/sdms_claims/sdms_claims_event.dart';
import '../../blocs/sdms_claims/sdms_claims_state.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional/professional_search_bar.dart';
import '../../widgets/professional/professional_status_badge.dart';
import '../../widgets/shimmer/order_card_shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';

class SdmsClaimsMainPage extends StatefulWidget {
  const SdmsClaimsMainPage({Key? key}) : super(key: key);

  @override
  State<SdmsClaimsMainPage> createState() => _SdmsClaimsMainPageState();
}

class _SdmsClaimsMainPageState extends State<SdmsClaimsMainPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  Timer? _pollingTimer;
  Timer? _debounceTimer;
  late TabController _tabController;
  bool _filterBeneficiary = false; // Hot fix 2026-02-12: Beneficiary filter state

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Load active orders on page load
    context.read<SdmsClaimsBloc>().add(const LoadSdmsOrders(tab: OrderTab.active));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pollingTimer?.cancel();
    _debounceTimer?.cancel();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = _tabController.index == 0 ? OrderTab.active : OrderTab.history;
      _searchController.clear();
      // Hot fix 2026-02-12: Keep filter when switching tabs (or clear it - user preference)
      context.read<SdmsClaimsBloc>().add(LoadSdmsOrders(
        tab: tab,
        isBeneficiary: _filterBeneficiary ? true : null,
      ));
    }
  }

  void _navigateToOrderEntry() async {
    // Navigate to order entry page
    await Navigator.pushNamed(context, '/sdms-claims/entry');

    // Reload orders when coming back (in case new order was created)
    if (mounted) {
      _loadOrders();
    }
  }

  void _loadOrders() {
    final tab = _tabController.index == 0 ? OrderTab.active : OrderTab.history;
    context.read<SdmsClaimsBloc>().add(LoadSdmsOrders(
      tab: tab,
      isBeneficiary: _filterBeneficiary ? true : null,
    ));
  }

  void _startPolling(List<SdmsOrder> orders) {
    _pollingTimer?.cancel();

    // Only poll active tab for RPA updates
    if (_tabController.index != 0) return;

    // Check if any order is in progress
    final hasInProgressOrders = orders.any(
      (order) => order.dataStatus == 'QUEUED' || order.dataStatus == 'PROCESSING',
    );

    if (hasInProgressOrders) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        // Silent refresh
        context.read<SdmsClaimsBloc>().add(const LoadSdmsOrders(tab: OrderTab.active));
      });
    }
  }

  void _onSearch(String query) {
    // Debounce search (300ms)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final tab = _tabController.index == 0 ? OrderTab.active : OrderTab.history;
      context.read<SdmsClaimsBloc>().add(LoadSdmsOrders(
        tab: tab,
        page: 1,
        searchQuery: query.isEmpty ? null : query,
        isBeneficiary: _filterBeneficiary ? true : null, // Hot fix 2026-02-12: Include filter
      ));
    });
  }

  void _onOrderTap(SdmsOrder order) async {
    // Navigate to detail page
    await Navigator.pushNamed(
      context,
      '/sdms-claims/order/${order.id}',
    );

    // Reload orders when coming back from detail page
    if (mounted) {
      _loadOrders();
    }
  }

  void _loadMoreHistory() {
    final currentState = context.read<SdmsClaimsBloc>().state;
    if (currentState is OrdersLoaded && currentState.hasMorePages) {
      context.read<SdmsClaimsBloc>().add(LoadSdmsOrders(
        tab: OrderTab.history,
        page: currentState.currentPage + 1,
        searchQuery: currentState.searchQuery,
        isBeneficiary: currentState.isBeneficiary, // Hot fix 2026-02-12: Preserve filter
      ));
    }
  }

  // Hot fix 2026-02-12: Beneficiary filter toggle
  void _toggleBeneficiaryFilter() {
    setState(() {
      _filterBeneficiary = !_filterBeneficiary;
    });
    _loadOrders();
  }

  // Hot fix 2026-02-12: Show filter menu
  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20.r),
          ),
        ),
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              context.l10n.translate('sdmsClaimsFilterOrdersTitle'),
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Beneficiary filter toggle
            InkWell(
              onTap: () {
                _toggleBeneficiaryFilter();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: _filterBeneficiary
                      ? AppColorsEnhanced.brandBlue.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: _filterBeneficiary
                        ? AppColorsEnhanced.brandBlue
                        : AppColorsEnhanced.border,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _filterBeneficiary
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: _filterBeneficiary
                          ? AppColorsEnhanced.brandBlue
                          : AppColorsEnhanced.secondaryText,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.translate('sdmsClaimsMyPartnerOrdersLabel'),
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: _filterBeneficiary
                                  ? AppColorsEnhanced.brandBlue
                                  : AppColorsEnhanced.primaryText,
                            ),
                          ),
                          SizedBox(height: AppSpacing.xs),
                          Text(
                            context.l10n.translate('sdmsClaimsMyPartnerOrdersDescription'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.md),

            // Clear filter button
            if (_filterBeneficiary)
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterBeneficiary = false;
                  });
                  _loadOrders();
                  Navigator.pop(context);
                },
                child: Text(context.l10n.translate('sdmsClaimsClearFilterButton')),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsEnhanced.background,
      appBar: AppBar(
        title: Text(context.l10n.translate('sdmsClaimsMyOrdersTitle'), style: AppTextStyles.h2),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadOrders,
            tooltip: context.l10n.translate('commonRefreshTooltip'),
          ),
          SizedBox(width: AppSpacing.xs),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          tabs: [
            Tab(text: context.l10n.translate('sdmsClaimsActiveTabLabel')),
            Tab(text: context.l10n.translate('sdmsClaimsHistoryTabLabel')),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: AppColorsEnhanced.background,
            padding: EdgeInsets.all(AppSpacing.md),
            child: ProfessionalSearchBar(
              controller: _searchController,
              hintText: context.l10n.translate('sdmsClaimsSearchHintText'),
              onChanged: _onSearch,
              onFilter: _showFilterMenu, // Hot fix 2026-02-12: Add filter button
            ),
          ),

          // Hot fix 2026-02-12: Filter indicator chip
          if (_filterBeneficiary)
            Container(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  Chip(
                    label: Text(context.l10n.translate('sdmsClaimsMyPartnerOrdersLabel')),
                    onDeleted: () {
                      setState(() {
                        _filterBeneficiary = false;
                      });
                      _loadOrders();
                    },
                    deleteIcon: Icon(Icons.close, size: 16.sp),
                    backgroundColor: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                    labelStyle: AppTextStyles.labelSmall.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Tab view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Active tab
                _buildOrderList(isActiveTab: true),
                // History tab
                _buildOrderList(isActiveTab: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToOrderEntry,
        icon: const Icon(Icons.add),
        label: Text(context.l10n.translate('sdmsClaimsNewOrderButtonLabel')),
        backgroundColor: AppColorsEnhanced.brandBlue,
      ),
    );
  }

  Widget _buildOrderList({required bool isActiveTab}) {
    return BlocConsumer<SdmsClaimsBloc, SdmsClaimsState>(
      listener: (context, state) {
        if (state is OrdersLoaded && isActiveTab) {
          _startPolling(state.orders);
        }
        if (state is OrderCreated) {
          // Refresh list when new order created
          _loadOrders();
        }
      },
      builder: (context, state) {
        if (state is SdmsClaimsLoading) {
          return ListView.separated(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: 5,  // Show 5 placeholder cards
            separatorBuilder: (context, index) => SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) => const OrderCardShimmer(),
          );
        }

        if (state is SdmsClaimsError) {
          return ProfessionalEmptyState(
            icon: Icons.error_outline,
            message: state.message,
            description: 'Please try again',
            actionText: context.l10n.translate('commonRetryButton'),
            onAction: _loadOrders,
          );
        }

        if (state is OrdersLoaded) {
          // Only show this tab's data
          final expectedTab = isActiveTab ? OrderTab.active : OrderTab.history;
          if (state.currentTab != expectedTab) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColorsEnhanced.brandBlue,
              ),
            );
          }

          if (state.orders.isEmpty) {
            return ProfessionalEmptyState(
              icon: Icons.inbox_outlined,
              message: isActiveTab ? context.l10n.translate('sdmsClaimsNoActiveOrdersEmptyTitle') : context.l10n.translate('sdmsClaimsNoOrderHistoryEmptyTitle'),
              description: isActiveTab
                  ? context.l10n.translate('sdmsClaimsNoActiveOrdersEmptyDescription')
                  : context.l10n.translate('sdmsClaimsNoOrderHistoryEmptyDescription'),
              actionText: null,
              onAction: null,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadOrders();
              await Future.delayed(const Duration(seconds: 1));
            },
            color: AppColorsEnhanced.brandBlue,
            child: ListView.separated(
              padding: EdgeInsets.all(AppSpacing.md),
              itemCount: state.orders.length + (state.hasMorePages ? 1 : 0),
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                // Load more indicator for history tab
                if (index == state.orders.length) {
                  _loadMoreHistory();
                  return Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColorsEnhanced.brandBlue,
                      ),
                    ),
                  );
                }

                final order = state.orders[index];
                return _OrderCard(
                  order: order,
                  onTap: () => _onOrderTap(order),
                );
              },
            ),
          );
        }

        // For other states, show loading
        return Center(
          child: CircularProgressIndicator(
            color: AppColorsEnhanced.brandBlue,
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatefulWidget {
  final SdmsOrder order;
  final VoidCallback onTap;

  const _OrderCard({
    Key? key,
    required this.order,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  Color _getAccentColor() {
    final pendingTransferSummary = widget.order.pendingTransferSummary;
    final isActionable = pendingTransferSummary?.isActionableByMe ?? false;

    if (isActionable) return AppColorsEnhanced.warningYellow;
    if (widget.order.isRpaInProgress) return AppColorsEnhanced.infoBlue;
    if (widget.order.isClaimed) return AppColorsEnhanced.successGreen;
    return AppColorsEnhanced.border;
  }

  Color _getStatusColor() {
    if (widget.order.isRpaInProgress) return AppColorsEnhanced.secondaryText;

    // v1.6: Different colors for different error categories
    if (widget.order.isFailed) {
      if (widget.order.isRejectedError) {
        return AppColorsEnhanced.secondaryText; // Greyed out for permanent failures
      }
      return AppColorsEnhanced.errorRed;
    }

    if (widget.order.isIncident) return AppColorsEnhanced.warningYellow;
    if (widget.order.isPendingCompletion) return AppColorsEnhanced.warningYellow;
    if (widget.order.isUnclaimed) return AppColorsEnhanced.infoBlue;
    if (widget.order.isPendingApproval) return AppColorsEnhanced.warningYellow;
    if (widget.order.isClaimed) return AppColorsEnhanced.successGreen;
    if (widget.order.isRejected) return AppColorsEnhanced.errorRed;
    return AppColorsEnhanced.secondaryText;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM');
    final pendingTransferSummary = widget.order.pendingTransferSummary;
    final isActionable = pendingTransferSummary?.isActionableByMe ?? false;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onTap,
        child: Material(
          color: isActionable
              ? AppColorsEnhanced.warningYellow.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: _getAccentColor(),
                  width: 4,
                ),
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT/RIGHT SPLIT LAYOUT
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (60% width)
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Consumer name
                          Text(
                            widget.order.consumerName ?? 'Unknown Consumer',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: AppSpacing.xs / 2),

                          // Beneficiary badge
                          if (widget.order.isBeneficiary == true)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 9.sp,
                                    color: AppColorsEnhanced.brandBlue,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    context.l10n.translate('sdmsClaimsMyPartnerBadgeLabel'),
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColorsEnhanced.brandBlue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 9.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (widget.order.isBeneficiary == true)
                            SizedBox(height: AppSpacing.xs / 2),

                          // REL ID
                          if (widget.order.consumerNumber != null)
                            Text(
                              widget.order.consumerNumber!,
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColorsEnhanced.secondaryText,
                                fontSize: 11.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),

                          SizedBox(height: AppSpacing.xs / 2),

                          // Category
                          Text(
                            widget.order.categoryDisplay.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: AppSpacing.sm),

                    // VERTICAL DIVIDER
                    Container(
                      width: 1,
                      height: 70.h,
                      color: AppColorsEnhanced.border.withOpacity(0.3),
                    ),

                    SizedBox(width: AppSpacing.sm),

                    // RIGHT COLUMN (40% width)
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Amount
                          if (widget.order.amount != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.currency_rupee_rounded,
                                  size: 14.sp,
                                  color: AppColorsEnhanced.successGreen,
                                ),
                                Text(
                                  widget.order.amount!.toStringAsFixed(0),
                                  style: AppTextStyles.h4.copyWith(
                                    color: AppColorsEnhanced.successGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                          SizedBox(height: AppSpacing.xs),

                          // Date
                          if (widget.order.orderDate != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 10.sp,
                                  color: AppColorsEnhanced.secondaryText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateFormat.format(widget.order.orderDate!),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColorsEnhanced.secondaryText,
                                    fontSize: 10.sp,
                                  ),
                                ),
                              ],
                            ),

                          SizedBox(height: AppSpacing.xs),

                          // Order ID (short)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                size: 10.sp,
                                color: AppColorsEnhanced.secondaryText,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '#${widget.order.orderId.length > 10 ? widget.order.orderId.substring(widget.order.orderId.length - 10) : widget.order.orderId}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColorsEnhanced.secondaryText,
                                    fontSize: 10.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: AppSpacing.xs),

                          // Payment mode
                          Text(
                            widget.order.paymentModeDisplay.toUpperCase(),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // FULL WIDTH BOTTOM: Status/Transfer
                if (pendingTransferSummary != null || !widget.order.isClaimed) ...[
                  SizedBox(height: AppSpacing.sm),
                  if (pendingTransferSummary != null)
                    _buildCompactTransferIndicator(pendingTransferSummary)
                  else
                    ProfessionalStatusBadge(
                      status: widget.order.getCombinedStatusDisplay(),
                      color: _getStatusColor(),
                      size: BadgeSize.small,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTransferIndicator(dynamic summary) {
    if (summary.isActionableByMe) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: AppColorsEnhanced.warningYellow.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.priority_high_rounded,
              size: 14.sp,
              color: AppColorsEnhanced.warningYellow,
            ),
            SizedBox(width: AppSpacing.xs / 2),
            Expanded(
              child: Text(
                '${summary.toUserName} wants to claim',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsEnhanced.warningYellow,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              summary.timeRemainingDisplay,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 9.sp,
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      'Pending on ${widget.order.originalDeliveryBoyName ?? 'Unknown'}',
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColorsEnhanced.secondaryText,
        fontSize: 10.sp,
      ),
    );
  }
}
