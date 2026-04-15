import 'package:equatable/equatable.dart';

/// Represents a single ledger transaction for quota detail view
class QuotaLedgerDetailEntry extends Equatable {
  final String time;
  final String entryType;
  final String entryTypeDisplay;
  final int quantity;
  final String company;
  final String? journalNumber;
  final String? notes;
  final String? orderNumber;
  final String? orderDate;

  const QuotaLedgerDetailEntry({
    required this.time,
    required this.entryType,
    required this.entryTypeDisplay,
    required this.quantity,
    required this.company,
    this.journalNumber,
    this.notes,
    this.orderNumber,
    this.orderDate,
  });

  /// Whether this is a positive (credit) transaction
  bool get isPositive => quantity > 0;

  /// Absolute value of quantity
  int get absoluteQuantity => quantity.abs();

  /// Color indicator based on entry type
  EntryTypeColor get colorIndicator {
    switch (entryType) {
      case 'PICKUP':
      case 'ADJUSTMENT_NEGATIVE':
      case 'TRANSFER_OUT':
      case 'GODOWN_FULFILLED':
        return EntryTypeColor.negative;
      case 'RETURN':
      case 'SALE_OTP':
      case 'SALE_OVERRIDE':
      case 'TOKEN_CREDIT':
      case 'BONUS_CONSUMED':
      case 'ADJUSTMENT_POSITIVE':
      case 'TRANSFER_IN':
        return EntryTypeColor.positive;
      default:
        return EntryTypeColor.neutral;
    }
  }

  factory QuotaLedgerDetailEntry.fromJson(Map<String, dynamic> json) {
    return QuotaLedgerDetailEntry(
      time: json['time']?.toString() ?? '',
      entryType: json['entry_type']?.toString() ?? '',
      entryTypeDisplay: json['entry_type_display']?.toString() ?? '',
      quantity: (json['quantity'] as int?) ?? 0,
      company: json['company']?.toString() ?? '',
      journalNumber: json['journal_number']?.toString(),
      notes: json['notes']?.toString(),
      orderNumber: json['order_number']?.toString(),
      orderDate: json['order_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'entry_type': entryType,
      'entry_type_display': entryTypeDisplay,
      'quantity': quantity,
      'company': company,
      'journal_number': journalNumber,
      'notes': notes,
      'order_number': orderNumber,
      'order_date': orderDate,
    };
  }

  @override
  List<Object?> get props => [
        time,
        entryType,
        entryTypeDisplay,
        quantity,
        company,
        journalNumber,
        notes,
        orderNumber,
        orderDate,
      ];
}

/// Color indicator for different entry types
enum EntryTypeColor {
  positive,  // Green - adds to quota
  negative,  // Red - subtracts from quota
  neutral,   // Gray - informational
}
