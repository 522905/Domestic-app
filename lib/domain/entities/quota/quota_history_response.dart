import 'package:equatable/equatable.dart';
import 'quota_history_entry.dart';
import 'quota_history_aggregates.dart';

/// Paginated response from quota history API
class QuotaHistoryResponse extends Equatable {
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final String? next;
  final String? previous;
  final QuotaHistoryAggregates aggregates;
  final List<QuotaHistoryEntry> results;

  const QuotaHistoryResponse({
    required this.count,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    this.next,
    this.previous,
    required this.aggregates,
    required this.results,
  });

  /// Whether there are more pages to load
  bool get hasNextPage => next != null;

  /// Whether there are previous pages
  bool get hasPreviousPage => previous != null;

  /// Is this the first page?
  bool get isFirstPage => page == 1;

  /// Is this the last page?
  bool get isLastPage => page >= totalPages;

  factory QuotaHistoryResponse.fromJson(Map<String, dynamic> json) {
    return QuotaHistoryResponse(
      count: json['count'] as int,
      page: json['page'] as int,
      pageSize: json['page_size'] as int,
      totalPages: json['total_pages'] as int,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      aggregates: QuotaHistoryAggregates.fromJson(
        json['aggregates'] as Map<String, dynamic>,
      ),
      results: (json['results'] as List)
          .map((e) => QuotaHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'page': page,
      'page_size': pageSize,
      'total_pages': totalPages,
      'next': next,
      'previous': previous,
      'aggregates': aggregates.toJson(),
      'results': results.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        count,
        page,
        pageSize,
        totalPages,
        next,
        previous,
        aggregates,
        results,
      ];
}
