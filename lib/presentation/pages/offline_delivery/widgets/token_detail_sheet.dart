import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
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
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';
import 'delivery_dialog.dart';
import 'token_correction_dialog.dart';
import 'token_image_upload_widget.dart';

class TokenDetailSheet extends StatefulWidget {
  final OfflineDeliveryToken token;
  final bool printOnly;
  final bool hidePrint;

  const TokenDetailSheet({Key? key, required this.token, this.printOnly = false, this.hidePrint = false}) : super(key: key);

  @override
  State<TokenDetailSheet> createState() => _TokenDetailSheetState();
}

class _TokenDetailSheetState extends State<TokenDetailSheet> {
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
      debugPrint('TokenDetailSheet: Printer init error: $e');
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

  Future<void> _printReceipt(OfflineDeliveryToken currentToken) async {
    if (_printer == null || !_isConnected) return;
    setState(() => _isPrinting = true);
    try {
      final binaryData = await _apiService.thermalPrintOfflineDeliveryToken(
        currentToken.id,
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenDelivered && state.token.id == widget.token.id) {
          if (widget.hidePrint) {
            // Opened from scan — re-fetch token for fresh available_actions
            context.read<OfflineDeliveryBloc>().add(ScanToken(uuid: widget.token.id));
          } else {
            Navigator.of(context).pop();
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return BlocBuilder<OfflineDeliveryBloc, OfflineDeliveryState>(
              buildWhen: (prev, curr) =>
                  curr is OfflineDeliveryLoaded || curr is ImagesAttached || curr is TokenScanned,
              builder: (context, state) {
                // Get the latest token data from action states or bloc cache
                OfflineDeliveryToken currentToken = widget.token;
                bool isSupervisor = false;
                if (state is TokenScanned && state.token.id == widget.token.id) {
                  // Fresh token from re-scan (after delivery/action)
                  currentToken = state.token;
                } else if (state is ImagesAttached && state.token.id == widget.token.id) {
                  // Updated token from attach response
                  currentToken = state.token;
                } else if (state is OfflineDeliveryLoaded) {
                  isSupervisor = state.isSupervisor;
                  final updated = state.tokens.where((t) => t.id == widget.token.id);
                  if (updated.isNotEmpty) {
                    currentToken = updated.first;
                  }
                }

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

                      // Token number + status
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Token #${currentToken.tokenNumber ?? '?'}',
                              style: AppTextStyles.h1.copyWith(
                                color: AppColorsEnhanced.brandBlue,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildStatusBadge(currentToken),
                        ],
                      ),
                      SizedBox(height: AppSpacing.lg),

                      // Correction warning banner
                      if (currentToken.needsCorrection) ...[
                        _buildCorrectionBanner(context, currentToken),
                        SizedBox(height: AppSpacing.md),
                      ],

                      // Consumer info section
                      _buildSectionTitle('Consumer Info'),
                      SizedBox(height: AppSpacing.sm),
                      if (currentToken.consumerId != null)
                        _buildInfoRow('Consumer ID', currentToken.consumerId!),
                      if (currentToken.consumerNumber != null)
                        _buildInfoRow('Consumer No', currentToken.consumerNumber!),
                      _buildInfoRow('Name', currentToken.displayName),
                      SizedBox(height: AppSpacing.md),

                      // Financial section
                      _buildSectionTitle('Financial'),
                      SizedBox(height: AppSpacing.sm),
                      if (currentToken.cashToCollect != null)
                        _buildInfoRow(
                          'Cash to Collect',
                          'Rs. ${currentToken.cashToCollect!.toStringAsFixed(2)}${currentToken.cashToCollectIsEstimated ? ' (est.)' : ''}',
                        ),
                      if (currentToken.digitalAmount != null)
                        _buildInfoRow(
                          'Digital Amount',
                          'Rs. ${currentToken.digitalAmount!.toStringAsFixed(2)}',
                        ),
                      if (currentToken.isDelivered && currentToken.cashCollected != null)
                        _buildInfoRow(
                          'Cash Collected',
                          'Rs. ${currentToken.cashCollected!.toStringAsFixed(2)}',
                          valueColor: AppColorsEnhanced.successGreen,
                        ),
                      SizedBox(height: AppSpacing.md),

                      // Details section
                      _buildSectionTitle('Details'),
                      SizedBox(height: AppSpacing.sm),
                      if (currentToken.orderNumber != null)
                        _buildInfoRow('Order Number', currentToken.orderNumber!),
                      if (currentToken.dacCode != null)
                        _buildInfoRow('DAC Code', currentToken.dacCode!),
                      if (currentToken.distributionPointName != null)
                        _buildInfoRow('Distribution Point', currentToken.distributionPointName!),
                      if (currentToken.createdByName != null)
                        _buildInfoRow('Created by', currentToken.createdByName!),
                      if (currentToken.remark != null)
                        _buildInfoRow('Remark', currentToken.remark!),
                      if (currentToken.createdAt != null)
                        _buildInfoRow(
                          'Created',
                          DateFormat('dd/MM/yyyy hh:mm a').format(currentToken.createdAt!),
                        ),
                      if (currentToken.isDelivered && currentToken.deliveredAt != null)
                        _buildInfoRow(
                          'Delivered',
                          DateFormat('dd/MM/yyyy hh:mm a').format(currentToken.deliveredAt!),
                          valueColor: AppColorsEnhanced.successGreen,
                        ),

                      // Obligation details section
                      if (currentToken.isObligation && currentToken.obligationDetail != null) ...[
                        SizedBox(height: AppSpacing.md),
                        _buildObligationDetailsSection(currentToken),
                      ],

                      // System obligation badge
                      if (currentToken.isSystemObligation) ...[
                        SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColorsEnhanced.infoBlue.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColorsEnhanced.infoBlue.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColorsEnhanced.infoBlue, size: 18.sp),
                              SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'System Obligation - Sale already posted in SDMS',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColorsEnhanced.infoBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      SizedBox(height: AppSpacing.xl),

                      if (!widget.printOnly) ...[
                        // Actions driven by available_actions from API
                        ..._buildAvailableActions(context, currentToken),
                      ],

                      // Inline printer section (hidden when opened from scan)
                      if (!widget.hidePrint)
                        _buildPrinterSection(currentToken, isSupervisor),

                      SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPrinterSection(OfflineDeliveryToken currentToken, bool isSupervisor) {
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
              child: Builder(builder: (_) {
                // Supervisors can always print; non-supervisors rely on API's canPrint
                final canPrintNow = currentToken.canPrint || isSupervisor;
                return Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (!_isPrinting && canPrintNow)
                            ? () => _printReceipt(currentToken)
                            : null,
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
                          _isPrinting
                              ? 'Printing...'
                              : currentToken.printCount == 0
                                  ? 'Print Token'
                                  : 'Reprint Token',
                          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    if (!canPrintNow) ...[
                      SizedBox(height: 4.h),
                      Text(
                        'Already printed. Ask supervisor to reprint.',
                        style: TextStyle(color: Colors.orange, fontSize: 12.sp),
                      ),
                    ],
                  ],
                );
              }),
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

  Widget _buildCorrectionBanner(BuildContext context, OfflineDeliveryToken currentToken) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.warningYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColorsEnhanced.warningYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColorsEnhanced.warningYellow, size: 20.sp),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Correction Required',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          if (currentToken.reconciliationError != null) ...[
            SizedBox(height: AppSpacing.xs),
            Padding(
              padding: EdgeInsets.only(left: 28.w),
              child: Text(
                currentToken.reconciliationError!,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCorrectionDialog(context, currentToken),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColorsEnhanced.warningYellow,
                side: BorderSide(color: AppColorsEnhanced.warningYellow),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              icon: Icon(Icons.edit_note, size: 18.sp),
              label: const Text('Correct Data'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColorsEnhanced.secondaryText,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  List<Widget> _buildAvailableActions(BuildContext context, OfflineDeliveryToken token) {
    final actions = token.availableActions;
    final widgets = <Widget>[];

    // If API returns available_actions, use them
    if (actions.isNotEmpty) {
      // attach_images action
      if (token.hasAction('attach_images')) {
        widgets.add(TokenImageUploadWidget(tokenId: token.id));
        widgets.add(SizedBox(height: AppSpacing.md));
      }

      // Uploaded indicator (when images are uploaded but no attach_images action)
      if (token.imagesUploaded && !token.hasAction('attach_images')) {
        widgets.add(Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColorsEnhanced.successGreen.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColorsEnhanced.successGreen.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle,
                  color: AppColorsEnhanced.successGreen, size: 18.sp),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Photo uploaded',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.successGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ));
        widgets.add(SizedBox(height: AppSpacing.md));
      }

      // deliver action
      if (token.hasAction('deliver')) {
        widgets.add(SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDeliveryDialog(context, token),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.successGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            icon: Icon(Icons.check_circle_outline, size: 20.sp),
            label: Text(
              'Mark Delivered',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ));
        widgets.add(SizedBox(height: AppSpacing.md));
      }

      // collect_empties action
      if (token.hasAction('collect_empties')) {
        final action = token.getAction('collect_empties')!;
        final label = action['label']?.toString() ?? 'Collect Empties';
        widgets.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showCollectEmptiesDialog(context, token, action),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsEnhanced.warningYellow,
              side: BorderSide(color: AppColorsEnhanced.warningYellow),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            icon: Icon(Icons.swap_vert, size: 20.sp),
            label: Text(
              label,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ));
        widgets.add(SizedBox(height: AppSpacing.md));
      }

      // collect_cash action
      if (token.hasAction('collect_cash')) {
        widgets.add(SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _collectCash(context, token),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColorsEnhanced.successGreen,
              side: BorderSide(color: AppColorsEnhanced.successGreen),
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            icon: Icon(Icons.payments, size: 20.sp),
            label: Text(
              'Mark Cash Collected',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ));
        widgets.add(SizedBox(height: AppSpacing.md));
      }
    } else {
      // Fallback: no available_actions
      // Obligation tokens: only print (deliver/photo handled via scan flow)
      // Other tokens: show deliver button
      if (token.isPending && !token.isObligation) {
        widgets.add(SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showDeliveryDialog(context, token),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.successGreen,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.r),
              ),
            ),
            icon: Icon(Icons.check_circle_outline, size: 20.sp),
            label: Text(
              'Mark Delivered',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ));
        widgets.add(SizedBox(height: AppSpacing.md));
      }
    }

    return widgets;
  }

  void _showCollectEmptiesDialog(
      BuildContext context, OfflineDeliveryToken token, Map<String, dynamic> action) {
    final remaining = action['empties_remaining'] ?? token.obligationDetail?.emptiesRemaining ?? 0;
    final controller = TextEditingController(text: remaining.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collect Empties'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Count',
            hintText: 'Max: $remaining',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.brandBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final count = int.tryParse(controller.text.trim());
              if (count == null || count < 1 || count > remaining) return;
              Navigator.pop(ctx);
              try {
                final apiService = await ServiceProvider.getApiService();
                await apiService.collectEmpties(token.id, count);
                if (context.mounted) {
                  context.showSuccessSnackBar('$count empties collected');
                  // Re-scan to get fresh available_actions
                  context.read<OfflineDeliveryBloc>().add(ScanToken(uuid: token.id));
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}');
                }
              }
            },
            child: const Text('Collect'),
          ),
        ],
      ),
    );
  }

  void _collectCash(BuildContext context, OfflineDeliveryToken token) {
    // Direct API call via service provider for cash collection
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Cash Collection'),
        content: const Text('Mark deferred cash as collected?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final apiService = await ServiceProvider.getApiService();
                await apiService.collectCash(token.id);
                if (context.mounted) {
                  context.showSuccessSnackBar('Cash collection recorded');
                  // Re-scan to get fresh available_actions
                  context.read<OfflineDeliveryBloc>().add(ScanToken(uuid: token.id));
                }
              } catch (e) {
                if (context.mounted) {
                  context.showErrorSnackBar('Failed: ${e.toString().replaceAll('Exception: ', '')}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.successGreen,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildObligationDetailsSection(OfflineDeliveryToken token) {
    final detail = token.obligationDetail!;

    // Resolve director name: from nested object, from directed_by_name, or from cached directors
    String? directorLabel;
    if (detail.directedBy != null && detail.directedBy!.name.isNotEmpty) {
      directorLabel = '${detail.directedBy!.name} (${detail.directedBy!.role})';
    } else if (detail.directedByName != null && detail.directedByName!.isNotEmpty) {
      directorLabel = detail.directedByName;
    } else if (detail.directedBy != null) {
      // Look up from cached directors in the BLoC state
      final state = context.read<OfflineDeliveryBloc>().state;
      if (state is OfflineDeliveryLoaded) {
        final match = state.obligationDirectors
            .where((d) => d.id == detail.directedBy!.id);
        if (match.isNotEmpty) {
          directorLabel = '${match.first.name} (${match.first.role})';
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Obligation Details'),
        SizedBox(height: AppSpacing.sm),
        if (directorLabel != null)
          _buildInfoRow('Authorized By', directorLabel),
        _buildInfoRow('Delivery Type', detail.deliveryTypeDisplay),
        _buildInfoRow('Cylinder', '${detail.itemDisplayName} x${detail.quantity}'),
        if (detail.assignedToName != null)
          _buildInfoRow('Assigned To', detail.assignedToName!),

        // Empty collection status
        if (detail.emptiesExpected > 0) ...[
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: detail.emptiesCompleted
                  ? AppColorsEnhanced.successGreen.withOpacity(0.05)
                  : detail.isOverdueEmpties
                      ? AppColorsEnhanced.errorRed.withOpacity(0.05)
                      : AppColorsEnhanced.warningYellow.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: detail.emptiesCompleted
                    ? AppColorsEnhanced.successGreen.withOpacity(0.3)
                    : detail.isOverdueEmpties
                        ? AppColorsEnhanced.errorRed.withOpacity(0.3)
                        : AppColorsEnhanced.warningYellow.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.swap_vert,
                      size: 22.sp,
                      color: detail.emptiesCompleted
                          ? AppColorsEnhanced.successGreen
                          : detail.isOverdueEmpties
                              ? AppColorsEnhanced.errorRed
                              : AppColorsEnhanced.warningYellow,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Empty Collection',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (detail.emptiesCompleted)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 14.sp, color: AppColorsEnhanced.successGreen),
                            SizedBox(width: 4.w),
                            Text('Complete', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColorsEnhanced.successGreen)),
                          ],
                        ),
                      )
                    else if (detail.isOverdueEmpties)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('OVERDUE', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColorsEnhanced.errorRed)),
                      ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: detail.emptiesExpected > 0
                        ? detail.emptiesCollected / detail.emptiesExpected
                        : 0,
                    minHeight: 8.h,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      detail.emptiesCompleted
                          ? AppColorsEnhanced.successGreen
                          : AppColorsEnhanced.warningYellow,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collected: ${detail.emptiesCollected}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      'Expected: ${detail.emptiesExpected}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                if (!detail.emptiesCompleted && detail.emptiesRemaining > 0) ...[
                  SizedBox(height: 4),
                  Text(
                    '${detail.emptiesRemaining} remaining',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.warningYellow,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
                if (detail.emptiesDueDate != null && !detail.emptiesCompleted) ...[
                  SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14.sp,
                          color: detail.isOverdueEmpties ? AppColorsEnhanced.errorRed : AppColorsEnhanced.secondaryText),
                      SizedBox(width: 4.w),
                      Text(
                        'Due: ${detail.emptiesDueDate!.day}/${detail.emptiesDueDate!.month}/${detail.emptiesDueDate!.year}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: detail.isOverdueEmpties
                              ? AppColorsEnhanced.errorRed
                              : AppColorsEnhanced.secondaryText,
                          fontWeight: detail.isOverdueEmpties ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Cash status — show for all arrangements
        if (detail.cashArrangement != null) ...[
          SizedBox(height: AppSpacing.md),
          Builder(builder: (_) {
            final arrangement = detail.cashArrangement!;
            final Color cardColor;
            final IconData cardIcon;
            final String cardTitle;
            final String cardSubtitle;
            Widget? trailing;

            if (arrangement == 'COLLECT_AT_DELIVERY') {
              cardColor = AppColorsEnhanced.brandBlue;
              cardIcon = Icons.payments;
              cardTitle = 'Cash';
              cardSubtitle = 'Collect at delivery';
            } else if (arrangement == 'DEFERRED') {
              if (detail.cashCollectedLater) {
                cardColor = AppColorsEnhanced.successGreen;
                cardIcon = Icons.check_circle;
                cardTitle = 'Cash Collected';
                cardSubtitle = 'Deferred cash has been collected';
                trailing = Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14.sp, color: AppColorsEnhanced.successGreen),
                      SizedBox(width: 4.w),
                      Text('Done', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: AppColorsEnhanced.successGreen)),
                    ],
                  ),
                );
              } else {
                cardColor = detail.isOverdueCash ? AppColorsEnhanced.errorRed : AppColorsEnhanced.warningYellow;
                cardIcon = Icons.schedule;
                cardTitle = 'Cash Pending';
                cardSubtitle = detail.cashDueDate != null
                    ? 'Due: ${detail.cashDueDate!.day}/${detail.cashDueDate!.month}/${detail.cashDueDate!.year}'
                    : 'Deferred — collect later';
                trailing = detail.isOverdueCash
                    ? Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColorsEnhanced.errorRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('OVERDUE', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppColorsEnhanced.errorRed)),
                      )
                    : null;
              }
            } else if (arrangement == 'ALREADY_PAID') {
              cardColor = AppColorsEnhanced.successGreen;
              cardIcon = Icons.check_circle;
              cardTitle = 'Cash';
              cardSubtitle = 'Already paid';
            } else {
              cardColor = AppColorsEnhanced.secondaryText;
              cardIcon = Icons.remove_circle_outline;
              cardTitle = 'Cash';
              cardSubtitle = 'Not applicable';
            }

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(cardIcon, size: 22.sp, color: cardColor),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cardTitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          cardSubtitle,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: cardColor,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing,
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
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
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OfflineDeliveryToken currentToken) {
    final Color bgColor;
    final Color textColor;
    final String label;

    if (currentToken.isDelivered) {
      bgColor = AppColorsEnhanced.successGreen.withOpacity(0.1);
      textColor = AppColorsEnhanced.successGreen;
      label = 'DELIVERED';
    } else if (currentToken.isVoided) {
      bgColor = AppColorsEnhanced.errorRed.withOpacity(0.1);
      textColor = AppColorsEnhanced.errorRed;
      label = 'VOIDED';
    } else {
      bgColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey.shade700;
      label = 'ISSUED';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  void _showDeliveryDialog(BuildContext context, OfflineDeliveryToken currentToken) {
    final bloc = context.read<OfflineDeliveryBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: DeliveryDialog(
          token: currentToken,
        ),
      ),
    );
  }

  void _showCorrectionDialog(BuildContext context, OfflineDeliveryToken currentToken) {
    final bloc = context.read<OfflineDeliveryBloc>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: TokenCorrectionDialog(token: currentToken),
      ),
    );
  }
}
