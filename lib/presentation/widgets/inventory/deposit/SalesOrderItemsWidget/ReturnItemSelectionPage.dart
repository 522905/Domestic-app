import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/models/deposit/sales_order_deposit_data.dart';

class ReturnItemSelectionPage extends StatefulWidget {
  final OrderItem orderItem;
  final Map<String, List<Map<String, dynamic>>> eligibleReturns;
  final double maxQuantity;
  final SelectedReturn? editingReturn;

  const ReturnItemSelectionPage({
    Key? key,
    required this.orderItem,
    required this.eligibleReturns,
    required this.maxQuantity,
    this.editingReturn,
  }) : super(key: key);

  @override
  State<ReturnItemSelectionPage> createState() => _ReturnItemSelectionPageState();
}

class _ReturnItemSelectionPageState extends State<ReturnItemSelectionPage> {
  static const List<String> faultTypes = [
    'Valve Damaged',
    'Body Dented',
    'Handle Broken',
    'Thread Damaged',
    'Leak Detected',
    'Corrosion',
    'Other'
  ];

  String _selectedReturnType = 'empty';
  String? _selectedReturnItemCode;
  String? _selectedReturnDescription;

  final _quantityController = TextEditingController(text: '1');
  final _cylinderNumberController = TextEditingController();
  final _tareWeightController = TextEditingController();
  final _grossWeightController = TextEditingController();

  String? _selectedFaultType;
  double _netWeight = 0.0;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _addListeners();
  }

  void _initializeFormData() {
    if (widget.editingReturn != null) {
      final editingReturn = widget.editingReturn!;
      _selectedReturnType = editingReturn.returnType;
      _selectedReturnItemCode = editingReturn.returnItemCode;
      _selectedReturnDescription = editingReturn.returnItemDescription;
      _quantityController.text = editingReturn.qty.toInt().toString();

      if (editingReturn.isDefective) {
        _cylinderNumberController.text = editingReturn.cylinderNumber ?? '';
        _tareWeightController.text = editingReturn.tareWeight?.toString() ?? '';
        _grossWeightController.text = editingReturn.grossWeight?.toString() ?? '';
        _selectedFaultType = editingReturn.faultType;
        _netWeight = editingReturn.netWeight ?? 0.0;
      }
    } else {
      // Set default return item if only one option available
      _setDefaultReturnItem();
    }
  }

  void _addListeners() {
    _quantityController.addListener(_onFormChanged);
    _cylinderNumberController.addListener(_onFormChanged);
    _tareWeightController.addListener(_onFormChanged);
    _grossWeightController.addListener(_onFormChanged);

    _tareWeightController.addListener(_calculateNetWeight);
    _grossWeightController.addListener(_calculateNetWeight);
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  void _calculateNetWeight() {
    final tare = double.tryParse(_tareWeightController.text) ?? 0.0;
    final gross = double.tryParse(_grossWeightController.text) ?? 0.0;
    setState(() {
      _netWeight = gross - tare;
    });
  }

  void _setDefaultReturnItem() {
    final availableReturns = widget.eligibleReturns[_selectedReturnType] ?? [];
    if (availableReturns.isNotEmpty) {
      final firstReturn = availableReturns.first;
      _selectedReturnItemCode = firstReturn['item_code'];
      _selectedReturnDescription = firstReturn['description'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Return Item'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
        ),
        body: Column(
          children: [
            _buildOrderItemHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReturnTypeSelection(),
                    SizedBox(height: 16.h),
                    _buildReturnItemSelection(),
                    SizedBox(height: 16.h),
                    _buildQuantitySection(),
                    if (_selectedReturnType == 'defective') ...[
                      SizedBox(height: 16.h),
                      _buildDefectiveDetailsSection(),
                    ],
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Returning Against',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${widget.orderItem.itemCode} - ${widget.orderItem.itemDescription}',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'SO: ${widget.orderItem.salesOrder}',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Maximum returnable: ${widget.maxQuantity.toInt()}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTypeSelection() {
    final hasEmptyReturns = (widget.eligibleReturns['empty'] ?? []).isNotEmpty;
    final hasDefectiveReturns = (widget.eligibleReturns['defective'] ?? []).isNotEmpty;

    if (!hasEmptyReturns && !hasDefectiveReturns) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            'No eligible return items available',
            style: TextStyle(color: Colors.red, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Return Type',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            if (hasEmptyReturns)
              RadioListTile<String>(
                title: Text('Empty Return'),
                subtitle: Text('${widget.eligibleReturns['empty']!.length} options available'),
                value: 'empty',
                groupValue: _selectedReturnType,
                onChanged: hasEmptyReturns ? (value) {
                  setState(() {
                    _selectedReturnType = value!;
                    _setDefaultReturnItem();
                    if (_selectedReturnType == 'empty') {
                      _quantityController.text = '1';
                    }
                    _onFormChanged();
                  });
                } : null,
              ),
            if (hasDefectiveReturns)
              RadioListTile<String>(
                title: Text('Defective Return'),
                subtitle: Text('${widget.eligibleReturns['defective']!.length} options available'),
                value: 'defective',
                groupValue: _selectedReturnType,
                onChanged: hasDefectiveReturns ? (value) {
                  setState(() {
                    _selectedReturnType = value!;
                    _setDefaultReturnItem();
                    _quantityController.text = '1'; // Always 1 for defective
                    _onFormChanged();
                  });
                } : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReturnItemSelection() {
    final availableReturns = widget.eligibleReturns[_selectedReturnType] ?? [];

    if (availableReturns.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(
            'No ${_selectedReturnType} return items available',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select ${_selectedReturnType.toUpperCase()} Return Item',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            ...availableReturns.map((returnItem) {
              final itemCode = returnItem['item_code'] ?? '';
              final description = returnItem['description'] ?? itemCode;

              return RadioListTile<String>(
                title: Text(description),
                subtitle: Text('Code: $itemCode'),
                value: itemCode,
                groupValue: _selectedReturnItemCode,
                onChanged: (value) {
                  setState(() {
                    _selectedReturnItemCode = value;
                    _selectedReturnDescription = description;
                    _onFormChanged();
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            if (_selectedReturnType == 'defective') ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'Defective returns are always 1 quantity per cylinder',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: _canDecreaseQuantity() ? _decreaseQuantity : null,
                  ),
                  SizedBox(
                    width: 100.w,
                    child: TextField(
                      controller: _quantityController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                      ),
                      onChanged: _onQuantityChanged,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: _canIncreaseQuantity() ? _increaseQuantity : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefectiveDetailsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Defective Item Details',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),

            // Cylinder Number
            TextField(
              controller: _cylinderNumberController,
              decoration: InputDecoration(
                labelText: 'Cylinder Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.qr_code),
              ),
            ),
            SizedBox(height: 16.h),

            // Weights Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tareWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Tare Weight (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _grossWeightController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Gross Weight (kg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Net Weight Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Net Weight: ${_netWeight.toStringAsFixed(2)} kg',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),

            // Fault Type
            DropdownButtonFormField<String>(
              value: _selectedFaultType,
              decoration: InputDecoration(
                labelText: 'Fault Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.warning),
              ),
              items: faultTypes.map((fault) {
                return DropdownMenuItem<String>(
                  value: fault,
                  child: Text(fault),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFaultType = value;
                  _onFormChanged();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _onBackPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: const Text('Cancel'),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ElevatedButton(
              onPressed: _canSave() ? _onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(widget.editingReturn != null ? 'Update' : 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSave() {
    if (_selectedReturnItemCode == null) return false;

    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0 || qty > widget.maxQuantity) return false;

    if (_selectedReturnType == 'defective') {
      if (_cylinderNumberController.text.trim().isEmpty) return false;
      if (_selectedFaultType == null) return false;
      final tare = double.tryParse(_tareWeightController.text);
      final gross = double.tryParse(_grossWeightController.text);
      if (tare == null || gross == null) return false;
    }

    return true;
  }

  bool _canIncreaseQuantity() {
    if (_selectedReturnType == 'defective') return false;
    final currentQty = int.tryParse(_quantityController.text) ?? 0;
    return currentQty < widget.maxQuantity;
  }

  bool _canDecreaseQuantity() {
    if (_selectedReturnType == 'defective') return false;
    final currentQty = int.tryParse(_quantityController.text) ?? 0;
    return currentQty > 1;
  }

  void _increaseQuantity() {
    final currentQty = int.tryParse(_quantityController.text) ?? 0;
    if (currentQty < widget.maxQuantity) {
      _quantityController.text = (currentQty + 1).toString();
    }
  }

  void _decreaseQuantity() {
    final currentQty = int.tryParse(_quantityController.text) ?? 0;
    if (currentQty > 1) {
      _quantityController.text = (currentQty - 1).toString();
    }
  }

  void _onQuantityChanged(String value) {
    final qty = int.tryParse(value);
    if (qty != null && (qty < 1 || qty > widget.maxQuantity)) {
      // Show error or reset to valid range
      if (qty < 1) {
        _quantityController.text = '1';
      } else if (qty > widget.maxQuantity) {
        _quantityController.text = widget.maxQuantity.toInt().toString();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _onBackPressed() async {
    final shouldPop = await _onWillPop();
    if (shouldPop) {
      Navigator.of(context).pop();
    }
  }

  void _onSave() {
    if (!_canSave()) return;

    final selectedReturn = SelectedReturn(
      id: widget.editingReturn?.id ?? const Uuid().v4(),
      returnItemCode: _selectedReturnItemCode!,
      returnItemDescription: _selectedReturnDescription!,
      returnType: _selectedReturnType,
      qty: double.tryParse(_quantityController.text) ?? 1.0,
      againstSalesOrder: widget.orderItem.salesOrder,
      againstSalesOrderItem: widget.orderItem.salesOrderItem,
      againstItemCode: widget.orderItem.itemCode,
      againstItemDescription: widget.orderItem.itemDescription,
      cylinderNumber: _selectedReturnType == 'defective' ? _cylinderNumberController.text.trim() : null,
      tareWeight: _selectedReturnType == 'defective' ? double.tryParse(_tareWeightController.text) : null,
      grossWeight: _selectedReturnType == 'defective' ? double.tryParse(_grossWeightController.text) : null,
      netWeight: _selectedReturnType == 'defective' ? _netWeight : null,
      faultType: _selectedReturnType == 'defective' ? _selectedFaultType : null,
    );

    Navigator.of(context).pop(selectedReturn);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _cylinderNumberController.dispose();
    _tareWeightController.dispose();
    _grossWeightController.dispose();
    super.dispose();
  }
}