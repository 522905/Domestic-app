import 'digital_credit.dart';
import 'claim_transfer.dart';

class ClaimResult {
  final bool success;
  final String type; // 'CLAIMED' or 'TRANSFER_REQUESTED'
  final String message;
  final DigitalCredit? credit;
  final ClaimTransfer? transfer;

  ClaimResult({
    required this.success,
    required this.type,
    required this.message,
    this.credit,
    this.transfer,
  });

  bool get isDirectClaim => type == 'CLAIMED';
  bool get isTransferRequest => type == 'TRANSFER_REQUESTED';

  factory ClaimResult.fromJson(Map<String, dynamic> json) {
    return ClaimResult(
      success: json['success'] as bool,
      type: json['type'] as String,
      message: json['message'] as String,
      credit: json['credit'] != null
          ? DigitalCredit.fromJson(json['credit'])
          : null,
      transfer: json['transfer'] != null
          ? ClaimTransfer.fromJson(json['transfer'])
          : null,
    );
  }
}
