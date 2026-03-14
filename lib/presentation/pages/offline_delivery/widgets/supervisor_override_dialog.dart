import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class SupervisorOverrideDialog extends StatefulWidget {
  final BookingVerification verification;
  final String distributionPointId;

  const SupervisorOverrideDialog({
    Key? key,
    required this.verification,
    required this.distributionPointId,
  }) : super(key: key);

  @override
  State<SupervisorOverrideDialog> createState() =>
      _SupervisorOverrideDialogState();
}

class _SupervisorOverrideDialogState extends State<SupervisorOverrideDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    final idempotencyKey = const Uuid().v4();

    final bloc = context.read<OfflineDeliveryBloc>();
    final companyId = widget.verification.company?.id ??
        (bloc.state is OfflineDeliveryLoaded
            ? (bloc.state as OfflineDeliveryLoaded).lastSelectedCompanyId
            : null);
    if (companyId == null) return;
    bloc.add(CreateToken(
      distributionPointId: widget.distributionPointId,
      consumerId: widget.verification.consumerId,
      consumerNumber: widget.verification.consumerNumber,
      orderNumber: widget.verification.orderNumberFromRpa ??
          widget.verification.orderNumber,
      idempotencyKey: idempotencyKey,
      bookingVerificationId: widget.verification.id,
      creationType: 'SUPERVISOR_OVERRIDE',
      overrideReason: _reasonController.text.trim(),
      companyId: companyId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenCreated && _isSubmitting) {
          Navigator.of(context).pop();
          context.showSuccessSnackBar(
            'Override token #${state.token.tokenNumber} created!',
          );
        } else if (state is OfflineDeliveryError && _isSubmitting) {
          setState(() => _isSubmitting = false);
        }
      },
      child: AlertDialog(
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: AppColorsEnhanced.warningYellow, size: 24.sp),
            SizedBox(width: AppSpacing.sm),
            const Expanded(child: Text('Supervisor Override')),
          ],
        ),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consumer info summary
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColorsEnhanced.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.verification.consumerName ??
                          widget.verification.consumerNumber ??
                          widget.verification.consumerId ??
                          'Unknown Consumer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.verification.consumerNumber != null) ...[
                      SizedBox(height: 2),
                      Text(
                        widget.verification.consumerNumber!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                        ),
                      ),
                    ],
                    if (widget.verification.errorMessage != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'Error: ${widget.verification.errorMessage}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.errorRed,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Override reason
              TextFormField(
                controller: _reasonController,
                enabled: !_isSubmitting,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Override Reason *',
                  hintText: 'Why is this override necessary?',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Override reason is required';
                  }
                  if (value.trim().length < 5) {
                    return 'Please provide a more detailed reason';
                  }
                  return null;
                },
              ),

              SizedBox(height: AppSpacing.sm),
              Text(
                'This will create a token despite the failed verification. Evidence upload will be required.',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.warningYellow,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.warningYellow,
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? SizedBox(
                    height: 18.sp,
                    width: 18.sp,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Issue Override'),
          ),
        ],
      ),
    );
  }
}
