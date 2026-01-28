import 'package:equatable/equatable.dart';

abstract class DigitalCreditEvent extends Equatable {
  const DigitalCreditEvent();

  @override
  List<Object?> get props => [];
}

// List events
class LoadDigitalCredits extends DigitalCreditEvent {
  const LoadDigitalCredits();
}

class RefreshDigitalCredits extends DigitalCreditEvent {
  const RefreshDigitalCredits();
}

class FilterDigitalCredits extends DigitalCreditEvent {
  final String? dataStatus;
  final String? claimStatus;
  final bool? isMine;

  const FilterDigitalCredits({
    this.dataStatus,
    this.claimStatus,
    this.isMine,
  });

  @override
  List<Object?> get props => [dataStatus, claimStatus, isMine];
}

class SearchDigitalCredits extends DigitalCreditEvent {
  final String query;

  const SearchDigitalCredits(this.query);

  @override
  List<Object> get props => [query];
}

// Detail events
class LoadCreditDetail extends DigitalCreditEvent {
  final String creditId;

  const LoadCreditDetail(this.creditId);

  @override
  List<Object> get props => [creditId];
}

// Create event
class CreateDigitalCredit extends DigitalCreditEvent {
  final String orderId;
  final String orderDate;
  final bool autoClaim;

  const CreateDigitalCredit({
    required this.orderId,
    required this.orderDate,
    this.autoClaim = false,
  });

  @override
  List<Object> get props => [orderId, orderDate, autoClaim];
}

// Claim event
class ClaimCredit extends DigitalCreditEvent {
  final String creditId;

  const ClaimCredit(this.creditId);

  @override
  List<Object> get props => [creditId];
}

// Retry event
class RetryCredit extends DigitalCreditEvent {
  final String creditId;

  const RetryCredit(this.creditId);

  @override
  List<Object> get props => [creditId];
}

// Transfer events
class LoadPendingTransfers extends DigitalCreditEvent {
  const LoadPendingTransfers();
}

class ApproveTransfer extends DigitalCreditEvent {
  final String transferId;

  const ApproveTransfer(this.transferId);

  @override
  List<Object> get props => [transferId];
}

class RejectTransfer extends DigitalCreditEvent {
  final String transferId;
  final String? reason;

  const RejectTransfer(this.transferId, {this.reason});

  @override
  List<Object?> get props => [transferId, reason];
}

// Cache clear
class ClearDigitalCreditCache extends DigitalCreditEvent {
  const ClearDigitalCreditCache();
}
