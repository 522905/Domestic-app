// lib/presentation/widgets/order/order_items_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/order/selectable_order_item.dart';
import '../../../core/models/order/order_data.dart';
import '../professional_snackbar.dart';
import 'quota_badge.dart';

class OrderItemsWidget extends StatefulWidget {
  final OrderData orderData;
  final List<SelectableOrderItem> selectedItems;
  final Function(List<SelectableOrderItem>) onItemsChanged;

  const OrderItemsWidget({
    Key? key,
    required this.orderData,
    required this.selectedItems,
    required this.onItemsChanged,
  }) : super(key: key);

  @override
  State<OrderItemsWidget> createState() => _OrderItemsWidgetState();
}

class _OrderItemsWidgetState extends State<OrderItemsWidget> {
  String _searchQuery = '';
  String? _selectedItemGroupFilter;
  String? _selectedAvailabilityFilter;
  String? _selectedBucketFilter;
  late List<SelectableOrderItem> _availableItems;
  List<ActiveExtensionDetail> _activeExtensions = [];
  bool _useCreditExtension = false;  // Toggle state (default OFF)
  bool _isSearching = false;  // Search mode state
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _availableItems = widget.orderData.getSelectableItems();
    _selectedAvailabilityFilter = 'Available';
    _loadActiveExtensions();
  }

  @override
  void didUpdateWidget(OrderItemsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderData != widget.orderData) {
      _availableItems = widget.orderData.getSelectableItems();
      _loadActiveExtensions();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadActiveExtensions() {
    // Extract unique extensions from items
    final extensionsMap = <String, ActiveExtensionDetail>{};
    for (var item in _availableItems) {
      if (item.quota?.hasActiveExtension ?? false) {
        for (var ext in item.quota!.extensions) {
          extensionsMap[ext.itemCode] = ext;
        }
      }
    }
    setState(() {
      _activeExtensions = extensionsMap.values.toList();
    });
  }

  SelectableOrderItem _applyExtensionToggle(SelectableOrderItem item) {
    // If toggle is ON or item has no quota, return unchanged
    if (_useCreditExtension || item.quota == null) {
      return item;
    }

    // Toggle is OFF - hide extension quota
    final originalQuota = item.quota!;

    // Create modified quota without extension (only hide extension, keep base quota unchanged)
    final modifiedQuota = QuotaInfo(
      available: originalQuota.available,  // Keep original quota value
      isBlocked: originalQuota.isBlocked,  // Keep original blocked state (don't recalculate)
      isQuotaEnforced: originalQuota.isQuotaEnforced,
      isQuotaDisabled: originalQuota.isQuotaDisabled,
      isSdmsDown: originalQuota.isSdmsDown,
      isPartnerExempt: originalQuota.isPartnerExempt,
      extensionAvailable: 0,  // Hide extension
      effectiveLimit: originalQuota.available > 0 ? originalQuota.available : 0,  // Only base quota, no extension
      hasActiveExtension: false,  // Hide extension indicator
      extensions: [],  // Clear extensions
    );

    return item.copyWith(quota: modifiedQuota);
  }

  List<SelectableOrderItem> get _filteredItems {
    var items = _availableItems;

    // Apply item group filter
    if (_selectedItemGroupFilter != null) {
      items = items.where((item) {
        return item.metadata['item_group'] == _selectedItemGroupFilter;
      }).toList();
    }

    // Apply availability filter
    if (_selectedAvailabilityFilter != null) {
      items = items.where((item) {
        return item.availabilityStatus == _selectedAvailabilityFilter;
      }).toList();
    }

    // Apply bucket filter
    if (_selectedBucketFilter != null) {
      items = items.where((item) {
        return item.type == _selectedBucketFilter;
      }).toList();
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) {
        final itemName = item.itemName.toLowerCase();
        final itemCode = item.itemCode.toLowerCase();
        final description = item.description.toLowerCase();
        final query = _searchQuery.toLowerCase();
        return itemName.contains(query) ||
            itemCode.contains(query) ||
            description.contains(query);
      }).toList();
    }

    // Apply extension toggle to all filtered items
    return items.map((item) => _applyExtensionToggle(item)).toList();
  }

  bool _isItemSelected(SelectableOrderItem item) {
    return widget.selectedItems.any((selected) => selected.id == item.id);
  }

  SelectableOrderItem? _getSelectedItem(SelectableOrderItem item) {
    try {
      return widget.selectedItems.firstWhere((selected) => selected.id == item.id);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // _buildHeader(),  // Commented out - not required for now
        _buildCreditExtensionToggle(),
        _buildFilterOptions(),
        Expanded(child: _buildItemsList()),
      ],
    );
  }


  Widget _buildHeader() {
    final orderType = widget.orderData.orderType;
    final color = orderType == 'Refill' ? Colors.blue : Colors.orange;
    final icon = orderType == 'Refill' ? Icons.inventory_2_outlined : Icons.inventory;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (!_isSearching) ...[
            Icon(icon, color: color, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$orderType Items',
                    style: TextStyle(
                      color: color,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Select items for your $orderType order',
                    style: TextStyle(
                      color: color,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.selectedItems.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  '${widget.selectedItems.length} selected',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
            ],
            IconButton(
              icon: Icon(Icons.search, color: color),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          ] else ...[
            Expanded(
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                style: TextStyle(fontSize: 16.sp),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
            IconButton(
              icon: Icon(Icons.close, color: color),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditExtensionToggle() {
    // Only show toggle if user has active extensions
    if (_activeExtensions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _useCreditExtension ? Colors.purple.shade50 : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: _useCreditExtension ? Colors.purple.shade200 : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.card_giftcard,
            color: _useCreditExtension ? Colors.purple.shade700 : Colors.grey[600],
            size: 22.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use Credit Extension',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _useCreditExtension
                    ? 'Credit extensions are included in quota'
                    : 'Order within base quota only',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _useCreditExtension,
            onChanged: (value) {
              setState(() {
                _useCreditExtension = value;
              });
              // Show feedback
              if (value) {
                context.showSuccessSnackBar('Credit extension enabled');
              } else {
                context.showWarningSnackBar('Credit extension disabled - ordering within base quota');
              }
            },
            activeColor: Colors.purple.shade700,
          ),
        ],
      ),
    );
  }


  Widget _buildFilterOptions() {
    final itemGroupFilters = widget.orderData.getItemGroupFilters();
    final availabilityFilters = widget.orderData.getAvailabilityFilters();
    final bucketFilters = widget.orderData.getBucketFilters();

    if (itemGroupFilters.isEmpty && availabilityFilters.isEmpty && bucketFilters.isEmpty) {
      return const SizedBox.shrink();
    }

    // Split availability filters into "Available" and others
    final availableFilters = availabilityFilters
        .where((filter) =>
    filter['value']?.toString().toLowerCase() == 'available')
        .toList();

    final otherAvailabilityFilters = availabilityFilters
        .where((filter) =>
    filter['value']?.toString().toLowerCase() != 'available')
        .toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1) All
                _buildFilterChip('All', null, FilterType.all, Colors.grey),
                SizedBox(width: 8.w),

                // 2) Available (forced to second position if it exists)
                if (availableFilters.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _buildFilterChip(
                      '${availableFilters.first['value']} (${availableFilters.first['count']})',
                      availableFilters.first['value'],
                      FilterType.availability,
                      _getAvailabilityColor(availableFilters.first['value']),
                    ),
                  ),

                // Bucket filters
                ...bucketFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.bucket,
                        Colors.blue,
                      ),
                    ),
                ),

                // Item Group filters
                ...itemGroupFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.itemGroup,
                        Colors.green,
                      ),
                    ),
                ),

                // Remaining availability filters (Filled, Filled Cylinder, Out of Stock, etc.)
                ...otherAvailabilityFilters.map((filter) =>
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: _buildFilterChip(
                        '${filter['value']} (${filter['count']})',
                        filter['value'],
                        FilterType.availability,
                        _getAvailabilityColor(filter['value']),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, FilterType type, Color color) {
    bool isSelected = false;

    switch (type) {
      case FilterType.all:
        isSelected = _selectedItemGroupFilter == null &&
            _selectedAvailabilityFilter == null &&
            _selectedBucketFilter == null;
        break;
      case FilterType.itemGroup:
        isSelected = _selectedItemGroupFilter == value;
        break;
      case FilterType.availability:
        isSelected = _selectedAvailabilityFilter == value;
        break;
      case FilterType.bucket:
        isSelected = _selectedBucketFilter == value;
        break;
    }

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          switch (type) {
            case FilterType.all:
              _selectedItemGroupFilter = null;
              _selectedAvailabilityFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.itemGroup:
              _selectedItemGroupFilter = selected ? value : null;
              _selectedAvailabilityFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.availability:
              _selectedAvailabilityFilter = selected ? value : null;
              _selectedItemGroupFilter = null;
              _selectedBucketFilter = null;
              break;
            case FilterType.bucket:
              _selectedBucketFilter = selected ? value : null;
              _selectedItemGroupFilter = null;
              _selectedAvailabilityFilter = null;
              break;
          }
        });
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? color : Colors.grey[300]!,
          width: 1,
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.orderData.orderType == 'Refill'
                  ? Icons.local_gas_station_outlined
                  : Icons.inventory_2_outlined,
              size: 64.sp,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16.h),
            Text(
              _searchQuery.isNotEmpty ? 'No items match your search' : 'No items available',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  child: const Text('Clear search'),
                ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildItemCard(item);
      },
    );
  }

  Widget _buildItemCard(SelectableOrderItem item) {
    final isSelected = _isItemSelected(item);
    final selectedItem = _getSelectedItem(item);
    final orderType = widget.orderData.orderType;

    // base color from orderType
    final baseColor = orderType == 'Refill' ? Colors.blue : Colors.orange;

    // final color based on itemCode override
    final color = _getItemColor(item.itemCode, baseColor);

    final isOutOfStock = item.isOutOfStock;
    final isSelectable = item.isSelectable;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
          width: 2,
        ),
      ),
      child: Opacity(
        opacity: !isSelectable ? 0.6 : 1.0,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Icon(
                      orderType == 'Refill' ? Icons.propane_tank : Icons.propane_tank_outlined,
                      color: color,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                            color: isOutOfStock ? Colors.grey : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Code: ${item.itemCode}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (item.metadata['item_group'] != null)
                          Text(
                            'Group: ${item.metadata['item_group']}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Text(
                              'Stock: ${item.maxQuantity}',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: isOutOfStock ? Colors.red[700] : Colors.green[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            // Show quota badge if quota info is available
                            if (item.quota != null) ...[
                              QuotaBadge(quota: item.quota!),
                              SizedBox(width: 8.w),
                            ],
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: _getAvailabilityColor(item.availabilityStatus).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4.r),
                                border: Border.all(
                                  color: _getAvailabilityColor(item.availabilityStatus),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                item.availabilityStatus,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: _getAvailabilityColor(item.availabilityStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12.h),
              if (!isSelected)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: !isSelectable ? () {
                      // If blocked but extension available, suggest enabling
                      if (item.quota?.isBlocked ?? false) {
                        if (!_useCreditExtension && _activeExtensions.any((e) => e.itemCode == item.itemCode)) {
                          context.showWarningSnackBar(
                            'Enable "Use Credit Extension" toggle to order this item'
                          );
                          return;
                        }
                        context.showErrorSnackBar('${item.displayName} - Over quota limit');
                      } else {
                        context.showErrorSnackBar('${item.displayName} is out of stock');
                      }
                    } : () => _showQuantityDialog(item),
                    icon: Icon(
                      !isSelectable ? Icons.block : Icons.add_shopping_cart,
                      size: 18.sp,
                    ),
                    label: Text(_getButtonText(item)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isSelectable ? Colors.grey : color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showQuantityDialog(item),
                        icon: Icon(Icons.edit, size: 16.sp),
                        label: Text('Qty: ${selectedItem?.metadata['selected_qty'] ?? 0}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _removeItem(item),
                        icon: Icon(Icons.delete, size: 16.sp),
                        label: const Text('Remove'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAvailabilityColor(String status) {
    switch (status.toLowerCase()) {
      case 'in stock':
        return Colors.green;
      case 'out of stock':
        return Colors.red;
      case 'low stock':
        return Colors.orange;
      case 'limited stock':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Color _getItemColor(String itemCode, Color defaultColor) {
    switch (itemCode) {
      case 'M00087':
      case 'M00104':
        return Colors.red;
      case 'M00218':
        return Colors.blue;
      default:
        return defaultColor;
    }
  }

  String _getButtonText(SelectableOrderItem item) {
    if (item.quota?.isBlocked ?? false) {
      // Check if extension would help
      if (!_useCreditExtension && _activeExtensions.any((e) => e.itemCode == item.itemCode)) {
        return 'Quota: ${item.quota!.available} - Enable Extension';
      }
      return 'Over Quota: ${item.quota!.available}';
    } else if (item.isOutOfStock) {
      return 'Out of Stock';
    } else {
      return 'Select Item';
    }
  }

  Color _getQuotaWarningColor(QuotaInfo quota) {
    switch (quota.status) {
      case QuotaStatus.available:
        return Colors.green;
      case QuotaStatus.low:
        return Colors.orange;
      case QuotaStatus.zero:
      case QuotaStatus.blocked:
        return Colors.red;
      case QuotaStatus.unlimited:
        return Colors.blue;
    }
  }

  IconData _getQuotaWarningIcon(QuotaInfo quota) {
    switch (quota.status) {
      case QuotaStatus.available:
        return Icons.check_circle;
      case QuotaStatus.low:
        return Icons.warning;
      case QuotaStatus.zero:
      case QuotaStatus.blocked:
        return Icons.cancel;
      case QuotaStatus.unlimited:
        return Icons.verified;
    }
  }

  void _showQuantityDialog(SelectableOrderItem item) async {
    final selectedItem = _getSelectedItem(item);
    int selectedQty = selectedItem?.metadata['selected_qty'] ?? 1;
    final maxQty = item.effectiveMaxQuantity;
    late TextEditingController quantityController;

    // Don't allow selection if not selectable (out of stock or over quota)
    if (!item.isSelectable) {
      if (item.quota?.isBlocked ?? false) {
        context.showErrorSnackBar('${item.displayName} - Over quota limit');
      } else {
        context.showErrorSnackBar('${item.displayName} is out of stock');
      }
      return;
    }

    quantityController = TextEditingController(text: selectedQty.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: const Text(
            'Select Quantity',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(5.w),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16.sp,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Code: ${item.itemCode}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _getAvailabilityColor(item.availabilityStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(
                              color: _getAvailabilityColor(item.availabilityStatus),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            item.availabilityStatus,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: _getAvailabilityColor(item.availabilityStatus),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // Show quota info if available
                  if (item.quota != null && item.quota!.hasQuotaLimit) ...[
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: _getQuotaWarningColor(item.quota!).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: _getQuotaWarningColor(item.quota!),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getQuotaWarningIcon(item.quota!),
                                color: _getQuotaWarningColor(item.quota!),
                                size: 16.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'Quota Limited',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _getQuotaWarningColor(item.quota!),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'Stock: ${item.maxQuantity}  |  Quota: ${item.quota!.available}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            'Maximum: $maxQty units',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: _getQuotaWarningColor(item.quota!),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Extension info in quantity dialog
                    if (item.quota!.hasActiveExtension && item.quota!.extensionAvailable > 0) ...[
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.card_giftcard,
                                  color: Colors.purple.shade700,
                                  size: 16.sp
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Credit Extension Active',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade900,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Regular Quota:',
                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                                ),
                                Text(
                                  '${item.quota!.available} units',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: item.quota!.available < 0
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Extension:',
                                  style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
                                ),
                                Text(
                                  '+${item.quota!.extensionAvailable} units',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 16.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Available:',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade900,
                                  ),
                                ),
                                Text(
                                  '${item.quota!.effectiveLimit} units',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Maximum available:',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14.sp,
                          ),
                        ),
                        Text(
                          '$maxQty',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: selectedQty > 1 ? () {
                            setDialogState(() {
                              selectedQty--;
                              quantityController.text = selectedQty.toString();
                            });
                          } : null,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      SizedBox(
                        width: 80.w,
                        child: TextField(
                          controller: quantityController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          onTap: () {
                            quantityController.selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: quantityController.text.length,
                            );
                          },
                          onChanged: (value) {
                            final parsedValue = int.tryParse(value);
                            if (parsedValue != null && parsedValue >= 1 && parsedValue <= maxQty) {
                              setDialogState(() {
                                selectedQty = parsedValue;
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: selectedQty < maxQty ? () {
                            setDialogState(() {
                              selectedQty++;
                              quantityController.text = selectedQty.toString();
                            });
                          } : null,
                        ),
                      ),
                    ],
                  ),
                  if (maxQty == 0) ...[
                    SizedBox(height: 16.h),
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 20.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              'This item is currently out of stock',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 12.sp,
                                fontStyle: FontStyle.italic,
                              ),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: maxQty == 0 ? null : () async {
                final finalQty = int.tryParse(quantityController.text) ?? selectedQty;
                if (finalQty >= 1 && finalQty <= maxQty) {
                  _updateItemSelection(item, finalQty);
                  Navigator.pop(context);

                  // Show success message
                  context.showSuccessSnackBar('Added $finalQty × ${item.displayName}');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(selectedItem != null ? 'Update' : 'Add to Order'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemSelection(SelectableOrderItem item, int quantity) {
    final updatedItems = List<SelectableOrderItem>.from(widget.selectedItems);

    // Remove existing item if present
    updatedItems.removeWhere((selected) => selected.id == item.id);

    // Add new item with updated quantity
    final newItem = SelectableOrderItem(
      id: item.id,
      itemCode: item.itemCode,
      itemName: item.itemName,
      description: item.description,
      type: item.type,
      maxQuantity: item.maxQuantity,
      availabilityStatus: item.availabilityStatus,
      metadata: {
        ...item.metadata,
        'selected_qty': quantity,
      },
      quota: item.quota,
    );

    updatedItems.add(newItem);
    widget.onItemsChanged(updatedItems);
  }

  void _removeItem(SelectableOrderItem item) {
    final updatedItems = List<SelectableOrderItem>.from(widget.selectedItems);
    updatedItems.removeWhere((selected) => selected.id == item.id);
    widget.onItemsChanged(updatedItems);

    // Show removal message
    context.showWarningSnackBar('Removed ${item.displayName} from order');
  }
}

enum FilterType {
  all,
  availability,
  itemGroup,
  bucket,
}
