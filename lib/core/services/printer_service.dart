// lib/core/services/printer_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  bool _isConnected = false;
  final StreamController<bool> _connectionStatusController = StreamController<bool>.broadcast();

  Stream<bool> get connectionStatus => _connectionStatusController.stream;
  bool get isConnected => _isConnected;
  String? get connectedDeviceName => _connectedDevice?.name;

  Future<List<BluetoothDevice>> scanForPrinters() async {
    try {
      // Check if scanning is already in progress before starting
      if (!await FlutterBluePlus.isScanning.first) {
        FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      }

      await Future.delayed(const Duration(seconds: 4));

      // Check if scanning is still active before stopping
      if (await FlutterBluePlus.isScanning.first) {
        FlutterBluePlus.stopScan();
      }

      final List<BluetoothDevice> devices = FlutterBluePlus.connectedDevices;
      final List<ScanResult> scanResults = await FlutterBluePlus.scanResults.first;

      // Filter for TVS printers or any thermal printer
      final printerDevices = scanResults
          .where((result) =>
      result.device.name.toLowerCase().contains('tvs') ||
          result.device.name.toLowerCase().contains('mlp') ||
          result.device.name.toLowerCase().contains('thermal') ||
          result.device.name.toLowerCase().contains('printer'))
          .map((result) => result.device)
          .toList();

      return printerDevices;
    } catch (e) {
      debugPrint('Error scanning for printers: $e');
      return [];
    }
  }

  Future<bool> connectToPrinter(BluetoothDevice device) async {
    try {
      if (_isConnected) {
        await disconnectPrinter();
      }

      await device.connect();
      _connectedDevice = device;

      // Get services
      List<BluetoothService> services = await device.discoverServices();

      // Look for a service with write characteristic
      for (BluetoothService service in services) {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic characteristic in characteristics) {
          if (characteristic.properties.write) {
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
      _connectionStatusController.add(false);
    }
  }

  Future<bool> printGatepass(InventoryRequest request, String date, String vehicleId, String driverName) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      // ESC/POS commands for printing
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Set text alignment center
      bytes.addAll([27, 97, 1]); // ESC a 1

      // Set text size - double height and width
      bytes.addAll([29, 33, 17]); // GS ! 17

      // Print title in bold
      bytes.addAll([27, 69, 1]); // ESC E 1
      bytes.addAll('GATEPASS'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Reset text size to normal
      bytes.addAll([29, 33, 0]); // GS ! 0

      // Set text alignment left
      bytes.addAll([27, 97, 0]); // ESC a 0

      // Print request ID
      bytes.addAll('For Collection #${request.id}'.codeUnits);
      bytes.addAll([10, 10]); // 2 Line feeds

      // Print divider
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print details
      bytes.addAll('Date & Time: $date'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Vehicle: $vehicleId'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Driver: $driverName'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Format and print items
      String items = 'Items: ';
      if (request.cylinders14kg > 0) {
        items += '14.2kg: ${request.cylinders14kg} ';
      }
      if (request.smallCylinders > 0) {
        items += '5kg: ${request.smallCylinders} ';
      }
      if (request.cylinders19kg > 0) {
        items += '19kg: ${request.cylinders19kg}';
      }

      bytes.addAll(items.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print divider
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10, 10]); // 2 Line feeds

      // Print signature line
      bytes.addAll('Authorized Signature:'.codeUnits);
      bytes.addAll([10, 10, 10]); // 3 Line feeds
      bytes.addAll('_______________________'.codeUnits);
      bytes.addAll([10, 10, 10, 10, 10]); // 5 Line feeds

      // Cut paper
      bytes.addAll([29, 86, 66, 0]); // GS V B 0

      // Send data to printer
      await _writeCharacteristic!.write(bytes);

      return true;
    } catch (e) {
      debugPrint('Error printing gatepass: $e');
      return false;
    }
  }

  Future<bool> printSimpleGatepass(Map<String, dynamic> gatepassData) async {
    if (!_isConnected || _writeCharacteristic == null) {
      return false;
    }

    try {
      // ESC/POS commands for printing
      List<int> bytes = [];

      // Initialize printer
      bytes.addAll([27, 64]); // ESC @

      // Set text alignment center
      bytes.addAll([27, 97, 1]); // ESC a 1

      // Set text size - double height and width
      bytes.addAll([29, 33, 17]); // GS ! 17

      // Print title in bold
      bytes.addAll([27, 69, 1]); // ESC E 1
      bytes.addAll('GATEPASS'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Reset text size to normal
      bytes.addAll([29, 33, 0]); // GS ! 0

      // Set text alignment left
      bytes.addAll([27, 97, 0]); // ESC a 0

      // Print gatepass number
      bytes.addAll('Gatepass #${gatepassData['gatepassNo']}'.codeUnits);
      bytes.addAll([10, 10]); // 2 Line feeds

      // Print divider
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print details
      bytes.addAll('Date: ${gatepassData['date']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Time: ${gatepassData['time']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('From: ${gatepassData['from']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('To: ${gatepassData['to']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Driver: ${gatepassData['driver']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Phone: ${gatepassData['phone']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      bytes.addAll('Vehicle: ${gatepassData['vehicle']}'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print divider
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print items header
      bytes.addAll('Items:'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print items
      List<dynamic> items = gatepassData['items'];
      for (var item in items) {
        bytes.addAll('${item['name']} - Quantity: ${item['quantity']}'.codeUnits);
        bytes.addAll([10]); // Line feed
      }

      // Print divider
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([10]); // Line feed

      // Print authorized by
      bytes.addAll('Authorized By: ${gatepassData['authorizedBy']}'.codeUnits);
      bytes.addAll([10, 10]); // 2 Line feeds

      // Print signature line
      bytes.addAll('Signature:'.codeUnits);
      bytes.addAll([10, 10, 10]); // 3 Line feeds
      bytes.addAll('_______________________'.codeUnits);
      bytes.addAll([10, 10, 10, 10, 10]); // 5 Line feeds

      // Cut paper
      bytes.addAll([29, 86, 66, 0]); // GS V B 0

      // Send data to printer
      await _writeCharacteristic!.write(bytes);

      return true;
    } catch (e) {
      debugPrint('Error printing gatepass: $e');
      return false;
    }
  }

  void dispose() {
    disconnectPrinter();
    _connectionStatusController.close();
  }
}