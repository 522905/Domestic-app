import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => "ApiException: $message";
}

/// Utility for handling errors globally
class ErrorHandler {
  /// Handle and format error messages
  static String handleError(dynamic error) {
    if (error is TimeoutException) {
      return "Request timed out. Please try again.";
    } else if (error is DioException) {
      return _handleDioError(error);
    } else if (error is ApiException) {
      return "API Error: ${error.message}";
    } else if (error is Exception) {
      // Clean up exception string (remove "Exception: " prefix)
      String errorString = error.toString();
      if (errorString.startsWith('Exception: ')) {
        return errorString.substring(11);
      }
      return errorString;
    } else {
      return "An unknown error occurred.";
    }
  }

  /// Handle Dio-specific errors and extract API response details
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "Connection timeout. Please check your internet connection.";

      case DioExceptionType.badResponse:
        return _extractApiErrorMessage(error.response);

      case DioExceptionType.cancel:
        return "Request was cancelled.";

      case DioExceptionType.connectionError:
        return "Connection error. Please check your internet connection.";

      case DioExceptionType.unknown:
      default:
        return "Network error occurred. Please try again.";
    }
  }

  /// Extract meaningful error messages from API response
  static String _extractApiErrorMessage(Response? response) {
    if (response?.data == null) {
      return "Server error occurred (${response?.statusCode ?? 'Unknown'}).";
    }

    try {
      final data = response!.data;

      // Handle different response formats
      if (data is Map<String, dynamic>) {
        // Handle field-specific errors like {"warehouse":["Incorrect type..."]}
        List<String> errorMessages = [];

        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            // Field validation errors
            for (var errorMsg in value) {
              errorMessages.add("$key: $errorMsg");
            }
          } else if (value is String && value.isNotEmpty) {
            // Simple field errors
            errorMessages.add("$key: $value");
          }
        });

        if (errorMessages.isNotEmpty) {
          return errorMessages.join('\n');
        }

        // Check for common error keys
        if (data.containsKey('detail')) {
          return data['detail'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
      }

      // Fallback for other formats
      return "Server error: ${data.toString()}";
    } catch (e) {
      return "Server error occurred (${response?.statusCode ?? 'Unknown'}).";
    }
  }

  /// Show error popup dialog
  static void showErrorPopup(BuildContext context, String error, {VoidCallback? onRetry}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 24),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(
            error,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            if (onRetry != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
          ],
        );
      },
    );
  }

  /// Show error snackbar (alternative to popup)
  static void showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}