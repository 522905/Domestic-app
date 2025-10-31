// lib/presentation/blocs/sdms/sdms_create_event.dart
import 'package:equatable/equatable.dart';

abstract class SDMSCreateEvent extends Equatable {
  const SDMSCreateEvent();

  @override
  List<Object> get props => [];
}

class CreateInvoiceAssignEvent extends SDMSCreateEvent {
  final String orderId;

  const CreateInvoiceAssignEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

class CreateCreditPaymentEvent extends SDMSCreateEvent {
  final String orderId;

  const CreateCreditPaymentEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}

class ResetCreateStateEvent extends SDMSCreateEvent {}
