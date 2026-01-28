import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';
import 'package:lpg_distribution_app/core/services/service_provider.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_event.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_state.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota_history/quota_history_bloc.dart';
import 'package:lpg_distribution_app/presentation/pages/quota/quota_history_page.dart';
import 'package:lpg_distribution_app/presentation/widgets/dashboard/bonus_summary_card.dart';
import 'package:lpg_distribution_app/domain/entities/quota/quota_snapshot.dart';
import 'package:lpg_distribution_app/l10n/l10n_extensions.dart';

class QuotaSnapshotPage extends StatelessWidget {
  const QuotaSnapshotPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Quota Status', style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.history, size: 24.sp),
          //   tooltip: 'View History',
          //   onPressed: () async {
          //     final apiService = await ServiceProvider.getApiService();
          //     if (context.mounted) {
          //       Navigator.push(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => BlocProvider(
          //             create: (_) => QuotaHistoryBloc(
          //               apiService: apiService,
          //               initialItemCode: 'M00087', // Always default to 14.2 KG Cylinder
          //             ),
          //             child: QuotaHistoryPage(
          //               pageTitle: context.l10n.translate('quotaHistoryTitle'),
          //             ),
          //           ),
          //         ),
          //       );
          //     }
          //   },
          // ),
          SizedBox(width: 58.h),
          IconButton(
            icon: Icon(Icons.refresh, size: 24.sp),
            onPressed: () {
              context.read<QuotaBloc>().add(RefreshQuotaSnapshot());
            },
          ),
        ],
      ),
      body: BlocBuilder<QuotaBloc, QuotaState>(
        builder: (context, state) {
          if (state is QuotaLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.brandBlue),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading quota data...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is QuotaError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        color: AppColors.errorRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isAccessDenied ? Icons.block : Icons.error_outline,
                        size: 64.sp,
                        color: AppColors.errorRed,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.primaryText,
                      ),
                    ),
                    if (!state.isAccessDenied) ...[
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<QuotaBloc>().add(LoadQuotaSnapshot());
                        },
                        icon: Icon(Icons.refresh, size: 20.sp),
                        label: Text('Retry', style: TextStyle(fontSize: 16.sp)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          if (state is QuotaLoaded || state is QuotaSyncInProgress) {
            final snapshot = state is QuotaLoaded
                ? state.snapshot
                : (state as QuotaSyncInProgress).snapshot;

            final isSyncing = state is QuotaSyncInProgress;

            return ListView(
              padding: EdgeInsets.all(10.w),
              children: [
                // Partner Header Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.brandBlue.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandBlue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(10.w),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.account_circle,
                          size: 32.sp,
                          color: AppColors.brandBlue,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              snapshot.partnerName,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryText,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Code: ${snapshot.partnerCode}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),
                // Bonus Summary Card - Only show if there are bonuses
                if (_hasBonuses(snapshot)) ...[
                  BonusSummaryCard(snapshot: snapshot),
                  SizedBox(height: 16.h),
                ],
                // Sync Status Banner
                if (isSyncing)
                  Container(
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.infoBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.infoBlue,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Syncing with SDMS...',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.infoBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Items Section Header
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    'Quota Items (${snapshot.items.length})',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),

                // Items List
                ...snapshot.items.map((item) {
                  final isBlocked = item.isBlocked;
                  final isZeroBalance = item.availableBalance == 0;
                  final cardColor = isBlocked
                      ? AppColors.errorRed
                      : (isZeroBalance ? Colors.grey : AppColors.brandBlue);

                  return Opacity(
                    opacity: isZeroBalance ? 0.6 : 1.0,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 12.h),
                      decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: cardColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Header
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: cardColor.withOpacity(0.05),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16.r),
                              topRight: Radius.circular(16.r),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 24.sp,
                                  color: cardColor,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.itemName,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryText,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    GestureDetector(
                                      onTap: () async {
                                        // Navigate to Quota History with item filter
                                        final apiService = await ServiceProvider.getApiService();

                                        // Collect all available items to pass to history page
                                        final availableItems = <String, String>{};
                                        for (final snapshotItem in snapshot.items) {
                                          availableItems[snapshotItem.itemCode] = snapshotItem.itemName;
                                        }

                                        if (context.mounted) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BlocProvider(
                                                create: (_) => QuotaHistoryBloc(
                                                  apiService: apiService,
                                                  initialItemCode: item.itemCode, // Pre-filter by this item
                                                ),
                                                child: QuotaHistoryPage(
                                                  pageTitle: '${item.itemName} - ${context.l10n.translate('quotaHistoryTitle')}',
                                                  initialAvailableItems: availableItems, // Pass available items
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.history,
                                            size: 12.sp,
                                            color: AppColors.brandBlue,
                                          ),
                                          SizedBox(width: 4.w),
                                          Text(
                                            'View History',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: AppColors.brandBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isBlocked)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed,
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    'BLOCKED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (isZeroBalance && !isBlocked)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    borderRadius: BorderRadius.circular(20.r),
                                  ),
                                  child: Text(
                                    'NO Quota Available ',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Item Details
                        Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            children: [
                              // KEY BALANCES CARD - Highlighted at top
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section Header
                                  Row(
                                    children: [
                                      Icon(Icons.account_balance_wallet, size: 20.sp, color: AppColors.brandBlue),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'KEY BALANCES',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandBlue,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Divider(color: AppColors.brandBlue.withOpacity(0.3), height: 20.h),

                                  // Bonus
                                  _buildKeyBalanceRow(
                                    icon: Icons.card_giftcard,
                                    label: 'Bonus',
                                    value: item.bonus,
                                    fontSize: 14.sp,
                                  ),

                                  SizedBox(height: 12.h),

                                  // Credit Limit
                                  _buildKeyBalanceRow(
                                    icon: Icons.credit_card,
                                    label: 'Credit Limit',
                                    value: item.creditLimit,
                                    fontSize: 14.sp,
                                  ),

                                  SizedBox(height: 10.h),

                                  // Available Balance - BIGGEST
                                  Container(
                                    padding: EdgeInsets.all(8.w),
                                    decoration: BoxDecoration(
                                      color: isBlocked
                                          ? AppColors.errorRed.withOpacity(0.15)
                                          : AppColors.successGreen.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isBlocked ? Icons.warning : Icons.check_circle,
                                              size: 24.sp,
                                              color: isBlocked ? AppColors.errorRed : AppColors.successGreen,
                                            ),
                                            SizedBox(width: 10.w),

                                            Text(
                                              'Available',
                                              style: TextStyle(
                                                fontSize: 16.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Divider(color: AppColors.brandBlue.withOpacity(0.3), height: 20.h),
                                        Text(
                                          '${item.availableBalance}',
                                          style: TextStyle(
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isBlocked
                                                ? AppColors.errorRed
                                                : AppColors.successGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 8.h),

                              // TRANSACTION DETAILS - Always visible
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section Header
                                  Row(
                                    children: [
                                      Icon(Icons.timeline, size: 20.sp, color: AppColors.primaryText),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'TRANSACTION DETAILS',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryText,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: 2.h),

                                  // Transaction rows
                                  _buildTransactionRow(
                                    icon: Icons.start,
                                    label: 'Opening',
                                    value: item.opening,
                                    color: Colors.blue,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.tune,
                                    label: 'Adjustment',
                                    value: item.adjustment,
                                    color: item.adjustment >= 0 ? AppColors.successGreen : AppColors.errorRed,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.shopping_cart,
                                    label: 'Orders',
                                    value: item.orders,
                                    color: item.orders < 0 ? AppColors.errorRed : AppColors.secondaryText,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.local_shipping,
                                    label: 'Pickups',
                                    value: item.pickups,
                                    color: item.pickups < 0 ? AppColors.errorRed : AppColors.secondaryText,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.keyboard_return,
                                    label: 'Returns',
                                    value: item.returns,
                                    color: item.returns > 0 ? AppColors.successGreen : AppColors.secondaryText,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.point_of_sale,
                                    label: 'SDMS Sales',
                                    value: item.sdmsSales,
                                    color: item.sdmsSales > 0 ? AppColors.successGreen : AppColors.secondaryText,
                                  ),
                                  _buildTransactionRow(
                                    icon: Icons.inventory,
                                    label: 'Closing',
                                    value: item.closing,
                                    color: Colors.blue,
                                    isBold: true,
                                  ),
                                ],
                              ),

                              SizedBox(height: 5.h),

                              // HOW IT'S CALCULATED Section - Collapsible
                              Theme(
                                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  tilePadding: EdgeInsets.zero,
                                  childrenPadding: EdgeInsets.only(top: 4.h),
                                  title: Row(
                                    children: [
                                      Icon(Icons.info_outline, size: 18.sp, color: Colors.blue[700]),
                                      SizedBox(width: 8.w),
                                      Text(
                                        'HOW IT\'S CALCULATED',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12.w),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: Border.all(color: Colors.blue[200]!, width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Formula 1: Closing
                                          Text(
                                            'Closing = Opening + Adj - Orders - Pickups + Returns + SDMS',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.blue[900],
                                              fontFamily: 'monospace',
                                            ),
                                          ),

                                          SizedBox(height: 6.h),

                                          // Formula 2: Available
                                          Text(
                                            'Available = Closing + Bonus + Credit Limit',
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              color: Colors.blue[900],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Blocked Warning
                              if (isBlocked) ...[
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorRed,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.block,
                                        size: 20.sp,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          'BLOCKED - Deficit: ${item.deficit}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                );
                }).toList(),

                SizedBox(height: 16.h),

                // Sync Status Card (at bottom)
                _buildSyncStatusCard(snapshot),

                SizedBox(height: 16.h), // Bottom spacing
              ],
            );
          }

          return Center(
            child: Text(
              'No data available',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.secondaryText,
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper: Key Balance Row (for Bonus, Credit Limit in highlighted card)
  Widget _buildKeyBalanceRow({
    required IconData icon,
    required String label,
    required int value,
    required double fontSize,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.sp, color: AppColors.brandBlue),
            SizedBox(width: 10.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
          ),
        ),
      ],
    );
  }

  // Helper: Transaction Row (for Opening, Adjustment, Orders, etc.)
  Widget _buildTransactionRow({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: AppColors.primaryText,
              ),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: isBold ? 16.sp : 14.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to format DateTime to relative time string
  String _getRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return 'Never';

    final diff = DateTime.now().difference(dateTime);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
  }

  // Helper method to get color based on staleness
  Color _getSyncStatusColor(DateTime? lastSync) {
    if (lastSync == null) return Colors.grey;

    final diff = DateTime.now().difference(lastSync);

    if (diff.inMinutes <= 30) return Colors.green;
    if (diff.inMinutes <= 60) return Colors.orange;
    return AppColors.errorRed;
  }

  // Build the overall sync status card
  Widget _buildSyncStatusCard(snapshot) {
    final syncColor = _getSyncStatusColor(snapshot.lastSync);
    final relativeTime = _getRelativeTime(snapshot.lastSync);
    final isStale = snapshot.isStale;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: syncColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: syncColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: syncColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sync, size: 20.sp, color: syncColor),
              ),
              SizedBox(width: 2.w),
              Text(
                'SYNC STATUS',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  letterSpacing: 0.5,
                ),
              ),
              Spacer(),
              // Sync SDMS Button
              BlocBuilder<QuotaBloc, QuotaState>(
                builder: (context, state) {
                  final isSyncing = state is QuotaSyncInProgress;
                  return ElevatedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () async {
                            try {
                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.brandBlue,
                                  ),
                                ),
                              );

                              // Get API service
                              final apiService = await ServiceProvider.getApiService();
                              final response = await apiService.triggerQuotaSync();

                              // Close loading
                              if (context.mounted) Navigator.of(context).pop();

                              // Show response dialog
                              if (context.mounted) _showSyncResponseDialog(context, response);

                              // Refresh quota snapshot
                              if (context.mounted) {
                                context.read<QuotaBloc>().add(RefreshQuotaSnapshot());
                              }
                            } catch (e) {
                              // Close loading
                              if (context.mounted) Navigator.of(context).pop();

                              // Show error dialog
                              if (context.mounted) {
                                _showSyncResponseDialog(
                                  context,
                                  {
                                    'success': false,
                                    'message': 'Sync failed',
                                    'error': e.toString(),
                                  },
                                );
                              }
                            }
                          },
                    icon: isSyncing
                        ? SizedBox(
                            width: 14.sp,
                            height: 14.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(Icons.sync, size: 14.sp),
                    label: Text(
                      isSyncing ? 'Syncing...' : 'Sync SDMS',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      elevation: 0,
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 5.h),

          // Last Sync Time
          Row(
            children: [
              Icon(Icons.access_time, size: 16.sp, color: AppColors.secondaryText),
              SizedBox(width: 8.w),
              Text(
                'Last synced: ',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                relativeTime,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: syncColor,
                ),
              ),
            ],
          ),

          // Company Sync Details
          if (snapshot.syncStatus.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Divider(color: Colors.grey[300]),
            SizedBox(height: 8.h),
            Text(
              'Company Sync Details',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
            SizedBox(height: 12.h),
            ...snapshot.syncStatus.map((company) => _buildCompanySyncItem(company)),
          ],
        ],
      ),
    );
  }

  // Build individual company sync item
  Widget _buildCompanySyncItem(company) {
    final canSync = company.canSync;
    final syncColor = canSync ? Colors.green : Colors.orange;
    final relativeTime = _getRelativeTime(company.lastSync);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: syncColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: syncColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Name
          Row(
            children: [
              Icon(Icons.business, size: 16.sp, color: syncColor),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  company.companyName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Last Sync
          Row(
            children: [
              SizedBox(width: 24.w), // Align with company name
              Icon(Icons.schedule, size: 12.sp, color: AppColors.secondaryText),
              SizedBox(width: 4.w),
              Text(
                'Last sync: ',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.secondaryText,
                ),
              ),
              Text(
                relativeTime,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Sync Status
          Row(
            children: [
              SizedBox(width: 24.w), // Align with company name
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: syncColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      canSync ? Icons.check_circle : Icons.schedule,
                      size: 12.sp,
                      color: syncColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      canSync
                          ? 'Can sync now'
                          : 'Wait ${company.secondsUntilSync}s',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: syncColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Show sync response dialog
  void _showSyncResponseDialog(BuildContext context, Map<String, dynamic> response) {
    final status = response['status'] ?? '';
    final companies = response['companies'] as List<dynamic>? ?? [];
    final isSuccess = status == 'all_synced' || status == 'sync_requested';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              _getOverallStatusIcon(status),
              color: _getOverallStatusColor(status),
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                'SDMS Sync Response',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall status
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: _getOverallStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _getOverallStatusColor(status).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: _getOverallStatusColor(status),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _formatOverallStatus(status),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Companies sync status
              if (companies.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(
                  'Company Status:',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
                SizedBox(height: 8.h),
                ...companies.map((company) {
                  final companyStatus = company['status'] ?? '';
                  final companyMessage = company['message'] ?? '';
                  final companyName = company['company_name'] ?? '';
                  final processId = company['process_id'] ?? '';

                  final statusConfig = _getCompanyStatusConfig(companyStatus);

                  return Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: statusConfig['color'].withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: statusConfig['color'].withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company name and status icon
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14.sp,
                              color: statusConfig['color'],
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                companyName,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryText,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: statusConfig['color'].withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusConfig['icon'],
                                    size: 10.sp,
                                    color: statusConfig['color'],
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    statusConfig['label'],
                                    style: TextStyle(
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w600,
                                      color: statusConfig['color'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        // Message
                        Text(
                          companyMessage,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        // Process ID (if available)
                        if (processId.isNotEmpty) ...[
                          SizedBox(height: 4.h),
                          Text(
                            'Process: ${processId.substring(0, 8)}...',
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: Colors.grey[500],
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.brandBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get overall status color
  Color _getOverallStatusColor(String status) {
    switch (status) {
      case 'all_synced':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      case 'failed':
        return AppColors.errorRed;
      default:
        return Colors.blue;
    }
  }

  // Get overall status icon
  IconData _getOverallStatusIcon(String status) {
    switch (status) {
      case 'all_synced':
        return Icons.check_circle;
      case 'partial':
        return Icons.warning;
      case 'failed':
        return Icons.error;
      default:
        return Icons.sync;
    }
  }

  // Format overall status text
  String _formatOverallStatus(String status) {
    switch (status) {
      case 'all_synced':
        return 'All companies processed';
      case 'partial':
        return 'Partial sync - some companies have issues';
      case 'failed':
        return 'Sync failed';
      default:
        return status;
    }
  }

  // Get company status configuration
  Map<String, dynamic> _getCompanyStatusConfig(String status) {
    switch (status) {
      case 'sync_started':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'label': 'Started',
        };
      case 'already_running':
        return {
          'color': Colors.orange,
          'icon': Icons.sync,
          'label': 'Running',
        };
      case 'sync_requested':
        return {
          'color': Colors.blue,
          'icon': Icons.pending,
          'label': 'Requested',
        };
      case 'config_error':
        return {
          'color': AppColors.errorRed,
          'icon': Icons.error,
          'label': 'Config Error',
        };
      case 'synced':
        return {
          'color': Colors.green,
          'icon': Icons.check_circle,
          'label': 'Synced',
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help,
          'label': status,
        };
    }
  }

  // Helper method to check if there are any bonuses to display
  bool _hasBonuses(QuotaSnapshot snapshot) {
    // Check if there's any total bonus or active bonuses
    final totalBonus = snapshot.items.fold<int>(
      0,
      (int sum, item) => sum + item.bonus,
    );
    final activeBonusesCount = snapshot.items
        .expand((item) => item.activeBonuses)
        .length;

    return totalBonus > 0 || activeBonusesCount > 0;
  }
}
