import 'package:equatable/equatable.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';

abstract class ObligationCollectionState extends Equatable {
  const ObligationCollectionState();

  @override
  List<Object?> get props => [];
}

class ObligationCollectionInitial extends ObligationCollectionState {}

class ObligationCollectionLoading extends ObligationCollectionState {}

class ObligationCollectionLoaded extends ObligationCollectionState {
  final List<OfflineDeliveryToken> tokens;
  final DateTime selectedDate;
  final int companyId;

  const ObligationCollectionLoaded({
    required this.tokens,
    required this.selectedDate,
    required this.companyId,
  });

  @override
  List<Object?> get props => [tokens, selectedDate, companyId];
}

class EmptiesCollecting extends ObligationCollectionState {}

class EmptiesCollected extends ObligationCollectionState {
  final OfflineDeliveryToken token;
  const EmptiesCollected(this.token);

  @override
  List<Object> get props => [token];
}

class CashCollecting extends ObligationCollectionState {}

class CashCollected extends ObligationCollectionState {
  final OfflineDeliveryToken token;
  const CashCollected(this.token);

  @override
  List<Object> get props => [token];
}

class ObligationCollectionError extends ObligationCollectionState {
  final String message;
  const ObligationCollectionError(this.message);

  @override
  List<Object> get props => [message];
}
