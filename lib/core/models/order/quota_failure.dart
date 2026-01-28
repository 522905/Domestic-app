// lib/core/models/order/quota_failure.dart

/// Model representing a quota failure for an item in an order
class QuotaFailure {
  final String itemCode;
  final int requested;
  final int available;
  final int shortfall;
  final String reason;

  QuotaFailure({
    required this.itemCode,
    required this.requested,
    required this.available,
    required this.shortfall,
    required this.reason,
  });

  factory QuotaFailure.fromJson(Map<String, dynamic> json) {
    return QuotaFailure(
      itemCode: json['item_code'] ?? '',
      requested: json['requested'] ?? 0,
      available: json['available'] ?? 0,
      shortfall: json['shortfall'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_code': itemCode,
      'requested': requested,
      'available': available,
      'shortfall': shortfall,
      'reason': reason,
    };
  }
}
