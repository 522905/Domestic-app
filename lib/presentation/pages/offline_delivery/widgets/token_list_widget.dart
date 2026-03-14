import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import 'token_detail_sheet.dart';

enum _TokenFilter { all, pending, delivered, voided }

class TokenListWidget extends StatefulWidget {
  final List<OfflineDeliveryToken> tokens;
  final VoidCallback onRefresh;
  final DateTime selectedDate;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const TokenListWidget({
    Key? key,
    required this.tokens,
    required this.onRefresh,
    required this.selectedDate,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  }) : super(key: key);

  @override
  State<TokenListWidget> createState() => _TokenListWidgetState();
}

class _TokenListWidgetState extends State<TokenListWidget> {
  _TokenFilter _activeFilter = _TokenFilter.all;

  List<OfflineDeliveryToken> get _filteredTokens {
    switch (_activeFilter) {
      case _TokenFilter.pending:
        return widget.tokens.where((t) => t.isPending).toList();
      case _TokenFilter.delivered:
        return widget.tokens.where((t) => t.isDelivered).toList();
      case _TokenFilter.voided:
        return widget.tokens.where((t) => t.isVoided).toList();
      case _TokenFilter.all:
        // All except voided by default
        return widget.tokens.where((t) => !t.isVoided).toList();
    }
  }

  bool get _isToday {
    final now = DateTime.now();
    return widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
  }

  String get _headerText {
    if (_isToday) return "Today's Tokens";
    return DateFormat('dd MMM yyyy').format(widget.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tokens.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: AppColorsEnhanced.secondaryText.withOpacity(0.4),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No tokens yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final filtered = _filteredTokens;

    // Group tokens
    final correctionNeeded = <OfflineDeliveryToken>[];
    final pending = <OfflineDeliveryToken>[];
    final delivered = <OfflineDeliveryToken>[];
    final quickDelivery = <OfflineDeliveryToken>[];
    final voided = <OfflineDeliveryToken>[];

    for (final t in filtered) {
      if (t.isVoided) {
        voided.add(t);
      } else if (t.needsCorrection) {
        correctionNeeded.add(t);
      } else if (t.isQuickDelivery) {
        quickDelivery.add(t);
      } else if (t.isDelivered) {
        delivered.add(t);
      } else {
        pending.add(t);
      }
    }

    // Sort each group by createdAt descending
    int byCreatedAtDesc(OfflineDeliveryToken a, OfflineDeliveryToken b) {
      final aTime = a.createdAt ?? DateTime(2000);
      final bTime = b.createdAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    }

    correctionNeeded.sort(byCreatedAtDesc);
    pending.sort(byCreatedAtDesc);
    delivered.sort(byCreatedAtDesc);
    quickDelivery.sort(byCreatedAtDesc);
    voided.sort(byCreatedAtDesc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                _headerText,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${widget.tokens.length} tokens',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              _buildFilterChip('All', _TokenFilter.all),
              SizedBox(width: AppSpacing.xs),
              _buildFilterChip('Pending', _TokenFilter.pending),
              SizedBox(width: AppSpacing.xs),
              _buildFilterChip('Delivered', _TokenFilter.delivered),
              SizedBox(width: AppSpacing.xs),
              _buildFilterChip('Voided', _TokenFilter.voided),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),

        // Grouped sections
        if (correctionNeeded.isNotEmpty)
          _buildSection(
            context,
            'Correction Needed',
            correctionNeeded,
            AppColorsEnhanced.warningYellow,
          ),
        if (pending.isNotEmpty)
          _buildSection(
            context,
            'Pending',
            pending,
            Colors.grey,
          ),
        if (delivered.isNotEmpty)
          _buildSection(
            context,
            'Delivered',
            delivered,
            AppColorsEnhanced.successGreen,
          ),
        if (quickDelivery.isNotEmpty)
          _buildSection(
            context,
            'Quick Delivery',
            quickDelivery,
            AppColorsEnhanced.brandBlue,
          ),
        if (voided.isNotEmpty)
          _buildSection(
            context,
            'Voided',
            voided,
            AppColorsEnhanced.errorRed,
          ),

        if (filtered.isEmpty)
          Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No tokens match this filter',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
            ),
          ),

        // Load more button
        if (widget.hasMore)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: widget.isLoadingMore
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : OutlinedButton(
                      onPressed: widget.onLoadMore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColorsEnhanced.brandBlue,
                        side: BorderSide(color: AppColorsEnhanced.brandBlue.withOpacity(0.3)),
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      ),
                      child: Text(
                        'Load more...',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColorsEnhanced.brandBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, _TokenFilter filter) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filter),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColorsEnhanced.brandBlue.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isActive
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.secondaryText,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<OfflineDeliveryToken> tokens,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              SizedBox(width: AppSpacing.xs),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${tokens.length}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...tokens.map((token) => _TokenCard(
              token: token,
              onTap: () => _showTokenDetail(context, token),
            )),
      ],
    );
  }

  void _showTokenDetail(BuildContext context, OfflineDeliveryToken token) {
    final bloc = context.read<OfflineDeliveryBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: TokenDetailSheet(token: token),
      ),
    );
  }
}

class _TokenCard extends StatelessWidget {
  final OfflineDeliveryToken token;
  final VoidCallback onTap;

  const _TokenCard({
    required this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Row(
          children: [
            // Token number badge
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${token.tokenNumber ?? '?'}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                  fontSize: 13.sp,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),

            // Consumer info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (token.consumerName != null || token.consumerNameManual != null)
                    Text(
                      token.consumerName ?? token.consumerNameManual!,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (token.consumerNumber != null) ...[
                    SizedBox(height: 2),
                    _infoRow('Consumer No.', token.consumerNumber!.substring(1), prefix: '7'),
                  ],
                  if (token.consumerId != null) ...[
                    SizedBox(height: 2),
                    _infoRow('Consumer ID', token.consumerId!.substring(1), prefix: '7'),
                  ],
                  if (token.cashToCollect != null) ...[
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Rs. ${token.cashToCollect!.toStringAsFixed(2)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (token.cashToCollectIsEstimated)
                          Text(
                            ' (est.)',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.warningYellow,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Status badge
            _buildStatusBadge(),
            SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              color: AppColorsEnhanced.secondaryText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {String? prefix}) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
          if (prefix != null)
            TextSpan(
              text: prefix,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          TextSpan(
            text: value,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Color get _statusColor {
    if (token.isDelivered) return AppColorsEnhanced.successGreen;
    if (token.isVoided) return AppColorsEnhanced.errorRed;
    return Colors.grey;
  }

  Widget _buildStatusBadge() {
    final Color bgColor;
    final Color textColor;
    final String label;

    // Correction badge takes priority over normal status
    if (token.needsCorrection) {
      bgColor = AppColorsEnhanced.warningYellow.withOpacity(0.1);
      textColor = AppColorsEnhanced.warningYellow;
      label = 'CORRECTION';
    } else if (token.isDelivered) {
      bgColor = AppColorsEnhanced.successGreen.withOpacity(0.1);
      textColor = AppColorsEnhanced.successGreen;
      label = 'DELIVERED';
    } else if (token.isVoided) {
      bgColor = AppColorsEnhanced.errorRed.withOpacity(0.1);
      textColor = AppColorsEnhanced.errorRed;
      label = 'VOIDED';
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey.shade700;
      label = 'PENDING';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
