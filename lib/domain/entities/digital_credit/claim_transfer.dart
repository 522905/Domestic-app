class ClaimTransfer {
  final String id;
  final String creditId;
  final String orderId;
  final double amount;
  final String fromUserName;
  final String toUserName;
  final String status;
  final DateTime requestedAt;
  final DateTime autoApproveAt;
  final String autoApproveDisplay;
  final double? hoursRemaining;
  final String? rejectionReason;
  final DateTime? resolvedAt;

  ClaimTransfer({
    required this.id,
    required this.creditId,
    required this.orderId,
    required this.amount,
    required this.fromUserName,
    required this.toUserName,
    required this.status,
    required this.requestedAt,
    required this.autoApproveAt,
    required this.autoApproveDisplay,
    this.hoursRemaining,
    this.rejectionReason,
    this.resolvedAt,
  });

  // Computed properties
  bool get isPending => status == 'PENDING';
  bool get isApproved => status == 'APPROVED' || status == 'AUTO_APPROVED';
  bool get isRejected => status == 'REJECTED';

  Duration get timeRemaining => autoApproveAt.difference(DateTime.now());

  factory ClaimTransfer.fromJson(Map<String, dynamic> json) {
    return ClaimTransfer(
      id: json['id'] as String,
      creditId: json['credit_id'] as String,
      orderId: json['order_id'] as String,
      amount: double.parse(json['amount'].toString()),
      fromUserName: json['from_user_name'] as String,
      toUserName: json['to_user_name'] as String,
      status: json['status'] as String,
      requestedAt: DateTime.parse(json['requested_at']),
      autoApproveAt: DateTime.parse(json['auto_approve_at']),
      autoApproveDisplay: json['auto_approve_display'] as String,
      hoursRemaining: json['hours_remaining'] != null
          ? double.tryParse(json['hours_remaining'].toString())
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
    );
  }
}
