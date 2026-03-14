import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class QuickDeliveryForm extends StatefulWidget {
  final String distributionPointId;
  final OfflineSystemStatus systemStatus;
  final int companyId;

  const QuickDeliveryForm({
    Key? key,
    required this.distributionPointId,
    required this.systemStatus,
    required this.companyId,
  }) : super(key: key);

  @override
  State<QuickDeliveryForm> createState() => _QuickDeliveryFormState();
}

class _QuickDeliveryFormState extends State<QuickDeliveryForm> {
  final _formKey = GlobalKey<FormState>();
  final _consumerIdController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _orderNumberController = TextEditingController();
  final _dacCodeController = TextEditingController();
  final _cashController = TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  bool _isSubmitting = false;
  bool _submitSuccess = false;
  OfflineDeliveryToken? _lastDeliveredToken;

  // Photo state
  XFile? _photoFile;
  String? _photoUrl;
  bool _uploading = false;
  double _uploadProgress = 0;
  String? _photoError;

  @override
  void dispose() {
    _consumerIdController.dispose();
    _consumerNumberController.dispose();
    _orderNumberController.dispose();
    _dacCodeController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      final xfile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        imageQuality: 70,
      );
      if (xfile == null || !mounted) return;

      setState(() {
        _photoFile = xfile;
        _photoUrl = null;
        _photoError = null;
      });

      _uploadPhoto(xfile);
    } catch (e) {
      if (mounted) setState(() => _photoError = 'Camera error: $e');
    }
  }

  Future<void> _uploadPhoto(XFile xfile) async {
    setState(() {
      _uploading = true;
      _uploadProgress = 0;
      _photoError = null;
    });

    try {
      final tusClient = TusClient(xfile);
      await tusClient.upload(
        uri: Uri.parse('https://tus.dca.arungas.com/files/'),
        onProgress: (double progress, Duration total) {
          if (!mounted) return;
          setState(() => _uploadProgress = progress);
        },
        onComplete: () {
          if (!mounted) return;
          setState(() {
            _uploading = false;
            _photoUrl = tusClient.uploadUrl?.toString();
          });
        },
      ).timeout(const Duration(seconds: 90));
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _photoError = 'Upload failed: $e';
        });
      }
    }
  }

  Future<bool> _handleSubmit() async {
    if (_isSubmitting) return false;
    if (!_formKey.currentState!.validate()) return false;

    final consumerId = _consumerIdController.text.trim();
    final consumerNumber = _consumerNumberController.text.trim();

    if (consumerId.isEmpty && consumerNumber.isEmpty) {
      context.showWarningSnackBar(
          'At least one of Consumer ID or Consumer Number is required');
      return false;
    }

    final cashCollected = double.tryParse(_cashController.text.trim());
    if (cashCollected == null) {
      context.showWarningSnackBar('Enter a valid cash amount');
      return false;
    }

    setState(() => _isSubmitting = true);

    final idempotencyKey = const Uuid().v4();

    context.read<OfflineDeliveryBloc>().add(QuickDeliver(
      distributionPointId: widget.distributionPointId,
      consumerId: consumerId.isNotEmpty ? '7$consumerId' : null,
      consumerNumber: consumerNumber.isNotEmpty ? '7$consumerNumber' : null,
      orderNumber: _orderNumberController.text.trim().isNotEmpty
          ? '2-${_orderNumberController.text.trim()}'
          : null,
      dacCode: _dacCodeController.text.trim().isNotEmpty
          ? _dacCodeController.text.trim()
          : null,
      cashCollected: cashCollected,
      referenceImage1Url: _photoUrl,
      idempotencyKey: idempotencyKey,
      companyId: widget.companyId,
    ));

    return true;
  }

  void _resetForm() {
    _consumerIdController.clear();
    _consumerNumberController.clear();
    _orderNumberController.clear();
    _dacCodeController.clear();
    _cashController.clear();
    setState(() {
      _submitSuccess = false;
      _lastDeliveredToken = null;
      _photoFile = null;
      _photoUrl = null;
      _photoError = null;
      _uploading = false;
      _uploadProgress = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is QuickDelivered && _isSubmitting) {
          setState(() {
            _submitSuccess = true;
            _lastDeliveredToken = state.token;
            _isSubmitting = false;
          });
        } else if (state is OfflineDeliveryError && _isSubmitting) {
          setState(() => _isSubmitting = false);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Consumer ID
                      TextFormField(
                        controller: _consumerIdController,
                        enabled: !_submitSuccess,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(15),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Consumer ID',
                          hintText: '500000047614745',
                          prefixIcon: const Icon(Icons.tag),
                          prefixText: '7',
                          prefixStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (value.trim().length != 15) {
                            return 'Enter 15 digits (total 16 with prefix 7)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Consumer Number
                      TextFormField(
                        controller: _consumerNumberController,
                        enabled: !_submitSuccess,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Consumer Number',
                          hintText: '547614745',
                          prefixIcon: const Icon(Icons.numbers),
                          prefixText: '7',
                          prefixStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (value.trim().length != 9) {
                            return 'Enter 9 digits (total 10 with prefix 7)';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                        child: Text(
                          'At least one of Consumer ID or Consumer Number is required',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.warningYellow,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Order Number
                      TextFormField(
                        controller: _orderNumberController,
                        enabled: !_submitSuccess,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(12),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Order Number',
                          hintText: '005456757366',
                          prefixIcon: const Icon(Icons.receipt_long),
                          prefixText: '2-',
                          prefixStyle: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (value.trim().length != 12) {
                            return 'Enter 12 digits after 2-';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // DAC Code
                      if (widget.systemStatus.requireDacCode) ...[
                        TextFormField(
                          controller: _dacCodeController,
                          enabled: !_submitSuccess,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'DAC Code',
                            hintText: 'Enter DAC Code (digits only)',
                            prefixIcon: const Icon(Icons.qr_code),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],

                      // Cash Collected (mandatory)
                      TextFormField(
                        controller: _cashController,
                        enabled: !_submitSuccess,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Cash Collected *',
                          hintText: 'Enter amount collected',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Cash collected is required';
                          }
                          final amount = double.tryParse(value.trim());
                          if (amount == null || amount < 0) {
                            return 'Enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md),

                      // Optional photo
                      if (!_submitSuccess) _buildPhotoSection(),
                      SizedBox(height: AppSpacing.xl),

                      // Slide to Submit
                      if (!_submitSuccess)
                        _isSubmitting
                            ? const Center(child: CircularProgressIndicator())
                            : _SlideToSubmitButton(onSubmit: _handleSubmit),

                      // Success state
                      if (_submitSuccess) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColorsEnhanced.successGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle,
                                      color: AppColorsEnhanced.successGreen,
                                      size: 24.sp),
                                  SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      'Quick delivery completed!',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColorsEnhanced.successGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_lastDeliveredToken != null) ...[
                                SizedBox(height: AppSpacing.xs),
                                Row(
                                  children: [
                                    SizedBox(width: 32.sp),
                                    Text(
                                      '${_lastDeliveredToken!.displayName} — DELIVERED',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColorsEnhanced.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Add another button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _resetForm,
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                            ),
                            icon: const Icon(Icons.add),
                            label: Text(
                              'Add Another',
                              style: TextStyle(fontSize: 14.sp),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _photoUrl != null
              ? AppColorsEnhanced.successGreen
              : _photoError != null
                  ? AppColorsEnhanced.errorRed
                  : AppColorsEnhanced.border,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          if (_photoFile != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
                  child: Image.file(
                    File(_photoFile!.path),
                    height: 100.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (_uploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.4),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 100.w,
                              child: LinearProgressIndicator(
                                value: _uploadProgress / 100,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${_uploadProgress.toStringAsFixed(0)}%',
                              style: TextStyle(color: Colors.white, fontSize: 12.sp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_photoUrl != null)
                  Positioned(
                    top: 4, right: 4,
                    child: Container(
                      padding: EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.check_circle, color: AppColorsEnhanced.successGreen, size: 18.sp),
                    ),
                  ),
                if (!_uploading)
                  Positioned(
                    top: 4, left: 4,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _photoFile = null;
                        _photoUrl = null;
                        _photoError = null;
                      }),
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: Icon(Icons.close, color: AppColorsEnhanced.errorRed, size: 16.sp),
                      ),
                    ),
                  ),
              ],
            )
          else
            InkWell(
              onTap: _capturePhoto,
              child: Container(
                height: 60.h,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 22.r, color: AppColorsEnhanced.brandBlue),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Take Photo (optional)',
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
          if (_photoError != null)
            Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Text(
                _photoError!,
                style: TextStyle(fontSize: 10.sp, color: AppColorsEnhanced.errorRed),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideToSubmitButton extends StatefulWidget {
  final Future<bool> Function() onSubmit;
  const _SlideToSubmitButton({required this.onSubmit});

  @override
  State<_SlideToSubmitButton> createState() => _SlideToSubmitButtonState();
}

class _SlideToSubmitButtonState extends State<_SlideToSubmitButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  late double _maxDrag;
  final double _thumbSize = 56;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _dragPosition = _resetAnimation.value);
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetToStart() {
    _resetAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.reset();
    _resetController.forward();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) async {
    if (_dragPosition >= _maxDrag * 0.85) {
      final success = await widget.onSubmit();
      if (!success && mounted) {
        _resetToStart();
      }
    } else {
      _resetToStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        _maxDrag = trackWidth - _thumbSize - 8;
        final progress = (_dragPosition / _maxDrag).clamp(0.0, 1.0);

        return Container(
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            color: Color.lerp(
              Colors.grey.shade200,
              Colors.orange.withValues(alpha: 0.2),
              progress,
            ),
            border: Border.all(
              color: Color.lerp(
                Colors.grey.shade300,
                Colors.orange,
                progress,
              )!,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                opacity: 1.0 - progress,
                duration: const Duration(milliseconds: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: _thumbSize.w),
                    Icon(Icons.arrow_forward, size: 16.sp, color: Colors.grey.shade500),
                    SizedBox(width: 4.w),
                    Text(
                      'Slide to Quick Deliver',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward, size: 16.sp, color: Colors.grey.shade500),
                  ],
                ),
              ),
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: _thumbSize.w,
                    height: _thumbSize.w - 8,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.orange,
                        AppColorsEnhanced.successGreen,
                        progress,
                      ),
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      progress > 0.85 ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
