import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lpg_distribution_app/core/services/printer_service.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothPrinterWidget extends StatefulWidget {
  final Function(bool) onConnectionChanged;

  const BluetoothPrinterWidget({
    Key? key,
    required this.onConnectionChanged,
  }) : super(key: key);

  @override
  State<BluetoothPrinterWidget> createState() => _BluetoothPrinterWidgetState();
}

class _BluetoothPrinterWidgetState extends State<BluetoothPrinterWidget> {
  final PrinterService _printerService = PrinterService();
  bool _isScanning = false;
  List<BluetoothDevice> _availablePrinters = [];

  @override
  void initState() {
    super.initState();
    _printerService.connectionStatus.listen((isConnected) {
      widget.onConnectionChanged(isConnected);
    });
  }

  Future<void> _startScan() async {
    try {
      setState(() {
        _isScanning = true;
      });

      // Check if Location is enabled (required for BLE on Android)
      bool locationEnabled = await Permission.locationWhenInUse.serviceStatus.isEnabled;
      if (!locationEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enable Location services for Bluetooth scanning')),
        );
        return;
      }

      // Ensure Bluetooth is on
      bool isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        await FlutterBluePlus.turnOn();
      }

      // Stop any existing scan first
      await FlutterBluePlus.stopScan();

      // Start scanning with slight delay to ensure previous scan is stopped
      await Future.delayed(Duration(milliseconds: 300));
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

      // Listen for scan results for 10 seconds
      await for (List<ScanResult> results in FlutterBluePlus.scanResults.timeout(Duration(seconds: 10))) {
        // Update available printers as results come in
        final printers = results.where((result) =>
        result.device.name.isNotEmpty && (
            result.device.name.toLowerCase().contains('tvs') ||
                result.device.name.toLowerCase().contains('printer') ||
                result.device.name.toLowerCase().contains('mlp')
        )).toList();

        setState(() {
          _availablePrinters = printers.map((r) => r.device).toList();
        });
      }
    } catch (e) {
      debugPrint("Error scanning: $e");
    } finally {
      // Always stop scan
      await FlutterBluePlus.stopScan();
      setState(() {
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: _printerService.isConnected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: _printerService.isConnected ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bluetooth,
                size: 18.sp,
                color: _printerService.isConnected ? Colors.green : Colors.grey,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  _printerService.isConnected
                      ? 'Connected to ${_printerService.connectedDeviceName}'
                      : 'Printer not connected',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _printerService.isConnected ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              OutlinedButton(
                onPressed: _isScanning
                    ? null
                    : () {
                  if (_printerService.isConnected) {
                    _printerService.disconnectPrinter();
                  } else {
                    _showPrinterSelectionDialog();
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: _isScanning
                    ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  _printerService.isConnected ? 'Disconnect' : 'Connect',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPrinterSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Select Printer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isScanning)
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16.h),
                      Text('Scanning for printers...'),
                    ],
                  ),
                )
              else if (_availablePrinters.isEmpty)
                Center(
                  child: Text('No printers found'),
                )
              else
                Container(
                  height: 200.h,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: _availablePrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _availablePrinters[index];
                      return ListTile(
                        leading: Icon(Icons.print),
                        title: Text(printer.name.isNotEmpty ? printer.name : 'Unknown Device'),
                        subtitle: Text(printer.id.id),
                        onTap: () async {
                          Navigator.pop(context);
                          final connected = await _printerService.connectToPrinter(printer);
                          if (!connected) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to connect to printer'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isScanning
                  ? null
                  : () async {
                setState(() {
                  _isScanning = true;
                });
                await _startScan();
                setState(() {
                  _isScanning = false;
                });
              },
              child: Text('Scan'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}