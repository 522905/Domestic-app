import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_system_status.dart';

class ModeBannerWidget extends StatelessWidget {
  final OfflineSystemStatus status;

  const ModeBannerWidget({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color textColor;
    final IconData icon;
    final String title;

    if (status.isManual) {
      backgroundColor = AppColorsEnhanced.errorRed.withOpacity(0.1);
      textColor = AppColorsEnhanced.errorRed;
      icon = Icons.cloud_off;
      title = 'SDMS Offline';
    } else if (status.isAssisted) {
      backgroundColor = AppColorsEnhanced.warningYellow.withOpacity(0.1);
      textColor = AppColorsEnhanced.warningYellow;
      icon = Icons.engineering;
      title = 'Booking Channels Down — RPA Bridging';
    } else {
      backgroundColor = AppColorsEnhanced.successGreen.withOpacity(0.1);
      textColor = AppColorsEnhanced.successGreen;
      icon = Icons.check_circle;
      title = 'All Systems Operational';
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (status.notes != null && status.notes!.isNotEmpty) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              status.notes!,
              style: AppTextStyles.labelSmall.copyWith(
                color: textColor.withOpacity(0.8),
              ),
            ),
          ],
          if (status.updatedAt != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              'Status as of ${_formatTime(status.updatedAt!)}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
