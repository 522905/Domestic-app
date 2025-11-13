import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/master_data.dart';
import '../../../core/models/defect_inspection/purchase_invoice.dart';
import '../../../core/models/defect_inspection/dir_item.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../blocs/defect_inspection/defect_inspection_bloc.dart';
import '../../blocs/defect_inspection/defect_inspection_event.dart';
import '../../blocs/defect_inspection/defect_inspection_state.dart';
import '../../widgets/defect_inspection/dir_item_row.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/selectors/warehouse_selector_dialog.dart';
import '../../widgets/error_dialog.dart';
import 'add_defective_item_screen.dart';

/// Screen for creating Defect Inspection Report
class DIRCreationScreen extends StatefulWidget {
  final DIRPrePopulated? prePopulated;

  const DIRCreationScreen({
    super.key,
    this.prePopulated,
  });

  @override
  State<DIRCreationScreen> createState() => _DIRCreationScreenState();
}

class _DIRCreationScreenState extends State<DIRCreationScreen> {
  late final ApiServiceInterface apiService;

  // Form state
  String? _selectedWarehouse;
  String? _selectedWarehouseId;
  String _purpose = 'Storage Inspection';
  String? _purchaseInvoice;
  String? _company;

  // Master data
  MasterDataResponse? _masterData;
  List<Map<String, dynamic>> _warehouses = [];

  // Items list
  List<DIRItem> _items = [];

  // Loading states
  bool _isLoadingMasterData = false;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    // Check if pre-populated from PI
    if (widget.prePopulated != null) {
      _selectedWarehouse = widget.prePopulated!.warehouse;
      _purpose = widget.prePopulated!.purpose;
      _purchaseInvoice = widget.prePopulated!.purchaseInvoice;
      _company = widget.prePopulated!.company;

      // Load master data immediately
      await _loadMasterData();
    } else {
      // Standalone mode - load warehouses
      await _loadWarehouses();

      // Get company from user session
      final userCompany = await User().getActiveCompany();
      _company = userCompany?.name;
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehousesData = await apiService.getWarehouses();

      setState(() {
        _warehouses = List<Map<String, dynamic>>.from(warehousesData);
      });
    } catch (e) {
      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Load Warehouses',
          error: e,
          onRetry: _loadWarehouses,
        );
      }
    }
  }

  Future<void> _loadMasterData() async {
    if (_selectedWarehouse == null) return;

    setState(() {
      _isLoadingMasterData = true;
    });

    context.read<DefectInspectionBloc>().add(LoadMasterDataEvent(
      warehouse: _selectedWarehouse!,
      purchaseInvoice: _purchaseInvoice,
    ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Inspection Report',
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocListener<DefectInspectionBloc, DefectInspectionState>(
        listener: _handleBlocState,
        child: _isLoadingMasterData && _masterData == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderSection(),
                    SizedBox(height: AppSpacing.xl.h),
                    if (_masterData != null) ...[
                      _buildAddItemButton(),
                      SizedBox(height: AppSpacing.xl.h),
                      _buildItemsList(),
                      SizedBox(height: AppSpacing.xl.h),
                      _buildSummaryAndSubmit(),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _handleBlocState(BuildContext context, DefectInspectionState state) {
    if (state is MasterDataLoaded) {
      setState(() {
        _masterData = state.masterData;
        _isLoadingMasterData = false;
      });
    } else if (state is MasterDataError) {
      setState(() {
        _isLoadingMasterData = false;
      });
      context.showErrorDialog(
        title: 'Failed to Load Data',
        error: state.message,
        onRetry: _loadMasterData,
      );
    } else if (state is DIRSubmitted) {
      context.showSuccessSnackBar(state.message);
      Navigator.pop(context, true); // Return to previous screen
    } else if (state is DIRSubmissionError) {
      _showSubmissionError(state.message, state.details);
    }
  }

  Widget _buildHeaderSection() {
    final bool isPrePopulated = widget.prePopulated != null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Information',
              style: AppTextStyles.h2.copyWith(
                color: AppColorsEnhanced.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.md.h),

            // Warehouse Selector
            if (!isPrePopulated) ...[
              Text(
                'Warehouse *',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColorsEnhanced.darkGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              InkWell(
                onTap: _showWarehouseSelector,
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.md.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColorsEnhanced.lightGray,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedWarehouse ?? 'Select warehouse',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: _selectedWarehouse != null
                              ? AppColorsEnhanced.darkGray
                              : AppColorsEnhanced.darkGray.withOpacity(0.5),
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
            ] else ...[
              _buildReadOnlyField('Warehouse', _selectedWarehouse!),
              SizedBox(height: AppSpacing.md.h),
            ],

            // Purpose
            _buildReadOnlyField('Purpose', _purpose),
            SizedBox(height: AppSpacing.md.h),

            // Purchase Invoice (if applicable)
            if (_purchaseInvoice != null)
              _buildReadOnlyField('Purchase Invoice', _purchaseInvoice!),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        Container(
          padding: EdgeInsets.all(AppSpacing.md.w),
          decoration: BoxDecoration(
            color: AppColorsEnhanced.lightGray.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColorsEnhanced.lightGray,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.darkGray,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showWarehouseSelector() async {
    final selected = await WarehouseSelectorDialog.show(
      context: context,
      warehouses: _warehouses,
      title: 'Select Warehouse',
    );

    if (selected != null) {
      setState(() {
        _selectedWarehouse = selected['name'];
        _selectedWarehouseId = selected['id']?.toString();
      });

      // Load master data for selected warehouse
      await _loadMasterData();
    }
  }

  Widget _buildAddItemButton() {
    return ProfessionalButton(
      text: 'Add Defective Item${_items.isNotEmpty ? 's' : ''}',
      icon: Icons.add_circle_outline,
      variant: ButtonVariant.primary,
      onPressed: _navigateToAddItemsScreen,
      fullWidth: true,
    );
  }

  Future<void> _navigateToAddItemsScreen() async {
    final result = await Navigator.push<List<DIRItem>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddDefectiveItemScreen(
          masterData: _masterData!,
          existingItems: _items,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _items = result;
      });
    }
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt,
              color: AppColorsEnhanced.brandBlue,
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.sm.w),
            Text(
              'Added Items (${_items.length})',
              style: AppTextStyles.h2.copyWith(
                color: AppColorsEnhanced.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return DIRItemRow(
              item: _items[index],
              index: index,
              onRemove: () => _removeItem(index),
            );
          },
        ),
      ],
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    context.showSuccessSnackBar('Item removed');
  }

  Widget _buildSummaryAndSubmit() {
    return Column(
      children: [
        Card(
          elevation: 2,
          color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Items:',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColorsEnhanced.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_items.length}',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColorsEnhanced.brandBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        BlocBuilder<DefectInspectionBloc, DefectInspectionState>(
          builder: (context, state) {
            final isSubmitting = state is DIRSubmitting;

            return ProfessionalButton(
              text: 'Submit Inspection Report',
              icon: Icons.check_circle,
              variant: ButtonVariant.primary,
              onPressed: _items.isEmpty ? null : _submitReport,
              isLoading: isSubmitting,
              fullWidth: true,
            );
          },
        ),
      ],
    );
  }

  void _submitReport() {
    if (_items.isEmpty) {
      context.showErrorSnackBar('Please add at least one item');
      return;
    }

    // Get current date and time
    final now = DateTime.now();
    final postingDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final postingTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final request = CreateDIRRequest(
      company: _company!,
      warehouse: _selectedWarehouse!,
      purpose: _purpose,
      purchaseInvoice: _purpose == 'Same Load Defectives' ? _purchaseInvoice : null,
      postingDate: postingDate,
      postingTime: postingTime,
      items: _items,
    );

    context.read<DefectInspectionBloc>().add(SubmitDIREvent(request: request));
  }

  void _showSubmissionError(String message, String? details) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColorsEnhanced.errorRed),
            SizedBox(width: AppSpacing.sm.w),
            Text(
              'Submission Failed',
              style: AppTextStyles.h2.copyWith(color: AppColorsEnhanced.errorRed),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: AppTextStyles.bodyMedium,
              ),
              if (details != null) ...[
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'Details:',
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.sm.h),
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm.w),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.lightGray,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    details,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppColorsEnhanced.brandBlue)),
          ),
        ],
      ),
    );
  }
}
