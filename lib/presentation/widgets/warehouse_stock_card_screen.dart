import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/services/api_service_interface.dart';

class WarehouseStockCard extends StatefulWidget {
  const WarehouseStockCard({super.key});

  @override
  State<WarehouseStockCard> createState() => _WarehouseStockCardState();
}

class _WarehouseStockCardState extends State<WarehouseStockCard> {
  late ApiServiceInterface _apiService;

  // Warehouse list state
  bool _isLoadingWarehouses = true;
  String? _warehouseError;
  List<Map<String, dynamic>> _warehouses = [];
  int? _selectedWarehouseId;

  // Stock data state
  bool _isLoadingStock = false;
  String? _stockError;
  Map<String, dynamic>? _stockData;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _fetchWarehouses();
  }

  Future<void> _fetchWarehouses() async {
    setState(() {
      _isLoadingWarehouses = true;
      _warehouseError = null;
    });

    try {
      final response = await _apiService.getWarehouses();

      if (response is List && response.isNotEmpty) {
        setState(() {
          _warehouses = response.cast<Map<String, dynamic>>();
          _selectedWarehouseId = _warehouses[0]['id'] as int;
          _isLoadingWarehouses = false;
        });

        // Auto-load stock for first warehouse
        _fetchWarehouseStock(_selectedWarehouseId!);
      } else {
        setState(() {
          _warehouseError = 'No warehouses found';
          _isLoadingWarehouses = false;
        });
      }
    } catch (e) {
      setState(() {
        _warehouseError = 'Failed to load warehouses: $e';
        _isLoadingWarehouses = false;
      });
    }
  }

  Future<void> _fetchWarehouseStock(int warehouseId) async {
    setState(() {
      _isLoadingStock = true;
      _stockError = null;
    });

    try {
      final response = await _apiService.getWarehouseStock(
        warehouseId: warehouseId.toString(),
      );

      if (response['success'] == true) {
        setState(() {
          _stockData = response;
          _isLoadingStock = false;
        });
      } else {
        setState(() {
          _stockError = 'Failed to fetch stock data';
          _isLoadingStock = false;
        });
      }
    } catch (e) {
      setState(() {
        _stockError = 'Error: $e';
        _isLoadingStock = false;
      });
    }
  }

  void _onWarehouseSelected(int warehouseId) {
    if (_selectedWarehouseId != warehouseId) {
      setState(() {
        _selectedWarehouseId = warehouseId;
      });
      _fetchWarehouseStock(warehouseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.inventory_2,
                        color: const Color(0xFF0E5CA8),
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'Warehouse Stock',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                if (!_isLoadingStock && _selectedWarehouseId != null)
                  GestureDetector(
                    onTap: () => _fetchWarehouseStock(_selectedWarehouseId!),
                    child: Icon(
                      Icons.refresh,
                      color: Colors.grey[600],
                      size: 20.sp,
                    ),
                  ),
              ],
            ),
          ),

          // Warehouse selection chips
          if (_isLoadingWarehouses)
            _buildWarehouseLoadingState()
          else if (_warehouseError != null)
            _buildWarehouseErrorState()
          else
            _buildWarehouseChips(),

          // Divider
          if (!_isLoadingWarehouses && _warehouseError == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Divider(height: 1, color: Colors.grey[300]),
            ),

          // Stock content
          if (!_isLoadingWarehouses && _warehouseError == null)
            if (_isLoadingStock)
              _buildStockLoadingState()
            else if (_stockError != null)
              _buildStockErrorState()
            else if (_stockData != null)
                _buildStockContent(),
        ],
      ),
    );
  }

  Widget _buildWarehouseLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          SizedBox(
            width: 16.w,
            height: 16.h,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF0E5CA8),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Loading warehouses...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseErrorState() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red[400],
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _warehouseError!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.red[700],
                ),
              ),
            ),
            TextButton(
              onPressed: _fetchWarehouses,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: _warehouses.map((warehouse) {
          final warehouseId = warehouse['id'] as int;
          final warehouseLabel = warehouse['warehouse_label'] as String;
          final isSelected = _selectedWarehouseId == warehouseId;

          return GestureDetector(
            onTap: () => _onWarehouseSelected(warehouseId),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF0E5CA8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF0E5CA8)
                      : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: Text(
                warehouseLabel,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF333333),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStockLoadingState() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 24.w,
              height: 24.h,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF0E5CA8),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Loading stock data...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockErrorState() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: 32.sp,
          ),
          SizedBox(height: 8.h),
          Text(
            _stockError!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => _fetchWarehouseStock(_selectedWarehouseId!),
            child: Text(
              'Try Again',
              style: TextStyle(
                color: const Color(0xFF0E5CA8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockContent() {
    final stockList = _stockData!['stock_data'] as List<dynamic>;
    final warehouseName = stockList.isNotEmpty
        ? stockList[0]['warehouse'] as String
        : 'Unknown Warehouse';
    final totalItems = _stockData!['total_items'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warehouse info
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8).withOpacity(0.05),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warehouse,
                  color: const Color(0xFF0E5CA8),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    warehouseName,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0E5CA8),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$totalItems items',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Stock items list
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Stock Details',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
        ),

        SizedBox(height: 8.h),

        ...stockList.map((item) => _buildStockItem(item)).toList(),

        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildStockItem(Map<String, dynamic> item) {
    final itemCode = item['item_code'] as String;
    final actualQty = (item['actual_qty'] as num).toInt();
    final reservedQty = (item['reserved_qty'] as num).toInt();
    final projectedQty = (item['projected_qty'] as num).toInt();
    final stockUom = item['stock_uom'] as String;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemCode,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
              Text(
                stockUom,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          Row(
            children: [
              _buildQuantityChip('Available', actualQty, const Color(0xFF4CAF50)),
              SizedBox(width: 4.w),
              if (reservedQty > 0) ...[
                _buildQuantityChip('Reserved', reservedQty, const Color(0xFFFFC107)),
                SizedBox(width: 4.w),
              ],
              _buildQuantityChip('Projected', projectedQty, const Color(0xFF2196F3)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityChip(String label, int quantity, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $quantity',
        style: TextStyle(
          fontSize: 11.sp,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}