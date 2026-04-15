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
import '../../../../core/services/api_service_interface.dart';
import '../../../../core/services/service_provider.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../../domain/entities/offline_delivery/obligation_director.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';

class ObligationTokenForm extends StatefulWidget {
  final String distributionPointId;
  final bool requireDacCode;
  final int companyId;

  const ObligationTokenForm({
    Key? key,
    required this.distributionPointId,
    required this.requireDacCode,
    required this.companyId,
  }) : super(key: key);

  @override
  State<ObligationTokenForm> createState() => _ObligationTokenFormState();
}

class _ObligationTokenFormState extends State<ObligationTokenForm> {
  final _formKey = GlobalKey<FormState>();
  final _consumerNameController = TextEditingController();
  final _remarkController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  final PrinterManager _printerManager = PrinterManager();

  bool _submitSuccess = false;
  bool _isSubmitting = false;
  OfflineDeliveryToken? _lastCreatedToken;

  // Form selections
  int? _selectedDirectorId;
  String _deliveryType = 'REFILL';
  String _itemCode = 'M00087';
  String _cashArrangement = 'COLLECT_AT_DELIVERY';
  String _emptyArrangement = 'SAME_DAY';
  DateTime? _emptiesDueDate;
  DateTime? _cashDueDate;

  // Printer state
  PrinterInterface? _printer;
  PrinterType? _printerType;
  bool _isPrinterInitializing = true;
  bool _isPrinting = false;
  bool _isConnected = false;
  bool _isScanning = false;
  List<BluetoothDevice> _printers = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  ApiServiceInterface? _apiService;

  @override
  void initState() {
    super.initState();
    _initPrinter();
    _initApiService();
    // Load directors for the selected company
    context.read<OfflineDeliveryBloc>().add(
      LoadObligationDirectors(widget.companyId),
    );
  }

  Future<void> _initApiService() async {
    _apiService = await ServiceProvider.getApiService();
  }

  @override
  void dispose() {
    _consumerNameController.dispose();
    _remarkController.dispose();
    _quantityController.dispose();
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
      debugPrint('ObligationTokenForm: Printer init error: $e');
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
    if (_selectedDirectorId == null) {
      context.showWarningSnackBar('Please select who authorized this delivery');
      return false;
    }

    setState(() => _isSubmitting = true);

    final idempotencyKey = const Uuid().v4();
    final quantity = int.tryParse(_quantityController.text.trim()) ?? 1;

    context.read<OfflineDeliveryBloc>().add(CreateToken(
      distributionPointId: widget.distributionPointId,
      consumerNameManual: _consumerNameController.text.trim(),
      remark: _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : null,
      overrideReason: _remarkController.text.trim().isNotEmpty
          ? _remarkController.text.trim()
          : 'Obligation delivery',
      idempotencyKey: idempotencyKey,
      creationType: 'OBLIGATION',
      companyId: widget.companyId,
      directedById: _selectedDirectorId,
      deliveryType: _deliveryType,
      itemCode: _itemCode,
      quantity: quantity,
      emptyArrangement: _deliveryType == 'REFILL' ? _emptyArrangement : 'NOT_APPLICABLE',
      emptiesDueDate: _emptyArrangement == 'DEFERRED' && _emptiesDueDate != null
          ? _emptiesDueDate!.toIso8601String().split('T')[0]
          : null,
      cashArrangement: _cashArrangement,
      cashDueDate: _cashArrangement == 'DEFERRED' && _cashDueDate != null
          ? _cashDueDate!.toIso8601String().split('T')[0]
          : null,
    ));

    return true;
  }

  Future<void> _handlePrint() async {
    if (_lastCreatedToken == null || _printer == null || !_isConnected) return;
    if (_apiService == null) {
      _apiService = await ServiceProvider.getApiService();
    }
    setState(() => _isPrinting = true);
    try {
      final binaryData = await _apiService!.thermalPrintOfflineDeliveryToken(
        _lastCreatedToken!.id,
        _printer!.deviceIdentifier,
        _printer!.paperWidthMm,
      );
      final success = await _printer!.printBinaryData(binaryData);
      if (mounted) {
        if (success) {
          context.showSuccessSnackBar('Receipt printed successfully');
          context.read<OfflineDeliveryBloc>().add(const RefreshTokens());
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

  void _resetForm() {
    _consumerNameController.clear();
    _remarkController.clear();
    _quantityController.text = '1';
    setState(() {
      _submitSuccess = false;
      _lastCreatedToken = null;
      _deliveryType = 'REFILL';
      _itemCode = 'M00087';
      _cashArrangement = 'COLLECT_AT_DELIVERY';
      _emptyArrangement = 'SAME_DAY';
      _emptiesDueDate = null;
      _cashDueDate = null;
      _selectedDirectorId = null;
    });
  }

  Future<void> _pickDate(bool isEmpties) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isEmpties) {
          _emptiesDueDate = picked;
        } else {
          _cashDueDate = picked;
        }
      });
    }
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
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_submitSuccess) ...[
                _buildDirectorDropdown(),
                SizedBox(height: AppSpacing.md),
                _buildConsumerNameField(),
                SizedBox(height: AppSpacing.md),
                _buildDeliveryTypeSelector(),
                SizedBox(height: AppSpacing.md),
                _buildCylinderTypeSelector(),
                SizedBox(height: AppSpacing.md),
                _buildQuantityField(),
                SizedBox(height: AppSpacing.md),
                _buildCashArrangementDropdown(),
                if (_cashArrangement == 'DEFERRED') ...[
                  SizedBox(height: AppSpacing.sm),
                  _buildDatePicker(
                    label: 'Cash Due Date',
                    date: _cashDueDate,
                    onTap: () => _pickDate(false),
                  ),
                ],
                if (_deliveryType == 'REFILL') ...[
                  SizedBox(height: AppSpacing.md),
                  _buildEmptyArrangementDropdown(),
                  if (_emptyArrangement == 'DEFERRED') ...[
                    SizedBox(height: AppSpacing.sm),
                    _buildDatePicker(
                      label: 'Empties Due Date',
                      date: _emptiesDueDate,
                      onTap: () => _pickDate(true),
                    ),
                  ],
                ],
                SizedBox(height: AppSpacing.md),
                _buildRemarkField(),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'Evidence upload will be mandatory after token creation.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.warningYellow,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : _SlideToSubmitButton(onSubmit: _handleSubmit),
              ],
              if (_submitSuccess) _buildSuccessState(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectorDropdown() {
    return BlocBuilder<OfflineDeliveryBloc, OfflineDeliveryState>(
      buildWhen: (prev, curr) => curr is OfflineDeliveryLoaded,
      builder: (context, state) {
        final directors = state is OfflineDeliveryLoaded
            ? state.obligationDirectors
            : <ObligationDirector>[];

        return DropdownButtonFormField<int>(
          value: _selectedDirectorId,
          decoration: InputDecoration(
            labelText: 'Authorized By *',
            prefixIcon: const Icon(Icons.admin_panel_settings),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          items: directors.map((d) {
            return DropdownMenuItem<int>(
              value: d.id,
              child: Text('${d.name} (${d.role})'),
            );
          }).toList(),
          onChanged: _submitSuccess
              ? null
              : (value) => setState(() => _selectedDirectorId = value),
          validator: (value) {
            if (value == null) return 'Please select who authorized this';
            return null;
          },
          hint: directors.isEmpty
              ? const Text('Loading directors...')
              : const Text('Select director'),
        );
      },
    );
  }

  Widget _buildConsumerNameField() {
    return TextFormField(
      controller: _consumerNameController,
      enabled: !_submitSuccess,
      decoration: InputDecoration(
        labelText: 'Consumer Name *',
        hintText: 'Enter recipient name',
        prefixIcon: const Icon(Icons.person),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Consumer name is required';
        }
        return null;
      },
    );
  }

  Widget _buildDeliveryTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Type',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColorsEnhanced.secondaryText,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: 'Refill',
                icon: Icons.refresh,
                isSelected: _deliveryType == 'REFILL',
                onTap: () => setState(() {
                  _deliveryType = 'REFILL';
                  _emptyArrangement = 'SAME_DAY';
                }),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildToggleButton(
                label: 'New Connection',
                icon: Icons.add_circle_outline,
                isSelected: _deliveryType == 'NEW_CONNECTION',
                onTap: () => setState(() {
                  _deliveryType = 'NEW_CONNECTION';
                  _emptyArrangement = 'NOT_APPLICABLE';
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCylinderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cylinder Type',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColorsEnhanced.secondaryText,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: '14.2 Kg',
                icon: Icons.propane_tank,
                isSelected: _itemCode == 'M00087',
                onTap: () => setState(() => _itemCode = 'M00087'),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildToggleButton(
                label: '5 Kg',
                icon: Icons.propane_tank_outlined,
                isSelected: _itemCode == 'M00104',
                onTap: () => setState(() => _itemCode = 'M00104'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _submitSuccess ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColorsEnhanced.brandBlue.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColorsEnhanced.brandBlue
                : AppColorsEnhanced.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected
                  ? AppColorsEnhanced.brandBlue
                  : AppColorsEnhanced.secondaryText,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppColorsEnhanced.brandBlue
                    : AppColorsEnhanced.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      enabled: !_submitSuccess,
      decoration: InputDecoration(
        labelText: 'Quantity',
        hintText: 'Number of cylinders',
        prefixIcon: const Icon(Icons.numbers),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Quantity is required';
        }
        final qty = int.tryParse(value.trim());
        if (qty == null || qty < 1) {
          return 'Enter a valid quantity';
        }
        return null;
      },
    );
  }

  Widget _buildCashArrangementDropdown() {
    return DropdownButtonFormField<String>(
      value: _cashArrangement,
      decoration: InputDecoration(
        labelText: 'Cash Arrangement',
        prefixIcon: const Icon(Icons.payments),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'COLLECT_AT_DELIVERY', child: Text('Collect at Delivery')),
        DropdownMenuItem(value: 'DEFERRED', child: Text('Deferred (collect later)')),
        DropdownMenuItem(value: 'ALREADY_PAID', child: Text('Already Paid')),
        DropdownMenuItem(value: 'NOT_APPLICABLE', child: Text('Not Applicable')),
      ],
      onChanged: _submitSuccess
          ? null
          : (value) => setState(() => _cashArrangement = value!),
    );
  }

  Widget _buildEmptyArrangementDropdown() {
    return DropdownButtonFormField<String>(
      value: _emptyArrangement,
      decoration: InputDecoration(
        labelText: 'Empty Arrangement',
        prefixIcon: const Icon(Icons.swap_vert),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'SAME_DAY', child: Text('Collect Same Day')),
        DropdownMenuItem(value: 'DEFERRED', child: Text('Deferred (collect later)')),
        DropdownMenuItem(value: 'NOT_APPLICABLE', child: Text('Not Applicable')),
      ],
      onChanged: _submitSuccess
          ? null
          : (value) => setState(() => _emptyArrangement = value!),
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _submitSuccess ? null : onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          date != null
              ? '${date.day}/${date.month}/${date.year}'
              : 'Tap to select date',
          style: AppTextStyles.bodyMedium.copyWith(
            color: date != null
                ? Colors.black87
                : AppColorsEnhanced.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildRemarkField() {
    return TextFormField(
      controller: _remarkController,
      enabled: !_submitSuccess,
      decoration: InputDecoration(
        labelText: 'Remark / Reason',
        hintText: 'Enter reason for obligation delivery',
        prefixIcon: const Icon(Icons.note),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      maxLines: 2,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColorsEnhanced.successGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColorsEnhanced.successGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppColorsEnhanced.successGreen, size: 24.sp),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Obligation token #${_lastCreatedToken?.tokenNumber ?? ''} created!',
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
          if (_printerType == PrinterType.sunmi)
            _buildPrinterStatus(
                Icons.print, 'Sunmi Printer Ready', _isConnected)
          else ...[
            _buildPrinterStatus(
              Icons.bluetooth_connected,
              _isConnected ? 'Printer Connected' : 'Not Connected',
              _isConnected,
            ),
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
                _isPrinting ? 'Printing...' : 'Print Token',
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],

        SizedBox(height: AppSpacing.md),

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
                      'Slide to Create Obligation Token',
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
                        AppColorsEnhanced.warningYellow,
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
