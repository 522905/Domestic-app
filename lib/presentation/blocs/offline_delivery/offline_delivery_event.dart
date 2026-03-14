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
  });

  @override
  List<Object?> get props => [
    distributionPointId, consumerId, consumerNumber,
    orderNumber, dacCode, remark, idempotencyKey, bookingVerificationId,
    creationType, overrideReason, consumerNameManual, companyId,
  ];
}

class DeliverToken extends OfflineDeliveryEvent {
  final String tokenId;
  final double cashCollected;
  final String? dacCode;

  const DeliverToken({
    required this.tokenId,
    required this.cashCollected,
    this.dacCode,
  });

  @override
  List<Object?> get props => [tokenId, cashCollected, dacCode];
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
  final double cashCollected;
  final String? referenceImage1Url;
  final String idempotencyKey;
  final int companyId;

  const QuickDeliver({
    required this.distributionPointId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    this.dacCode,
    required this.cashCollected,
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
  final String distributionPointId;
  final String? consumerId;
  final String? consumerNumber;
  final String? orderNumber;
  final String idempotencyKey;
  final int companyId;

  const CreateVerification({
    required this.distributionPointId,
    this.consumerId,
    this.consumerNumber,
    this.orderNumber,
    required this.idempotencyKey,
    required this.companyId,
  });

  @override
  List<Object?> get props => [
    distributionPointId, consumerId, consumerNumber, orderNumber, idempotencyKey,
    companyId,
  ];
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
