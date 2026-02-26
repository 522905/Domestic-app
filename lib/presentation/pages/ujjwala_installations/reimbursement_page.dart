import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/selectors/warehouse_selector_dialog.dart';
import 'package:provider/provider.dart';

class ReimbursementPage extends StatefulWidget {
  const ReimbursementPage({Key? key}) : super(key: key);

  @override
  State<ReimbursementPage> createState() => _ReimbursementPageState();
}

class _ReimbursementPageState extends State<ReimbursementPage> {
  // State
  List<Map<String, dynamic>> _warehouses = [];
  Map<String, dynamic>? _selectedWarehouse;
  Map<String, dynamic>? _preview;
  Map<String, dynamic>? _result;

  bool _loadingWarehouses = true;
  bool _loadingPreview = false;
  bool _submitting = false;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWarehouses();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadWarehouses() async {
    try {
      final apiService = context.read<ApiServiceInterface>();
      final data = await apiService.getWarehouses();
      setState(() {
        _warehouses = data.map((w) => w as Map<String, dynamic>).toList();
        _loadingWarehouses = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load warehouses: $e';
        _loadingWarehouses = false;
      });
    }
  }

  Future<void> _onWarehouseSelected(Map<String, dynamic> warehouse) async {
    setState(() {
      _selectedWarehouse = warehouse;
      _preview = null;
      _result = null;
      _loadingPreview = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiServiceInterface>();
      final warehouseId = warehouse['id'] as int? ?? 0;
      final preview = await apiService.getReimbursementPreview(warehouseId);
      final claimable = preview['claimable_count'] ?? 0;
      setState(() {
        _preview = preview;
        _loadingPreview = false;
        _qtyController.text = claimable.toString();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load preview: $e';
        _loadingPreview = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedWarehouse == null || _preview == null) return;

    setState(() {
      _submitting = true;
      _result = null;
      _error = null;
    });

    try {
      final apiService = context.read<ApiServiceInterface>();
      final warehouseId = _selectedWarehouse!['id'] as int? ?? 0;
      final qty = int.parse(_qtyController.text.trim());
      final result = await apiService.createReimbursement(
        warehouseId: warehouseId,
        qty: qty,
      );
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (e) {
      final msg = e.toString();
      if (context.mounted) {
        ProfessionalSnackBar.show(
          context,
          message: msg,
          type: SnackBarType.error,
        );
      }
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claim Reimbursement'),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loadingWarehouses) {
      return Center(
        child: CircularProgressIndicator(color: AppColorsEnhanced.brandBlue),
      );
    }

    if (_error != null && _selectedWarehouse == null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48.r, color: AppColorsEnhanced.errorRed),
              SizedBox(height: AppSpacing.md),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: AppSpacing.md),
              ProfessionalButton(
                text: 'Retry',
                onPressed: _loadWarehouses,
              ),
            ],
          ),
        ),
      );
    }

    // Show result card if submitted
    if (_result != null) {
      return _buildResultCard();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step 1: Warehouse selection
            _buildSectionHeader('Step 1: Select Warehouse'),
            SizedBox(height: AppSpacing.sm),
            _buildWarehouseSelector(),

            // Step 2: Preview
            if (_loadingPreview) ...[
              SizedBox(height: AppSpacing.lg),
              Center(
                child: CircularProgressIndicator(
                    color: AppColorsEnhanced.brandBlue),
              ),
            ],
            if (_preview != null && !_loadingPreview) ...[
              SizedBox(height: AppSpacing.lg),
              _buildSectionHeader('Step 2: Preview'),
              SizedBox(height: AppSpacing.sm),
              _buildPreviewPanel(),

              // Step 3: Qty input
              SizedBox(height: AppSpacing.lg),
              _buildSectionHeader('Step 3: Enter Quantity'),
              SizedBox(height: AppSpacing.sm),
              _buildQtyInput(),

              // Step 4: Submit
              SizedBox(height: AppSpacing.lg),
              ProfessionalButton(
                text: 'Submit Reimbursement',
                icon: Icons.currency_rupee,
                fullWidth: true,
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],

            if (_error != null && _selectedWarehouse != null) ...[
              SizedBox(height: AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.errorRed.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColorsEnhanced.errorRed),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.bodyMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColorsEnhanced.brandBlue,
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    final label = _selectedWarehouse != null
        ? (_selectedWarehouse!['warehouse_label'] ??
            _selectedWarehouse!['name'] ??
            'Selected')
        : 'Tap to select warehouse';

    return InkWell(
      onTap: _warehouses.isEmpty
          ? null
          : () async {
              final selected = await WarehouseSelectorDialog.show(
                context: context,
                warehouses: _warehouses,
                title: 'Select Warehouse',
              );
              if (selected != null) {
                await _onWarehouseSelected(selected);
              }
            },
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColorsEnhanced.border),
          borderRadius: BorderRadius.circular(8.r),
          color: AppColorsEnhanced.background,
        ),
        child: Row(
          children: [
            Icon(Icons.warehouse_outlined,
                color: AppColorsEnhanced.brandBlue, size: 20.r),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label.toString(),
                style: AppTextStyles.bodyMedium.copyWith(
                  color: _selectedWarehouse != null
                      ? null
                      : AppColorsEnhanced.secondaryText,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: AppColorsEnhanced.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewPanel() {
    final claimable = _preview!['claimable_count'] ?? 0;
    final items = (_preview!['items'] as List<dynamic>? ?? []);
    final hasShortage = items.any((item) {
      final avail = (item['available_stock'] ?? 0) as num;
      final needed = (item['claimable_qty'] ?? 0) as num;
      return avail < needed;
    });

    return Container(
      decoration: BoxDecoration(
        color: AppColorsEnhanced.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Claimable count header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.brandBlue.withOpacity(0.07),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            child: Text(
              'Claimable installations: $claimable',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),

          // Items table
          if (items.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  // Header row
                  Row(
                    children: [
                      Expanded(
                          child: Text('Item Code',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText))),
                      SizedBox(
                          width: 70.w,
                          child: Text('Need',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText))),
                      SizedBox(
                          width: 70.w,
                          child: Text('In Stock',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColorsEnhanced.secondaryText))),
                      SizedBox(
                          width: 30.w,
                          child: Text('',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall)),
                    ],
                  ),
                  Divider(color: AppColorsEnhanced.border),
                  ...items.map((item) {
                    final avail = (item['available_stock'] ?? 0) as num;
                    final needed = (item['claimable_qty'] ?? 0) as num;
                    final shortage = avail < needed;
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(
                                  item['item_code']?.toString() ?? '',
                                  style: AppTextStyles.bodySmall)),
                          SizedBox(
                            width: 70.w,
                            child: Text(needed.toString(),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall),
                          ),
                          SizedBox(
                            width: 70.w,
                            child: Text(avail.toString(),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: shortage
                                      ? AppColorsEnhanced.warningYellow
                                      : AppColorsEnhanced.successGreen,
                                  fontWeight: FontWeight.w600,
                                )),
                          ),
                          SizedBox(
                            width: 30.w,
                            child: Icon(
                              shortage ? Icons.warning_amber : Icons.check_circle,
                              size: 16.r,
                              color: shortage
                                  ? AppColorsEnhanced.warningYellow
                                  : AppColorsEnhanced.successGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // Shortage warning banner
          if (hasShortage)
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.warningYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                    color: AppColorsEnhanced.warningYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber,
                      size: 16.r, color: AppColorsEnhanced.warningYellow),
                  SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Insufficient stock for some items. Reimbursement may be partial.',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.warningYellow),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQtyInput() {
    final claimable = (_preview!['claimable_count'] ?? 0) as int;
    return TextFormField(
      controller: _qtyController,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: 'Quantity (max: $claimable)',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        suffixText: '/ $claimable',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a quantity';
        }
        final qty = int.tryParse(value.trim());
        if (qty == null || qty < 1) return 'Must be at least 1';
        if (qty > claimable) return 'Cannot exceed $claimable';
        return null;
      },
    );
  }

  Widget _buildResultCard() {
    final erpStatus = _result!['erp_posting_status']?.toString() ?? '';
    final isSuccess = erpStatus == 'SUCCESS';
    final soNumber = _result!['so_number']?.toString() ?? '';
    final erpError = _result!['erp_posting_error']?.toString() ?? '';

    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSuccess
                    ? AppColorsEnhanced.successGreen.withOpacity(0.08)
                    : AppColorsEnhanced.errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSuccess
                      ? AppColorsEnhanced.successGreen.withOpacity(0.3)
                      : AppColorsEnhanced.errorRed.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle : Icons.error_outline,
                    size: 48.r,
                    color: isSuccess
                        ? AppColorsEnhanced.successGreen
                        : AppColorsEnhanced.errorRed,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    isSuccess ? 'Reimbursement Submitted!' : 'Submission Failed',
                    style: AppTextStyles.h4.copyWith(
                      color: isSuccess
                          ? AppColorsEnhanced.successGreen
                          : AppColorsEnhanced.errorRed,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSuccess && soNumber.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'SO Number: $soNumber',
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (!isSuccess && erpError.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      erpError,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColorsEnhanced.errorRed),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: AppSpacing.lg),

            if (isSuccess)
              ProfessionalButton(
                text: 'Back',
                icon: Icons.arrow_back,
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              )
            else
              ProfessionalButton(
                text: 'Try Again',
                icon: Icons.refresh,
                variant: ButtonVariant.warning,
                fullWidth: true,
                onPressed: () {
                  setState(() {
                    _result = null;
                    _error = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}
