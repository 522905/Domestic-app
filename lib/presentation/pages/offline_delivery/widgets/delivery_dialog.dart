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

class DeliveryDialog extends StatefulWidget {
  final OfflineDeliveryToken token;
  final bool requireDacCode;

  const DeliveryDialog({
    Key? key,
    required this.token,
    this.requireDacCode = false,
  }) : super(key: key);

  @override
  State<DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<DeliveryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cashController;
  final _dacCodeController = TextEditingController();
  bool _isDelivering = false;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(
      text: widget.token.cashToCollect?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _dacCodeController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final cashCollected = double.tryParse(_cashController.text.trim());
    if (cashCollected == null) return;

    setState(() => _isDelivering = true);

    context.read<OfflineDeliveryBloc>().add(DeliverToken(
      tokenId: widget.token.id,
      cashCollected: cashCollected,
      dacCode: widget.requireDacCode && _dacCodeController.text.trim().isNotEmpty
          ? _dacCodeController.text.trim()
          : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenDelivered && state.token.id == widget.token.id) {
          Navigator.of(context).pop();
          context.showSuccessSnackBar(state.message);
        } else if (state is OfflineDeliveryError) {
          setState(() => _isDelivering = false);
          context.showErrorSnackBar(state.message);
        } else if (state is OfflineDeliveryLoaded && _isDelivering) {
          // Loaded state after error recovery — dismiss delivering state
          setState(() => _isDelivering = false);
        }
      },
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.local_shipping, color: AppColorsEnhanced.successGreen),
            SizedBox(width: AppSpacing.sm),
            const Text('Mark Delivered'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Token summary
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Token #${widget.token.tokenNumber ?? '?'}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        widget.token.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                        ),
                      ),
                      if (widget.token.consumerNumber != null) ...[
                        SizedBox(height: 2),
                        Text(
                          widget.token.consumerNumber!,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Cash Collected
                TextFormField(
                  controller: _cashController,
                  enabled: !_isDelivering,
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

                // DAC Code (if required and not already set)
                if (widget.requireDacCode) ...[
                  TextFormField(
                    controller: _dacCodeController,
                    enabled: !_isDelivering,
                    decoration: InputDecoration(
                      labelText: 'DAC Code',
                      hintText: 'Enter DAC Code (digits only)',
                      prefixIcon: const Icon(Icons.qr_code),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isDelivering ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsEnhanced.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: _isDelivering ? null : _handleConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: _isDelivering
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                : const Text('Confirm Delivery'),
          ),
        ],
      ),
    );
  }
}
