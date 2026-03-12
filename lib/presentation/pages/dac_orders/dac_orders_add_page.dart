import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class DacOrdersAddPage extends StatefulWidget {
  const DacOrdersAddPage({Key? key}) : super(key: key);

  @override
  State<DacOrdersAddPage> createState() => _DacOrdersAddPageState();
}

class _DacOrdersAddPageState extends State<DacOrdersAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _consumerIdController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _dacCodeController = TextEditingController();
  final _remarkController = TextEditingController();

  final DacOrderStorageService _storageService = DacOrderStorageService();
  final PrinterManager _printerManager = PrinterManager();

  bool _submitSuccess = false;
  bool _isSubmitting = false;
  DacOrderEntry? _lastSubmitted;

  // Printer state
  PrinterInterface? _printer;
  PrinterType? _printerType;
  bool _isPrinterInitializing = true;
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
    _consumerIdController.dispose();
    _consumerNumberController.dispose();
    _dacCodeController.dispose();
    _remarkController.dispose();
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
      debugPrint('DacOrdersAdd: Printer init error: $e');
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

  /// Returns true if submit succeeded, false if validation failed.
  Future<bool> _handleSubmit() async {
    if (_isSubmitting) return false;

    if (!_formKey.currentState!.validate()) return false;

    final consumerId = _consumerIdController.text.trim();
    final consumerNumber = _consumerNumberController.text.trim();

    if (consumerId.isEmpty && consumerNumber.isEmpty) {
      context.showWarningSnackBar(
          'At least one of Consumer ID or Consumer Number is required');
      return false;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final entry = DacOrderEntry(
        id: now.millisecondsSinceEpoch.toString(),
        consumerId: consumerId.isNotEmpty ? consumerId : null,
        consumerNumber: consumerNumber.isNotEmpty ? consumerNumber : null,
        dacCode: _dacCodeController.text.trim(),
        remark: _remarkController.text.trim().isNotEmpty
            ? _remarkController.text.trim()
            : null,
        createdAt: now,
      );

      final savedEntry = await _storageService.add(entry);

      if (mounted) {
        setState(() {
          _submitSuccess = true;
          _lastSubmitted = savedEntry;
          _isSubmitting = false;
        });
        context.showSuccessSnackBar('DAC Order saved successfully');
      }
      return true;
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackBar('Failed to save: $e');
      }
      return false;
    }
  }

  Future<void> _handlePrint() async {
    if (_lastSubmitted == null || _printer == null || !_isConnected) return;
    setState(() => _isPrinting = true);
    try {
      final userName = await User().getUserName() ?? 'Unknown';
      final bytes =
          DacOrderPrintHelper.buildSlipBytes(_lastSubmitted!, userName);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New DAC Order'),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consumer ID — format: X-XXXXXXXXXXXX (1-2 digits, dash, 12 digits)
              TextFormField(
                controller: _consumerIdController,
                enabled: !_submitSuccess,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: InputDecoration(
                  labelText: 'Consumer ID',
                  hintText: 'e.g. 2-123456789012',
                  prefixIcon: const Icon(Icons.tag),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  final pattern = RegExp(r'^\d{1,2}-\d{12}$');
                  if (!pattern.hasMatch(value.trim())) {
                    return 'Format: 1-2 digits, dash, 12 digits (e.g. 2-123456789012)';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Consumer Number — 10 digits
              TextFormField(
                controller: _consumerNumberController,
                enabled: !_submitSuccess,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  labelText: 'Consumer Number',
                  hintText: '10-digit Consumer Number',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  if (value.trim().length != 10) {
                    return 'Consumer Number must be exactly 10 digits';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.xs),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'At least one of Consumer ID or Consumer Number is required',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.warningYellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md),

              // DAC Code
              TextFormField(
                controller: _dacCodeController,
                enabled: !_submitSuccess,
                decoration: InputDecoration(
                  labelText: 'DAC Code *',
                  hintText: 'Enter DAC Code (digits only)',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'DAC Code is required';
                  }
                  return null;
                },
              ),
              SizedBox(height: AppSpacing.md),

              // Remark
              TextFormField(
                controller: _remarkController,
                enabled: !_submitSuccess,
                decoration: InputDecoration(
                  labelText: 'Remark',
                  hintText: 'Enter remark (optional)',
                  prefixIcon: const Icon(Icons.note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                maxLines: 2,
                textInputAction: TextInputAction.done,
              ),
              SizedBox(height: AppSpacing.xl),

              // Slide to Submit
              if (!_submitSuccess)
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : _SlideToSubmitButton(onSubmit: _handleSubmit),

              // Success state
              if (_submitSuccess) ...[
                // Success indicator
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                        color:
                            AppColorsEnhanced.successGreen.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColorsEnhanced.successGreen, size: 24.sp),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'DAC Order saved successfully!',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColorsEnhanced.successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),

                // Printer section
                if (_isPrinterInitializing)
                  const Center(child: CircularProgressIndicator())
                else if (_printer != null) ...[
                  // Printer status
                  if (_printerType == PrinterType.sunmi)
                    _buildPrinterStatus(
                        Icons.print, 'Sunmi Printer Ready', _isConnected)
                  else ...[
                    _buildPrinterStatus(
                        Icons.bluetooth_connected,
                        _isConnected
                            ? 'Printer Connected'
                            : 'Not Connected',
                        _isConnected),
                    if (!_isConnected) ...[
                      SizedBox(height: AppSpacing.sm),
                      if (_isScanning)
                        const Center(child: CircularProgressIndicator())
                      else if (_printers.isNotEmpty)
                        ..._printers.map((p) => ListTile(
                              dense: true,
                              leading:
                                  const Icon(Icons.print, color: Colors.blue),
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

                  // Print button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isConnected && !_isPrinting ? _handlePrint : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsEnhanced.brandBlue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
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
                        style: TextStyle(
                            fontSize: 16.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: AppSpacing.md),

                // Add another button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _consumerIdController.clear();
                      _consumerNumberController.clear();
                      _dacCodeController.clear();
                      _remarkController.clear();
                      setState(() {
                        _submitSuccess = false;
                        _lastSubmitted = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: Text(
                      'Add Another',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterStatus(IconData icon, String text, bool connected) {
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
                color:
                    connected ? Colors.green.shade700 : Colors.grey.shade700,
              )),
        ],
      ),
    );
  }
}

/// A simple "slide right to submit" button
class _SlideToSubmitButton extends StatefulWidget {
  final Future<bool> Function() onSubmit;
  const _SlideToSubmitButton({required this.onSubmit});

  @override
  State<_SlideToSubmitButton> createState() => _SlideToSubmitButtonState();
}

class _SlideToSubmitButtonState extends State<_SlideToSubmitButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  late double _maxDrag;
  final double _thumbSize = 56;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _resetAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() => _dragPosition = _resetAnimation.value);
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _resetToStart() {
    _resetAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.reset();
    _resetController.forward();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0, _maxDrag);
    });
  }

  void _onDragEnd(DragEndDetails details) async {
    if (_dragPosition >= _maxDrag * 0.85) {
      final success = await widget.onSubmit();
      if (!success && mounted) {
        // Validation failed — reset slider back
        _resetToStart();
      }
    } else {
      _resetToStart();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        _maxDrag = trackWidth - _thumbSize - 8;
        final progress = (_dragPosition / _maxDrag).clamp(0.0, 1.0);

        return Container(
          height: 60.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            color: Color.lerp(
              Colors.grey.shade200,
              AppColorsEnhanced.successGreen.withValues(alpha: 0.2),
              progress,
            ),
            border: Border.all(
              color: Color.lerp(
                Colors.grey.shade300,
                AppColorsEnhanced.successGreen,
                progress,
              )!,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hint text
              AnimatedOpacity(
                opacity: 1.0 - progress,
                duration: const Duration(milliseconds: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: _thumbSize.w),
                    Icon(Icons.arrow_forward,
                        size: 16.sp, color: Colors.grey.shade500),
                    SizedBox(width: 4.w),
                    Text(
                      'Slide to Submit',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_forward,
                        size: 16.sp, color: Colors.grey.shade500),
                  ],
                ),
              ),
              // Draggable thumb
              Positioned(
                left: _dragPosition + 4,
                child: GestureDetector(
                  onHorizontalDragUpdate: _onDragUpdate,
                  onHorizontalDragEnd: _onDragEnd,
                  child: Container(
                    width: _thumbSize.w,
                    height: _thumbSize.w - 8,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        AppColorsEnhanced.brandBlue,
                        AppColorsEnhanced.successGreen,
                        progress,
                      ),
                      borderRadius: BorderRadius.circular(26.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      progress > 0.85 ? Icons.check : Icons.chevron_right,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
