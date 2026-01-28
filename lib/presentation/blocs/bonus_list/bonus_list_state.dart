import 'package:equatable/equatable.dart';
import '../../../domain/entities/bonus/bonus.dart';
import '../../../domain/entities/bonus/bonus_summary.dart';
import '../../../domain/entities/bonus/bonus_filters.dart';

/// Base class for all bonus list states
abstract class BonusListState extends Equatable {
  const BonusListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class BonusListInitial extends BonusListState {
  const BonusListInitial();
}

/// State while loading initial data
class BonusListLoading extends BonusListState {
  const BonusListLoading();
}

/// State with successfully loaded bonus data
class BonusListLoaded extends BonusListState {
  final List<Bonus> allBonuses;
  final BonusSummary summary;
  final BonusFilters filters;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasMorePages;

  const BonusListLoaded({
    required this.allBonuses,
    required this.summary,
    required this.filters,
    this.isLoadingMore = false,
    this.currentPage = 1,
    this.hasMorePages = false,
  });

  /// Creates a copy with updated fields
  BonusListLoaded copyWith({
    List<Bonus>? allBonuses,
    BonusSummary? summary,
    BonusFilters? filters,
    bool? isLoadingMore,
    int? currentPage,
    bool? hasMorePages,
  }) {
    return BonusListLoaded(
      allBonuses: allBonuses ?? this.allBonuses,
      summary: summary ?? this.summary,
      filters: filters ?? this.filters,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasMorePages: hasMorePages ?? this.hasMorePages,
    );
  }

  @override
  List<Object?> get props => [
        allBonuses,
        summary,
        filters,
        isLoadingMore,
        currentPage,
        hasMorePages,
      ];
}

/// State when an error occurs
class BonusListError extends BonusListState {
  final String message;
  final BonusFilters? filters;

  const BonusListError({
    required this.message,
    this.filters,
  });

  @override
  List<Object?> get props => [message, filters];
}
