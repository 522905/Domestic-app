import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/constants/app_colors.dart';

class OrderErrorDialog extends StatelessWidget {
  final String error;
  final String? detail;
  final VoidCallback? onClose;

  const OrderErrorDialog({
    Key? key,
    required this.error,
    this.detail,
    this.onClose,
  }) : super(key: key);

  /// Parse error from DioException or Map
  static Map<String, String?> parseOrderError(dynamic errorData) {
    String error = 'Order creation failed';
    String? detail;

    try {
      // Try to access DioException response data (duck typing)
      // Check if error has a 'response' property with 'data'
      try {
        final response = (errorData as dynamic).response;
        if (response != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            error = data['error']?.toString() ??
                    data['message']?.toString() ??
                    'Order creation failed';
            detail = data['detail']?.toString();

            // Format the detail message for better readability
            if (detail != null) {
              detail = _formatDetailMessage(detail);
            }

            return {'error': error, 'detail': detail};
          } else if (data is String) {
            // Try to parse as JSON string
            try {
              // This is a simple string, might contain error info
              error = data;
            } catch (_) {
              error = data;
            }
          }
        }
      } catch (_) {
        // Not a DioException or no response data, continue with other parsing
      }

      // Handle Map directly
      if (errorData is Map<String, dynamic>) {
        error = errorData['error']?.toString() ??
                errorData['message']?.toString() ??
                'Order creation failed';
        detail = errorData['detail']?.toString();

        // Format the detail message for better readability
        if (detail != null) {
          detail = _formatDetailMessage(detail);
        }
      } else {
        // Fall back to string representation
        error = errorData.toString();

        // Try to extract meaningful message from exception
        if (error.contains('Exception:')) {
          final parts = error.split('Exception:');
          if (parts.length > 1) {
            error = parts[1].trim();
          }
        }
      }
    } catch (e) {
      error = 'An unexpected error occurred';
    }

    return {'error': error, 'detail': detail};
  }

  /// Format detail message for better readability
  static String _formatDetailMessage(String detail) {
    // Check if message contains schedule information (separated by semicolons)
    if (detail.contains(';')) {
      // Split by semicolon and format each schedule line
      final parts = detail.split(';');
      final buffer = StringBuffer();

      for (int i = 0; i < parts.length; i++) {
        String part = parts[i].trim();

        // Check if this part contains "only allowed during:"
        if (part.contains('only allowed during:')) {
          // Extract the prefix (e.g., "Orders for Sherpur Godown are only allowed during:")
          final colonIndex = part.indexOf('only allowed during:');
          final prefix = part.substring(0, colonIndex + 'only allowed during:'.length);
          final schedule = part.substring(colonIndex + 'only allowed during:'.length).trim();

          buffer.writeln(prefix);
          buffer.writeln();

          if (schedule.isNotEmpty) {
            // Format the schedule line (e.g., "Monday, Tuesday... Saturday: 06:15 AM - 05:00 PM IST")
            final formatted = _formatScheduleLine(schedule);
            buffer.writeln(formatted);
          }
        } else if (part.isNotEmpty) {
          // This is a continuation line (e.g., "Sunday: 06:15 AM - 03:00 PM IST")
          final formatted = _formatScheduleLine(part);
          buffer.writeln(formatted);
        }
      }

      return buffer.toString().trim();
    }

    // Return as-is if no special formatting needed
    return detail;
  }

  /// Format a single schedule line (e.g., "Monday, Tuesday... Saturday: timing")
  static String _formatScheduleLine(String line) {
    // Replace long day sequences with short form
    String formatted = line;

    // Replace "Monday, Tuesday, Wednesday, Thursday, Friday, Saturday" with "Mon-Sat"
    formatted = formatted.replaceAll(
      RegExp(r'Monday,?\s*Tuesday,?\s*Wednesday,?\s*Thursday,?\s*Friday,?\s*Saturday', caseSensitive: false),
      'Mon-Sat',
    );

    // Replace "Monday, Tuesday, Wednesday, Thursday, Friday" with "Mon-Fri"
    formatted = formatted.replaceAll(
      RegExp(r'Monday,?\s*Tuesday,?\s*Wednesday,?\s*Thursday,?\s*Friday', caseSensitive: false),
      'Mon-Fri',
    );

    return formatted;
  }

  /// Show the dialog
  static Future<void> show({
    required BuildContext context,
    required dynamic errorData,
    VoidCallback? onClose,
  }) async {
    final parsed = parseOrderError(errorData);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return OrderErrorDialog(
          error: parsed['error']!,
          detail: parsed['detail'],
          onClose: onClose,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 400.w,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Error Icon
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 48.sp,
                color: AppColors.errorRed,
              ),
            ),

            SizedBox(height: 20.h),

            // Title
            Text(
              'Order Creation Failed',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.errorRed,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16.h),

            // Error Message
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.errorRed.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                error,
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Detail Message (if available)
            if (detail != null && detail!.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 10.sp,
                      color: Colors.blue[700],
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        detail!,
                        style: TextStyle(
                          // fontSize: 1.sp,
                          color: Colors.blue[900],
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 14.h),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onClose != null) {
                    onClose!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
