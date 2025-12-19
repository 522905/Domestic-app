import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import '../core/services/printer_service.dart';
import '../core/services/api_service_interface.dart';
import '../core/services/service_provider.dart';
import '../domain/entities/cash/cash_transaction.dart';
import '../presentation/widgets/professional_snackbar.dart';

class CashThermalPrintDialog extends StatefulWidget {
  final CashTransaction transaction;

  const CashThermalPrintDialog({
    super.key,
    required this.transaction,
  });

  @override
  State<CashThermalPrintDialog> createState() => _CashThermalPrintDialogState();
}

class _CashThermalPrintDialogState extends State<CashThermalPrintDialog> {
  final PrinterService _printerService = PrinterService();
  bool _isThermalPrinting = false;
  bool _isScanning = false;
  bool _isConnected = false;
  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  late ApiServiceInterface _apiService;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
    _listenToAdapterState();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ServiceProvider.getApiService();
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

  Future<void> _scanForPrinters({StateSetter? dialogSetState}) async {
    if (_isScanning) return;

    void refreshDialog() {
      if (dialogSetState != null) {
        try {
          dialogSetState(() {});
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
          final size = MediaQuery.of(context).size;

          return AlertDialog(
            title: const Text('Select Printer'),
            content: SizedBox(
              width: size.width * 0.8,
              height: size.height * 0.5,
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
    await _printerService.disconnectPrinter();
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
    });
    if (mounted) {
      context.showWarningSnackBar('Printer disconnected');
    }
  }

  Future<void> _handleThermalPrint() async {
    // Check approval status first
    if (widget.transaction.status != TransactionStatus.approved) {
      if (mounted) {
        context.showWarningSnackBar('Transaction must be approved before printing');
      }
      return;
    }

    // Check printer connection
    if (!_printerService.isConnected) {
      if (mounted) {
        context.showErrorSnackBar('Please connect to printer first');
      }
      return;
    }

    final macAddress = _printerService.connectedDeviceMacAddress;
    if (macAddress == null) {
      if (mounted) {
        context.showErrorSnackBar('Unable to get printer MAC address');
      }
      return;
    }

    setState(() => _isThermalPrinting = true);

    try {
      // Step 1: Fetch binary ESC/POS data from API
      final binaryData = await _apiService.thermalPrintPaymentRequest(
        widget.transaction.id,
        macAddress,
      );

      debugPrint('Received ${binaryData.length} bytes from API');

      // Step 2: Send binary data to printer
      final success = await _printerService.printBinaryData(binaryData);

      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Document printed successfully');
        } else {
          context.showErrorSnackBar('Failed to send data to printer');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          'Failed to print: ${e.toString().replaceAll('Exception: ', '')}'
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isThermalPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Printer Connection Status
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
        SizedBox(height: 12.h),
        // Thermal Print Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isConnected &&
                       !_isThermalPrinting &&
                       widget.transaction.status == TransactionStatus.approved
                ? _handleThermalPrint
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
            child: _isThermalPrinting
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
        ),
      ],
    );
  }
}
