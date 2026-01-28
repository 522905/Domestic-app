import 'package:equatable/equatable.dart';
import '../../../domain/entities/bonus/bonus_filters.dart';

/// Base class for all bonus list events
abstract class BonusListEvent extends Equatable {
  const BonusListEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load initial bonus list
class LoadBonusList extends BonusListEvent {
  final bool refresh;

  const LoadBonusList({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

/// Event to load more bonuses (pagination)
class LoadMoreBonuses extends BonusListEvent {
  const LoadMoreBonuses();
}

/// Event to update filters and reload data
class UpdateBonusFilters extends BonusListEvent {
  final BonusFilters filters;

  const UpdateBonusFilters(this.filters);

  @override
  List<Object?> get props => [filters];
}

/// Event to update status filter
class UpdateBonusStatus extends BonusListEvent {
  final String status;

  const UpdateBonusStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Event to refresh bonus list
class RefreshBonusList extends BonusListEvent {
  const RefreshBonusList();
}
