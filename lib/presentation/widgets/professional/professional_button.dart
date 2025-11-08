import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/borders.dart';

/// Professional button widget with gradient, icons, and loading states
/// Supports primary, secondary, success, error, and warning variants
class ProfessionalButton extends StatelessWidget {
  /// Button text
  final String text;

  /// Optional leading icon
  final IconData? icon;

  /// Optional trailing icon
  final IconData? trailingIcon;

  /// Button tap callback
  final VoidCallback? onPressed;

  /// Button variant (primary, secondary, success, error, warning)
  final ButtonVariant variant;

  /// Button size (small, medium, large)
  final ButtonSize size;

  /// Whether button is in loading state
  final bool isLoading;

  /// Whether button takes full width
  final bool fullWidth;

  /// Whether button is disabled
  final bool isDisabled;

  const ProfessionalButton({
    Key? key,
    required this.text,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool disabled = isDisabled || isLoading || onPressed == null;

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: _getBorderRadius(),
          child: Container(
            decoration: _getDecoration(disabled),
            padding: _getPadding(),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          _buildLoader()
        else if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(),
            color: _getTextColor(),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: _getTextStyle(),
          textAlign: TextAlign.center,
        ),
        if (!isLoading && trailingIcon != null) ...[
          SizedBox(width: AppSpacing.sm),
          Icon(
            trailingIcon,
            size: _getIconSize(),
            color: _getTextColor(),
          ),
        ],
      ],
    );
  }

  Widget _buildLoader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _getIconSize(),
          width: _getIconSize(),
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
      ],
    );
  }

  BoxDecoration _getDecoration(bool disabled) {
    if (disabled) {
      return BoxDecoration(
        color: AppColorsEnhanced.disabled,
        borderRadius: _getBorderRadius(),
      );
    }

    switch (variant) {
      case ButtonVariant.primary:
        return AppBorders.primaryButtonDecoration;
      case ButtonVariant.secondary:
        return AppBorders.secondaryButtonDecoration;
      case ButtonVariant.success:
        return AppBorders.successButtonDecoration;
      case ButtonVariant.error:
        return AppBorders.errorButtonDecoration;
      case ButtonVariant.warning:
        return AppBorders.warningButtonDecoration;
    }
  }

  BorderRadius _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.roundedMD;
      case ButtonSize.medium:
        return AppSpacing.roundedLG;
      case ButtonSize.large:
        return AppSpacing.roundedXL;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        );
      case ButtonSize.medium:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        );
      case ButtonSize.large:
        return EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        );
    }
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (size) {
      case ButtonSize.small:
        baseStyle = AppTextStyles.buttonSmall;
        break;
      case ButtonSize.medium:
        baseStyle = AppTextStyles.buttonMedium;
        break;
      case ButtonSize.large:
        baseStyle = AppTextStyles.buttonLarge;
        break;
    }

    return baseStyle.copyWith(color: _getTextColor());
  }

  Color _getTextColor() {
    if (variant == ButtonVariant.secondary) {
      return AppColorsEnhanced.brandBlue;
    }
    return AppColorsEnhanced.inverseText;
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return AppSpacing.iconSM;
      case ButtonSize.medium:
        return AppSpacing.iconMD;
      case ButtonSize.large:
        return AppSpacing.iconLG;
    }
  }
}

/// Button variant enum
enum ButtonVariant {
  primary,
  secondary,
  success,
  error,
  warning,
}

/// Button size enum
enum ButtonSize {
  small,
  medium,
  large,
}
