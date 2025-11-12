import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/defect_inspection_report.dart';
import '../../blocs/defect_inspection/defect_inspection_bloc.dart';
import '../../blocs/defect_inspection/defect_inspection_event.dart';
import '../../blocs/defect_inspection/defect_inspection_state.dart';
import '../../widgets/professional/professional_status_badge.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/selectors/warehouse_selector_dialog.dart';
import 'dir_detail_screen.dart';
import 'dir_creation_screen.dart';

/// Screen for listing inspection reports
class DIRListScreen extends StatefulWidget {
  const DIRListScreen({super.key});

  @override
  State<DIRListScreen> createState() => _DIRListScreenState();
}

class _DIRListScreenState extends State<DIRListScreen> {
  String? _selectedWarehouse;
  List<Map<String, dynamic>> _warehouses = [];

  @override
  void initState() {
    super.initState();
    _loadInspectionReports();
    _loadWarehouses();
  }

  void _loadInspectionReports() {
    context.read<DefectInspectionBloc>().add(
          LoadInspectionReportsEvent(warehouse: _selectedWarehouse),
        );
  }

  Future<void> _loadWarehouses() async {
    try {
      final response = await context
          .read<DefectInspectionBloc>()
          .defectService
          .apiClient
          .get(
            context
                .read<DefectInspectionBloc>()
                .defectService
                .apiClient
                .endpoints
                .warehouseListApi,
          );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _warehouses = List<Map<String, dynamic>>.from(response.data['data'] ?? []);
        });
      }
    } catch (e) {
      // Silently fail - warehouse filter is optional
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inspection Reports',
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _navigateToCreateDIR,
            tooltip: 'Create New Report',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildWarehouseFilter(),
          Expanded(
            child: BlocConsumer<DefectInspectionBloc, DefectInspectionState>(
              listener: (context, state) {
                if (state is InspectionReportsError) {
                  context.showErrorSnackBar(state.message);
                }
              },
              builder: (context, state) {
                if (state is InspectionReportsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is InspectionReportsLoaded || state is InspectionReportsRefreshing) {
                  final reports = state is InspectionReportsLoaded
                      ? state.reports
                      : (state as InspectionReportsRefreshing).currentReports;

                  if (reports.isEmpty) {
                    return ProfessionalEmptyState(
                      icon: Icons.description_outlined,
                      message: 'No Reports Found',
                      description: 'No inspection reports found for the selected criteria.',
                      actionText: 'Create New Report',
                      onAction: _navigateToCreateDIR,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      padding: EdgeInsets.all(AppSpacing.md.w),
                      itemCount: reports.length,
                      itemBuilder: (context, index) {
                        return _buildReportCard(reports[index]);
                      },
                    ),
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

  Widget _buildWarehouseFilter() {
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
      child: InkWell(
        onTap: _showWarehouseFilter,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md.w),
          decoration: BoxDecoration(
            color: AppColorsEnhanced.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: AppColorsEnhanced.lightGray,
              width: 1,
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
                  _selectedWarehouse ?? 'All Warehouses',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColorsEnhanced.darkGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_selectedWarehouse != null) ...[
                IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18.sp,
                    color: AppColorsEnhanced.errorRed,
                  ),
                  onPressed: _clearWarehouseFilter,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: AppSpacing.sm.w),
              ],
              Icon(
                Icons.arrow_drop_down,
                color: AppColorsEnhanced.brandBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showWarehouseFilter() async {
    final selected = await WarehouseSelectorDialog.show(
      context: context,
      warehouses: _warehouses,
      title: 'Filter by Warehouse',
    );

    if (selected != null) {
      setState(() {
        _selectedWarehouse = selected['name'];
      });
      _loadInspectionReports();
    }
  }

  void _clearWarehouseFilter() {
    setState(() {
      _selectedWarehouse = null;
    });
    _loadInspectionReports();
  }

  Widget _buildReportCard(InspectionReport report) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _navigateToReportDetail(report.name),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with DIR name and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.name,
                      style: AppTextStyles.h2.copyWith(
                        color: AppColorsEnhanced.brandBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ProfessionalStatusBadge(
                    status: report.status.toLowerCase(),
                    size: BadgeSize.small,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),

              // Purpose
              _buildInfoRow(
                icon: Icons.category,
                label: 'Purpose',
                value: report.purpose,
                color: AppColorsEnhanced.brandOrange,
              ),
              SizedBox(height: AppSpacing.sm.h),

              // Warehouse
              _buildInfoRow(
                icon: Icons.warehouse,
                label: 'Warehouse',
                value: report.warehouse,
                color: AppColorsEnhanced.infoBlue,
              ),
              SizedBox(height: AppSpacing.sm.h),

              // Date and Time
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Date',
                value: '${_formatDate(report.postingDate)} ${report.postingTime}',
                color: AppColorsEnhanced.darkGray,
              ),

              // Purchase Invoice (if applicable)
              if (report.purchaseInvoice != null) ...[
                SizedBox(height: AppSpacing.sm.h),
                _buildInfoRow(
                  icon: Icons.receipt,
                  label: 'PI',
                  value: report.purchaseInvoice!,
                  color: AppColorsEnhanced.successGreen,
                ),
              ],
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

  Future<void> _onRefresh() async {
    context.read<DefectInspectionBloc>().add(
          RefreshInspectionReportsEvent(warehouse: _selectedWarehouse),
        );
  }

  void _navigateToReportDetail(String dirName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIRDetailScreen(dirName: dirName),
      ),
    );
  }

  Future<void> _navigateToCreateDIR() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DIRCreationScreen(),
      ),
    );

    // Refresh list if report was created
    if (result == true) {
      _loadInspectionReports();
    }
  }
}
