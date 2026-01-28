import 'package:equatable/equatable.dart';
import '../../../domain/entities/quota/quota_history_entry.dart';
import '../../../domain/entities/quota/quota_history_aggregates.dart';
import '../../../domain/entities/quota/quota_history_filters.dart';

/// Base class for all quota history states
abstract class QuotaHistoryState extends Equatable {
  const QuotaHistoryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class QuotaHistoryInitial extends QuotaHistoryState {
  const QuotaHistoryInitial();
}

/// State while loading initial data
class QuotaHistoryLoading extends QuotaHistoryState {
  const QuotaHistoryLoading();
}

/// State with successfully loaded history data
class QuotaHistoryLoaded extends QuotaHistoryState {
  final List<QuotaHistoryEntry> allEntries;
  final QuotaHistoryAggregates aggregates;
  final QuotaHistoryFilters filters;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMorePages;

  const QuotaHistoryLoaded({
    required this.allEntries,
    required this.aggregates,
    required this.filters,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.hasMorePages = false,
  });

  /// Creates a copy with updated fields
  QuotaHistoryLoaded copyWith({
    List<QuotaHistoryEntry>? allEntries,
    QuotaHistoryAggregates? aggregates,
    QuotaHistoryFilters? filters,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMorePages,
  }) {
    return QuotaHistoryLoaded(
      allEntries: allEntries ?? this.allEntries,
      aggregates: aggregates ?? this.aggregates,
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }

  @override
  List<Object?> get props => [
        allEntries,
        aggregates,
        filters,
        isLoadingMore,
        currentPage,
        hasMorePages,
      ];
}

/// State when an error occurs
class QuotaHistoryError extends QuotaHistoryState {
  final String message;
  final QuotaHistoryFilters? filters;

  const QuotaHistoryError({
    required this.message,
    this.filters,
  });

  @override
  List<Object?> get props => [message, filters];
}
