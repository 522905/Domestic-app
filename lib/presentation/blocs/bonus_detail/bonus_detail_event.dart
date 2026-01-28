import 'package:equatable/equatable.dart';

/// Base class for all bonus detail events
abstract class BonusDetailEvent extends Equatable {
  const BonusDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load bonus detail
class LoadBonusDetail extends BonusDetailEvent {
  final int bonusId;

  const LoadBonusDetail(this.bonusId);

  @override
  List<Object?> get props => [bonusId];
}

/// Event to refresh bonus detail
class RefreshBonusDetail extends BonusDetailEvent {
  final int bonusId;

  const RefreshBonusDetail(this.bonusId);

  @override
  List<Object?> get props => [bonusId];
}
