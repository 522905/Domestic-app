import 'dart:async';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'printer_status.dart';
import 'printer_type.dart';

/// Abstract interface for all printer implementations
///
/// This interface provides a unified API for different printer types:
/// - Bluetooth printers (MLP 360, TVS, etc.)
/// - Sunmi built-in printers (V2s, V2 Pro, etc.)
///
/// Usage:
/// ```dart
/// final printer = await PrinterManager().getPrinter();
/// if (!printer.isConnected) {
///   await printer.connect();
/// }
/// await printer.printBinaryData(data);
/// ```
abstract class PrinterInterface {
  /// Printer type identifier
  PrinterType get printerType;

  /// Paper width in millimeters (58mm for 2 inch, 80mm for 3 inch)
  int get paperWidthMm;

  /// Device identifier for API calls
  String get deviceIdentifier;

  /// Check if printer is available on this device
  Future<bool> isAvailable();

  /// Initialize printer service
  Future<bool> initialize();

  /// Connect to printer
  /// For Bluetooth: requires deviceAddress parameter
  /// For Sunmi: no-op (always connected)
  Future<bool> connect({String? deviceAddress});

  /// Disconnect from printer
  /// For Bluetooth: disconnects from device
  /// For Sunmi: no-op
  Future<void> disconnect();

  /// Print raw binary ESC/POS data
  /// This is the core printing method used by all document types
  Future<bool> printBinaryData(List<int> data);

  /// Print cash receipt (local generation)
  /// Generates and prints a cash receipt using the printer's native capabilities
  Future<bool> printCashReceipt(
    CashTransaction transaction,
    String companyType,
  );

  /// Printer status stream
  /// Emits status updates when connection state changes
  Stream<PrinterStatus> get statusStream;

  /// Current connection status
  PrinterStatus get currentStatus;

  /// Dispose resources
  Future<void> dispose();
}
