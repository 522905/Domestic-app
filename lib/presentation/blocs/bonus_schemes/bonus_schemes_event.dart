import 'package:equatable/equatable.dart';

/// Base class for all bonus schemes events
abstract class BonusSchemesEvent extends Equatable {
  const BonusSchemesEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load bonus schemes
class LoadBonusSchemes extends BonusSchemesEvent {
  final bool includeInactive;

  const LoadBonusSchemes({this.includeInactive = false});

  @override
  List<Object?> get props => [includeInactive];
}

/// Event to refresh bonus schemes
class RefreshBonusSchemes extends BonusSchemesEvent {
  const RefreshBonusSchemes();
}
