import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../blocs/sdms_claims/sdms_claims_bloc.dart';
import '../../blocs/sdms_claims/sdms_claims_event.dart';
import '../../blocs/sdms_claims/sdms_claims_state.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional/professional_status_badge.dart';
import '../../widgets/professional/professional_info_card.dart';
import '../../widgets/professional/split_info_row.dart';
import '../../widgets/professional_snackbar.dart';
import '../../../domain/entities/sdms_claims/sdms_order.dart';
import '../digital_credit/widgets/company_switch_dialog.dart';
import '../../../core/services/User.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage>
    with WidgetsBindingObserver {
  Timer? _rpaPollingTimer;
  SdmsOrder? _currentOrder; // Cache order to survive state changes

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadOrderDetail();
    // Draft v3: Transfers are now nested in order detail response
  }

  @override
  void dispose() {
    _stopRpaPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopRpaPolling();
    } else if (state == AppLifecycleState.resumed) {
      _loadOrderDetail();
    }
  }

  void _loadOrderDetail() {
    context.read<SdmsClaimsBloc>().add(LoadOrderDetail(widget.orderId));
  }

  void _startRpaPolling() {
    _rpaPollingTimer?.cancel();
    _rpaPollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      context.read<SdmsClaimsBloc>().add(PollOrderDetail(widget.orderId));
    });
  }

  void _stopRpaPolling() {
    _rpaPollingTimer?.cancel();
    _rpaPollingTimer = null;
  }

  void _handlePollingLogic(SdmsOrder order) {
    // Start polling if RPA is in progress
    if (order.isRpaInProgress) {
      _startRpaPolling();
    } else {
      _stopRpaPolling();
    }
  }

  void _handleClaimOrder() {
    context.read<SdmsClaimsBloc>().add(ClaimOrder(widget.orderId));
  }

  void _handleRetryOrder() {
    context.read<SdmsClaimsBloc>().add(RetryOrder(widget.orderId));
  }

  void _handleSwitchCompany() async {
    try {
      final bloc = context.read<SdmsClaimsBloc>();

      // Get current company information with fallback
      final user = User();
      final activeCompany = await user.getActiveCompany();

      // CRITICAL: Always get company ID, even if getActiveCompany() returns null
      final currentCompanyId = activeCompany?.id ?? await user.getActiveCompanyId();
      final currentCompanyName = activeCompany?.name ?? await user.getActiveCompanyName() ?? 'Current Company';

      // Validate we have company ID
      if (currentCompanyId == null) {
        if (!mounted) return;
        ProfessionalSnackBar.show(
          context,
          message: 'Unable to determine current company',
          type: SnackBarType.error,
        );
        return;
      }

      // Get all allowed companies from API
      final companies = await bloc.apiService.companyList();

      // Filter out current company from list
      final otherCompanies = companies
          .where((c) => c.id != currentCompanyId)
          .toList();

      if (otherCompanies.isEmpty) {
        if (!mounted) return;
        ProfessionalSnackBar.show(
          context,
          message: 'No other companies available',
          type: SnackBarType.error,
        );
        return;
      }

      final suggestedCompanies = otherCompanies.map((c) => {
        'company_id': c.id,
        'company_name': c.name,
        'can_switch': true,
      }).toList();

      if (!mounted) return;
      final selectedCompanyId = await showDialog<int>(
        context: context,
        barrierDismissible: true,
        builder: (context) => CompanySwitchDialog(
          currentCompanyName: currentCompanyName,
          suggestedCompanies: suggestedCompanies,
          onSwitch: (companyId) {
            Navigator.pop(context, companyId);
          },
        ),
      );

      if (selectedCompanyId != null && mounted) {
        context.read<SdmsClaimsBloc>().add(
          SwitchOrderCompany(widget.orderId, selectedCompanyId),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ProfessionalSnackBar.show(
        context,
        message: 'Failed to load companies: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  // Draft v3: Use orderId instead of transferId
  void _handleApprove() {
    context.read<SdmsClaimsBloc>().add(ApproveTransfer(widget.orderId));
  }

  void _handleReject() {
    _showRejectDialog();
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          context.l10n.translate('sdmsClaimsRejectTransferDialogTitle'),
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.translate('sdmsClaimsRejectTransferConfirmationText'),
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: context.l10n.translate('sdmsClaimsRejectTransferReasonHintText'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.translate('commonCancelButton')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SdmsClaimsBloc>().add(
                    RejectTransfer(
                      widget.orderId,
                      reason: reasonController.text.isEmpty
                          ? null
                          : reasonController.text,
                    ),
                  );
            },
            child: Text(
              'Reject',
              style: TextStyle(color: AppColorsEnhanced.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsEnhanced.background,
      appBar: AppBar(
        title: Text(context.l10n.translate('sdmsClaimsOrderDetailsAppBarTitle'), style: AppTextStyles.h2),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<SdmsClaimsBloc, SdmsClaimsState>(
        listener: (context, state) {
          if (state is OrderDetailLoaded) {
            setState(() {
              _currentOrder = state.order;
            });
            _handlePollingLogic(state.order);
          } else if (state is OrderActionSuccess) {
            setState(() {
              _currentOrder = state.order;
            });
            ProfessionalSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.success,
            );
          } else if (state is TransferActionSuccess) {
            setState(() {
              _currentOrder = state.order;
            });
            ProfessionalSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.success,
            );
            // Draft v3: Order detail is already in the response, no need to reload
          } else if (state is SdmsClaimsError) {
            ProfessionalSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          // Show loading only if we don't have cached order yet
          if (_currentOrder == null &&
              (state is OrderDetailLoading || state is SdmsClaimsLoading)) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColorsEnhanced.brandBlue,
              ),
            );
          }

          // Use cached order if available
          if (_currentOrder != null) {
            return _buildOrderDetail(_currentOrder!);
          }

          return Center(
            child: Text(
              context.l10n.translate('sdmsClaimsOrderNotFoundErrorText'),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderDetail(SdmsOrder order) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO STATUS CARD
          _buildHeroStatusCard(order),
          SizedBox(height: AppSpacing.md),

          // 1b. QUEUED BANNER (prominent explanation when data not yet fetched)
          if (order.isRpaInProgress) ...[
            _buildQueuedBanner(order),
            SizedBox(height: AppSpacing.md),
          ],

          // 2. APPROVAL SECTION (if pending) - PROMINENT!
          if (order.pendingTransfer != null && order.pendingTransfer!.canApprove) ...[
            _ApprovalWidget(
              transfer: order.pendingTransfer!,
              onApprove: _handleApprove,
              onReject: _handleReject,
            ),
            SizedBox(height: AppSpacing.md),
          ],

          // 3. TRANSFER HISTORY (recent context)
          if (order.transferHistory.isNotEmpty) ...[
            _buildTransferHistoryCard(order),
            SizedBox(height: AppSpacing.md),
          ],

          // 4. CORE INFO (order + consumer)
          _buildCoreInfoCard(order),
          SizedBox(height: AppSpacing.md),

          // 5. PARTNER INFO (conditional)
          if (order.originalDeliveryBoyName != null ||
              order.isBeneficiary == true ||
              order.originalPartnerName != null ||
              order.claimedPartnerName != null) ...[
            _buildPartnerInfoCard(order),
            SizedBox(height: AppSpacing.md),
          ],

          // 6. SERVICE ITEMS (conditional)
          if (order.isServiceOrder && order.items.isNotEmpty) ...[
            _buildItemsCard(order),
            SizedBox(height: AppSpacing.md),
          ],

          // 7. ERP STATUS (collapsible, technical)
          if (order.isOnlinePayment && order.dpcPosting != null) ...[
            _ErpStatusCard(order: order),
            SizedBox(height: AppSpacing.md),
          ],

          // Action Buttons
          _buildActionButtons(order),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildHeroStatusCard(SdmsOrder order) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return ProfessionalInfoCard(
      accentColor: _getStatusAccentColor(order),
      padding: EdgeInsets.all(AppSpacing.sm),
      child: Column(
        children: [
          // Split layout: Consumer info (left) | Amount + Date (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT (60%)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consumer name
                    Text(
                      order.consumerName ?? 'Unknown Consumer',
                      style: AppTextStyles.h3.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),

                    // Beneficiary badge
                    if (order.isBeneficiary == true)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                size: 10.sp,
                                color: AppColorsEnhanced.brandBlue),
                            SizedBox(width: 4),
                            Text(
                              'My Partner',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColorsEnhanced.brandBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: AppSpacing.xs),

                    // REL ID
                    if (order.consumerNumber != null)
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12.sp,
                              color: AppColorsEnhanced.secondaryText),
                          SizedBox(width: 4),
                          Text(
                            order.consumerNumber!,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: AppSpacing.xs / 2),

                    // Order ID
                    Row(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 12.sp,
                            color: AppColorsEnhanced.secondaryText),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            order.orderId,
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
                  ],
                ),
              ),

              SizedBox(width: AppSpacing.sm),

              // Vertical divider
              Container(
                width: 1,
                height: 100.h,
                color: AppColorsEnhanced.border.withOpacity(0.3),
              ),

              SizedBox(width: AppSpacing.sm),

              // RIGHT (40%)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Amount
                    if (order.amount != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.currency_rupee_rounded,
                            size: 20.sp,
                            color: AppColorsEnhanced.successGreen,
                          ),
                          Text(
                            order.amount!.toStringAsFixed(0),
                            style: AppTextStyles.h2.copyWith(
                              color: AppColorsEnhanced.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                    SizedBox(height: AppSpacing.sm),

                    // Date
                    if (order.orderDate != null)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 12.sp,
                              color: AppColorsEnhanced.secondaryText),
                          SizedBox(width: 4),
                          Text(
                            dateFormat.format(order.orderDate!),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.sm),

          // Status badge (full width)
          ProfessionalStatusBadge(
            status: order.getCombinedStatusDisplay(),
            color: _getStatusColor(order),
            size: BadgeSize.medium,
          ),

          // v1.6: Show error category details for failed orders
          if (order.isFailed && order.hasErrorCategory) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: order.isRejectedError
                    ? AppColorsEnhanced.secondaryText.withOpacity(0.1)
                    : AppColorsEnhanced.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: order.isRejectedError
                      ? AppColorsEnhanced.secondaryText
                      : AppColorsEnhanced.errorRed,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    order.isRejectedError ? Icons.block : Icons.error_outline,
                    color: order.isRejectedError
                        ? AppColorsEnhanced.secondaryText
                        : AppColorsEnhanced.errorRed,
                    size: 16.sp,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      order.getErrorCategoryMessage(),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: order.isRejectedError
                            ? AppColorsEnhanced.secondaryText
                            : AppColorsEnhanced.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // RPA Progress (if applicable)
          if (order.isRpaInProgress) ...[
            SizedBox(height: AppSpacing.sm),
            _buildCompactRpaProgress(order.dataStatus),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactRpaProgress(String progress) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.infoBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppColorsEnhanced.infoBlue),
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              progress,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.infoBlue,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusAccentColor(SdmsOrder order) {
    if (order.pendingTransfer != null && order.pendingTransfer!.canApprove)
      return AppColorsEnhanced.warningYellow;
    if (order.isRpaInProgress) return AppColorsEnhanced.infoBlue;
    if (order.isFailed || order.isRejected) return AppColorsEnhanced.errorRed;
    if (order.isClaimed) return AppColorsEnhanced.successGreen;
    return AppColorsEnhanced.border;
  }

  Widget _buildCoreInfoCard(SdmsOrder order) {
    return ProfessionalInfoCard(
      title: context.l10n.translate('sdmsClaimsOrderDetailsCardTitle'),
      accentColor: AppColorsEnhanced.brandBlue,
      child: Column(
        children: [
          // Row 1: Category | Consumer Address
          SplitInfoRow(
            leftLabel: 'Category',
            leftValue: order.categoryDisplay,
            leftIcon: Icons.category_outlined,
            rightLabel: 'Address',
            rightValue: order.consumerAddress ?? 'N/A',
            rightIcon: Icons.location_on_outlined,
          ),

          SizedBox(height: AppSpacing.sm),

          // Row 2: Payment Mode
          Row(
            children: [
              Icon(Icons.payment,
                  size: 12.sp, color: AppColorsEnhanced.secondaryText),
              SizedBox(width: 4),
              Text(
                'Payment: ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                  fontSize: 10.sp,
                ),
              ),
              Text(
                order.paymentModeDisplay,
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          if (order.sourceDisplay.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),

            // Row 3: Source (full width)
            Row(
              children: [
                Icon(Icons.source_outlined,
                    size: 12.sp, color: AppColorsEnhanced.secondaryText),
                SizedBox(width: 4),
                Text(
                  'Source: ',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                    fontSize: 10.sp,
                  ),
                ),
                Text(
                  order.sourceDisplay,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildItemsCard(SdmsOrder order) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.translate('sdmsClaimsServiceOrderItemsCardTitle'),
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.md),

          ...order.items.map((item) {
            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.backgroundSecondary,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${item.itemCode} × ${item.quantity}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${item.amount.toStringAsFixed(2)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColorsEnhanced.brandBlue,
                        ),
                      ),
                      ProfessionalStatusBadge(
                        status: item.direction,
                        color: item.isIssue
                            ? AppColorsEnhanced.successGreen
                            : AppColorsEnhanced.infoBlue,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQueuedBanner(SdmsOrder order) {
    final isQueued = order.dataStatus == 'QUEUED';
    final label = isQueued ? 'Queued for SDMS Processing' : 'Processing in SDMS...';
    final description = isQueued
        ? 'Your order has been submitted and is waiting in the SDMS queue. Consumer details and amount will appear once processing begins.'
        : 'SDMS is currently processing this order. Consumer details and amount will appear shortly.';

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.infoBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.infoBlue.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            height: 20.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(AppColorsEnhanced.infoBlue),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColorsEnhanced.infoBlue,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  description,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(SdmsOrder order) {
    // QUEUED / PROCESSING: show disabled waiting indicator instead of blank
    if (order.isRpaInProgress) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColorsEnhanced.infoBlue.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColorsEnhanced.infoBlue.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14.w,
              height: 14.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColorsEnhanced.infoBlue),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Waiting for SDMS data — actions available after processing',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.infoBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }


    if (order.canClaim) {
      return ProfessionalButton(
        text: context.l10n.translate('sdmsClaimsClaimOrderButtonText'),
        icon: Icons.check_circle,
        onPressed: _handleClaimOrder,
        variant: ButtonVariant.primary,
        size: ButtonSize.large,
        fullWidth: true,
      );
    }

    // v1.6: Company switch + retry for NOT_FOUND errors
    if (order.canSwitchCompany) {
      return Column(
        children: [
          ProfessionalButton(
            text: context.l10n.translate('sdmsClaimsSwitchCompanyButtonText'),
            icon: Icons.business,
            onPressed: _handleSwitchCompany,
            variant: ButtonVariant.primary,
            size: ButtonSize.large,
            fullWidth: true,
          ),
          SizedBox(height: AppSpacing.sm),
          ProfessionalButton(
            text: context.l10n.translate('sdmsClaimsRetryCurrentCompanyButtonText'),
            icon: Icons.refresh,
            onPressed: _handleRetryOrder,
            variant: ButtonVariant.secondary,
            size: ButtonSize.large,
            fullWidth: true,
          ),
        ],
      );
    }

    if (order.canRetry) {
      return ProfessionalButton(
        text: context.l10n.translate('commonRetryButton'),
        icon: Icons.refresh,
        onPressed: _handleRetryOrder,
        variant: ButtonVariant.warning,
        size: ButtonSize.large,
        fullWidth: true,
      );
    }

    // Rejected errors: Show greyed out message, no action
    if (order.isFailed && order.isRejectedError) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColorsEnhanced.secondaryText.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(Icons.block,
                color: AppColorsEnhanced.secondaryText,
                size: 20.sp),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'This order cannot be retried. ${order.rpaError ?? ""}',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildPartnerInfoCard(SdmsOrder order) {
    return ProfessionalInfoCard(
      title: context.l10n.translate('sdmsClaimsPartnerInformationCardTitle'),
      accentColor: AppColorsEnhanced.brandBlue,
      child: Column(
        children: [
          if (order.originalDeliveryBoyName != null ||
              order.originalPartnerName != null)
            SplitInfoRow(
              leftLabel: 'Original Partner',
              leftValue: order.originalDeliveryBoyName ??
                  order.originalPartnerName ??
                  'N/A',
              leftIcon: Icons.person_outline,
              rightLabel: context.l10n.translate('sdmsClaimsClaimedByLabel'),
              rightValue: order.claimedPartnerName ??
                  order.claimedByName ??
                  context.l10n.translate('sdmsClaimsUnclaimedStatus'),
              rightIcon: Icons.person_pin,
            ),

          // Beneficiary indicator (if applicable)
          if (order.isBeneficiary == true) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16.sp, color: AppColorsEnhanced.brandBlue),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.translate('sdmsClaimsYouAreBeneficiaryMessage'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColorsEnhanced.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(SdmsOrder order) {
    if (order.isRpaInProgress) return AppColorsEnhanced.secondaryText;
    if (order.isFailed) return AppColorsEnhanced.errorRed;
    if (order.isIncident) return AppColorsEnhanced.warningYellow;
    if (order.isPendingCompletion) return AppColorsEnhanced.warningYellow;
    if (order.isUnclaimed) return AppColorsEnhanced.infoBlue;
    if (order.isPendingApproval) return AppColorsEnhanced.warningYellow;
    if (order.isClaimed) return AppColorsEnhanced.successGreen;
    if (order.isRejected) return AppColorsEnhanced.errorRed;
    return AppColorsEnhanced.secondaryText;
  }

  Widget _buildTransferHistoryCard(SdmsOrder order) {
    if (order.transferHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return ProfessionalInfoCard(
      title: context.l10n.translate('sdmsClaimsTransferHistoryCardTitle'),
      accentColor: AppColorsEnhanced.secondaryText,
      child: Column(
        children: order.transferHistory.take(5).map((transfer) {
          return _buildCompactTransferRow(transfer);
        }).toList(),
      ),
    );
  }

  Widget _buildCompactTransferRow(dynamic transfer) {
    final dateFormat = DateFormat('dd MMM');
    final status = transfer.status as String;
    final statusColor = status == 'APPROVED'
        ? AppColorsEnhanced.successGreen
        : AppColorsEnhanced.errorRed;
    final statusIcon =
        status == 'APPROVED' ? Icons.check_circle : Icons.cancel;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          // Status icon
          Icon(statusIcon, size: 16.sp, color: statusColor),
          SizedBox(width: AppSpacing.xs),

          // Compact info: "Alice → Bob"
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.labelMedium,
                children: [
                  TextSpan(
                    text: transfer.fromUserName,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: ' → ',
                    style: TextStyle(color: AppColorsEnhanced.secondaryText),
                  ),
                  TextSpan(
                    text: transfer.toUserName,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          SizedBox(width: AppSpacing.xs),

          // Date
          Text(
            transfer.resolvedAt != null
                ? dateFormat.format(transfer.resolvedAt!)
                : '',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }
}

// Approval Widget - Prominent design with urgency indicators
// Draft v3: Updated to use PendingTransfer
class _ApprovalWidget extends StatelessWidget {
  final dynamic transfer; // PendingTransfer (dynamic for compatibility)
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalWidget({
    Key? key,
    required this.transfer,
    required this.onApprove,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isActionable = transfer.canApprove as bool;

    return ProfessionalInfoCard(
      accentColor: AppColorsEnhanced.warningYellow,
      backgroundColor: isActionable
          ? AppColorsEnhanced.warningYellow.withOpacity(0.08)
          : Colors.white,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with urgency indicator
          Row(
            children: [
              Icon(Icons.pending_actions,
                  size: 20.sp, color: AppColorsEnhanced.warningYellow),
              SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.translate('sdmsClaimsTransferRequestCardTitle'),
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColorsEnhanced.warningYellow,
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.sm),

          // Split layout: Requester info (left) | Timer + Actions (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT (60%)
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Requester
                    Text(
                      transfer.toUserName,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      context.l10n.translate('sdmsClaimsWantsToClaimOrderText'),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),

                    // Reason (if provided)
                    if (transfer.reason != null &&
                        transfer.reason.toString().isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.backgroundSecondary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          '"${transfer.reason}"',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 10.sp,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: AppSpacing.md),

              // RIGHT (40%)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Countdown timer (large, prominent)
                    Container(
                      padding: EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColorsEnhanced.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColorsEnhanced.errorRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.timer,
                              size: 24.sp, color: AppColorsEnhanced.errorRed),
                          SizedBox(height: 4),
                          Text(
                            transfer.timeRemainingDisplay,
                            style: AppTextStyles.h4.copyWith(
                              color: AppColorsEnhanced.errorRed,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            context.l10n.translate('sdmsClaimsTimeRemainingLabel'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action buttons (if actionable)
          if (isActionable) ...[
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ProfessionalButton(
                    text: context.l10n.translate('commonRejectButton'),
                    onPressed: onReject,
                    variant: ButtonVariant.error,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ProfessionalButton(
                    text: context.l10n.translate('commonApproveButton'),
                    onPressed: onApprove,
                    variant: ButtonVariant.success,
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14.sp, color: AppColorsEnhanced.infoBlue),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      context.l10n.translate('sdmsClaimsPendingApprovalFromPartnerMessage'),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.infoBlue,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Collapsible ERP Status Card
class _ErpStatusCard extends StatefulWidget {
  final SdmsOrder order;

  const _ErpStatusCard({Key? key, required this.order}) : super(key: key);

  @override
  State<_ErpStatusCard> createState() => _ErpStatusCardState();
}

class _ErpStatusCardState extends State<_ErpStatusCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    // Auto-expand if there are errors
    if (_hasErrors()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isExpanded = true);
        }
      });
    }
  }

  bool _hasErrors() {
    final dpc = widget.order.dpcPosting;
    if (dpc == null) return false;
    return (dpc.error != null && dpc.error!.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final dpc = widget.order.dpcPosting!;
    final hasErrors = _hasErrors();

    return ProfessionalInfoCard(
      accentColor:
          hasErrors ? AppColorsEnhanced.errorRed : AppColorsEnhanced.secondaryText,
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16.sp,
                  color: hasErrors
                      ? AppColorsEnhanced.errorRed
                      : AppColorsEnhanced.secondaryText,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.translate('sdmsClaimsErpStatusCardTitle'),
                  style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (hasErrors)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Error',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.errorRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 9.sp,
                      ),
                    ),
                  ),
                SizedBox(width: AppSpacing.xs),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColorsEnhanced.secondaryText,
                ),
              ],
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            SizedBox(height: AppSpacing.sm),
            _buildErpTrackRow(
              context.l10n.translate('sdmsClaimsErpAccrualLabel'),
              dpc.accrualStatus,
              null,
              dpc.getTrackColor(dpc.accrualStatus),
            ),
            SizedBox(height: AppSpacing.xs),
            _buildErpTrackRow(
              context.l10n.translate('sdmsClaimsErpAllocationLabel'),
              dpc.allocationStatus,
              null,
              dpc.getTrackColor(dpc.allocationStatus),
            ),
            SizedBox(height: AppSpacing.xs),
            _buildErpTrackRow(
              context.l10n.translate('sdmsClaimsErpSettlementLabel'),
              dpc.settlementStatus,
              dpc.error,
              dpc.getTrackColor(dpc.settlementStatus),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErpTrackRow(
      String label, String? status, String? error, Color color) {
    final hasError = error != null && error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.check_circle_outline,
              size: 14.sp,
              color: color,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Text(
              status ?? 'N/A',
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        if (hasError) ...[
          SizedBox(height: AppSpacing.xs / 2),
          Container(
            padding: EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              error,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.errorRed,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
