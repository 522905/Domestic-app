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
  late final TextEditingController _emptiesController;
  bool _isDelivering = false;

  // Derive hints from available_actions
  Map<String, dynamic>? get _deliverAction => widget.token.getAction('deliver');

  bool get _showCashField {
    final action = _deliverAction;
    if (action != null) {
      // API tells us whether to collect cash at delivery
      return action['collect_cash_at_delivery'] == true;
    }
    // Fallback: show cash for non-obligation tokens, or if cash_arrangement is COLLECT_AT_DELIVERY
    if (!widget.token.isObligation) return true;
    return widget.token.obligationDetail?.cashArrangement == 'COLLECT_AT_DELIVERY';
  }

  bool get _showEmptiesField {
    final action = _deliverAction;
    if (action != null) {
      // record_empties = DEFERRED (user picks count), collect_empties = SAME_DAY (auto)
      return action['record_empties_at_delivery'] == true;
    }
    // Fallback
    final detail = widget.token.obligationDetail;
    return widget.token.isObligation &&
        detail != null &&
        detail.emptyArrangement == 'DEFERRED' &&
        detail.emptiesExpected > 0;
  }

  bool get _showEmptiesAutoNote {
    final action = _deliverAction;
    return action != null && action['collect_empties_at_delivery'] == true;
  }

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(
      text: _showCashField
          ? (widget.token.cashToCollect?.toStringAsFixed(2) ?? '')
          : '',
    );
    _dacCodeController.text = widget.token.dacCode ?? '';
    final expected = _deliverAction?['empties_expected'] ??
        widget.token.obligationDetail?.emptiesExpected ?? 0;
    _emptiesController = TextEditingController(
      text: _showEmptiesField ? expected.toString() : '',
    );
  }

  @override
  void dispose() {
    _cashController.dispose();
    _dacCodeController.dispose();
    _emptiesController.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    if (!_formKey.currentState!.validate()) return;

    final cashCollected = _showCashField
        ? (_cashController.text.trim().isNotEmpty
            ? double.tryParse(_cashController.text.trim())
            : null)
        : null;
    final emptiesCollected = _showEmptiesField
        ? (_emptiesController.text.trim().isNotEmpty
            ? int.tryParse(_emptiesController.text.trim())
            : null)
        : null;

    setState(() => _isDelivering = true);

    context.read<OfflineDeliveryBloc>().add(DeliverToken(
      tokenId: widget.token.id,
      cashCollected: cashCollected,
      dacCode: _dacCodeController.text.trim().isNotEmpty
          ? _dacCodeController.text.trim()
          : null,
      emptiesCollected: emptiesCollected,
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

                // SAME_DAY empties auto-complete note
                if (_showEmptiesAutoNote) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.sm),
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.successGreen.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsEnhanced.successGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: AppColorsEnhanced.successGreen),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'All empties will be marked as collected automatically',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.successGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // DEFERRED empties — user enters count collected now
                if (_showEmptiesField) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.sm),
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.infoBlue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsEnhanced.infoBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.swap_vert, size: 16, color: AppColorsEnhanced.infoBlue),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          '${_deliverAction?['empties_expected'] ?? widget.token.obligationDetail?.emptiesExpected ?? 0} empties expected (deferred)',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.infoBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextFormField(
                    controller: _emptiesController,
                    enabled: !_isDelivering,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Empties Collected Now',
                      hintText: 'Enter 0 if none collected now',
                      prefixIcon: const Icon(Icons.swap_vert),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final count = int.tryParse(value.trim());
                        if (count == null || count < 0) {
                          return 'Enter a valid count';
                        }
                        final max = _deliverAction?['empties_expected'] ?? widget.token.obligationDetail?.emptiesExpected ?? 0;
                        if (count > max) {
                          return 'Cannot exceed $max';
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: AppSpacing.md),
                ],

                // Deferred cash info note
                if (widget.token.isObligation && !_showCashField &&
                    widget.token.obligationDetail?.cashArrangement == 'DEFERRED') ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.sm),
                    margin: EdgeInsets.only(bottom: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.warningYellow.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsEnhanced.warningYellow.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.schedule, size: 16, color: AppColorsEnhanced.warningYellow),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Cash deferred — due ${widget.token.obligationDetail?.cashDueDate != null ? '${widget.token.obligationDetail!.cashDueDate!.day}/${widget.token.obligationDetail!.cashDueDate!.month}/${widget.token.obligationDetail!.cashDueDate!.year}' : 'later'}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.warningYellow,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Cash Collected (only when collect_cash_at_delivery)
                if (_showCashField)
                TextFormField(
                  controller: _cashController,
                  enabled: !_isDelivering,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Cash Collected',
                    hintText: 'Enter amount collected',
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final amount = double.tryParse(value.trim());
                      if (amount == null || amount < 0) {
                        return 'Enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),

                // DAC Code
                TextFormField(
                  controller: _dacCodeController,
                  enabled: !_isDelivering,
                  decoration: InputDecoration(
                    labelText: 'DAC Code',
                    hintText: 'Enter 6-digit DAC Code',
                    prefixIcon: const Icon(Icons.qr_code),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (value.trim().length != 6) {
                      return 'Enter 6-digit DAC Code';
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.md),
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
