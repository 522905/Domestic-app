import 'package:equatable/equatable.dart';

abstract class MyInstallationsEvent extends Equatable {
  const MyInstallationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadMyInstallations extends MyInstallationsEvent {
  const LoadMyInstallations();
}

class RefreshMyInstallations extends MyInstallationsEvent {
  const RefreshMyInstallations();
}

class ChangeScopeFilter extends MyInstallationsEvent {
  final String scope;
  const ChangeScopeFilter(this.scope);

  @override
  List<Object?> get props => [scope];
}

class ChangeStatusFilter extends MyInstallationsEvent {
  final String? status;
  const ChangeStatusFilter(this.status);

  @override
  List<Object?> get props => [status];
}

class BulkVerifyInstallations extends MyInstallationsEvent {
  final List<int> ids;
  const BulkVerifyInstallations(this.ids);

  @override
  List<Object?> get props => [ids];
}

class RetryFailedInstallations extends MyInstallationsEvent {
  final List<int> ids;
  const RetryFailedInstallations(this.ids);

  @override
  List<Object?> get props => [ids];
}

class PollMyInstallations extends MyInstallationsEvent {
  const PollMyInstallations();
}
