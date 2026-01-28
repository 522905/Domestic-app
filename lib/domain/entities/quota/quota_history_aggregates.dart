import 'package:equatable/equatable.dart';

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
  final DateTime dateFrom;
  final DateTime dateTo;

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
    required this.dateFrom,
    required this.dateTo,
  });

  /// Overall posting ratio: (total SDMS sales / total net pickups) * 100
  double? get overallPostingRatio {
    final netPickups = totalPickups - totalReturns;
    if (netPickups <= 0) return null;
    return (totalSdmsSales / netPickups) * 100;
  }

  /// Total confirmed sales (OTP + Override)
  int get totalConfirmedSales => totalOtpSales + totalOverrideSales;

  /// Net pickups across all entries
  int get totalNetPickups => totalPickups - totalReturns;

  factory QuotaHistoryAggregates.fromJson(Map<String, dynamic> json) {
    final dateRange = json['date_range'] as Map<String, dynamic>;
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
      dateFrom: DateTime.parse(dateRange['from'] as String),
      dateTo: DateTime.parse(dateRange['to'] as String),
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
      'date_range': {
        'from': dateFrom.toIso8601String().split('T')[0],
        'to': dateTo.toIso8601String().split('T')[0],
      },
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
        dateFrom,
        dateTo,
      ];
}
