import 'package:equatable/equatable.dart';
import 'offline_delivery_company.dart';

class BookingVerification extends Equatable {
  final String id;
  final String? consumerId;
  final String? consumerNumber;
  final String? consumerName;
  final String? orderNumber;
  final String status;
  final double? cashToCollect;
  final double? digitalAmount;
  final bool isDigitallyPaid;
  final String? orderNumberFromRpa;
  final String? errorMessage;
  final String? errorCode;
  final OfflineDeliveryCompany? company;
  final bool hasToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const BookingVerification({
    required this.id,
    this.consumerId,
    this.consumerNumber,
    this.consumerName,
    this.orderNumber,
    required this.status,
    this.cashToCollect,
    this.digitalAmount,
    required this.isDigitallyPaid,
    this.orderNumberFromRpa,
    this.errorMessage,
    this.errorCode,
    this.company,
    required this.hasToken,
    this.createdAt,
    this.updatedAt,
  });

  bool get isVerified => status == 'VERIFIED';
  bool get isBookingCreated => status == 'BOOKING_CREATED';
  bool get isFailed => status == 'FAILED';
  bool get canCreateToken => (isVerified || isBookingCreated) && !hasToken;

  BookingVerification copyWith({String? status, bool? hasToken, OfflineDeliveryCompany? company}) {
    return BookingVerification(
      id: id,
      consumerId: consumerId,
      consumerNumber: consumerNumber,
      consumerName: consumerName,
      orderNumber: orderNumber,
      status: status ?? this.status,
      cashToCollect: cashToCollect,
      digitalAmount: digitalAmount,
      isDigitallyPaid: isDigitallyPaid,
      orderNumberFromRpa: orderNumberFromRpa,
      errorMessage: errorMessage,
      errorCode: errorCode,
      company: company ?? this.company,
      hasToken: hasToken ?? this.hasToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory BookingVerification.fromJson(Map<String, dynamic> json) {
    return BookingVerification(
      id: json['id']?.toString() ?? '',
      consumerId: json['consumer_id']?.toString(),
      consumerNumber: json['consumer_number'],
      consumerName: json['consumer_name'],
      orderNumber: json['order_number'],
      status: json['status'] ?? 'PENDING',
      cashToCollect: json['cash_to_collect'] != null ? double.tryParse(json['cash_to_collect'].toString()) : null,
      digitalAmount: json['digital_amount'] != null ? double.tryParse(json['digital_amount'].toString()) : null,
      isDigitallyPaid: json['is_digitally_paid'] ?? false,
      orderNumberFromRpa: json['order_number_from_rpa'],
      errorMessage: json['error_message'],
      errorCode: json['error_code'],
      company: json['company'] != null
          ? OfflineDeliveryCompany.fromJson(json['company'] as Map<String, dynamic>)
          : null,
      hasToken: json['has_token'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, consumerId, consumerNumber, consumerName, orderNumber,
    status, cashToCollect, digitalAmount, isDigitallyPaid,
    orderNumberFromRpa, errorMessage, errorCode, company, hasToken,
    createdAt, updatedAt,
  ];
}
