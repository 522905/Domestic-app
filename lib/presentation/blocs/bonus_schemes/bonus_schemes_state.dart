import 'package:equatable/equatable.dart';
import '../../../domain/entities/bonus/bonus_scheme.dart';

/// Base class for all bonus schemes states
abstract class BonusSchemesState extends Equatable {
  const BonusSchemesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class BonusSchemesInitial extends BonusSchemesState {
  const BonusSchemesInitial();
}

/// State while loading schemes
class BonusSchemesLoading extends BonusSchemesState {
  const BonusSchemesLoading();
}

/// State with successfully loaded schemes
class BonusSchemesLoaded extends BonusSchemesState {
  final List<BonusScheme> schemes;

  const BonusSchemesLoaded(this.schemes);

  @override
  List<Object?> get props => [schemes];
}

/// State when an error occurs
class BonusSchemesError extends BonusSchemesState {
  final String message;

  const BonusSchemesError(this.message);

  @override
  List<Object?> get props => [message];
}
