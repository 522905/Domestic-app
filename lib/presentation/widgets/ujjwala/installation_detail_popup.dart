import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../professional/professional_status_badge.dart';
import '../professional/professional_button.dart';

class InstallationDetailPopup extends StatelessWidget {
  final UjjwalaInstallation installation;
  final VoidCallback? onViewDetails;
  final VoidCallback? onSubmit;

  const InstallationDetailPopup({
    Key? key,
    required this.installation,
    this.onViewDetails,
    this.onSubmit,
  }) : super(key: key);

  static Future<void> show(
    BuildContext context, {
    required UjjwalaInstallation installation,
    VoidCallback? onViewDetails,
    VoidCallback? onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InstallationDetailPopup(
        installation: installation,
        onViewDetails: onViewDetails,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    installation.consumerName,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColorsEnhanced.secondaryText,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),

            // ID Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColorsEnhanced.brandBlue,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tag,
                    size: 18.r,
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Installation ID: ${installation.id}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Application number
            _buildInfoRow(
              Icons.receipt_long,
              'Application Number',
              installation.applicationNumber,
            ),
            SizedBox(height: AppSpacing.sm),

            _buildInfoRow(
              Icons.badge,
              'Consumer Number',
              installation.consumerNumber,
            ),
            SizedBox(height: AppSpacing.sm),

            // Info rows
            _buildInfoRow(
              Icons.phone,
              'Mobile',
              installation.mobileNumber,
            ),
            SizedBox(height: AppSpacing.sm),

            _buildInfoRow(
              Icons.location_on,
              'Address',
              installation.address,
              maxLines: 2,
            ),
            SizedBox(height: AppSpacing.md),

            // Status and date
            Row(
              children: [
                ProfessionalStatusBadge(
                  status: installation.status,
                  size: BadgeSize.medium,
                ),
                const Spacer(),
                Icon(
                  Icons.calendar_today,
                  size: 16.r,
                  color: AppColorsEnhanced.secondaryText,
                ),
                SizedBox(width: AppSpacing.xs),
                Text(
                  _formatDate(installation.materialDeliveredDate),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            // Action buttons
            Row(
              children: [
                if (onViewDetails != null)
                  Expanded(
                    child: ProfessionalButton(
                      text: 'View Details',
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewDetails!();
                      },
                      variant: ButtonVariant.primary,
                    ),
                  ),
                            ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18.r,
          color: AppColorsEnhanced.secondaryText,
        ),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.bodyMedium,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
