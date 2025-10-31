import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_data.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
import 'package:intl/intl.dart';
import '../../../core/services/User.dart';
import '../../../domain/entities/cash/partner_balance.dart';

// Events remain the same
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

// States remain mostly the same
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
  final String action;

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
  final List<CashTransaction> allTransactions;
  final List<CashTransaction> filteredTransactions;
  final String searchQuery;
  final DateTime timestamp; // ← Add timestamp to force state change detection

  CashManagementLoaded({
    required this.cashData,
    required this.allTransactions,
    required this.filteredTransactions,
    this.searchQuery = '',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
    cashData,
    _getTransactionIdsHash(allTransactions), // ← Use hash of transaction IDs
    _getTransactionIdsHash(filteredTransactions),
    searchQuery,
    timestamp, // ← Include timestamp in props
  ];

  // Helper method to create a hash of transaction IDs
  // This ensures state change detection even when list length stays the same (pagination)
  String _getTransactionIdsHash(List<CashTransaction> transactions) {
    if (transactions.isEmpty) return 'empty';
    return transactions.map((t) => t.id).take(10).join(','); // Use first 10 IDs
  }

  CashManagementLoaded copyWith({
    CashData? cashData,
    List<CashTransaction>? allTransactions,
    List<CashTransaction>? filteredTransactions,
    String? searchQuery,
    DateTime? timestamp,
  }) {
    return CashManagementLoaded(
      cashData: cashData ?? this.cashData,
      allTransactions: allTransactions ?? this.allTransactions,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
      searchQuery: searchQuery ?? this.searchQuery,
      timestamp: timestamp ?? DateTime.now(), // ← Always create new timestamp
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
    on<RefreshCashData>(_onRefreshCashData);
    on<LoadTransactionDetails>(_onLoadTransactionDetails);
    on<AddTransaction>(_onAddTransaction);
    on<ApproveTransaction>(_onApproveTransaction);
    on<RejectTransaction>(_onRejectTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<SearchCashRequest>(_onSearchCashRequest);
  }

  // ✅ FIXED: Load transaction details handler
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

  // ✅ FIXED: Add transaction handler with proper state management
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
      }
      else if (event.transaction.type == TransactionType.handover) {
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
      }
      else if(event.transaction.type == TransactionType.bank) {
        requestData = {
          "payment_type": "BANK_DEPOSIT",
          "amount": event.transaction.amount,
          "to_account": event.transaction.selectedBank,
          "bank_reference_no": event.transaction.bankReferenceNo,
        };
        // Add remarks if available
        if (event.transaction.notes != null && event.transaction.notes!.isNotEmpty) {
          requestData["remarks"] = event.transaction.notes;
        }

        // Add bank deposit details if applicable
        Map<String, dynamic> bankDepositDetails = {};

        if (event.transaction.createdAt != null) {
          bankDepositDetails["bank_deposit_date"] =
              DateFormat('yyyy-MM-dd').format(event.transaction.createdAt);
        }

        if (event.transaction.receiptImagePath != null &&
            event.transaction.receiptImagePath!.isNotEmpty) {
          bankDepositDetails["bank_deposit_slip_url"] =
              event.transaction.receiptImagePath;
        }

        // Only add the object if it has data
        if (bankDepositDetails.isNotEmpty) {
          requestData["bank_deposit_details"] = bankDepositDetails;
        }
      }
      else {
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

      // ✅ FIXED: Emit success state and let UI handle refresh
      emit(TransactionAddedSuccess(
        message: 'Transaction submitted successfully',
        transaction: newTransaction,
      ));

      // ✅ CRITICAL: Immediately refresh cash data after successful transaction
      add(RefreshCashData());

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

    Future<void> _onApproveTransaction(
        ApproveTransaction event,
        Emitter<CashManagementState> emit,
        ) async {
      emit(TransactionActionLoading(
        transactionId: event.transactionId,
        action: 'approve',
      ));

      try {
        await apiService.approveTransaction(event.transactionId);

        emit(TransactionActionSuccess(
          message: 'Transaction approved successfully',
          transactionId: event.transactionId,
          action: 'approve',
        ));

        // Trigger full refresh after short delay
        await Future.delayed(const Duration(milliseconds: 300));
        add(RefreshCashData());

      } on DioException catch (e) {
        final errorMessage = _extractErrorMessage(e);
        emit(CashManagementError(
          'Failed to approve: $errorMessage',
          errorCode: e.response?.statusCode?.toString(),
          rawError: e.response?.data,
        ));
      } catch (e) {
        emit(CashManagementError('Failed to approve: ${e.toString()}'));
      }
    }

    Future<void> _onRejectTransaction(
        RejectTransaction event,
        Emitter<CashManagementState> emit,
        ) async {
    emit(TransactionActionLoading(
      transactionId: event.transactionId,
      action: 'reject',
    ));

    try {
      await apiService.rejectTransaction(
        event.transactionId,
        {
          'reason': event.reason,
          if (event.comment != null && event.comment!.isNotEmpty)
            'comment': event.comment,
        },
      );

      emit(TransactionActionSuccess(
        message: 'Transaction rejected successfully',
        transactionId: event.transactionId,
        action: 'reject',
      ));

      // Trigger full refresh after short delay
      await Future.delayed(const Duration(milliseconds: 200));
      add(RefreshCashData());

    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      emit(CashManagementError(
        'Failed to reject: $errorMessage',
        errorCode: e.response?.statusCode?.toString(),
        rawError: e.response?.data,
      ));
    } catch (e) {
      emit(CashManagementError('Failed to reject: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshCashData(RefreshCashData event, Emitter<CashManagementState> emit) async {
    try {
      // ✅ CRITICAL FIX: Emit loading state to force UI update detection
      print('🔄 Bloc: Starting refresh...');

      String currentSearchQuery = '';
      if (state is CashManagementLoaded) {
        currentSearchQuery = (state as CashManagementLoaded).searchQuery;
        // Don't emit loading if we already have data (smoother UX)
        // Just the timestamp change in the new state will trigger update
      }

      final roles = await User().getUserRoles();
      final userRoleList = roles.map((role) => role.role).toList();
      final isDeliveryBoy = userRoleList.contains('Delivery Boy');
      final isCashier = userRoleList.contains('Cashier');

      print('🌐 Bloc: Fetching transactions from API...');
      // Load fresh data from API
      final transactionsData = await apiService.getCashTransactions();
      final transactions = transactionsData.map<CashTransaction>((data) {
        return CashTransaction.fromJson(data);
      }).toList();

      print('📊 Bloc: Received ${transactions.length} transactions');

      // ✅ ENHANCED: Sort transactions by creation date (newest first)
      transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      Map<String, dynamic> summaryResponse = {};
      if (isDeliveryBoy) {
        summaryResponse = await apiService.getPartnerAccountBalance();
      }
      if (isCashier) {
        summaryResponse = await apiService.getCashierBalance();
      }

      final cashData = _buildCashDataFromResponse(summaryResponse, transactions, userRoleList);

      // Apply current search filter if any
      List<CashTransaction> filteredTransactions = transactions;
      if (currentSearchQuery.isNotEmpty) {
        filteredTransactions = _filterTransactions(transactions, currentSearchQuery);
      }

      print('✅ Bloc: Emitting new CashManagementLoaded state with ${transactions.length} transactions');
      emit(CashManagementLoaded(
        cashData: cashData,
        allTransactions: transactions,
        filteredTransactions: filteredTransactions,
        searchQuery: currentSearchQuery,
        timestamp: DateTime.now(), // ✅ Force new timestamp
      ));
      print('✅ Bloc: State emitted successfully');
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

  // ✅ IMPROVED: Update transaction handler
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

  // ✅ IMPROVED: Search handler with better performance
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

  // Helper methods remain the same
  String _extractErrorMessage(DioException e) {
    if (e.response?.data != null) {
      final data = e.response!.data;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('non_field_errors') && data['non_field_errors'] is List) {
          return (data['non_field_errors'] as List).join(', ');
        }

        if (data.containsKey('message')) {
          return data['message'].toString();
        }

        if (data.containsKey('error')) {
          return data['error'].toString();
        }

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

  CashData _buildCashDataFromResponse(Map<String, dynamic> response, List<CashTransaction> transactions, List<String> userRoles) {
    final isDeliveryBoy = userRoles.contains('Delivery Boy');
    final isCashier = userRoles.contains('Cashier');

    double cashInHand = 0.0;
    List<PartnerBalance> partners = [];
    int totalPartners = 0;
    List<Map<String, dynamic>> customerOverview = [];
    List<Map<String, dynamic>> cashierAccounts = [];

    if (isDeliveryBoy && response.containsKey('partners')) {
      final partnersData = response['partners'] as List<dynamic>? ?? [];
      partners = partnersData.map((partnerData) => PartnerBalance.fromJson(partnerData)).toList();
      totalPartners = response['total_partners'] as int? ?? partners.length;

      if (partners.isNotEmpty && partners.first.balanceData.isNotEmpty) {
        cashInHand = partners.first.balanceData.first.availableBalance;
      }
    }

    if (isCashier && response.containsKey('accounts')) {
      final accountsData = response['accounts'] as List<dynamic>? ?? [];
      cashierAccounts = accountsData.cast<Map<String, dynamic>>();

      if (cashierAccounts.isNotEmpty) {
        final balanceData = cashierAccounts[0]['balance_data'] as Map<String, dynamic>?;
        if (balanceData != null && balanceData['message'] is Map<String, dynamic>) {
          final message = balanceData['message'] as Map<String, dynamic>;
          if (message.isNotEmpty) {
            cashInHand = (message.values.first as num?)?.toDouble() ?? 0.0;
          }
        }
      }
    }

    return CashData(
      cashInHand: cashInHand,
      lastUpdated: DateTime.now(),
      pendingApprovals: transactions.where((tx) => tx.status == TransactionStatus.pending).length,
      todayDeposits: _calculateTodayDeposits(transactions),
      todayHandovers: _calculateTodayHandovers(transactions),
      todayRefunds: 0.0,
      customerOverview: customerOverview,
      partners: partners,
      totalPartners: totalPartners,
      cashierAccounts: cashierAccounts,
    );
  }

  CashData _updateCashDataWithNewTransaction(CashData currentCashData, CashTransaction newTransaction) {
    int newPendingCount = currentCashData.pendingApprovals;
    if (newTransaction.status == TransactionStatus.pending) {
      newPendingCount += 1;
    }

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