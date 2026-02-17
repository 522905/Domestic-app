import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../blocs/sdms_claims/sdms_claims_bloc.dart';
import '../../../blocs/sdms_claims/sdms_claims_event.dart';
import '../../../blocs/sdms_claims/sdms_claims_state.dart';
import '../../../widgets/professional/professional_search_bar.dart';
import '../../../widgets/professional/professional_empty_state.dart';
import '../../../widgets/professional/professional_button.dart';
import '../../../widgets/professional_snackbar.dart';
import '../../../../domain/entities/sdms_claims/sdms_order.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/l10n_extensions.dart';

class UnclaimedOrdersTab extends StatefulWidget {
  const UnclaimedOrdersTab({Key? key}) : super(key: key);

  @override
  State<UnclaimedOrdersTab> createState() => _UnclaimedOrdersTabState();
}

class _UnclaimedOrdersTabState extends State<UnclaimedOrdersTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // Keep state when switching tabs

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadOrders() {
    context.read<SdmsClaimsBloc>().add(const LoadUnclaimedOrders());
  }

  void _onSearch(String query) {
    context.read<SdmsClaimsBloc>().add(SearchUnclaimedOrders(query));
  }

  void _onOrderTap(SdmsOrder order) {
    Navigator.pushNamed(
      context,
      '/sdms-claims/order/${order.id}',
    );
  }

  void _onClaimOrder(SdmsOrder order) {
    context.read<SdmsClaimsBloc>().add(ClaimOrderFromBrowse(order.id));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Column(
      children: [
        // Search bar
        Container(
          color: AppColorsEnhanced.background,
          padding: EdgeInsets.all(AppSpacing.md),
          child: ProfessionalSearchBar(
            controller: _searchController,
            hintText: context.l10n.translate('sdmsClaimsUnclaimedSearchHintText'),
            onChanged: _onSearch,
          ),
        ),

        // Info banner
        Container(
          width: double.infinity,
          color: AppColorsEnhanced.infoBlue.withValues(alpha: 0.1),
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18.sp,
                color: AppColorsEnhanced.infoBlue,
              ),
              SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.translate('sdmsClaimsUnclaimedOrdersInfoBannerText'),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.infoBlue,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Order list
        Expanded(
          child: BlocConsumer<SdmsClaimsBloc, SdmsClaimsState>(
            listener: (context, state) {
              if (state is OrderActionSuccess) {
                ProfessionalSnackBar.show(
                  context,
                  message: state.message,
                  type: SnackBarType.success,
                );
                // Navigate to order detail after successful claim
                Navigator.pushNamed(
                  context,
                  '/sdms-claims/order/${state.order.id}',
                );
              }
              if (state is SdmsClaimsError) {
                ProfessionalSnackBar.show(
                  context,
                  message: state.message,
                  type: SnackBarType.error,
                );
                // Reload orders to get fresh state
                _loadOrders();
              }
              if (state is OrderCreated) {
                // Refresh list when new order created
                _loadOrders();
              }
            },
            builder: (context, state) {
              if (state is SdmsClaimsLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: AppColorsEnhanced.brandBlue,
                  ),
                );
              }

              if (state is SdmsClaimsError && state != state) {
                // Error is already shown in listener
                return ProfessionalEmptyState(
                  icon: Icons.error_outline,
                  message: 'Failed to load orders',
                  description: 'Please try again',
                  actionText: context.l10n.translate('commonRetryButton'),
                  onAction: _loadOrders,
                );
              }

              if (state is OrdersLoaded) {
                if (state.orders.isEmpty) {
                  return ProfessionalEmptyState(
                    icon: Icons.check_circle_outline,
                    message: context.l10n.translate('sdmsClaimsNoUnclaimedOrdersEmptyTitle'),
                    description:
                        context.l10n.translate('sdmsClaimsNoUnclaimedOrdersEmptyDescription'),
                    actionText: context.l10n.translate('commonRefreshTooltip'),
                    onAction: _loadOrders,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<SdmsClaimsBloc>()
                        .add(const RefreshUnclaimedOrders());
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  color: AppColorsEnhanced.brandBlue,
                  child: ListView.separated(
                    padding: EdgeInsets.all(AppSpacing.md),
                    itemCount: state.orders.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final order = state.orders[index];
                      return _UnclaimedOrderCard(
                        order: order,
                        onTap: () => _onOrderTap(order),
                        onClaim: () => _onClaimOrder(order),
                      );
                    },
                  ),
                );
              }

              if (state is OrderActionLoading) {
                // Show loading overlay while claiming
                return Stack(
                  children: [
                    // Keep the list visible
                    if (context.read<SdmsClaimsBloc>().state is OrdersLoaded)
                      ListView.separated(
                        padding: EdgeInsets.all(AppSpacing.md),
                        itemCount: (context.read<SdmsClaimsBloc>().state
                                as OrdersLoaded)
                            .orders
                            .length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final order = (context.read<SdmsClaimsBloc>().state
                                  as OrdersLoaded)
                              .orders[index];
                          return _UnclaimedOrderCard(
                            order: order,
                            onTap: () => _onOrderTap(order),
                            onClaim: () => _onClaimOrder(order),
                            isLoading: order.id == state.orderId,
                          );
                        },
                      ),
                    // Loading overlay
                    Container(
                      color: Colors.black26,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColorsEnhanced.brandBlue,
                        ),
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _UnclaimedOrderCard extends StatelessWidget {
  final SdmsOrder order;
  final VoidCallback onTap;
  final VoidCallback onClaim;
  final bool isLoading;

  const _UnclaimedOrderCard({
    Key? key,
    required this.order,
    required this.onTap,
    required this.onClaim,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Order ID
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 20.sp,
                          color: AppColorsEnhanced.brandBlue,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          order.orderId,
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date
                  if (order.orderDate != null)
                    Text(
                      dateFormat.format(order.orderDate!),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                ],
              ),

              SizedBox(height: AppSpacing.sm),

              // Order details
              Row(
                children: [
                  // Category
                  Text(
                    order.categoryDisplay,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.secondaryText,
                    ),
                  ),
                  // Payment mode
                  Text(
                    order.paymentModeDisplay,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.secondaryText,
                    ),
                  ),
                  if (order.amount != null) ...[
                    Text(
                      ' • ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                    Text(
                      '₹${order.amount!.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                    ),
                  ],
                ],
              ),

              SizedBox(height: AppSpacing.sm),

              // Consumer name (if available)
              if (order.consumerName != null)
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 16.sp,
                      color: AppColorsEnhanced.secondaryText,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        order.consumerName!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              // Original delivery boy (if available)
              if (order.originalDeliveryBoyName != null) ...[
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      Icons.delivery_dining,
                      size: 16.sp,
                      color: AppColorsEnhanced.secondaryText,
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Original DB: ${order.originalDeliveryBoyName}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: AppSpacing.md),

              // Action buttons row
              Row(
                children: [
                  // Status info
                  Expanded(
                    child: Text(
                      context.l10n.translate('sdmsClaimsReadyToClaimStatus'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColorsEnhanced.infoBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Claim button
                  ProfessionalButton(
                    text: context.l10n.translate('sdmsClaimsClaimButtonText'),
                    onPressed: isLoading ? null : onClaim,
                    isLoading: isLoading,
                    variant: ButtonVariant.primary,
                    size: ButtonSize.small,
                    icon: Icons.add_task,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
