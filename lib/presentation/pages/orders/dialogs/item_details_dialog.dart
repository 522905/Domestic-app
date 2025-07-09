import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../domain/entities/inventory_item.dart';

class ItemDetailsDialog extends StatelessWidget {
  final InventoryItem item;

  const ItemDetailsDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                topRight: Radius.circular(16.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Item name
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              item.name,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Stock details
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Text(
                  'Stock Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 16.h),
                _buildStockRow('Available:', item.available.toString(), '120'),
                _buildStockRow('Reserved:', item.reserved.toString(), '18'),
                _buildStockRow('Total:', item.total?.toString() ?? '-', '150'),
                _buildStockRow('Defective:', item.defective?.toString() ?? '0', '3'),
                _buildStockRow('In Transit:', item.inTransit?.toString() ?? '0', '24'),
                _buildStockRow(
                  'Last Update:',
                  item.lastUpdated != null
                      ? DateFormat('MMM d, h:mm a').format(item.lastUpdated!)
                      : '-',
                  'Today, 9:30 AM',
                ),
              ],
            ),
          ),

          // Add to order button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Return to order creation with this item selected
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56.h),
                backgroundColor: const Color(0xFF0E5CA8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'ADD TO ORDER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRow(String label, String value, String fallbackValue) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            value.isNotEmpty ? value : fallbackValue,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}