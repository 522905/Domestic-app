import 'package:intl/intl.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';

class OfflineDeliveryPrintHelper {
  /// Builds ESC/POS thermal receipt bytes for a delivery token.
  static List<int> buildTokenReceiptBytes(OfflineDeliveryToken token, String userName) {
    List<int> bytes = [];

    // Initialize printer
    bytes.addAll([27, 64]); // ESC @

    // Header - Center align
    bytes.addAll([27, 97, 1]); // Center align
    bytes.addAll([27, 69, 1]); // Bold ON
    bytes.addAll([10]);
    bytes.addAll('DELIVERY TOKEN'.codeUnits);
    bytes.addAll([10]);
    bytes.addAll([27, 69, 0]); // Bold OFF
    bytes.addAll([10]);

    // Left align for content
    bytes.addAll([27, 97, 0]);
    bytes.addAll([29, 33, 0]); // Ensure normal size

    // Token Number
    if (token.tokenNumber != null) {
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Token #     : ${token.tokenNumber}'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
    }

    // Consumer ID
    if (token.consumerId != null && token.consumerId!.isNotEmpty) {
      bytes.addAll('Consumer ID : ${token.consumerId}'.codeUnits);
      bytes.addAll([10]);
    }

    // Consumer Number
    if (token.consumerNumber != null && token.consumerNumber!.isNotEmpty) {
      bytes.addAll('Consumer No : ${token.consumerNumber}'.codeUnits);
      bytes.addAll([10]);
    }

    // Order Number
    if (token.orderNumber != null && token.orderNumber!.isNotEmpty) {
      bytes.addAll('Order #     : ${token.orderNumber}'.codeUnits);
      bytes.addAll([10]);
    }

    // Separator
    bytes.addAll('------------------'.codeUnits);
    bytes.addAll([10]);

    // Cash to collect
    if (token.cashToCollect != null) {
      final estSuffix = token.cashToCollectIsEstimated ? ' (est.)' : '';
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Cash        : Rs. ${token.cashToCollect!.toStringAsFixed(2)}$estSuffix'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
    }

    // Status
    final statusLabel = token.isDelivered ? 'Delivered' : (token.isVoided ? 'Voided' : 'Token Issued');
    bytes.addAll('Status      : $statusLabel'.codeUnits);
    bytes.addAll([10]);

    // Cash collected (if delivered)
    if (token.isDelivered && token.cashCollected != null) {
      bytes.addAll('Collected   : Rs. ${token.cashCollected!.toStringAsFixed(2)}'.codeUnits);
      bytes.addAll([10]);
    }

    // DAC Code
    if (token.dacCode != null && token.dacCode!.isNotEmpty) {
      bytes.addAll('DAC Code    : ${token.dacCode}'.codeUnits);
      bytes.addAll([10]);
    }

    // Separator
    bytes.addAll('------------------'.codeUnits);
    bytes.addAll([10]);

    // Distribution Point
    if (token.distributionPointName != null) {
      bytes.addAll('Point       : ${token.distributionPointName}'.codeUnits);
      bytes.addAll([10]);
    }

    // Date & Time
    final dateTime = token.createdAt ?? DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
    final timeStr = DateFormat('hh:mm a').format(dateTime);
    bytes.addAll('Date        : $dateStr'.codeUnits);
    bytes.addAll([10]);
    bytes.addAll('Time        : $timeStr'.codeUnits);
    bytes.addAll([10]);

    // Issued by
    bytes.addAll('Issued by   : $userName'.codeUnits);
    bytes.addAll([10]);

    // Footer
    bytes.addAll([27, 97, 1]); // Center align
    bytes.addAll([27, 69, 1]); // Bold ON
    bytes.addAll('================================'.codeUnits);
    bytes.addAll([27, 69, 0]); // Bold OFF
    bytes.addAll([10, 10, 10]); // Feed for tear

    // Cut paper
    bytes.addAll([29, 86, 66, 0]);

    return bytes;
  }
}
