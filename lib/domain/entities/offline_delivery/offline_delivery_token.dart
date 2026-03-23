import 'package:equatable/equatable.dart';
import 'offline_delivery_company.dart';

class OfflineDeliveryToken extends Equatable {
  final String id;
  final int? tokenNumber;
  final String? tokenDate;
  final String? consumerId;
  final String? consumerNumber;
  final String? consumerName;
  final String? consumerNameManual;
  final String? orderNumber;
  final String? bookingOrigin;
  final String? dacCode;
  final DateTime? deliveredAt;
  final double? cashToCollect;
  final bool cashToCollectIsEstimated;
  final double? digitalAmount;
  final double? cashCollected;
  final String? referenceImage1;
  final String? referenceImage2;
  final bool imagesUploaded;
  final bool evidenceRequired;
  final String? remark;
  final String status;
  final String? modeSnapshot;
  final String? creationType;
  final bool isQuickDelivery;
  final String? overrideReason;
  final String? reconciliationStatus;
  final String? reconciliationError;
  final String? distributionPointName;
  final String? createdByName;
  final OfflineDeliveryCompany? company;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int printCount;
  final bool canPrint;

  const OfflineDeliveryToken({
    required this.id,
    this.tokenNumber,
    this.tokenDate,
    this.consumerId,
    this.consumerNumber,
    this.consumerName,
    this.consumerNameManual,
    this.orderNumber,
    this.bookingOrigin,
    this.dacCode,
    this.deliveredAt,
    this.cashToCollect,
    this.cashToCollectIsEstimated = false,
    this.digitalAmount,
    this.cashCollected,
    this.referenceImage1,
    this.referenceImage2,
    this.imagesUploaded = false,
    this.evidenceRequired = false,
    this.remark,
    required this.status,
    this.modeSnapshot,
    this.creationType,
    this.isQuickDelivery = false,
    this.overrideReason,
    this.reconciliationStatus,
    this.reconciliationError,
    this.distributionPointName,
    this.company,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.printCount = 0,
    this.canPrint = true,
  });

  bool get isPending => status == 'TOKEN_ISSUED';
  bool get isDelivered => status == 'DELIVERED';
  bool get isVoided => status == 'VOIDED';
  bool get needsCorrection => reconciliationStatus == 'NEEDS_CORRECTION';
  String get displayName => consumerName ?? consumerNameManual ?? consumerNumber ?? 'Unknown';

  factory OfflineDeliveryToken.fromJson(Map<String, dynamic> json) {
    return OfflineDeliveryToken(
      id: json['id']?.toString() ?? '',
      tokenNumber: json['token_number'] != null ? int.tryParse(json['token_number'].toString()) : null,
      tokenDate: json['token_date'],
      consumerId: json['consumer_id']?.toString(),
      consumerNumber: json['consumer_number'],
      consumerName: json['consumer_name'],
      consumerNameManual: json['consumer_name_manual'],
      orderNumber: json['order_number'],
      bookingOrigin: json['booking_origin'],
      dacCode: json['dac_code'],
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      cashToCollect: json['cash_to_collect'] != null ? double.tryParse(json['cash_to_collect'].toString()) : null,
      cashToCollectIsEstimated: json['cash_to_collect_is_estimated'] ?? false,
      digitalAmount: json['digital_amount'] != null ? double.tryParse(json['digital_amount'].toString()) : null,
      cashCollected: json['cash_collected'] != null ? double.tryParse(json['cash_collected'].toString()) : null,
      referenceImage1: json['reference_image_1'],
      referenceImage2: json['reference_image_2'],
      imagesUploaded: json['images_uploaded'] ?? false,
      evidenceRequired: json['evidence_required'] ?? false,
      remark: json['remark'],
      status: json['status'] ?? 'TOKEN_ISSUED',
      modeSnapshot: json['mode_snapshot'],
      creationType: json['creation_type'],
      isQuickDelivery: json['is_quick_delivery'] ?? false,
      overrideReason: json['override_reason'],
      reconciliationStatus: json['reconciliation_status'],
      reconciliationError: json['reconciliation_error'],
      company: json['company'] != null
          ? OfflineDeliveryCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      distributionPointName: json['distribution_point_name'],
      createdByName: json['created_by_name'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      printCount: json['print_count'] ?? 0,
      canPrint: json['can_print'] ?? true,
    );
  }

  OfflineDeliveryToken copyWith({
    int? printCount,
    bool? canPrint,
    String? status,
    String? reconciliationStatus,
    String? reconciliationError,
  }) {
    return OfflineDeliveryToken(
      id: id,
      tokenNumber: tokenNumber,
      tokenDate: tokenDate,
      consumerId: consumerId,
      consumerNumber: consumerNumber,
      consumerName: consumerName,
      consumerNameManual: consumerNameManual,
      orderNumber: orderNumber,
      bookingOrigin: bookingOrigin,
      dacCode: dacCode,
      deliveredAt: deliveredAt,
      cashToCollect: cashToCollect,
      cashToCollectIsEstimated: cashToCollectIsEstimated,
      digitalAmount: digitalAmount,
      cashCollected: cashCollected,
      referenceImage1: referenceImage1,
      referenceImage2: referenceImage2,
      imagesUploaded: imagesUploaded,
      evidenceRequired: evidenceRequired,
      remark: remark,
      status: status ?? this.status,
      modeSnapshot: modeSnapshot,
      creationType: creationType,
      isQuickDelivery: isQuickDelivery,
      overrideReason: overrideReason,
      reconciliationStatus: reconciliationStatus ?? this.reconciliationStatus,
      reconciliationError: reconciliationError ?? this.reconciliationError,
      distributionPointName: distributionPointName,
      company: company,
      createdByName: createdByName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      printCount: printCount ?? this.printCount,
      canPrint: canPrint ?? this.canPrint,
    );
  }

  @override
  List<Object?> get props => [
    id, tokenNumber, tokenDate, consumerId, consumerNumber,
    consumerName, consumerNameManual, orderNumber, bookingOrigin,
    dacCode, deliveredAt, cashToCollect, cashToCollectIsEstimated,
    digitalAmount, cashCollected, referenceImage1, referenceImage2,
    imagesUploaded, evidenceRequired, remark, status, modeSnapshot,
    creationType, isQuickDelivery, overrideReason,
    reconciliationStatus, reconciliationError, company,
    distributionPointName, createdByName, createdAt, updatedAt,
    printCount, canPrint,
  ];
}
