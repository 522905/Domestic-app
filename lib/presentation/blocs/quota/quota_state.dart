import 'package:equatable/equatable.dart';
import 'package:lpg_distribution_app/domain/entities/quota/quota_snapshot.dart';

abstract class QuotaState extends Equatable {
  const QuotaState();

  @override
  List<Object?> get props => [];
}

class QuotaInitial extends QuotaState {}

class QuotaLoading extends QuotaState {}

class QuotaLoaded extends QuotaState {
  final QuotaSnapshot snapshot;

  const QuotaLoaded({required this.snapshot});

  @override
  List<Object> get props => [snapshot];
}

class QuotaSyncInProgress extends QuotaState {
  final QuotaSnapshot snapshot; // Keep showing current data during sync

  const QuotaSyncInProgress({required this.snapshot});

  @override
  List<Object> get props => [snapshot];
}

class QuotaError extends QuotaState {
  final String message;
  final bool isAccessDenied; // 403 error - user is not a delivery partner

  const QuotaError({
    required this.message,
    this.isAccessDenied = false,
  });

  @override
  List<Object> get props => [message, isAccessDenied];
}
