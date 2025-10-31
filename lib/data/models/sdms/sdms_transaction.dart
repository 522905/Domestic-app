// lib/data/models/sdms/sdms_transaction.dart
import 'package:equatable/equatable.dart';

class SDMSTransaction extends Equatable {
  final String id;
  final String orderId;
  final String orderDate;
  final String companyName;
  final String actionType;
  final String actionTypeDisplay;
  final String processStatus;
  final String processStatusDisplay;
  final String? camundaProcessId;
  final String createdAt;
  final String updatedAt;
  final String? completedAt;
  final String resultMessage;
  final Map<String, dynamic>? errorDetails;
  final String initiatedByName;
  final int retryCount;

  const SDMSTransaction({
    required this.id,
    required this.orderId,
    required this.orderDate,
    required this.companyName,
    required this.actionType,
    required this.actionTypeDisplay,
    required this.processStatus,
    required this.processStatusDisplay,
    this.camundaProcessId,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    required this.resultMessage,
    this.errorDetails,
    required this.initiatedByName,
    required this.retryCount,
  });

  factory SDMSTransaction.fromJson(Map<String, dynamic> json) {
    return SDMSTransaction(
      id: json['id'] ?? '',
      orderId: json['order_id'] ?? '',
      orderDate: json['order_date'] ?? '',
      companyName: json['company_name'] ?? '',
      actionType: json['action_type'] ?? '',
      actionTypeDisplay: json['action_type_display'] ?? '',
      processStatus: json['process_status'] ?? '',
      processStatusDisplay: json['process_status_display'] ?? '',
      camundaProcessId: json['camunda_process_id'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      completedAt: json['completed_at'],
      resultMessage: json['result_message'] ?? '',
      errorDetails: json['error_details'] != null
          ? Map<String, dynamic>.from(json['error_details'])
          : null, // Fix parsing
      initiatedByName: json['initiated_by_name'] ?? '',
      retryCount: json['retry_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'order_date': orderDate,
      'company_name': companyName,
      'action_type': actionType,
      'action_type_display': actionTypeDisplay,
      'process_status': processStatus,
      'process_status_display': processStatusDisplay,
      'camunda_process_id': camundaProcessId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'completed_at': completedAt,
      'result_message': resultMessage,
      'error_details': errorDetails, // Remove quotes - it's already a Map
      'initiated_by_name': initiatedByName,
      'retry_count': retryCount,
    };
  }
  @override
  List<Object?> get props => [
    id,
    orderId,
    orderDate,
    companyName,
    actionType,
    actionTypeDisplay,
    processStatus,
    processStatusDisplay,
    camundaProcessId,
    createdAt,
    updatedAt,
    completedAt,
    resultMessage,
    errorDetails,
    initiatedByName,
    retryCount,
  ];
}

class SDMSTransactionRequest extends Equatable {
  final String orderId;

  const SDMSTransactionRequest({required this.orderId});

  Map<String, dynamic> toJson() {
    return {'order_id': orderId};
  }

  @override
  List<Object> get props => [orderId];
}

class SDMSApiResponse extends Equatable {
  final String transactionId;
  final String? camundaProcessId;
  final String status;

  const SDMSApiResponse({
    required this.transactionId,
    this.camundaProcessId,
    required this.status,
  });

  factory SDMSApiResponse.fromJson(Map<String, dynamic> json) {
    return SDMSApiResponse(
      transactionId: json['transaction_id'] ?? '',
      camundaProcessId: json['camunda_process_id'],
      status: json['status'] ?? '',
    );
  }

  @override
  List<Object?> get props => [transactionId, camundaProcessId, status];
}