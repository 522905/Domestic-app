import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/domain/entities/cash/cash_transaction.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isConnected = false;
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDevice?.platformName;

  // Chunk size handling
  static const int _fallbackChunkSize = 200;
  static const int _minChunkSize = 20;
  static const int _absoluteMaxChunkSize = 512;
  int _negotiatedChunkSize = _fallbackChunkSize;

  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      if (_isConnected) {
        await disconnectPrinter();
      }

      await device.connect(timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      await _negotiateChunkSize(device);

      List<BluetoothService> services = await device.discoverServices();

      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
            break;
          }
        }
        if (_writeCharacteristic != null) break;
      }

      if (_writeCharacteristic == null) {
        await device.disconnect();
        _isConnected = false;
        _connectionStatusController.add(false);
        return false;
      }

      _isConnected = true;
      _connectionStatusController.add(true);
      return true;
    } catch (e) {
      debugPrint('Error connecting to printer: $e');
      _isConnected = false;
      _connectionStatusController.add(false);
      return false;
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint('Error disconnecting printer: $e');
    } finally {
      _connectedDevice = null;
      _writeCharacteristic = null;
      _isConnected = false;
      _negotiatedChunkSize = _fallbackChunkSize;
      _connectionStatusController.add(false);
    }
  }

  /// Write data in chunks to avoid Bluetooth MTU limits
  Future<bool> _writeInChunks(List<int> data) async {
    if (_writeCharacteristic == null) return false;

    try {
      int offset = 0;
      while (offset < data.length) {
        final chunkSize = _negotiatedChunkSize;
        final end = min(offset + chunkSize, data.length);
        final chunk = data.sublist(offset, end);

        try {
          await _writeCharacteristic!.write(
            chunk,
            withoutResponse: _writeCharacteristic!.properties.writeWithoutResponse,
          );

          await Future.delayed(const Duration(milliseconds: 80));
          offset = end;  // Only advance if successful

        } on PlatformException catch (e) {
          final allowedLength = _extractAllowedLength(e);
          if (allowedLength != null && allowedLength < chunk.length) {
            _updateChunkSize(allowedLength);
            // Don't advance offset - retry with smaller chunk
            continue;
          }
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('Error writing chunks: $e');
      return false;
    }
  }

  Future<bool> printGatepass(
      InventoryRequest request,
      String date,
      String vehicleId,
      String driverName, {
        String company = 'arungas',
      }) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Dynamic Header based on company
      bytes.addAll([27, 97, 1]); // Center align
      bytes.addAll([29, 33, 17]); // Double size
      bytes.addAll([27, 69, 1]); // Bold ON

      if (company.toLowerCase() == 'arungas') {
        bytes.addAll('ARUN GAS SERVICE'.codeUnits);
      } else {
        bytes.addAll('ARUN INDANE'.codeUnits);
      }

      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]); // Line feed

      // Subtitle - Distributor info (Normal size, Center, compact)
      bytes.addAll([29, 33, 0]); // Normal size
      bytes.addAll('Distributors: India Oil Corporation Limited'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('12 A, Sherpur Khurd, Backside Apollo Hospital'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Sherpur, LUDHIANA'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds

      // Title - GATE PASS CUM PRE DELIVERY CHECK (Bold, Center, compact)
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('GATE PASS CUM PRE DELIVERY CHECK'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]); // 1 line feeds

      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('CHALLAN'.codeUnits); // Changed from WAREHOUSE SLIP
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10, 10]);

      // Format date and time
      final timestamp = DateTime.parse(request.timestamp).toLocal();
      final dateStr = DateFormat('dd/MM/yyyy').format(timestamp);
      final timeStr = DateFormat('hh:mm a').format(timestamp);

      // Left align for details
      bytes.addAll([27, 97, 0]); // Left align

      // Top section - compact format
      bytes.addAll('Sr. No: ${request.id}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Date: $dateStr'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Time Out: $timeStr'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds

      // Vehicle and delivery details - compact
      final totalQty = _getTotalQuantity(request.items);
      bytes.addAll('No. of Cylinder: $totalQty'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Type of Vehicle: ${request.vehicle ?? vehicleId}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Delivery Boy: $driverName'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds

      // Table header - with full width formatting
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Sr | Item Code    | Qty | Sales Order'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);

      // Table rows - Print items with full width alignment
      if (request.items != null && request.items!.isNotEmpty) {
        int srNo = 1;
        for (var item in request.items!) {
          final itemCode = item['item_code'] ?? 'N/A';
          final qty = item['qty'] ?? '0';
          final soRef = item['sales_order_ref'] ?? '-';

          final qtyDouble = double.tryParse(qty.toString()) ?? 0.0;
          final qtyStr = qtyDouble % 1 == 0 ? qtyDouble.toInt().toString() : qtyDouble.toStringAsFixed(1);

          // Format with proper spacing for full width
          final srPadded = _padLeft(srNo.toString(), 2); // 2 chars
          final itemPadded = _padRight(itemCode, 12); // 12 chars
          final qtyPadded = _padLeft(qtyStr, 3); // 3 chars
          final soPadded = _padRight(soRef, 18); // 18 chars

          bytes.addAll('$srPadded | $itemPadded | $qtyPadded | $soPadded'.codeUnits);
          bytes.addAll([10]);
          srNo++;
        }
      }

      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10, 10, 10]); // 3 line feeds for signature space

      // Signature section (Center)
      bytes.addAll([27, 97, 1]); // Center align
      bytes.addAll('Authorized Signature'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds
      bytes.addAll('___________________'.codeUnits);
      bytes.addAll([10, 10, 10, 10]); // 4 line feeds

      // Cut paper
      bytes.addAll([29, 86, 66, 0]); // GS V B 0

      debugPrint('Total bytes to send: ${bytes.length}');

      // Send data in chunks
      final success = await _writeInChunks(bytes);

      if (success) {
        debugPrint('Gatepass printed successfully for $company');
      }

      return success;
    } catch (e) {
      debugPrint('Error printing gatepass: $e');
      return false;
    }
  }

    Future<bool> printSlip(
        InventoryRequest request,
        String date,
        String vehicleId,
        String driverName,
        {String company = 'arungas'}
        ) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Header - Center
      bytes.addAll([27, 97, 1]); // Center align
      bytes.addAll([29, 33, 17]); // Double size
      bytes.addAll([27, 69, 1]); // Bold ON

      if (company.toLowerCase() == 'arungas') {
        bytes.addAll('ARUN GAS SERVICE'.codeUnits);
      } else {
        bytes.addAll('ARUN INDANE'.codeUnits);
      }

      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);

      bytes.addAll([29, 33, 0]); // Normal size
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Slip for warehosue'.codeUnits);  // Changed from WAREHOUSE SLIP
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10, 10]);

      // Format date and time
      final timestamp = DateTime.parse(request.timestamp).toLocal();
      final dateStr = DateFormat('dd/MM/yyyy').format(timestamp);
      final timeStr = DateFormat('hh:mm a').format(timestamp);

      // Left align for content
      bytes.addAll([27, 97, 0]);

      // Basic details
      bytes.addAll('Challan No    : ${request.id}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Date          : $dateStr'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Time          : $timeStr'.codeUnits);
      bytes.addAll([10, 10]);

      bytes.addAll('Vehicle       : ${request.vehicle ?? vehicleId}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Delivery Boy  : $driverName'.codeUnits);
      bytes.addAll([10, 10]);

      // Items section - with Sales Order
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('ITEMS:'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Sr | Item Code    | Qty | Sales Order'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);

      if (request.items != null && request.items!.isNotEmpty) {
        int srNo = 1;
        for (var item in request.items!) {
          final itemCode = item['item_code'] ?? 'N/A';
          final qty = item['qty'] ?? '0';
          final soRef = item['sales_order_ref'] ?? '-';  // Added SO ref

          final qtyDouble = double.tryParse(qty.toString()) ?? 0.0;
          final qtyStr = qtyDouble % 1 == 0 ? qtyDouble.toInt().toString() : qtyDouble.toStringAsFixed(1);

          final srPadded = _padLeft(srNo.toString(), 2);
          final itemPadded = _padRight(itemCode, 12);
          final qtyPadded = _padLeft(qtyStr, 3);
          final soPadded = _padRight(soRef, 18);

          bytes.addAll('$srPadded | $itemPadded | $qtyPadded | $soPadded'.codeUnits);
          bytes.addAll([10]);
          srNo++;
        }
      }

      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);

      final totalQty = _getTotalQuantity(request.items);
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Total Cylinders: $totalQty'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10, 10, 10, 10, 10]);  // Extra spacing at end

      // Cut paper (removed signature section)
      bytes.addAll([29, 86, 66, 0]);

      debugPrint('Total slip bytes: ${bytes.length}');

      final success = await _writeInChunks(bytes);

      if (success) {
        debugPrint('Slip printed successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Error printing slip: $e');
      return false;
    }
  }

  String _getTotalQuantity(List<Map<String, dynamic>>? items) {
    if (items == null || items.isEmpty) return '0';

    double total = 0;
    for (var item in items) {
      final qty = item['qty'];
      if (qty != null) {
        total += double.tryParse(qty.toString()) ?? 0.0;
      }
    }

    return total % 1 == 0 ? total.toInt().toString() : total.toStringAsFixed(1);
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return text.substring(0, maxLength);
  }

// Helper method for right padding (fills with spaces on the right)
  String _padRight(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    return text.padRight(width, ' ');
  }

// Helper method for left padding (fills with spaces on the left)
  String _padLeft(String text, int width) {
    if (text.length >= width) return text;
    return text.padLeft(width, ' ');
  }

  Future<bool> printSimpleGatepass(Map<String, dynamic> gatepassData) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Header
      bytes.addAll([27, 97, 1]); // Center align
      bytes.addAll([29, 33, 17]); // Double size
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('ARUN INDANE'.codeUnits);
      bytes.addAll([10]);

      bytes.addAll([29, 33, 0]); // Normal size
      bytes.addAll('Distributors: India Oil'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Corporation Limited'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('12 A, Sherpur Khurd'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Backside Apollo Hospital'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Sherpur, LUDHIANA'.codeUnits);
      bytes.addAll([10, 10]);

      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('GATE PASS CUM'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('PRE DELIVERY CHECK'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10, 10]);

      // Left align
      bytes.addAll([27, 97, 0]);

      bytes.addAll('Gatepass #${gatepassData['gatepassNo']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Date: ${gatepassData['date']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Time: ${gatepassData['time']}'.codeUnits);
      bytes.addAll([10, 10]);

      bytes.addAll('From: ${gatepassData['from']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('To: ${gatepassData['to']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Driver: ${gatepassData['driver']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Phone: ${gatepassData['phone']}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Vehicle: ${gatepassData['vehicle']}'.codeUnits);
      bytes.addAll([10, 10]);

      bytes.addAll('Items:'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10]);

      List<dynamic> items = gatepassData['items'];
      for (var item in items) {
        bytes.addAll('${item['name']} - Qty: ${item['quantity']}'.codeUnits);
        bytes.addAll([10]);
      }

      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10, 10]);

      bytes.addAll('Authorized By:'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('${gatepassData['authorizedBy']}'.codeUnits);
      bytes.addAll([10, 10, 10]);

      bytes.addAll([27, 97, 1]); // Center
      bytes.addAll('Authorized Signature'.codeUnits);
      bytes.addAll([10, 10, 10]);
      bytes.addAll('___________________'.codeUnits);
      bytes.addAll([10, 10, 10, 10]);

      bytes.addAll([29, 86, 66, 0]); // Cut paper

      debugPrint('Total bytes to send: ${bytes.length}');

      // Send data in chunks
      final success = await _writeInChunks(bytes);

      return success;
    } catch (e) {
      debugPrint('Error printing gatepass: $e');
      return false;
    }
  }

  void dispose() {
    disconnectPrinter();
    _connectionStatusController.close();
  }
  Future<void> _negotiateChunkSize(BluetoothDevice device) async {
    _negotiatedChunkSize = _fallbackChunkSize;

    try {
      await device.requestMtu(_absoluteMaxChunkSize);
      final mtuStream = device.mtu;
      final mtu = await mtuStream.first
          .timeout(const Duration(seconds: 2), onTimeout: () => device.mtuNow);
      _updateChunkSize(mtu - 3);
      debugPrint('Printer MTU negotiated: $mtu, chunk size: $_negotiatedChunkSize');
    } catch (e) {
      final mtuNow = device.mtuNow;
      if (mtuNow > 0) {
        _updateChunkSize(mtuNow - 3);
        debugPrint(
            'Using current MTU $mtuNow, chunk size: $_negotiatedChunkSize (negotiation failed: $e)');
      } else {
        debugPrint('MTU negotiation failed: $e');
      }
    }
  }

    void _updateChunkSize(int? proposedLength) {
      if (proposedLength == null || proposedLength <= 0) {
        _negotiatedChunkSize = _fallbackChunkSize;
        return;
      }

      final clamped = proposedLength.clamp(_minChunkSize, _absoluteMaxChunkSize);
      _negotiatedChunkSize = clamped is int ? clamped : clamped.toInt();
    }

    int? _extractAllowedLength(PlatformException exception) {
      final message = exception.message ?? exception.details?.toString();
      if (message == null) return null;

      final match = RegExp(r'max:\s*(\d+)').firstMatch(message);
      if (match != null) {
        final value = int.tryParse(match.group(1)!);
        return value;
      }

      return null;
    }

  // Cash Receipt Print Method
  Future<bool> printCashReceipt(
      CashTransaction transaction,
      String date, {
        String company = 'arungas',
      }) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Dynamic Header based on company
      bytes.addAll([27, 97, 1]); // Center align
      bytes.addAll([29, 33, 17]); // Double size
      bytes.addAll([27, 69, 1]); // Bold ON

      if (company.toLowerCase() == 'arungas') {
        bytes.addAll('ARUN GAS SERVICE'.codeUnits);
      } else {
        bytes.addAll('ARUN INDANE'.codeUnits);
      }

      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]); // Line feed

      // Subtitle - Distributor info (Normal size, Center, compact)
      bytes.addAll([29, 33, 0]); // Normal size
      bytes.addAll('Distributors: India Oil Corporation Limited'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('12 A, Sherpur Khurd, Backside Apollo Hospital'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Sherpur, LUDHIANA'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds

      // Title - CASH RECEIPT (Bold, Center, compact)
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('CASH RECEIPT'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10, 10]);

      // Format date and time
      final timestamp = transaction.createdAt?.toLocal() ?? DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(timestamp);
      final timeStr = DateFormat('hh:mm a').format(timestamp);

      // Left align for details
      bytes.addAll([27, 97, 0]); // Left align

      // Top section - compact format
      bytes.addAll('Receipt No: ${transaction.id}'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Date: $dateStr'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll('Time: $timeStr'.codeUnits);
      bytes.addAll([10, 10]); // 2 line feeds

      // Transaction details
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('TRANSACTION DETAILS'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10, 10]);

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
      bytes.addAll('Type: $transactionType'.codeUnits);
      bytes.addAll([10]);

      // Amount
      final amountStr = NumberFormat.currency(
        symbol: 'Rs. ',
        decimalDigits: 2,
        locale: 'en_IN',
      ).format(transaction.amount);
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Amount: $amountStr'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);

      // From Account
      if (transaction.fromAccount.isNotEmpty) {
        bytes.addAll('From: ${transaction.fromAccount}'.codeUnits);
        bytes.addAll([10]);
      }

      // To Account
      if (transaction.selectedAccount != null && transaction.selectedAccount!.isNotEmpty) {
        bytes.addAll('To: ${transaction.selectedAccount}'.codeUnits);
        bytes.addAll([10]);
      }

      // Bank info if applicable
      if (transaction.selectedBank != null && transaction.selectedBank!.isNotEmpty) {
        bytes.addAll('Bank: ${transaction.selectedBank}'.codeUnits);
        bytes.addAll([10]);
      }

      // Bank Reference
      if (transaction.bankReferenceNo != null && transaction.bankReferenceNo!.isNotEmpty) {
        bytes.addAll('Ref No: ${transaction.bankReferenceNo}'.codeUnits);
        bytes.addAll([10]);
      }

      bytes.addAll([10]);

      // Initiator
      bytes.addAll('Initiated by: ${transaction.requestedByName ?? transaction.initiator}'.codeUnits);
      bytes.addAll([10]);

      // Remarks
      if (transaction.notes != null && transaction.notes!.isNotEmpty) {
        bytes.addAll('Remarks: ${transaction.notes}'.codeUnits);
        bytes.addAll([10]);
      }

      bytes.addAll([10]);

      // Status
      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10]);
      String status = 'PENDING';
      switch (transaction.status) {
        case TransactionStatus.pending:
          status = 'PENDING';
          break;
        case TransactionStatus.approved:
          status = 'APPROVED';
          break;
        case TransactionStatus.rejected:
          status = 'REJECTED';
          break;
      }
      bytes.addAll([27, 69, 1]); // Bold ON
      bytes.addAll('Status: $status'.codeUnits);
      bytes.addAll([27, 69, 0]); // Bold OFF
      bytes.addAll([10]);

      // Approved by (if approved)
      if (transaction.status == TransactionStatus.approved) {
        if (transaction.approvedByName != null && transaction.approvedByName!.isNotEmpty) {
          bytes.addAll('Approved by: ${transaction.approvedByName}'.codeUnits);
          bytes.addAll([10]);
        }
        if (transaction.approvedAt != null) {
          final approvedDate = DateFormat('dd/MM/yyyy hh:mm a').format(transaction.approvedAt!.toLocal());
          bytes.addAll('Approved on: $approvedDate'.codeUnits);
          bytes.addAll([10]);
        }
      }

      bytes.addAll('------------------------------------------------'.codeUnits);
      bytes.addAll([10, 10, 10, 10, 10]); // Extra spacing at end

      // Cut paper
      bytes.addAll([29, 86, 66, 0]);

      debugPrint('Total receipt bytes: ${bytes.length}');

      final success = await _writeInChunks(bytes);

      if (success) {
        debugPrint('Cash receipt printed successfully');
      }

      return success;
    } catch (e) {
      debugPrint('Error printing cash receipt: $e');
      return false;
    }
  }
}
