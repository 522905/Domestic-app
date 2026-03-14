import 'package:equatable/equatable.dart';
import '../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../../domain/entities/offline_delivery/distribution_point.dart';
import '../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_company.dart';

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
  }) : selectedDate = selectedDate ?? DateTime.now();

  @override
  List<Object?> get props => [
    systemStatus, distributionPoints, selectedPoint,
    verifications, tokens, isSupervisor, selectedDate,
    hasMoreTokens, hasMoreVerifications,
    isLoadingMoreTokens, isLoadingMoreVerifications,
    searchQuery, companies, lastSelectedCompanyId,
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

class OfflineDeliveryError extends OfflineDeliveryState {
  final String message;

  const OfflineDeliveryError(this.message);

  @override
  List<Object> get props => [message];
}
