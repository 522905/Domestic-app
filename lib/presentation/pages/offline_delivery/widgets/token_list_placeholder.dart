import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../domain/entities/offline_delivery/distribution_point.dart';
import '../../../../domain/entities/offline_delivery/offline_system_status.dart';

class TokenListPlaceholder extends StatelessWidget {
  final DistributionPoint? selectedPoint;
  final OfflineSystemStatus status;

  const TokenListPlaceholder({
    Key? key,
    this.selectedPoint,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedPoint == null) {
      return _buildMessage(
        icon: Icons.touch_app,
        text: 'Select a distribution point to begin',
      );
    }

    final String hint;
    final IconData icon;

    if (status.isManual) {
      hint = 'Ready to create tokens directly';
      icon = Icons.add_circle_outline;
    } else {
      hint = 'Ready for booking verification';
      icon = Icons.verified_user_outlined;
    }

    return _buildMessage(icon: icon, text: hint);
  }

  Widget _buildMessage({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColorsEnhanced.secondaryText.withOpacity(0.4),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
