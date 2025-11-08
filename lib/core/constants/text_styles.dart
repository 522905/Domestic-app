import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_colors_enhanced.dart';

/// Professional text styles for consistent typography across the app
/// Uses flutter_screenutil for responsive sizing
class AppTextStyles {
  // ==================== HEADINGS ====================

  /// Display heading - largest text (32sp)
  /// Use for: Welcome screens, major section titles
  static TextStyle displayLarge = TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.primaryText,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display medium (28sp)
  /// Use for: Page titles, important headings
  static TextStyle displayMedium = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.primaryText,
    height: 1.2,
    letterSpacing: -0.5,
  );

  /// Display small (24sp)
  /// Use for: Section headers, card titles
  static TextStyle displaySmall = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.primaryText,
    height: 1.3,
  );

  /// Heading 1 (22sp)
  /// Use for: Dialog titles, important labels
  static TextStyle h1 = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.primaryText,
    height: 1.3,
  );

  /// Heading 2 (20sp)
  /// Use for: Subsection titles
  static TextStyle h2 = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.primaryText,
    height: 1.3,
  );

  /// Heading 3 (18sp)
  /// Use for: Card headers, list group titles
  static TextStyle h3 = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.primaryText,
    height: 1.4,
  );

  /// Heading 4 (16sp)
  /// Use for: Small section headers
  static TextStyle h4 = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.primaryText,
    height: 1.4,
  );

  // ==================== BODY TEXT ====================

  /// Body large (16sp) - regular weight
  /// Use for: Main content, descriptions
  static TextStyle bodyLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.primaryText,
    height: 1.5,
  );

  /// Body medium (14sp) - regular weight
  /// Use for: Standard body text, list items
  static TextStyle bodyMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.primaryText,
    height: 1.5,
  );

  /// Body small (12sp) - regular weight
  /// Use for: Helper text, timestamps, metadata
  static TextStyle bodySmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.secondaryText,
    height: 1.5,
  );

  // ==================== LABELS ====================

  /// Label large (14sp) - medium weight
  /// Use for: Form labels, button text
  static TextStyle labelLarge = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.primaryText,
    height: 1.4,
  );

  /// Label medium (12sp) - medium weight
  /// Use for: Small labels, chip text
  static TextStyle labelMedium = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.primaryText,
    height: 1.4,
  );

  /// Label small (10sp) - medium weight
  /// Use for: Tiny labels, badges
  static TextStyle labelSmall = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.secondaryText,
    height: 1.4,
  );

  // ==================== SPECIALIZED STYLES ====================

  /// Button text - large (16sp, medium weight)
  static TextStyle buttonLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.inverseText,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button text - medium (14sp, medium weight)
  static TextStyle buttonMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.inverseText,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Button text - small (12sp, medium weight)
  static TextStyle buttonSmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.inverseText,
    height: 1.2,
    letterSpacing: 0.3,
  );

  /// Caption text (11sp)
  /// Use for: Image captions, footnotes
  static TextStyle caption = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.secondaryText,
    height: 1.4,
  );

  /// Overline text (10sp, uppercase)
  /// Use for: Category labels, tags
  static TextStyle overline = TextStyle(
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.secondaryText,
    height: 1.6,
    letterSpacing: 1.5,
  );

  /// Link text (14sp, colored)
  /// Use for: Clickable text, hyperlinks
  static TextStyle link = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.link,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Error text (12sp, colored)
  /// Use for: Validation errors, error messages
  static TextStyle error = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.errorRed,
    height: 1.4,
  );

  /// Hint text (14sp, light color)
  /// Use for: Input placeholders
  static TextStyle hint = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColorsEnhanced.hintText,
    height: 1.5,
  );

  // ==================== STATUS STYLES ====================

  /// Success text (14sp, green)
  static TextStyle success = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.successGreen,
    height: 1.4,
  );

  /// Warning text (14sp, yellow)
  static TextStyle warning = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.warningYellow,
    height: 1.4,
  );

  /// Info text (14sp, blue)
  static TextStyle info = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColorsEnhanced.infoBlue,
    height: 1.4,
  );

  // ==================== NUMERIC STYLES ====================

  /// Large number (28sp, bold)
  /// Use for: Dashboard metrics, totals
  static TextStyle numberLarge = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.brandBlue,
    height: 1.2,
  );

  /// Medium number (20sp, bold)
  /// Use for: Card values, amounts
  static TextStyle numberMedium = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.primaryText,
    height: 1.2,
  );

  /// Small number (16sp, medium)
  /// Use for: List item values
  static TextStyle numberSmall = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColorsEnhanced.primaryText,
    height: 1.2,
  );

  /// Currency text (18sp, bold)
  /// Use for: Prices, amounts with currency symbol
  static TextStyle currency = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    color: AppColorsEnhanced.brandBlue,
    height: 1.2,
  );

  // ==================== HELPER METHODS ====================

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) {
    return style.copyWith(fontWeight: weight);
  }

  /// Apply size to any text style
  static TextStyle withSize(TextStyle style, double size) {
    return style.copyWith(fontSize: size.sp);
  }

  /// Make text bold
  static TextStyle bold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.bold);
  }

  /// Make text semi-bold
  static TextStyle semiBold(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w600);
  }

  /// Make text medium weight
  static TextStyle medium(TextStyle style) {
    return style.copyWith(fontWeight: FontWeight.w500);
  }

  /// Make text italic
  static TextStyle italic(TextStyle style) {
    return style.copyWith(fontStyle: FontStyle.italic);
  }

  /// Add underline
  static TextStyle underline(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.underline);
  }

  /// Add strikethrough
  static TextStyle strikethrough(TextStyle style) {
    return style.copyWith(decoration: TextDecoration.lineThrough);
  }

  /// Get text style for status
  static TextStyle getStatusStyle(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'approved':
      case 'completed':
      case 'success':
        return success;
      case 'pending':
      case 'processing':
        return warning;
      case 'rejected':
      case 'failed':
      case 'error':
        return error;
      default:
        return info;
    }
  }
}
