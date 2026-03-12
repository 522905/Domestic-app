import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../../domain/entities/ujjwala/ujjwala_photo_upload.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_bloc.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_event.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_state.dart';
import '../../widgets/ujjwala/applicant_info_card.dart';
import '../../widgets/ujjwala/photo_upload_widget.dart';
import '../../widgets/ujjwala/location_widget.dart';
import '../../widgets/ujjwala/map_preview_widget.dart';
import '../../widgets/professional/professional_button.dart';

class InstallationSubmitPage extends StatelessWidget {
  const InstallationSubmitPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.ujjwalaSubmitTitle),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<UjjwalaInstallationsBloc, UjjwalaInstallationsState>(
        listener: (context, state) {
          if (state is InstallationSubmitState) {
            // Show success message and navigate back
            if (state.submitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.ujjwalaSubmitSuccess),
                  backgroundColor: AppColorsEnhanced.successGreen,
                ),
              );
              Navigator.pop(context);
            }

            // Show error message
            if (state.submitError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.submitError!),
                  backgroundColor: AppColorsEnhanced.errorRed,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state is! InstallationSubmitState) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColorsEnhanced.brandBlue,
              ),
            );
          }

          return Container(
            color: AppColorsEnhanced.backgroundSecondary,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Applicant Info Card
                  ApplicantInfoCard(installation: state.installation),
                  SizedBox(height: AppSpacing.lg),

                  // Map Preview (only if coordinates available)
                  if (state.installation.latitude != null &&
                      state.installation.longitude != null &&
                      state.installation.latitude != 0.0 &&
                      state.installation.longitude != 0.0)
                    Column(
                      children: [
                        MapPreviewWidget(
                          latitude: state.installation.latitude!,
                          longitude: state.installation.longitude!,
                          googleMapsUrl: state.installation.googleMapsUrl,
                        ),
                        SizedBox(height: AppSpacing.lg),
                      ],
                    ),

                  // Photos Section Header
                  _buildSectionLabel(context,
                      icon: Icons.photo_camera,
                      title: context.l10n.ujjwalaPhotosSection),
                  SizedBox(height: AppSpacing.sm),

                  // Kitchen Photo
                  PhotoUploadWidget(
                    photoType: PhotoType.kitchen,
                    photoUpload: state.photos[PhotoType.kitchen]!,
                    label: context.l10n.ujjwalaKitchenPhoto,
                    infoText: context.l10n.ujjwalaKitchenPhotoInfo,
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Gate Photo
                  PhotoUploadWidget(
                    photoType: PhotoType.gate,
                    photoUpload: state.photos[PhotoType.gate]!,
                    label: context.l10n.ujjwalaGatePhoto,
                    infoText: context.l10n.ujjwalaGatePhotoInfo,
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Stove Photo
                  PhotoUploadWidget(
                    photoType: PhotoType.stove,
                    photoUpload: state.photos[PhotoType.stove]!,
                    label: context.l10n.ujjwalaStovePhoto,
                    infoText: context.l10n.ujjwalaStovePhotoInfo,
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Location Section Header
                  _buildSectionLabel(context,
                      icon: Icons.location_on,
                      title: context.l10n.ujjwalaLocationSection),
                  SizedBox(height: AppSpacing.sm),

                  // Location Widget
                  LocationWidget(
                    location: state.location,
                    isLoading: state.isLocationLoading,
                    errorMessage: state.locationError,
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Previous Attempts section
                  if (state.isHistoryLoading || state.installationHistory.isNotEmpty)
                    Column(children: [
                      _buildSectionLabel(
                        context,
                        icon: Icons.history,
                        title: state.installationHistory.isEmpty
                            ? 'Previous Attempts'
                            : 'Previous Attempts (${state.installationHistory.length})',
                      ),
                      SizedBox(height: AppSpacing.sm),
                      _buildHistorySection(context, state),
                      SizedBox(height: AppSpacing.lg),
                    ]),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ProfessionalButton(
                      text: context.l10n.ujjwalaSubmitButton,
                      icon: Icons.check_circle,
                      variant: ButtonVariant.primary,
                      size: ButtonSize.large,
                      isLoading: state.isSubmitting,
                      onPressed: state.canSubmit && !state.isSubmitting
                          ? () {
                              context.read<UjjwalaInstallationsBloc>().add(
                                    const SubmitInstallation(),
                                  );
                            }
                          : null,
                    ),
                  ),

                  // Helper text
                  if (!state.canSubmit) ...[
                    SizedBox(height: AppSpacing.md),
                    Container(
                      padding: EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColorsEnhanced.warningYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColorsEnhanced.warningYellow,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColorsEnhanced.warningYellow,
                            size: 20.r,
                          ),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              _getHelperText(context, state),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColorsEnhanced.warningYellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getHelperText(BuildContext context, InstallationSubmitState state) {
    final missingPhotos = <String>[];

    if (state.photos[PhotoType.kitchen]?.isUploaded != true) {
      missingPhotos.add(context.l10n.ujjwalaKitchenPhoto);
    }
    if (state.photos[PhotoType.gate]?.isUploaded != true) {
      missingPhotos.add(context.l10n.ujjwalaGatePhoto);
    }
    if (state.photos[PhotoType.stove]?.isUploaded != true) {
      missingPhotos.add(context.l10n.ujjwalaStovePhoto);
    }

    if (missingPhotos.isNotEmpty) {
      return '${context.l10n.ujjwalaAllPhotosRequired}: ${missingPhotos.join(", ")}';
    }

    if (state.location == null) {
      return context.l10n.ujjwalaLocationRequired;
    }

    return '';
  }

  Widget _buildHistorySection(
      BuildContext context, InstallationSubmitState state) {
    if (state.isHistoryLoading) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Row(children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColorsEnhanced.brandBlue),
          ),
          SizedBox(width: AppSpacing.sm),
          Text('Loading history...', style: AppTextStyles.bodySmall),
        ]),
      );
    }

    return Column(
      children: state.installationHistory.map((attempt) {
        final status = attempt['status']?.toString() ?? '';
        final statusDisplay =
            attempt['status_display']?.toString() ?? status;
        final submittedAt = attempt['submitted_at']?.toString() ?? '';
        final rejectionReason =
            attempt['rejection_reason']?.toString();

        final statusColor = switch (status) {
          'ACCEPTED' => AppColorsEnhanced.successGreen,
          'REJECTED' => AppColorsEnhanced.errorRed,
          _ => AppColorsEnhanced.warningYellow,
        };

        return Container(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColorsEnhanced.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(statusDisplay,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(
                  submittedAt.isNotEmpty
                      ? _formatHistoryDate(submittedAt)
                      : '',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColorsEnhanced.secondaryText),
                ),
              ]),
              if (rejectionReason != null &&
                  rejectionReason.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          size: 16.r, color: AppColorsEnhanced.errorRed),
                      SizedBox(width: AppSpacing.xs),
                      Expanded(
                          child: Text(rejectionReason,
                              style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColorsEnhanced.errorRed))),
                    ]),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatHistoryDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Widget _buildSectionLabel(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16.r,
          decoration: BoxDecoration(
            color: AppColorsEnhanced.brandBlue,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Icon(icon, size: 15.r, color: AppColorsEnhanced.brandBlue),
        SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColorsEnhanced.brandBlue,
          ),
        ),
      ],
    );
  }
}
