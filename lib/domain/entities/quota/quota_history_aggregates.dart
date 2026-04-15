import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Aggregated totals across filtered quota history data
class QuotaHistoryAggregates extends Equatable {
  final int totalEntries;
  final int totalPickups;
  final int totalReturns;
  final int totalAdjustments;
  final int totalOtpSales;
  final int totalOverrideSales;
  final int totalBlankSales;
  final int totalSdmsSales;
  final int totalBonusConsumed;
  final int totalNetChange;
  final int totalTokenDeductions;
  final int totalTokenCredits;
  final DateTime dateFrom;
  final DateTime dateTo;
  final double? backendPostingRatio;

  const QuotaHistoryAggregates({
    required this.totalEntries,
    required this.totalPickups,
    required this.totalReturns,
    required this.totalAdjustments,
    required this.totalOtpSales,
    required this.totalOverrideSales,
    required this.totalBlankSales,
    required this.totalSdmsSales,
    required this.totalBonusConsumed,
    required this.totalNetChange,
    this.totalTokenDeductions = 0,
    this.totalTokenCredits = 0,
    required this.dateFrom,
    required this.dateTo,
    this.backendPostingRatio,
  });

  /// Overall posting ratio: ALWAYS calculate from aggregated data
  /// Formula: (Total OTP Sales / Total Net Pickups) * 100
  double? get overallPostingRatio {
    // ALWAYS calculate from aggregated data (backend values are incorrect)
    final netPickups = totalPickups - totalReturns;

    if (netPickups <= 0) {
      return 0.0;
    }

    // Calculate ratio using OTP sales (confirmed sales)
    final ratio = (totalOtpSales / netPickups) * 100;

    // Cap at 100%
    return ratio > 100 ? 100.0 : ratio;
  }

  /// Total confirmed sales (OTP + Override)
  int get totalConfirmedSales => totalOtpSales + totalOverrideSales;

  /// Net pickups across all entries
  int get totalNetPickups => totalPickups - totalReturns;

  factory QuotaHistoryAggregates.fromJson(Map<String, dynamic> json) {
    final dateRange = json['date_range'] as Map<String, dynamic>;

    // Try to get posting ratio from backend (multiple possible field names)
    double? postingRatio;
    if (json['overall_posting_ratio'] != null) {
      postingRatio = (json['overall_posting_ratio'] as num).toDouble();
    } else if (json['posting_ratio'] != null) {
      postingRatio = (json['posting_ratio'] as num).toDouble();
    }

    return QuotaHistoryAggregates(
      totalEntries: json['total_entries'] as int,
      totalPickups: json['total_pickups'] as int,
      totalReturns: json['total_returns'] as int,
      totalAdjustments: json['total_adjustments'] as int? ?? 0,
      totalOtpSales: json['total_otp_sales'] as int,
      totalOverrideSales: json['total_override_sales'] as int,
      totalBlankSales: json['total_blank_sales'] as int,
      totalSdmsSales: json['total_sdms_sales'] as int,
      totalBonusConsumed: json['total_bonus_consumed'] as int,
      totalNetChange: json['total_net_change'] as int,
      totalTokenDeductions: json['total_token_deductions'] as int? ?? 0,
      totalTokenCredits: json['total_token_credits'] as int? ?? 0,
      dateFrom: DateTime.parse(dateRange['from'] as String),
      dateTo: DateTime.parse(dateRange['to'] as String),
      backendPostingRatio: postingRatio,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_entries': totalEntries,
      'total_pickups': totalPickups,
      'total_returns': totalReturns,
      'total_adjustments': totalAdjustments,
      'total_otp_sales': totalOtpSales,
      'total_override_sales': totalOverrideSales,
      'total_blank_sales': totalBlankSales,
      'total_sdms_sales': totalSdmsSales,
      'total_bonus_consumed': totalBonusConsumed,
      'total_net_change': totalNetChange,
      'total_token_deductions': totalTokenDeductions,
      'total_token_credits': totalTokenCredits,
      'date_range': {
        'from': dateFrom.toIso8601String().split('T')[0],
        'to': dateTo.toIso8601String().split('T')[0],
      },
      if (backendPostingRatio != null) 'overall_posting_ratio': backendPostingRatio,
    };
  }

  @override
  List<Object?> get props => [
        totalEntries,
        totalPickups,
        totalReturns,
        totalAdjustments,
        totalOtpSales,
        totalOverrideSales,
        totalBlankSales,
        totalSdmsSales,
        totalBonusConsumed,
        totalNetChange,
        totalTokenDeductions,
        totalTokenCredits,
        dateFrom,
        dateTo,
        backendPostingRatio,
      ];
}
