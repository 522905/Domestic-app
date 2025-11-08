import 'package:flutter/material.dart';

/// Enhanced color system for professional UI design
/// Includes primary, secondary, status, gradient, and semantic colors
class AppColorsEnhanced {
  // ==================== PRIMARY COLORS ====================

  /// Main brand blue - used for primary actions and headers
  static const Color brandBlue = Color(0xFF0E5CA8);

  /// Accent orange - used for highlights and secondary actions
  static const Color brandOrange = Color(0xFFF7941D);

  /// Dark gray for primary text
  static const Color darkGray = Color(0xFF333333);

  /// Light gray for backgrounds and dividers
  static const Color lightGray = Color(0xFFE5E5E5);

  // ==================== SECONDARY COLORS ====================

  /// Success green - used for approved/success states
  static const Color successGreen = Color(0xFF4CAF50);

  /// Warning yellow - used for pending/warning states
  static const Color warningYellow = Color(0xFFFFC107);

  /// Error red - used for rejected/error states
  static const Color errorRed = Color(0xFFF44336);

  /// Info blue - used for informational messages
  static const Color infoBlue = Color(0xFF2196F3);

  // ==================== STATUS COLORS ====================

  /// Pending status - same as warning yellow
  static const Color pending = warningYellow;

  /// Approved status - same as success green
  static const Color approved = successGreen;

  /// Rejected status - same as error red
  static const Color rejected = errorRed;

  /// Processing status - same as info blue
  static const Color processing = infoBlue;

  // ==================== TEXT COLORS ====================

  /// Primary text color - dark gray
  static const Color primaryText = darkGray;

  /// Secondary text color - medium gray
  static const Color secondaryText = Color(0xFF666666);

  /// Disabled text color - light gray
  static const Color disabledText = Color(0xFF999999);

  /// Inverse text color - white (for dark backgrounds)
  static const Color inverseText = Colors.white;

  /// Hint text color - lighter gray
  static const Color hintText = Color(0xFFAAAAAA);

  // ==================== BACKGROUND COLORS ====================

  /// Primary background - white
  static const Color background = Color(0xFFFFFFFF);

  /// Secondary background - very light gray
  static const Color backgroundSecondary = Color(0xFFF5F5F5);

  /// Card background - white with subtle elevation
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Surface color for elevated components
  static const Color surface = Color(0xFFFFFFFF);

  /// Overlay background - semi-transparent black
  static const Color overlay = Color(0x80000000);

  // ==================== BORDER COLORS ====================

  /// Default border color
  static const Color border = Color(0xFFE0E0E0);

  /// Border color for inputs
  static const Color borderInput = Color(0xFFCCCCCC);

  /// Border color for focused inputs
  static const Color borderFocused = brandBlue;

  /// Border color for errors
  static const Color borderError = errorRed;

  /// Divider color
  static const Color divider = Color(0xFFEEEEEE);

  // ==================== GRADIENT COLORS ====================

  /// Primary gradient (blue)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0E5CA8),
      Color(0xFF0A4A8A),
    ],
  );

  /// Success gradient (green)
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4CAF50),
      Color(0xFF388E3C),
    ],
  );

  /// Warning gradient (yellow/orange)
  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFC107),
      Color(0xFFFFA000),
    ],
  );

  /// Error gradient (red)
  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF44336),
      Color(0xFFD32F2F),
    ],
  );

  /// Card gradient - subtle light gray
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAFAFA),
    ],
  );

  // ==================== SHADOW COLORS ====================

  /// Light shadow for cards
  static const Color shadowLight = Color(0x1A000000);

  /// Medium shadow for elevated components
  static const Color shadowMedium = Color(0x33000000);

  /// Dark shadow for modals and dialogs
  static const Color shadowDark = Color(0x4D000000);

  // ==================== SEMANTIC COLORS ====================

  /// Link color - blue
  static const Color link = Color(0xFF2196F3);

  /// Disabled state color
  static const Color disabled = Color(0xFFBDBDBD);

  /// Selected item background
  static const Color selected = Color(0xFFE3F2FD);

  /// Hover background
  static const Color hover = Color(0xFFF5F5F5);

  /// Badge background color
  static const Color badgeBackground = errorRed;

  /// Badge text color
  static const Color badgeText = inverseText;

  // ==================== HELPER METHODS ====================

  /// Get color for status
  static Color getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'approved':
      case 'completed':
      case 'success':
        return approved;
      case 'pending':
      case 'processing':
      case 'in_progress':
        return pending;
      case 'rejected':
      case 'failed':
      case 'error':
        return rejected;
      case 'cancelled':
      case 'inactive':
        return disabledText;
      default:
        return infoBlue;
    }
  }

  /// Get gradient for status
  static LinearGradient getStatusGradient(String status) {
    final statusLower = status.toLowerCase();
    switch (statusLower) {
      case 'approved':
      case 'completed':
      case 'success':
        return successGradient;
      case 'pending':
      case 'processing':
        return warningGradient;
      case 'rejected':
      case 'failed':
      case 'error':
        return errorGradient;
      default:
        return primaryGradient;
    }
  }

  /// Get lighter shade of color (for backgrounds)
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }

  /// Get darker shade of color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);

    return hsl.withLightness(lightness).toColor();
  }

  /// Add opacity to color
  static Color withOpacity(Color color, double opacity) {
    assert(opacity >= 0 && opacity <= 1);
    return color.withOpacity(opacity);
  }
}
