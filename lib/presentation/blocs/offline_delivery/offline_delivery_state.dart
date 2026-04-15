import 'package:equatable/equatable.dart';
import '../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../../domain/entities/offline_delivery/distribution_point.dart';
import '../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_company.dart';
import '../../../domain/entities/offline_delivery/obligation_director.dart';

abstract class OfflineDeliveryState extends Equatable {
  const OfflineDeliveryState();

  @override
  List<Object?> get props => [];
}

class OfflineDeliveryInitial extends OfflineDeliveryState {}

class OfflineDeliveryLoading extends OfflineDeliveryState {}

class OfflineDeliveryLoaded extends OfflineDeliveryState {
  final OfflineSystemStatus systemStatus;
  final List<DistributionPoint> distributionPoints;
  final DistributionPoint? selectedPoint;
  final List<BookingVerification> verifications;
  final List<OfflineDeliveryToken> tokens;
  final bool isSupervisor;
  final DateTime selectedDate;
  final bool hasMoreTokens;
  final bool hasMoreVerifications;
  final bool isLoadingMoreTokens;
  final bool isLoadingMoreVerifications;

  final String searchQuery;

  final List<OfflineDeliveryCompany> companies;
  final int? lastSelectedCompanyId;

  final bool showAllVerifications;

  final List<ObligationDirector> obligationDirectors;

  OfflineDeliveryLoaded({
    required this.systemStatus,
    required this.distributionPoints,
    this.selectedPoint,
    this.verifications = const [],
    this.tokens = const [],
    this.isSupervisor = false,
    DateTime? selectedDate,
    this.hasMoreTokens = false,
    this.hasMoreVerifications = false,
    this.isLoadingMoreTokens = false,
    this.isLoadingMoreVerifications = false,
    this.searchQuery = '',
    this.companies = const [],
    this.lastSelectedCompanyId,
    this.showAllVerifications = false,
    this.obligationDirectors = const [],
  }) : selectedDate = selectedDate ?? DateTime.now();

  @override
  List<Object?> get props => [
    systemStatus, distributionPoints, selectedPoint,
    verifications, tokens, isSupervisor, selectedDate,
    hasMoreTokens, hasMoreVerifications,
    isLoadingMoreTokens, isLoadingMoreVerifications,
    searchQuery, companies, lastSelectedCompanyId,
    showAllVerifications, obligationDirectors,
  ];
}

class TokenCreating extends OfflineDeliveryState {}

class TokenCreated extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  const TokenCreated(this.token);

  @override
  List<Object> get props => [token];
}

class TokenDelivering extends OfflineDeliveryState {}

class TokenDelivered extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  final String message;
  const TokenDelivered({required this.token, required this.message});

  @override
  List<Object> get props => [token, message];
}

class TokenCorrecting extends OfflineDeliveryState {}

class TokenCorrected extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  const TokenCorrected(this.token);

  @override
  List<Object> get props => [token];
}

class ImagesAttaching extends OfflineDeliveryState {}

class ImagesAttached extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  const ImagesAttached(this.token);

  @override
  List<Object> get props => [token];
}

class QuickDelivering extends OfflineDeliveryState {}

class QuickDelivered extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  final String message;
  const QuickDelivered({required this.token, required this.message});

  @override
  List<Object> get props => [token, message];
}

class VerificationCreating extends OfflineDeliveryState {}

class VerificationCreated extends OfflineDeliveryState {
  final BookingVerification verification;
  const VerificationCreated(this.verification);

  @override
  List<Object> get props => [verification];
}

class ConsumerLookupLoading extends OfflineDeliveryState {}

class ConsumerLookupResult extends OfflineDeliveryState {
  final List<Map<String, dynamic>> records;
  const ConsumerLookupResult(this.records);

  @override
  List<Object> get props => [records];
}

class ConsumerLookupError extends OfflineDeliveryState {
  final String message;
  const ConsumerLookupError(this.message);

  @override
  List<Object> get props => [message];
}

class PartnerTokensLoading extends OfflineDeliveryState {}

class PartnerTokensLoaded extends OfflineDeliveryState {
  final List<OfflineDeliveryToken> tokens;
  const PartnerTokensLoaded(this.tokens);

  @override
  List<Object> get props => [tokens];
}

class TokenScanning extends OfflineDeliveryState {}

class TokenScanned extends OfflineDeliveryState {
  final OfflineDeliveryToken token;
  const TokenScanned(this.token);

  @override
  List<Object> get props => [token];
}

class TokenScanError extends OfflineDeliveryState {
  final String message;
  const TokenScanError(this.message);

  @override
  List<Object> get props => [message];
}

class OfflineDeliveryError extends OfflineDeliveryState {
  final String message;

  const OfflineDeliveryError(this.message);

  @override
  List<Object> get props => [message];
}
