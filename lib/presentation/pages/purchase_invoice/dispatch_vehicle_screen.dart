import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional_snackbar.dart';

class DispatchVehicleScreen extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final List<Map<String, dynamic>>? invoiceItems;

  const DispatchVehicleScreen({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    this.invoiceItems,
  }) : super(key: key);

  @override
  State<DispatchVehicleScreen> createState() => _DispatchVehicleScreenState();
}

class _DispatchVehicleScreenState extends State<DispatchVehicleScreen> {
  late ApiServiceInterface _apiService;

  // State variables
  Map<String, List<Map<String, dynamic>>> _availableItems = {};
  List<Map<String, dynamic>> _selectedItems = [];

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Mock serial numbers for demonstration
  final List<String> _mockSerialNumbers = [
    'SN001234',
    'SN005678',
    'SN009012',
    'SN003456',
    'SN007890',
    'SN001122',
    'SN003344',
    'SN005566',
    'SN007788',
    'SN009900',
  ];

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadAvailableItems();
  }

  Future<void> _loadAvailableItems() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final itemsData = await _apiService.getUnlinkedItemList();

      // Debug: Print the actual response structure
      print('API Response: $itemsData');

      // Check if the response has the expected structure
      if (itemsData == null) {
        throw Exception('API returned null response');
      }

      if (itemsData is! Map<String, dynamic>) {
        throw Exception('API response is not a valid Map');
      }

      final bucketsData = itemsData['buckets'];
      if (bucketsData == null) {
        throw Exception('No buckets found in API response');
      }

      // Process buckets data
      Map<String, List<Map<String, dynamic>>> processedBuckets = {};

      if (bucketsData is Map) {
        bucketsData.forEach((key, value) {
          if (value is List) {
            processedBuckets[key.toString()] = value
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
          }
        });
      }

      setState(() {
        _availableItems = processedBuckets;
        _isLoading = false;
      });

      // Debug: Print processed buckets
      print('Processed buckets: $_availableItems');

    } catch (e) {
      print('Error in _loadAvailableItems: $e');
      setState(() {
        _errorMessage = 'Failed to load items: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showItemSelectionDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _buildItemSelectionPage(),
      ),
    );
  }

  Widget _buildItemSelectionPage() {
    return StatefulBuilder(
      builder: (context, setPageState) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Select Items to Dispatch'),
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
            actions: [
              if (_selectedItems.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15.r),
                      ),
                      child: Text(
                        '${_selectedItems.length} items',
                        style: TextStyle(
                          color: const Color(0xFF0E5CA8),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.sp,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _buildItemsList(setPageState),
              ),
              if (_selectedItems.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5CA8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'Back to Dispatch Screen',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItemsList(StateSetter setPageState) {
    if (_availableItems.isEmpty) {
      return const Center(
        child: Text('No items available'),
      );
    }

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: _availableItems.entries.map((bucketEntry) {
        String bucketName = bucketEntry.key;
        List<Map<String, dynamic>> items = bucketEntry.value;

        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bucket Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF0E5CA8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(
                  color: const Color(0xFF0E5CA8).withOpacity(0.3),
                ),
              ),
              child: Text(
                bucketName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0E5CA8),
                ),
              ),
            ),

            // Items in bucket
            ...items.map((item) {
              final isSelected = _selectedItems.any(
                      (selected) => selected['item_code'] == item['item_code']
              );

              final selectedItem = isSelected
                  ? _selectedItems.firstWhere(
                      (selected) => selected['item_code'] == item['item_code']
              )
                  : null;

              // Get serial numbers count for defective items
              final serialNosCount = selectedItem?['serial_nos']?.length ?? 0;

              return Card(
                margin: EdgeInsets.only(bottom: 12.h),
                elevation: isSelected ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF0E5CA8) : Colors.transparent,
                    width: 2,
                  ),
                ),
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
                              color: bucketName == 'Defective'
                                  ? Colors.red.withOpacity(0.1)
                                  : const Color(0xFF0E5CA8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25.r),
                            ),
                            child: Icon(
                              bucketName == 'Defective' ? Icons.warning : Icons.inventory_2,
                              color: bucketName == 'Defective' ? Colors.red : const Color(0xFF0E5CA8),
                              size: 24.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['item_name'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Code: ${item['item_code'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Container(
                                  margin: EdgeInsets.only(top: 4.h),
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: bucketName == 'Empty'
                                        ? Colors.blue.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    bucketName,
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: bucketName == 'Empty'
                                          ? Colors.blue.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (item['item_group'] != null)
                                  Text(
                                    'Group: ${item['item_group']}',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: const BoxDecoration(
                                color: Color(0xFF0E5CA8),
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
                          child: ElevatedButton(
                            onPressed: () => _showQuantityDialog(item, bucketName, setPageState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0E5CA8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: const Text('Select'),
                          ),
                        )
                      else
                        Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _showQuantityDialog(item, bucketName, setPageState),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF0E5CA8),
                                      side: const BorderSide(color: Color(0xFF0E5CA8)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    child: Text('Qty: ${selectedItem?['quantity'] ?? 0}'),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _removeItem(item, setPageState),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                    ),
                                    child: const Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                            // Show serial numbers button for defective items
                            if (bucketName == 'Defective' && isSelected) ...[
                              SizedBox(height: 8.h),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _showSerialNumberDialog(item, selectedItem!, setPageState),
                                  icon: Icon(Icons.qr_code_scanner, size: 18.sp),
                                  label: Text(
                                    serialNosCount > 0
                                        ? 'Serial Nos: $serialNosCount selected'
                                        : 'Select Serial Numbers',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: serialNosCount > 0 ? Colors.green : Colors.orange,
                                    side: BorderSide(
                                      color: serialNosCount > 0 ? Colors.green : Colors.orange,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            SizedBox(height: 16.h),
          ],
        );
      }).toList(),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> item, String bucketName, StateSetter setPageState) {
    final selectedItem = _selectedItems.firstWhere(
          (selected) => selected['item_code'] == item['item_code'],
      orElse: () => <String, dynamic>{},
    );

    int selectedQty = selectedItem['quantity'] ?? 1;
    ///TODO here to change the available quantity from API
    int maxQty = item['available_qty'] ?? 999; // Get available quantity limit
    late TextEditingController quantityController;
    quantityController = TextEditingController(text: selectedQty.toString());

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Select Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item['item_name'] ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Code: ${item['item_code'] ?? ''}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Available: $maxQty',
                style: TextStyle(
                  color: Colors.green[600],
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: selectedQty > 1 ? () {
                      setDialogState(() {
                        selectedQty--;
                        quantityController.text = selectedQty.toString();
                      });
                    } : null,
                  ),
                  SizedBox(
                    width: 80.w,
                    child: TextField(
                      controller: quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        errorText: selectedQty > maxQty ? 'Exceeds limit' : null,
                      ),
                      onChanged: (value) {
                        final parsedValue = int.tryParse(value);
                        if (parsedValue != null && parsedValue >= 1) {
                          setDialogState(() {
                            selectedQty = parsedValue;
                          });
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: selectedQty < maxQty ? () {
                      setDialogState(() {
                        selectedQty++;
                        quantityController.text = selectedQty.toString();
                      });
                    } : null,
                  ),
                ],
              ),
              if (selectedQty > maxQty) ...[
                SizedBox(height: 8.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 16.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'Quantity cannot exceed available limit of $maxQty',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedQty >= 1 && selectedQty <= maxQty ? () {
                final finalQty = int.tryParse(quantityController.text) ?? selectedQty;
                if (finalQty >= 1 && finalQty <= maxQty) {
                  _updateItemSelection(item, finalQty, bucketName, setPageState);
                  Navigator.pop(context);
                } else {
                  // Show snackbar for invalid quantity
                  context.showErrorSnackBar('Quantity must be between 1 and $maxQty');
                }
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedQty >= 1 && selectedQty <= maxQty
                    ? const Color(0xFF0E5CA8)
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateItemSelection(Map<String, dynamic> item, int quantity, String returnType, StateSetter setPageState) {
    setPageState(() {
      setState(() {
        // Remove existing item if present
        _selectedItems.removeWhere(
                (selected) => selected['item_code'] == item['item_code']
        );

        // Add new item with updated quantity and return type
        final newItem = {
          'item_code': item['item_code'],
          'item_name': item['item_name'],
          'quantity': quantity,
          'return_type': returnType,
        };

        // If defective, initialize empty serial numbers list
        if (returnType == 'Defective') {
          newItem['serial_nos'] = <String>[];
        }

        _selectedItems.add(newItem);
      });
    });
  }

  void _showSerialNumberDialog(Map<String, dynamic> item, Map<String, dynamic> selectedItem, StateSetter setPageState) {
    final int quantity = selectedItem['quantity'] ?? 1;
    final List<String> currentSerialNos = List<String>.from(selectedItem['serial_nos'] ?? []);
    List<String> tempSelectedSerials = List<String>.from(currentSerialNos);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Serial Numbers'),
              SizedBox(height: 4.h),
              Text(
                'Select $quantity serial number(s)',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['item_name'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),
                Text(
                  'Code: ${item['item_code'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: tempSelectedSerials.length == quantity
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: tempSelectedSerials.length == quantity
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tempSelectedSerials.length == quantity
                            ? Icons.check_circle
                            : Icons.info_outline,
                        size: 16.sp,
                        color: tempSelectedSerials.length == quantity
                            ? Colors.green
                            : Colors.orange,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${tempSelectedSerials.length} of $quantity selected',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: tempSelectedSerials.length == quantity
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _mockSerialNumbers.length,
                    itemBuilder: (context, index) {
                      final serialNo = _mockSerialNumbers[index];
                      final isSelected = tempSelectedSerials.contains(serialNo);
                      final canSelect = tempSelectedSerials.length < quantity || isSelected;

                      return CheckboxListTile(
                        title: Text(
                          serialNo,
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        value: isSelected,
                        enabled: canSelect,
                        onChanged: canSelect
                            ? (bool? value) {
                          setDialogState(() {
                            if (value == true && !isSelected) {
                              tempSelectedSerials.add(serialNo);
                            } else if (value == false && isSelected) {
                              tempSelectedSerials.remove(serialNo);
                            }
                          });
                        }
                            : null,
                        activeColor: const Color(0xFF0E5CA8),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: tempSelectedSerials.length == quantity
                  ? () {
                _updateSerialNumbers(item, tempSelectedSerials, setPageState);
                Navigator.pop(context);
              }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: tempSelectedSerials.length == quantity
                    ? const Color(0xFF0E5CA8)
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSerialNumbers(Map<String, dynamic> item, List<String> serialNumbers, StateSetter setPageState) {
    setPageState(() {
      setState(() {
        final index = _selectedItems.indexWhere(
                (selected) => selected['item_code'] == item['item_code']
        );

        if (index != -1) {
          _selectedItems[index]['serial_nos'] = serialNumbers;
        }
      });
    });
  }

  void _removeItem(Map<String, dynamic> item, StateSetter setPageState) {
    setPageState(() {
      setState(() {
        _selectedItems.removeWhere(
                (selected) => selected['item_code'] == item['item_code']
        );
      });
    });
  }

  Widget _buildInvoiceItemsSection() {
    if (widget.invoiceItems == null || widget.invoiceItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: const Color(0xFF0E5CA8),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Invoice Items',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Column(
                children: widget.invoiceItems!.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == widget.invoiceItems!.length - 1;

                  return Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      border: isLast ? null : const Border(
                        bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0E5CA8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['item_name'] ?? '',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                item['item_code'] ?? '',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5CA8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'Qty: ${item['qty'] ?? '0'}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0E5CA8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitDispatch() async {
    if (_isSubmitting) return;

    if (_selectedItems.isEmpty) {
      context.showErrorSnackBar('Please select at least one item');
      return;
    }

    // Validate defective items have serial numbers
    for (var item in _selectedItems) {
      if (item['return_type'] == 'Defective') {
        final serialNos = item['serial_nos'] as List?;
        final quantity = item['quantity'] as int;
        if (serialNos == null || serialNos.isEmpty) {
          context.showErrorSnackBar(
              'Please select serial numbers for defective item: ${item['item_code']}');
          return;
        }
        if (serialNos.length != quantity) {
          context.showErrorSnackBar(
              'Serial numbers (${serialNos.length}) must match quantity ($quantity) for: ${item['item_code']}');
          return;
        }
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final payload = {
        'supplier_gstin': widget.supplierGstin,
        'supplier_invoice_date': widget.supplierInvoiceDate,
        'supplier_invoice_number': widget.supplierInvoiceNumber,
        'items_dispatched': _selectedItems.map((item) {
          final itemData = {
            'item_code': item['item_code'],
            'quantity': item['quantity'].toString(),
            'return_type': item['return_type'] ?? 'Empty',
          };

          // Add serial number if it's a defective item with serial numbers
          if (item['return_type'] == 'Defective' &&
              item['serial_nos'] != null &&
              (item['serial_nos'] as List).isNotEmpty) {
            // Join serial numbers with comma or send first one (adjust based on your API)
            itemData['serial_no'] = (item['serial_nos'] as List).join(',');
          }

          return itemData;
        }).toList(),
      };

      print('Dispatch Payload: $payload'); // Debug print

      final response = await _apiService.submitDispatchVehicle(payload);

      if (mounted) {
        context.showSuccessSnackBar('Dispatch submitted successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to submit dispatch: $e');
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Dispatch Vehicle',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0E5CA8),
        ),
      )
          : _errorMessage.isNotEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.w,
                color: const Color(0xFFF44336),
              ),
              SizedBox(height: 16.h),
              Text(
                'Error loading items',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: const Color(0xFF666666),
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadAvailableItems,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      )
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Invoice Items Section (from original invoice)
                  _buildInvoiceItemsSection(),
                  // Items Section
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items to Dispatch',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _showItemSelectionDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Select Items'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E5CA8),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 8.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),

                        // Selected Items List or Empty State
                        if (_selectedItems.isEmpty)
                          Center(
                            child: Column(
                              children: [
                                SizedBox(height: 40.h),
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 48.w,
                                  color: const Color(0xFF999999),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'No items selected',
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Tap "Select Items" to get started',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF999999),
                                  ),
                                ),
                                SizedBox(height: 40.h),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: _selectedItems.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;
                              return Container(
                                margin: EdgeInsets.only(bottom: 8.h),
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF0E5CA8),
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                  color: const Color(0xFF0E5CA8).withOpacity(0.05),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['item_code'] ?? '',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14.sp,
                                            ),
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            item['item_name'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0E5CA8),
                                        borderRadius: BorderRadius.circular(12.r),
                                      ),
                                      child: Text(
                                        'Qty: ${item['quantity']}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    IconButton(
                                      onPressed: () {
                                        _showItemSelectionDialog();
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.green,
                                      ),
                                      iconSize: 20.sp,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: 80.h), // Space for submit button
                ],
              ),
            ),
          ),

          // Submit Button
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16.w),
            child: ElevatedButton(
              onPressed: _selectedItems.isNotEmpty && !_isSubmitting
                  ? _submitDispatch
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: _isSubmitting
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Dispatching...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
                  : Text(
                'Dispatch Vehicle',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}