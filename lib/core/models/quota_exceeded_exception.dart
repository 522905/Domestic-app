// lib/core/models/quota_exceeded_exception.dart

import 'order/quota_failure.dart';

/// Exception thrown when an order exceeds quota limits
class QuotaExceededException implements Exception {
  final String message;
  final List<QuotaFailure> quotaFailures;

  QuotaExceededException({
    required this.message,
    required this.quotaFailures,
  });

  factory QuotaExceededException.fromApiResponse(Map<String, dynamic> data) {
    final failures = (data['quota_failures'] as List?)
        ?.map((f) => QuotaFailure.fromJson(f as Map<String, dynamic>))
        .toList() ?? [];

    return QuotaExceededException(
      message: data['error']?.toString() ?? 'Quota exceeded',
      quotaFailures: failures,
    );
  }

  @override
  String toString() => 'QuotaExceededException: $message';
}
