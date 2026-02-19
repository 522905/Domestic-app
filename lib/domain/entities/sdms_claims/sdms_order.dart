import 'claim_transfer.dart';
import 'dpc_posting.dart';
import 'order_item.dart';

/// SDMS Order entity with dual-track status (data_status + claim_status)
/// and optional ERP posting for online payments
/// Draft v3: Added nested transfer data (pendingTransfer, transferHistory, pendingTransferSummary)
class SdmsOrder {
  final String id;
  final String orderId;
  final DateTime? orderDate;
  final String orderCategory; // REFILL, SV, TV_IN, TV_OUT, CONVERSION, ADDON, UNKNOWN
  final String paymentMode; // CASH, ONLINE, UNKNOWN
  final String postingType; // NORMAL, SYSTEM, UNKNOWN
  final String dataStatus; // QUEUED, PROCESSING, COMPLETE, FAILED, INCIDENT, PENDING_COMPLETION
  final String claimStatus; // PENDING_DATA, UNCLAIMED, PENDING_APPROVAL, CLAIMED, REJECTED
  final String settlementStatus; // N/A, UNSETTLED, SETTLED
  final double? amount;
  final String? consumerName;
  final String? consumerNumber;
  final String? consumerAddress;
  final String? consumerPhone;
  final String? originalDeliveryBoyName;
  final String? claimedByName;
  final String source; // FLUTTER_APP, DELIVERY_REGISTER, DPR_IMPORT
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool canClaim;
  final bool canRetry;

  // v1.6: Error categorization and company switching
  final String errorCategory;  // NOT_FOUND, PENDING_COMPLETION, REJECTED, or ""
  final bool canSwitchCompany;

  // Draft v3: Nested transfer data
  final PendingTransferSummary? pendingTransferSummary; // For list view
  final PendingTransfer? pendingTransfer; // For detail view
  final List<TransferHistory> transferHistory; // For detail view

  // Hot fix 2026-02-12: Beneficiary partner fields
  final String? originalPartnerName;
  final String? claimedPartnerName;
  final bool? isBeneficiary;

  // Detail fields (from order detail endpoint)
  final DateTime? deliveryDate;
  final String? orderSubtypeRaw;
  final String? sdmsUserCode;
  final String? sdmsDeliveryBoyName;
  final int? intendedClaimant;
  final bool? autoClaimed;
  final String? rejectionReason;
  final DpcPosting? dpcPosting;
  final Map<String, dynamic>? soPosting;
  final bool? quotaAdjusted;
  final String? camundaProcessId;
  final int? retryCount;
  final String? rpaError;
  final List<OrderItem> items;

  // Create order response fields
  final bool? created;
  final String? message;

  SdmsOrder({
    required this.id,
    required this.orderId,
    this.orderDate,
    required this.orderCategory,
    required this.paymentMode,
    required this.postingType,
    required this.dataStatus,
    required this.claimStatus,
    required this.settlementStatus,
    this.amount,
    this.consumerName,
    this.consumerNumber,
    this.consumerAddress,
    this.consumerPhone,
    this.originalDeliveryBoyName,
    this.claimedByName,
    required this.source,
    required this.createdAt,
    this.updatedAt,
    required this.canClaim,
    required this.canRetry,
    this.errorCategory = '',
    this.canSwitchCompany = false,
    this.pendingTransferSummary,
    this.pendingTransfer,
    this.transferHistory = const [],
    this.originalPartnerName,
    this.claimedPartnerName,
    this.isBeneficiary,
    this.deliveryDate,
    this.orderSubtypeRaw,
    this.sdmsUserCode,
    this.sdmsDeliveryBoyName,
    this.intendedClaimant,
    this.autoClaimed,
    this.rejectionReason,
    this.dpcPosting,
    this.soPosting,
    this.quotaAdjusted,
    this.camundaProcessId,
    this.retryCount,
    this.rpaError,
    this.items = const [],
    this.created,
    this.message,
  });

  // Computed properties for RPA status
  bool get isQueued => dataStatus == 'QUEUED';
  bool get isProcessing => dataStatus == 'PROCESSING';
  bool get isRpaInProgress => isQueued || isProcessing;
  bool get isComplete => dataStatus == 'COMPLETE';
  bool get isFailed => dataStatus == 'FAILED';
  bool get isIncident => dataStatus == 'INCIDENT';
  bool get isPendingCompletion => dataStatus == 'PENDING_COMPLETION';
  bool get isRpaTerminal => isComplete || isFailed || isIncident || isPendingCompletion;

  // Computed properties for claim status
  bool get isPendingData => claimStatus == 'PENDING_DATA';
  bool get isUnclaimed => claimStatus == 'UNCLAIMED';
  bool get isPendingApproval => claimStatus == 'PENDING_APPROVAL';
  bool get isClaimed => claimStatus == 'CLAIMED';
  bool get isRejected => claimStatus == 'REJECTED';

  // Computed properties for category
  bool get isRefill => orderCategory == 'REFILL';
  bool get isServiceOrder =>
      orderCategory == 'SV' ||
      orderCategory == 'TV_IN' ||
      orderCategory == 'TV_OUT' ||
      orderCategory == 'CONVERSION' ||
      orderCategory == 'ADDON';

  // Computed properties for payment
  bool get isOnlinePayment => paymentMode == 'ONLINE';
  bool get isCashPayment => paymentMode == 'CASH';

  // Computed properties for posting type
  bool get isNormalPosting => postingType == 'NORMAL';
  bool get isSystemPosting => postingType == 'SYSTEM';

  // v1.6: Error category helpers
  bool get isNotFoundError => errorCategory == 'NOT_FOUND';
  bool get isPendingCompletionError => errorCategory == 'PENDING_COMPLETION';
  bool get isRejectedError => errorCategory == 'REJECTED';
  bool get hasErrorCategory => errorCategory.isNotEmpty;

  String getErrorCategoryMessage() {
    switch (errorCategory) {
      case 'NOT_FOUND':
        return 'Order not found in this company';
      case 'PENDING_COMPLETION':
        return 'Order not yet completed in SDMS';
      case 'REJECTED':
        return 'Rejected: ${rpaError ?? "Unknown reason"}';
      default:
        return rpaError != null && rpaError!.isNotEmpty
            ? 'Error: $rpaError'
            : 'RPA processing failed';
    }
  }

  // Display helpers
  String get categoryDisplay {
    switch (orderCategory) {
      case 'REFILL':
        return 'Refill';
      case 'SV':
        return 'Subscription Voucher';
      case 'TV_IN':
        return 'Termination Voucher In';
      case 'TV_OUT':
        return 'Termination Voucher Out';
      case 'CONVERSION':
        return 'Conversion';
      case 'ADDON':
        return 'Addon';
      default:
        return 'Unknown';
    }
  }

  String get paymentModeDisplay {
    switch (paymentMode) {
      case 'ONLINE':
        return 'Online';
      case 'CASH':
        return 'Cash';
      default:
        return 'Unknown';
    }
  }

  String get sourceDisplay {
    switch (source) {
      case 'FLUTTER_APP':
        return 'Flutter App';
      case 'DELIVERY_REGISTER':
        return 'Delivery Register';
      case 'DPR_IMPORT':
        return 'DPR Import';
      default:
        return source;
    }
  }

  /// Get user-friendly combined status for UI display
  String getCombinedStatusDisplay() {
    if (isRpaInProgress) return 'Fetching data...';
    if (isFailed) return 'Failed - Tap to retry';
    if (isIncident) return 'Needs attention';
    if (isPendingCompletion) return 'Pending in SDMS';
    if (isUnclaimed) return 'Ready to claim';
    if (isPendingApproval) return 'Transfer pending';
    if (isClaimed) return 'Claimed';
    if (isRejected) return 'Rejected';
    return 'Unknown';
  }

  factory SdmsOrder.fromJson(Map<String, dynamic> json) {
    return SdmsOrder(
      id: json['id'].toString(),
      orderId: json['order_id'] as String,
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : null,
      orderCategory: json['order_category'] as String? ?? 'UNKNOWN',
      paymentMode: json['payment_mode'] as String? ?? 'UNKNOWN',
      postingType: json['posting_type'] as String? ?? 'UNKNOWN',
      dataStatus: json['data_status'] as String? ?? 'QUEUED',
      claimStatus: json['claim_status'] as String? ?? 'PENDING_DATA',
      settlementStatus: json['settlement_status'] as String? ?? 'N/A',
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      consumerName: json['consumer_name'] as String?,
      consumerNumber: json['consumer_number'] as String?,
      consumerAddress: json['consumer_address'] as String?,
      consumerPhone: json['consumer_phone'] as String?,
      originalDeliveryBoyName: json['original_delivery_boy_name'] as String?,
      claimedByName: json['claimed_by_name'] as String?,
      source: json['source'] as String? ?? 'FLUTTER_APP',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      canClaim: json['can_claim'] as bool? ?? false,
      canRetry: json['can_retry'] as bool? ?? false,
      errorCategory: json['error_category'] as String? ?? '',
      canSwitchCompany: json['can_switch_company'] as bool? ?? false,
      pendingTransferSummary: json['pending_transfer_summary'] != null
          ? PendingTransferSummary.fromJson(
              json['pending_transfer_summary'] as Map<String, dynamic>)
          : null,
      pendingTransfer: json['pending_transfer'] != null
          ? PendingTransfer.fromJson(
              json['pending_transfer'] as Map<String, dynamic>)
          : null,
      transferHistory: json['transfer_history'] != null
          ? (json['transfer_history'] as List)
              .map((e) => TransferHistory.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      originalPartnerName: json['original_partner_name'] as String?,
      claimedPartnerName: json['claimed_partner_name'] as String?,
      isBeneficiary: json['is_beneficiary'] as bool?,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      orderSubtypeRaw: json['order_subtype_raw'] as String?,
      sdmsUserCode: json['sdms_user_code'] as String?,
      sdmsDeliveryBoyName: json['sdms_delivery_boy_name'] as String?,
      intendedClaimant: json['intended_claimant'] as int?,
      autoClaimed: json['auto_claimed'] as bool?,
      rejectionReason: json['rejection_reason'] as String?,
      dpcPosting: json['dpc_posting'] != null
          ? DpcPosting.fromJson(json['dpc_posting'] as Map<String, dynamic>)
          : null,
      soPosting: json['so_posting'] as Map<String, dynamic>?,
      quotaAdjusted: json['quota_adjusted'] as bool?,
      camundaProcessId: json['camunda_process_id'] as String?,
      retryCount: json['retry_count'] as int?,
      rpaError: json['rpa_error'] as String?,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      created: json['created'] as bool?,
      message: json['message'] as String?,
    );
  }

  SdmsOrder copyWith({
    String? id,
    String? orderId,
    DateTime? orderDate,
    String? orderCategory,
    String? paymentMode,
    String? postingType,
    String? dataStatus,
    String? claimStatus,
    String? settlementStatus,
    double? amount,
    String? consumerName,
    String? consumerNumber,
    String? consumerAddress,
    String? consumerPhone,
    String? originalDeliveryBoyName,
    String? claimedByName,
    String? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? canClaim,
    bool? canRetry,
    String? errorCategory,
    bool? canSwitchCompany,
    PendingTransferSummary? pendingTransferSummary,
    PendingTransfer? pendingTransfer,
    List<TransferHistory>? transferHistory,
    String? originalPartnerName,
    String? claimedPartnerName,
    bool? isBeneficiary,
    DateTime? deliveryDate,
    String? orderSubtypeRaw,
    String? sdmsUserCode,
    String? sdmsDeliveryBoyName,
    int? intendedClaimant,
    bool? autoClaimed,
    String? rejectionReason,
    DpcPosting? dpcPosting,
    Map<String, dynamic>? soPosting,
    bool? quotaAdjusted,
    String? camundaProcessId,
    int? retryCount,
    String? rpaError,
    List<OrderItem>? items,
    bool? created,
    String? message,
  }) {
    return SdmsOrder(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      orderCategory: orderCategory ?? this.orderCategory,
      paymentMode: paymentMode ?? this.paymentMode,
      postingType: postingType ?? this.postingType,
      dataStatus: dataStatus ?? this.dataStatus,
      claimStatus: claimStatus ?? this.claimStatus,
      settlementStatus: settlementStatus ?? this.settlementStatus,
      amount: amount ?? this.amount,
      consumerName: consumerName ?? this.consumerName,
      consumerNumber: consumerNumber ?? this.consumerNumber,
      consumerAddress: consumerAddress ?? this.consumerAddress,
      consumerPhone: consumerPhone ?? this.consumerPhone,
      originalDeliveryBoyName:
          originalDeliveryBoyName ?? this.originalDeliveryBoyName,
      claimedByName: claimedByName ?? this.claimedByName,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canClaim: canClaim ?? this.canClaim,
      canRetry: canRetry ?? this.canRetry,
      errorCategory: errorCategory ?? this.errorCategory,
      canSwitchCompany: canSwitchCompany ?? this.canSwitchCompany,
      pendingTransferSummary:
          pendingTransferSummary ?? this.pendingTransferSummary,
      pendingTransfer: pendingTransfer ?? this.pendingTransfer,
      transferHistory: transferHistory ?? this.transferHistory,
      originalPartnerName: originalPartnerName ?? this.originalPartnerName,
      claimedPartnerName: claimedPartnerName ?? this.claimedPartnerName,
      isBeneficiary: isBeneficiary ?? this.isBeneficiary,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      orderSubtypeRaw: orderSubtypeRaw ?? this.orderSubtypeRaw,
      sdmsUserCode: sdmsUserCode ?? this.sdmsUserCode,
      sdmsDeliveryBoyName: sdmsDeliveryBoyName ?? this.sdmsDeliveryBoyName,
      intendedClaimant: intendedClaimant ?? this.intendedClaimant,
      autoClaimed: autoClaimed ?? this.autoClaimed,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      dpcPosting: dpcPosting ?? this.dpcPosting,
      soPosting: soPosting ?? this.soPosting,
      quotaAdjusted: quotaAdjusted ?? this.quotaAdjusted,
      camundaProcessId: camundaProcessId ?? this.camundaProcessId,
      retryCount: retryCount ?? this.retryCount,
      rpaError: rpaError ?? this.rpaError,
      items: items ?? this.items,
      created: created ?? this.created,
      message: message ?? this.message,
    );
  }
}
