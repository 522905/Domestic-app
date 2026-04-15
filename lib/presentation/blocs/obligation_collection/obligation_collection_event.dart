import 'package:equatable/equatable.dart';

abstract class ObligationCollectionEvent extends Equatable {
  const ObligationCollectionEvent();

  @override
  List<Object?> get props => [];
}

class LoadDueCollections extends ObligationCollectionEvent {
  final int companyId;
  final String date;

  const LoadDueCollections({required this.companyId, required this.date});

  @override
  List<Object> get props => [companyId, date];
}

class RefreshCollections extends ObligationCollectionEvent {
  const RefreshCollections();
}

class CollectEmpties extends ObligationCollectionEvent {
  final String tokenId;
  final int count;

  const CollectEmpties({required this.tokenId, required this.count});

  @override
  List<Object> get props => [tokenId, count];
}

class CollectCash extends ObligationCollectionEvent {
  final String tokenId;

  const CollectCash({required this.tokenId});

  @override
  List<Object> get props => [tokenId];
}
