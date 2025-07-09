import 'package:equatable/equatable.dart';

enum TransactionType { deposit, handover, bank }

enum TransactionStatus { pending, approved, rejected }

enum TransactionAccountType { svTv, refill, nfr }

class CashTransaction extends Equatable {
  final String id;
  final TransactionType type;
  final TransactionStatus status;
  final double amount;
  final DateTime createdAt;
  final String initiator;
  final String? selectedAccount;
  final String? selectedBank;
  final TransactionAccountType accountType;
  final String? notes;
  final String? createdBy;
  final String? rejectionReason;
  final String? receiptImagePath;
  final String? paymentEntryNumber;
  final String? paidTo;
  final String ? paymentType;
  final String ? modeOfPayment;
  final bool ? approved;
  final bool ? rejected;
  final String ? rejectedBy;
  final String ? approvedBy;



  const CashTransaction({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    required this.createdAt,
    required this.initiator,
    required this.accountType,
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
    this.approvedBy,
    this.rejectedBy,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    amount,
    createdAt,
    initiator,
    selectedAccount,
    selectedBank,
    accountType,
    notes,
    rejectionReason,
    receiptImagePath,
  ];

  // Factory methods for convenience - update with receiptImagePath
  factory CashTransaction.deposit({
    required String id,
    required TransactionStatus status,
    required double amount,
    required DateTime timestamp,
    required String initiator,
    required TransactionAccountType accountType,
    String? notes,
    String? rejectionReason,
    String? receiptImagePath,
  }) {
    return CashTransaction(
      id: id,
      type: TransactionType.deposit,
      status: status,
      amount: amount,
      createdAt: timestamp,
      initiator: initiator,
      accountType: accountType,
      notes: notes,
      rejectionReason: rejectionReason,
      receiptImagePath: receiptImagePath,
    );
  }

  factory CashTransaction.handover({
    required String id,
    required TransactionStatus status,
    required double amount,
    required DateTime timestamp,
    required String initiator,
    required String recipient,
    required TransactionAccountType accountType,
    String? notes,
    String? rejectionReason,
    String? receiptImagePath,
  }) {
    return CashTransaction(
      id: id,
      type: TransactionType.handover,
      status: status,
      amount: amount,
      createdAt: timestamp,
      initiator: initiator,
      selectedAccount: recipient,
      accountType: accountType,
      notes: notes,
      rejectionReason: rejectionReason,
      receiptImagePath: receiptImagePath,
    );
  }

  factory CashTransaction.bank({
    required String id,
    required TransactionStatus status,
    required double amount,
    required DateTime timestamp,
    required String initiator,
    required String bankDetails,
    required TransactionAccountType accountType,
    String? notes,
    String? rejectionReason,
    String? receiptImagePath,
  }) {
    return CashTransaction(
      id: id,
      type: TransactionType.bank,
      status: status,
      amount: amount,
      createdAt: timestamp,
      initiator: initiator,
      selectedBank: bankDetails,
      accountType: accountType,
      notes: notes,
      rejectionReason: rejectionReason,
      receiptImagePath: receiptImagePath,
    );
  }

  // From JSON (API)
  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    return CashTransaction(
      id: json['id'],
      type: TransactionType.values.firstWhere(
              (e) => e.name == json['type'],
          orElse: () => TransactionType.deposit),
      status: TransactionStatus.values.firstWhere(
              (e) => e.name == json['status'],
          orElse: () => TransactionStatus.pending),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['date']),
      initiator: json['initiator'] ?? 'UNKNOWN',
      selectedAccount: json['recipient'],
      selectedBank: json['bankDetails'],
      accountType: TransactionAccountType.values.firstWhere(
              (e) => e.name == json['account'],
          orElse: () => TransactionAccountType.refill),
      notes: json['notes'],
      rejectionReason: json['rejectionReason'],
      receiptImagePath: json['receiptImagePath'],
    );
  }

  // To JSON (API)
  Map<String, dynamic> toJson() {
    return {
      "type": type.name,
      "status": status.name,
      "amount": amount,
      "date": createdAt.toIso8601String(),
      "initiator": initiator,
      "recipient": selectedAccount,
      "bankDetails": selectedBank,
      "account": accountType.name,
      "notes": notes,
      "rejectionReason": rejectionReason,
      "receiptImagePath": receiptImagePath,
    };
  }


  // UI Helper Getters
  String get statusText => status.name.toUpperCase();
  String get typePrefix {
    switch (type) {
      case TransactionType.deposit:
        return 'DEP';
      case TransactionType.handover:
        return 'CH';
      case TransactionType.bank:
        return 'BD';
    }
  }

  String get accountTypeText {
    switch (accountType) {
      case TransactionAccountType.svTv:
        return 'SV/TV Account';
      case TransactionAccountType.refill:
        return 'Refill Account';
      case TransactionAccountType.nfr:
        return 'NFR Account';
    }
  }

  bool get isOutgoing =>
      type == TransactionType.handover ||
          (type == TransactionType.bank && amount > 0);

  bool get hasReceipt =>
      receiptImagePath != null && receiptImagePath!.isNotEmpty;
}