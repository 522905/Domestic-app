// lib/presentation/pages/orders/dialogs/select_warehouse_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../domain/entities/warehouse.dart';

class SelectWarehouseDialog extends StatelessWidget {
  final List<Warehouse> warehouses;
  final Function(Warehouse) onWarehouseSelected;

  const SelectWarehouseDialog({
    Key? key,
    required this.warehouses,
    required this.onWarehouseSelected,
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
                  'Select Warehouse',
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

          // Warehouses list
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.all(16.w),
              itemCount: warehouses.length,
              itemBuilder: (context, index) {
                final warehouse = warehouses[index];
                return _buildWarehouseCard(context, warehouse);
              },
            ),
          ),

          // Confirm button
          Padding(
            padding: EdgeInsets.all(16.w),
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56.h),
                backgroundColor: const Color(0xFF0E5CA8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'CONFIRM',
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

  Widget _buildWarehouseCard(BuildContext context, Warehouse warehouse) {
    // Example stock data for visualization
    final stockData = {
      '14.2kg': 120,
      '5kg': 45,
      '19kg': 12,
    };

    return Card(
      margin: EdgeInsets.only(bottom: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: InkWell(
        onTap: () => onWarehouseSelected(warehouse),
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      warehouse.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '14.2kg: ${stockData['14.2kg']} | 5kg: ${stockData['5kg']} | 19kg: ${stockData['19kg']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: warehouse.warehouseName,
                groupValue: null, // This would be set to selected warehouse ID
                onChanged: (value) => onWarehouseSelected(warehouse),
                activeColor: const Color(0xFF0E5CA8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}