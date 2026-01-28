import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';
import 'package:lpg_distribution_app/l10n/l10n_extensions.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_event.dart';
import 'package:lpg_distribution_app/presentation/blocs/quota/quota_state.dart';

class QuotaDashboardWidget extends StatefulWidget {
  final String greetingLine;
  final String roleLine;
  final int pendingCount;
  final String pendingLabel;

  const QuotaDashboardWidget({
    Key? key,
    required this.greetingLine,
    required this.roleLine,
    required this.pendingCount,
    required this.pendingLabel,
  }) : super(key: key);

  @override
  State<QuotaDashboardWidget> createState() => _QuotaDashboardWidgetState();
}

class _QuotaDashboardWidgetState extends State<QuotaDashboardWidget> {
  @override
  void initState() {
    super.initState();
    // Load quota on widget init
    context.read<QuotaBloc>().add(LoadQuotaSnapshot());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuotaBloc, QuotaState>(
      builder: (context, state) {
        // Don't show widget if access denied (not a delivery partner)
        if (state is QuotaError && state.isAccessDenied) {
          return const SizedBox.shrink();
        }

        // Determine card color based on state
        Color cardColor;
        if (state is QuotaError) {
          cardColor = AppColors.errorRed;
        } else if (state is QuotaLoaded &&
            (state as QuotaLoaded).snapshot.blockedItemsCount > 0) {
          cardColor = AppColors.errorRed;
        } else {
          cardColor = AppColors.brandBlue;
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 0, vertical: 8.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.brandBlue.withOpacity(0.1),
                AppColors.brandBlue.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.brandBlue.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandBlue.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (state is QuotaLoaded || state is QuotaSyncInProgress) {
                  // Get partner info from state
                  final snapshot = state is QuotaLoaded
                      ? state.snapshot
                      : (state as QuotaSyncInProgress).snapshot;

                  final partnerName = snapshot.partnerName.toUpperCase();
                  final partnerCode = snapshot.partnerCode.toUpperCase();

                  // Don't navigate if partner is VK Logistics or contains VL
                  if (partnerName.contains('VK LOGISTICS') ||
                      partnerName.contains('VL') ||
                      partnerCode.contains('VL') ||
                      partnerCode == 'VL') {
                    // Do nothing - quota status page is disabled for VK Logistics/VL
                    return;
                  }

                  Navigator.pushNamed(context, '/quota');
                }
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: _buildContent(context, state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, QuotaState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting Section
        _buildGreetingSection(),

        // Divider
        // SizedBox(height: 10.h),
        Divider(color: AppColors.brandBlue.withOpacity(0.2), thickness: 1),
        // SizedBox(height: 10.h),

        // Quota Content
        _buildQuotaContent(state),
      ],
    );
  }

  Widget _buildQuotaContent(QuotaState state) {
    if (state is QuotaLoading) {
      return Row(
        children: [
          Icon(Icons.account_balance_wallet,
               color: AppColors.brandBlue, size: 32.sp),
          SizedBox(width: 12.w),
          const CircularProgressIndicator(),
          SizedBox(width: 12.w),
          Text('Loading Quota...', style: TextStyle(fontSize: 16.sp)),
        ],
      );
    }

    if (state is QuotaError) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: AppColors.errorRed,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quota Error',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.errorRed,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      state.message,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<QuotaBloc>().add(LoadQuotaSnapshot());
              },
              icon: Icon(Icons.refresh, size: 16.sp),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (state is QuotaLoaded || state is QuotaSyncInProgress) {
      final snapshot = state is QuotaLoaded
          ? state.snapshot
          : (state as QuotaSyncInProgress).snapshot;

      final blockedCount = snapshot.blockedItemsCount;

      // Filter out items where ALL values are zero
      final itemsToDisplay = snapshot.items.where((item) {
        return item.availableBalance != 0 ||
               item.opening != 0 ||
               item.adjustment != 0 ||
               item.orders != 0 ||
               item.pickups != 0 ||
               item.returns != 0 ||
               item.sdmsSales != 0 ||
               item.closing != 0 ||
               item.bonus != 0 ||
               item.creditLimit != 0;
      }).toList();

      final displayedItemsCount = itemsToDisplay.length;

      // Hide widget entirely if no items to display
      if (itemsToDisplay.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple cards for each item - only item name and available balance
          ...itemsToDisplay.map((item) => Container(
              margin: EdgeInsets.only(bottom: 10.h),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: item.isBlocked
                    ? AppColors.errorRed.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: item.isBlocked
                      ? AppColors.errorRed.withOpacity(0.3)
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Item icon and name
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      size: 20.sp,
                      color: AppColors.brandBlue,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: item.isBlocked
                            ? AppColors.errorRed
                            : AppColors.primaryText,
                      ),
                    ),
                  ),
                  SizedBox(width: 5.w),
                  // Available balance - BIG and prominent
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Available',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${item.availableBalance}',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: item.isBlocked
                              ? AppColors.errorRed
                              : AppColors.successGreen,
                        ),
                      ),
                    ],
                  ),
                  if (item.isBlocked) ...[
                    SizedBox(width: 8.w),
                    Icon(Icons.block, size: 18.sp, color: AppColors.errorRed),
                  ],
                ],
              ),
            )).toList(),

          SizedBox(height: 4.h),

          // Summary with sync time
          if (displayedItemsCount > 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$displayedItemsCount item${displayedItemsCount != 1 ? 's' : ''} available',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                    SizedBox(width: 4.w),
                    Text(
                      _getRelativeTime(snapshot.lastSync),
                      style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
            InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/quota');
              },
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 6.w),
                // decoration: BoxDecoration(
                //   color: AppColors.brandBlue.withOpacity(0.05),
                //   borderRadius: BorderRadius.circular(8.r),
                //   border: Border.all(
                //     color: AppColors.brandBlue.withOpacity(0.2),
                //     width: 1,
                //   ),
                // ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 16.sp,
                      color: AppColors.brandBlue,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Click to See Details',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12.sp,
                      color: AppColors.brandBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  // Helper method: Table Header Cell
  Widget _buildTableHeader(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // Helper method: Table Cell Wrapper
  Widget _buildTableCell({
    required Widget child,
    Alignment alignment = Alignment.center,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      child: Align(
        alignment: alignment,
        child: child,
      ),
    );
  }

  // Helper method: Table Data Row
  TableRow _buildItemTableRow(dynamic item) {
    final isBlocked = item.isBlocked;

    return TableRow(
      decoration: BoxDecoration(
        color: isBlocked ? AppColors.errorRed.withOpacity(0.05) : Colors.white,
      ),
      children: [
        // Item Name (left-aligned with block icon if blocked)
        _buildTableCell(
          child: Row(
            children: [
              if (isBlocked) ...[
                Icon(Icons.block, size: 12.sp, color: AppColors.errorRed),
                SizedBox(width: 4.w),
              ],
              Expanded(
                child: Text(
                  item.itemName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isBlocked ? AppColors.errorRed : AppColors.primaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
        ),

        // Available Balance (right-aligned, color-coded)
        _buildTableCell(
          child: Text(
            '${item.availableBalance}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: isBlocked
                  ? AppColors.errorRed
                  : (item.availableBalance > 0
                      ? AppColors.successGreen
                      : AppColors.secondaryText),
            ),
            textAlign: TextAlign.right,
          ),
          alignment: Alignment.centerRight,
        ),

        // Orders (right-aligned, red if negative)
        _buildTableCell(
          child: Text(
            '${item.orders}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: item.orders < 0 ? AppColors.errorRed : AppColors.secondaryText,
            ),
            textAlign: TextAlign.right,
          ),
          alignment: Alignment.centerRight,
        ),

        // SDMS Sales (right-aligned, green if positive)
        _buildTableCell(
          child: Text(
            '${item.sdmsSales}',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: item.sdmsSales > 0 ? AppColors.successGreen : AppColors.secondaryText,
            ),
            textAlign: TextAlign.right,
          ),
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }

  // Helper method: Empty State Widget
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 20.sp, color: Colors.grey[500]),
          SizedBox(width: 8.w),
          Text(
            'No items with available balance',
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method: Simple Info Box (for Orders and SDMS)
  Widget _buildSimpleInfoBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method: Greeting Section
  Widget _buildGreetingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(5.w),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.brandBlue.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.person,
                color: AppColors.brandBlue,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 2.w),
                  Text(
                    widget.greetingLine,
                    style: TextStyle(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.roleLine,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (widget.pendingCount > 0) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.withOpacity(0.2),
                  Colors.orange.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Colors.orange[800],
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  widget.pendingLabel,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
}
