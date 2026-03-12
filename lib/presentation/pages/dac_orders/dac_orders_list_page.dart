import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/dac_order_storage_service.dart';
import '../../../core/services/printer/printer_manager.dart';
import '../../../core/services/printer/printer_interface.dart';
import '../../../core/services/printer/printer_type.dart';
import '../../../core/services/printer/bluetooth_printer_service.dart';
import '../../../core/services/User.dart';
import '../../../domain/entities/dac_order/dac_order_entry.dart';
import '../../widgets/professional_snackbar.dart';
import 'dac_order_print_helper.dart';

class DacOrdersListPage extends StatefulWidget {
  const DacOrdersListPage({Key? key}) : super(key: key);

  @override
  State<DacOrdersListPage> createState() => _DacOrdersListPageState();
}

class _DacOrdersListPageState extends State<DacOrdersListPage> {
  final DacOrderStorageService _storageService = DacOrderStorageService();
  List<DacOrderEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    final entries = await _storageService.getAll();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  void _onEntryTap(DacOrderEntry entry) {
    _showReprintDialog(entry);
  }

  Future<void> _deleteEntry(DacOrderEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text(
          'Delete DAC order${entry.slipNumber > 0 ? ' #${entry.slipNumber}' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorsEnhanced.errorRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storageService.delete(entry.id);
      _loadEntries();
      if (mounted) context.showSuccessSnackBar('Entry deleted');
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All'),
        content: const Text(
          'Delete all DAC orders? This will also reset the slip counter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorsEnhanced.errorRed,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _storageService.deleteAll();
      _loadEntries();
      if (mounted) context.showSuccessSnackBar('All entries deleted');
    }
  }

  void _showReprintDialog(DacOrderEntry entry) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => _ReprintSheet(entry: entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAC Orders'),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Delete All',
              onPressed: _deleteAll,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadEntries,
                  child: ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.md),
                    itemCount: _entries.length,
                    itemBuilder: (context, index) =>
                        _buildEntryCard(_entries[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.pushNamed(context, '/dac-orders/add')
              .then((_) => _loadEntries());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64.sp,
            color: AppColorsEnhanced.secondaryText,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No DAC Orders yet',
            style: AppTextStyles.h4.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Tap + to add a new entry',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(DacOrderEntry entry) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(entry.createdAt);
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColorsEnhanced.errorRed,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.lg),
        child: Icon(Icons.delete, color: Colors.white, size: 24.sp),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Entry'),
            content: Text(
              'Delete DAC order${entry.slipNumber > 0 ? ' #${entry.slipNumber}' : ''}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColorsEnhanced.errorRed,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        await _storageService.delete(entry.id);
        _loadEntries();
        if (mounted) context.showSuccessSnackBar('Entry deleted');
      },
      child: Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: AppColorsEnhanced.border),
      ),
      child: InkWell(
        onTap: () => _onEntryTap(entry),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon with slip number
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: entry.slipNumber > 0
                      ? Text(
                          '#${entry.slipNumber}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColorsEnhanced.brandBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Icon(
                          Icons.assignment,
                          color: AppColorsEnhanced.brandBlue,
                          size: 20.sp,
                        ),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consumer info
                    if (entry.consumerId != null && entry.consumerId!.isNotEmpty)
                      _buildInfoRow('Consumer ID', entry.consumerId!),
                    if (entry.consumerNumber != null && entry.consumerNumber!.isNotEmpty)
                      _buildInfoRow('Consumer No', entry.consumerNumber!),
                    SizedBox(height: 2.h),
                    // DAC Code - highlighted
                    Row(
                      children: [
                        Text(
                          'DAC Code: ',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorsEnhanced.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            entry.dacCode,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColorsEnhanced.successGreen,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (entry.remark != null && entry.remark!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        entry.remark!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: 4.h),
                    // Timestamp + print icon
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12.sp,
                            color: AppColorsEnhanced.secondaryText),
                        SizedBox(width: 4.w),
                        Text(
                          dateStr,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.secondaryText,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.print_outlined, size: 16.sp,
                            color: AppColorsEnhanced.secondaryText),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for reprinting a DAC order slip
class _ReprintSheet extends StatefulWidget {
  final DacOrderEntry entry;
  const _ReprintSheet({required this.entry});

  @override
  State<_ReprintSheet> createState() => _ReprintSheetState();
}

class _ReprintSheetState extends State<_ReprintSheet> {
  final PrinterManager _printerManager = PrinterManager();
  PrinterInterface? _printer;
  PrinterType? _printerType;
  bool _isInitializing = true;
  bool _isPrinting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  List<BluetoothDevice> _printers = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initPrinter();
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
        if (mounted) setState(() => _isInitializing = false);
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
      debugPrint('ReprintSheet: Printer init error: $e');
    } finally {
      if (mounted) setState(() => _isInitializing = false);
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

  Future<void> _printSlip() async {
    if (_printer == null || !_isConnected) return;
    setState(() => _isPrinting = true);
    try {
      final userName = await User().getUserName() ?? 'Unknown';
      final bytes =
          DacOrderPrintHelper.buildSlipBytes(widget.entry, userName);
      final success = await _printer!.printBinaryData(bytes);
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Slip printed successfully');
          Navigator.pop(context);
        } else {
          context.showErrorSnackBar('Failed to print');
        }
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar('Print error: $e');
    } finally {
      if (mounted) setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd MMM yyyy, hh:mm a').format(widget.entry.createdAt);

    return Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Reprint DAC Slip',
            style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.md),
          Text(widget.entry.displayIdentifier,
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          Text('DAC Code: ${widget.entry.dacCode}',
              style: AppTextStyles.bodyMedium),
          if (widget.entry.remark?.isNotEmpty == true)
            Text('Remark: ${widget.entry.remark}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColorsEnhanced.secondaryText)),
          Text(dateStr,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColorsEnhanced.secondaryText)),
          SizedBox(height: AppSpacing.lg),
          if (_isInitializing)
            const Center(child: CircularProgressIndicator())
          else if (_printer == null)
            Center(
              child: Text('Printer not available',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColorsEnhanced.errorRed)),
            )
          else ...[
            // Printer status
            if (_printerType == PrinterType.sunmi)
              _buildStatusRow(
                  Icons.print, 'Sunmi Printer Ready', _isConnected)
            else ...[
              _buildStatusRow(Icons.bluetooth_connected,
                  _isConnected ? 'Printer Connected' : 'Not Connected',
                  _isConnected),
              if (!_isConnected) ...[
                SizedBox(height: AppSpacing.sm),
                if (_isScanning)
                  const Center(child: CircularProgressIndicator())
                else if (_printers.isNotEmpty)
                  ..._printers.map((p) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.print, color: Colors.blue),
                        title: Text(p.platformName.isNotEmpty
                            ? p.platformName
                            : 'Unknown'),
                        onTap: () => _connectToPrinter(p),
                      ))
                else
                  Center(
                    child: TextButton.icon(
                      onPressed: _scanForPrinters,
                      icon: const Icon(Icons.bluetooth_searching),
                      label: const Text('Scan for Printers'),
                    ),
                  ),
              ],
            ],
            SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnected && !_isPrinting ? _printSlip : null,
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
                  _isPrinting ? 'Printing...' : 'Print Slip',
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String text, bool connected) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: connected ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: connected ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20.sp,
              color: connected ? Colors.green : Colors.grey),
          SizedBox(width: 8.w),
          Text(text,
              style: TextStyle(
                fontSize: 12.sp,
                color: connected
                    ? Colors.green.shade700
                    : Colors.grey.shade700,
              )),
        ],
      ),
    );
  }
}
