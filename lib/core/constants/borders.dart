import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors_enhanced.dart';
import 'spacing.dart';

/// Professional border styles for consistent design
/// Includes borders, shadows, and decorations
class AppBorders {
  // ==================== BORDER WIDTHS ====================

  /// Thin border - 1dp
  static final double thin = 1.w;

  /// Normal border - 1.5dp
  static final double normal = 1.5.w;

  /// Thick border - 2dp
  static final double thick = 2.w;

  /// Extra thick border - 3dp
  static final double extraThick = 3.w;

  // ==================== BASIC BORDERS ====================

  /// Default border (1dp, light gray)
  static Border get defaultBorder => Border.all(
        color: AppColorsEnhanced.border,
        width: thin,
      );

  /// Input border (1dp, gray)
  static Border get inputBorder => Border.all(
        color: AppColorsEnhanced.borderInput,
        width: thin,
      );

  /// Focused border (2dp, blue)
  static Border get focusedBorder => Border.all(
        color: AppColorsEnhanced.borderFocused,
        width: thick,
      );

  /// Error border (2dp, red)
  static Border get errorBorder => Border.all(
        color: AppColorsEnhanced.borderError,
        width: thick,
      );

  /// Success border (2dp, green)
  static Border get successBorder => Border.all(
        color: AppColorsEnhanced.successGreen,
        width: thick,
      );

  /// Warning border (2dp, yellow)
  static Border get warningBorder => Border.all(
        color: AppColorsEnhanced.warningYellow,
        width: thick,
      );

  // ==================== OUTLINED BORDERS (for TextField) ====================

  /// Default outline border
  static OutlineInputBorder get outlineDefault => OutlineInputBorder(
        borderRadius: AppSpacing.roundedMD,
        borderSide: BorderSide(
          color: AppColorsEnhanced.borderInput,
          width: thin,
        ),
      );

  /// Focused outline border
  static OutlineInputBorder get outlineFocused => OutlineInputBorder(
        borderRadius: AppSpacing.roundedMD,
        borderSide: BorderSide(
          color: AppColorsEnhanced.borderFocused,
          width: thick,
        ),
      );

  /// Error outline border
  static OutlineInputBorder get outlineError => OutlineInputBorder(
        borderRadius: AppSpacing.roundedMD,
        borderSide: BorderSide(
          color: AppColorsEnhanced.borderError,
          width: thick,
        ),
      );

  /// Disabled outline border
  static OutlineInputBorder get outlineDisabled => OutlineInputBorder(
        borderRadius: AppSpacing.roundedMD,
        borderSide: BorderSide(
          color: AppColorsEnhanced.disabled,
          width: thin,
        ),
      );

  // ==================== BOX SHADOWS ====================

  /// Light shadow (subtle elevation)
  static List<BoxShadow> get shadowLight => [
        BoxShadow(
          color: AppColorsEnhanced.shadowLight,
          offset: const Offset(0, 2),
          blurRadius: 4.r,
          spreadRadius: 0,
        ),
      ];

  /// Medium shadow (card elevation)
  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: AppColorsEnhanced.shadowMedium,
          offset: const Offset(0, 4),
          blurRadius: 8.r,
          spreadRadius: 0,
        ),
      ];

  /// Dark shadow (modal/dialog elevation)
  static List<BoxShadow> get shadowDark => [
        BoxShadow(
          color: AppColorsEnhanced.shadowDark,
          offset: const Offset(0, 8),
          blurRadius: 16.r,
          spreadRadius: 0,
        ),
      ];

  /// Button shadow (subtle button elevation)
  static List<BoxShadow> get shadowButton => [
        BoxShadow(
          color: AppColorsEnhanced.shadowLight,
          offset: const Offset(0, 2),
          blurRadius: 4.r,
          spreadRadius: 0,
        ),
      ];

  /// Card shadow (standard card elevation)
  static List<BoxShadow> get shadowCard => [
        BoxShadow(
          color: AppColorsEnhanced.shadowLight,
          offset: const Offset(0, 2),
          blurRadius: 6.r,
          spreadRadius: 0,
        ),
      ];

  // ==================== BOX DECORATIONS ====================

  /// Default card decoration (white background, rounded, shadow)
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColorsEnhanced.cardBackground,
        borderRadius: AppSpacing.roundedLG,
        boxShadow: shadowCard,
        border: Border.all(
          color: AppColorsEnhanced.border,
          width: thin,
        ),
      );

  /// Card with gradient decoration
  static BoxDecoration get cardGradientDecoration => BoxDecoration(
        gradient: AppColorsEnhanced.cardGradient,
        borderRadius: AppSpacing.roundedLG,
        boxShadow: shadowCard,
        border: Border.all(
          color: AppColorsEnhanced.border,
          width: thin,
        ),
      );

  /// Primary button decoration (gradient, rounded, shadow)
  static BoxDecoration get primaryButtonDecoration => BoxDecoration(
        gradient: AppColorsEnhanced.primaryGradient,
        borderRadius: AppSpacing.roundedXL,
        boxShadow: shadowButton,
      );

  /// Secondary button decoration (border, rounded, no gradient)
  static BoxDecoration get secondaryButtonDecoration => BoxDecoration(
        color: AppColorsEnhanced.background,
        borderRadius: AppSpacing.roundedXL,
        border: Border.all(
          color: AppColorsEnhanced.brandBlue,
          width: thick,
        ),
      );

  /// Success button decoration
  static BoxDecoration get successButtonDecoration => BoxDecoration(
        gradient: AppColorsEnhanced.successGradient,
        borderRadius: AppSpacing.roundedXL,
        boxShadow: shadowButton,
      );

  /// Error button decoration
  static BoxDecoration get errorButtonDecoration => BoxDecoration(
        gradient: AppColorsEnhanced.errorGradient,
        borderRadius: AppSpacing.roundedXL,
        boxShadow: shadowButton,
      );

  /// Warning button decoration
  static BoxDecoration get warningButtonDecoration => BoxDecoration(
        gradient: AppColorsEnhanced.warningGradient,
        borderRadius: AppSpacing.roundedXL,
        boxShadow: shadowButton,
      );

  /// Dialog decoration
  static BoxDecoration get dialogDecoration => BoxDecoration(
        color: AppColorsEnhanced.background,
        borderRadius: AppSpacing.roundedLG,
        boxShadow: shadowDark,
      );

  /// Input field decoration
  static BoxDecoration get inputDecoration => BoxDecoration(
        color: AppColorsEnhanced.background,
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: AppColorsEnhanced.borderInput,
          width: thin,
        ),
      );

  /// Badge decoration (small colored pill)
  static BoxDecoration get badgeDecoration => BoxDecoration(
        color: AppColorsEnhanced.badgeBackground,
        borderRadius: AppSpacing.roundedCircular,
      );

  /// Chip decoration (outlined pill)
  static BoxDecoration get chipDecoration => BoxDecoration(
        color: AppColorsEnhanced.background,
        borderRadius: AppSpacing.roundedCircular,
        border: Border.all(
          color: AppColorsEnhanced.border,
          width: thin,
        ),
      );

  // ==================== STATUS DECORATIONS ====================

  /// Approved/success status decoration
  static BoxDecoration get approvedDecoration => BoxDecoration(
        color: AppColorsEnhanced.lighten(AppColorsEnhanced.successGreen, 0.85),
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: AppColorsEnhanced.successGreen,
          width: thin,
        ),
      );

  /// Pending/warning status decoration
  static BoxDecoration get pendingDecoration => BoxDecoration(
        color: AppColorsEnhanced.lighten(AppColorsEnhanced.warningYellow, 0.85),
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: AppColorsEnhanced.warningYellow,
          width: thin,
        ),
      );

  /// Rejected/error status decoration
  static BoxDecoration get rejectedDecoration => BoxDecoration(
        color: AppColorsEnhanced.lighten(AppColorsEnhanced.errorRed, 0.85),
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: AppColorsEnhanced.errorRed,
          width: thin,
        ),
      );

  /// Info status decoration
  static BoxDecoration get infoDecoration => BoxDecoration(
        color: AppColorsEnhanced.lighten(AppColorsEnhanced.infoBlue, 0.85),
        borderRadius: AppSpacing.roundedMD,
        border: Border.all(
          color: AppColorsEnhanced.infoBlue,
          width: thin,
        ),
      );

  // ==================== DIVIDERS ====================

  /// Horizontal divider
  static Divider get horizontalDivider => const Divider(
        color: AppColorsEnhanced.divider,
        thickness: 1,
        height: 1,
      );

  /// Vertical divider
  static VerticalDivider get verticalDivider => const VerticalDivider(
        color: AppColorsEnhanced.divider,
        thickness: 1,
        width: 1,
      );

  /// Thick horizontal divider
  static Divider get horizontalDividerThick => const Divider(
        color: AppColorsEnhanced.border,
        thickness: 2,
        height: 2,
      );

  // ==================== HELPER METHODS ====================

  /// Create custom box decoration
  static BoxDecoration customDecoration({
    Color? color,
    Gradient? gradient,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) =>
      BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
        border: border,
      );

  /// Create custom border
  static Border customBorder({
    Color? color,
    double? width,
  }) =>
      Border.all(
        color: color ?? AppColorsEnhanced.border,
        width: width ?? thin,
      );

  /// Create custom outline border
  static OutlineInputBorder customOutlineBorder({
    Color? color,
    double? width,
    BorderRadius? borderRadius,
  }) =>
      OutlineInputBorder(
        borderRadius: borderRadius ?? AppSpacing.roundedMD,
        borderSide: BorderSide(
          color: color ?? AppColorsEnhanced.borderInput,
          width: width ?? thin,
        ),
      );

  /// Get decoration for status
  static BoxDecoration getStatusDecoration(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'approved':
      case 'completed':
      case 'success':
        return approvedDecoration;
      case 'pending':
      case 'processing':
        return pendingDecoration;
      case 'rejected':
      case 'failed':
      case 'error':
        return rejectedDecoration;
      default:
        return infoDecoration;
    }
  }

  /// Get border for status
  static Border getStatusBorder(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'approved':
      case 'completed':
      case 'success':
        return successBorder;
      case 'pending':
      case 'processing':
        return warningBorder;
      case 'rejected':
      case 'failed':
      case 'error':
        return errorBorder;
      default:
        return defaultBorder;
    }
  }
}
