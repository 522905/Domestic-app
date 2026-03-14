import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class TokenCorrectionDialog extends StatefulWidget {
  final OfflineDeliveryToken token;

  const TokenCorrectionDialog({Key? key, required this.token}) : super(key: key);

  @override
  State<TokenCorrectionDialog> createState() => _TokenCorrectionDialogState();
}

class _TokenCorrectionDialogState extends State<TokenCorrectionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _consumerIdController;
  late final TextEditingController _consumerNumberController;
  late final TextEditingController _orderNumberController;
  late final TextEditingController _dacCodeController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _consumerIdController = TextEditingController(text: widget.token.consumerId ?? '');
    _consumerNumberController = TextEditingController(text: widget.token.consumerNumber ?? '');
    _orderNumberController = TextEditingController(text: widget.token.orderNumber ?? '');
    _dacCodeController = TextEditingController(text: widget.token.dacCode ?? '');
  }

  @override
  void dispose() {
    _consumerIdController.dispose();
    _consumerNumberController.dispose();
    _orderNumberController.dispose();
    _dacCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final consumerId = _consumerIdController.text.trim();
    final consumerNumber = _consumerNumberController.text.trim();

    if (consumerId.isEmpty && consumerNumber.isEmpty) {
      context.showWarningSnackBar('At least one of Consumer ID or Consumer Number is required');
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<OfflineDeliveryBloc>().add(CorrectToken(
      tokenId: widget.token.id,
      consumerId: consumerId.isNotEmpty ? consumerId : null,
      consumerNumber: consumerNumber.isNotEmpty ? consumerNumber : null,
      orderNumber: _orderNumberController.text.trim().isNotEmpty
          ? _orderNumberController.text.trim()
          : null,
      dacCode: _dacCodeController.text.trim().isNotEmpty
          ? _dacCodeController.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenCorrected && state.token.id == widget.token.id) {
          Navigator.of(context).pop();
          context.showSuccessSnackBar('Token corrected successfully');
        } else if (state is OfflineDeliveryError) {
          setState(() => _isSubmitting = false);
          context.showErrorSnackBar(state.message);
        } else if (state is OfflineDeliveryLoaded && _isSubmitting) {
          setState(() => _isSubmitting = false);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: AppColorsEnhanced.warningYellow),
            SizedBox(width: AppSpacing.sm),
            const Text('Correct Token Data'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning with reconciliation error
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.warningYellow.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsEnhanced.warningYellow.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColorsEnhanced.warningYellow,
                        size: 20.sp,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          widget.token.reconciliationError ?? 'Data correction required',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Consumer ID
                TextFormField(
                  controller: _consumerIdController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Consumer ID',
                    hintText: 'e.g. 2-123456789012',
                    prefixIcon: const Icon(Icons.tag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final pattern = RegExp(r'^\d{1,2}-\d{12}$');
                    if (!pattern.hasMatch(value.trim())) {
                      return 'Format: 1-2 digits, dash, 12 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),

                // Consumer Number
                TextFormField(
                  controller: _consumerNumberController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Consumer Number',
                    hintText: '10-digit Consumer Number',
                    prefixIcon: const Icon(Icons.numbers),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (value.trim().length != 10) {
                      return 'Consumer Number must be exactly 10 digits';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),

                // Order Number
                TextFormField(
                  controller: _orderNumberController,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    labelText: 'Order Number',
                    hintText: 'Enter order number',
                    prefixIcon: const Icon(Icons.receipt_long),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // DAC Code
                TextFormField(
                  controller: _dacCodeController,
                  enabled: !_isSubmitting,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'DAC Code',
                    hintText: 'Enter DAC Code',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsEnhanced.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.warningYellow,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                : const Text('Submit Correction'),
          ),
        ],
      ),
    );
  }
}
