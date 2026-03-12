import 'package:intl/intl.dart';
import '../../../domain/entities/dac_order/dac_order_entry.dart';

class DacOrderPrintHelper {
  static List<int> buildSlipBytes(DacOrderEntry entry, String userName) {
    List<int> bytes = [];

    // Initialize printer
    bytes.addAll([27, 64]); // ESC @

    // Header - Center align
    bytes.addAll([27, 97, 1]); // Center align
    bytes.addAll([27, 69, 1]); // Bold ON
    bytes.addAll([10]);
    bytes.addAll([29, 33, 17]); // Double size
    bytes.addAll('VERIFICATION SLIP'.codeUnits);
    bytes.addAll([10]);
    bytes.addAll([29, 33, 0]); // Normal size
    bytes.addAll([27, 69, 0]); // Bold OFF
    bytes.addAll([10, 10]);

    // Left align for content - normal size
    bytes.addAll([27, 97, 0]);
    bytes.addAll([29, 33, 0]); // Ensure normal size

    // Slip Number
    if (entry.slipNumber > 0) {
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Slip No     : #${entry.slipNumber}'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
    }

    // Consumer ID
    if (entry.consumerId != null && entry.consumerId!.isNotEmpty) {
      bytes.addAll('Consumer ID : ${entry.consumerId}'.codeUnits);
      bytes.addAll([10]);
    }

    // Consumer Number
    if (entry.consumerNumber != null && entry.consumerNumber!.isNotEmpty) {
      bytes.addAll('Consumer No : ${entry.consumerNumber}'.codeUnits);
      bytes.addAll([10]);
    }

    // DAC Code
    bytes.addAll([27, 69, 1]); // Bold ON
    bytes.addAll('DAC Code    : ${entry.dacCode}'.codeUnits);
    bytes.addAll([27, 69, 0]); // Bold OFF
    bytes.addAll([10]);

    // Remark
    if (entry.remark != null && entry.remark!.isNotEmpty) {
      bytes.addAll('Remark      : ${entry.remark}'.codeUnits);
      bytes.addAll([10]);
    }

    // Separator
    bytes.addAll('------------------'.codeUnits);
    bytes.addAll([10]);

    // Date & Time
    final dateStr = DateFormat('dd/MM/yyyy').format(entry.createdAt);
    final timeStr = DateFormat('hh:mm a').format(entry.createdAt);
    bytes.addAll('Date        : $dateStr'.codeUnits);
    bytes.addAll([10]);
    bytes.addAll('Time        : $timeStr'.codeUnits);
    bytes.addAll([10]);

    // Verified by
    bytes.addAll('Verified by : $userName'.codeUnits);
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
