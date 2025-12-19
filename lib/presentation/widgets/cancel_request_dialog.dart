import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CancelRequestDialog extends StatelessWidget {
  final String requestId;
  final VoidCallback? onConfirm;
  final VoidCallback? onDismiss;

  const CancelRequestDialog({
    Key? key,
    required this.requestId,
    this.onConfirm,
    this.onDismiss,
  }) : super(key: key);

  /// Show the cancel confirmation dialog
  ///
  /// Returns true if confirmed, false if dismissed, null if closed by other means
  static Future<bool?> show(BuildContext context, String requestId) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => CancelRequestDialog(
        requestId: requestId,
        onConfirm: () => Navigator.pop(context, true),
        onDismiss: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange.shade700,
            size: 28.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Cancel Request?',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to cancel request #$requestId?',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.orange.shade700,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'This action cannot be undone. The request will be permanently cancelled.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.orange.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Cancel/dismiss button
        OutlinedButton(
          onPressed: onDismiss ?? () => Navigator.pop(context, false),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey.shade700,
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          child: Text(
            'No, Keep It',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // Confirm cancel button
        ElevatedButton(
          onPressed: onConfirm ?? () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            elevation: 2,
          ),
          child: Text(
            'Yes, Cancel',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
      buttonPadding: EdgeInsets.zero,
    );
  }
}
