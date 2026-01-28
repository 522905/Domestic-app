import 'package:equatable/equatable.dart';
import '../../../domain/entities/bonus/bonus.dart';

/// Base class for all bonus detail states
abstract class BonusDetailState extends Equatable {
  const BonusDetailState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class BonusDetailInitial extends BonusDetailState {
  const BonusDetailInitial();
}

/// State while loading bonus detail
class BonusDetailLoading extends BonusDetailState {
  const BonusDetailLoading();
}

/// State with successfully loaded bonus detail
class BonusDetailLoaded extends BonusDetailState {
  final Bonus bonus;

  const BonusDetailLoaded(this.bonus);

  @override
  List<Object?> get props => [bonus];
}

/// State when an error occurs
class BonusDetailError extends BonusDetailState {
  final String message;

  const BonusDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
