import 'package:equatable/equatable.dart';
import 'obligation_detail.dart';
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
  final String? initiationSource; // WALK_IN / OWNER_DIRECTED / SYSTEM_OBLIGATION
  final int? sourceDeliveryRecordId;
  final ObligationDetail? obligationDetail;
  final List<Map<String, dynamic>> availableActions;

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
    this.initiationSource,
    this.sourceDeliveryRecordId,
    this.obligationDetail,
    this.availableActions = const [],
  });

  bool get isPending => status == 'TOKEN_ISSUED';
  bool get isDelivered => status == 'DELIVERED';
  bool get isVoided => status == 'VOIDED';
  bool get needsCorrection => reconciliationStatus == 'NEEDS_CORRECTION';
  bool get isObligation => creationType == 'OBLIGATION';
  bool get isSystemObligation => initiationSource == 'SYSTEM_OBLIGATION';

  bool hasAction(String action) =>
      availableActions.any((a) => a['action'] == action);
  Map<String, dynamic>? getAction(String action) {
    final idx = availableActions.indexWhere((a) => a['action'] == action);
    return idx != -1 ? availableActions[idx] : null;
  }
  String get displayName {
    if (consumerName != null && consumerName!.isNotEmpty) return consumerName!;
    if (consumerNameManual != null && consumerNameManual!.isNotEmpty) return consumerNameManual!;
    if (obligationDetail?.consumerNameManual != null && obligationDetail!.consumerNameManual!.isNotEmpty) return obligationDetail!.consumerNameManual!;
    if (consumerNumber != null && consumerNumber!.isNotEmpty) return consumerNumber!;
    return 'Unknown';
  }

  factory OfflineDeliveryToken.fromJson(Map<String, dynamic> json) {
    // Parse obligation detail from either key the API might use
    final obligationJson = json['obligation_detail'] ?? json['obligation_summary'];

    return OfflineDeliveryToken(
      id: json['id']?.toString() ?? '',
      tokenNumber: json['token_number'] != null ? int.tryParse(json['token_number'].toString()) : null,
      tokenDate: json['token_date']?.toString(),
      consumerId: json['consumer_id']?.toString(),
      consumerNumber: json['consumer_number']?.toString(),
      consumerName: json['consumer_name']?.toString(),
      consumerNameManual: json['consumer_name_manual']?.toString(),
      orderNumber: json['order_number']?.toString(),
      bookingOrigin: json['booking_origin']?.toString(),
      dacCode: json['dac_code']?.toString(),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'].toString())
          : null,
      cashToCollect: json['cash_to_collect'] != null ? double.tryParse(json['cash_to_collect'].toString()) : null,
      cashToCollectIsEstimated: json['cash_to_collect_is_estimated'] ?? false,
      digitalAmount: json['digital_amount'] != null ? double.tryParse(json['digital_amount'].toString()) : null,
      cashCollected: json['cash_collected'] != null ? double.tryParse(json['cash_collected'].toString()) : null,
      referenceImage1: json['reference_image_1']?.toString(),
      referenceImage2: json['reference_image_2']?.toString(),
      imagesUploaded: json['images_uploaded'] ?? false,
      evidenceRequired: json['evidence_required'] ?? false,
      remark: json['remark']?.toString(),
      status: json['status']?.toString() ?? 'TOKEN_ISSUED',
      modeSnapshot: json['mode_snapshot']?.toString(),
      creationType: json['creation_type']?.toString(),
      isQuickDelivery: json['is_quick_delivery'] ?? false,
      overrideReason: json['override_reason']?.toString(),
      reconciliationStatus: json['reconciliation_status']?.toString(),
      reconciliationError: json['reconciliation_error']?.toString(),
      company: json['company'] is Map<String, dynamic>
          ? OfflineDeliveryCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      distributionPointName: json['distribution_point_name']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      printCount: json['print_count'] ?? 0,
      canPrint: json['can_print'] ?? true,
      initiationSource: json['initiation_source']?.toString(),
      sourceDeliveryRecordId: json['source_delivery_record_id'] != null
          ? int.tryParse(json['source_delivery_record_id'].toString())
          : null,
      obligationDetail: obligationJson is Map<String, dynamic>
          ? ObligationDetail.fromJson(obligationJson)
          : null,
      availableActions: json['available_actions'] is List
          ? (json['available_actions'] as List)
              .map((a) => a is Map<String, dynamic> ? a : <String, dynamic>{})
              .where((a) => a.isNotEmpty)
              .toList()
          : const [],
    );
  }

  OfflineDeliveryToken copyWith({
    int? printCount,
    bool? canPrint,
    String? status,
    String? reconciliationStatus,
    String? reconciliationError,
    ObligationDetail? obligationDetail,
    List<Map<String, dynamic>>? availableActions,
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
      initiationSource: initiationSource,
      sourceDeliveryRecordId: sourceDeliveryRecordId,
      obligationDetail: obligationDetail ?? this.obligationDetail,
      availableActions: availableActions ?? this.availableActions,
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
    printCount, canPrint, initiationSource, sourceDeliveryRecordId,
    obligationDetail, availableActions,
  ];
}
