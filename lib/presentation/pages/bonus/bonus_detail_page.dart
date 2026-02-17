import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../blocs/bonus_detail/bonus_detail_bloc.dart';
import '../../blocs/bonus_detail/bonus_detail_event.dart';
import '../../blocs/bonus_detail/bonus_detail_state.dart';
import '../../widgets/bonus/bonus_urgency_badge.dart';
import '../../widgets/bonus/bonus_progress_bar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../../core/constants/app_colors.dart';

/// Page to display detailed bonus information with calculation breakdown
class BonusDetailPage extends StatelessWidget {
  const BonusDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(l10n.bonusDetailTitle, style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<BonusDetailBloc, BonusDetailState>(
            builder: (context, state) {
              if (state is BonusDetailLoaded) {
                return IconButton(
                  icon: Icon(Icons.refresh, size: 24.sp),
                  tooltip: context.l10n.translate('commonRefreshTooltip'),
                  onPressed: () {
                    context.read<BonusDetailBloc>().add(RefreshBonusDetail(state.bonus.id));
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocBuilder<BonusDetailBloc, BonusDetailState>(
        builder: (context, state) {
          if (state is BonusDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BonusDetailError) {
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
                ],
              ),
            );
          } else if (state is BonusDetailLoaded) {
            final bonus = state.bonus;
            return RefreshIndicator(
              onRefresh: () async {
                context.read<BonusDetailBloc>().add(RefreshBonusDetail(bonus.id));
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Section
                    _buildHeroSection(context, bonus),
                    SizedBox(height: 24.h),

                    // Scheme Section
                    if (bonus.strategy != null) _buildSchemeSection(context, bonus),
                    if (bonus.strategy != null) SizedBox(height: 24.h),

                    // Calculation Breakdown
                    if (bonus.sourceMetrics != null) _buildCalculationSection(context, bonus),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bonus) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bonus.itemName,
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                  ),
                ),
                if (bonus.expiryUrgency != null)
                  BonusUrgencyBadge(urgency: bonus.expiryUrgency!),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              bonus.itemCode,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
            SizedBox(height: 16.h),

            // Dates
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow(
                    context.l10n.translate('bonusDetailEarned'),
                    DateFormat('dd MMM yyyy').format(bonus.earnedDate),
                  ),
                ),
                Expanded(
                  child: _buildInfoRow(
                    context.l10n.translate('bonusDetailExpires'),
                    DateFormat('dd MMM yyyy').format(bonus.expiryDate),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Quantities
            Row(
              children: [
                _buildQuantityChip(context.l10n.translate('bonusDetailEarned'), bonus.quantityEarned, Colors.green),
                SizedBox(width: 8.w),
                _buildQuantityChip(context.l10n.translate('bonusFilterConsumed'), bonus.quantityConsumed, Colors.orange),
                SizedBox(width: 8.w),
                _buildQuantityChip(context.l10n.translate('bonusDetailChipRemaining'), bonus.quantityRemaining, Colors.blue),
              ],
            ),
            SizedBox(height: 16.h),

            // Progress Bar
            BonusProgressBar(
              consumptionPercentage: bonus.consumptionPercentage,
              isExpiringSoon: bonus.isExpiringSoon,
            ),
            SizedBox(height: 8.h),

            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${bonus.statusDisplay}',
                  style: TextStyle(fontSize: 12.sp),
                ),
                if (bonus.daysUntilExpiry != null)
                  Text(
                    '${bonus.daysUntilExpiry} ${context.l10n.translate('bonusDetailDaysRemaining')}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchemeSection(BuildContext context, bonus) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.translate('bonusDetailSchemeTitle'),
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text(
              bonus.strategy!.name,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 4.h),
            Text(
              bonus.strategy!.description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationSection(BuildContext context, bonus) {
    final l10n = AppLocalizations.of(context)!;
    final metrics = bonus.sourceMetrics!;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.bonusSourceMetricsTitle,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.h),
            _buildMetricRow(context.l10n.translate('bonusMetricPickups'), metrics.pickups.toString(), Icons.arrow_downward),
            _buildMetricRow(context.l10n.translate('bonusMetricReturns'), metrics.returns.toString(), Icons.arrow_upward),
            _buildMetricRow(context.l10n.translate('bonusMetricNetPickups'), metrics.netPickups.toString(), Icons.inventory, highlight: true),
            Divider(height: 24.h),
            _buildMetricRow(context.l10n.translate('bonusMetricOtpSales'), metrics.otpSales.toString(), Icons.phone_android),
            _buildMetricRow(context.l10n.translate('bonusMetricOverrideSales'), metrics.overrideSales.toString(), Icons.verified),
            _buildMetricRow(context.l10n.translate('bonusMetricConfirmedSales'), metrics.confirmedSales.toString(), Icons.check_circle, highlight: true),
            Divider(height: 24.h),
            _buildMetricRow(context.l10n.translate('bonusMetricPostingRatio'), '${metrics.postingRatio.toStringAsFixed(2)}%', Icons.percent, highlight: true),
            _buildMetricRow(context.l10n.translate('bonusMetricBonusCalculated'), metrics.bonusCalculated.toString(), Icons.card_giftcard, highlight: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildQuantityChip(String label, int value, Color color) {
    return Chip(
      label: Text(
        '$label: $value',
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon, {bool highlight = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: highlight ? Colors.green : Colors.grey),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
              color: highlight ? Colors.green : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
