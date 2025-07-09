import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/services/mock_data.dart';
import '../../widgets/dashboard/inventory_action_card.dart';

class TransferDetailsScreen extends StatefulWidget {
  final String transferId;
  final String warehouseFrom;
  final String warehouseTo;
  final String itemDetails;
  final String gatepassNo;
  final String status; // Default status

  const TransferDetailsScreen({
    Key? key,
    required this.transferId,
    required this.warehouseFrom,
    required this.warehouseTo,
    required this.itemDetails,
    required this.gatepassNo,
    required this.status,
  }) : super(key: key);

  @override
  State<TransferDetailsScreen> createState() => _TransferDetailsScreenState();
}

class _TransferDetailsScreenState extends State<TransferDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transfer Details',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pending Handover Status
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
               widget.status == 'Pending'
                  ? 'Pending Handover'
                  : 'Handover Approved',
                style: TextStyle(
                  color: widget.status == 'Pending' ? Colors.amber : Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // Transfer Details
            _buildInfoRow('Gatepass No:', widget.gatepassNo),
            _buildInfoRow('Date:', '05/05/2025'),
            _buildInfoRow('Time:', '14:30'),
            _buildInfoRow('From:', widget.warehouseFrom),
            _buildInfoRow('To:', widget.warehouseTo),

            Divider(height: 24.h),

            // Items Details
            Text(
              'Items Details:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            _buildItemDetail('Filled Cylinders', _extractQuantity(widget.itemDetails)),

            SizedBox(height: 16.h),

            // Manager Verification
            Text(
              'Manager Verification:',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text(
                  'Amit Singh',
                  style: TextStyle(
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Verified at 14:35',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            if(widget.status == 'Pending') ...[
              SizedBox(height: 24.h),

              // Confirmation and Action Button
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Please confirm you have received ${_extractQuantity(widget.itemDetails)} cylinders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.black87,
                  ),
                ),
              ),

              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    // Handle approval action
                    _approveHandover();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'APPROVE HANDOVER',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetail(String itemName, String quantity) {
    return Padding(
      padding: EdgeInsets.only(left: 16.w, bottom: 8.h),
      child: Row(
        children: [
          Text(
            '$itemName:',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(width: 8.w),
          Text(
            quantity,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _extractQuantity(String itemDetails) {
    // Extract number from string like "10 Filled Cylinders"
    final RegExp regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(itemDetails);
    return match?.group(1) ?? '0';
  }

  void _approveHandover() {
    final quantity = int.tryParse(_extractQuantity(widget.itemDetails)) ?? 0;

    // Update MockData inventory
    final stockItems = MockData.stockItems['warehouse_manager'] ?? [];
    for (int i = 0; i < stockItems.length; i++) {
      if (stockItems[i].name == '14.2kg Cylinders') {
        MockData.stockItems['warehouse_manager']![i] = StockItem(
          name: stockItems[i].name,
          available: stockItems[i].available + quantity,
          total: stockItems[i].total,
          color: _getColorForStock(stockItems[i].available + quantity, stockItems[i].total),
        );
        break;
      }
    }

    // Update approval status
    final approvalItems = MockData.approvalItems['warehouse_manager'] ?? [];
    for (int i = 0; i < approvalItems.length; i++) {
      if (approvalItems[i]['id'] == widget.transferId) {
        MockData.approvalItems['warehouse_manager']![i]['status'] = 'Approved';
        break;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Handover Approved'),
        content: const Text('The transfer has been successfully approved.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog

              // Return with result to trigger refresh
              Navigator.of(context).pop(true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _getColorForStock(int available, int total) {
    final percentage = available / total;
    if (percentage > 0.7) return Colors.green;
    if (percentage > 0.3) return Colors.amber;
    return Colors.red;
  }
}