import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../../../../core/constants/app_colors_enhanced.dart';
import '../../../../core/constants/spacing.dart';
import '../../../../core/constants/text_styles.dart';
import '../../../../core/services/printer/printer_manager.dart';
import '../../../../core/services/printer/printer_interface.dart';
import '../../../../core/services/printer/printer_type.dart';
import '../../../../core/services/printer/bluetooth_printer_service.dart';
import '../../../../core/services/User.dart';
import '../../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';
import '../offline_delivery_print_helper.dart';

class TokenCreationForm extends StatefulWidget {
  final String distributionPointId;
  final OfflineSystemStatus systemStatus;
  final int companyId;

  const TokenCreationForm({
    Key? key,
    required this.distributionPointId,
    required this.systemStatus,
    required this.companyId,
  }) : super(key: key);

  @override
  State<TokenCreationForm> createState() => _TokenCreationFormState();
}

class _TokenCreationFormState extends State<TokenCreationForm> {
  final _formKey = GlobalKey<FormState>();
  final _consumerIdController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _orderNumberController = TextEditingController();
  final _remarkController = TextEditingController();

  final PrinterManager _printerManager = PrinterManager();

  bool _submitSuccess = false;
  bool _isSubmitting = false;
  OfflineDeliveryToken? _lastCreatedToken;

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
    _orderNumberController.dispose();
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
      debugPrint('TokenCreationForm: Printer init error: $e');
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

    final idempotencyKey = const Uuid().v4();

    context.read<OfflineDeliveryBloc>().add(CreateToken(
      distributionPointId: widget.distributionPointId,
      consumerId: consumerId.isNotEmpty ? '7$consumerId' : null,
      consumerNumber: consumerNumber.isNotEmpty ? '7$consumerNumber' : null,
      orderNumber: _orderNumberController.text.trim().isNotEmpty
          ? '2-${_orderNumberController.text.trim()}'
          : null,
      remark: _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : null,
      idempotencyKey: idempotencyKey,
      companyId: widget.companyId,
    ));

    return true;
  }

  Future<void> _handlePrint() async {
    if (_lastCreatedToken == null || _printer == null || !_isConnected) return;
    setState(() => _isPrinting = true);
    try {
      final userName = await User().getUserName() ?? 'Unknown';
      final bytes = OfflineDeliveryPrintHelper.buildTokenReceiptBytes(
          _lastCreatedToken!, userName);
      final success = await _printer!.printBinaryData(bytes);
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Receipt printed successfully');
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

  void _resetForm() {
    _consumerIdController.clear();
    _consumerNumberController.clear();
    _orderNumberController.clear();
    _remarkController.clear();
    setState(() {
      _submitSuccess = false;
      _lastCreatedToken = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenCreated && _isSubmitting) {
          setState(() {
            _submitSuccess = true;
            _lastCreatedToken = state.token;
            _isSubmitting = false;
          });
        } else if (state is OfflineDeliveryError && _isSubmitting) {
          setState(() => _isSubmitting = false);
        }
      },
      child: Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsEnhanced.border),
      ),
      child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Consumer ID
                    TextFormField(
                      controller: _consumerIdController,
                      enabled: !_submitSuccess,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(15),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Consumer ID',
                        hintText: '500000047614745',
                        prefixIcon: const Icon(Icons.tag),
                        prefixText: '7',
                        prefixStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (value.trim().length != 15) {
                          return 'Enter 15 digits (total 16 with prefix 7)';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: AppSpacing.md),

                    // Consumer Number
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
                        hintText: '547614745',
                        prefixIcon: const Icon(Icons.numbers),
                        prefixText: '7',
                        prefixStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (value.trim().length != 10) {
                          return 'Enter 10 digits after 7';
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

                    // Order Number
                    TextFormField(
                      controller: _orderNumberController,
                      enabled: !_submitSuccess,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(12),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Order Number',
                        hintText: '005456757366',
                        prefixIcon: const Icon(Icons.receipt_long),
                        prefixText: '2-',
                        prefixStyle: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        if (value.trim().length != 12) {
                          return 'Enter 12 digits after 2-';
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
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColorsEnhanced.successGreen
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: AppColorsEnhanced.successGreen,
                                    size: 24.sp),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    'Token #${_lastCreatedToken?.tokenNumber ?? ''} created!',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColorsEnhanced.successGreen,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_lastCreatedToken?.cashToCollect != null) ...[
                              SizedBox(height: AppSpacing.xs),
                              Row(
                                children: [
                                  SizedBox(width: 32.sp),
                                  Text(
                                    'Cash to collect: Rs. ${_lastCreatedToken!.cashToCollect!.toStringAsFixed(2)}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColorsEnhanced.secondaryText,
                                    ),
                                  ),
                                  if (_lastCreatedToken!
                                      .cashToCollectIsEstimated)
                                    Text(
                                      ' (est.)',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColorsEnhanced.warningYellow,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),

                      // Printer section
                      if (_isPrinterInitializing)
                        const Center(child: CircularProgressIndicator())
                      else if (_printer != null) ...[
                        if (_printerType == PrinterType.sunmi)
                          _buildPrinterStatus(
                              Icons.print, 'Sunmi Printer Ready', _isConnected)
                        else ...[
                          _buildPrinterStatus(
                            Icons.bluetooth_connected,
                            _isConnected
                                ? 'Printer Connected'
                                : 'Not Connected',
                            _isConnected,
                          ),
                          if (!_isConnected) ...[
                            SizedBox(height: AppSpacing.sm),
                            if (_isScanning)
                              const Center(child: CircularProgressIndicator())
                            else if (_printers.isNotEmpty)
                              ..._printers.map((p) => ListTile(
                                    dense: true,
                                    leading: const Icon(Icons.print,
                                        color: Colors.blue),
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
                            onPressed: _isConnected && !_isPrinting
                                ? _handlePrint
                                : null,
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
                              _isPrinting ? 'Printing...' : 'Print Receipt',
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
                          onPressed: _resetForm,
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
          Icon(icon,
              size: 20.sp, color: connected ? Colors.green : Colors.grey),
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
                      'Slide to Create Token',
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
