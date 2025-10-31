import 'dart:ui';

class ApiValidationException implements Exception {
  final String title;
  final List<ValidationError> errors;
  final Map<String, dynamic>? balanceInfo;
  final VoidCallback? onRetry;

  ApiValidationException({
    required this.title,
    required this.errors,
    this.balanceInfo,
    this.onRetry,
  });

  @override
  String toString() {
    return 'ApiValidationException: $title\n${errors.map((e) => '- ${e.message}').join('\n')}';
  }
}

class ValidationError {
  final String message;
  final String code;

  ValidationError({
    required this.message,
    required this.code,
  });
}