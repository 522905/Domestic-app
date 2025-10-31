// lib/presentation/blocs/sdms/sdms_create_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/models/sdms/sdms_error_response.dart';
import '../../../../data/models/sdms/sdms_transaction.dart';

abstract class SDMSCreateState extends Equatable {
  const SDMSCreateState();

  @override
  List<Object> get props => [];
}

class SDMSCreateInitial extends SDMSCreateState {}

class SDMSCreateLoading extends SDMSCreateState {}

class SDMSCreateSuccess extends SDMSCreateState {
  final SDMSApiResponse response;

  const SDMSCreateSuccess({required this.response});

  @override
  List<Object> get props => [response];
}

class SDMSCreateError extends SDMSCreateState {
  final String message;

  const SDMSCreateError({required this.message});

  @override
  List<Object> get props => [message];
}

class SDMSCreateDetailedError extends SDMSCreateState {
  final SDMSErrorResponse errorResponse;
  SDMSCreateDetailedError({required this.errorResponse});
}