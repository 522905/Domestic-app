import 'package:equatable/equatable.dart';

/// Main container for credit extension decision context
class CreditExtensionContext extends Equatable {
  final int requestId;
  final PartnerInfo partner;
  final ItemInfo item;
  final int requestedQuantity;
  final String justification;
  final String? audioUrl;
  final LiveQuotaSnapshot liveSnapshot;
  final QuotaHistory quotaHistory;
  final List<ExtensionHistoryEntry> extensionHistory;
  final List<PendingRequest> otherPendingRequests;

  const CreditExtensionContext({
    required this.requestId,
    required this.partner,
    required this.item,
    required this.requestedQuantity,
    required this.justification,
    this.audioUrl,
    required this.liveSnapshot,
    required this.quotaHistory,
    required this.extensionHistory,
    required this.otherPendingRequests,
  });

  factory CreditExtensionContext.fromJson(Map<String, dynamic> json) {
    return CreditExtensionContext(
      requestId: json['request_id'] ?? 0,
      partner: PartnerInfo.fromJson(json['partner'] ?? {}),
      item: ItemInfo.fromJson(json['item'] ?? {}),
      requestedQuantity: json['requested_quantity'] ?? 0,
      justification: json['justification'] ?? '',
      audioUrl: json['audio_url'],
      liveSnapshot: LiveQuotaSnapshot.fromJson(json['live_snapshot'] ?? {}),
      quotaHistory: QuotaHistory.fromJson(json['quota_history'] ?? {}),
      extensionHistory: (json['extension_history'] as List<dynamic>?)
              ?.map((e) => ExtensionHistoryEntry.fromJson(e))
              .toList() ??
          [],
      otherPendingRequests: (json['other_pending_requests'] as List<dynamic>?)
              ?.map((e) => PendingRequest.fromJson(e))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        requestId,
        partner,
        item,
        requestedQuantity,
        justification,
        audioUrl,
        liveSnapshot,
        quotaHistory,
        extensionHistory,
        otherPendingRequests,
      ];
}

/// Partner information
class PartnerInfo extends Equatable {
  final int id;
  final String name;
  final String code;

  const PartnerInfo({
    required this.id,
    required this.name,
    required this.code,
  });

  factory PartnerInfo.fromJson(Map<String, dynamic> json) {
    return PartnerInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      code: json['code'] ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, code];
}

/// Item information
class ItemInfo extends Equatable {
  final String code;
  final String name;

  const ItemInfo({
    required this.code,
    required this.name,
  });

  factory ItemInfo.fromJson(Map<String, dynamic> json) {
    return ItemInfo(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [code, name];
}

/// Live quota snapshot with breakdown
class LiveQuotaSnapshot extends Equatable {
  final int opening;
  final int adjustments;
  final int orders;
  final int pickups;
  final int returns;
  final int sdmsSales;
  final int bonusConsumed;
  final int closing;
  final int bonus;
  final int creditLimit;
  final int availableBalance;
  final bool isBlocked;

  const LiveQuotaSnapshot({
    required this.opening,
    required this.adjustments,
    required this.orders,
    required this.pickups,
    required this.returns,
    required this.sdmsSales,
    required this.bonusConsumed,
    required this.closing,
    required this.bonus,
    required this.creditLimit,
    required this.availableBalance,
    required this.isBlocked,
  });

  factory LiveQuotaSnapshot.fromJson(Map<String, dynamic> json) {
    return LiveQuotaSnapshot(
      opening: json['opening'] ?? 0,
      adjustments: json['adjustments'] ?? 0,
      orders: json['orders'] ?? 0,
      pickups: json['pickups'] ?? 0,
      returns: json['returns'] ?? 0,
      sdmsSales: json['sdms_sales'] ?? 0,
      bonusConsumed: json['bonus_consumed'] ?? 0,
      closing: json['closing'] ?? 0,
      bonus: json['bonus'] ?? 0,
      creditLimit: json['credit_limit'] ?? 0,
      availableBalance: json['available_balance'] ?? 0,
      isBlocked: json['is_blocked'] ?? false,
    );
  }

  @override
  List<Object?> get props => [
        opening,
        adjustments,
        orders,
        pickups,
        returns,
        sdmsSales,
        bonusConsumed,
        closing,
        bonus,
        creditLimit,
        availableBalance,
        isBlocked,
      ];
}

/// Quota history for 7-day period
class QuotaHistory extends Equatable {
  final DateRange dateRange;
  final List<QuotaHistoryEntry> entries;
  final QuotaAggregates aggregates;

  const QuotaHistory({
    required this.dateRange,
    required this.entries,
    required this.aggregates,
  });

  factory QuotaHistory.fromJson(Map<String, dynamic> json) {
    return QuotaHistory(
      dateRange: DateRange.fromJson(json['date_range'] ?? {}),
      entries: (json['entries'] as List<dynamic>?)
              ?.map((e) => QuotaHistoryEntry.fromJson(e))
              .toList() ??
          [],
      aggregates: QuotaAggregates.fromJson(json['aggregates'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [dateRange, entries, aggregates];
}

/// Date range
class DateRange extends Equatable {
  final DateTime from;
  final DateTime to;

  const DateRange({
    required this.from,
    required this.to,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      from: DateTime.parse(json['from'] ?? DateTime.now().toIso8601String()),
      to: DateTime.parse(json['to'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [from, to];
}

/// Daily quota history entry
class QuotaHistoryEntry extends Equatable {
  final DateTime date;
  final int opening;
  final int adjustments;
  final int orders;
  final int pickups;
  final int returns;
  final int sdmsSales;
  final int closing;
  final double postingRatio;

  const QuotaHistoryEntry({
    required this.date,
    required this.opening,
    required this.adjustments,
    required this.orders,
    required this.pickups,
    required this.returns,
    required this.sdmsSales,
    required this.closing,
    required this.postingRatio,
  });

  factory QuotaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return QuotaHistoryEntry(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      opening: json['opening'] ?? 0,
      adjustments: json['adjustments'] ?? 0,
      orders: json['orders'] ?? 0,
      pickups: json['pickups'] ?? 0,
      returns: json['returns'] ?? 0,
      sdmsSales: json['sdms_sales'] ?? 0,
      closing: json['closing'] ?? 0,
      postingRatio: (json['posting_ratio'] ?? 0).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        date,
        opening,
        adjustments,
        orders,
        pickups,
        returns,
        sdmsSales,
        closing,
        postingRatio,
      ];
}

/// Aggregated quota statistics
class QuotaAggregates extends Equatable {
  final double avgDailyPickups;
  final double avgPostingRatio;
  final int totalSdmsSales;
  final int totalOrders;
  final int totalPickups;

  const QuotaAggregates({
    required this.avgDailyPickups,
    required this.avgPostingRatio,
    required this.totalSdmsSales,
    required this.totalOrders,
    required this.totalPickups,
  });

  factory QuotaAggregates.fromJson(Map<String, dynamic> json) {
    return QuotaAggregates(
      avgDailyPickups: (json['avg_daily_pickups'] ?? 0).toDouble(),
      avgPostingRatio: (json['avg_posting_ratio'] ?? 0).toDouble(),
      totalSdmsSales: json['total_sdms_sales'] ?? 0,
      totalOrders: json['total_orders'] ?? 0,
      totalPickups: json['total_pickups'] ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        avgDailyPickups,
        avgPostingRatio,
        totalSdmsSales,
        totalOrders,
        totalPickups,
      ];
}

/// Past extension history entry
class ExtensionHistoryEntry extends Equatable {
  final int id;
  final DateTime requestedAt;
  final int requestedQuantity;
  final String status;
  final int? approvedQuantity;
  final DateTime? approvedAt;
  final String? approvedBy;
  final int? quantityConsumed;
  final int? quantityRemaining;
  final String? rejectionReason;

  const ExtensionHistoryEntry({
    required this.id,
    required this.requestedAt,
    required this.requestedQuantity,
    required this.status,
    this.approvedQuantity,
    this.approvedAt,
    this.approvedBy,
    this.quantityConsumed,
    this.quantityRemaining,
    this.rejectionReason,
  });

  factory ExtensionHistoryEntry.fromJson(Map<String, dynamic> json) {
    return ExtensionHistoryEntry(
      id: json['id'] ?? 0,
      requestedAt: DateTime.parse(
          json['requested_at'] ?? DateTime.now().toIso8601String()),
      requestedQuantity: json['requested_quantity'] ?? 0,
      status: json['status'] ?? '',
      approvedQuantity: json['approved_quantity'],
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'])
          : null,
      approvedBy: json['approved_by'],
      quantityConsumed: json['quantity_consumed'],
      quantityRemaining: json['quantity_remaining'],
      rejectionReason: json['rejection_reason'],
    );
  }

  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  @override
  List<Object?> get props => [
        id,
        requestedAt,
        requestedQuantity,
        status,
        approvedQuantity,
        approvedAt,
        approvedBy,
        quantityConsumed,
        quantityRemaining,
        rejectionReason,
      ];
}

/// Other pending credit extension requests
class PendingRequest extends Equatable {
  final int id;
  final String itemCode;
  final String itemName;
  final int requestedQuantity;
  final DateTime requestedAt;

  const PendingRequest({
    required this.id,
    required this.itemCode,
    required this.itemName,
    required this.requestedQuantity,
    required this.requestedAt,
  });

  factory PendingRequest.fromJson(Map<String, dynamic> json) {
    return PendingRequest(
      id: json['id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      itemName: json['item_name'] ?? '',
      requestedQuantity: json['requested_quantity'] ?? 0,
      requestedAt: DateTime.parse(
          json['requested_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemCode,
        itemName,
        requestedQuantity,
        requestedAt,
      ];
}
