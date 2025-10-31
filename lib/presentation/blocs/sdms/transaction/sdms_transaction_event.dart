// lib/presentation/blocs/sdms/sdms_transaction_event.dart
import 'package:equatable/equatable.dart';

abstract class SDMSTransactionEvent extends Equatable {
  const SDMSTransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends SDMSTransactionEvent {}

class RefreshTransactionsEvent extends SDMSTransactionEvent {}

class FilterTransactionsEvent extends SDMSTransactionEvent {
  final String? status;
  final String? actionType;
  final String? fromDate;
  final String? toDate;

  const FilterTransactionsEvent({
    this.status,
    this.actionType,
    this.fromDate,
    this.toDate,
  });

  @override
  List<Object?> get props => [status, actionType, fromDate, toDate];
}

class LoadTransactionDetailEvent extends SDMSTransactionEvent {
  final String transactionId;

  const LoadTransactionDetailEvent({required this.transactionId});

  @override
  List<Object> get props => [transactionId];
}

