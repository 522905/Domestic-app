import 'package:equatable/equatable.dart';
import '../../../domain/entities/digital_credit/digital_credit.dart';
import '../../../domain/entities/digital_credit/claim_transfer.dart';
import '../../../domain/entities/digital_credit/claim_result.dart';

abstract class DigitalCreditState extends Equatable {
  const DigitalCreditState();

  @override
  List<Object?> get props => [];
}

class DigitalCreditInitial extends DigitalCreditState {}

class DigitalCreditLoading extends DigitalCreditState {}

class DigitalCreditLoaded extends DigitalCreditState {
  final List<DigitalCredit> credits;

  const DigitalCreditLoaded(this.credits);

  @override
  List<Object> get props => [credits];
}

class DigitalCreditError extends DigitalCreditState {
  final String message;

  const DigitalCreditError(this.message);

  @override
  List<Object> get props => [message];
}

// Detail states
class CreditDetailLoading extends DigitalCreditState {}

class CreditDetailLoaded extends DigitalCreditState {
  final DigitalCredit credit;

  const CreditDetailLoaded(this.credit);

  @override
  List<Object> get props => [credit];
}

class CreditDetailError extends DigitalCreditState {
  final String message;

  const CreditDetailError(this.message);

  @override
  List<Object> get props => [message];
}

// Create states
class CreditCreating extends DigitalCreditState {}

class CreditCreated extends DigitalCreditState {
  final DigitalCredit credit;
  final String message;

  const CreditCreated(this.credit, this.message);

  @override
  List<Object> get props => [credit, message];
}

// Claim states
class CreditClaiming extends DigitalCreditState {}

class CreditClaimSuccess extends DigitalCreditState {
  final ClaimResult result;

  const CreditClaimSuccess(this.result);

  @override
  List<Object> get props => [result];
}

// Transfer states
class TransfersLoading extends DigitalCreditState {}

class TransfersLoaded extends DigitalCreditState {
  final List<ClaimTransfer> transfers;

  const TransfersLoaded(this.transfers);

  @override
  List<Object> get props => [transfers];
}

class TransferActionLoading extends DigitalCreditState {
  final String transferId;

  const TransferActionLoading(this.transferId);

  @override
  List<Object> get props => [transferId];
}

class TransferActionSuccess extends DigitalCreditState {
  final String message;

  const TransferActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

// Company mismatch state
class CompanyMismatchError extends DigitalCreditState {
  final String message;
  final String orderId;
  final String orderDate;
  final Map<String, dynamic> currentCompany;
  final List<Map<String, dynamic>> orderFoundIn;

  const CompanyMismatchError({
    required this.message,
    required this.orderId,
    required this.orderDate,
    required this.currentCompany,
    required this.orderFoundIn,
  });

  @override
  List<Object> get props => [message, orderId, orderDate, currentCompany, orderFoundIn];
}
