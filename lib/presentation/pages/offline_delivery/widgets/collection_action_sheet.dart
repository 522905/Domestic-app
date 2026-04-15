import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/obligation_collection/obligation_collection_bloc.dart';
import '../../../blocs/obligation_collection/obligation_collection_event.dart';
import '../../../blocs/obligation_collection/obligation_collection_state.dart';
import '../../../widgets/professional_snackbar.dart';

class CollectionActionSheet extends StatefulWidget {
  final OfflineDeliveryToken token;

  const CollectionActionSheet({Key? key, required this.token})
      : super(key: key);

  @override
  State<CollectionActionSheet> createState() => _CollectionActionSheetState();
}

class _CollectionActionSheetState extends State<CollectionActionSheet> {
  final _emptiesController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _emptiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.token.obligationDetail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return BlocListener<ObligationCollectionBloc, ObligationCollectionState>(
      listener: (context, state) {
        if (state is EmptiesCollected || state is CashCollected) {
          Navigator.of(context).pop();
        } else if (state is ObligationCollectionError) {
          setState(() => _isProcessing = false);
        }
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // Token info
              Text(
                'Token #${widget.token.tokenNumber ?? '?'} - ${widget.token.displayName}',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (detail.directorDisplayName != null)
                Text(
                  'Directed by: ${detail.directorDisplayName}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                  ),
                ),
              Text(
                '${detail.deliveryTypeDisplay} - ${detail.itemDisplayName} x${detail.quantity}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
              SizedBox(height: AppSpacing.lg),

              // Empties section
              if (detail.hasPendingEmpties) ...[
                _buildSectionHeader(
                  icon: Icons.swap_vert,
                  title: 'Empty Collection',
                  color: detail.isOverdueEmpties
                      ? AppColorsEnhanced.errorRed
                      : AppColorsEnhanced.warningYellow,
                ),
                SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: AppColorsEnhanced.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expected: ${detail.emptiesExpected}'),
                          Text('Collected: ${detail.emptiesCollected}'),
                          Text(
                            'Remaining: ${detail.emptiesRemaining}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColorsEnhanced.warningYellow,
                            ),
                          ),
                        ],
                      ),
                      if (detail.emptiesDueDate != null) ...[
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Due: ${detail.emptiesDueDate!.day}/${detail.emptiesDueDate!.month}/${detail.emptiesDueDate!.year}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: detail.isOverdueEmpties
                                ? AppColorsEnhanced.errorRed
                                : AppColorsEnhanced.secondaryText,
                            fontWeight: detail.isOverdueEmpties
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emptiesController,
                        enabled: !_isProcessing,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Count to collect',
                          hintText: '${detail.emptiesRemaining}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    ElevatedButton(
                      onPressed: _isProcessing ? null : _collectEmpties,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsEnhanced.brandBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      child: _isProcessing
                          ? SizedBox(
                              height: 16.h,
                              width: 16.w,
                              child: const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Collect'),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.lg),
              ],

              // Cash section
              if (detail.hasPendingCash) ...[
                _buildSectionHeader(
                  icon: Icons.payments,
                  title: 'Cash Collection',
                  color: detail.isOverdueCash
                      ? AppColorsEnhanced.errorRed
                      : AppColorsEnhanced.warningYellow,
                ),
                SizedBox(height: AppSpacing.sm),
                if (detail.cashDueDate != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Text(
                      'Due: ${detail.cashDueDate!.day}/${detail.cashDueDate!.month}/${detail.cashDueDate!.year}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: detail.isOverdueCash
                            ? AppColorsEnhanced.errorRed
                            : AppColorsEnhanced.secondaryText,
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _collectCash,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorsEnhanced.successGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: _isProcessing
                        ? SizedBox(
                            height: 16.h,
                            width: 16.w,
                            child: const CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Mark Cash Collected'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _collectEmpties() {
    final countText = _emptiesController.text.trim();
    if (countText.isEmpty) {
      context.showWarningSnackBar('Enter the number of empties collected');
      return;
    }
    final count = int.tryParse(countText);
    if (count == null || count < 1) {
      context.showWarningSnackBar('Enter a valid count');
      return;
    }
    final remaining = widget.token.obligationDetail?.emptiesRemaining ?? 0;
    if (count > remaining) {
      context.showWarningSnackBar('Cannot exceed remaining ($remaining)');
      return;
    }

    setState(() => _isProcessing = true);
    context.read<ObligationCollectionBloc>().add(CollectEmpties(
      tokenId: widget.token.id,
      count: count,
    ));
  }

  void _collectCash() {
    setState(() => _isProcessing = true);
    context.read<ObligationCollectionBloc>().add(CollectCash(
      tokenId: widget.token.id,
    ));
  }
}
