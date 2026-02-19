import 'package:equatable/equatable.dart';

/// Draft v3: Order tab enum
enum OrderTab { active, history }

abstract class SdmsClaimsEvent extends Equatable {
  const SdmsClaimsEvent();

  @override
  List<Object?> get props => [];
}

// List events - Draft v3: Updated to use tab/page/search
// Hot fix 2026-02-12: Added isBeneficiary filter
class LoadSdmsOrders extends SdmsClaimsEvent {
  final OrderTab tab;
  final int page;
  final String? searchQuery;
  final bool? isBeneficiary;

  const LoadSdmsOrders({
    this.tab = OrderTab.active,
    this.page = 1,
    this.searchQuery,
    this.isBeneficiary,
  });

  @override
  List<Object?> get props => [tab, page, searchQuery, isBeneficiary];
}

class RefreshSdmsOrders extends SdmsClaimsEvent {
  const RefreshSdmsOrders();
}

class FilterSdmsOrders extends SdmsClaimsEvent {
  final String? orderCategory;
  final String? dataStatus;
  final String? claimStatus;
  final String? settlementStatus;
  final String? source;
  final bool? isMine;

  const FilterSdmsOrders({
    this.orderCategory,
    this.dataStatus,
    this.claimStatus,
    this.settlementStatus,
    this.source,
    this.isMine,
  });

  @override
  List<Object?> get props => [
        orderCategory,
        dataStatus,
        claimStatus,
        settlementStatus,
        source,
        isMine,
      ];
}

class SearchSdmsOrders extends SdmsClaimsEvent {
  final String query;

  const SearchSdmsOrders(this.query);

  @override
  List<Object> get props => [query];
}

// Detail events
class LoadOrderDetail extends SdmsClaimsEvent {
  final String orderId;

  const LoadOrderDetail(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Silent polling for RPA updates (does NOT emit loading state)
class PollOrderDetail extends SdmsClaimsEvent {
  final String orderId;

  const PollOrderDetail(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Create event
class CreateSdmsOrder extends SdmsClaimsEvent {
  final String orderId;
  final bool claimForSelf;
  final int? intendedPartner;
  final String? consumerNumber;

  const CreateSdmsOrder({
    required this.orderId,
    this.claimForSelf = true,
    this.intendedPartner,
    this.consumerNumber,
  });

  @override
  List<Object?> get props => [orderId, claimForSelf, intendedPartner, consumerNumber];
}

// Claim event
class ClaimOrder extends SdmsClaimsEvent {
  final String orderId;

  const ClaimOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Retry event
class RetryOrder extends SdmsClaimsEvent {
  final String orderId;

  const RetryOrder(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Switch company event (v1.6)
class SwitchOrderCompany extends SdmsClaimsEvent {
  final String orderId;
  final int companyId;

  const SwitchOrderCompany(this.orderId, this.companyId);

  @override
  List<Object> get props => [orderId, companyId];
}

// Transfer events - Draft v3: Use orderId instead of transferId
class ApproveTransfer extends SdmsClaimsEvent {
  final String orderId;

  const ApproveTransfer(this.orderId);

  @override
  List<Object> get props => [orderId];
}

class RejectTransfer extends SdmsClaimsEvent {
  final String orderId;
  final String? reason;

  const RejectTransfer(this.orderId, {this.reason});

  @override
  List<Object?> get props => [orderId, reason];
}

// Partner search
class SearchPartners extends SdmsClaimsEvent {
  final String query;

  const SearchPartners(this.query);

  @override
  List<Object> get props => [query];
}

// Unclaimed Orders Browse
class LoadUnclaimedOrders extends SdmsClaimsEvent {
  const LoadUnclaimedOrders();
}

class RefreshUnclaimedOrders extends SdmsClaimsEvent {
  const RefreshUnclaimedOrders();
}

class SearchUnclaimedOrders extends SdmsClaimsEvent {
  final String query;

  const SearchUnclaimedOrders(this.query);

  @override
  List<Object> get props => [query];
}

class ClaimOrderFromBrowse extends SdmsClaimsEvent {
  final String orderId;

  const ClaimOrderFromBrowse(this.orderId);

  @override
  List<Object> get props => [orderId];
}

// Cache clear
class ClearSdmsClaimsCache extends SdmsClaimsEvent {
  const ClearSdmsClaimsCache();
}
