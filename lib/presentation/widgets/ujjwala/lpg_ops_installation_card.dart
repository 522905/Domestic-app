import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/lpg_ops_installation.dart';
import '../professional/professional_status_badge.dart';

class LpgOpsInstallationCard extends StatelessWidget {
  final LpgOpsInstallation installation;
  final VoidCallback? onTap;

  const LpgOpsInstallationCard({
    Key? key,
    required this.installation,
    this.onTap,
  }) : super(key: key);

  Color get _accentColor {
    switch (installation.status) {
      case 'PENDING_VERIFICATION':
        return AppColorsEnhanced.warningYellow;
      case 'VERIFIED':
        return AppColorsEnhanced.successGreen;
      case 'FAILED':
        return AppColorsEnhanced.errorRed;
      case 'REIMBURSED':
        return AppColorsEnhanced.brandBlue;
      case 'UNUSUAL':
        return AppColorsEnhanced.infoBlue;
      default:
        return AppColorsEnhanced.border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    color: _accentColor,
                  ),

                  // Card content
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: name + status badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  installation.consumerName.isNotEmpty
                                      ? installation.consumerName
                                      : 'Unknown Consumer',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: AppSpacing.sm),
                              ProfessionalStatusBadge(
                                status: installation.statusDisplay.isNotEmpty
                                    ? installation.statusDisplay
                                    : installation.status,
                                size: BadgeSize.small,
                              ),
                            ],
                          ),

                          SizedBox(height: 4.h),

                          // Order/doc ID + date in one row
                          Row(
                            children: [
                              Text(
                                installation.displayId.isNotEmpty
                                    ? '#${installation.displayId}'
                                    : 'ID: ${installation.id}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText,
                                ),
                              ),
                              Text(
                                ' · ',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText,
                                ),
                              ),
                              Text(
                                _formatDate(installation.createdAt),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText,
                                ),
                              ),
                            ],
                          ),

                          // Partner name (if set)
                          if (installation.partnerName.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              'Partner: ${installation.partnerName}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColorsEnhanced.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],

                          // FAILED: compact error chip
                          if (installation.status == 'FAILED') ...[
                            SizedBox(height: AppSpacing.xs),
                            _ErrorChip(category: installation.errorCategory),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Trailing chevron
                  Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      Icons.chevron_right,
                      color: AppColorsEnhanced.border,
                      size: 20.r,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}

class _ErrorChip extends StatelessWidget {
  final String category;

  const _ErrorChip({required this.category});

  String get _label {
    switch (category) {
      case 'NOT_FOUND':
        return 'Order not found in SDMS';
      case 'PENDING_COMPLETION':
        return 'Pending completion in SDMS';
      case 'TECHNICAL':
        return 'Technical error';
      default:
        return 'Error — tap for details';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.r),
        border: Border.all(color: AppColorsEnhanced.errorRed.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 12.r, color: AppColorsEnhanced.errorRed),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              _label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.errorRed,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
