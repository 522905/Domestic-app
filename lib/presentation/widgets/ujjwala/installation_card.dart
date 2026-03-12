import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../../../l10n/l10n_extensions.dart';
import '../professional/professional_status_badge.dart';

class InstallationCard extends StatelessWidget {
  final UjjwalaInstallation installation;
  final VoidCallback onTap;

  const InstallationCard({
    Key? key,
    required this.installation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 30.r,
                backgroundColor: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                backgroundImage: installation.consumerPhoto != null
                    ? NetworkImage(installation.consumerPhoto!)
                    : null,
                child: installation.consumerPhoto == null
                    ? Icon(
                        Icons.person,
                        size: 30.r,
                        color: AppColorsEnhanced.brandBlue,
                      )
                    : null,
              ),
              SizedBox(width: AppSpacing.md),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ID Badge and Map Icon
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppColorsEnhanced.brandBlue,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ID: ${installation.id}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.brandBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (installation.orderId != null) ...[
                          SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: AppColorsEnhanced.successGreen,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Order: ${installation.orderId}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColorsEnhanced.successGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (_hasValidLocation)
                          InkWell(
                            onTap: () => _openGoogleMaps(context),
                            borderRadius: BorderRadius.circular(20.r),
                            child: Padding(
                              padding: EdgeInsets.all(4.r),
                              child: Icon(
                                Icons.map,
                                size: 20.r,
                                color: AppColorsEnhanced.brandBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    // Name
                    Text(
                      installation.consumerName,
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: AppSpacing.xs),
                    // Application number
                    Row(
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 14.r,
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'App: ${installation.applicationNumber}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    // Consumer number
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 14.r,
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Consumer: ${installation.consumerNumber}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    // Mobile number
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 14.r,
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          installation.mobileNumber,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14.r,
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            installation.address,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xs),
                    // Material delivered date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14.r,
                          color: AppColorsEnhanced.secondaryText,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatDate(installation.materialDeliveredDate),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    // Status badge
                    ProfessionalStatusBadge(
                      status: installation.status,
                      size: BadgeSize.small,
                    ),
                  ],
                ),
              ),
              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16.r,
                color: AppColorsEnhanced.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _hasValidLocation {
    return (installation.latitude != null &&
            installation.longitude != null &&
            installation.latitude != 0.0 &&
            installation.longitude != 0.0) ||
        (installation.googleMapsUrl != null && installation.googleMapsUrl!.isNotEmpty);
  }

  Future<void> _openGoogleMaps(BuildContext context) async {
    String? url;

    if (installation.googleMapsUrl != null && installation.googleMapsUrl!.isNotEmpty) {
      url = installation.googleMapsUrl;
    } else if (installation.latitude != null && installation.longitude != null) {
      url = 'https://www.google.com/maps/search/?api=1&query=${installation.latitude},${installation.longitude}';
    }

    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open maps'),
              backgroundColor: AppColorsEnhanced.errorRed,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }
}
