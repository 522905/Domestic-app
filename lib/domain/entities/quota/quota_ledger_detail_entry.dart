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

  const QuotaLedgerDetailEntry({
    required this.time,
    required this.entryType,
    required this.entryTypeDisplay,
    required this.quantity,
    required this.company,
    this.journalNumber,
    this.notes,
  });

  /// Whether this is a positive (credit) transaction
  bool get isPositive => quantity > 0;

  /// Absolute value of quantity
  int get absoluteQuantity => quantity.abs();

  /// Color indicator based on entry type
  EntryTypeColor get colorIndicator {
    switch (entryType) {
      case 'PICKUP':
        return EntryTypeColor.negative;
      case 'RETURN':
      case 'SALE_OTP':
      case 'SALE_OVERRIDE':
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
      time: json['time'] as String,
      entryType: json['entry_type'] as String,
      entryTypeDisplay: json['entry_type_display'] as String,
      quantity: json['quantity'] as int,
      company: json['company'] as String,
      journalNumber: json['journal_number'] as String?,
      notes: json['notes'] as String?,
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
      ];
}

/// Color indicator for different entry types
enum EntryTypeColor {
  positive,  // Green - adds to quota
  negative,  // Red - subtracts from quota
  neutral,   // Gray - informational
}
