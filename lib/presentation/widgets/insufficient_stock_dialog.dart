import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/models/insufficient_stock_exception.dart';

/// Dialog shown when order creation fails due to insufficient stock.
/// Uses orange/warning theme since user can recover by using available quantities.
class InsufficientStockDialog extends StatelessWidget {
  final InsufficientStockException exception;
  final VoidCallback? onUseAvailable;
  final VoidCallback? onCancel;

  const InsufficientStockDialog({
    Key? key,
    required this.exception,
    this.onUseAvailable,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with warning icon
              _buildHeader(context),

              // Scrollable content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner explaining the situation
                      _buildInfoBanner(),
                      SizedBox(height: 16.h),

                      // Stock error cards for each item
                      ...exception.stockErrors.map((error) => _buildStockErrorCard(error)),

                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),

              // Action buttons
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: Colors.orange.shade800,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insufficient Stock',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '${exception.affectedItemCount} item(s) affected',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade700,
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Some items have been reserved by other delivery partners. You can proceed with the available quantities or cancel the order.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockErrorCard(StockError error) {
    final bool canProceed = error.hasAvailableStock;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: canProceed ? Colors.orange.shade300 : Colors.red.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header with status badge
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      error.itemName,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Code: ${error.itemCode}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(canProceed),
            ],
          ),

          SizedBox(height: 12.h),

          // Quantity breakdown
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              children: [
                _buildQuantityRow(
                  'Requested',
                  error.requestedQty.toString(),
                  Colors.black87,
                  isBold: true,
                ),
                Divider(height: 16.h, color: Colors.grey.shade300),
                _buildQuantityRow(
                  'Available',
                  error.availableQty.toString(),
                  canProceed ? Colors.green.shade700 : Colors.red.shade700,
                  isBold: true,
                ),
                SizedBox(height: 8.h),
                _buildQuantityRow(
                  'Total Stock',
                  error.totalStock.toString(),
                  Colors.grey.shade700,
                ),
                SizedBox(height: 4.h),
                _buildQuantityRow(
                  'Reserved by Others',
                  error.reservedStock.toString(),
                  Colors.orange.shade700,
                ),
              ],
            ),
          ),

          // Shortage indicator
          if (error.shortage > 0) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.red.shade600,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Shortage: ${error.shortage} units',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool canProceed) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: canProceed ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: canProceed ? Colors.green.shade300 : Colors.red.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            canProceed ? Icons.check_circle_outline : Icons.cancel_outlined,
            color: canProceed ? Colors.green.shade700 : Colors.red.shade700,
            size: 14.sp,
          ),
          SizedBox(width: 4.w),
          Text(
            canProceed ? 'Can proceed' : 'No stock',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: canProceed ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final bool canUseAvailable = exception.canProceedWithAvailable;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.r),
          bottomRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          // Cancel button (always shown)
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                side: BorderSide(color: Colors.grey.shade400),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Use Available button (only if any item has stock)
          if (canUseAvailable) ...[
            SizedBox(width: 12.w),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onUseAvailable?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Use Available',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Static method to show the dialog
  static Future<void> show(
    BuildContext context,
    InsufficientStockException exception, {
    VoidCallback? onUseAvailable,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InsufficientStockDialog(
        exception: exception,
        onUseAvailable: onUseAvailable,
        onCancel: onCancel,
      ),
    );
  }
}
