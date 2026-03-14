import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class TokenImageUploadWidget extends StatefulWidget {
  final String tokenId;

  const TokenImageUploadWidget({Key? key, required this.tokenId}) : super(key: key);

  @override
  State<TokenImageUploadWidget> createState() => _TokenImageUploadWidgetState();
}

class _TokenImageUploadWidgetState extends State<TokenImageUploadWidget> {
  final ImagePicker _imagePicker = ImagePicker();

  // Slot 1
  XFile? _file1;
  String? _uploadedUrl1;
  bool _uploading1 = false;
  double _progress1 = 0;
  String? _error1;

  // Slot 2
  XFile? _file2;
  String? _uploadedUrl2;
  bool _uploading2 = false;
  double _progress2 = 0;
  String? _error2;

  bool _isAttaching = false;

  bool get _hasAtLeastOneUrl => _uploadedUrl1 != null || _uploadedUrl2 != null;

  Future<void> _capturePhoto(int slot) async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (xfile == null) return;
      if (!mounted) return;

      setState(() {
        if (slot == 1) {
          _file1 = xfile;
          _uploadedUrl1 = null;
          _error1 = null;
        } else {
          _file2 = xfile;
          _uploadedUrl2 = null;
          _error2 = null;
        }
      });

      _uploadPhoto(slot, xfile);
    } catch (e) {
      if (mounted) {
        setState(() {
          if (slot == 1) _error1 = 'Camera error: $e';
          else _error2 = 'Camera error: $e';
        });
      }
    }
  }

  Future<void> _uploadPhoto(int slot, XFile xfile) async {
    setState(() {
      if (slot == 1) {
        _uploading1 = true;
        _progress1 = 0;
        _error1 = null;
      } else {
        _uploading2 = true;
        _progress2 = 0;
        _error2 = null;
      }
    });

    try {
      final tusClient = TusClient(xfile);

      await tusClient.upload(
        uri: Uri.parse('https://tus.dca.arungas.com/files/'),
        onProgress: (double progress, Duration total) {
          if (!mounted) return;
          setState(() {
            if (slot == 1) _progress1 = progress;
            else _progress2 = progress;
          });
        },
        onComplete: () {
          if (!mounted) return;
          final url = tusClient.uploadUrl?.toString();
          setState(() {
            if (slot == 1) {
              _uploading1 = false;
              _uploadedUrl1 = url;
            } else {
              _uploading2 = false;
              _uploadedUrl2 = url;
            }
          });
        },
      ).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (mounted) {
        setState(() {
          if (slot == 1) {
            _uploading1 = false;
            _error1 = 'Upload failed: $e';
          } else {
            _uploading2 = false;
            _error2 = 'Upload failed: $e';
          }
        });
      }
    }
  }

  void _deletePhoto(int slot) {
    setState(() {
      if (slot == 1) {
        _file1 = null;
        _uploadedUrl1 = null;
        _error1 = null;
        _uploading1 = false;
        _progress1 = 0;
      } else {
        _file2 = null;
        _uploadedUrl2 = null;
        _error2 = null;
        _uploading2 = false;
        _progress2 = 0;
      }
    });
  }

  void _attachImages() {
    if (!_hasAtLeastOneUrl || _isAttaching) return;
    setState(() => _isAttaching = true);

    context.read<OfflineDeliveryBloc>().add(AttachTokenImages(
      tokenId: widget.tokenId,
      referenceImage1Url: _uploadedUrl1,
      referenceImage2Url: _uploadedUrl2,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is ImagesAttached && state.token.id == widget.tokenId) {
          setState(() => _isAttaching = false);
          context.showSuccessSnackBar('Images attached successfully');
        } else if (state is OfflineDeliveryError && _isAttaching) {
          setState(() => _isAttaching = false);
        }
      },
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reference Photos',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Upload photos for delivery evidence',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Two photo slots in a row
            Row(
              children: [
                Expanded(
                  child: _buildPhotoSlot(
                    slot: 1,
                    label: 'Photo 1',
                    file: _file1,
                    uploadedUrl: _uploadedUrl1,
                    uploading: _uploading1,
                    progress: _progress1,
                    error: _error1,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildPhotoSlot(
                    slot: 2,
                    label: 'Photo 2',
                    file: _file2,
                    uploadedUrl: _uploadedUrl2,
                    uploading: _uploading2,
                    progress: _progress2,
                    error: _error2,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),

            // Attach button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _hasAtLeastOneUrl && !_isAttaching ? _attachImages : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorsEnhanced.brandBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: _isAttaching
                    ? SizedBox(
                        height: 18.h,
                        width: 18.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                    : Icon(Icons.cloud_upload_outlined, size: 20.sp),
                label: Text(
                  _isAttaching ? 'Attaching...' : 'Attach Images',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required int slot,
    required String label,
    XFile? file,
    String? uploadedUrl,
    required bool uploading,
    required double progress,
    String? error,
  }) {
    Color borderColor = AppColorsEnhanced.border;
    if (error != null) {
      borderColor = AppColorsEnhanced.errorRed;
    } else if (uploadedUrl != null) {
      borderColor = AppColorsEnhanced.successGreen;
    } else if (uploading) {
      borderColor = AppColorsEnhanced.brandBlue;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          // Label
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.08),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: borderColor == AppColorsEnhanced.border
                    ? AppColorsEnhanced.secondaryText
                    : borderColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Content area
          if (file != null)
            // Preview
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
                  child: Image.file(
                    File(file.path),
                    height: 100.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Status overlay
                if (uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80.w,
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${progress.toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.white, fontSize: 11.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (uploadedUrl != null)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColorsEnhanced.successGreen,
                        size: 18.sp,
                      ),
                    ),
                  ),
                // Delete button
                if (!uploading)
                  Positioned(
                    top: 4, left: 4,
                    child: GestureDetector(
                      onTap: () => _deletePhoto(slot),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColorsEnhanced.errorRed,
                          size: 16.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            // Capture button
            InkWell(
              onTap: () => _capturePhoto(slot),
              child: Container(
                height: 100.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 28.r,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Take Photo',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.brandBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Error message
          if (error != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColorsEnhanced.errorRed, size: 14.sp),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error,
                      style: TextStyle(fontSize: 9.sp, color: AppColorsEnhanced.errorRed),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Retry button on error
          if (error != null && file != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => _uploadPhoto(slot, file),
                child: Text(
                  'Retry',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.warningYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
