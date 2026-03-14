import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class VerificationForm extends StatefulWidget {
  final String distributionPointId;
  final int companyId;

  const VerificationForm({
    Key? key,
    required this.distributionPointId,
    required this.companyId,
  }) : super(key: key);

  @override
  State<VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends State<VerificationForm> {
  final _formKey = GlobalKey<FormState>();
  final _consumerIdController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _orderNumberController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _consumerIdController.dispose();
    _consumerNumberController.dispose();
    _orderNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final consumerId = _consumerIdController.text.trim();
    final consumerNumber = _consumerNumberController.text.trim();

    if (consumerId.isEmpty && consumerNumber.isEmpty) {
      context.showWarningSnackBar(
          'At least one of Consumer ID or Consumer Number is required');
      return;
    }

    setState(() => _isSubmitting = true);

    final idempotencyKey = const Uuid().v4();

    context.read<OfflineDeliveryBloc>().add(CreateVerification(
      distributionPointId: widget.distributionPointId,
      consumerId: consumerId.isNotEmpty ? '7$consumerId' : null,
      consumerNumber: consumerNumber.isNotEmpty ? '7$consumerNumber' : null,
      orderNumber: _orderNumberController.text.trim().isNotEmpty
          ? '2-${_orderNumberController.text.trim()}'
          : null,
      idempotencyKey: idempotencyKey,
      companyId: widget.companyId,
    ));
  }

  void _resetForm() {
    _consumerIdController.clear();
    _consumerNumberController.clear();
    _orderNumberController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is VerificationCreated && _isSubmitting) {
          setState(() => _isSubmitting = false);
          _resetForm();
          context.showSuccessSnackBar('Verification submitted');
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
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          if (value.trim().length != 12) {
                            return 'Enter 12 digits after 2-';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.xl),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorsEnhanced.brandBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                          ),
                          icon: _isSubmitting
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.w,
                                  ),
                                )
                              : Icon(Icons.send, size: 20.sp),
                          label: Text(
                            _isSubmitting ? 'Submitting...' : 'Submit Verification',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
