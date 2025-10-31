import 'package:equatable/equatable.dart';

enum TransactionType { deposit, handover, bank }
enum TransactionStatus { pending, approved, rejected }

class CashTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final DateTime createdAt;
  final String initiator;
  final String fromAccount;
  final String? selectedAccount;
  final String? selectedBank;
  final String? notes;
  final String? createdBy;
  final String? rejectionReason;
  final String? receiptImagePath;
  final String? paymentEntryNumber;
  final String? paidTo;
  final String? paymentType;
  final String? modeOfPayment;
  final bool? approved;
  final bool? rejected;
  final int? rejectedBy;
  final String? rejectedByName;
  final int? approvedBy;
  final String? approvedByName;
  final String? bankReferenceNo;
  final String? erpPostingStatus;
  final int? requestedBy;
  final String? requestedByName;
  final DateTime? approvedAt;
  final DateTime? updatedAt;
  final DateTime? rejectedAt;
  final String? erpnextVoucherName;
  final DateTime? erpnextPostedAt;
  final String? erpPostingError;
  final String? approvedUsingAccount;
  final String? approvedAsRole;
  final int? fromAccountId;
  final int? toAccountId;
  final Map<String, dynamic>? bankDepositDetails;

  const CashTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.initiator,
    required this.fromAccount,
    this.selectedAccount,
    this.selectedBank,
    this.notes,
    this.createdBy,
    this.rejectionReason,
    this.receiptImagePath,
    this.paymentEntryNumber,
    this.paidTo,
    this.paymentType,
    this.modeOfPayment,
    this.approved,
    this.rejected,
    this.rejectedBy,
    this.rejectedByName,
    this.approvedBy,
    this.approvedByName,
    this.bankReferenceNo,
    this.erpPostingStatus,
    this.requestedBy,
    this.requestedByName,
    this.approvedAt,
    this.rejectedAt,
    this.updatedAt,
    this.erpnextVoucherName,
    this.erpnextPostedAt,
    this.erpPostingError,
    this.approvedUsingAccount,
    this.approvedAsRole,
    this.fromAccountId,
    this.toAccountId,
    this.bankDepositDetails,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    amount,
    createdAt,
    initiator,
    fromAccount,
    selectedAccount,
    selectedBank,
    notes,
    rejectionReason,
    receiptImagePath,
    bankReferenceNo,
    erpPostingStatus,
    requestedBy,
    approvedAt,
    rejectedAt,
    erpnextVoucherName,
    erpnextPostedAt,
    erpPostingError,
    rejectedByName,
    approvedByName,
    requestedByName,
  ];

  // Helper method to safely convert to String or null
  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    return value.toString();
  }

  // Helper method to safely convert to non-empty String or null
  static String? _toNonEmptyStringOrNull(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.trim().isEmpty ? null : value.trim();
    }
    final stringValue = value.toString().trim();
    return stringValue.isEmpty ? null : stringValue;
  }

  // Helper method to safely convert to int or null
  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  // From JSON (API) with proper type handling
  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    try {
      return CashTransaction(
        id: json['id'].toString(),
        type: _parseTransactionType(json['payment_type']),
        status: _parseTransactionStatus(json['status']),
        amount: double.tryParse(json['amount'].toString()) ?? 0.0,
        createdAt: DateTime.parse(json['created_at']),
        updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
        initiator: _toStringOrNull(json['requested_by_name']) ?? 'UNKNOWN',
        fromAccount: _toStringOrNull(json['from_account_name']) ?? '',
        selectedAccount: _toNonEmptyStringOrNull(json['to_account_name']),
        selectedBank: null, // Not provided in the API response for this format
        notes: _toNonEmptyStringOrNull(json['notes']),
        rejectionReason: _toNonEmptyStringOrNull(json['rejection_reason']),
        receiptImagePath: null, // Not provided in the API response
        bankReferenceNo: _toNonEmptyStringOrNull(json['bank_reference_no']),
        erpPostingStatus: _toNonEmptyStringOrNull(json['erp_posting_status']),
        requestedBy: _toIntOrNull(json['requested_by']),
        requestedByName: _toNonEmptyStringOrNull(json['requested_by_name']),
        approvedBy: _toIntOrNull(json['approved_by']),
        approvedByName: _toNonEmptyStringOrNull(json['approved_by_name']),
        approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at']) : null,
        rejectedBy: _toIntOrNull(json['rejected_by']),
        rejectedByName: _toNonEmptyStringOrNull(json['rejected_by_name']),
        rejectedAt: json['rejected_at'] != null ? DateTime.tryParse(json['rejected_at']) : null,
        erpnextVoucherName: _toNonEmptyStringOrNull(json['erpnext_voucher_name']),
        erpnextPostedAt: json['erpnext_posted_at'] != null ? DateTime.tryParse(json['erpnext_posted_at']) : null,
        erpPostingError: _toNonEmptyStringOrNull(json['erp_posting_error']),
        approvedUsingAccount: _toNonEmptyStringOrNull(json['approved_using_account']),
        approvedAsRole: _toNonEmptyStringOrNull(json['approved_as_role']),
        fromAccountId: _toIntOrNull(json['from_account']),
        toAccountId: _toIntOrNull(json['to_account']),
        bankDepositDetails: json['bank_deposit_details'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error parsing CashTransaction from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static TransactionType _parseTransactionType(dynamic value) {
    final typeString = value?.toString().toLowerCase() ?? '';
    switch (typeString) {
      case 'handover':
        return TransactionType.handover;
      case 'bank_deposit':
        return TransactionType.bank;
      case 'deposit':
      default:
        return TransactionType.deposit;
    }
  }

  static TransactionStatus _parseTransactionStatus(dynamic value) {
    final statusString = value?.toString().toLowerCase() ?? '';
    switch (statusString) {
      case 'approved':
        return TransactionStatus.approved;
      case 'rejected':
        return TransactionStatus.rejected;
      case 'pending':
      default:
        return TransactionStatus.pending;
    }
  }

  // To JSON (API)
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "payment_type": type.name,
      "status": status.name,
      "amount": amount,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "requested_by_name": initiator,
      "from_account_name": fromAccount,
      "to_account_name": selectedAccount,
      "notes": notes,
      "rejection_reason": rejectionReason,
      "bank_reference_no": bankReferenceNo,
      "erp_posting_status": erpPostingStatus,
      "requested_by": requestedBy,
      "approved_by": approvedBy,
      "approved_by_name": approvedByName,
      "approved_at": approvedAt?.toIso8601String(),
      "rejected_by": rejectedBy,
      "rejected_by_name": rejectedByName,
      "rejected_at": rejectedAt?.toIso8601String(),
      "erpnext_voucher_name": erpnextVoucherName,
      "erpnext_posted_at": erpnextPostedAt?.toIso8601String(),
      "erp_posting_error": erpPostingError,
      "approved_using_account": approvedUsingAccount,
      "approved_as_role": approvedAsRole,
      "from_account": fromAccountId,
      "to_account": toAccountId,
    };
  }

  // Copy with method for updating transactions
  CashTransaction copyWith({
    String? id,
    TransactionType? type,
    TransactionStatus? status,
    double? amount,
    DateTime? createdAt,
    String? initiator,
    String? fromAccount,
    String? selectedAccount,
    String? selectedBank,
    String? notes,
    String? createdBy,
    String? rejectionReason,
    String? receiptImagePath,
    String? paymentEntryNumber,
    String? paidTo,
    String? paymentType,
    String? modeOfPayment,
    bool? approved,
    bool? rejected,
    int? rejectedBy,
    String? rejectedByName,
    int? approvedBy,
    String? approvedByName,
    String? bankReferenceNo,
    String? erpPostingStatus,
    int? requestedBy,
    String? requestedByName,
    DateTime? approvedAt,
    DateTime? updatedAt,
    DateTime? rejectedAt,
    String? erpnextVoucherName,
    DateTime? erpnextPostedAt,
    String? erpPostingError,
    String? approvedUsingAccount,
    String? approvedAsRole,
    int? fromAccountId,
    int? toAccountId,
  }) {
    return CashTransaction(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      initiator: initiator ?? this.initiator,
      fromAccount: fromAccount ?? this.fromAccount,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedBank: selectedBank ?? this.selectedBank,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      paymentEntryNumber: paymentEntryNumber ?? this.paymentEntryNumber,
      paidTo: paidTo ?? this.paidTo,
      paymentType: paymentType ?? this.paymentType,
      modeOfPayment: modeOfPayment ?? this.modeOfPayment,
      approved: approved ?? this.approved,
      rejected: rejected ?? this.rejected,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      rejectedByName: rejectedByName ?? this.rejectedByName,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      bankReferenceNo: bankReferenceNo ?? this.bankReferenceNo,
      erpPostingStatus: erpPostingStatus ?? this.erpPostingStatus,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      erpnextVoucherName: erpnextVoucherName ?? this.erpnextVoucherName,
      erpnextPostedAt: erpnextPostedAt ?? this.erpnextPostedAt,
      erpPostingError: erpPostingError ?? this.erpPostingError,
      approvedUsingAccount: approvedUsingAccount ?? this.approvedUsingAccount,
      approvedAsRole: approvedAsRole ?? this.approvedAsRole,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
    );
  }
}