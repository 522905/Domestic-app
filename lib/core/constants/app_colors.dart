import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color brandBlue = Color(0xFF0E5CA8);
  static const Color brandOrange = Color(0xFFF7941D);
  static const Color darkGray = Color(0xFF333333);
  static const Color lightGray = Color(0xFFE5E5E5);

  // Secondary Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningYellow = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Status Colors
  static const Color pending = warningYellow;
  static const Color approved = successGreen;
  static const Color rejected = errorRed;
  static const Color processing = infoBlue;

  // Text Colors
  static const Color primaryText = darkGray;
  static const Color secondaryText = Color(0xFF666666);
  static const Color disabledText = Color(0xFF999999);
  static const Color inverseText = Colors.white;
}