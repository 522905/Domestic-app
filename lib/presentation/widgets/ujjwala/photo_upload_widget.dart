import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/ujjwala_photo_upload.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_bloc.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_event.dart';

class PhotoUploadWidget extends StatelessWidget {
  final PhotoType photoType;
  final UjjwalaPhotoUpload photoUpload;
  final String label;
  final String? infoText;

  const PhotoUploadWidget({
    Key? key,
    required this.photoType,
    required this.photoUpload,
    required this.label,
    this.infoText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _getBorderColor(),
          width: 2,
        ),
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (infoText != null)
                IconButton(
                  icon: Icon(
                    Icons.info_outline,
                    color: AppColorsEnhanced.brandBlue,
                    size: 18.r,
                  ),
                  tooltip: 'Photo instructions',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _showInfoDialog(context, label, infoText!),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),

          // Photo preview, cached placeholder, or capture button
          if (photoUpload.isUploaded && !photoUpload.hasFile)
            _buildCachedPhotoPlaceholder(context)
          else if (photoUpload.hasFile)
            _buildPhotoPreview(context)
          else
            _buildCaptureButton(context),

          // Upload status
          if (photoUpload.isUploading) ...[
            SizedBox(height: AppSpacing.md),
            _buildUploadProgress(context),
          ],

          // Error message
          if (photoUpload.hasError) ...[
            SizedBox(height: AppSpacing.sm),
            _buildErrorMessage(context),
          ],

          // Success indicator
          if (photoUpload.isUploaded) ...[
            SizedBox(height: AppSpacing.sm),
            _buildSuccessIndicator(context),
          ],

          // Action buttons — also shown for cache-restored uploads (no local file)
          if ((photoUpload.hasFile || (photoUpload.isUploaded && !photoUpload.hasFile)) && !photoUpload.isUploading) ...[
            SizedBox(height: AppSpacing.md),
            _buildActionButtons(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCachedPhotoPlaceholder(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: AppColorsEnhanced.successGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: AppColorsEnhanced.successGreen,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_done,
              size: 22.r,
              color: AppColorsEnhanced.successGreen,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Uploaded — tap Retake to replace',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColorsEnhanced.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureButton(BuildContext context) {
    return InkWell(
      onTap: () {
        context.read<UjjwalaInstallationsBloc>().add(
              CapturePhoto(
                photoType: photoType,
                source: ImageSource.camera,
              ),
            );
      },
      child: Container(
        height: 120.h,
        decoration: BoxDecoration(
          color: AppColorsEnhanced.brandBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: AppColorsEnhanced.brandBlue,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt,
                size: 28.r,
                color: AppColorsEnhanced.brandBlue,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                context.l10n.ujjwalaTakePhoto,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.brandBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Image.file(
        File(photoUpload.file!.path),
        height: 150.h,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildUploadProgress(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: photoUpload.uploadProgress / 100,
          backgroundColor: AppColorsEnhanced.border,
          valueColor: AlwaysStoppedAnimation<Color>(
            AppColorsEnhanced.brandBlue,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          '${context.l10n.ujjwalaPhotoUploading} ${photoUpload.uploadProgress.toStringAsFixed(0)}%',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColorsEnhanced.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColorsEnhanced.errorRed,
            size: 20.r,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              photoUpload.errorMessage ?? context.l10n.ujjwalaPhotoError,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.errorRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColorsEnhanced.successGreen,
            size: 20.r,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            context.l10n.ujjwalaPhotoUploaded,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.successGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Retake button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<UjjwalaInstallationsBloc>().add(
                    CapturePhoto(
                      photoType: photoType,
                      source: ImageSource.camera,
                    ),
                  );
            },
            icon: Icon(
              Icons.camera_alt,
              size: 18.r,
            ),
            label: Text(context.l10n.ujjwalaRetakePhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsEnhanced.brandBlue,
              side: BorderSide(color: AppColorsEnhanced.brandBlue),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        // Delete button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<UjjwalaInstallationsBloc>().add(
                    DeletePhoto(photoType: photoType),
                  );
            },
            icon: Icon(
              Icons.delete_outline,
              size: 18.r,
            ),
            label: Text(context.l10n.ujjwalaDeletePhoto),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsEnhanced.errorRed,
              side: BorderSide(color: AppColorsEnhanced.errorRed),
            ),
          ),
        ),
        // Retry button (only show if error)
        if (photoUpload.hasError) ...[
          SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: () {
              context.read<UjjwalaInstallationsBloc>().add(
                    UploadPhoto(photoType: photoType),
                  );
            },
            icon: Icon(
              Icons.refresh,
              color: AppColorsEnhanced.warningYellow,
            ),
            tooltip: 'Retry upload',
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(BuildContext context, String title, String info) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColorsEnhanced.brandBlue, size: 20.r),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(info, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (photoUpload.hasError) {
      return AppColorsEnhanced.errorRed;
    } else if (photoUpload.isUploaded) {
      return AppColorsEnhanced.successGreen;
    } else if (photoUpload.isUploading) {
      return AppColorsEnhanced.brandBlue;
    } else if (photoUpload.hasFile) {
      return AppColorsEnhanced.warningYellow;
    } else {
      return AppColorsEnhanced.border;
    }
  }
}
