import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    'Body Leakage',
    'Pin Broken',
    'Water Filled',
    'Valve Leak',
    'Due To ReTesting',
    'Sperious Cylinder',
    'Bung Leak',
    'OMC',
    'Other'
  ];

  String _selectedReturnType = 'empty';
  String? _selectedReturnItemCode;
  String? _selectedReturnDescription;

  final _quantityController = TextEditingController(text: '1');
  final _cylinderNumberController = TextEditingController();
  final _tareWeightController = TextEditingController();
  final _grossWeightController = TextEditingController();

  // Consumer details controllers
  final _consumerIdController = TextEditingController();
  final _consumerNameController = TextEditingController();
  final _consumerMobileController = TextEditingController();

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

        // Load consumer details
        _consumerIdController.text = editingReturn.consumerNumber ?? '';
        _consumerNameController.text = editingReturn.consumerName ?? '';
        _consumerMobileController.text = editingReturn.consumerMobileNumber ?? '';
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
    _consumerIdController.addListener(_onFormChanged);
    _consumerNameController.addListener(_onFormChanged);
    _consumerMobileController.addListener(_onFormChanged);
    _tareWeightController.addListener(_calculateNetWeight);
    _grossWeightController.addListener(_calculateNetWeight);
  }

  void _onFormChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
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
                      _buildConsumerDetailsSection(),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Maximum returnable: ${widget.maxQuantity.toInt()}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Text(
                'Delivered: ${widget.orderItem.deliveredQty}',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnTypeSelection() {
    final hasEmptyReturns = (widget.eligibleReturns['empty'] ?? []).isNotEmpty;
    final hasFilledReturns = (widget.eligibleReturns['filled'] ?? []).isNotEmpty;
    final hasDefectiveReturns = (widget.eligibleReturns['defective'] ?? []).isNotEmpty;


    if (!hasEmptyReturns && !hasDefectiveReturns && !hasFilledReturns) {
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
                onChanged: (value) {
                  setState(() {
                    _selectedReturnType = value!;
                    _setDefaultReturnItem();
                    _onFormChanged();
                  });
                },
              ),
            if (hasFilledReturns)
              RadioListTile<String>(
                title: Text(
                  'Filled Return',
                  style: TextStyle(
                    color: widget.orderItem.deliveredQty == 0 ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  widget.orderItem.deliveredQty == 0
                      ? 'Not available (no delivered items)'
                      : '${widget.eligibleReturns['filled']!.length} options available',
                  style: TextStyle(
                    color: widget.orderItem.deliveredQty == 0 ? Colors.grey : null,
                  ),
                ),
                value: 'filled',
                groupValue: _selectedReturnType,
                onChanged: widget.orderItem.deliveredQty == 0
                    ? null
                    : (value) {
                  setState(() {
                    _selectedReturnType = value!;
                    _setDefaultReturnItem();
                    _onFormChanged();
                  });
                },
              ),
            if (hasDefectiveReturns)
              RadioListTile<String>(
                title: Text(
                  'Defective Return',
                  style: TextStyle(
                    color: widget.orderItem.deliveredQty == 0 ? Colors.grey : null,
                  ),
                ),
                subtitle: Text(
                  widget.orderItem.deliveredQty == 0
                      ? 'Not available (no delivered items)'
                      : '${widget.eligibleReturns['defective']!.length} options available',
                  style: TextStyle(
                    color: widget.orderItem.deliveredQty == 0 ? Colors.grey : null,
                  ),
                ),
                value: 'defective',
                groupValue: _selectedReturnType,
                onChanged: widget.orderItem.deliveredQty == 0
                    ? null
                    : (value) {
                  setState(() {
                    _selectedReturnType = value!;
                    _setDefaultReturnItem();
                    _quantityController.text = '1'; // Defective always quantity 1
                    _onFormChanged();
                  });
                },
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
            'No return items available for $_selectedReturnType returns',
            style: TextStyle(color: Colors.orange, fontSize: 14.sp),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(5.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Return Item',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            DropdownButtonFormField<String>(
              value: _selectedReturnItemCode,
              decoration: InputDecoration(
                labelText: 'Return Item',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.inventory_2),
              ),
              items: availableReturns.map((item) {
                final itemCode = item['item_code'] as String;
                final description = item['description'] as String;
                return DropdownMenuItem<String>(
                  value: itemCode,
                  child: Text(' $description '),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedReturnItemCode = value;
                  final selectedItem = availableReturns.firstWhere(
                        (item) => item['item_code'] == value,
                  );
                  _selectedReturnDescription = selectedItem['description'];
                  _onFormChanged();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    final isDefective = _selectedReturnType == 'defective';

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
            Row(
              children: [
                IconButton(
                  onPressed: _canDecreaseQuantity() ? _decreaseQuantity : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.blue,
                  iconSize: 32.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    enabled: !isDefective,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    onTap: () {
                      _quantityController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _quantityController.text.length,
                      );
                    },
                    onChanged: _onQuantityChanged,
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: _canIncreaseQuantity() ? _increaseQuantity : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.blue,
                  iconSize: 32.sp,
                ),
              ],
            ),
            if (isDefective) ...[
              SizedBox(height: 8.h),
              Text(
                'Note: Defective returns are limited to quantity 1',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.orange[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerDetailsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.blue[700], size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Consumer Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Consumer Number
            TextField(
              controller: _consumerIdController,
              keyboardType: TextInputType.number,
              maxLength: 16,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: InputDecoration(
                labelText: 'Consumer ID *',
                hintText: 'Enter 16-digit consumer number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.badge),
                counterText: '',
              ),
              onTap: () {
                _consumerIdController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _consumerIdController.text.length,
                );
              },
            ),
            SizedBox(height: 12.h),

            // Consumer Name
            TextField(
              controller: _consumerNameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Consumer Name *',
                hintText: 'Enter consumer name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            SizedBox(height: 12.h),

            // Consumer Mobile Number
            TextField(
              controller: _consumerMobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: 'Consumer Mobile Number *',
                hintText: 'Enter 10-digit mobile number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.phone),
                counterText: '',
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '* All fields are mandatory for defective returns',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
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
            Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700], size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Defective Item Details',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
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
            SizedBox(height: 12.h),

            // Weight Fields
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
                    onTap: () {
                      _tareWeightController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _tareWeightController.text.length,
                      );
                    },
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
                    onTap: () {
                      _grossWeightController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _grossWeightController.text.length,
                      );
                    },
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
    final canSave = _canSave();
    final missingFields = _getMissingFields();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show missing fields hint
          if (!canSave && missingFields.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.sp, color: Colors.orange.shade700),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Please fill: ${missingFields.join(", ")}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
          ],
          Row(
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
                  onPressed: canSave ? _onSave : null,
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
        ],
      ),
    );
  }

// Add this helper method
  List<String> _getMissingFields() {
    List<String> missing = [];

    if (_selectedReturnItemCode == null) missing.add('Return Item');

    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0 || qty > widget.maxQuantity) missing.add('Valid Quantity');

    // Check filled quantity against delivered quantity
    if (_selectedReturnType == 'filled' && qty > widget.orderItem.deliveredQty) {
      missing.add('Filled qty cannot exceed delivered (${widget.orderItem.deliveredQty})');
    }

    if (_selectedReturnType == 'defective') {
      // Check defective quantity against delivered quantity
      if (qty > widget.orderItem.deliveredQty) {
        missing.add('Defective qty cannot exceed delivered (${widget.orderItem.deliveredQty})');
      }

      if (_cylinderNumberController.text.trim().isEmpty) missing.add('Cylinder Number');
      if (_selectedFaultType == null) missing.add('Fault Type');
      final tare = double.tryParse(_tareWeightController.text);
      final gross = double.tryParse(_grossWeightController.text);
      if (tare == null) missing.add('Tare Weight');
      if (gross == null) missing.add('Gross Weight');

      final consumerId = _consumerIdController.text.trim();
      if (consumerId.isEmpty || consumerId.length != 16) missing.add('Consumer ID (16 digits)');
      if (_consumerNameController.text.trim().isEmpty) missing.add('Consumer Name');
      final mobile = _consumerMobileController.text.trim();
      if (mobile.isEmpty || mobile.length != 10) missing.add('Mobile Number (10 digits)');
    }

    return missing;
  }

  bool _canSave() {
    if (_selectedReturnItemCode == null) return false;

    final qty = int.tryParse(_quantityController.text) ?? 0;
    if (qty <= 0 || qty > widget.maxQuantity) return false;

    // Validate filled returns against delivered quantity
    if (_selectedReturnType == 'filled' && qty > widget.orderItem.deliveredQty) {
      return false;
    }

    if (_selectedReturnType == 'defective') {
      // Defective also counts against delivered quantity
      if (qty > widget.orderItem.deliveredQty) {
        return false;
      }

      // Validate defective-specific fields
      if (_cylinderNumberController.text.trim().isEmpty) return false;
      if (_selectedFaultType == null) return false;
      final tare = double.tryParse(_tareWeightController.text);
      final gross = double.tryParse(_grossWeightController.text);
      if (tare == null || gross == null) return false;

      // Validate consumer details (mandatory for defective)
      final consumerId = _consumerIdController.text.trim();
      if (consumerId.isEmpty || consumerId.length != 16) return false;
      if (_consumerNameController.text.trim().isEmpty) return false;
      final mobile = _consumerMobileController.text.trim();
      if (mobile.isEmpty || mobile.length != 10) return false;
    }

    return true;
  }

  bool _canIncreaseQuantity() {
    if (_selectedReturnType == 'defective') return false;
    final currentQty = int.tryParse(_quantityController.text) ?? 0;

    // For filled returns, cap at deliveredQty
    if (_selectedReturnType == 'filled') {
      return currentQty < widget.orderItem.deliveredQty && currentQty < widget.maxQuantity;
    }

    return currentQty < widget.maxQuantity;
  }

  bool _canDecreaseQuantity() {
    if (_selectedReturnType == 'defective') return false;
    final currentQty = int.tryParse(_quantityController.text) ?? 0;
    return currentQty > 1;
  }

  void _increaseQuantity() {
    final currentQty = int.tryParse(_quantityController.text) ?? 0;

    // For filled returns, cap at deliveredQty
    int maxLimit = widget.maxQuantity.toInt();
    if (_selectedReturnType == 'filled') {
      maxLimit = widget.orderItem.deliveredQty < maxLimit
          ? widget.orderItem.deliveredQty
          : maxLimit;
    }

    if (currentQty < maxLimit) {
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
    if (qty != null) {
      int maxLimit = widget.maxQuantity.toInt();

      // For filled returns, cap at deliveredQty
      if (_selectedReturnType == 'filled') {
        maxLimit = widget.orderItem.deliveredQty < maxLimit
            ? widget.orderItem.deliveredQty
            : maxLimit;
      }

      if (qty < 1 || qty > maxLimit) {
        // Show error or reset to valid range
        if (qty < 1) {
          _quantityController.text = '1';
        } else if (qty > maxLimit) {
          _quantityController.text = maxLimit.toString();
        }
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
      consumerNumber: _selectedReturnType == 'defective' ? _consumerIdController.text.trim() : null,
      consumerName: _selectedReturnType == 'defective' ? _consumerNameController.text.trim() : null,
      consumerMobileNumber: _selectedReturnType == 'defective' ? _consumerMobileController.text.trim() : null,
    );

    Navigator.of(context).pop(selectedReturn);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _cylinderNumberController.dispose();
    _tareWeightController.dispose();
    _grossWeightController.dispose();
    _consumerIdController.dispose();
    _consumerNameController.dispose();
    _consumerMobileController.dispose();
    super.dispose();
  }
}