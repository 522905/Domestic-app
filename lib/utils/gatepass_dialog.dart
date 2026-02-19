import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/core/services/printer/printer_manager.dart';
import 'package:lpg_distribution_app/core/services/printer/printer_interface.dart';
import 'package:lpg_distribution_app/core/services/printer/printer_type.dart';
import 'package:lpg_distribution_app/core/services/printer/bluetooth_printer_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

import '../core/services/api_service_interface.dart';
import '../core/services/service_provider.dart';
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
  final PrinterManager _printerManager = PrinterManager();
  PrinterInterface? _printer;
  PrinterType? _printerType;
  bool _isInitializing = true;
  bool _isThermalPrintingChallan = false;
  bool _isThermalPrintingSlip = false;
  late ApiServiceInterface _apiService;
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _initPrinter();
    _listenToAdapterState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ServiceProvider.getApiService();
  }

  Future<void> _initPrinter() async {
    if (!mounted) return;
    setState(() => _isInitializing = true);

    try {
      await _printerManager.initialize();
      _printer = await _printerManager.getPrinter();

      if (_printer == null) {
        debugPrint('GatepassDialog: Printer initialization failed - printer is null');
        if (mounted) {
          setState(() => _isInitializing = false);
        }
        return;
      }

      _printerType = _printer!.printerType;
      debugPrint('GatepassDialog: Detected printer type: $_printerType');

      // For Sunmi, auto-connect
      if (_printerType == PrinterType.sunmi) {
        final connected = await _printer!.connect();
        if (mounted) {
          setState(() {
            _isConnected = connected;
          });
        }
        debugPrint('GatepassDialog: Sunmi printer connected: $connected');
      } else {
        // For Bluetooth, check existing connection
        _checkConnectionStatus();
      }
    } catch (e) {
      debugPrint('GatepassDialog: Printer initialization error: $e');
      if (mounted) {
        setState(() {
          _printer = null;
          _printerType = null;
          _isConnected = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  void _checkConnectionStatus() {
    // Only for Bluetooth
    if (_printer is BluetoothPrinterService) {
      setState(() {
        _isConnected = (_printer as BluetoothPrinterService).isConnected;
      });
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    // Only stop Bluetooth scan if we were using Bluetooth
    if (_printerType != PrinterType.sunmi) {
      try {
        FlutterBluePlus.stopScan();
      } catch (e) {
        debugPrint('GatepassDialog: Error stopping Bluetooth scan: $e');
      }
    }
    super.dispose();
  }

  void _listenToAdapterState() {
    // Only listen to Bluetooth adapter state if we're not on Sunmi
    // Sunmi devices don't need Bluetooth monitoring
    _adapterStateSubscription = FlutterBluePlus.adapterState.listen((state) {
      if (_printerType == PrinterType.sunmi) return; // Skip for Sunmi
      if (state != BluetoothAdapterState.on && _isScanning) {
        if (mounted) {
          setState(() {
            _isScanning = false;
            _printers.clear();
          });
        }
      }
    });
  }

  Future<void> _scanForPrinters({StateSetter? dialogSetState}) async {
    // Don't scan if we're on Sunmi device
    if (_printerType == PrinterType.sunmi) {
      debugPrint('GatepassDialog: Scan not available on Sunmi device');
      return;
    }

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
              // Don't stop scanning - let it continue to find all printers
            });
            refreshDialog();
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
      // Stop scanning when user selects a printer
      await FlutterBluePlus.stopScan();
      if (mounted) {
        setState(() => _isScanning = false);
      }

      // Check if printer is available and is Bluetooth type
      if (_printer == null) {
        if (mounted) {
          context.showErrorSnackBar('Printer not initialized');
        }
        return;
      }

      if (_printer is! BluetoothPrinterService) {
        debugPrint('GatepassDialog: Printer is not BluetoothPrinterService, type: ${_printer.runtimeType}');
        if (mounted) {
          context.showErrorSnackBar('Cannot connect: Wrong printer type');
        }
        return;
      }

      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Safe cast to BluetoothPrinterService
      final bluetoothPrinter = _printer as BluetoothPrinterService;
      final success = await bluetoothPrinter.connectToPrinter(device);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          setState(() {
            _isConnected = true;
            _connectedDevice = device;
          });
        }

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
      if (mounted) {
        try {
          Navigator.pop(context);
        } catch (_) {
          // Dialog already closed
        }
      }

      debugPrint('GatepassDialog: Connection error: $e');
      if (mounted) {
        context.showErrorSnackBar('Connection error: $e');
      }
    }
  }

  void _showPrinterDialog() {
    // Don't show printer dialog on Sunmi devices (they auto-connect)
    if (_printerType == PrinterType.sunmi) {
      debugPrint('GatepassDialog: Printer dialog not needed on Sunmi device');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final size = MediaQuery.of(context).size;

          return AlertDialog(
            title: const Text('Select Printer'),
            // IMPORTANT: use SizedBox with explicit width & height
            content: SizedBox(
              width: size.width * 0.8,          // fixed width
              height: size.height * 0.5,        // fixed height
              child: _isScanning
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16),
                    const Text('Scanning for printers...'),
                  ],
                ),
              )
                  : _printers.isEmpty
                  ? const Center(
                child: Text('No printers found.\nTap Scan to search.'),
              )
                  : ListView.builder(
                // VERY IMPORTANT: no shrinkWrap here
                // shrinkWrap: true,  // <- REMOVE THIS
                itemCount: _printers.length,
                itemBuilder: (context, index) {
                  final printer = _printers[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.print,
                        color: Colors.blue,
                      ),
                      title: Text(
                        printer.platformName.isNotEmpty
                            ? printer.platformName
                            : 'Unknown Printer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        printer.remoteId.str,
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _connectToPrinter(printer),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton.icon(
                icon: Icon(
                  _isScanning ? Icons.stop : Icons.bluetooth_searching,
                ),
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
    if (_printer != null) {
      await _printer!.disconnect();
    }
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
    });
    if (mounted) {
      context.showWarningSnackBar('Printer disconnected');
    }
  }

  Future<void> _handleThermalPrintChallan() async {
    // Check approval status first
    if (widget.request.status.toUpperCase() != 'APPROVED') {
      if (mounted) {
        context.showWarningSnackBar('Request must be approved before printing');
      }
      return;
    }

    // Check printer availability
    if (_printer == null) {
      if (mounted) {
        context.showErrorSnackBar('Printer not initialized');
      }
      return;
    }

    // Check connection
    if (!_printer!.currentStatus.isConnected) {
      if (mounted) {
        context.showErrorSnackBar('Please connect to printer first');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isThermalPrintingChallan = true);

    try {
      debugPrint('GatepassDialog: Printing challan via ${_printer!.printerType}');
      debugPrint('GatepassDialog: Device ID: ${_printer!.deviceIdentifier}');
      debugPrint('GatepassDialog: Paper width: ${_printer!.paperWidthMm}mm');

      // Fetch binary data from API with device info
      final binaryData = await _apiService.thermalPrintStockRequest(
        widget.request.id,
        'gatepass',
        _printer!.deviceIdentifier,
        _printer!.paperWidthMm,
      );

      debugPrint('GatepassDialog: Received ${binaryData.length} bytes from API');

      // Print via current printer (Bluetooth or Sunmi)
      final success = await _printer!.printBinaryData(binaryData);

      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Challan printed successfully');
        } else {
          context.showErrorSnackBar('Failed to send data to printer');
        }
      }
    } catch (e) {
      debugPrint('GatepassDialog: Print error: $e');
      if (mounted) {
        context.showErrorSnackBar(
          'Failed to print: ${e.toString().replaceAll('Exception: ', '')}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isThermalPrintingChallan = false);
      }
    }
  }

  Future<void> _handleThermalPrintSlip() async {
    // Check approval status first
    if (widget.request.status.toUpperCase() != 'APPROVED') {
      if (mounted) {
        context.showWarningSnackBar('Request must be approved before printing');
      }
      return;
    }

    // Check printer availability
    if (_printer == null) {
      if (mounted) {
        context.showErrorSnackBar('Printer not initialized');
      }
      return;
    }

    // Check connection
    if (!_printer!.currentStatus.isConnected) {
      if (mounted) {
        context.showErrorSnackBar('Please connect to printer first');
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isThermalPrintingSlip = true);

    try {
      debugPrint('GatepassDialog: Printing slip via ${_printer!.printerType}');
      debugPrint('GatepassDialog: Device ID: ${_printer!.deviceIdentifier}');
      debugPrint('GatepassDialog: Paper width: ${_printer!.paperWidthMm}mm');

      // Fetch binary data from API with device info
      final binaryData = await _apiService.thermalPrintStockRequest(
        widget.request.id,
        'warehouse_slip',
        _printer!.deviceIdentifier,
        _printer!.paperWidthMm,
      );

      debugPrint('GatepassDialog: Received ${binaryData.length} bytes from API');

      // Print via current printer (Bluetooth or Sunmi)
      final success = await _printer!.printBinaryData(binaryData);

      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Slip printed successfully');
        } else {
          context.showErrorSnackBar('Failed to send data to printer');
        }
      }
    } catch (e) {
      debugPrint('GatepassDialog: Print error: $e');
      if (mounted) {
        context.showErrorSnackBar(
          'Failed to print: ${e.toString().replaceAll('Exception: ', '')}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isThermalPrintingSlip = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If printer initialization failed completely
    if (_printer == null || _printerType == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48.sp,
                color: Colors.orange,
              ),
              SizedBox(height: 16.h),
              Text(
                'Printer Initialization Failed',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Unable to detect printer. Please restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: () => _initPrinter(),
                icon: Icon(Icons.refresh, size: 18.sp),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
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
            // Route based on printer type
            if (_printerType == PrinterType.sunmi)
              _buildSunmiPrintUI()
            else
              _buildBluetoothPrintUI(),
          ],
        ),
      ),
    );
  }

  Widget _buildSunmiPrintUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sunmi status indicator
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.print, size: 20.sp, color: Colors.green),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'Sunmi Built-in Printer Ready',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        // Print buttons based on request type
        _buildPrintButtons(),
      ],
    );
  }

  Widget _buildBluetoothPrintUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Connection status container
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
        // Print buttons based on request type
        _buildPrintButtons(),
      ],
    );
  }

  Widget _buildPrintButtons() {
    return Column(
      children: [
        // Show different buttons based on request type
        if (widget.request.requestType.toUpperCase() == 'DEPOSIT')
          // Single button for DEPOSIT requests
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isConnected &&
                         !_isThermalPrintingChallan &&
                         widget.request.status.toUpperCase() == 'APPROVED'
                  ? _handleThermalPrintChallan
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
              child: _isThermalPrintingChallan
                  ? SizedBox(
                      height: 20.h,
                      width: 20.w,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.w,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.print_outlined, size: 18.sp),
                        SizedBox(width: 8.w),
                        Text('THERMAL PRINT', style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
            ),
          )
        else
          // Two buttons for COLLECT requests
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isConnected &&
                             !_isThermalPrintingChallan &&
                             !_isThermalPrintingSlip &&
                             widget.request.status.toUpperCase() == 'APPROVED'
                      ? _handleThermalPrintChallan
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
                  child: _isThermalPrintingChallan
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_outlined, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text('THERMAL CHALLAN', style: TextStyle(fontSize: 12.sp)),
                          ],
                        ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isConnected &&
                             !_isThermalPrintingChallan &&
                             !_isThermalPrintingSlip &&
                             widget.request.status.toUpperCase() == 'APPROVED'
                      ? _handleThermalPrintSlip
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
                  child: _isThermalPrintingSlip
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print_outlined, size: 18.sp),
                            SizedBox(width: 8.w),
                            Text('THERMAL SLIP', style: TextStyle(fontSize: 14.sp)),
                          ],
                        ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

