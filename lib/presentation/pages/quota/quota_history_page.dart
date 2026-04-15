import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../blocs/quota_history/quota_history_bloc.dart';
import '../../blocs/quota_history/quota_history_event.dart';
import '../../blocs/quota_history/quota_history_state.dart';
import '../../widgets/quota/quota_aggregates_card.dart';
import '../../widgets/quota/quota_history_entry_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/service_provider.dart';
import '../../../domain/entities/quota/quota_history_aggregates.dart';
import '../../../domain/entities/quota/quota_history_filters.dart';
import '../../../domain/entities/quota/quota_history_response.dart';
import '../../../l10n/l10n_extensions.dart';

/// Main page for displaying quota history in a timeline view
class QuotaHistoryPage extends StatefulWidget {
  final String? pageTitle;
  final Map<String, String>? initialAvailableItems;

  const QuotaHistoryPage({
    Key? key,
    this.pageTitle,
    this.initialAvailableItems,
  }) : super(key: key);

  @override
  State<QuotaHistoryPage> createState() => _QuotaHistoryPageState();
}

class _QuotaHistoryPageState extends State<QuotaHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedItemCode; // null = all items
  Map<String, String> _availableItems = {}; // itemCode -> itemName cache

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initialize available items from widget if provided
    if (widget.initialAvailableItems != null) {
      _availableItems = Map.from(widget.initialAvailableItems!);
    }

    // Get initial item code from bloc if set
    final bloc = context.read<QuotaHistoryBloc>();
    _selectedItemCode = bloc.initialItemCode;

    // Load initial data
    bloc.add(const LoadQuotaHistory());

    // Always load all items in the background to populate filter chips if needed
    // This ensures filter chips show all available items, not just the filtered one
    if (widget.initialAvailableItems == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _loadAllItemsForCache();
        }
      });
    }
  }

  // Load all items (no filter) to populate the cache
  void _loadAllItemsForCache() async {
    try {
      final bloc = context.read<QuotaHistoryBloc>();
      final currentState = bloc.state;

      if (currentState is QuotaHistoryLoaded) {
        // Make API call without filter to get all items
        final apiService = await ServiceProvider.getApiService();
        final responseData = await apiService.getQuotaHistory(
          dateFrom: currentState.filters.dateFrom,
          dateTo: currentState.filters.dateTo,
          itemCode: null, // No filter - get ALL items
          sort: currentState.filters.sort,
          page: 1,
          pageSize: 30,
        );

        // Extract all available items and update cache
        final response = QuotaHistoryResponse.fromJson(responseData);
        if (mounted) {
          setState(() {
            for (final entry in response.results) {
              _availableItems[entry.itemCode] = entry.itemName;
            }
          });
        }
      }
    } catch (e) {
      // Silently fail - cache building is not critical
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<QuotaHistoryBloc>().add(const LoadMoreHistory());
    }
  }

  void _selectItemFilter(String? itemCode, QuotaHistoryState state) {
    setState(() {
      _selectedItemCode = itemCode;
    });

    if (state is QuotaHistoryLoaded) {
      final currentFilters = state.filters;
      final newFilters = QuotaHistoryFilters(
        dateFrom: currentFilters.dateFrom,
        dateTo: currentFilters.dateTo,
        itemCode: itemCode,
        sort: currentFilters.sort,
      );
      context.read<QuotaHistoryBloc>().add(UpdateHistoryFilters(newFilters));
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.translate('quotaHistoryFilterTitle'),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          SizedBox(height: 16.h),
          _buildFilterButton(context.l10n.translate('quotaHistoryFilterLast7Days'), QuotaHistoryFilters.last7Days()),
          SizedBox(height: 8.h),
          _buildFilterButton(context.l10n.translate('quotaHistoryFilterLast30Days'), QuotaHistoryFilters.last30Days()),
          SizedBox(height: 8.h),
          _buildFilterButton(context.l10n.translate('quotaHistoryFilterThisMonth'), QuotaHistoryFilters.thisMonth()),
          SizedBox(height: 8.h),
          _buildFilterButton(context.l10n.translate('quotaHistoryFilterLastMonth'), QuotaHistoryFilters.lastMonth()),
          SizedBox(height: 16.h),
          Divider(color: AppColors.lightGray),
          SizedBox(height: 8.h),
          _buildCustomRangeButton(),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, QuotaHistoryFilters filters) {
    return ElevatedButton(
      onPressed: () {
        // Preserve the current item filter when changing date range
        final preservedFilters = QuotaHistoryFilters(
          dateFrom: filters.dateFrom,
          dateTo: filters.dateTo,
          itemCode: _selectedItemCode, // Preserve item filter
          sort: filters.sort,
        );
        context.read<QuotaHistoryBloc>().add(UpdateHistoryFilters(preservedFilters));
        Navigator.pop(context);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brandBlue,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: AppColors.brandBlue),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCustomRangeButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        Navigator.pop(context);

        final DateTimeRange? pickedRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.brandBlue,
                ),
              ),
              child: child!,
            );
          },
        );

        if (pickedRange != null) {
          // Preserve the current item filter when changing date range
          final filters = QuotaHistoryFilters(
            dateFrom: pickedRange.start,
            dateTo: pickedRange.end,
            itemCode: _selectedItemCode, // Preserve item filter
          );
          if (mounted) {
            context.read<QuotaHistoryBloc>().add(UpdateHistoryFilters(filters));
          }
        }
      },
      icon: Icon(Icons.date_range, size: 20.sp),
      label: Text(
        context.l10n.translate('quotaHistoryFilterCustomRange'),
        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryText,
        padding: EdgeInsets.symmetric(vertical: 14.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.pageTitle ?? context.l10n.translate('quotaHistoryTitle'),
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, size: 24.sp),
            tooltip: 'Filter',
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: BlocBuilder<QuotaHistoryBloc, QuotaHistoryState>(
        builder: (context, state) {
          if (state is QuotaHistoryLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.brandBlue,
              ),
            );
          }

          if (state is QuotaHistoryError) {
            return _buildErrorState(state);
          }

          if (state is QuotaHistoryLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<QuotaHistoryBloc>().add(const LoadQuotaHistory(refresh: true));
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: AppColors.brandBlue,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Sticky Summary card
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SummaryHeaderDelegate(
                      aggregates: state.aggregates,
                      minHeight: 200.h,
                      maxHeight: 200.h,
                    ),
                  ),

                  // Item filter chips - sticky (only show when there are entries)
                  if (state.allEntries.isNotEmpty)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _FilterChipsHeaderDelegate(
                        state: state,
                        buildChips: () => _buildItemFilterChips(state),
                        minHeight: 58.h,
                        maxHeight: 58.h,
                      ),
                    ),

                  // Empty state
                  if (state.allEntries.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    ),

                  // Timeline entries (only show when there are entries)
                  if (state.allEntries.isNotEmpty)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index >= state.allEntries.length) {
                            return state.isLoadingMore
                                ? Padding(
                                    padding: EdgeInsets.all(16.h),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.brandBlue,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          }
                          final isLastItem = !state.hasMorePages &&
                                            index == state.allEntries.length - 1;
                          final isFirstItem = index == 0;
                          return QuotaHistoryEntryCard(
                            entry: state.allEntries[index],
                            isFirstItem: isFirstItem,
                            isLastItem: isLastItem,
                          );
                        },
                        childCount: state.allEntries.length + (state.hasMorePages ? 1 : 0),
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

  Widget _buildErrorState(QuotaHistoryError state) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: AppColors.errorRed,
            ),
            SizedBox(height: 16.h),
            Text(
              context.l10n.translate('quotaHistoryErrorLoadFailed'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: () {
                context.read<QuotaHistoryBloc>().add(const LoadQuotaHistory());
              },
              icon: Icon(Icons.refresh, size: 20.sp),
              label: Text(context.l10n.translate('commonRetryButton'), style: TextStyle(fontSize: 15.sp)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.secondaryText,
            ),
            SizedBox(height: 16.h),
            Text(
              context.l10n.translate('quotaHistoryEmptyTitle'),
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              context.l10n.translate('quotaHistoryEmptyMessage'),
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemFilterChips(QuotaHistoryState state) {
    if (state is! QuotaHistoryLoaded || state.allEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sync local state with bloc state
    final currentItemCode = state.filters.itemCode;
    if (_selectedItemCode != currentItemCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedItemCode = currentItemCode;
          });
        }
      });
    }

    // Always build/update available items cache from current entries
    // This ensures we have all items even when viewing filtered results
    for (final entry in state.allEntries) {
      _availableItems[entry.itemCode] = entry.itemName;
    }

    // ALWAYS show filter chips (don't check for single item)
    // This allows switching between items even when filtered

    // Group current filtered entries by item code for counts
    final itemGroups = <String, List<dynamic>>{};
    for (final entry in state.allEntries) {
      itemGroups.putIfAbsent(entry.itemCode, () => []).add(entry);
    }

    return Container(
      height: 50.h,
      margin: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        children: [
          // Individual item chips - use cached items OR from current entries
          ...(_availableItems.isEmpty
              ? itemGroups.entries.map((entry) {
                  final itemName = state.allEntries
                      .firstWhere((e) => e.itemCode == entry.key)
                      .itemName;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(
                      label: itemName,
                      itemCode: entry.key,
                      count: entry.value.length,
                      icon: Icons.inventory_2,
                      isSelected: currentItemCode == entry.key,
                      state: state,
                    ),
                  );
                })
              : _availableItems.entries.map((item) {
                  final count = itemGroups[item.key]?.length ?? 0;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(
                      label: item.value, // itemName from cache
                      itemCode: item.key, // itemCode
                      count: count,
                      icon: Icons.inventory_2,
                      isSelected: currentItemCode == item.key,
                      state: state,
                    ),
                  );
                })),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? itemCode,
    required int count,
    required IconData icon,
    required bool isSelected,
    required QuotaHistoryState state,
  }) {
    return InkWell(
      onTap: () => _selectItemFilter(itemCode, state),
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandBlue : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.brandBlue : AppColors.lightGray,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.brandBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? Colors.white : AppColors.secondaryText,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primaryText,
              ),
            ),
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : AppColors.lightGray,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Delegate for sticky summary header
class _SummaryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final QuotaHistoryAggregates aggregates;
  final double minHeight;
  final double maxHeight;

  _SummaryHeaderDelegate({
    required this.aggregates,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight.roundToDouble();

  @override
  double get maxExtent => minHeight.roundToDouble();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        color: Colors.grey[50],
        child: QuotaAggregatesCard(aggregates: aggregates),
      ),
    );
  }

  @override
  bool shouldRebuild(_SummaryHeaderDelegate oldDelegate) {
    return aggregates != oldDelegate.aggregates;
  }
}

/// Delegate for sticky filter chips header
class _FilterChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final QuotaHistoryState state;
  final Widget Function() buildChips;
  final double minHeight;
  final double maxHeight;

  _FilterChipsHeaderDelegate({
    required this.state,
    required this.buildChips,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight.roundToDouble();

  @override
  double get maxExtent => minHeight.roundToDouble();

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox(
      height: maxExtent,
      child: Container(
        color: Colors.grey[50],
        child: buildChips(),
      ),
    );
  }

  @override
  bool shouldRebuild(_FilterChipsHeaderDelegate oldDelegate) {
    return state != oldDelegate.state;
  }
}
