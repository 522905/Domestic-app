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

  XFile? _file;
  String? _uploadedUrl;
  bool _uploading = false;
  double _progress = 0;
  String? _error;
  bool _isAttaching = false;

  Future<void> _capturePhoto() async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (xfile == null || !mounted) return;

      setState(() {
        _file = xfile;
        _uploadedUrl = null;
        _error = null;
      });

      _uploadPhoto(xfile);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Camera error: $e');
      }
    }
  }

  Future<void> _uploadPhoto(XFile xfile) async {
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });

    try {
      final tusClient = TusClient(xfile);

      await tusClient.upload(
        uri: Uri.parse('https://tus.dca.arungas.com/files/'),
        onProgress: (double progress, Duration total) {
          if (!mounted) return;
          setState(() => _progress = progress);
        },
        onComplete: () {
          if (!mounted) return;
          setState(() {
            _uploading = false;
            _uploadedUrl = tusClient.uploadUrl?.toString();
          });
        },
      ).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed: $e';
        });
      }
    }
  }

  void _deletePhoto() {
    setState(() {
      _file = null;
      _uploadedUrl = null;
      _error = null;
      _uploading = false;
      _progress = 0;
    });
  }

  void _attachImage() {
    if (_uploadedUrl == null || _isAttaching) return;
    setState(() => _isAttaching = true);

    context.read<OfflineDeliveryBloc>().add(AttachTokenImages(
      tokenId: widget.tokenId,
      referenceImage1Url: _uploadedUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is ImagesAttached && state.token.id == widget.tokenId) {
          setState(() => _isAttaching = false);
          context.showSuccessSnackBar('Photo attached successfully');
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
              'Reference Photo',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Upload a photo for delivery evidence',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
            SizedBox(height: AppSpacing.md),

            // Single photo slot
            _buildPhotoSlot(),
            SizedBox(height: AppSpacing.lg),

            // Attach button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploadedUrl != null && !_isAttaching ? _attachImage : null,
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
                  _isAttaching ? 'Attaching...' : 'Attach Photo',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot() {
    Color borderColor = AppColorsEnhanced.border;
    if (_error != null) {
      borderColor = AppColorsEnhanced.errorRed;
    } else if (_uploadedUrl != null) {
      borderColor = AppColorsEnhanced.successGreen;
    } else if (_uploading) {
      borderColor = AppColorsEnhanced.brandBlue;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          if (_file != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: Image.file(
                    File(_file!.path),
                    height: 160.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_uploading)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 120.w,
                            child: LinearProgressIndicator(
                              value: _progress / 100,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_progress.toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.white, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_uploadedUrl != null)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: AppColorsEnhanced.successGreen,
                        size: 22.sp,
                      ),
                    ),
                  ),
                if (!_uploading)
                  Positioned(
                    top: 8, left: 8,
                    child: GestureDetector(
                      onTap: _deletePhoto,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColorsEnhanced.errorRed,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ),
              ],
            )
          else
            InkWell(
              onTap: _capturePhoto,
              child: Container(
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 36.r,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Take Photo',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColorsEnhanced.brandBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_error != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColorsEnhanced.errorRed, size: 14.sp),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(fontSize: 10.sp, color: AppColorsEnhanced.errorRed),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          if (_error != null && _file != null)
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => _uploadPhoto(_file!),
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
