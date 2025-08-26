import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_data.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';

abstract class CashEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchCashRequest extends CashEvent {
  final String query;

  SearchCashRequest({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadCashData extends CashEvent {}

class LoadTransactionDetails extends CashEvent {
  final String transactionId;

  LoadTransactionDetails({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class AddTransaction extends CashEvent {
  final CashTransaction transaction;
  final Completer<void> completer;

  AddTransaction(this.transaction, {required this.completer});

  @override
  List<Object?> get props => [transaction, completer];
}

class ApproveTransaction extends CashEvent {
  final String transactionId;

  ApproveTransaction({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class RejectTransaction extends CashEvent {
  final String transactionId;
  final String reason;
  final String? comment;

  RejectTransaction({
    required this.transactionId,
    required this.reason,
    this.comment,
  });

  @override
  List<Object?> get props => [transactionId, reason, comment];
}

class UpdateTransaction extends CashEvent {
  final CashTransaction transaction;

  UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class FilterTransactions extends CashEvent {
  final String? status;
  final String? type;
  final DateTime? fromDate;
  final DateTime? toDate;

  FilterTransactions({this.status, this.type, this.fromDate, this.toDate});

  @override
  List<Object?> get props => [status, type, fromDate, toDate];
}

class RefreshCashData extends CashEvent {}

abstract class CashManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashManagementInitial extends CashManagementState {}

class CashManagementLoading extends CashManagementState {}

class TransactionDetailsLoading extends CashManagementState {}

class TransactionDetailsLoaded extends CashManagementState {
  final CashTransaction transaction;

  TransactionDetailsLoaded({required this.transaction});

  @override
  List<Object?> get props => [transaction];
}

class TransactionActionLoading extends CashManagementState {
  final String transactionId;
  final String action; // 'approve' or 'reject'

  TransactionActionLoading({required this.transactionId, required this.action});

  @override
  List<Object?> get props => [transactionId, action];
}

class TransactionActionSuccess extends CashManagementState {
  final String message;
  final String transactionId;
  final String action;

  TransactionActionSuccess({
    required this.message,
    required this.transactionId,
    required this.action,
  });

  @override
  List<Object?> get props => [message, transactionId, action];
}

// Add new state for transaction addition success
class TransactionAddedSuccess extends CashManagementState {
  final String message;
  final CashTransaction transaction;

  TransactionAddedSuccess({
    required this.message,
    required this.transaction,
  });

  @override
  List<Object?> get props => [message, transaction];
}

class CashManagementLoaded extends CashManagementState {
  final CashData cashData;
  final List<CashTransaction> allTransactions; // All transactions
  final List<CashTransaction> filteredTransactions; // Filtered/searched transactions
  final String searchQuery; // Current search query

  CashManagementLoaded({
    required this.cashData,
    required this.allTransactions,
    required this.filteredTransactions,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [cashData, allTransactions, filteredTransactions, searchQuery];

  CashManagementLoaded copyWith({
    CashData? cashData,
    List<CashTransaction>? allTransactions,
    List<CashTransaction>? filteredTransactions,
    String? searchQuery,
  }) {
    return CashManagementLoaded(
      cashData: cashData ?? this.cashData,
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CashManagementError extends CashManagementState {
  final String message;
  final String? errorCode;
  final dynamic rawError;

  CashManagementError(this.message, {this.errorCode, this.rawError});

  @override
  List<Object?> get props => [message, errorCode, rawError];
}

class CashManagementBloc extends Bloc<CashEvent, CashManagementState> {
  final ApiServiceInterface apiService;

  CashManagementBloc({required this.apiService}) : super(CashManagementInitial()) {
    on<LoadCashData>(_onLoadCashData);
    on<LoadTransactionDetails>(_onLoadTransactionDetails);
    on<RefreshCashData>(_onRefreshCashData);
    on<AddTransaction>(_onAddTransaction);
    on<ApproveTransaction>(_onApproveTransaction);
    on<RejectTransaction>(_onRejectTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<SearchCashRequest>(_onSearchCashRequest);
  }

  Future<void> _onLoadCashData(LoadCashData event, Emitter<CashManagementState> emit) async {
    emit(CashManagementLoading());
    try {
      // Load transactions
      final transactionsData = await apiService.getCashTransactions();
      final transactions = transactionsData.map<CashTransaction>((data) {
        return CashTransaction.fromJson(data);
      }).toList();

      // Load cash summary data
      final cashSummaryResponse = await apiService.getCashSummary();
      final cashData = _buildCashDataFromResponse(cashSummaryResponse, transactions);

      emit(
        CashManagementLoaded(
          cashData: cashData,
          allTransactions: transactions,
          filteredTransactions: transactions,
        ),
      );
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Error loading cash data: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError(
        'Unexpected error: ${e.toString()}',
        rawError: e,
      ));
    }
  }

  Future<void> _onLoadTransactionDetails(LoadTransactionDetails event, Emitter<CashManagementState> emit) async {
    emit(TransactionDetailsLoading());
    try {
      final transactionData = await apiService.getTransactionDetails(event.transactionId);
      final transaction = CashTransaction.fromJson(transactionData);
      emit(TransactionDetailsLoaded(transaction: transaction));
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Failed to load transaction details: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError(
        'Failed to load transaction details: ${e.toString()}',
        rawError: e,
      ));
    }
  }

  void _onAddTransaction(AddTransaction event, Emitter<CashManagementState> emit) async {
    try {
      Map<String, dynamic> requestData;

      // Build request data based on transaction type
      if (event.transaction.type == TransactionType.deposit) {
        requestData = {
          'type': event.transaction.type.name,
          "payment_type": "DEPOSIT",
          'to_account': event.transaction.selectedAccount,
          'from_account': event.transaction.fromAccount,
          'amount': event.transaction.amount,
          'notes': event.transaction.notes ?? ''
        };
      } else if (event.transaction.type == TransactionType.handover) {
        requestData = {
          "payment_type": "HANDOVER",
          'to_account': event.transaction.selectedAccount,
          'amount': event.transaction.amount,
        };

        if (event.transaction.notes != null && event.transaction.notes!.isNotEmpty) {
          requestData['notes'] = event.transaction.notes;
        }
        if (event.transaction.selectedBank != null && event.transaction.selectedBank!.isNotEmpty) {
          requestData['bank'] = event.transaction.selectedBank;
        }
      } else if (event.transaction.type == TransactionType.bank) {
        requestData = {
          "payment_type": "BANK_DEPOSIT",
          'amount': event.transaction.amount,
          'to_account': event.transaction.selectedBank,
          'bank_reference_no': event.transaction.bankReferenceNo,
        };

        if (event.transaction.notes != null && event.transaction.notes!.isNotEmpty) {
          requestData['notes'] = event.transaction.notes;
        }
        if (event.transaction.receiptImagePath != null) {
          requestData['receipt_image'] = event.transaction.receiptImagePath;
        }
      } else {
        requestData = {
          'type': event.transaction.type.name,
          "payment_type": event.transaction.type.name.toUpperCase(),
          'amount': event.transaction.amount,
          'notes': event.transaction.notes ?? ''
        };
      }

      final response = await apiService.createTransaction(requestData);
      final newTransaction = CashTransaction.fromJson(response);

      // Complete the completer first
      event.completer.complete();

      // Update the current state immediately by adding the new transaction
      if (state is CashManagementLoaded) {
        final currentState = state as CashManagementLoaded;

        // Add new transaction to the beginning of the list
        final updatedAllTransactions = [newTransaction, ...currentState.allTransactions];

        // Apply current search filter to updated list
        List<CashTransaction> updatedFilteredTransactions;
        if (currentState.searchQuery.isNotEmpty) {
          updatedFilteredTransactions = _filterTransactions(updatedAllTransactions, currentState.searchQuery);
        } else {
          updatedFilteredTransactions = updatedAllTransactions;
        }

        // Update cash data with new statistics
        final updatedCashData = _updateCashDataWithNewTransaction(currentState.cashData, newTransaction);

        // Emit the updated state immediately - this will update the UI
        emit(currentState.copyWith(
          cashData: updatedCashData,
          allTransactions: updatedAllTransactions,
          filteredTransactions: updatedFilteredTransactions,
        ));
      } else {
        // If not in loaded state, refresh all data
        add(RefreshCashData());
      }

    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      final error = CashManagementError(
        'Failed to add transaction: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      );

      emit(error);
      event.completer.completeError(error);
    } catch (e) {
      final error = CashManagementError(
        'Failed to add transaction: ${e.toString()}',
        rawError: e,
      );

      emit(error);
      event.completer.completeError(error);
    }
  }

  Future<void> _onApproveTransaction(ApproveTransaction event, Emitter<CashManagementState> emit) async {
    emit(TransactionActionLoading(transactionId: event.transactionId, action: 'approve'));

    try {
      final result = await apiService.approveTransaction(event.transactionId);

      if (result != null && result['success'] == true) {
        emit(TransactionActionSuccess(
          message: result['message'] ?? 'Transaction approved successfully',
          transactionId: event.transactionId,
          action: 'approve',
        ));

        // Refresh the main cash data to update all lists
        add(RefreshCashData());
      } else {
        emit(CashManagementError(
          result?['message'] ?? 'Failed to approve transaction',
          rawError: result,
        ));
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Approval failed: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError(
        'Approval failed: ${e.toString()}',
        rawError: e,
      ));
    }
  }

  Future<void> _onRejectTransaction(RejectTransaction event, Emitter<CashManagementState> emit) async {
    emit(TransactionActionLoading(transactionId: event.transactionId, action: 'reject'));

    try {
      final requestData = {
        'reason': event.reason,
        if (event.comment != null && event.comment!.isNotEmpty) 'comment': event.comment,
      };

      final result = await apiService.rejectTransaction(event.transactionId, requestData);

      if (result != null && result['success'] == true) {
        emit(TransactionActionSuccess(
          message: result['message'] ?? 'Transaction rejected successfully',
          transactionId: event.transactionId,
          action: 'reject',
        ));

        // Refresh the main cash data to update all lists
        add(RefreshCashData());
      } else {
        emit(CashManagementError(
          result?['message'] ?? 'Failed to reject transaction',
          rawError: result,
        ));
      }
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Rejection failed: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError(
        'Rejection failed: ${e.toString()}',
        rawError: e,
      ));
    }
  }

  Future<void> _onRefreshCashData(RefreshCashData event, Emitter<CashManagementState> emit) async {
    try {
      // Preserve current search query if any
      String currentSearchQuery = '';
      if (state is CashManagementLoaded) {
        currentSearchQuery = (state as CashManagementLoaded).searchQuery;
      }

      // Load fresh data from API
      final transactionsData = await apiService.getCashTransactions();
      final transactions = transactionsData.map<CashTransaction>((data) {
        return CashTransaction.fromJson(data);
      }).toList();

      // Load cash summary data
      final cashSummaryResponse = await apiService.getCashSummary();
      final cashData = _buildCashDataFromResponse(cashSummaryResponse, transactions);

      // Apply current search filter if any
      List<CashTransaction> filteredTransactions = transactions;
      if (currentSearchQuery.isNotEmpty) {
        filteredTransactions = _filterTransactions(transactions, currentSearchQuery);
      }

      emit(CashManagementLoaded(
        cashData: cashData,
        allTransactions: transactions,
        filteredTransactions: filteredTransactions,
        searchQuery: currentSearchQuery,
      ));
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Failed to refresh data: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError(
        'Failed to refresh data: ${e.toString()}',
        rawError: e,
      ));
    }
  }

  Future<void> _onUpdateTransaction(UpdateTransaction event, Emitter<CashManagementState> emit) async {
    if (state is CashManagementLoaded) {
      final currentState = state as CashManagementLoaded;

      try {
        // Update in all transactions list
        final updatedAllTransactions = currentState.allTransactions.map((tx) {
          return tx.id == event.transaction.id ? event.transaction : tx;
        }).toList();

        // Apply current search filter to updated list
        List<CashTransaction> updatedFilteredTransactions;
        if (currentState.searchQuery.isNotEmpty) {
          updatedFilteredTransactions = _filterTransactions(updatedAllTransactions, currentState.searchQuery);
        } else {
          updatedFilteredTransactions = updatedAllTransactions;
        }

        // Recalculate cash data with updated transactions
        final pendingCount = updatedAllTransactions
            .where((tx) => tx.status == TransactionStatus.pending)
            .length;

        final updatedCashData = currentState.cashData.copyWith(
          lastUpdated: DateTime.now(),
          pendingApprovals: pendingCount,
          todayDeposits: _calculateTodayDeposits(updatedAllTransactions),
          todayHandovers: _calculateTodayHandovers(updatedAllTransactions),
        );

        emit(currentState.copyWith(
          cashData: updatedCashData,
          allTransactions: updatedAllTransactions,
          filteredTransactions: updatedFilteredTransactions,
        ));

      } catch (e) {
        print('Error updating transaction: $e');
        emit(currentState); // Emit current state on error
      }
    }
  }

  void _onSearchCashRequest(SearchCashRequest event, Emitter<CashManagementState> emit) {
    if (state is! CashManagementLoaded) return;

    final currentState = state as CashManagementLoaded;
    final query = event.query.toLowerCase().trim();

    List<CashTransaction> searchResults;
    if (query.isEmpty) {
      searchResults = currentState.allTransactions;
    } else {
      searchResults = _filterTransactions(currentState.allTransactions, query);
    }

    emit(currentState.copyWith(
      filteredTransactions: searchResults,
      searchQuery: query,
    ));
  }

  // Helper method to extract error messages from DioException
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        // Handle field-specific errors
        if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
          return (data['non_field_errors'] as List).join(', ');
        }

        // Handle general error message
        if (data.containsKey('message')) {
          return data['message'].toString();
        }

        if (data.containsKey('error')) {
          return data['error'].toString();
        }

        // Handle field validation errors
        final fieldErrors = <String>[];
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            fieldErrors.add('$key: ${value.join(', ')}');
          } else if (value is String && value.isNotEmpty) {
            fieldErrors.add('$key: $value');
          }
        });

        if (fieldErrors.isNotEmpty) {
          return fieldErrors.join(', ');
        }
      }

      return data.toString();
    }

    if (e.message != null) {
      return e.message!;
    }

    return 'Network error occurred';
  }

  // Helper method to filter transactions based on search query
  List<CashTransaction> _filterTransactions(List<CashTransaction> transactions, String query) {
    final lowercaseQuery = query.toLowerCase();
    return transactions.where((transaction) {
      return transaction.id.toLowerCase().contains(lowercaseQuery) ||
          transaction.amount.toString().contains(lowercaseQuery) ||
          (transaction.notes?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (transaction.selectedAccount?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (transaction.selectedBank?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (transaction.requestedByName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (transaction.approvedByName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          (transaction.rejectedByName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
          transaction.type.name.toLowerCase().contains(lowercaseQuery) ||
          transaction.status.name.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Build CashData from API response and transactions
  CashData _buildCashDataFromResponse(Map<String, dynamic> response, List<CashTransaction> transactions) {
    final customerOverview = response['customerOverview'] as List<dynamic>? ?? [];
    double cashInHand = 0.0;

    // Extract cash in hand from customer overview if available
    if (customerOverview.isNotEmpty) {
      final firstAccount = customerOverview[0] as Map<String, dynamic>;
      cashInHand = (firstAccount['availableBalance'] as num?)?.toDouble() ?? 0.0;
    }

    return CashData(
      cashInHand: cashInHand,
      lastUpdated: DateTime.now(),
      pendingApprovals: transactions.where((tx) => tx.status == TransactionStatus.pending).length,
      todayDeposits: _calculateTodayDeposits(transactions),
      todayHandovers: _calculateTodayHandovers(transactions),
      todayRefunds: 0.0,
      customerOverview: customerOverview.cast<Map<String, dynamic>>(),
    );
  }

  // Update CashData when a new transaction is added
  CashData _updateCashDataWithNewTransaction(CashData currentCashData, CashTransaction newTransaction) {
    // Recalculate pending approvals count
    int newPendingCount = currentCashData.pendingApprovals;
    if (newTransaction.status == TransactionStatus.pending) {
      newPendingCount += 1;
    }

    // Recalculate today's deposits and handovers
    double newTodayDeposits = currentCashData.todayDeposits;
    double newTodayHandovers = currentCashData.todayHandovers;

    final today = DateTime.now();
    final isToday = newTransaction.createdAt.day == today.day &&
        newTransaction.createdAt.month == today.month &&
        newTransaction.createdAt.year == today.year;

    if (isToday) {
      if (newTransaction.type == TransactionType.deposit) {
        newTodayDeposits += newTransaction.amount;
      } else if (newTransaction.type == TransactionType.handover) {
        newTodayHandovers += newTransaction.amount;
      }
    }

    return currentCashData.copyWith(
      lastUpdated: DateTime.now(),
      pendingApprovals: newPendingCount,
      todayDeposits: newTodayDeposits,
      todayHandovers: newTodayHandovers,
    );
  }

  double _calculateTodayDeposits(List<CashTransaction> transactions) {
    final today = DateTime.now();
    return transactions
        .where((tx) =>
    tx.type == TransactionType.deposit &&
        tx.createdAt.day == today.day &&
        tx.createdAt.month == today.month &&
        tx.createdAt.year == today.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double _calculateTodayHandovers(List<CashTransaction> transactions) {
    final today = DateTime.now();
    return transactions
        .where((tx) =>
    tx.type == TransactionType.handover &&
        tx.createdAt.day == today.day &&
        tx.createdAt.month == today.month &&
        tx.createdAt.year == today.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }
}