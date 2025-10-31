// lib/core/models/sdms/sdms_error_response.dart
class SDMSErrorResponse {
  final String error;
  final bool canCreate;
  final String reason;
  final Map<String, dynamic> details;

  SDMSErrorResponse({
    required this.error,
    required this.canCreate,
    required this.reason,
    required this.details,
  });

  factory SDMSErrorResponse.fromJson(Map<String, dynamic> json) {
    return SDMSErrorResponse(
      error: json['error'] ?? '',
      canCreate: json['can_create'] ?? false,
      reason: json['reason'] ?? '',
      details: json['details'] ?? {},
    );
  }
}