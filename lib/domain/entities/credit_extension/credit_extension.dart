import 'package:equatable/equatable.dart';

enum CreditExtensionStatus {
  pending,
  approved,
  rejected;

  static CreditExtensionStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return CreditExtensionStatus.pending;
      case 'APPROVED':
        return CreditExtensionStatus.approved;
      case 'REJECTED':
        return CreditExtensionStatus.rejected;
      default:
        return CreditExtensionStatus.pending;
    }
  }

  String toApiString() {
    return name.toUpperCase();
  }
}

class CreditExtension extends Equatable {
  final int id;
  final String itemCode;
  final String itemName;
  final int requestedQuantity;
  final String justification;
  final CreditExtensionStatus status;
  final int? approvedQuantity;
  final DateTime? validUntil;
  final int? quantityReserved;
  final int? quantityConsumed;
  final int? quantityRemaining;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  // Audio fields
  final bool hasAudio;
  final String? justificationAudioUrl;

  // For GM views
  final int? partnerId;
  final String? partnerName;
  final String? partnerCode;
  final int? currentQuotaBalance;

  // Additional fields
  final String? statusDisplay;
  final String? approvedByUsername;
  final String? rejectedByUsername;
  final DateTime? rejectedAt;
  final int? quantityPendingPickup;
  final bool? isActiveFromServer;
  final bool? isExpiredFromServer;

  const CreditExtension({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.requestedQuantity,
    required this.justification,
    required this.status,
    this.approvedQuantity,
    this.validUntil,
    this.quantityReserved,
    this.quantityConsumed,
    this.quantityRemaining,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdAt,
    this.hasAudio = false,
    this.justificationAudioUrl,
    this.partnerId,
    this.partnerName,
    this.partnerCode,
    this.currentQuotaBalance,
    this.statusDisplay,
    this.approvedByUsername,
    this.rejectedByUsername,
    this.rejectedAt,
    this.quantityPendingPickup,
    this.isActiveFromServer,
    this.isExpiredFromServer,
  });

  // Computed properties
  bool get isActive =>
      status == CreditExtensionStatus.approved &&
      validUntil != null &&
      validUntil!.isAfter(DateTime.now()) &&
      (quantityRemaining ?? 0) > 0;

  bool get isExpiringSoon {
    if (validUntil == null) return false;
    return daysUntilExpiry <= 2;
  }

  int get daysUntilExpiry {
    if (validUntil == null) return 0;
    return validUntil!.difference(DateTime.now()).inDays;
  }

  bool get isPending => status == CreditExtensionStatus.pending;
  bool get isApproved => status == CreditExtensionStatus.approved;
  bool get isRejected => status == CreditExtensionStatus.rejected;

  factory CreditExtension.fromJson(Map<String, dynamic> json) {
    return CreditExtension(
      id: json['id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      requestedQuantity: json['requested_quantity'] ?? 0,
      justification: json['justification'] ?? '',
      status: CreditExtensionStatus.fromString(json['status'] ?? 'PENDING'),
      approvedQuantity: json['approved_quantity'],
      validUntil: json['valid_until'] != null
          ? DateTime.parse(json['valid_until'])
          : null,
      quantityReserved: json['quantity_reserved'] ?? 0,
      quantityConsumed: json['quantity_consumed'] ?? 0,
      quantityRemaining: json['quantity_remaining'] ?? 0,
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      rejectionReason: json['rejection_reason'],
      createdAt: DateTime.parse(json['created_at']),
      hasAudio: json['has_audio'] ?? false,
      justificationAudioUrl: json['justification_audio_url'],
      partnerId: json['partner_id'],
      partnerName: json['partner_name'],
      partnerCode: json['partner_code'],
      currentQuotaBalance: json['current_quota_balance'],
      statusDisplay: json['status_display'],
      approvedByUsername: json['approved_by_username'],
      rejectedByUsername: json['rejected_by_username'],
      rejectedAt: json['rejected_at'] != null
          ? DateTime.parse(json['rejected_at'])
          : null,
      quantityPendingPickup: json['quantity_pending_pickup'] ?? 0,
      isActiveFromServer: json['is_active'],
      isExpiredFromServer: json['is_expired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_code': itemCode,
      'item_name': itemName,
      'requested_quantity': requestedQuantity,
      'justification': justification,
      'status': status.toApiString(),
      'approved_quantity': approvedQuantity,
      'valid_until': validUntil?.toIso8601String(),
      'quantity_reserved': quantityReserved,
      'quantity_consumed': quantityConsumed,
      'quantity_remaining': quantityRemaining,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'partner_id': partnerId,
      'partner_name': partnerName,
      'partner_code': partnerCode,
      'current_quota_balance': currentQuotaBalance,
    };
  }

  CreditExtension copyWith({
    int? id,
    String? itemCode,
    String? itemName,
    int? requestedQuantity,
    String? justification,
    CreditExtensionStatus? status,
    int? approvedQuantity,
    DateTime? validUntil,
    int? quantityReserved,
    int? quantityConsumed,
    int? quantityRemaining,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    int? partnerId,
    String? partnerName,
    String? partnerCode,
    int? currentQuotaBalance,
  }) {
    return CreditExtension(
      id: id ?? this.id,
      itemCode: itemCode ?? this.itemCode,
      itemName: itemName ?? this.itemName,
      requestedQuantity: requestedQuantity ?? this.requestedQuantity,
      justification: justification ?? this.justification,
      status: status ?? this.status,
      approvedQuantity: approvedQuantity ?? this.approvedQuantity,
      validUntil: validUntil ?? this.validUntil,
      quantityReserved: quantityReserved ?? this.quantityReserved,
      quantityConsumed: quantityConsumed ?? this.quantityConsumed,
      quantityRemaining: quantityRemaining ?? this.quantityRemaining,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      partnerId: partnerId ?? this.partnerId,
      partnerName: partnerName ?? this.partnerName,
      partnerCode: partnerCode ?? this.partnerCode,
      currentQuotaBalance: currentQuotaBalance ?? this.currentQuotaBalance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemCode,
        itemName,
        requestedQuantity,
        justification,
        status,
        approvedQuantity,
        validUntil,
        quantityReserved,
        quantityConsumed,
        quantityRemaining,
        approvedBy,
        approvedAt,
        rejectionReason,
        createdAt,
        hasAudio,
        justificationAudioUrl,
        partnerId,
        partnerName,
        partnerCode,
        currentQuotaBalance,
        statusDisplay,
        approvedByUsername,
        rejectedByUsername,
        rejectedAt,
        quantityPendingPickup,
        isActiveFromServer,
        isExpiredFromServer,
      ];
}
