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
import '../../../../core/services/User.dart';
import '../../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../../widgets/professional_snackbar.dart';
import '../offline_delivery_print_helper.dart';
import 'delivery_dialog.dart';
import 'token_correction_dialog.dart';
import 'token_image_upload_widget.dart';

class TokenDetailSheet extends StatefulWidget {
  final OfflineDeliveryToken token;

  const TokenDetailSheet({Key? key, required this.token}) : super(key: key);

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
      final userName = await User().getUserName() ?? 'Unknown';
      final bytes = OfflineDeliveryPrintHelper.buildTokenReceiptBytes(
          currentToken, userName);
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenDelivered && state.token.id == widget.token.id) {
          Navigator.of(context).pop();
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
                  curr is OfflineDeliveryLoaded || curr is ImagesAttached,
              builder: (context, state) {
                // Get the latest token data from the bloc cache
                OfflineDeliveryToken currentToken = widget.token;
                if (state is OfflineDeliveryLoaded) {
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
                      SizedBox(height: AppSpacing.xl),

                      // Image upload section — show for PENDING tokens
                      if (currentToken.isPending && !currentToken.imagesUploaded) ...[
                        TokenImageUploadWidget(tokenId: currentToken.id),
                        SizedBox(height: AppSpacing.md),
                      ],

                      // Uploaded indicator
                      if (currentToken.imagesUploaded) ...[
                        Container(
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
                                'Photos uploaded',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColorsEnhanced.successGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],

                      // Actions
                      if (currentToken.isPending) ...[
                        // Evidence gate: if evidence required but images not uploaded, block delivery
                        if (currentToken.evidenceRequired && !currentToken.imagesUploaded) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(24.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey, size: 20.sp),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Upload photo first',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showDeliveryDialog(context, currentToken),
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
                                style: TextStyle(
                                    fontSize: 16.sp, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: AppSpacing.md),
                      ],

                      // Inline printer section
                      _buildPrinterSection(currentToken),

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

  Widget _buildPrinterSection(OfflineDeliveryToken currentToken) {
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
                  onPressed: !_isPrinting ? () => _printReceipt(currentToken) : null,
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
      label = 'PENDING';
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
    final blocState = bloc.state;
    final requireDacCode = blocState is OfflineDeliveryLoaded
        ? blocState.systemStatus.requireDacCode
        : false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: DeliveryDialog(
          token: currentToken,
          requireDacCode: requireDacCode && currentToken.dacCode == null,
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
