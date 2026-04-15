import 'package:equatable/equatable.dart';
import 'quota_ledger_detail_entry.dart';

/// Detailed ledger response for a specific date and item
class QuotaHistoryDetailResponse extends Equatable {
  final DateTime entryDate;
  final String itemCode;
  final String itemName;
  final int openingBalance;
  final int closingBalance;
  final List<QuotaLedgerDetailEntry> transactions;

  const QuotaHistoryDetailResponse({
    required this.entryDate,
    required this.itemCode,
    required this.itemName,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactions,
  });

  /// Total number of transactions
  int get transactionCount => transactions.length;

  /// Net change for the day
  int get netChange => closingBalance - openingBalance;

  factory QuotaHistoryDetailResponse.fromJson(Map<String, dynamic> json) {
    // API returns 'entries' not 'transactions'
    final entriesList = (json['entries'] ?? json['transactions'] ?? []) as List;
    return QuotaHistoryDetailResponse(
      entryDate: DateTime.parse(json['entry_date'] as String),
      itemCode: json['item_code']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      openingBalance: (json['opening_balance'] as int?) ?? 0,
      closingBalance: (json['closing_balance'] as int?) ?? 0,
      transactions: entriesList
          .map((e) =>
              QuotaLedgerDetailEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entry_date': entryDate.toIso8601String(),
      'item_code': itemCode,
      'item_name': itemName,
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'transactions': transactions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        entryDate,
        itemCode,
        itemName,
        openingBalance,
        closingBalance,
        transactions,
      ];
}
