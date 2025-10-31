// lib/presentation/blocs/sdms/sdms_transaction_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../utils/error_handler.dart';
import 'sdms_transaction_event.dart';
import 'sdms_transaction_state.dart';

class SDMSTransactionBloc extends Bloc<SDMSTransactionEvent, SDMSTransactionState> {
  final ApiServiceInterface apiService;

  SDMSTransactionBloc({required this.apiService}) : super(SDMSTransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoadTransactions);
    on<RefreshTransactionsEvent>(_onRefreshTransactions);
    on<FilterTransactionsEvent>(_onFilterTransactions);
    on<LoadTransactionDetailEvent>(_onLoadTransactionDetail);
  }

  Future<void> _onLoadTransactions(
      LoadTransactionsEvent event,
      Emitter<SDMSTransactionState> emit,
      ) async {
    try {
      emit(SDMSTransactionLoading());
      final transactions = await apiService.getSDMSTransactions();
      emit(SDMSTransactionLoaded(transactions: transactions));
    } catch (error) {
      emit(SDMSTransactionError(message: ErrorHandler.handleError(error)));
    }
  }

  Future<void> _onRefreshTransactions(
      RefreshTransactionsEvent event,
      Emitter<SDMSTransactionState> emit,
      ) async {
    try {
      final transactions = await apiService.getSDMSTransactions();

      if (state is SDMSTransactionLoaded) {
        final currentState = state as SDMSTransactionLoaded;
        emit(SDMSTransactionLoaded(
          transactions: transactions,
          statusFilter: currentState.statusFilter,
          actionTypeFilter: currentState.actionTypeFilter,
          fromDateFilter: currentState.fromDateFilter,
          toDateFilter: currentState.toDateFilter,
        ));
      } else {
        emit(SDMSTransactionLoaded(transactions: transactions));
      }
    } catch (error) {
      emit(SDMSTransactionError(message: ErrorHandler.handleError(error)));
    }
  }

  Future<void> _onFilterTransactions(
      FilterTransactionsEvent event,
      Emitter<SDMSTransactionState> emit,
      ) async {
    try {
      emit(SDMSTransactionLoading());
      final transactions = await apiService.getSDMSTransactions(
        status: event.status,
        actionType: event.actionType,
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      emit(SDMSTransactionLoaded(
        transactions: transactions,
        statusFilter: event.status,
        actionTypeFilter: event.actionType,
        fromDateFilter: event.fromDate,
        toDateFilter: event.toDate,
      ));
    } catch (error) {
      emit(SDMSTransactionError(message: ErrorHandler.handleError(error)));
    }
  }

  Future<void> _onLoadTransactionDetail(
      LoadTransactionDetailEvent event,
      Emitter<SDMSTransactionState> emit,
      ) async {
    try {
      emit(SDMSTransactionLoading());
      final transaction = await apiService.getSDMSTransactionDetail(event.transactionId);
      emit(SDMSTransactionDetailLoaded(transaction: transaction));
    } catch (error) {
      emit(SDMSTransactionError(message: ErrorHandler.handleError(error)));
    }
  }
}