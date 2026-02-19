import 'printer_type.dart';

/// Printer status information class
class PrinterStatus {
  final PrinterConnectionStatus status;
  final String? errorMessage;
  final String? deviceName;
  final String? deviceAddress;

  const PrinterStatus({
    required this.status,
    this.errorMessage,
    this.deviceName,
    this.deviceAddress,
  });

  bool get isConnected => status == PrinterConnectionStatus.connected;
  bool get isError => status == PrinterConnectionStatus.error;
  bool get isDisconnected => status == PrinterConnectionStatus.disconnected;
  bool get isConnecting => status == PrinterConnectionStatus.connecting;

  @override
  String toString() {
    return 'PrinterStatus(status: $status, device: $deviceName, error: $errorMessage)';
  }
}
