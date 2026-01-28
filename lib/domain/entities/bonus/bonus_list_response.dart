import 'package:equatable/equatable.dart';
import 'bonus.dart';
import 'bonus_summary.dart';

class BonusListResponse extends Equatable {
  final BonusSummary summary;
  final int count;
  final int page;
  final int pageSize;
  final int totalPages;
  final String? next;
  final String? previous;
  final List<Bonus> results;

  const BonusListResponse({
    required this.summary,
    required this.count,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    this.next,
    this.previous,
    required this.results,
  });

  // Computed properties
  bool get hasMorePages => next != null;
  bool get hasPreviousPages => previous != null;
  bool get isEmpty => results.isEmpty;

  factory BonusListResponse.fromJson(Map<String, dynamic> json) {
    return BonusListResponse(
      summary: BonusSummary.fromJson(json['summary'] ?? {}),
      count: json['count'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['page_size'] ?? 20,
      totalPages: json['total_pages'] ?? 1,
      next: json['next'],
      previous: json['previous'],
      results: (json['results'] as List?)
              ?.map((bonus) => Bonus.fromJson(bonus))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        summary,
        count,
        page,
        pageSize,
        totalPages,
        next,
        previous,
        results,
      ];
}
