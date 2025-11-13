import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/purchase_invoice.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional_snackbar.dart';
import '../../widgets/error_dialog.dart';
import 'dir_creation_screen.dart';

/// Screen for displaying purchase invoice details
class PurchaseInvoiceDetailScreen extends StatefulWidget {
  final PurchaseInvoice purchaseInvoice;

  const PurchaseInvoiceDetailScreen({
    super.key,
    required this.purchaseInvoice,
  });

  @override
  State<PurchaseInvoiceDetailScreen> createState() => _PurchaseInvoiceDetailScreenState();
}

class _PurchaseInvoiceDetailScreenState extends State<PurchaseInvoiceDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Purchase Invoice Details',
          style: AppTextStyles.h1.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            SizedBox(height: AppSpacing.lg.h),
            _buildDetailsCard(),
            SizedBox(height: AppSpacing.xl.h),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [
              AppColorsEnhanced.brandBlue,
              AppColorsEnhanced.brandBlue.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.purchaseInvoice.name,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md.w,
                    vertical: AppSpacing.sm.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    '₹${_formatAmount(widget.purchaseInvoice.grandTotal)}',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColorsEnhanced.brandBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              widget.purchaseInvoice.supplier,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Information',
              style: AppTextStyles.h2.copyWith(
                color: AppColorsEnhanced.darkGray,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: 'Posting Date',
              value: _formatDate(widget.purchaseInvoice.postingDate),
              iconColor: AppColorsEnhanced.brandOrange,
            ),
            SizedBox(height: AppSpacing.md.h),
            _buildDetailRow(
              icon: Icons.warehouse,
              label: 'Warehouse',
              value: widget.purchaseInvoice.setWarehouse,
              iconColor: AppColorsEnhanced.infoBlue,
            ),
            SizedBox(height: AppSpacing.md.h),
            _buildDetailRow(
              icon: Icons.business,
              label: 'Company',
              value: widget.purchaseInvoice.company,
              iconColor: AppColorsEnhanced.successGreen,
            ),
            SizedBox(height: AppSpacing.md.h),
            _buildDetailRow(
              icon: Icons.attach_money,
              label: 'Grand Total',
              value: '₹${widget.purchaseInvoice.grandTotal.toStringAsFixed(2)}',
              iconColor: AppColorsEnhanced.brandBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(AppSpacing.sm.w),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: iconColor,
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Create Defect Report Button
        ProfessionalButton(
          text: 'Create Defect Report',
          icon: Icons.error_outline,
          variant: ButtonVariant.primary,
          onPressed: _navigateToDIRCreation,
          fullWidth: true,
        ),
        SizedBox(height: AppSpacing.md.h),
        // Mark for Dispatch Button
        ProfessionalButton(
          text: 'Mark for Dispatch',
          icon: Icons.local_shipping,
          variant: ButtonVariant.secondary,
          onPressed: _isProcessing ? null : _markForDispatch,
          isLoading: _isProcessing,
          fullWidth: true,
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

  Future<void> _navigateToDIRCreation() async {
    final prePopulated = DIRPrePopulated(
      purchaseInvoice: widget.purchaseInvoice.name,
      warehouse: widget.purchaseInvoice.setWarehouse,
      purpose: 'Same Load Defectives',
      company: widget.purchaseInvoice.company,
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIRCreationScreen(prePopulated: prePopulated),
      ),
    );

    if (result == true && mounted) {
      context.showSuccessSnackBar('Defect report created successfully');
      Navigator.pop(context, true); // Return to list and refresh
    }
  }

  Future<void> _markForDispatch() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // TODO: Call your API endpoint here with the invoice number
      // Example:
      // await apiService.markInvoiceForDispatch(widget.purchaseInvoice.name);

      // Simulate API call for now
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        context.showSuccessSnackBar(
          'Purchase Invoice ${widget.purchaseInvoice.name} marked for dispatch',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorDialog(
          title: 'Failed to Mark for Dispatch',
          error: e,
          onRetry: _markForDispatch,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
}
