import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/ujjwala/ujjwala_location.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_bloc.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_event.dart';

class LocationWidget extends StatelessWidget {
  final UjjwalaLocation? location;
  final bool isLoading;
  final String? errorMessage;

  const LocationWidget({
    Key? key,
    this.location,
    this.isLoading = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _getBorderColor(), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Loading state — inline spinner
    if (isLoading) {
      return Row(children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColorsEnhanced.brandBlue,
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        Text(
          context.l10n.ujjwalaFetchingLocation,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColorsEnhanced.secondaryText),
        ),
      ]);
    }

    // Error state — inline error + retry
    if (errorMessage != null) {
      return Row(children: [
        Icon(Icons.location_off,
            color: AppColorsEnhanced.errorRed, size: 18.r),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            errorMessage!,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColorsEnhanced.errorRed),
          ),
        ),
        TextButton(
          onPressed: () => context
              .read<UjjwalaInstallationsBloc>()
              .add(const FetchLocation()),
          style: TextButton.styleFrom(
            padding:
                EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Retry',
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColorsEnhanced.brandBlue),
          ),
        ),
      ]);
    }

    // Location captured — coords + accuracy + refresh button
    if (location != null) {
      return Row(children: [
        Icon(Icons.gps_fixed,
            color: AppColorsEnhanced.successGreen, size: 20.r),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${location!.latitude.toStringAsFixed(5)}, '
                '${location!.longitude.toStringAsFixed(5)}',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Row(children: [
                Text(
                  '${context.l10n.ujjwalaAccuracy}: '
                  '${location!.accuracy.toStringAsFixed(1)} m',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColorsEnhanced.secondaryText),
                ),
                if (location!.accuracy < 50) ...[
                  SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.successGreen
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Good',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ]),
            ],
          ),
        ),
        IconButton(
          onPressed: () => context
              .read<UjjwalaInstallationsBloc>()
              .add(const FetchLocation()),
          icon: Icon(Icons.refresh,
              color: AppColorsEnhanced.brandBlue, size: 20.r),
          tooltip: context.l10n.ujjwalaRefreshLocation,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 32.r, minHeight: 32.r),
        ),
      ]);
    }

    // No location yet — prompt with Get button
    return Row(children: [
      Icon(Icons.location_searching,
          color: AppColorsEnhanced.secondaryText, size: 20.r),
      SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Text(
          context.l10n.ujjwalaLocationRequired,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColorsEnhanced.secondaryText),
        ),
      ),
      SizedBox(width: AppSpacing.sm),
      ElevatedButton.icon(
        onPressed: () => context
            .read<UjjwalaInstallationsBloc>()
            .add(const FetchLocation()),
        icon: Icon(Icons.my_location, size: 14.r),
        label: Text('Get', style: AppTextStyles.labelSmall),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsEnhanced.brandBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    ]);
  }

  Color _getBorderColor() {
    if (errorMessage != null) return AppColorsEnhanced.errorRed;
    if (location != null) return AppColorsEnhanced.successGreen;
    return AppColorsEnhanced.warningYellow;
  }
}
