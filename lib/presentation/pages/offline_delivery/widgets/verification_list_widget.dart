import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import 'supervisor_override_dialog.dart';


class VerificationListWidget extends StatelessWidget {
  final List<BookingVerification> verifications;
  final String distributionPointId;
  final bool isSupervisor;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

  const VerificationListWidget({
    Key? key,
    required this.verifications,
    required this.distributionPointId,
    this.isSupervisor = false,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (verifications.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 48,
              color: AppColorsEnhanced.secondaryText.withOpacity(0.4),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'No verifications yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              Text(
                'Verifications',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${verifications.length} items',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ...verifications.map((v) => _VerificationCard(
              verification: v,
              distributionPointId: distributionPointId,
              isSupervisor: isSupervisor,
            )),

        // Load more button
        if (hasMore)
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: isLoadingMore
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
                      onPressed: onLoadMore,
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
}

class _VerificationCard extends StatelessWidget {
  final BookingVerification verification;
  final String distributionPointId;
  final bool isSupervisor;

  const _VerificationCard({
    required this.verification,
    required this.distributionPointId,
    this.isSupervisor = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Consumer info + status badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (verification.consumerName != null)
                      Text(
                        verification.consumerName!,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (verification.consumerNumber != null) ...[
                      SizedBox(height: 2),
                      _infoRow('Consumer No.', verification.consumerNumber!.substring(1), prefix: '7'),
                    ],
                    if (verification.consumerId != null) ...[
                      SizedBox(height: 2),
                      _infoRow('Consumer ID', verification.consumerId!.substring(1), prefix: '7'),
                    ],
                    if (verification.orderNumber != null ||
                        verification.orderNumberFromRpa != null) ...[
                      SizedBox(height: 2),
                      _infoRow('Order', (verification.orderNumberFromRpa ?? verification.orderNumber ?? '').substring(2), prefix: '2-'),
                    ],
                  ],
                ),
              ),
              _buildStatusBadge(),
            ],
          ),

          // Financial info (if available)
          if (verification.cashToCollect != null ||
              verification.digitalAmount != null) ...[
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (verification.cashToCollect != null)
                  Text(
                    'Cash: Rs. ${verification.cashToCollect!.toStringAsFixed(2)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (verification.cashToCollect != null &&
                    verification.digitalAmount != null)
                  SizedBox(width: AppSpacing.md),
                if (verification.digitalAmount != null)
                  Text(
                    'Digital: Rs. ${verification.digitalAmount!.toStringAsFixed(2)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorsEnhanced.brandBlue,
                    ),
                  ),
              ],
            ),
          ],

          // Error message
          if (verification.isFailed && verification.errorMessage != null) ...[
            SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: AppColorsEnhanced.errorRed, size: 16.sp),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      verification.errorMessage!,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          SizedBox(height: AppSpacing.sm),
          _buildActions(context),
        ],
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

  Widget _buildStatusBadge() {
    final Color bgColor;
    final Color textColor;
    final String label;
    Widget? trailing;

    switch (verification.status) {
      case 'QUEUED':
        bgColor = AppColorsEnhanced.infoBlue.withOpacity(0.1);
        textColor = AppColorsEnhanced.infoBlue;
        label = 'QUEUED';
        break;
      case 'PROCESSING':
        bgColor = AppColorsEnhanced.infoBlue.withOpacity(0.06);
        textColor = AppColorsEnhanced.infoBlue;
        label = 'PROCESSING';
        trailing = SizedBox(
          height: 12.sp,
          width: 12.sp,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: AppColorsEnhanced.infoBlue,
          ),
        );
        break;
      case 'VERIFIED':
        bgColor = AppColorsEnhanced.successGreen.withOpacity(0.1);
        textColor = AppColorsEnhanced.successGreen;
        label = 'VERIFIED';
        break;
      case 'BOOKING_CREATED':
        bgColor = AppColorsEnhanced.successGreen.withOpacity(0.1);
        textColor = AppColorsEnhanced.successGreen;
        label = 'BOOKING CREATED';
        break;
      case 'FAILED':
        bgColor = AppColorsEnhanced.errorRed.withOpacity(0.1);
        textColor = AppColorsEnhanced.errorRed;
        label = 'FAILED';
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade700;
        label = verification.status;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: 4),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    // Already has a token — show indicator
    if (verification.hasToken) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.grey, size: 16.sp),
            SizedBox(width: AppSpacing.xs),
            Text(
              'Token Created',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    // Can create token (VERIFIED or BOOKING_CREATED)
    if (verification.canCreateToken) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            final idempotencyKey = const Uuid().v4();
            final bloc = context.read<OfflineDeliveryBloc>();
            final companyId = verification.company?.id ??
                (bloc.state is OfflineDeliveryLoaded
                    ? (bloc.state as OfflineDeliveryLoaded).lastSelectedCompanyId
                    : null);
            if (companyId == null) return;
            bloc.add(CreateToken(
              distributionPointId: distributionPointId,
              consumerId: verification.consumerId,
              consumerNumber: verification.consumerNumber,
              orderNumber: verification.orderNumberFromRpa ?? verification.orderNumber,
              idempotencyKey: idempotencyKey,
              bookingVerificationId: verification.id,
              companyId: companyId,
            ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsEnhanced.brandBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          icon: Icon(Icons.add_circle_outline, size: 18.sp),
          label: Text(
            'Create Token',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // Failed — show retry + optional supervisor override
    if (verification.isFailed) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<OfflineDeliveryBloc>().add(
                  RetryVerification(verificationId: verification.id),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsEnhanced.warningYellow,
                side: BorderSide(color: AppColorsEnhanced.warningYellow),
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.refresh, size: 18.sp),
              label: Text(
                'Retry',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Supervisor override button
          if (isSupervisor) ...[
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final bloc = context.read<OfflineDeliveryBloc>();
                  showDialog(
                    context: context,
                    builder: (ctx) => BlocProvider.value(
                      value: bloc,
                      child: SupervisorOverrideDialog(
                        verification: verification,
                        distributionPointId: distributionPointId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsEnhanced.warningYellow,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                icon: Icon(Icons.admin_panel_settings, size: 18.sp),
                label: Text(
                  'Issue Anyway',
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // QUEUED or PROCESSING — no action available
    return const SizedBox.shrink();
  }
}
