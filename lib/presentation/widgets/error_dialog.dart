import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:share_plus/share_plus.dart';
import 'professional_snackbar.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final Map<String, dynamic>? rawError;
  final VoidCallback? onRetry;

  const ErrorDialog({
    Key? key,
    required this.title,
    required this.message,
    this.rawError,
    this.onRetry,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    Map<String, dynamic>? rawError,
    VoidCallback? onRetry,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ErrorDialog(
          title: title,
          message: message,
          rawError: rawError,
          onRetry: onRetry,
        );
      },
    );
  }

  static String parseErrorMessage(dynamic error) {
    if (error is Map<String, dynamic>) {
      // Handle DRF validation errors
      final fieldErrors = <String>[];
      final nonFieldErrors = <String>[];

      error.forEach((key, value) {
        if (key == 'non_field_errors') {
          if (value is List) {
            nonFieldErrors.addAll(value.map((e) => e.toString()));
          } else {
            nonFieldErrors.add(value.toString());
          }
        } else {
          if (value is List) {
            fieldErrors.add('$key: ${value.join(', ')}');
          } else {
            fieldErrors.add('$key: $value');
          }
        }
      });

      final allErrors = [...nonFieldErrors, ...fieldErrors];
      return allErrors.isNotEmpty ? allErrors.join('\n') : 'Unknown error occurred';
    }

    return error.toString();
  }

  String get _formattedErrorDetails {
    if (rawError == null) return '';

    try {
      final buffer = StringBuffer();
      buffer.writeln('Error Details:');
      buffer.writeln('Title: $title');
      buffer.writeln('Message: $message');
      buffer.writeln('Raw Response:');
      buffer.writeln(rawError.toString());
      buffer.writeln('\nTimestamp: ${DateTime.now().toIso8601String()}');
      return buffer.toString();
    } catch (e) {
      return 'Error details could not be formatted: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 28,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
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
            message,
            style: const TextStyle(fontSize: 16),
          ),
          if (rawError != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Technical Details:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rawError.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: _formattedErrorDetails),
                            );
                            context.showSuccessSnackBar('Error details copied to clipboard');
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Share.share(
                            //   _formattedErrorDetails,
                            //   subject: 'LPG App Error Report',
                            // );
                          },
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text('Share'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (onRetry != null)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// Helper extension for easy error display
extension ErrorDialogExtension on BuildContext {
  Future<void> showErrorDialog({
    required String title,
    required dynamic error,
    VoidCallback? onRetry,
  }) async {
    return ErrorDialog.show(
      context: this,
      title: title,
      message: ErrorDialog.parseErrorMessage(error),
      rawError: error is Map<String, dynamic> ? error : null,
      onRetry: onRetry,
    );
  }
}