import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
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

class _GatepassDialogState extends State<GatepassDialog>  {
  final PrinterService _printerService = PrinterService();
  bool _isPrinterConnected = false;
  bool _isPrinting = false;

  String _formatItemsList(InventoryRequest request) {
    final List<String> items = [];

    if (request.cylinders14kg > 0) {
      items.add('14.2kg: ${request.cylinders14kg}');
    }

    if (request.smallCylinders > 0) {
      items.add('5kg: ${request.smallCylinders}');
    }

    if (request.cylinders19kg > 0) {
      items.add('19kg: ${request.cylinders19kg}');
    }

    return items.join(' | ');
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    return formatter.format(now);
  }

  // Generate vehicle ID based on request
  String _getVehicleId() {
    // In a real app, you would fetch this from the request data
    return widget.request.id.contains('CL-')
        ? 'KA-01-AB-1234'
        : 'KA-02-CD-5678';
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

            // Bluetooth printer connection widget
            BluetoothPrinterWidget(
              onConnectionChanged: (isConnected) {
                setState(() {
                  _isPrinterConnected = isConnected;
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
                  child: const Text('PRINT GATEPASS'),
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