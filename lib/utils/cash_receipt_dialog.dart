import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/services/printer_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';

import '../core/services/User.dart';
import '../domain/entities/cash/cash_transaction.dart';
import '../presentation/widgets/professional_snackbar.dart';

class CashReceiptDialog extends StatefulWidget {
  final CashTransaction transaction;

  const CashReceiptDialog({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  State<CashReceiptDialog> createState() => _CashReceiptDialogState();
}

class _CashReceiptDialogState extends State<CashReceiptDialog> {
  final PrinterService _printerService = PrinterService();
  bool _isPrinting = false;
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

    debugPrint('Short Code: "$trimmedCode"');

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

  String _getFormattedDate(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    final local = dateTime.toLocal();
    final DateFormat formatter = DateFormat('MMM dd, yyyy • h:mm a');
    return formatter.format(local);
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
      setState(() {});
    }

    setState(() {
      _isScanning = true;
      _printers.clear();
    });
    refreshDialog();

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (mounted) {
          context.showWarningSnackBar('Please enable Bluetooth');
        }
        setState(() => _isScanning = false);
        refreshDialog();
        return;
      }

      if (FlutterBluePlus.isScanningNow) {
        await FlutterBluePlus.stopScan();
      }

      _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen(
            (results) {
          final Set<String> seenAddresses = {};
          final List<BluetoothDevice> uniquePrinters = [];

          for (var result in results) {
            final device = result.device;
            final name = device.platformName.toLowerCase();
            final address = device.remoteId.toString();

            if (!seenAddresses.contains(address) &&
                (name.contains('printer') || name.contains('pos') ||
                    name.contains('bt') || name.contains('rpp') ||
                    name.contains('mtp') || name.contains('escpos'))) {
              seenAddresses.add(address);
              uniquePrinters.add(device);
            }
          }

          setState(() {
            _printers = uniquePrinters;
          });
          refreshDialog();
        },
        onError: (error) {
          debugPrint('Scan error: $error');
          setState(() => _isScanning = false);
          refreshDialog();
        },
      );

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );

      await Future.delayed(const Duration(seconds: 10));

      setState(() => _isScanning = false);
      refreshDialog();
    } catch (e) {
      debugPrint('Scan exception: $e');
      setState(() {
        _isScanning = false;
      });
      refreshDialog();

      if (mounted) {
        context.showErrorSnackBar('Failed to scan: ${e.toString()}');
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    setState(() => _isScanning = false);

    bool success = await _printerService.connectToPrinter(device);

    if (success) {
      setState(() {
        _isConnected = true;
        _connectedDevice = device;
      });
      if (mounted) {
        context.showSuccessSnackBar('Connected to ${device.platformName}');
      }
    } else {
      if (mounted) {
        context.showErrorSnackBar('Failed to connect to ${device.platformName}');
      }
    }
  }

  void _showPrinterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text('Select Printer', style: TextStyle(fontSize: 16.sp)),
              content: SizedBox(
                width: double.maxFinite,
                height: 300.h,
                child: Column(
                  children: [
                    if (_isScanning)
                      Column(
                        children: [
                          const CircularProgressIndicator(),
                          SizedBox(height: 8.h),
                          Text('Scanning...', style: TextStyle(fontSize: 12.sp)),
                        ],
                      )
                    else if (_printers.isEmpty)
                      Column(
                        children: [
                          Icon(Icons.bluetooth_searching, size: 48.sp, color: Colors.grey),
                          SizedBox(height: 8.h),
                          Text('No printers found', style: TextStyle(fontSize: 12.sp)),
                        ],
                      ),
                    if (_printers.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _printers.length,
                          itemBuilder: (context, index) {
                            final printer = _printers[index];
                            return ListTile(
                              leading: const Icon(Icons.print),
                              title: Text(
                                printer.platformName.isNotEmpty
                                    ? printer.platformName
                                    : 'Unknown Printer',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                              subtitle: Text(
                                printer.remoteId.toString(),
                                style: TextStyle(fontSize: 11.sp),
                              ),
                              onTap: () {
                                Navigator.pop(dialogContext);
                                _connectToPrinter(printer);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: Icon(
                    _isScanning ? Icons.stop : Icons.refresh,
                    size: 16.sp,
                  ),
                  label: Text(_isScanning ? 'Stop Scan' : 'Scan Again'),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
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

  String _getTransactionTypeName(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.handover:
        return 'Handover';
      case TransactionType.bank:
        return 'Bank Deposit';
      default:
        return 'Transaction';
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _getFormattedDate(widget.transaction.createdAt);

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
                    'Print Receipt',
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConnected && !_isPrinting
                      ? () async {
                    setState(() => _isPrinting = true);
                    try {
                      final success = await _printerService.printCashReceipt(
                        widget.transaction,
                        formattedDate,
                        company: _companyType,
                      );

                      if (mounted) {
                        if (success) {
                          context.showSuccessSnackBar('Receipt printed successfully');
                        } else {
                          context.showErrorSnackBar('Failed to print receipt');
                        }
                      }
                    } finally {
                      if (mounted) setState(() => _isPrinting = false);
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
                  child: _isPrinting
                      ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.w,
                    ),
                  )
                      : Text('PRINT RECEIPT', style: TextStyle(fontSize: 14.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
