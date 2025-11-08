import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Professional spacing system for consistent layout
/// Uses flutter_screenutil for responsive spacing
class AppSpacing {
  // ==================== BASIC SPACING VALUES ====================

  /// Extra small spacing - 4dp
  /// Use for: Very tight spacing, icon padding
  static final double xs = 4.w;

  /// Small spacing - 8dp
  /// Use for: Compact layouts, chip padding
  static final double sm = 8.w;

  /// Medium spacing - 12dp
  /// Use for: Default spacing between related elements
  static final double md = 12.w;

  /// Large spacing - 16dp
  /// Use for: Standard padding, card content spacing
  static final double lg = 16.w;

  /// Extra large spacing - 24dp
  /// Use for: Section spacing, card margins
  static final double xl = 24.w;

  /// Double extra large spacing - 32dp
  /// Use for: Major section breaks, page padding
  static final double xxl = 32.w;

  /// Triple extra large spacing - 48dp
  /// Use for: Large gaps between major sections
  static final double xxxl = 48.w;

  // ==================== SEMANTIC SPACING ====================

  /// Page horizontal padding (16dp)
  /// Standard padding for page edges
  static final double pageHorizontal = lg;

  /// Page vertical padding (16dp)
  /// Standard padding for top/bottom of pages
  static final double pageVertical = lg;

  /// Card padding (16dp)
  /// Internal padding for cards
  static final double cardPadding = lg;

  /// Card margin (12dp)
  /// Space between cards
  static final double cardMargin = md;

  /// List item padding (12dp vertical, 16dp horizontal)
  /// Standard padding for list items
  static final EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Dialog padding (24dp)
  /// Padding inside dialogs
  static final double dialogPadding = xl;

  /// Button padding horizontal (24dp)
  /// Horizontal padding inside buttons
  static final double buttonPaddingHorizontal = xl;

  /// Button padding vertical (12dp)
  /// Vertical padding inside buttons
  static final double buttonPaddingVertical = md;

  /// Input padding (12dp)
  /// Padding inside text fields
  static final double inputPadding = md;

  /// Section spacing (24dp)
  /// Space between major sections
  static final double sectionSpacing = xl;

  /// Item spacing (8dp)
  /// Space between related items in a group
  static final double itemSpacing = sm;

  // ==================== EDGE INSETS ====================

  /// All sides padding - extra small (4dp)
  static EdgeInsets get paddingXS => EdgeInsets.all(xs);

  /// All sides padding - small (8dp)
  static EdgeInsets get paddingSM => EdgeInsets.all(sm);

  /// All sides padding - medium (12dp)
  static EdgeInsets get paddingMD => EdgeInsets.all(md);

  /// All sides padding - large (16dp)
  static EdgeInsets get paddingLG => EdgeInsets.all(lg);

  /// All sides padding - extra large (24dp)
  static EdgeInsets get paddingXL => EdgeInsets.all(xl);

  /// All sides padding - double extra large (32dp)
  static EdgeInsets get paddingXXL => EdgeInsets.all(xxl);

  /// Horizontal padding - small (8dp)
  static EdgeInsets get paddingHorizontalSM => EdgeInsets.symmetric(horizontal: sm);

  /// Horizontal padding - medium (12dp)
  static EdgeInsets get paddingHorizontalMD => EdgeInsets.symmetric(horizontal: md);

  /// Horizontal padding - large (16dp)
  static EdgeInsets get paddingHorizontalLG => EdgeInsets.symmetric(horizontal: lg);

  /// Horizontal padding - extra large (24dp)
  static EdgeInsets get paddingHorizontalXL => EdgeInsets.symmetric(horizontal: xl);

  /// Vertical padding - small (8dp)
  static EdgeInsets get paddingVerticalSM => EdgeInsets.symmetric(vertical: sm);

  /// Vertical padding - medium (12dp)
  static EdgeInsets get paddingVerticalMD => EdgeInsets.symmetric(vertical: md);

  /// Vertical padding - large (16dp)
  static EdgeInsets get paddingVerticalLG => EdgeInsets.symmetric(vertical: lg);

  /// Vertical padding - extra large (24dp)
  static EdgeInsets get paddingVerticalXL => EdgeInsets.symmetric(vertical: xl);

  /// Page padding (horizontal: 16dp, vertical: 16dp)
  static EdgeInsets get pagePadding => EdgeInsets.symmetric(
        horizontal: pageHorizontal,
        vertical: pageVertical,
      );

  /// Card content padding (all sides: 16dp)
  static EdgeInsets get cardContentPadding => EdgeInsets.all(cardPadding);

  /// Dialog content padding (all sides: 24dp)
  static EdgeInsets get dialogContentPadding => EdgeInsets.all(dialogPadding);

  /// Button padding (horizontal: 24dp, vertical: 12dp)
  static EdgeInsets get buttonPadding => EdgeInsets.symmetric(
        horizontal: buttonPaddingHorizontal,
        vertical: buttonPaddingVertical,
      );

  /// Input field padding (all sides: 12dp)
  static EdgeInsets get inputFieldPadding => EdgeInsets.all(inputPadding);

  // ==================== SIZEDBOX HELPERS ====================

  /// Vertical spacing - extra small (4dp)
  static Widget get verticalSpaceXS => SizedBox(height: xs);

  /// Vertical spacing - small (8dp)
  static Widget get verticalSpaceSM => SizedBox(height: sm);

  /// Vertical spacing - medium (12dp)
  static Widget get verticalSpaceMD => SizedBox(height: md);

  /// Vertical spacing - large (16dp)
  static Widget get verticalSpaceLG => SizedBox(height: lg);

  /// Vertical spacing - extra large (24dp)
  static Widget get verticalSpaceXL => SizedBox(height: xl);

  /// Vertical spacing - double extra large (32dp)
  static Widget get verticalSpaceXXL => SizedBox(height: xxl);

  /// Horizontal spacing - extra small (4dp)
  static Widget get horizontalSpaceXS => SizedBox(width: xs);

  /// Horizontal spacing - small (8dp)
  static Widget get horizontalSpaceSM => SizedBox(width: sm);

  /// Horizontal spacing - medium (12dp)
  static Widget get horizontalSpaceMD => SizedBox(width: md);

  /// Horizontal spacing - large (16dp)
  static Widget get horizontalSpaceLG => SizedBox(width: lg);

  /// Horizontal spacing - extra large (24dp)
  static Widget get horizontalSpaceXL => SizedBox(width: xl);

  /// Horizontal spacing - double extra large (32dp)
  static Widget get horizontalSpaceXXL => SizedBox(width: xxl);

  // ==================== DIVIDER SPACING ====================

  /// Divider with small spacing (8dp above and below)
  static Widget get dividerWithSpacingSM => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          verticalSpaceSM,
          const Divider(height: 1),
          verticalSpaceSM,
        ],
      );

  /// Divider with medium spacing (12dp above and below)
  static Widget get dividerWithSpacingMD => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          verticalSpaceMD,
          const Divider(height: 1),
          verticalSpaceMD,
        ],
      );

  /// Divider with large spacing (16dp above and below)
  static Widget get dividerWithSpacingLG => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          verticalSpaceLG,
          const Divider(height: 1),
          verticalSpaceLG,
        ],
      );

  // ==================== CUSTOM SPACING HELPERS ====================

  /// Create vertical space with custom height
  static Widget verticalSpace(double height) => SizedBox(height: height.h);

  /// Create horizontal space with custom width
  static Widget horizontalSpace(double width) => SizedBox(width: width.w);

  /// Create symmetric padding
  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(
        horizontal: horizontal.w,
        vertical: vertical.h,
      );

  /// Create padding for all sides
  static EdgeInsets all(double value) => EdgeInsets.all(value.w);

  /// Create custom padding for each side
  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(
        left: left.w,
        top: top.h,
        right: right.w,
        bottom: bottom.h,
      );

  // ==================== ICON SIZES ====================

  /// Icon size - extra small (16dp)
  static final double iconXS = 16.sp;

  /// Icon size - small (20dp)
  static final double iconSM = 20.sp;

  /// Icon size - medium (24dp)
  static final double iconMD = 24.sp;

  /// Icon size - large (32dp)
  static final double iconLG = 32.sp;

  /// Icon size - extra large (48dp)
  static final double iconXL = 48.sp;

  /// Icon size - double extra large (64dp)
  static final double iconXXL = 64.sp;

  // ==================== BORDER RADIUS ====================

  /// Border radius - extra small (4dp)
  static final double radiusXS = 4.r;

  /// Border radius - small (8dp)
  static final double radiusSM = 8.r;

  /// Border radius - medium (12dp)
  static final double radiusMD = 12.r;

  /// Border radius - large (16dp)
  static final double radiusLG = 16.r;

  /// Border radius - extra large (24dp)
  static final double radiusXL = 24.r;

  /// Border radius - circular (999dp)
  static final double radiusCircular = 999.r;

  /// Rounded corners - extra small
  static BorderRadius get roundedXS => BorderRadius.circular(radiusXS);

  /// Rounded corners - small
  static BorderRadius get roundedSM => BorderRadius.circular(radiusSM);

  /// Rounded corners - medium
  static BorderRadius get roundedMD => BorderRadius.circular(radiusMD);

  /// Rounded corners - large
  static BorderRadius get roundedLG => BorderRadius.circular(radiusLG);

  /// Rounded corners - extra large
  static BorderRadius get roundedXL => BorderRadius.circular(radiusXL);

  /// Circular corners
  static BorderRadius get roundedCircular => BorderRadius.circular(radiusCircular);

  // ==================== ELEVATION HEIGHTS ====================

  /// Shadow elevation - none (0dp)
  static const double elevationNone = 0;

  /// Shadow elevation - low (2dp)
  static const double elevationLow = 2;

  /// Shadow elevation - medium (4dp)
  static const double elevationMedium = 4;

  /// Shadow elevation - high (8dp)
  static const double elevationHigh = 8;

  /// Shadow elevation - extra high (16dp)
  static const double elevationExtraHigh = 16;
}
