import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sunmi_printer_plugin/sunmi_printer_plugin.dart';
import 'package:sunmi_printer_plugin/enums.dart' hide PrinterStatus;
import 'package:sunmi_printer_plugin/sunmi_style.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';
import 'printer_interface.dart';
import 'printer_status.dart';
import 'printer_type.dart';

/// Sunmi printer service implementation for Sunmi V2s built-in thermal printers
/// Uses sunmi_printer_plugin for direct communication with built-in printer
class SunmiPrinterService implements PrinterInterface {
  static final SunmiPrinterService _instance = SunmiPrinterService._internal();
  factory SunmiPrinterService() => _instance;
  SunmiPrinterService._internal();

  bool _isInitialized = false;
  bool _isConnected = false;
  final StreamController<PrinterStatus> _statusController =
      StreamController<PrinterStatus>.broadcast();

  PrinterStatus _currentStatus = const PrinterStatus(
    status: PrinterConnectionStatus.disconnected,
  );

  @override
  PrinterType get printerType => PrinterType.sunmi;

  @override
  int get paperWidthMm => 58; // Sunmi V2s uses 2-inch (58mm) paper

  @override
  String get deviceIdentifier => 'SUNMI-V2S';

  @override
  Stream<PrinterStatus> get statusStream => _statusController.stream;

  @override
  PrinterStatus get currentStatus => _currentStatus;

  @override
  Future<bool> isAvailable() async {
    try {
      // Try to bind Sunmi printer service
      final result = await SunmiPrinter.bindingPrinter();
      return result ?? false;
    } catch (e) {
      debugPrint('Sunmi printer not available: $e');
      return false;
    }
  }

  @override
  Future<bool> initialize() async {
    try {
      final bound = await SunmiPrinter.bindingPrinter();
      if (bound == true) {
        await SunmiPrinter.initPrinter();
        _isInitialized = true;
        _isConnected = true;
        _updateStatus(const PrinterStatus(
          status: PrinterConnectionStatus.connected,
          deviceName: 'Sunmi Built-in Printer',
        ));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Sunmi initialization error: $e');
      _updateStatus(PrinterStatus(
        status: PrinterConnectionStatus.error,
        errorMessage: e.toString(),
      ));
      return false;
    }
  }

  @override
  Future<bool> connect({String? deviceAddress}) async {
    // No-op for Sunmi (auto-connected once initialized)
    return await initialize();
  }

  @override
  Future<void> disconnect() async {
    // No explicit disconnect for Sunmi
    _isConnected = false;
    _updateStatus(const PrinterStatus(
      status: PrinterConnectionStatus.disconnected,
    ));
  }

  @override
  Future<bool> printBinaryData(List<int> data) async {
    if (!_isConnected) {
      debugPrint('Sunmi printer not connected');
      return false;
    }

    try {
      debugPrint('Sunmi: Printing ${data.length} bytes of raw ESC/POS data');
      // debugPrint('Sunmi: First 100 bytes: ${data.take(100).toList()}');
      // debugPrint('Sunmi: Last 50 bytes: ${data.skip(data.length - 50).toList()}');

      // Initialize printer to reset state
      await SunmiPrinter.initPrinter();

      // Send raw ESC/POS data directly without transaction wrapping
      // The data already contains all necessary ESC/POS commands for formatting and cutting
      await SunmiPrinter.printRawData(Uint8List.fromList(data));

      debugPrint('Sunmi: Print completed successfully');
      return true;
    } catch (e) {
      debugPrint('Sunmi print error: $e');
      _updateStatus(PrinterStatus(
        status: PrinterConnectionStatus.error,
        errorMessage: 'Print failed: $e',
      ));
      return false;
    }
  }

  @override
  Future<bool> printCashReceipt(
    CashTransaction transaction,
    String companyType,
  ) async {
    if (!_isConnected) {
      debugPrint('Sunmi printer not connected');
      return false;
    }

    try {
      await SunmiPrinter.initPrinter();
      await SunmiPrinter.startTransactionPrint(true);

      // Company header - large, centered, bold
      await SunmiPrinter.printText(
        companyType.toLowerCase() == 'arungas'
          ? 'ARUN GAS SERVICE'
          : 'ARUN INDANE',
        style: SunmiStyle(
          align: SunmiPrintAlign.CENTER,
          fontSize: SunmiFontSize.LG,
          bold: true,
        ),
      );

      // Address lines - small, centered
      await SunmiPrinter.printText(
        'Distributors: India Oil Corporation Limited',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER, fontSize: SunmiFontSize.SM),
      );
      await SunmiPrinter.printText(
        '12 A, Sherpur Khurd, Backside Apollo Hospital',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER, fontSize: SunmiFontSize.SM),
      );
      await SunmiPrinter.printText(
        'Sherpur, LUDHIANA',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER, fontSize: SunmiFontSize.SM),
      );
      await SunmiPrinter.lineWrap(2);

      // Title - centered
      await SunmiPrinter.printText(
        'CASH RECEIPT',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.printText(
        '================================',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);

      final timestamp = transaction.createdAt?.toLocal() ?? DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(timestamp);
      final timeStr = DateFormat('hh:mm a').format(timestamp);

      // Transaction info - left aligned
      await SunmiPrinter.printText(
        'Receipt No: ${transaction.id}',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.printText(
        'Date: $dateStr',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.printText(
        'Time: $timeStr',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.lineWrap(1);

      await SunmiPrinter.printText(
        '--------------------------------',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.printText(
        'TRANSACTION DETAILS',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.printText(
        '--------------------------------',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );
      await SunmiPrinter.lineWrap(1);

      // Transaction Type
      String transactionType = 'Deposit';
      switch (transaction.type) {
        case TransactionType.deposit:
          transactionType = 'Deposit';
          break;
        case TransactionType.handover:
          transactionType = 'Handover';
          break;
        case TransactionType.bank:
          transactionType = 'Bank Deposit';
          break;
      }
      await SunmiPrinter.printText(
        'Type: $transactionType',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );

      // Amount
      final amountStr = NumberFormat.currency(
        symbol: 'Rs. ',
        decimalDigits: 2,
        locale: 'en_IN',
      ).format(transaction.amount);
      await SunmiPrinter.printText(
        'Amount: $amountStr',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );

      // From Account
      if (transaction.fromAccount.isNotEmpty) {
        await SunmiPrinter.printText(
          'From: ${transaction.fromAccount}',
          style: SunmiStyle(align: SunmiPrintAlign.LEFT),
        );
      }

      // To Account
      if (transaction.selectedAccount != null && transaction.selectedAccount!.isNotEmpty) {
        await SunmiPrinter.printText(
          'To: ${transaction.selectedAccount}',
          style: SunmiStyle(align: SunmiPrintAlign.LEFT),
        );
      }

      // Bank info
      if (transaction.selectedBank != null && transaction.selectedBank!.isNotEmpty) {
        await SunmiPrinter.printText(
          'Bank: ${transaction.selectedBank}',
          style: SunmiStyle(align: SunmiPrintAlign.LEFT),
        );
      }

      // Bank Reference
      if (transaction.bankReferenceNo != null && transaction.bankReferenceNo!.isNotEmpty) {
        await SunmiPrinter.printText(
          'Ref No: ${transaction.bankReferenceNo}',
          style: SunmiStyle(align: SunmiPrintAlign.LEFT),
        );
      }

      await SunmiPrinter.lineWrap(1);

      // Initiator
      await SunmiPrinter.printText(
        'Initiated by: ${transaction.requestedByName ?? transaction.initiator}',
        style: SunmiStyle(align: SunmiPrintAlign.LEFT),
      );

      // Remarks
      if (transaction.notes != null && transaction.notes!.isNotEmpty) {
        await SunmiPrinter.printText(
          'Remarks: ${transaction.notes}',
          style: SunmiStyle(align: SunmiPrintAlign.LEFT),
        );
      }

      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.printText(
        'Thank you!',
        style: SunmiStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);

      // Submit transaction and cut paper
      await SunmiPrinter.exitTransactionPrint(true);

      debugPrint('Sunmi: Cash receipt printed successfully');
      return true;
    } catch (e) {
      debugPrint('Sunmi print error: $e');
      _updateStatus(PrinterStatus(
        status: PrinterConnectionStatus.error,
        errorMessage: 'Print failed: $e',
      ));
      return false;
    }
  }

  @override
  Future<void> dispose() async {
    await _statusController.close();
  }

  void _updateStatus(PrinterStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  // Legacy compatibility properties
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _isConnected ? 'Sunmi Built-in Printer' : null;
}
