// lib/core/models/order/selectable_order_item.dart
import 'dart:math';

/// Enum representing the quota status
enum QuotaStatus {
  unlimited,   // No quota limit applies
  available,   // Quota > 10
  low,         // Quota 1-10
  zero,        // Quota = 0
  blocked,     // Quota < 0 (over quota)
}

/// Class representing quota information for an item
class QuotaInfo {
  final int available;           // Total quota available (can be negative)
  final bool isBlocked;          // true if available < 0
  final bool isQuotaEnforced;    // true if quota applies to this item
  final bool isQuotaDisabled;    // true if quota system is globally disabled
  final bool isSdmsDown;         // true if SDMS is down (emergency bypass)
  final bool isPartnerExempt;    // true if partner is exempt from quota

  QuotaInfo({
    required this.available,
    required this.isBlocked,
    required this.isQuotaEnforced,
    required this.isQuotaDisabled,
    required this.isSdmsDown,
    required this.isPartnerExempt,
  });

  factory QuotaInfo.fromJson(Map<String, dynamic> json) {
    return QuotaInfo(
      available: _safeToInt(json['available']),
      isBlocked: json['is_blocked'] ?? false,
      isQuotaEnforced: json['is_quota_enforced'] ?? false,
      isQuotaDisabled: json['is_quota_disabled'] ?? false,
      isSdmsDown: json['is_sdms_down'] ?? false,
      isPartnerExempt: json['is_partner_exempt'] ?? false,
    );
  }

  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Helper getter: Returns true if quota limit applies to this item
  bool get hasQuotaLimit => isQuotaEnforced && !isQuotaDisabled && !isSdmsDown && !isPartnerExempt;

  /// Helper getter: Returns true if quota is unlimited (no limit)
  bool get isUnlimited => !hasQuotaLimit;

  /// Helper getter: Returns the current quota status
  QuotaStatus get status {
    if (!hasQuotaLimit) return QuotaStatus.unlimited;
    if (isBlocked) return QuotaStatus.blocked;
    if (available == 0) return QuotaStatus.zero;
    if (available > 0 && available <= 10) return QuotaStatus.low;
    return QuotaStatus.available;
  }
}

class SelectableOrderItem {
  final String id;
  final String itemCode;
  final String itemName;
  final String description;
  final String type; // 'Filled', 'NFR', etc.
  final int maxQuantity; // actual_qty
  final String availabilityStatus;
  final Map<String, dynamic> metadata;
  final QuotaInfo? quota;

  SelectableOrderItem({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.description,
    required this.type,
    required this.maxQuantity,
    required this.availabilityStatus,
    required this.metadata,
    this.quota,
  });

  String get displayName => itemName.isNotEmpty ? itemName : itemCode;

  bool get isOutOfStock => availabilityStatus == 'Out of Stock' || maxQuantity <= 0;

  /// Returns the effective maximum quantity considering both stock and quota
  int get effectiveMaxQuantity {
    if (quota == null || !quota!.hasQuotaLimit) return maxQuantity;
    if (quota!.isBlocked) return 0;
    return min(maxQuantity, quota!.available);
  }

  /// Returns true if this item can be selected for ordering
  bool get isSelectable {
    if (isOutOfStock) return false;
    if (quota?.isBlocked ?? false) return false;
    return true;
  }

  factory SelectableOrderItem.fromJson(Map<String, dynamic> json, String bucketType) {
    // Safely convert actual_qty to int
    int projectedQty = 0;
    final projectedQtyValue = json["projected_qty"];
    if (projectedQtyValue != null) {
      if (projectedQtyValue is int) {
        projectedQty = projectedQtyValue;
      } else if (projectedQtyValue is double) {
        projectedQty = projectedQtyValue.toInt();
      } else if (projectedQtyValue is String) {
        projectedQty = int.tryParse(projectedQtyValue) ?? 0;
      }
    }

    // Parse quota info if available
    QuotaInfo? quotaInfo;
    if (json['quota'] != null && json['quota'] is Map<String, dynamic>) {
      quotaInfo = QuotaInfo.fromJson(json['quota']);
    }

    return SelectableOrderItem(
      id: json['item_code'] ?? '',
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      description: json['description'] ?? '',
      type: bucketType,
      maxQuantity: projectedQty,
      availabilityStatus: json['availability_status'] ?? 'Unknown',
      metadata: {
        'item_group': json['item_group'],
        'stock_uom': json['stock_uom'],
        'reserved_stock': _safeToInt(json['reserved_stock']),
        'projected_qty': _safeToInt(json['projected_qty']),
        'mappings': json['mappings'] ?? [],
        'availability_status': json['availability_status'],
        'actual_qty': projectedQty,
        ...json,
      },
      quota: quotaInfo,
    );
  }

  // Helper method to safely convert any number type to int
  static int _safeToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, dynamic> toApiPayload(int selectedQuantity) {
    return {
      'item_code': itemCode,
      'qty': selectedQuantity,
    };
  }

  SelectableOrderItem copyWith({
    String? id,
    String? itemCode,
    String? itemName,
    String? description,
    String? type,
    int? maxQuantity,
    String? availabilityStatus,
    Map<String, dynamic>? metadata,
    QuotaInfo? quota,
  }) {
    return SelectableOrderItem(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      type: type ?? this.type,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      metadata: metadata ?? this.metadata,
      quota: quota ?? this.quota,
    );
  }
}