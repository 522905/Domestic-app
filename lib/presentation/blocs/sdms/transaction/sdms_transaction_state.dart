// lib/presentation/blocs/sdms/sdms_transaction_state.dart
import 'package:equatable/equatable.dart';

import '../../../../data/models/sdms/sdms_transaction.dart';

abstract class SDMSTransactionState extends Equatable {
  const SDMSTransactionState();

  @override
  List<Object?> get props => [];
}

class SDMSTransactionInitial extends SDMSTransactionState {}

class SDMSTransactionLoading extends SDMSTransactionState {}

class SDMSTransactionLoaded extends SDMSTransactionState {
  final List<SDMSTransaction> transactions;
  final String? statusFilter;
  final String? actionTypeFilter;
  final String? fromDateFilter;
  final String? toDateFilter;

  const SDMSTransactionLoaded({
    required this.transactions,
    this.statusFilter,
    this.actionTypeFilter,
    this.fromDateFilter,
    this.toDateFilter,
  });

  @override
  List<Object?> get props => [
    transactions,
    statusFilter,
    actionTypeFilter,
    fromDateFilter,
    toDateFilter,
  ];
}

class SDMSTransactionDetailLoaded extends SDMSTransactionState {
  final SDMSTransaction transaction;

  const SDMSTransactionDetailLoaded({required this.transaction});

  @override
  List<Object> get props => [transaction];
}

class SDMSTransactionError extends SDMSTransactionState {
  final String message;

  const SDMSTransactionError({required this.message});

  @override
  List<Object> get props => [message];
}

