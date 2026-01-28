import 'package:equatable/equatable.dart';

/// Filter state for quota history queries
class QuotaHistoryFilters extends Equatable {
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? itemCode;
  final String sort;

  const QuotaHistoryFilters({
    this.dateFrom,
    this.dateTo,
    this.itemCode,
    this.sort = '-entry_date', // Default: newest first
  });

  /// Creates filters for "Last 7 Days" preset
  factory QuotaHistoryFilters.last7Days() {
    final now = DateTime.now();
    return QuotaHistoryFilters(
      dateFrom: now.subtract(const Duration(days: 7)),
      dateTo: now,
    );
  }

  /// Creates filters for "Last 30 Days" preset
  factory QuotaHistoryFilters.last30Days() {
    final now = DateTime.now();
    return QuotaHistoryFilters(
      dateFrom: now.subtract(const Duration(days: 30)),
      dateTo: now,
    );
  }

  /// Creates filters for "This Month" preset
  factory QuotaHistoryFilters.thisMonth() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    return QuotaHistoryFilters(
      dateFrom: firstDay,
      dateTo: now,
    );
  }

  /// Creates filters for "Last Month" preset
  factory QuotaHistoryFilters.lastMonth() {
    final now = DateTime.now();
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);
    final lastDayLastMonth = DateTime(now.year, now.month, 0);
    return QuotaHistoryFilters(
      dateFrom: firstDayLastMonth,
      dateTo: lastDayLastMonth,
    );
  }

  /// Creates a copy with updated fields
  QuotaHistoryFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? itemCode,
    String? sort,
  }) {
    return QuotaHistoryFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      itemCode: itemCode ?? this.itemCode,
      sort: sort ?? this.sort,
    );
  }

  /// Whether any filters are active
  bool get hasActiveFilters =>
      dateFrom != null || dateTo != null || itemCode != null;

  /// Human-readable filter summary
  String get filterSummary {
    if (!hasActiveFilters) return 'All history';

    final parts = <String>[];
    if (dateFrom != null || dateTo != null) {
      if (dateFrom != null && dateTo != null) {
        parts.add('${_formatDate(dateFrom!)} - ${_formatDate(dateTo!)}');
      } else if (dateFrom != null) {
        parts.add('From ${_formatDate(dateFrom!)}');
      } else if (dateTo != null) {
        parts.add('Until ${_formatDate(dateTo!)}');
      }
    }
    if (itemCode != null) {
      parts.add('Item: $itemCode');
    }
    return parts.join(', ');
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  List<Object?> get props => [dateFrom, dateTo, itemCode, sort];
}
