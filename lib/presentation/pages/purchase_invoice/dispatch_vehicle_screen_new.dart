import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/models/purchase_invoice/erv_models.dart';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional_snackbar.dart';
import 'serial_selection_screen.dart';

class DispatchVehicleScreenNew extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final String warehouse;

  const DispatchVehicleScreenNew({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    required this.warehouse,
  }) : super(key: key);

  @override
  State<DispatchVehicleScreenNew> createState() => _DispatchVehicleScreenNewState();
}

class _DispatchVehicleScreenNewState extends State<DispatchVehicleScreenNew> {
  late ApiServiceInterface _apiService;

  // State variables
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  String _currentMode = 'equal'; // 'equal' or 'unequal'

  // ERV Data
  ERVCalculationResponse? _ervResponse;

  // Linked groups selections (for Equal mode)
  Map<String, LinkedGroupSelection> _linkedGroupSelections = {};

  // Unlinked items selections (for both modes)
  List<UnlinkedItemSelection> _unlinkedSelections = [];

  // Stock projections
  Map<String, double> _projectedStocks = {};

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadERVData();
  }

  Future<void> _loadERVData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getERVCalculation(
        supplierGstin: widget.supplierGstin,
        supplierInvoiceDate: widget.supplierInvoiceDate,
        supplierInvoiceNumber: widget.supplierInvoiceNumber,
        warehouse: widget.warehouse,
        mode: _currentMode,
      );

      final ervResponse = ERVCalculationResponse.fromJson(response);

      setState(() {
        _ervResponse = ervResponse;
        _currentMode = ervResponse.data.mode;
        _initializeLinkedGroupSelections();
        _calculateProjectedStocks();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ERV data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _initializeLinkedGroupSelections() {
    if (_ervResponse == null || _currentMode != 'equal') return;

    _linkedGroupSelections.clear();

    for (var group in _ervResponse!.data.requiredGroups) {
      _linkedGroupSelections[group.filledItemCode] = LinkedGroupSelection(
        group: group,
        defectiveQty: group.preselections.defective.qty,
        defectiveItemCode: group.preselections.defective.itemCode,
        selectedSerials: List.from(group.preselections.defective.serials),
        emptyQty: group.preselections.empty.qty,
        emptyItemCode: group.preselections.empty.itemCode,
      );
    }
  }

  void _calculateProjectedStocks() {
    if (_ervResponse == null) return;

    _projectedStocks.clear();

    // Initialize with available quantities
    for (var item in _ervResponse!.data.availableItems.defective) {
      _projectedStocks[item.itemCode] = item.availableQty;
    }
    for (var item in _ervResponse!.data.availableItems.empty) {
      _projectedStocks[item.itemCode] = item.availableQty;
    }

    // Subtract linked group selections
    for (var selection in _linkedGroupSelections.values) {
      if (selection.defectiveItemCode != null) {
        _projectedStocks[selection.defectiveItemCode!] =
            (_projectedStocks[selection.defectiveItemCode!] ?? 0) - selection.defectiveQty;
      }
      if (selection.emptyItemCode != null) {
        _projectedStocks[selection.emptyItemCode!] =
            (_projectedStocks[selection.emptyItemCode!] ?? 0) - selection.emptyQty;
      }
    }

    // Subtract unlinked selections
    for (var selection in _unlinkedSelections) {
      _projectedStocks[selection.itemCode] =
          (_projectedStocks[selection.itemCode] ?? 0) - selection.qty;
    }
  }

  bool _hasNegativeStock() {
    return _projectedStocks.values.any((stock) => stock < 0);
  }

  bool _isValidForSubmission() {
    if (_currentMode == 'equal') {
      // Check all linked groups meet target_qty
      for (var selection in _linkedGroupSelections.values) {
        final total = selection.defectiveQty + selection.emptyQty;
        if (total != selection.group.targetQty) {
          return false;
        }
        // Check defective doesn't exceed received_qty_cap
        if (selection.defectiveQty > selection.group.receivedQtyCap) {
          return false;
        }
        // Check serial numbers match quantity
        if (selection.selectedSerials.length != selection.defectiveQty.toInt()) {
          return false;
        }
      }
    } else {
      // Unequal mode - just check if at least one item selected
      if (_unlinkedSelections.isEmpty) {
        return false;
      }
    }

    // Check no negative stocks
    if (_hasNegativeStock()) {
      return false;
    }

    // Check defective items have serial numbers
    for (var selection in _unlinkedSelections) {
      if (selection.isDefective && selection.selectedSerials.length != selection.qty.toInt()) {
        return false;
      }
    }

    return true;
  }

  void _toggleMode() async {
    final newMode = _currentMode == 'equal' ? 'unequal' : 'equal';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Switch to ${newMode == 'equal' ? 'Equal' : 'Unequal'} Mode?'),
        content: const Text('This will reset all selections. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _currentMode = newMode;
        _linkedGroupSelections.clear();
        _unlinkedSelections.clear();
      });
      _loadERVData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0E5CA8)))
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildMainContent(),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 12.w),
          child: Center(
            child: _buildModeToggle(),
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeButton('Equal', _currentMode == 'equal'),
          SizedBox(width: 4.w),
          _buildModeButton('Unequal', _currentMode == 'unequal'),
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: isSelected ? null : _toggleMode,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF0E5CA8) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.w, color: const Color(0xFFF44336)),
            SizedBox(height: 16.h),
            Text(
              'Error loading data',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: _loadERVData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_ervResponse == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInvoiceDetailsCard(),
          if (_currentMode == 'equal') ...[
            _buildLinkedGroupsSection(),
          ],
          _buildUnlinkedItemsSection(),
          SizedBox(height: 80.h), // Space for submit button
        ],
      ),
    );
  }

  Widget _buildInvoiceDetailsCard() {
    final invoice = _ervResponse!.data.invoiceDetails;

    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
            children: [
              Icon(Icons.receipt_long, color: const Color(0xFF0E5CA8), size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Invoice Details',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          _buildInfoRow('Purchase Invoice', invoice.purchaseInvoice),
          _buildInfoRow('Supplier', invoice.supplierName),
          _buildInfoRow('Warehouse', invoice.warehouse),
          _buildInfoRow('Bill No', invoice.billNo),
          _buildInfoRow('Bill Date', invoice.billDate),
          _buildInfoRow('Grand Total', '₹${invoice.grandTotal.toStringAsFixed(2)}'),
        ],
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
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedGroupsSection() {
    if (_linkedGroupSelections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: Row(
              children: [
                Icon(Icons.link, color: const Color(0xFF0E5CA8), size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  'Linked Groups (Equal Mode)',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          ..._linkedGroupSelections.values.map((selection) {
            return _buildLinkedGroupCard(selection);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLinkedGroupCard(LinkedGroupSelection selection) {
    final total = selection.defectiveQty + selection.emptyQty;
    final isValidTotal = total == selection.group.targetQty;
    final isValidDefectiveCap = selection.defectiveQty <= selection.group.receivedQtyCap;
    final hasValidSerials = selection.selectedSerials.length == selection.defectiveQty.toInt();

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isValidTotal && isValidDefectiveCap && hasValidSerials
              ? Colors.green
              : Colors.orange,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection.group.filledItemName,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        selection.group.filledItemCode,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isValidTotal ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    '$total / ${selection.group.targetQty.toInt()}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: isValidTotal ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Defective section
            _buildDefectiveSection(selection),

            SizedBox(height: 12.h),

            // Empty section
            _buildEmptySection(selection),

            // Validation messages
            if (!isValidTotal || !isValidDefectiveCap || !hasValidSerials) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isValidTotal)
                      _buildValidationMessage(
                        'Total must equal ${selection.group.targetQty.toInt()}',
                        Icons.warning,
                      ),
                    if (!isValidDefectiveCap)
                      _buildValidationMessage(
                        'Defective quantity cannot exceed ${selection.group.receivedQtyCap.toInt()}',
                        Icons.warning,
                      ),
                    if (!hasValidSerials)
                      _buildValidationMessage(
                        'Must select ${selection.defectiveQty.toInt()} serial numbers',
                        Icons.warning,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDefectiveSection(LinkedGroupSelection selection) {
    final defectiveItems = _ervResponse!.data.availableItems.defective
        .where((item) => item.mapsToFilled == selection.group.filledItemCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              'Defective Items',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Max: ${selection.group.receivedQtyCap.toInt()}',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: selection.defectiveItemCode,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          items: defectiveItems.map((item) {
            return DropdownMenuItem(
              value: item.itemCode,
              child: Text('${item.itemName} (${item.itemCode})', style: TextStyle(fontSize: 12.sp)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selection.defectiveItemCode = value;
              selection.selectedSerials.clear();
              _calculateProjectedStocks();
            });
          },
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: selection.defectiveQty.toInt().toString(),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final qty = double.tryParse(value) ?? 0;
                  setState(() {
                    selection.defectiveQty = qty;
                    selection.selectedSerials.clear();
                    _calculateProjectedStocks();
                  });
                },
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton.icon(
              onPressed: () => _navigateToSerialSelection(selection, true),
              icon: Icon(Icons.qr_code_scanner, size: 16.sp),
              label: Text(
                selection.selectedSerials.isEmpty
                    ? 'Select'
                    : '${selection.selectedSerials.length}',
                style: TextStyle(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: selection.selectedSerials.length == selection.defectiveQty.toInt()
                    ? Colors.green
                    : Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptySection(LinkedGroupSelection selection) {
    final emptyItems = _ervResponse!.data.availableItems.empty
        .where((item) => item.mapsToFilled == selection.group.filledItemCode)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inventory_2, color: const Color(0xFF0E5CA8), size: 16.sp),
            SizedBox(width: 6.w),
            Text(
              'Empty Items',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        DropdownButtonFormField<String>(
          value: selection.emptyItemCode,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          items: emptyItems.map((item) {
            return DropdownMenuItem(
              value: item.itemCode,
              child: Text('${item.itemName} (${item.itemCode})', style: TextStyle(fontSize: 12.sp)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selection.emptyItemCode = value;
              _calculateProjectedStocks();
            });
          },
        ),
        SizedBox(height: 8.h),
        TextFormField(
          initialValue: selection.emptyQty.toInt().toString(),
          decoration: InputDecoration(
            labelText: 'Quantity',
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final qty = double.tryParse(value) ?? 0;
            setState(() {
              selection.emptyQty = qty;
              _calculateProjectedStocks();
            });
          },
        ),
      ],
    );
  }

  Widget _buildValidationMessage(String message, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.orange.shade700),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 11.sp, color: Colors.orange.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkedItemsSection() {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: const Color(0xFF0E5CA8), size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(
                    'Additional Items',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _addUnlinkedItem,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_unlinkedSelections.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text(
                  'No additional items added',
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
                ),
              ),
            )
          else
            ..._unlinkedSelections.asMap().entries.map((entry) {
              final index = entry.key;
              final selection = entry.value;
              return _buildUnlinkedItemCard(selection, index);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildUnlinkedItemCard(UnlinkedItemSelection selection, int index) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selection.itemName,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        selection.itemCode,
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _removeUnlinkedItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  iconSize: 20.sp,
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Qty: ${selection.qty.toInt()}',
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                  ),
                ),
                if (selection.isDefective)
                  ElevatedButton.icon(
                    onPressed: () => _navigateToSerialSelectionForUnlinked(selection),
                    icon: Icon(Icons.qr_code_scanner, size: 14.sp),
                    label: Text(
                      selection.selectedSerials.isEmpty
                          ? 'Select Serials'
                          : '${selection.selectedSerials.length} selected',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selection.selectedSerials.length == selection.qty.toInt()
                          ? Colors.green
                          : Colors.orange,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addUnlinkedItem() {
    // Navigate to item selection
    // For now, showing a dialog (this should be a separate page)
    _showUnlinkedItemSelectionDialog();
  }

  void _showUnlinkedItemSelectionDialog() async {
    // This is a simplified version - should be a full page with search
    final allItems = <Map<String, dynamic>>[];

    // Add all defective items
    for (var item in _ervResponse!.data.availableItems.defective) {
      allItems.add({
        'item_code': item.itemCode,
        'item_name': item.itemName,
        'is_defective': true,
        'available_qty': item.availableQty,
        'maps_to_filled': item.mapsToFilled,
      });
    }

    // Add all empty items
    for (var item in _ervResponse!.data.availableItems.empty) {
      allItems.add({
        'item_code': item.itemCode,
        'item_name': item.itemName,
        'is_defective': false,
        'available_qty': item.availableQty,
        'maps_to_filled': item.mapsToFilled,
      });
    }

    // Show selection dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allItems.length,
            itemBuilder: (context, index) {
              final item = allItems[index];
              final projectedStock = _projectedStocks[item['item_code']] ?? 0;
              final isEnabled = projectedStock > 0;

              return ListTile(
                enabled: isEnabled,
                title: Text(item['item_name']),
                subtitle: Text('${item['item_code']} • Stock: ${projectedStock.toInt()}'),
                trailing: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: item['is_defective'] ? Colors.red.shade100 : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    item['is_defective'] ? 'Defective' : 'Empty',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: item['is_defective'] ? Colors.red.shade700 : Colors.blue.shade700,
                    ),
                  ),
                ),
                onTap: isEnabled ? () {
                  Navigator.pop(context);
                  _showQuantityDialog(item);
                } : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showQuantityDialog(Map<String, dynamic> item) {
    int quantity = 1;
    final maxQty = (_projectedStocks[item['item_code']] ?? 0).toInt();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Enter Quantity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(item['item_name']),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: quantity > 1 ? () {
                      setState(() => quantity--);
                    } : null,
                  ),
                  SizedBox(
                    width: 60.w,
                    child: TextField(
                      textAlign: TextAlign.center,
                      controller: TextEditingController(text: quantity.toString()),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        if (parsed != null && parsed >= 1 && parsed <= maxQty) {
                          setState(() => quantity = parsed);
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: quantity < maxQty ? () {
                      setState(() => quantity++);
                    } : null,
                  ),
                ],
              ),
              Text('Max: $maxQty', style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _addUnlinkedSelection(item, quantity.toDouble());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addUnlinkedSelection(Map<String, dynamic> item, double qty) {
    setState(() {
      _unlinkedSelections.add(UnlinkedItemSelection(
        itemCode: item['item_code'],
        itemName: item['item_name'],
        qty: qty,
        isDefective: item['is_defective'],
        selectedSerials: [],
      ));
      _calculateProjectedStocks();
    });
  }

  void _removeUnlinkedItem(int index) {
    setState(() {
      _unlinkedSelections.removeAt(index);
      _calculateProjectedStocks();
    });
  }

  void _navigateToSerialSelection(LinkedGroupSelection selection, bool isLinked) async {
    if (selection.defectiveItemCode == null) return;

    final defectiveItem = _ervResponse!.data.availableItems.defective
        .firstWhere((item) => item.itemCode == selection.defectiveItemCode);

    final result = await Navigator.push<List<SerialDetail>>(
      context,
      MaterialPageRoute(
        builder: (context) => SerialSelectionScreen(
          itemCode: defectiveItem.itemCode,
          itemName: defectiveItem.itemName,
          requiredQty: selection.defectiveQty.toInt(),
          availableSerials: defectiveItem.serials,
          preselectedSerials: selection.selectedSerials,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selection.selectedSerials = result;
      });
    }
  }

  void _navigateToSerialSelectionForUnlinked(UnlinkedItemSelection selection) async {
    final defectiveItem = _ervResponse!.data.availableItems.defective
        .firstWhere((item) => item.itemCode == selection.itemCode);

    final result = await Navigator.push<List<SerialDetail>>(
      context,
      MaterialPageRoute(
        builder: (context) => SerialSelectionScreen(
          itemCode: defectiveItem.itemCode,
          itemName: defectiveItem.itemName,
          requiredQty: selection.qty.toInt(),
          availableSerials: defectiveItem.serials,
          preselectedSerials: selection.selectedSerials,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        selection.selectedSerials = result;
      });
    }
  }

  Widget _buildSubmitButton() {
    final isValid = _isValidForSubmission();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isValid && !_isSubmitting ? _submitDispatch : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          disabledBackgroundColor: Colors.grey,
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            : Text(
                'Dispatch Vehicle',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitDispatch() async {
    setState(() => _isSubmitting = true);

    try {
      final payload = _buildSubmissionPayload();

      await _apiService.submitDispatchVehicle(payload);

      if (mounted) {
        context.showSuccessSnackBar('Dispatch submitted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to submit dispatch: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Map<String, dynamic> _buildSubmissionPayload() {
    final items = <Map<String, dynamic>>[];

    // Add linked group items
    for (var selection in _linkedGroupSelections.values) {
      // Add defective item
      if (selection.defectiveQty > 0) {
        items.add({
          'item_code': selection.defectiveItemCode,
          'quantity': selection.defectiveQty.toString(),
          'return_type': 'Defective',
          'serial_nos': selection.selectedSerials.map((s) => s.serialNo).join(','),
          'unlinked_item': 0,
        });
      }

      // Add empty item
      if (selection.emptyQty > 0) {
        items.add({
          'item_code': selection.emptyItemCode,
          'quantity': selection.emptyQty.toString(),
          'return_type': 'Empty',
          'unlinked_item': 0,
        });
      }
    }

    // Add unlinked items
    for (var selection in _unlinkedSelections) {
      items.add({
        'item_code': selection.itemCode,
        'quantity': selection.qty.toString(),
        'return_type': selection.isDefective ? 'Defective' : 'Empty',
        if (selection.isDefective)
          'serial_nos': selection.selectedSerials.map((s) => s.serialNo).join(','),
        'unlinked_item': 1,
      });
    }

    return {
      'supplier_gstin': widget.supplierGstin,
      'supplier_invoice_date': widget.supplierInvoiceDate,
      'supplier_invoice_number': widget.supplierInvoiceNumber,
      'warehouse': widget.warehouse,
      'mode': _currentMode,
      'items_dispatched': items,
    };
  }
}

// Helper classes for managing selections
class LinkedGroupSelection {
  final RequiredGroup group;
  double defectiveQty;
  String? defectiveItemCode;
  List<SerialDetail> selectedSerials;
  double emptyQty;
  String? emptyItemCode;

  LinkedGroupSelection({
    required this.group,
    required this.defectiveQty,
    this.defectiveItemCode,
    required this.selectedSerials,
    required this.emptyQty,
    this.emptyItemCode,
  });
}

class UnlinkedItemSelection {
  final String itemCode;
  final String itemName;
  double qty;
  final bool isDefective;
  List<SerialDetail> selectedSerials;

  UnlinkedItemSelection({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.isDefective,
    required this.selectedSerials,
  });
}
