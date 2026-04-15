import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/service_provider.dart';
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

  // System obligation support
  String _initiationSource = 'WALK_IN';
  bool _isLookingUp = false;
  List<Map<String, dynamic>> _lookupRecords = [];
  int? _selectedDeliveryRecordId;
  String? _lookupError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _lookupDeliveryRecords() async {
    final consumerNumber = widget.verification.consumerNumber;
    if (consumerNumber == null || consumerNumber.isEmpty) {
      setState(() => _lookupError = 'No consumer number available');
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _lookupRecords = [];
    });

    try {
      final apiService = await ServiceProvider.getApiService();
      final response = await apiService.lookupConsumer(consumerNumber);
      final results = (response['results'] ?? []) as List<dynamic>;
      if (mounted) {
        setState(() {
          _lookupRecords =
              results.map((r) => r as Map<String, dynamic>).toList();
          _isLookingUp = false;
          if (_lookupRecords.isEmpty) {
            _lookupError = 'No delivery records found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
          _lookupError = 'Lookup failed: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
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
      initiationSource: _initiationSource,
      sourceDeliveryRecordId: _initiationSource == 'SYSTEM_OBLIGATION'
          ? _selectedDeliveryRecordId
          : null,
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
        content: SingleChildScrollView(
          child: Form(
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

                // Initiation source toggle
                Text(
                  'Override Type',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceToggle(
                        label: 'Walk-in',
                        value: 'WALK_IN',
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _buildSourceToggle(
                        label: 'System Obligation',
                        value: 'SYSTEM_OBLIGATION',
                      ),
                    ),
                  ],
                ),

                // System obligation section
                if (_initiationSource == 'SYSTEM_OBLIGATION') ...[
                  SizedBox(height: AppSpacing.md),
                  _buildLookupSection(),
                ],

                SizedBox(height: AppSpacing.md),

                // Override reason
                TextFormField(
                  controller: _reasonController,
                  enabled: !_isSubmitting,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Override Reason *',
                    hintText: _initiationSource == 'SYSTEM_OBLIGATION'
                        ? 'e.g., Sale already posted - consumer collecting'
                        : 'Why is this override necessary?',
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
                  _initiationSource == 'SYSTEM_OBLIGATION'
                      ? 'Sale was already posted in SDMS. No reconciliation needed.'
                      : 'This will create a token despite the failed verification. Evidence upload will be required.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _initiationSource == 'SYSTEM_OBLIGATION'
                        ? AppColorsEnhanced.infoBlue
                        : AppColorsEnhanced.warningYellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
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

  Widget _buildSourceToggle({
    required String label,
    required String value,
  }) {
    final isSelected = _initiationSource == value;
    return GestureDetector(
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _initiationSource = value;
                _selectedDeliveryRecordId = null;
                _lookupRecords = [];
                _lookupError = null;
              });
            },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsEnhanced.brandBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? AppColorsEnhanced.brandBlue
                  : AppColorsEnhanced.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildLookupSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.infoBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColorsEnhanced.infoBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, size: 16.sp, color: AppColorsEnhanced.infoBlue),
              SizedBox(width: 4.w),
              Text(
                'Delivery Record Lookup',
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColorsEnhanced.infoBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          if (_isLookingUp)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_lookupRecords.isNotEmpty) ...[
            ..._lookupRecords.map((record) {
              final recordId = record['id'] as int?;
              final isSelected = _selectedDeliveryRecordId == recordId;
              final orderNumber = record['order_number'] ?? 'N/A';
              final date = record['date'] ?? '';
              return GestureDetector(
                onTap: () => setState(
                    () => _selectedDeliveryRecordId = recordId),
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 4.h),
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColorsEnhanced.brandBlue.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColorsEnhanced.brandBlue
                          : AppColorsEnhanced.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18.sp,
                        color: isSelected
                            ? AppColorsEnhanced.brandBlue
                            : AppColorsEnhanced.secondaryText,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order: $orderNumber',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (date.isNotEmpty)
                              Text(
                                date,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText,
                                  fontSize: 10.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            if (_lookupError != null)
              Text(
                _lookupError!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.errorRed,
                ),
              ),
            SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _lookupDeliveryRecords,
                icon: Icon(Icons.search, size: 16.sp),
                label: const Text('Lookup Sales'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColorsEnhanced.infoBlue,
                  side: BorderSide(color: AppColorsEnhanced.infoBlue),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
