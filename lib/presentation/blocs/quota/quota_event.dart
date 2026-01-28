import 'package:equatable/equatable.dart';

abstract class QuotaEvent extends Equatable {
  const QuotaEvent();

  @override
  List<Object> get props => [];
}

class LoadQuotaSnapshot extends QuotaEvent {}

class RefreshQuotaSnapshot extends QuotaEvent {}

class TriggerQuotaSync extends QuotaEvent {}
