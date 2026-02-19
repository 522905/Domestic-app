import 'package:equatable/equatable.dart';
import '../../../domain/entities/credit_extension/active_extension_summary.dart';

abstract class ActiveExtensionsState extends Equatable {
  const ActiveExtensionsState();

  @override
  List<Object?> get props => [];
}

class ActiveExtensionsInitial extends ActiveExtensionsState {}

class ActiveExtensionsLoading extends ActiveExtensionsState {}

class ActiveExtensionsLoaded extends ActiveExtensionsState {
  final ActiveExtensionSummary summary;

  const ActiveExtensionsLoaded(this.summary);

  @override
  List<Object?> get props => [summary];
}

class ActiveExtensionsError extends ActiveExtensionsState {
  final String message;

  const ActiveExtensionsError(this.message);

  @override
  List<Object?> get props => [message];
}
