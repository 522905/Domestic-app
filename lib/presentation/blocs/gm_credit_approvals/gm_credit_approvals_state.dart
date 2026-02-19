import 'package:equatable/equatable.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';

abstract class GmCreditApprovalsState extends Equatable {
  const GmCreditApprovalsState();

  @override
  List<Object?> get props => [];
}

class GmCreditApprovalsInitial extends GmCreditApprovalsState {}

class GmCreditApprovalsLoading extends GmCreditApprovalsState {}

class GmCreditApprovalsLoaded extends GmCreditApprovalsState {
  final List<CreditExtension> pendingApprovals;
  final int? currentPartnerId;
  final String? currentItemCode;

  const GmCreditApprovalsLoaded({
    required this.pendingApprovals,
    this.currentPartnerId,
    this.currentItemCode,
  });

  GmCreditApprovalsLoaded copyWith({
    List<CreditExtension>? pendingApprovals,
    int? currentPartnerId,
    String? currentItemCode,
  }) {
    return GmCreditApprovalsLoaded(
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      currentPartnerId: currentPartnerId ?? this.currentPartnerId,
      currentItemCode: currentItemCode ?? this.currentItemCode,
    );
  }

  @override
  List<Object?> get props => [pendingApprovals, currentPartnerId, currentItemCode];
}

class GmCreditApprovalsProcessing extends GmCreditApprovalsState {
  final List<CreditExtension> pendingApprovals;
  final int processingExtensionId;

  const GmCreditApprovalsProcessing({
    required this.pendingApprovals,
    required this.processingExtensionId,
  });

  @override
  List<Object?> get props => [pendingApprovals, processingExtensionId];
}

class GmCreditApprovalsSuccess extends GmCreditApprovalsState {
  final String message;
  final List<CreditExtension> updatedApprovals;

  const GmCreditApprovalsSuccess({
    required this.message,
    required this.updatedApprovals,
  });

  @override
  List<Object?> get props => [message, updatedApprovals];
}

class GmCreditApprovalsError extends GmCreditApprovalsState {
  final String message;

  const GmCreditApprovalsError(this.message);

  @override
  List<Object?> get props => [message];
}
