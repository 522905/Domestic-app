import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../core/services/api_service_interface.dart';
import '../../core/services/User.dart';
import '../../l10n/app_localizations.dart';

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

  // User role state
  List<String> _userRoles = [];
  bool _isWarehouseManager = false;

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadUserRole();
    _fetchWarehouses();
  }

  Future<void> _loadUserRole() async {
    try {
      final roles = await User().getUserRoles();
      setState(() {
        _userRoles = roles.map((role) => role.role).toList();
        _isWarehouseManager = _userRoles.contains('Warehouse Manager');
      });
    } catch (e) {
      // If role fetch fails, default to showing limited data
      setState(() {
        _isWarehouseManager = false;
      });
    }
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
          _selectedWarehouseId = _warehouses[0]['id'] as int? ?? 0;
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
                      AppLocalizations.of(context)!.warehouseStockTitle,
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
    // Sort warehouses: Sherpur Godown first, then Focal Point, then others
    final sortedWarehouses = List<Map<String, dynamic>>.from(_warehouses);
    sortedWarehouses.sort((a, b) {
      final labelA = (a['warehouse_label'] as String? ?? '').toLowerCase();
      final labelB = (b['warehouse_label'] as String? ?? '').toLowerCase();

      // Sherpur should come first
      if (labelA.contains('sherpur')) return -1;
      if (labelB.contains('sherpur')) return 1;

      // Focal Point should come second
      if (labelA.contains('focal')) return -1;
      if (labelB.contains('focal')) return 1;

      // Others maintain their order
      return 0;
    });

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: sortedWarehouses.map((warehouse) {
          final warehouseId = warehouse['id'] as int? ?? 0;
          final warehouseLabel = warehouse['warehouse_label'] as String? ?? 'Unknown';
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
              AppLocalizations.of(context)!.warehouseStockLoading,
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
    var stockList = _stockData!['stock_data'] as List<dynamic>;
    final warehousesMerged = _stockData!['warehouses_merged'] as bool? ?? false;
    final warehousesCount = _stockData!['warehouses_count'] as int? ?? 1;

    // Filter stock list for Delivery Boy - only show "Filled" items
    if (!_isWarehouseManager) {
      stockList = stockList.where((item) {
        final itemGroup = (item['item_group'] as String? ?? '').toLowerCase();
        return itemGroup.contains('filled');
      }).toList();
    }

    // Get total items count based on filtered list
    final totalItems = stockList.length;

    // Find the selected warehouse name
    final selectedWarehouse = _warehouses.firstWhere(
      (w) => w['id'] == _selectedWarehouseId,
      orElse: () => {'warehouse_label': AppLocalizations.of(context)!.warehouseStockUnknownWarehouse},
    );
    final warehouseName = selectedWarehouse['warehouse_label'] as String? ?? AppLocalizations.of(context)!.warehouseStockUnknownWarehouse;

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
            child: Column(
              children: [
                Row(
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
                        AppLocalizations.of(context)!.warehouseStockItems(totalItems.toString()),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Show merged warehouses info if applicable
                if (warehousesMerged && warehousesCount > 1) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.merge_type,
                          size: 14.sp,
                          color: Colors.orange.shade700,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          AppLocalizations.of(context)!.warehouseStockMergedFrom(warehousesCount.toString()),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Stock items list
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppLocalizations.of(context)!.warehouseStockDetails,
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
    final context = this.context;
    final itemName = item['item_name'] as String? ?? AppLocalizations.of(context)!.warehouseStockUnknownItem;
    final itemCode = item['item_code'] as String? ?? '';
    final itemGroup = item['item_group'] as String? ?? '';
    final actualQty = ((item['actual_qty'] as num?) ?? 0).toInt();
    final reservedQty = ((item['reserved_qty'] as num?) ?? 0).toInt();
    final projectedQty = ((item['projected_qty'] as num?) ?? 0).toInt();
    final stockUom = item['stock_uom'] as String? ?? 'Unit';

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
          // Item Name
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  itemName,
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

          // Item Code and Group
          if (itemCode.isNotEmpty || itemGroup.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side - Item Code
                if (itemCode.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.tag,
                        size: 12.sp,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        itemCode,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  )
                else
                  const SizedBox.shrink(),

                // Right side - Item Group
                if (itemGroup.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5CA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      itemGroup,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFF0E5CA8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],

          SizedBox(height: 8.h),

          // Quantity chips - conditional based on user role
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return Row(
                children: [
                  // Warehouse Manager: Show all quantities
                  if (_isWarehouseManager) ...[
                    _buildQuantityChip(l10n.warehouseStockAvailable, actualQty, const Color(0xFF4CAF50)),
                    SizedBox(width: 4.w),
                    if (reservedQty > 0) ...[
                      _buildQuantityChip(l10n.warehouseStockReserved, reservedQty, const Color(0xFFFFC107)),
                      SizedBox(width: 4.w),
                    ],
                    _buildQuantityChip(l10n.warehouseStockProjected, projectedQty, const Color(0xFF2196F3)),
                  ]
                  // Delivery Boy: Show only projected
                  else ...[
                    _buildQuantityChip(l10n.warehouseStockProjected, projectedQty, const Color(0xFF2196F3)),
                  ],
                ],
              );
            }
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