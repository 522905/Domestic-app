// lib/presentation/blocs/sdms/sdms_create_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/sdms/create/sdms_create_event.dart';
import 'package:lpg_distribution_app/presentation/blocs/sdms/create/sdms_create_state.dart';
import '../../../../core/models/sdms/sdms_error_response.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../utils/error_handler.dart';
import 'package:dio/dio.dart';

class SDMSCreateBloc extends Bloc<SDMSCreateEvent, SDMSCreateState> {
  final ApiServiceInterface apiService;

  SDMSCreateBloc({required this.apiService}) : super(SDMSCreateInitial()) {
    on<CreateInvoiceAssignEvent>(_onCreateInvoiceAssign);
    on<CreateCreditPaymentEvent>(_onCreateCreditPayment);
    on<ResetCreateStateEvent>(_onResetCreateState);
  }

  Future<void> _onCreateInvoiceAssign(
      CreateInvoiceAssignEvent event,
      Emitter<SDMSCreateState> emit,
      ) async {
    try {
      emit(SDMSCreateLoading());
      final response = await apiService.createInvoiceAssign(event.orderId);
      emit(SDMSCreateSuccess(response: response));
    } catch (error) {
      if (error is DioException && error.response?.data != null) {
        final data = error.response!.data;

        if (data is Map<String, dynamic> && data.containsKey('reason')) {
          try {
            final errorResponse = SDMSErrorResponse.fromJson(data);
            emit(SDMSCreateDetailedError(errorResponse: errorResponse));
            return;
          } catch (_) {}
        }

        if (data is Map<String, dynamic>) {
          final validationErrors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              validationErrors.addAll(value.map((e) => e.toString()));
            } else {
              validationErrors.add(value.toString());
            }
          });

          if (validationErrors.isNotEmpty) {
            emit(SDMSCreateError(message: validationErrors.join('\n')));
            return;
          }
        }
      }

      emit(SDMSCreateError(message: ErrorHandler.handleError(error)));
    }
  }

  Future<void> _onCreateCreditPayment(
      CreateCreditPaymentEvent event,
      Emitter<SDMSCreateState> emit,
      ) async {
    try {
      emit(SDMSCreateLoading());
      final response = await apiService.createCreditPayment(event.orderId);
      emit(SDMSCreateSuccess(response: response));
    } catch (error) {
      if (error is DioException && error.response?.data != null) {
        final data = error.response!.data;

        // Check for structured error (with reason field)
        if (data is Map<String, dynamic> && data.containsKey('reason')) {
          try {
            final errorResponse = SDMSErrorResponse.fromJson(data);
            emit(SDMSCreateDetailedError(errorResponse: errorResponse));
            return;
          } catch (_) {}
        }

        // Check for validation errors (field-level errors)
        if (data is Map<String, dynamic>) {
          final validationErrors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              validationErrors.addAll(value.map((e) => e.toString()));
            } else {
              validationErrors.add(value.toString());
            }
          });

          if (validationErrors.isNotEmpty) {
            emit(SDMSCreateError(message: validationErrors.join('\n')));
            return;
          }
        }
      }

      emit(SDMSCreateError(message: ErrorHandler.handleError(error)));
    }
  }

  void _onResetCreateState(
      ResetCreateStateEvent event,
      Emitter<SDMSCreateState> emit,
      ) {
    emit(SDMSCreateInitial());
  }
}