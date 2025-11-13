import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/purchase_invoice.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../blocs/defect_inspection/defect_inspection_bloc.dart';
import '../../blocs/defect_inspection/defect_inspection_event.dart';
import '../../blocs/defect_inspection/defect_inspection_state.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/selectors/warehouse_selector_dialog.dart';
import '../../widgets/error_dialog.dart';
import 'purchase_invoice_detail_screen.dart';

/// Screen for listing purchase invoices to create DIR from
class PurchaseInvoiceListScreen extends StatefulWidget {
  const PurchaseInvoiceListScreen({super.key});

  @override
  State<PurchaseInvoiceListScreen> createState() => _PurchaseInvoiceListScreenState();
}

class _PurchaseInvoiceListScreenState extends State<PurchaseInvoiceListScreen> {
  late final ApiServiceInterface apiService;
  String? _selectedWarehouse;
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _loadWarehouses();
  }

  Future<void> _loadWarehouses() async {
    try {
      final warehousesData = await apiService.getWarehouses();

      final warehouses = List<Map<String, dynamic>>.from(warehousesData);
      setState(() {
        _warehouses = warehouses;

        // Auto-select if single warehouse
        if (_warehouses.length == 1) {
          _selectedWarehouse = _warehouses[0]['name'];
          _loadPurchaseInvoices();
        }
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

  void _loadPurchaseInvoices() {
    if (_selectedWarehouse == null) return;

    context.read<DefectInspectionBloc>().add(
          LoadPurchaseInvoicesEvent(warehouse: _selectedWarehouse!),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Purchase Invoices',
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildWarehouseSelector(),
          Expanded(
            child: BlocConsumer<DefectInspectionBloc, DefectInspectionState>(
              listener: (context, state) {
                if (state is PurchaseInvoicesError) {
                  context.showErrorDialog(
                    title: 'Failed to Load Purchase Invoices',
                    error: state.message,
                    onRetry: _loadPurchaseInvoices,
                  );
                }
              },
              builder: (context, state) {
                if (_selectedWarehouse == null) {
                  return ProfessionalEmptyState(
                    icon: Icons.warehouse,
                    message: 'Select Warehouse',
                    description: 'Please select a warehouse to view purchase invoices.',
                  );
                }

                if (state is PurchaseInvoicesLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PurchaseInvoicesLoaded) {
                  if (state.purchaseInvoices.isEmpty) {
                    return ProfessionalEmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'No Purchase Invoices',
                      description: 'No purchase invoices found for the selected warehouse.',
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.md.w),
                    itemCount: state.purchaseInvoices.length,
                    itemBuilder: (context, index) {
                      return _buildPICard(state.purchaseInvoices[index]);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseSelector() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Warehouse',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColorsEnhanced.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          InkWell(
            onTap: _warehouses.length > 1 ? _showWarehouseSelector : null,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: _warehouses.length > 1
                    ? Colors.white
                    : AppColorsEnhanced.lightGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColorsEnhanced.lightGray,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warehouse,
                    color: AppColorsEnhanced.brandBlue,
                    size: 20.sp,
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      _selectedWarehouse ?? 'Select warehouse',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedWarehouse != null
                            ? AppColorsEnhanced.darkGray
                            : AppColorsEnhanced.darkGray.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_warehouses.length > 1)
                    Icon(
                      Icons.arrow_drop_down,
                      color: AppColorsEnhanced.brandBlue,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
      });
      _loadPurchaseInvoices();
    }
  }

  Widget _buildPICard(PurchaseInvoice pi) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _navigateToDIRCreation(pi),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PI Number and Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pi.name,
                    style: AppTextStyles.h2.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm.w,
                      vertical: AppSpacing.xs.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColorsEnhanced.successGreen,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '₹${_formatAmount(pi.grandTotal)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorsEnhanced.successGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),

              // Supplier
              _buildInfoRow(
                icon: Icons.business,
                label: 'Supplier',
                value: pi.supplier,
                color: AppColorsEnhanced.brandOrange,
              ),
              SizedBox(height: AppSpacing.sm.h),

              // Date
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: _formatDate(pi.postingDate),
                color: AppColorsEnhanced.darkGray,
              ),
              SizedBox(height: AppSpacing.sm.h),

              // Warehouse
              _buildInfoRow(
                icon: Icons.warehouse,
                label: 'Warehouse',
                value: pi.setWarehouse,
                color: AppColorsEnhanced.infoBlue,
              ),
              SizedBox(height: AppSpacing.md.h),

              // Action hint
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Tap to view details',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs.w),
                  Icon(
                    Icons.arrow_forward,
                    size: 16.sp,
                    color: AppColorsEnhanced.brandBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: color,
        ),
        SizedBox(width: AppSpacing.xs.w),
        Text(
          '$label: ',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.darkGray,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  Future<void> _navigateToDIRCreation(PurchaseInvoice pi) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseInvoiceDetailScreen(purchaseInvoice: pi),
      ),
    );

    // If any action was taken, refresh the list
    if (result == true && mounted) {
      _loadPurchaseInvoices();
    }
  }
}
