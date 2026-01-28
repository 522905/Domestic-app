import 'package:equatable/equatable.dart';
import '../../../domain/entities/quota/quota_history_filters.dart';

/// Base class for all quota history events
abstract class QuotaHistoryEvent extends Equatable {
  const QuotaHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial quota history data
class LoadQuotaHistory extends QuotaHistoryEvent {
  final bool refresh;

  const LoadQuotaHistory({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Event to load more history entries (pagination)
class LoadMoreHistory extends QuotaHistoryEvent {
  const LoadMoreHistory();
}

/// Event to update filters and reload data
class UpdateHistoryFilters extends QuotaHistoryEvent {
  final QuotaHistoryFilters filters;

  const UpdateHistoryFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

/// Event to update sort order
class UpdateHistorySort extends QuotaHistoryEvent {
  final String sort;

  const UpdateHistorySort(this.sort);

  @override
  List<Object?> get props => [sort];
}

/// Event to load detail for a specific entry
class LoadHistoryDetail extends QuotaHistoryEvent {
  final DateTime entryDate;
  final String itemCode;

  const LoadHistoryDetail({
    required this.entryDate,
    required this.itemCode,
  });

  @override
  List<Object?> get props => [entryDate, itemCode];
}
