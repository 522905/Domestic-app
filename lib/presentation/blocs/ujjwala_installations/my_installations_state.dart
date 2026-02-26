import 'package:equatable/equatable.dart';
import '../../../domain/entities/ujjwala/lpg_ops_installation.dart';

abstract class MyInstallationsState extends Equatable {
  const MyInstallationsState();

  @override
  List<Object?> get props => [];
}

class MyInstallationsInitial extends MyInstallationsState {
  const MyInstallationsInitial();
}

class MyInstallationsLoading extends MyInstallationsState {
  const MyInstallationsLoading();
}

class MyInstallationsLoaded extends MyInstallationsState {
  final List<LpgOpsInstallation> installations;
  final String scope;
  final String? statusFilter;
  final bool hasPendingVerification;

  const MyInstallationsLoaded({
    required this.installations,
    required this.scope,
    this.statusFilter,
    this.hasPendingVerification = false,
  });

  MyInstallationsLoaded copyWith({
    List<LpgOpsInstallation>? installations,
    String? scope,
    String? statusFilter,
    bool clearStatusFilter = false,
    bool? hasPendingVerification,
  }) {
    return MyInstallationsLoaded(
      installations: installations ?? this.installations,
      scope: scope ?? this.scope,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      hasPendingVerification: hasPendingVerification ?? this.hasPendingVerification,
    );
  }

  @override
  List<Object?> get props => [installations, scope, statusFilter, hasPendingVerification];
}

class MyInstallationsEmpty extends MyInstallationsState {
  final String scope;
  final String? statusFilter;

  const MyInstallationsEmpty({required this.scope, this.statusFilter});

  @override
  List<Object?> get props => [scope, statusFilter];
}

class MyInstallationsError extends MyInstallationsState {
  final String message;

  const MyInstallationsError({required this.message});

  @override
  List<Object?> get props => [message];
}
