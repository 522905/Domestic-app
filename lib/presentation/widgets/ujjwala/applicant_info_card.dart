import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/ujjwala_installation.dart';
import '../../../l10n/l10n_extensions.dart';

class ApplicantInfoCard extends StatelessWidget {
  final UjjwalaInstallation installation;

  const ApplicantInfoCard({
    Key? key,
    required this.installation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
            color: AppColorsEnhanced.brandBlue,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile Photo
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: _buildProfilePhoto(),
              ),
              Expanded(
                child: Text(
                  context.l10n.ujjwalaApplicantInfo,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            context,
            context.l10n.ujjwalaConsumerName,
            installation.consumerName,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            context.l10n.ujjwalaApplicationNumber,
            installation.applicationNumber,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            context.l10n.ujjwalaConsumerNumber,
            installation.consumerNumber,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            context.l10n.ujjwalaMobileNumber,
            installation.mobileNumber,
          ),
          SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            context,
            context.l10n.ujjwalaAddress,
            installation.address,
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhoto() {
    final hasPhoto = installation.consumerPhoto != null &&
        installation.consumerPhoto!.isNotEmpty;

    return CircleAvatar(
      radius: 40.r,
      backgroundColor: AppColorsEnhanced.backgroundSecondary,
      child: hasPhoto
          ? ClipOval(
              child: Image.network(
                installation.consumerPhoto!,
                width: 80.r,
                height: 80.r,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 40.r,
                    color: AppColorsEnhanced.secondaryText,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: AppColorsEnhanced.brandBlue,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            )
          : Icon(
              Icons.person,
              size: 40.r,
              color: AppColorsEnhanced.secondaryText,
            ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140.w,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
