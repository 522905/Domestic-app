import 'timeline_item.dart';

class DigitalCredit {
  final String id;
  final String orderId;
  final DateTime orderDate;
  final double? amount;
  final String dataStatus;
  final String dataStatusDisplay;
  final String claimStatus;
  final String claimStatusDisplay;
  final String dprStatus;
  final DateTime? deliveryDate;
  final String? consumerName;
  final String? consumerNumber;
  final String? originalDeliveryBoyName;
  final String? finalDeliveryBoyName;
  final bool isMine;
  final bool canClaim;
  final bool canRetry;
  final String source;
  final String sourceDisplay;
  final String? erpDpcName;
  final bool erpCreated;
  final bool erpClaimed;
  final List<TimelineItem>? timeline;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? dprStatusDisplay;
  final bool? autoClaimRequested;
  final bool? alreadyExists;
  final String? message;

  DigitalCredit({
    required this.id,
    required this.orderId,
    required this.orderDate,
    this.amount,
    required this.dataStatus,
    required this.dataStatusDisplay,
    required this.claimStatus,
    required this.claimStatusDisplay,
    required this.dprStatus,
    this.deliveryDate,
    this.consumerName,
    this.consumerNumber,
    this.originalDeliveryBoyName,
    this.finalDeliveryBoyName,
    required this.isMine,
    required this.canClaim,
    required this.canRetry,
    required this.source,
    required this.sourceDisplay,
    this.erpDpcName,
    required this.erpCreated,
    required this.erpClaimed,
    this.timeline,
    required this.createdAt,
    this.updatedAt,
    this.dprStatusDisplay,
    this.autoClaimRequested,
    this.alreadyExists,
    this.message,
  });

  // Computed properties
  bool get isProcessing => dataStatus == 'QUEUED' || dataStatus == 'RPA_PROCESSING';
  bool get isFailed => dataStatus == 'FAILED';
  bool get isComplete => dataStatus == 'COMPLETE';
  bool get isRejected => dataStatus == 'REJECTED';
  bool get isIncident => dataStatus == 'INCIDENT';
  bool get isUnclaimed => claimStatus == 'UNCLAIMED';
  bool get isClaimed => claimStatus == 'CLAIMED';
  bool get isPendingTransfer => claimStatus == 'PENDING_TRANSFER';
  bool get isSettled => dprStatus == 'SETTLED';

  factory DigitalCredit.fromJson(Map<String, dynamic> json) {
    return DigitalCredit(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderDate: DateTime.parse(json['order_date']),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      dataStatus: json['data_status'] as String,
      dataStatusDisplay: json['data_status_display'] as String,
      claimStatus: json['claim_status'] as String,
      claimStatusDisplay: json['claim_status_display'] as String,
      dprStatus: json['dpr_status'] as String,
      deliveryDate: json['delivery_date'] != null ? DateTime.parse(json['delivery_date']) : null,
      consumerName: json['consumer_name'] as String?,
      consumerNumber: json['consumer_number'] as String?,
      originalDeliveryBoyName: json['original_delivery_boy_name'] as String?,
      finalDeliveryBoyName: json['final_delivery_boy_name'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      canClaim: json['can_claim'] as bool? ?? false,
      canRetry: json['can_retry'] as bool? ?? false,
      source: json['source'] as String? ?? 'DELIVERY_BOY',
      sourceDisplay: json['source_display'] as String? ?? 'Delivery Boy App',
      erpDpcName: json['erp_dpc_name'] as String?,
      erpCreated: json['erp_created'] as bool? ?? false,
      erpClaimed: json['erp_claimed'] as bool? ?? false,
      timeline: json['timeline'] != null
          ? (json['timeline'] as List).map((e) => TimelineItem.fromJson(e)).toList()
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      dprStatusDisplay: json['dpr_status_display'] as String?,
      autoClaimRequested: json['auto_claim_requested'] as bool?,
      alreadyExists: json['already_exists'] as bool?,
      message: json['message'] as String?,
    );
  }

  DigitalCredit copyWith({
    String? id,
    String? orderId,
    DateTime? orderDate,
    double? amount,
    String? dataStatus,
    String? dataStatusDisplay,
    String? claimStatus,
    String? claimStatusDisplay,
    String? dprStatus,
    DateTime? deliveryDate,
    String? consumerName,
    String? consumerNumber,
    String? originalDeliveryBoyName,
    String? finalDeliveryBoyName,
    bool? isMine,
    bool? canClaim,
    bool? canRetry,
    String? source,
    String? sourceDisplay,
    String? erpDpcName,
    bool? erpCreated,
    bool? erpClaimed,
    List<TimelineItem>? timeline,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? dprStatusDisplay,
    bool? autoClaimRequested,
    bool? alreadyExists,
    String? message,
  }) {
    return DigitalCredit(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      amount: amount ?? this.amount,
      dataStatus: dataStatus ?? this.dataStatus,
      dataStatusDisplay: dataStatusDisplay ?? this.dataStatusDisplay,
      claimStatus: claimStatus ?? this.claimStatus,
      claimStatusDisplay: claimStatusDisplay ?? this.claimStatusDisplay,
      dprStatus: dprStatus ?? this.dprStatus,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      consumerName: consumerName ?? this.consumerName,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      originalDeliveryBoyName: originalDeliveryBoyName ?? this.originalDeliveryBoyName,
      finalDeliveryBoyName: finalDeliveryBoyName ?? this.finalDeliveryBoyName,
      isMine: isMine ?? this.isMine,
      canClaim: canClaim ?? this.canClaim,
      canRetry: canRetry ?? this.canRetry,
      source: source ?? this.source,
      sourceDisplay: sourceDisplay ?? this.sourceDisplay,
      erpDpcName: erpDpcName ?? this.erpDpcName,
      erpCreated: erpCreated ?? this.erpCreated,
      erpClaimed: erpClaimed ?? this.erpClaimed,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dprStatusDisplay: dprStatusDisplay ?? this.dprStatusDisplay,
      autoClaimRequested: autoClaimRequested ?? this.autoClaimRequested,
      alreadyExists: alreadyExists ?? this.alreadyExists,
      message: message ?? this.message,
    );
  }
}
