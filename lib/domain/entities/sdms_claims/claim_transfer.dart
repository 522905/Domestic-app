/// Draft v3: Transfer summary for list view (nested in order list response)
class PendingTransferSummary {
  final String toUserName;
  final DateTime autoApproveAt;
  final bool isActionableByMe;

  PendingTransferSummary({
    required this.toUserName,
    required this.autoApproveAt,
    required this.isActionableByMe,
  });

  /// Time remaining until auto-approval (can be negative if already passed)
  Duration get timeRemaining => autoApproveAt.difference(DateTime.now());

  /// User-friendly time remaining display
  String get timeRemainingDisplay {
    final remaining = timeRemaining;
    if (remaining.isNegative) {
      return 'Auto-approved';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 24) {
      final days = (hours / 24).floor();
      return 'Auto-approves in $days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Auto-approves in $hours hour${hours > 1 ? 's' : ''}';
    } else {
      return 'Auto-approves in $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  factory PendingTransferSummary.fromJson(Map<String, dynamic> json) {
    return PendingTransferSummary(
      toUserName: json['to_user_name'] as String,
      autoApproveAt: DateTime.parse(json['auto_approve_at']),
      isActionableByMe: json['is_actionable_by_me'] as bool? ?? false,
    );
  }
}

/// Draft v3: Pending transfer for detail view (nested in order detail response)
class PendingTransfer {
  final String id;
  final String fromUserName;
  final String toUserName;
  final String status; // Always 'PENDING'
  final DateTime autoApproveAt;
  final bool canApprove;
  final bool canReject;
  final bool canCancel;
  final DateTime createdAt;

  PendingTransfer({
    required this.id,
    required this.fromUserName,
    required this.toUserName,
    required this.status,
    required this.autoApproveAt,
    required this.canApprove,
    required this.canReject,
    required this.canCancel,
    required this.createdAt,
  });

  /// Time remaining until auto-approval (can be negative if already passed)
  Duration get timeRemaining => autoApproveAt.difference(DateTime.now());

  /// User-friendly time remaining display
  String get timeRemainingDisplay {
    final remaining = timeRemaining;
    if (remaining.isNegative) {
      return 'Auto-approved';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 24) {
      final days = (hours / 24).floor();
      return 'Auto-approves in $days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Auto-approves in $hours hour${hours > 1 ? 's' : ''}';
    } else {
      return 'Auto-approves in $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  factory PendingTransfer.fromJson(Map<String, dynamic> json) {
    return PendingTransfer(
      id: json['id'] as String,
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      status: json['status'] as String,
      autoApproveAt: DateTime.parse(json['auto_approve_at']),
      canApprove: json['can_approve'] as bool? ?? false,
      canReject: json['can_reject'] as bool? ?? false,
      canCancel: json['can_cancel'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Draft v3: Transfer history entry (nested in order detail response)
class TransferHistory {
  final String id;
  final String fromUserName;
  final String toUserName;
  final String status; // APPROVED, REJECTED, AUTO_APPROVED, CANCELLED
  final DateTime resolvedAt;
  final String? rejectionReason;

  TransferHistory({
    required this.id,
    required this.fromUserName,
    required this.toUserName,
    required this.status,
    required this.resolvedAt,
    this.rejectionReason,
  });

  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isAutoApproved => status == 'AUTO_APPROVED';
  bool get isCancelled => status == 'CANCELLED';

  factory TransferHistory.fromJson(Map<String, dynamic> json) {
    return TransferHistory(
      id: json['id'] as String,
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      status: json['status'] as String,
      resolvedAt: DateTime.parse(json['resolved_at']),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }
}

/// Claim transfer request with approval workflow
/// v1.3: Added orderDate, orderAmount, canApprove, canReject fields
/// DEPRECATED: Use PendingTransfer/TransferHistory for Draft v3
class ClaimTransfer {
  final String id;
  final String orderId;
  final DateTime? orderDate;
  final double? orderAmount;
  final String fromUserName;
  final String toUserName;
  final String status; // PENDING, APPROVED, REJECTED, AUTO_APPROVED
  final DateTime autoApproveAt;
  final DateTime? resolvedAt;
  final String? rejectionReason;
  final bool canApprove; // v1.3: Whether current user can approve
  final bool canReject; // v1.3: Whether current user can reject
  final DateTime createdAt;

  ClaimTransfer({
    required this.id,
    required this.orderId,
    this.orderDate,
    this.orderAmount,
    required this.fromUserName,
    required this.toUserName,
    required this.status,
    required this.autoApproveAt,
    this.resolvedAt,
    this.rejectionReason,
    required this.canApprove,
    required this.canReject,
    required this.createdAt,
  });

  // Computed properties
  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED';
  bool get isRejected => status == 'REJECTED';
  bool get isAutoApproved => status == 'AUTO_APPROVED';

  /// Time remaining until auto-approval (can be negative if already passed)
  Duration get timeRemaining => autoApproveAt.difference(DateTime.now());

  /// User-friendly time remaining display
  String get timeRemainingDisplay {
    final remaining = timeRemaining;
    if (remaining.isNegative) {
      return 'Auto-approved';
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    if (hours > 24) {
      final days = (hours / 24).floor();
      return 'Auto-approves in $days day${days > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return 'Auto-approves in $hours hour${hours > 1 ? 's' : ''}';
    } else {
      return 'Auto-approves in $minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  factory ClaimTransfer.fromJson(Map<String, dynamic> json) {
    return ClaimTransfer(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderDate: json['order_date'] != null
          ? DateTime.parse(json['order_date'])
          : null,
      orderAmount: json['order_amount'] != null
          ? double.tryParse(json['order_amount'].toString())
          : null,
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      status: json['status'] as String,
      autoApproveAt: DateTime.parse(json['auto_approve_at']),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      canApprove: json['can_approve'] as bool? ?? false,
      canReject: json['can_reject'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  ClaimTransfer copyWith({
    String? id,
    String? orderId,
    DateTime? orderDate,
    double? orderAmount,
    String? fromUserName,
    String? toUserName,
    String? status,
    DateTime? autoApproveAt,
    DateTime? resolvedAt,
    String? rejectionReason,
    bool? canApprove,
    bool? canReject,
    DateTime? createdAt,
  }) {
    return ClaimTransfer(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      orderAmount: orderAmount ?? this.orderAmount,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      status: status ?? this.status,
      autoApproveAt: autoApproveAt ?? this.autoApproveAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      canApprove: canApprove ?? this.canApprove,
      canReject: canReject ?? this.canReject,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
