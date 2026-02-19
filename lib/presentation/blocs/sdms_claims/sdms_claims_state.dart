import 'package:equatable/equatable.dart';
import '../../../domain/entities/sdms_claims/sdms_order.dart';
import '../../../domain/entities/sdms_claims/claim_transfer.dart';
import '../../../domain/entities/sdms_claims/partner.dart';
import 'sdms_claims_event.dart';

abstract class SdmsClaimsState extends Equatable {
  const SdmsClaimsState();

  @override
  List<Object?> get props => [];
}

class SdmsClaimsInitial extends SdmsClaimsState {}

class SdmsClaimsLoading extends SdmsClaimsState {}

// Draft v3: Updated to support tabs and pagination
// Hot fix 2026-02-12: Added isBeneficiary filter tracking
class OrdersLoaded extends SdmsClaimsState {
  final List<SdmsOrder> orders;
  final OrderTab currentTab;
  final int currentPage;
  final bool hasMorePages;
  final String? searchQuery;
  final bool? isBeneficiary;

  const OrdersLoaded({
    required this.orders,
    this.currentTab = OrderTab.active,
    this.currentPage = 1,
    this.hasMorePages = false,
    this.searchQuery,
    this.isBeneficiary,
  });

  @override
  List<Object?> get props =>
      [orders, currentTab, currentPage, hasMorePages, searchQuery, isBeneficiary];
}

class SdmsClaimsError extends SdmsClaimsState {
  final String message;

  const SdmsClaimsError(this.message);

  @override
  List<Object> get props => [message];
}

// Detail states
class OrderDetailLoading extends SdmsClaimsState {}

class OrderDetailLoaded extends SdmsClaimsState {
  final SdmsOrder order;

  const OrderDetailLoaded(this.order);

  @override
  List<Object> get props => [order];
}

// Create states
class OrderCreating extends SdmsClaimsState {}

class OrderCreated extends SdmsClaimsState {
  final SdmsOrder order;
  final bool created; // true for new order, false for existing
  final String message;

  const OrderCreated({
    required this.order,
    required this.created,
    required this.message,
  });

  @override
  List<Object> get props => [order, created, message];
}

// Claim/Retry states
class OrderActionLoading extends SdmsClaimsState {
  final String orderId;

  const OrderActionLoading(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class OrderActionSuccess extends SdmsClaimsState {
  final String message;
  final SdmsOrder order;

  const OrderActionSuccess({
    required this.message,
    required this.order,
  });

  @override
  List<Object> get props => [message, order];
}

// Transfer states - Draft v3: Updated to use orderId and include order data
class TransferActionLoading extends SdmsClaimsState {
  final String orderId;

  const TransferActionLoading(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class TransferActionSuccess extends SdmsClaimsState {
  final String message;
  final SdmsOrder order; // Draft v3: Include updated order

  const TransferActionSuccess({
    required this.message,
    required this.order,
  });

  @override
  List<Object> get props => [message, order];
}

// Partner search states
class PartnersLoading extends SdmsClaimsState {}

class PartnersLoaded extends SdmsClaimsState {
  final List<Partner> partners;

  const PartnersLoaded(this.partners);

  @override
  List<Object> get props => [partners];
}
