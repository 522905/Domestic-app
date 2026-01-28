import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Represents a single daily quota history entry for a specific item
class QuotaHistoryEntry extends Equatable {
  final int id;
  final DateTime entryDate;
  final String itemCode;
  final String itemName;
  final int pickups;
  final int returns;
  final int otpSales;
  final int overrideSales;
  final int blankSales;
  final int sdmsSales;
  final int bonusConsumed;
  final int netChange;
  final int openingBalance;
  final int closingBalance;
  final double? postingRatio;
  final int adjustment;

  const QuotaHistoryEntry({
    required this.id,
    required this.entryDate,
    required this.itemCode,
    required this.itemName,
    required this.pickups,
    required this.returns,
    required this.otpSales,
    required this.overrideSales,
    required this.blankSales,
    required this.sdmsSales,
    required this.bonusConsumed,
    required this.netChange,
    required this.openingBalance,
    required this.closingBalance,
    this.postingRatio,
    this.adjustment = 0,
  });

  /// Net pickups = pickups - returns
  int get netPickups => pickups - returns;

  /// Confirmed sales = OTP + Override
  int get confirmedSales => otpSales + overrideSales;

  /// Formatted date string (e.g., "Jan 20, 2026")
  String get formattedDate => DateFormat('MMM d, yyyy').format(entryDate);

  /// Short date string (e.g., "20 Jan")
  String get shortDate => DateFormat('d MMM').format(entryDate);

  /// Posting ratio color indicator
  PostingRatioColor get ratioColor {
    if (postingRatio == null) return PostingRatioColor.neutral;
    if (postingRatio! >= 90.0) return PostingRatioColor.good;
    if (postingRatio! >= 80.0) return PostingRatioColor.moderate;
    return PostingRatioColor.poor;
  }

  factory QuotaHistoryEntry.fromJson(Map<String, dynamic> json) {
    final entryDateStr = json['entry_date'] as String;

    // Try both field names: 'adjustments' (plural, per API docs) and 'adjustment' (singular, backup)
    // Check what the API actually returns
    final adjustmentValue = (json['adjustments'] as int?) ?? (json['adjustment'] as int?) ?? 0;

    // Read all balance fields for debugging
    final openingBalance = json['opening_balance'] as int;
    final closingBalance = json['closing_balance'] as int;
    final netChange = json['net_change'] as int;
    final pickups = json['pickups'] as int;
    final returns = json['returns'] as int;
    final otpSales = json['otp_sales'] as int;

    // Always print for 17 Jan entries to debug
    if (entryDateStr.contains('2026-01-17')) {
      print('=== QuotaHistoryEntry DEBUG - Date: $entryDateStr ===');
      print('  JSON has "adjustments"? ${json.containsKey('adjustments')} = ${json['adjustments']}');
      print('  JSON has "adjustment"? ${json.containsKey('adjustment')} = ${json['adjustment']}');
      print('  Final adjustment value: $adjustmentValue');
      print('  Opening: $openingBalance, Closing: $closingBalance, NetChange: $netChange');
      print('  Pickups: $pickups, Returns: $returns, OTP: $otpSales');

      // Verify the balance calculation
      final expectedClosing = openingBalance + netChange;
      print('  Expected Closing (opening + netChange): $expectedClosing');
      print('  Actual Closing from API: $closingBalance');
      print('  Match? ${expectedClosing == closingBalance}');
    }

    return QuotaHistoryEntry(
      id: json['id'] as int,
      entryDate: DateTime.parse(entryDateStr),
      itemCode: json['item_code'] as String,
      itemName: json['item_name'] as String,
      pickups: pickups,
      returns: returns,
      otpSales: otpSales,
      overrideSales: json['override_sales'] as int,
      blankSales: json['blank_sales'] as int,
      sdmsSales: json['sdms_sales'] as int,
      bonusConsumed: json['bonus_consumed'] as int,
      netChange: netChange,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      postingRatio: json['posting_ratio'] != null
          ? (json['posting_ratio'] as num).toDouble()
          : null,
      adjustment: adjustmentValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entry_date': entryDate.toIso8601String(),
      'item_code': itemCode,
      'item_name': itemName,
      'pickups': pickups,
      'returns': returns,
      'otp_sales': otpSales,
      'override_sales': overrideSales,
      'blank_sales': blankSales,
      'sdms_sales': sdmsSales,
      'bonus_consumed': bonusConsumed,
      'net_change': netChange,
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'posting_ratio': postingRatio,
      'adjustments': adjustment, // API uses 'adjustments' (plural)
    };
  }

  @override
  List<Object?> get props => [
        id,
        entryDate,
        itemCode,
        itemName,
        pickups,
        returns,
        otpSales,
        overrideSales,
        blankSales,
        sdmsSales,
        bonusConsumed,
        netChange,
        openingBalance,
        closingBalance,
        postingRatio,
        adjustment,
      ];
}

/// Color indicator for posting ratio performance
enum PostingRatioColor {
  good,      // >= 90% (green)
  moderate,  // 80-89% (yellow)
  poor,      // < 80% (red)
  neutral,   // null or N/A
}
