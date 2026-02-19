import 'package:equatable/equatable.dart';

class ExtensionReservation extends Equatable {
  final int reservationId;
  final int extensionId;
  final String itemCode;
  final int quantity;

  const ExtensionReservation({
    required this.reservationId,
    required this.extensionId,
    required this.itemCode,
    required this.quantity,
  });

  factory ExtensionReservation.fromJson(Map<String, dynamic> json) {
    return ExtensionReservation(
      reservationId: json['reservation_id'] ?? 0,
      extensionId: json['extension_id'] ?? 0,
      itemCode: json['item_code'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_id': reservationId,
      'extension_id': extensionId,
      'item_code': itemCode,
      'quantity': quantity,
    };
  }

  @override
  List<Object?> get props => [reservationId, extensionId, itemCode, quantity];
}
