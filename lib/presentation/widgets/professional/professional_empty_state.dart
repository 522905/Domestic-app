import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/app_icons.dart';
import 'professional_button.dart';

/// Professional empty state widget with icon, message, and optional action
/// Use for: Empty lists, no search results, no data states
class ProfessionalEmptyState extends StatelessWidget {
  /// Main message/title
  final String message;

  /// Optional description text
  final String? description;

  /// Icon to display (defaults to empty icon)
  final IconData? icon;

  /// Optional action button text
  final String? actionText;

  /// Optional action button callback
  final VoidCallback? onAction;

  /// Size of the empty state (compact or normal)
  final bool compact;

  const ProfessionalEmptyState({
    Key? key,
    required this.message,
    this.description,
    this.icon,
    this.actionText,
    this.onAction,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: compact ? AppSpacing.paddingMD : AppSpacing.paddingXL,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: AppSpacing.paddingXL,
              decoration: BoxDecoration(
                color: AppColorsEnhanced.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? AppIcons.empty,
                size: compact ? AppSpacing.iconXL : AppSpacing.iconXXL,
                color: AppColorsEnhanced.disabledText,
              ),
            ),

            SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),

            // Message
            Text(
              message,
              style: compact
                  ? AppTextStyles.h4
                  : AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Action Button
            if (actionText != null && onAction != null) ...[
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              ProfessionalButton(
                text: actionText!,
                onPressed: onAction,
                icon: AppIcons.add,
                variant: ButtonVariant.primary,
                size: compact ? ButtonSize.small : ButtonSize.medium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
