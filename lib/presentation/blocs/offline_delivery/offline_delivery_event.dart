import 'package:equatable/equatable.dart';

abstract class OfflineDeliveryEvent extends Equatable {
  const OfflineDeliveryEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialData extends OfflineDeliveryEvent {
  const LoadInitialData();
}

class PollSystemStatus extends OfflineDeliveryEvent {
  const PollSystemStatus();
}

class SelectDistributionPoint extends OfflineDeliveryEvent {
  final String pointId;

  const SelectDistributionPoint(this.pointId);

  @override
  List<Object> get props => [pointId];
}

class LoadTokens extends OfflineDeliveryEvent {
  final String? date;
  const LoadTokens({this.date});

  @override
  List<Object?> get props => [date];
}

class RefreshTokens extends OfflineDeliveryEvent {
  final String? date;
  const RefreshTokens({this.date});

  @override
  List<Object?> get props => [date];
}

class CreateToken extends OfflineDeliveryEvent {
  final String distributionPointId;
  final String? consumerId;
  final String? consumerNumber;
  final String? orderNumber;
  final String? dacCode;
  final String? remark;
  final String idempotencyKey;
  final String? bookingVerificationId;
  final String? creationType;
  final String? overrideReason;
  final String? consumerNameManual;
  final int companyId;
  // Obligation fields
  final String? initiationSource;
  final int? sourceDeliveryRecordId;
  final int? directedById;
  final String? deliveryType;
  final String? itemCode;
  final int? quantity;
  final int? assignedToId;
  final String? emptyArrangement;
  final String? emptiesDueDate;
  final String? cashArrangement;
  final String? cashDueDate;

  const CreateToken({
    required this.distributionPointId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    this.dacCode,
    this.remark,
    required this.idempotencyKey,
    this.bookingVerificationId,
    this.creationType,
    this.overrideReason,
    this.consumerNameManual,
    required this.companyId,
    this.initiationSource,
    this.sourceDeliveryRecordId,
    this.directedById,
    this.deliveryType,
    this.itemCode,
    this.quantity,
    this.assignedToId,
    this.emptyArrangement,
    this.emptiesDueDate,
    this.cashArrangement,
    this.cashDueDate,
  });

  @override
  List<Object?> get props => [
    distributionPointId, consumerId, consumerNumber,
    orderNumber, dacCode, remark, idempotencyKey, bookingVerificationId,
    creationType, overrideReason, consumerNameManual, companyId,
    initiationSource, sourceDeliveryRecordId, directedById,
    deliveryType, itemCode, quantity, assignedToId,
    emptyArrangement, emptiesDueDate, cashArrangement, cashDueDate,
  ];
}

class DeliverToken extends OfflineDeliveryEvent {
  final String tokenId;
  final double? cashCollected;
  final String? dacCode;
  final int? emptiesCollected;

  const DeliverToken({
    required this.tokenId,
    this.cashCollected,
    this.dacCode,
    this.emptiesCollected,
  });

  @override
  List<Object?> get props => [tokenId, cashCollected, dacCode, emptiesCollected];
}

class LoadVerifications extends OfflineDeliveryEvent {
  const LoadVerifications();
}

class AttachTokenImages extends OfflineDeliveryEvent {
  final String tokenId;
  final String? referenceImage1Url;
  final String? referenceImage2Url;

  const AttachTokenImages({
    required this.tokenId,
    this.referenceImage1Url,
    this.referenceImage2Url,
  });

  @override
  List<Object?> get props => [tokenId, referenceImage1Url, referenceImage2Url];
}

class CorrectToken extends OfflineDeliveryEvent {
  final String tokenId;
  final String? consumerId;
  final String? consumerNumber;
  final String? orderNumber;
  final String? dacCode;

  const CorrectToken({
    required this.tokenId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    this.dacCode,
  });

  @override
  List<Object?> get props => [tokenId, consumerId, consumerNumber, orderNumber, dacCode];
}

class QuickDeliver extends OfflineDeliveryEvent {
  final String distributionPointId;
  final String? consumerId;
  final String? consumerNumber;
  final String? orderNumber;
  final String? dacCode;
  final double? cashCollected;
  final String? referenceImage1Url;
  final String idempotencyKey;
  final int companyId;

  const QuickDeliver({
    required this.distributionPointId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    this.dacCode,
    this.cashCollected,
    this.referenceImage1Url,
    required this.idempotencyKey,
    required this.companyId,
  });

  @override
  List<Object?> get props => [
    distributionPointId, consumerId, consumerNumber,
    orderNumber, dacCode, cashCollected, referenceImage1Url, idempotencyKey,
    companyId,
  ];
}

class CreateVerification extends OfflineDeliveryEvent {
  final String? distributionPointId;
  final String? consumerId;
  final String? consumerNumber;
  final String? orderNumber;
  final String? dacCode;
  final String idempotencyKey;
  final int companyId;

  const CreateVerification({
    this.distributionPointId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    this.dacCode,
    required this.idempotencyKey,
    required this.companyId,
  });

  @override
  List<Object?> get props => [
    distributionPointId, consumerId, consumerNumber, orderNumber, dacCode, idempotencyKey,
    companyId,
  ];
}

class ToggleShowAllVerifications extends OfflineDeliveryEvent {
  final bool showAll;
  const ToggleShowAllVerifications(this.showAll);

  @override
  List<Object> get props => [showAll];
}

class RetryVerification extends OfflineDeliveryEvent {
  final String verificationId;

  const RetryVerification({required this.verificationId});

  @override
  List<Object> get props => [verificationId];
}

class PollVerifications extends OfflineDeliveryEvent {
  const PollVerifications();
}

class HandleSilentPush extends OfflineDeliveryEvent {
  final String action;
  final String resource;
  final String? resourceId;

  const HandleSilentPush({
    required this.action,
    required this.resource,
    this.resourceId,
  });

  @override
  List<Object?> get props => [action, resource, resourceId];
}

class SelectDate extends OfflineDeliveryEvent {
  final DateTime date;

  const SelectDate(this.date);

  @override
  List<Object> get props => [date];
}

class LoadMoreTokens extends OfflineDeliveryEvent {
  const LoadMoreTokens();
}

class LoadMoreVerifications extends OfflineDeliveryEvent {
  const LoadMoreVerifications();
}

class SearchTokens extends OfflineDeliveryEvent {
  final String query;
  const SearchTokens(this.query);

  @override
  List<Object> get props => [query];
}

class SearchVerifications extends OfflineDeliveryEvent {
  final String query;
  const SearchVerifications(this.query);

  @override
  List<Object> get props => [query];
}

class LoadObligationDirectors extends OfflineDeliveryEvent {
  final int companyId;
  const LoadObligationDirectors(this.companyId);

  @override
  List<Object> get props => [companyId];
}

class LookupConsumer extends OfflineDeliveryEvent {
  final String consumerNumber;
  const LookupConsumer(this.consumerNumber);

  @override
  List<Object> get props => [consumerNumber];
}

class ScanToken extends OfflineDeliveryEvent {
  final String? uuid;
  final int? tokenNumber;
  final String? distributionPointId;

  const ScanToken({this.uuid, this.tokenNumber, this.distributionPointId});

  @override
  List<Object?> get props => [uuid, tokenNumber, distributionPointId];
}

class LoadPartnerTokens extends OfflineDeliveryEvent {
  final int companyId;
  final String? status;

  const LoadPartnerTokens({required this.companyId, this.status});

  @override
  List<Object?> get props => [companyId, status];
}
