import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_data.dart';
import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/forms/cash_deposit_page.dart';

// Events
abstract class CashEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Add this to your CashEvent class
class SearchCashRequest extends CashEvent {
  final String query;

  SearchCashRequest({required this.query});

  @override
  List<Object?> get props => [query];
}

class LoadCashData extends CashEvent {}

class AddTransaction extends CashEvent {
  final CashTransaction transaction;

  AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
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


// States
abstract class CashManagementState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CashManagementInitial extends CashManagementState {}

class CashManagementLoading extends CashManagementState {}

class CashManagementLoaded extends CashManagementState {
  final CashData cashData;
  final List<CashTransaction> filteredTransactions;

  CashManagementLoaded({
    required this.cashData,
    required this.filteredTransactions,
  });

  @override
  List<Object?> get props => [cashData, filteredTransactions];

  CashManagementLoaded copyWith({
    CashData? cashData,
    List<CashTransaction>? filteredTransactions,
  }) {
    return CashManagementLoaded(
      cashData: cashData ?? this.cashData,
      filteredTransactions: filteredTransactions ?? this.filteredTransactions,
    );
  }
}

class CashManagementError extends CashManagementState {
  final String message;

  CashManagementError(this.message);

  @override
  List<Object?> get props => [message];
}
// Bloc
class CashManagementBloc extends Bloc<CashEvent, CashManagementState> {

  final ApiServiceInterface apiService;
  List<CashTransaction> _allTransactions = [];

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  CashManagementBloc({required this.apiService}) : super(CashManagementInitial()) {
    on<LoadCashData>(_onLoadCashData);
    on<RefreshCashData>(_onRefreshCashData);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<SearchCashRequest>(_onSearchCashRequest);

  }

   Future<void> _onLoadCashData(LoadCashData event, Emitter<CashManagementState> emit) async {
  emit(CashManagementLoading());
      try {
        final transactionsData = await apiService.getCashTransactions();

        // Map transactionsData to CashTransaction objects
        final transactions = transactionsData.map<CashTransaction>((data) {
          return CashTransaction(
            id: data['id']?.toString() ?? '',
           type: TransactionType.values.firstWhere(
              (transactionType) => transactionType.name == data['type'],
              orElse: () {
                switch (data['type']) {
                  case 'handover':
                  case 'deposit':
                    return TransactionType.deposit;
                  default:
                    return TransactionType.deposit; // Default fallback
                }
              },
            ),
            paymentType: data['payment_type'] ?? '',
            paymentEntryNumber: data['payment_entry_number'] ?? '',
            paidTo: data['paid_to'] ?? '',
            accountType: TransactionAccountType.values.firstWhere(
              (type) => type.name == data['account_type'],
              orElse: () => TransactionAccountType.svTv,
            ),

            modeOfPayment: data['mode_of_payment'] ?? '',
            amount: _toDouble(data['amount'] ?? 0.0),
            status: TransactionStatus.values.firstWhere(
              (status) => status.name == data['status'],
              orElse: () => TransactionStatus.pending, // Provide default value
            ),
            createdAt: DateTime.tryParse(data['created_at'] ?? DateTime.now().toString()) ?? DateTime.now(), // Handle null timestamp
            selectedAccount: data['paid_to'] ?? '',
            initiator: '',
            rejectionReason: data['rejection_reason'] ?? '',
            approved: data['approved'] ?? '',
            rejected: data['rejected'] ?? '',
            approvedBy: data['approved_by'] ?? '',
            rejectedBy: data['rejected_by'] ?? '',
            notes: data['notes'] ?? '',
            createdBy: data['created_by'] ?? '',
          );
        }).toList();

        emit(
          CashManagementLoaded(
            cashData: CashData(
              cashInHand: 0.0,
              lastUpdated: DateTime.now(), // Default value
              pendingApprovals: 0,
              todayDeposits: 0.0,
              todayHandovers: 0.0,
              todayRefunds: 0.0,
              customerOverview: [], // Default empty list since `getCashSummary` is removed
            ),
        filteredTransactions: transactions,
        ));
      } catch (e) {
        emit(CashManagementError('Error loading cash data: ${e.toString()}'));
      }
    }

   Future<void> _onRefreshCashData(RefreshCashData event, Emitter<CashManagementState> emit) async {
      if (state is! CashManagementLoaded) {
        add(LoadCashData());
        return;
      }

      try {
        final transactionsData = await apiService.getCashTransactions();

        if (transactionsData.isEmpty) {
          emit(CashManagementError('No transactions found'));
          return;
        }

        // Map transactionsData to CashTransaction objects
        final transactions = transactionsData.map<CashTransaction>((data) {
          return CashTransaction(
            id: data['id']?.toString() ?? '',
            type: TransactionType.values.firstWhere(
                  (transactionType) => transactionType.name == data['type'],
              orElse: () {
                switch (data['type']) {
                  case 'handover':
                  case 'deposit':
                    return TransactionType.deposit;
                  default:
                    return TransactionType.deposit; // Default fallback
                }
              },
            ),
            paymentType: data['payment_type'] ?? '',
            paymentEntryNumber: data['payment_entry_number'] ?? '',
            paidTo: data['paid_to'] ?? '',
            accountType: TransactionAccountType.values.firstWhere(
                  (type) => type.name == data['account_type'],
              orElse: () => TransactionAccountType.svTv,
            ),

            modeOfPayment: data['mode_of_payment'] ?? '',
            amount: _toDouble(data['amount'] ?? 0.0),
            status: TransactionStatus.values.firstWhere(
                  (status) => status.name == data['status'],
              orElse: () => TransactionStatus.pending, // Provide default value
            ),
            createdAt: DateTime.tryParse(data['created_at'] ?? DateTime.now().toString()) ?? DateTime.now(), // Handle null timestamp
            selectedAccount: data['paid_to'] ?? '',
            initiator: '',
            rejectionReason: data['rejection_reason'] ?? '',
            approved: data['approved'] ?? '',
            rejected: data['rejected'] ?? '',
            approvedBy: data['approved_by'] ?? '',
            rejectedBy: data['rejected_by'] ?? '',
            notes: data['notes'] ?? '',
            createdBy: data['created_by'] ?? '',
          );
        }).toList();

        // Create new CashData object
        final newCashData = CashData(
          cashInHand: 0.0,
          lastUpdated: DateTime.now(),
          pendingApprovals: transactionsData.where((tx) => tx['status'] == 'pending').length,
          todayDeposits: _calculateTodayDeposits(transactionsData),
          todayHandovers: _calculateTodayHandovers(transactionsData),
          todayRefunds: 0.0,
          customerOverview: [],
        );

        if (state is CashManagementLoaded) {
          final currentState = state as CashManagementLoaded;

          if (newCashData != currentState.cashData || transactions != currentState.filteredTransactions) {
            emit(CashManagementLoaded(
              cashData: newCashData,
              filteredTransactions: transactions,
            ));
          } else {
            print("No updates required.");
          }
        }
      } catch (e) {
        print("Refresh error: $e");
        emit(CashManagementError('Failed to refresh data: ${e.toString()}'));
      }
    }

    void _onAddTransaction(AddTransaction event, Emitter<CashManagementState> emit) async {
      if (state is CashManagementLoaded) {
        final currentState = state as CashManagementLoaded;

        try {
          final response = await apiService.createTransaction({
            'type': event.transaction.type.name,
            'account_type': event.transaction.accountType.name,
            'amount': event.transaction.amount,
            'timestamp': event.transaction.createdAt.toIso8601String(),
            'notes': event.transaction.notes,
            'paid_to': event.transaction.selectedAccount,
            'bank_details': event.transaction.selectedBank,
            'mode_of_payment': event.transaction.modeOfPayment,
          });
              // Create a new transaction from the API response
             final newTransaction = CashTransaction(
              id: response['id']?.toString() ?? '', // Convert 'id' to String
              type: TransactionType.values.firstWhere((type) => type.name == response['type']),
              accountType: TransactionAccountType.values.firstWhere((type) => type.name == response['account_type']),
              amount: response['amount'],
              status: TransactionStatus.values.firstWhere((status) => status.name == response['status']),
              createdAt: DateTime.parse(response['timestamp']),
              notes: response['notes'],
              selectedAccount: response['recipient'],
              selectedBank: response['bank_details'],
              initiator: response['initiator'],
              rejectionReason: response['rejection_reason'],
              approved: response['approved'],
              rejected: response['rejected'],
              approvedBy: response['approved_by'],
              rejectedBy: response['rejected_by'],
              createdBy: response['created_by'],
            );

            // Update state with the new transaction
              final updatedTransactions = [newTransaction, ...currentState.filteredTransactions];
              emit(currentState.copyWith(filteredTransactions: updatedTransactions));

              add(RefreshCashData());
        }
          catch (e) {
            print("Error adding transaction via API: $e");
            emit(CashManagementError('Failed to add transaction: ${e.toString()}'));
          }
      }
    }

  Future<void> _onUpdateTransaction(UpdateTransaction event, Emitter<CashManagementState> emit) async {
    if (state is CashManagementLoaded) {
      final currentState = state as CashManagementLoaded;

      try {
        // Find and update the transaction
        final index = currentState.filteredTransactions.indexWhere(
                (tx) => tx.id == event.transaction.id
        );

        if (index != -1) {
          List<CashTransaction> updatedTransactions = List.from(currentState.filteredTransactions);
          updatedTransactions[index] = event.transaction;

          // Update cash data based on status change
          CashData updatedCashData = currentState.cashData.copyWith(
            lastUpdated: DateTime.now(),
            pendingApprovals: event.transaction.status != TransactionStatus.pending &&
                currentState.filteredTransactions[index].status == TransactionStatus.pending
                ? currentState.cashData.pendingApprovals - 1
                : currentState.cashData.pendingApprovals,
          );

          emit(currentState.copyWith(
            cashData: updatedCashData,
            filteredTransactions: updatedTransactions,
          ));
        } else {
          // Transaction not found, keep current state
          emit(currentState);
        }
      } catch (e) {
        // Keep current state
        emit(currentState);
      }
    }
  }

  void _onSearchCashRequest(SearchCashRequest event, Emitter<CashManagementState> emit) {
    if (state is! CashManagementLoaded) return;
    if (_allTransactions.isEmpty) return; // Use stored original data

    final currentState = state as CashManagementLoaded;
    final query = event.query.toLowerCase();

    if (query.isEmpty) {
      // Show all original transactions when search is empty
      emit(currentState.copyWith(filteredTransactions: _allTransactions));
      return;
    }

    // Search within ALL transactions, not filtered ones
    final searchResults = _allTransactions.where((transaction) {
      return transaction.id.toLowerCase().contains(query) ||
          transaction.amount.toString().contains(query) ||
          (transaction.notes?.toLowerCase().contains(query) ?? false) ||
          (transaction.selectedAccount?.toLowerCase().contains(query) ?? false) ||
          (transaction.selectedBank?.toLowerCase().contains(query) ?? false) ||
          transaction.type.name.toLowerCase().contains(query) ||
          transaction.status.name.toLowerCase().contains(query);
    }).toList();

    emit(currentState.copyWith(filteredTransactions: searchResults));
  }
  double _calculateTodayDeposits(List<dynamic> transactions) {
    final today = DateTime.now();
    return transactions
        .where((tx) =>
    tx['type'] == 'deposit' &&
        DateTime.parse(tx['date']).day == today.day &&
        DateTime.parse(tx['date']).month == today.month &&
        DateTime.parse(tx['date']).year == today.year)
        .fold(0.0, (sum, tx) => sum + _toDouble(tx['amount']));
  }

  double _calculateTodayHandovers(List<dynamic> transactions) {
    final today = DateTime.now();
    return transactions
        .where((tx) =>
    tx['type'] == 'handover' &&
        DateTime.parse(tx['date']).day == today.day &&
        DateTime.parse(tx['date']).month == today.month &&
        DateTime.parse(tx['date']).year == today.year)
        .fold(0.0, (sum, tx) => sum + _toDouble(tx['amount']));
  }

  List<CashTransaction> _convertApiTransactions(List<dynamic> transactionsData) {
    return transactionsData.map<CashTransaction>((data) {
      // Map API transaction type to your enum
      TransactionType type = TransactionType.deposit;
      switch (data['type']) {
        case 'deposit':
          type = TransactionType.deposit;
          break;
        case 'handover':
          type = TransactionType.handover;
          break;
        case 'bank':
          type = TransactionType.bank;
          break;
      }

      // Map API status to your enum
      TransactionStatus status = TransactionStatus.pending;
      switch (data['status']) {
        case 'pending':
          status = TransactionStatus.pending;
          break;
        case 'approved':
        case 'completed':
          status = TransactionStatus.approved;
          break;
        case 'rejected':
          status = TransactionStatus.rejected;
          break;
      }

      // Determine account type from API data
      TransactionAccountType accountType = TransactionAccountType.svTv;
      if (data['account'] == 'Refill Account') {
        accountType = TransactionAccountType.refill;
      }

      return CashTransaction(
        id: data['id'],
        type: type,
        accountType: accountType,
        amount: _toDouble(data['amount']),
        status: status,
        createdAt: DateTime.parse(data['date']),
        initiator: data['type']?.toString().substring(0, 1).toUpperCase() ?? 'U',
        selectedAccount: data['notes']?.contains('handover') ? 'Recipient' : null,
        selectedBank: data['type'] == 'bank' ? data['account'] : null,
      );
    }).toList();

  }

}