import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/printer/printer_manager.dart';
import '../../../../core/services/printer/printer_interface.dart';
import '../../../../core/services/printer/printer_type.dart';
import '../../../../core/services/printer/bluetooth_printer_service.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../core/services/service_provider.dart';
import '../../../../domain/entities/offline_delivery/booking_verification.dart';
import '../../../widgets/professional_snackbar.dart';

class BookingReceiptSheet extends StatefulWidget {
  final BookingVerification verification;

  const BookingReceiptSheet({Key? key, required this.verification}) : super(key: key);

  @override
  State<BookingReceiptSheet> createState() => _BookingReceiptSheetState();
}

class _BookingReceiptSheetState extends State<BookingReceiptSheet> {
  final PrinterManager _printerManager = PrinterManager();
  PrinterInterface? _printer;
  PrinterType? _printerType;
  bool _isPrinterInitializing = true;
  bool _isPrinting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  List<BluetoothDevice> _printers = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  late ApiServiceInterface _apiService;

  @override
  void initState() {
    super.initState();
    _initPrinter();
    _initApiService();
  }

  Future<void> _initApiService() async {
    _apiService = await ServiceProvider.getApiService();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    if (_printerType != PrinterType.sunmi) {
      try {
        FlutterBluePlus.stopScan();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _initPrinter() async {
    try {
      await _printerManager.initialize();
      _printer = await _printerManager.getPrinter();
      if (_printer == null) {
        if (mounted) setState(() => _isPrinterInitializing = false);
        return;
      }
      _printerType = _printer!.printerType;
      if (_printerType == PrinterType.sunmi) {
        final connected = await _printer!.connect();
        if (mounted) setState(() => _isConnected = connected);
      } else if (_printer is BluetoothPrinterService) {
        if (mounted) {
          setState(() {
            _isConnected = (_printer as BluetoothPrinterService).isConnected;
          });
        }
      }
    } catch (e) {
      debugPrint('BookingReceiptSheet: Printer init error: $e');
    } finally {
      if (mounted) setState(() => _isPrinterInitializing = false);
    }
  }

  Future<void> _scanForPrinters() async {
    if (_printerType == PrinterType.sunmi || _isScanning) return;
    setState(() {
      _isScanning = true;
      _printers.clear();
    });

    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        if (mounted) context.showWarningSnackBar('Please turn on Bluetooth');
        if (mounted) setState(() => _isScanning = false);
        return;
      }

      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (!mounted) return;
        final found = <BluetoothDevice>[];
        for (var r in results) {
          final name = r.device.platformName.toLowerCase();
          if (r.device.platformName.isNotEmpty &&
              (name.contains('printer') ||
                  name.contains('tvs') ||
                  name.contains('mlp') ||
                  name.contains('rpp') ||
                  name.contains('pos'))) {
            if (!found.any((d) => d.remoteId == r.device.remoteId)) {
              found.add(r.device);
            }
          }
        }
        if (mounted) setState(() => _printers = found);
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: false,
      );
      await Future.delayed(const Duration(seconds: 10));
      if (mounted) {
        await FlutterBluePlus.stopScan();
        setState(() => _isScanning = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        context.showErrorSnackBar('Scan failed: $e');
      }
    }
  }

  Future<void> _connectToPrinter(BluetoothDevice device) async {
    if (_printer is! BluetoothPrinterService) return;
    try {
      await FlutterBluePlus.stopScan();
      if (mounted) setState(() => _isScanning = false);

      final bluetoothPrinter = _printer as BluetoothPrinterService;
      final success = await bluetoothPrinter.connectToPrinter(device);
      if (mounted) {
        setState(() => _isConnected = success);
        if (success) {
          context.showSuccessSnackBar('Connected to ${device.platformName}');
        } else {
          context.showErrorSnackBar('Failed to connect');
        }
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Connection error: $e');
    }
  }

  Future<void> _printReceipt() async {
    if (_printer == null || !_isConnected) return;
    setState(() => _isPrinting = true);
    try {
      final binaryData = await _apiService.thermalPrintBookingVerification(
        widget.verification.id,
        _printer!.deviceIdentifier,
        _printer!.paperWidthMm,
      );
      final success = await _printer!.printBinaryData(binaryData);
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Receipt printed successfully');
        } else {
          context.showErrorSnackBar('Failed to print');
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar(
          'Print error: ${e.toString().replaceAll('Exception: ', '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.verification;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Title
                Center(
                  child: Text(
                    'Booking Receipt',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Consumer info
                if (v.company != null)
                  _buildInfoRow('Company', v.company!.name),
                if (v.consumerName != null)
                  _buildInfoRow('Name', v.consumerName!),
                if (v.consumerId != null)
                  _buildInfoRow('Consumer ID', v.consumerId!),
                if (v.consumerNumber != null)
                  _buildInfoRow('Consumer No', v.consumerNumber!),
                if (v.orderNumberFromRpa != null || v.orderNumber != null)
                  _buildInfoRow('Order #', v.orderNumberFromRpa ?? v.orderNumber!),
                _buildInfoRow('Date', DateFormat('dd/MM/yyyy').format(v.createdAt ?? DateTime.now())),
                SizedBox(height: AppSpacing.sm),

                // Financial
                if (v.cashToCollect != null)
                  _buildInfoRow('Cash to Collect', 'Rs. ${v.cashToCollect!.toStringAsFixed(2)}'),
                if (v.digitalAmount != null)
                  _buildInfoRow('Digital Amount', 'Rs. ${v.digitalAmount!.toStringAsFixed(2)}'),
                SizedBox(height: AppSpacing.xl),

                // Printer section
                _buildPrinterSection(),

                SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterSection() {
    if (_isPrinterInitializing) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 18.h,
              width: 18.w,
              child: CircularProgressIndicator(strokeWidth: 2.w),
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Initializing printer...',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColorsEnhanced.secondaryText)),
          ],
        ),
      );
    }

    if (_printer == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColorsEnhanced.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print_disabled, size: 18.sp, color: Colors.grey),
            SizedBox(width: AppSpacing.sm),
            Text('Printer not available',
                style: AppTextStyles.labelSmall
                    .copyWith(color: AppColorsEnhanced.secondaryText)),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Printer status row
          if (_printerType == PrinterType.sunmi)
            _buildPrinterStatus(Icons.print, 'Sunmi Printer Ready', _isConnected)
          else ...[
            _buildPrinterStatus(
              Icons.bluetooth_connected,
              _isConnected ? 'Printer Connected' : 'Not Connected',
              _isConnected,
            ),
            if (!_isConnected) ...[
              Divider(height: 1, color: AppColorsEnhanced.border),
              if (_isScanning)
                Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 18.h,
                        width: 18.w,
                        child: CircularProgressIndicator(strokeWidth: 2.w),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text('Scanning...',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColorsEnhanced.secondaryText)),
                    ],
                  ),
                )
              else if (_printers.isNotEmpty)
                ..._printers.map((p) => InkWell(
                      onTap: () => _connectToPrinter(p),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.print, color: AppColorsEnhanced.brandBlue, size: 18.sp),
                            SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                p.platformName.isNotEmpty ? p.platformName : 'Unknown',
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 18.sp, color: AppColorsEnhanced.secondaryText),
                          ],
                        ),
                      ),
                    ))
              else
                InkWell(
                  onTap: _scanForPrinters,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bluetooth_searching,
                            size: 18.sp, color: AppColorsEnhanced.brandBlue),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Scan for Printers',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColorsEnhanced.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],

          // Print button
          if (_isConnected) ...[
            Divider(height: 1, color: AppColorsEnhanced.border),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: !_isPrinting ? _printReceipt : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorsEnhanced.brandBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  icon: _isPrinting
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.w,
                          ),
                        )
                      : Icon(Icons.print, size: 20.sp),
                  label: Text(
                    _isPrinting ? 'Printing...' : 'Print Receipt',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrinterStatus(IconData icon, String text, bool connected) {
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20.sp,
              color: connected ? AppColorsEnhanced.successGreen : Colors.grey),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text,
                style: AppTextStyles.labelSmall.copyWith(
                  color: connected
                      ? AppColorsEnhanced.successGreen
                      : AppColorsEnhanced.secondaryText,
                  fontWeight: FontWeight.w600,
                )),
          ),
          if (!connected && _printerType != PrinterType.sunmi && _printers.isEmpty && !_isScanning)
            InkWell(
              onTap: _scanForPrinters,
              child: Icon(Icons.refresh, size: 18.sp, color: AppColorsEnhanced.brandBlue),
            ),
        ],
      ),
    );
  }
}
