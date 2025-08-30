import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/core/services/printer_service.dart';

import 'bluethooth_printer_widget.dart';

class GatepassDialog extends StatefulWidget {
  final InventoryRequest request;

  const GatepassDialog({
    Key? key,
    required this.request,
  }) : super(key: key);

  @override
  State<GatepassDialog> createState() => _GatepassDialogState();
}

class _GatepassDialogState extends State<GatepassDialog> {
  final PrinterService _printerService = PrinterService();
  bool _isPrinting = false;
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  void _checkConnectionStatus() {
    setState(() {
      _isConnected = _printerService.isConnected;
    });
  }

  // Fix the items formatting - actually get items from request
  String _formatItemsList(InventoryRequest request) {
    final List<String> items = [];

    // Add items based on your InventoryRequest structure
    // Adjust these based on your actual request model properties
    if (request.items != null && request.items!.isNotEmpty) {
      for (var item in request.items!) {
        // items.add('${item.name} (${item.quantity})');
      }
    } else {
      // Fallback if items is null/empty
      items.add('Collection items');
    }

    return items.join(' | ');
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    return formatter.format(now);
  }

  String _getVehicleId() {
    // Use actual vehicle data from request if available
    return 'KA-01-AB-1234';
  }

  Future<void> _scanForPrinters() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _printers.clear();
    });

    try {
      // Check if Bluetooth is on
      bool isOn = await FlutterBluePlus.isOn;
      if (!isOn) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please turn on Bluetooth')),
        );
        return;
      }

      // Simple scan without complex timeout logic
      FlutterBluePlus.scanResults.listen((results) {
        final printers = <BluetoothDevice>[];
        for (ScanResult result in results) {
          if (result.device.name.isNotEmpty &&
              (result.device.name.toLowerCase().contains('printer') ||
                  result.device.name.toLowerCase().contains('tvs') ||
                  result.device.name.toLowerCase().contains('mlp'))) {
            printers.add(result.device);
          }
        }
        if (mounted) {
          setState(() {
            _printers = printers;
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: Duration(seconds: 8));

    } catch (e) {
      debugPrint("Scan error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    try {
      final success = await _printerService.connectToPrinter(device);
      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
        });
        Navigator.pop(context); // Close the printer selection dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connected to ${device.name}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to printer')),
        );
      }
    } catch (e) {
      debugPrint("Connection error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Select Printer'),
          content: Container(
            height: 300.h,
            width: 300.w,
            child: Column(
              children: [
                if (_isScanning)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16.h),
                        Text('Scanning...'),
                      ],
                    ),
                  )
                else if (_printers.isEmpty)
                  Center(child: Text('No printers found'))
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _printers.length,
                      itemBuilder: (context, index) {
                        final printer = _printers[index];
                        return ListTile(
                          leading: Icon(Icons.print),
                          title: Text(printer.name),
                          subtitle: Text(printer.id.id),
                          onTap: () => _connectToPrinter(printer),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isScanning ? null : () => _scanForPrinters(),
              child: Text(_isScanning ? 'Scanning...' : 'Scan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate();
    final vehicleId = _getVehicleId();
    final driverName = widget.request.requestedBy;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gatepass',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'For Collection #${widget.request.id}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _gatepassRow('Date & Time:', formattedDate),
                  _gatepassRow('Vehicle:', vehicleId),
                  _gatepassRow('Driver:', driverName),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.brown[600],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _formatItemsList(widget.request),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Simplified printer connection status
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: _isConnected ? Colors.green.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bluetooth,
                    size: 18.sp,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isConnected
                          ? 'Connected to ${_connectedDevice?.name ?? "Printer"}'
                          : 'Printer not connected',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: _isConnected ? Colors.green.shade700 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      if (_isConnected) {
                        _printerService.disconnectPrinter();
                        setState(() {
                          _isConnected = false;
                          _connectedDevice = null;
                        });
                      } else {
                        _showPrinterDialog();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                    ),
                    child: Text(
                      _isConnected ? 'Disconnect' : 'Connect',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  onPressed: _isConnected
                      ? () async {
                    setState(() {
                      _isPrinting = true;
                    });

                    try {
                      final success = await _printerService.printGatepass(
                          widget.request,
                          formattedDate,
                          vehicleId,
                          driverName
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gatepass printed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to print gatepass'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isPrinting = false;
                        });
                      }
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: _isPrinting
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                      : const Text('PRINT GATEPASS'),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gatepassRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.brown[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


/// only for transferring gatepass
class SimpleGatepassDialog extends StatefulWidget {
  final Map<String, dynamic> gatepassData;

  const SimpleGatepassDialog({
    Key? key,
    required this.gatepassData,
  }) : super(key: key);

  @override
  State<SimpleGatepassDialog> createState() => _SimpleGatepassDialogState();
}

class _SimpleGatepassDialogState extends State<SimpleGatepassDialog> {
  final PrinterService _printerService = PrinterService();
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gatepass',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Gatepass #${widget.gatepassData['gatepassNo']}',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.green[700],
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  _gatepassRow('Date:', widget.gatepassData['date']),
                  _gatepassRow('Time:', widget.gatepassData['time']),
                  _gatepassRow('From:', widget.gatepassData['from']),
                  _gatepassRow('To:', widget.gatepassData['to']),
                  _gatepassRow('Driver:', widget.gatepassData['driver']),
                  _gatepassRow('Phone:', widget.gatepassData['phone']),
                  _gatepassRow('Vehicle:', widget.gatepassData['vehicle']),
                  SizedBox(height: 8.h),
                  Text(
                    'Items:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._buildItemsList(widget.gatepassData['items']),
                  SizedBox(height: 8.h),
                  _gatepassRow('Authorized By:', widget.gatepassData['authorizedBy']),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Bluetooth printer connection widget
            BluetoothPrinterWidget(
              onConnectionChanged: (isConnected) {
                setState(() {
                  // Update printer connection state if needed
                });
              },
            ),

            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    child: Text(
                      'CLOSE',
                      style: TextStyle(
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                ElevatedButton(
                  onPressed: _printerService.isConnected
                      ? () async {
                    setState(() {
                      _isPrinting = true;
                    });

                    try {
                      // Using the existing PrinterService but with Map data
                      final success = await _printerService.printSimpleGatepass(
                        widget.gatepassData,
                      );

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gatepass printed successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to print gatepass'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isPrinting = false;
                        });
                      }
                    }
                  }
                      : null, // Disabled if not connected
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: _isPrinting
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                      : Text(
                    'PRINT GATEPASS',
                    style: TextStyle(
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gatepassRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.brown[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItemsList(List<dynamic> items) {
    return items
        .map((item) => Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            item['name'],
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.brown[600],
            ),
          ),
          Text(
            'Quantity: ${item['quantity']}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ))
        .toList();
  }
}