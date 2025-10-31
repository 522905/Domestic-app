class GeneralLedgerResponse {
  final double openingBalance;
  final double closingBalance;
  final double totalDebit;
  final double totalCredit;
  final List<GeneralLedgerTransaction> transactions;
  final String fromDate;
  final String toDate;
  final List<String> accounts;
  final String? party;
  final String company;

  GeneralLedgerResponse({
    required this.openingBalance,
    required this.closingBalance,
    required this.totalDebit,
    required this.totalCredit,
    required this.transactions,
    required this.fromDate,
    required this.toDate,
    required this.accounts,
    this.party,
    required this.company,
  });

  factory GeneralLedgerResponse.fromJson(Map<String, dynamic> json) {
    return GeneralLedgerResponse(
      openingBalance: (json['opening_balance'] ?? 0.0).toDouble(),
      closingBalance: (json['closing_balance'] ?? 0.0).toDouble(),
      totalDebit: (json['total_debit'] ?? 0.0).toDouble(),
      totalCredit: (json['total_credit'] ?? 0.0).toDouble(),
      transactions: (json['transactions'] as List? ?? [])
          .map((tx) => GeneralLedgerTransaction.fromJson(tx))
          .toList(),
      fromDate: json['from_date'] ?? '',
      toDate: json['to_date'] ?? '',
      accounts: (json['accounts'] as List? ?? []).cast<String>(),
      party: json['party'],
      company: json['company'] ?? '',
    );
  }
}

class GeneralLedgerTransaction {
  final String postingDate;
  final String account;
  final String? partyType;
  final String? party;
  final String voucherType;
  final String? voucherSubtype;
  final String voucherNo;
  final double debit;
  final double credit;
  final double balance;
  final String? against;
  final String? billNo;
  final String? costCenter;
  final String? project;
  final String? remarks; // Added this field

  GeneralLedgerTransaction({
    required this.postingDate,
    required this.account,
    this.partyType,
    this.party,
    required this.voucherType,
    this.voucherSubtype,
    required this.voucherNo,
    required this.debit,
    required this.credit,
    required this.balance,
    this.against,
    this.billNo,
    this.costCenter,
    this.project,
    this.remarks, // Added this parameter
  });

  factory GeneralLedgerTransaction.fromJson(Map<String, dynamic> json) {
    return GeneralLedgerTransaction(
      postingDate: json['posting_date'] ?? '',
      account: json['account'] ?? '',
      partyType: json['party_type'],
      party: json['party'],
      voucherType: json['voucher_type'] ?? '',
      voucherSubtype: json['voucher_subtype'],
      voucherNo: json['voucher_no'] ?? '',
      debit: (json['debit'] ?? 0.0).toDouble(),
      credit: (json['credit'] ?? 0.0).toDouble(),
      balance: (json['balance'] ?? 0.0).toDouble(),
      against: json['against'],
      billNo: json['bill_no'],
      costCenter: json['cost_center'],
      project: json['project'],
      remarks: json['remarks'], // Added this line
    );
  }

  DateTime get date => DateTime.parse(postingDate);
}