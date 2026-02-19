import 'package:equatable/equatable.dart';

abstract class GmCreditApprovalsEvent extends Equatable {
  const GmCreditApprovalsEvent();

  @override
  List<Object?> get props => [];
}

class LoadPendingApprovals extends GmCreditApprovalsEvent {
  final int? partnerId;
  final String? itemCode;

  const LoadPendingApprovals({this.partnerId, this.itemCode});

  @override
  List<Object?> get props => [partnerId, itemCode];
}

class RefreshPendingApprovals extends GmCreditApprovalsEvent {
  const RefreshPendingApprovals();
}

class ApproveExtension extends GmCreditApprovalsEvent {
  final int extensionId;
  final int approvedQuantity;
  final DateTime? validUntil;

  const ApproveExtension({
    required this.extensionId,
    required this.approvedQuantity,
    this.validUntil,
  });

  @override
  List<Object?> get props => [extensionId, approvedQuantity, validUntil];
}

class RejectExtension extends GmCreditApprovalsEvent {
  final int extensionId;
  final String rejectionReason;

  const RejectExtension({
    required this.extensionId,
    required this.rejectionReason,
  });

  @override
  List<Object?> get props => [extensionId, rejectionReason];
}

class FilterApprovals extends GmCreditApprovalsEvent {
  final int? partnerId;
  final String? itemCode;

  const FilterApprovals({this.partnerId, this.itemCode});

  @override
  List<Object?> get props => [partnerId, itemCode];
}
