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
  final int tokenDeductions;
  final int tokenCredits;

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
    this.tokenDeductions = 0,
    this.tokenCredits = 0,
  });

  /// Net pickups = pickups - returns
  int get netPickups => pickups - returns;

  /// Confirmed sales = OTP + Override
  int get confirmedSales => otpSales + overrideSales;

  /// Calculate posting ratio for this day
  /// Posting ratio = What % of net pickups were confirmed as OTP sales
  /// Formula: (OTP Sales / Net Pickups) * 100
  /// ALWAYS calculates from daily data (ignores backend value which may be incorrect)
  double? get calculatedPostingRatio {
    // ALWAYS calculate from daily data (backend values are incorrect)
    final netPickupCount = netPickups; // pickups - returns

    // If no pickups, return 0%
    if (netPickupCount <= 0) {
      return 0.0;
    }

    // Calculate ratio using OTP sales (confirmed sales)
    // Based on data: Feb 7 (0 OTP / 20 pickups = 0%), Feb 6 (1 OTP / 19 pickups = 5%)
    final ratio = (otpSales / netPickupCount) * 100;

    // Cap at 100% to avoid display issues
    return ratio > 100 ? 100.0 : ratio;
  }

  /// Formatted date string (e.g., "Jan 20, 2026")
  String get formattedDate => DateFormat('MMM d, yyyy').format(entryDate);

  /// Short date string (e.g., "20 Jan")
  String get shortDate => DateFormat('d MMM').format(entryDate);

  /// Posting ratio color indicator
  PostingRatioColor get ratioColor {
    final ratio = calculatedPostingRatio;
    if (ratio == null) return PostingRatioColor.neutral;
    if (ratio >= 90.0) return PostingRatioColor.good;
    if (ratio >= 80.0) return PostingRatioColor.moderate;
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
      tokenDeductions: (json['token_deductions'] as int?) ?? 0,
      tokenCredits: (json['token_credits'] as int?) ?? 0,
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
      'adjustments': adjustment,
      'token_deductions': tokenDeductions,
      'token_credits': tokenCredits,
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
        tokenDeductions,
        tokenCredits,
      ];
}

/// Color indicator for posting ratio performance
enum PostingRatioColor {
  good,      // >= 90% (green)
  moderate,  // 80-89% (yellow)
  poor,      // < 80% (red)
  neutral,   // null or N/A
}
