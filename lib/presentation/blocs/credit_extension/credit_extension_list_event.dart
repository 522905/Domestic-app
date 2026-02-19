import 'package:equatable/equatable.dart';

abstract class CreditExtensionListEvent extends Equatable {
  const CreditExtensionListEvent();

  @override
  List<Object?> get props => [];
}

class LoadCreditExtensions extends CreditExtensionListEvent {
  final String? status;
  final int page;

  const LoadCreditExtensions({this.status, this.page = 1});

  @override
  List<Object?> get props => [status, page];
}

class RefreshCreditExtensions extends CreditExtensionListEvent {
  final String? status;

  const RefreshCreditExtensions({this.status});

  @override
  List<Object?> get props => [status];
}

class FilterByStatus extends CreditExtensionListEvent {
  final String? status;

  const FilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class LoadMoreCreditExtensions extends CreditExtensionListEvent {
  const LoadMoreCreditExtensions();
}
