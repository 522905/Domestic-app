import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/core/services/printer_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

import '../core/services/User.dart';
import '../presentation/widgets/professional_snackbar.dart';

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
  bool _isSlipPrinting = false;
  bool _isChallanPrinting = false;
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  String _companyType = 'arungas';

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
    _listenToAdapterState();
    _loadCompany();
  }

  Future<void> _loadCompany() async {
    final shortCode = await User().getActiveCompanyShortCode();
    final trimmedCode = shortCode?.trim() ?? '';

    debugPrint('Short Code: "$trimmedCode"'); // Check for whitespace

    setState(() {
      _companyType = shortCode?.trim().toUpperCase() == 'AG' ? 'arungas' : 'arunindane';
    });

  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  void _listenToAdapterState() {
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (state != BluetoothAdapterState.on && _isScanning) {
        setState(() {
          _isScanning = false;
          _printers.clear();
        });
      }
    });
  }

  void _checkConnectionStatus() {
    setState(() {
      _isConnected = _printerService.isConnected;
    });
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final DateFormat formatter = DateFormat('MMM d, yyyy h:mm a');
    return formatter.format(now);
  }

  String _getVehicleId() {
    // Use actual vehicle data from request if available
    return widget.request.vehicle ?? 'N/A';
  }

  Future<void> _scanForPrinters({StateSetter? dialogSetState}) async {
    if (_isScanning) return;

    void refreshDialog() {
      if (dialogSetState != null) {
        try {
          dialogSetState!(() {});
        } catch (e) {
          debugPrint('Dialog refresh error: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _isScanning = true;
        _printers.clear();
      });
    }
    refreshDialog();

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (mounted) {
          context.showWarningSnackBar('Please turn on Bluetooth');
        }
        if (mounted) setState(() => _isScanning = false);
        refreshDialog();
        return;
      }

      await _scanSubscription?.cancel();

      _scanSubscription = FlutterBluePlus.scanResults.listen(
            (results) {
          if (!mounted) return;

          final foundPrinters = <BluetoothDevice>[];
          for (var result in results) {
            final name = result.device.platformName.toLowerCase();
            if (result.device.platformName.isNotEmpty &&
                (name.contains('printer') ||
                    name.contains('tvs') ||
                    name.contains('mlp') ||
                    name.contains('rpp') ||
                    name.contains('pos'))) {
              if (!foundPrinters.any((d) => d.remoteId == result.device.remoteId)) {
                foundPrinters.add(result.device);
              }
            }
          }

          if (mounted) {
            setState(() {
              _printers = foundPrinters;
              if (foundPrinters.isNotEmpty) {
                _isScanning = false;
              }
            });
            refreshDialog();
          }

          if (foundPrinters.isNotEmpty) {
            unawaited(FlutterBluePlus.stopScan());
          }
        },
        onError: (error) {
          debugPrint('Scan error: $error');
          if (mounted) {
            setState(() => _isScanning = false);
            refreshDialog();
          }
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      // Auto-stop after timeout
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        await FlutterBluePlus.stopScan();
        setState(() => _isScanning = false);
        refreshDialog();
      }
    } catch (e) {
      debugPrint('Scan error: $e');
      if (mounted) {
        setState(() => _isScanning = false);
        refreshDialog();
        context.showErrorSnackBar('Scan failed: $e');
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success = await _printerService.connectToPrinter(device);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        setState(() {
          _isConnected = true;
          _connectedDevice = device;
        });

        // Close printer selection dialog
        if (mounted) Navigator.pop(context);

        if (mounted) {
          context.showSuccessSnackBar('Connected to ${device.platformName}');
        }
      } else {
        if (mounted) {
          context.showErrorSnackBar('Failed to connect to printer');
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) Navigator.pop(context);

      debugPrint('Connection error: $e');
      if (mounted) {
        context.showErrorSnackBar('Connection error: $e');
      }
    }
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Select Printer'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
                maxWidth: double.infinity,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  if (_isScanning)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 16.h),
                          const Text('Scanning for printers...'),
                        ],
                      ),
                    )
                  else if (_printers.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text('No printers found.\nTap Scan to search.'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _printers.length,
                        itemBuilder: (context, index) {
                          final printer = _printers[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.print, color: Colors.blue),
                              title: Text(
                                printer.platformName.isNotEmpty
                                    ? printer.platformName
                                    : 'Unknown Printer',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                printer.remoteId.str,
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _connectToPrinter(printer),
                            ),
                          );
                        },
                      ),
                    ),
                ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
                label: Text(_isScanning ? 'Stop' : 'Scan'),
                onPressed: _isScanning
                    ? () async {
                    await FlutterBluePlus.stopScan();
                    if (mounted) {
                      setState(() => _isScanning = false);
                    }
                    setDialogState(() {});
                  }
                    : () {
                  _scanForPrinters(dialogSetState: setDialogState);
                },
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _disconnectPrinter() async {
    await _printerService.disconnectPrinter();
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
    });
    if (mounted) {
      context.showWarningSnackBar('Printer disconnected');
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate();
    final vehicleId = _getVehicleId();
    final driverName = widget.request.requestedBy;
    return Container(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                      Icon(
                          Icons.print,
                          size: 20.sp,
                          color: const Color(0xFF0E5CA8),
                    ),
                    SizedBox(width: 8.w),
                        Text(
                            'Print Gatepass',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0E5CA8),
                            ),
                        ),
                    ],
              ),
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(6.w),
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
                      _isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
                      size: 20.sp,
                      color: _isConnected ? Colors.green : Colors.grey,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _isConnected
                            ? 'Connected to ${_connectedDevice?.platformName ?? "Printer"}'
                            : 'Printer not connected',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: _isConnected ? Colors.green.shade700 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _isConnected ? _disconnectPrinter : _showPrinterDialog,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: Text(
                        _isConnected ? 'Disconnect' : 'Connect',
                        style: TextStyle(fontSize: 11.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConnected && !_isSlipPrinting && !_isChallanPrinting
                          ? () async {
                        setState(() => _isSlipPrinting = true);
                        try {
                          final success = await _printerService.printSlip(
                            widget.request,
                            formattedDate,
                            vehicleId,
                            driverName,
                            company: _companyType, // Use dynamic value
                          );

                          if (mounted) {
                            if (success) {
                              context.showSuccessSnackBar('Slip printed successfully');
                            } else {
                              context.showErrorSnackBar('Failed to print slip');
                            }
                          }
                        } finally {
                          if (mounted) setState(() => _isSlipPrinting = false);
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: _isSlipPrinting
                        ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                          : Text('PRINT SLIP', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isConnected && !_isSlipPrinting && !_isChallanPrinting
                          ? () async {
                        setState(() => _isChallanPrinting = true);
                        try {
                          final success = await _printerService.printGatepass(
                            widget.request,
                            formattedDate,
                            vehicleId,
                            driverName,
                            company: _companyType, // Use dynamic value
                          );

                          if (mounted) {
                            if (success) {
                              context.showSuccessSnackBar('Challan printed successfully');
                            } else {
                              context.showErrorSnackBar('Failed to print challan');
                            }
                          }
                        } finally {
                          if (mounted) setState(() => _isChallanPrinting = false);
                        }
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                      ),
                      child: _isChallanPrinting
                          ? SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.w,
                        ),
                      )
                          : Text('PRINT CHALLAN', style: TextStyle(fontSize: 14.sp)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

