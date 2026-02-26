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
        border: Border(
          left: BorderSide(
            color: _getBorderColor(),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.ujjwalaLocationSection,
                style: AppTextStyles.h4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isLoading)
                IconButton(
                  onPressed: () {
                    context.read<UjjwalaInstallationsBloc>().add(
                          const FetchLocation(),
                        );
                  },
                  icon: Icon(
                    Icons.refresh,
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  tooltip: context.l10n.ujjwalaRefreshLocation,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          if (isLoading)
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: AppColorsEnhanced.brandBlue,
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    context.l10n.ujjwalaFetchingLocation,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.secondaryText,
                    ),
                  ),
                ],
              ),
            )
          else if (errorMessage != null)
            Column(
              children: [
                Icon(
                  Icons.location_off,
                  size: 48.r,
                  color: AppColorsEnhanced.errorRed,
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  errorMessage!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorsEnhanced.errorRed,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else if (location != null)
            Column(
              children: [
                _buildLocationRow(
                  context,
                  Icons.location_on,
                  context.l10n.ujjwalaLatitude,
                  location!.latitude.toStringAsFixed(6),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildLocationRow(
                  context,
                  Icons.location_on,
                  context.l10n.ujjwalaLongitude,
                  location!.longitude.toStringAsFixed(6),
                ),
                SizedBox(height: AppSpacing.sm),
                _buildLocationRow(
                  context,
                  Icons.gps_fixed,
                  context.l10n.ujjwalaAccuracy,
                  '${location!.accuracy.toStringAsFixed(1)} m',
                ),
                if (location!.accuracy < 50)
                  Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16.r,
                          color: AppColorsEnhanced.successGreen,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Good accuracy',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          else
            Center(
              child: Text(
                context.l10n.ujjwalaLocationRequired,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20.r,
          color: AppColorsEnhanced.brandBlue,
        ),
        SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 100.w,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBorderColor() {
    if (errorMessage != null) {
      return AppColorsEnhanced.errorRed;
    } else if (location != null) {
      return AppColorsEnhanced.successGreen;
    } else {
      return AppColorsEnhanced.warningYellow;
    }
  }
}
