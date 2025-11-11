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
import '../../widgets/professional_snackbar.dart';
import '../../widgets/error_dialog.dart';

/// Screen for displaying inspection report details
class DIRDetailScreen extends StatefulWidget {
  final String dirName;

  const DIRDetailScreen({
    super.key,
    required this.dirName,
  });

  @override
  State<DIRDetailScreen> createState() => _DIRDetailScreenState();
}

class _DIRDetailScreenState extends State<DIRDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadReportDetail();
  }

  void _loadReportDetail() {
    context.read<DefectInspectionBloc>().add(
          LoadInspectionReportDetailEvent(dirName: widget.dirName),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.dirName,
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: BlocConsumer<DefectInspectionBloc, DefectInspectionState>(
        listener: (context, state) {
          if (state is InspectionReportDetailError) {
            context.showErrorDialog(
              title: 'Failed to Load Report',
              error: state.message,
              onRetry: _loadReportDetail,
            );
          }
        },
        builder: (context, state) {
          if (state is InspectionReportDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InspectionReportDetailLoaded ||
              state is InspectionReportDetailRefreshing) {
            final detail = state is InspectionReportDetailLoaded
                ? state.reportDetail
                : (state as InspectionReportDetailRefreshing).currentDetail;

            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.md.w),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderCard(detail),
                    SizedBox(height: AppSpacing.lg.h),
                    _buildItemsSection(detail),
                    if (detail.links.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.lg.h),
                      _buildLinkedDocumentsSection(detail),
                    ],
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHeaderCard(InspectionReportDetail detail) {
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
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Report Information',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColorsEnhanced.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ProfessionalStatusBadge(
                  status: detail.status.toLowerCase(),
                  size: BadgeSize.medium,
                  showIcon: true,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            Divider(color: AppColorsEnhanced.lightGray),
            SizedBox(height: AppSpacing.md.h),

            // Purpose
            _buildInfoRow(
              icon: Icons.category,
              label: 'Purpose',
              value: detail.purpose,
              color: AppColorsEnhanced.brandOrange,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Warehouse
            _buildInfoRow(
              icon: Icons.warehouse,
              label: 'Warehouse',
              value: detail.warehouse,
              color: AppColorsEnhanced.infoBlue,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Company
            _buildInfoRow(
              icon: Icons.business,
              label: 'Company',
              value: detail.company,
              color: AppColorsEnhanced.darkGray,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Date and Time
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: 'Date & Time',
              value: '${_formatDate(detail.postingDate)} at ${detail.postingTime}',
              color: AppColorsEnhanced.darkGray,
            ),

            // Purchase Invoice (if applicable)
            if (detail.purchaseInvoice != null) ...[
              SizedBox(height: AppSpacing.md.h),
              _buildInfoRow(
                icon: Icons.receipt,
                label: 'Purchase Invoice',
                value: detail.purchaseInvoice!,
                color: AppColorsEnhanced.successGreen,
              ),
            ],
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: color,
        ),
        SizedBox(width: AppSpacing.sm.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColorsEnhanced.darkGray.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColorsEnhanced.darkGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemsSection(InspectionReportDetail detail) {
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
              'Defective Items (${detail.items.length})',
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
          itemCount: detail.items.length,
          itemBuilder: (context, index) {
            return _buildItemCard(detail.items[index], index);
          },
        ),
      ],
    );
  }

  Widget _buildItemCard(InspectionReportItem item, int index) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: AppSpacing.md.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.all(AppSpacing.md.w),
          childrenPadding: EdgeInsets.only(
            left: AppSpacing.md.w,
            right: AppSpacing.md.w,
            bottom: AppSpacing.md.h,
          ),
          leading: Container(
            padding: EdgeInsets.all(AppSpacing.sm.w),
            decoration: BoxDecoration(
              color: AppColorsEnhanced.brandBlue,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '${index + 1}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            item.sourceItemCode,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColorsEnhanced.darkGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Serial: ${item.cylinderNumber}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColorsEnhanced.darkGray.withOpacity(0.7),
            ),
          ),
          children: [
            Divider(color: AppColorsEnhanced.lightGray),
            SizedBox(height: AppSpacing.sm.h),
            _buildItemDetailRow('Source Item', item.sourceItemCode),
            SizedBox(height: AppSpacing.sm.h),
            _buildItemDetailRow('Target Item', item.targetItemCode),
            SizedBox(height: AppSpacing.sm.h),
            _buildItemDetailRow('Cylinder Number', item.cylinderNumber),
            SizedBox(height: AppSpacing.md.h),

            // Weight Information
            Container(
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.successGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: AppColorsEnhanced.successGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWeightColumn('Tare', item.tareWeight, Icons.fitness_center),
                      _buildWeightColumn('Gross', item.grossWeight, Icons.monitor_weight),
                      _buildWeightColumn('Net', item.netWeight, Icons.calculate, highlight: true),
                    ],
                  ),
                ],
              ),
            ),

            // Fault Description
            if (item.faultType != null && item.faultType!.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md.h),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm.w),
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.warningYellow.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColorsEnhanced.warningYellow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 16.sp,
                      color: AppColorsEnhanced.warningYellow,
                    ),
                    SizedBox(width: AppSpacing.xs.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fault Description:',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColorsEnhanced.darkGray.withOpacity(0.7),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            item.faultType!,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorsEnhanced.darkGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Quantity and UOM
            SizedBox(height: AppSpacing.md.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSmallInfo('Quantity', '${item.qty.toStringAsFixed(0)}'),
                _buildSmallInfo('UOM', item.uom),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildWeightColumn(String label, double value, IconData icon, {bool highlight = false}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20.sp,
          color: highlight
              ? AppColorsEnhanced.successGreen
              : AppColorsEnhanced.darkGray.withOpacity(0.7),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '${value.toStringAsFixed(2)} kg',
          style: AppTextStyles.bodyLarge.copyWith(
            color: highlight
                ? AppColorsEnhanced.successGreen
                : AppColorsEnhanced.darkGray,
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedDocumentsSection(InspectionReportDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.link,
              color: AppColorsEnhanced.brandBlue,
              size: 24.sp,
            ),
            SizedBox(width: AppSpacing.sm.w),
            Text(
              'Linked Documents',
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
          itemCount: detail.links.length,
          itemBuilder: (context, index) {
            return _buildLinkCard(detail.links[index]);
          },
        ),
      ],
    );
  }

  Widget _buildLinkCard(InspectionReportLink link) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: AppSpacing.sm.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm.w),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                Icons.receipt_long,
                color: AppColorsEnhanced.infoBlue,
                size: 24.sp,
              ),
            ),
            SizedBox(width: AppSpacing.md.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    link.linkDoctype,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColorsEnhanced.darkGray.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    link.linkName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    link.purpose,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColorsEnhanced.darkGray.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
          RefreshInspectionReportDetailEvent(dirName: widget.dirName),
        );
  }
}
