import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional_snackbar.dart';

class DispatchVehicleScreen extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final String warehouse;

  const DispatchVehicleScreen({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    required this.warehouse,
  }) : super(key: key);

  @override
  State<DispatchVehicleScreen> createState() => _DispatchVehicleScreenState();
}

class _DispatchVehicleScreenState extends State<DispatchVehicleScreen> {
  late ApiServiceInterface _apiService;

  // Dispatch mode (Equal/Unequal)
  String _dispatchMode = 'Equal'; // Default to Equal

  // State for Equal mode
  Map<String, dynamic>? _invoiceDetails;
  List<Map<String, dynamic>> _itemGroups = [];

  // State for Unequal mode
  Map<String, List<Map<String, dynamic>>> _availableItems = {};
  List<Map<String, dynamic>> _selectedItems = [];

  // State management
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';

  // Track expanded serial sections
  Map<String, bool> _expandedSerials = {};

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    if (_dispatchMode == 'Equal') {
      await _loadEqualData();
    } else {
      await _loadUnequalData();
    }
  }

  // ============================================================
  // EQUAL MODE - API & DATA LOADING
  // ============================================================

  Future<void> _loadEqualData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _apiService.getEqualERVCalculation(
        supplierGstin: widget.supplierGstin,
        supplierInvoiceDate: widget.supplierInvoiceDate,
        supplierInvoiceNumber: widget.supplierInvoiceNumber,
        warehouse: widget.warehouse,
      );

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to load equal ERV data');
      }

      final data = response['data'];

      setState(() {
        _invoiceDetails = data['invoice_details'];
        _itemGroups = List<Map<String, dynamic>>.from(data['item_groups'] ?? []);

        // Initialize selected items with defaults (all auto-suggested serials pre-selected)
        _selectedItems.clear();
        for (var group in _itemGroups) {
          final filledItemCode = group['filled_item_code'];
          final defectiveData = group['calculated_split']?['defective'];
          final emptyData = group['calculated_split']?['empty'];

          // Add defective item with auto-suggested serials pre-selected
          if (defectiveData != null) {
            final autoSuggestedSerials = List<Map<String, dynamic>>.from(
              defectiveData['auto_suggested_serials'] ?? [],
            );

            if (autoSuggestedSerials.isNotEmpty) {
              _selectedItems.add({
                'item_code': defectiveData['selected_item_code'],
                'filled_item_code': filledItemCode,
                'type': 'Defective',
                'quantity': defectiveData['auto_suggested_qty'],
                'serial_nos': autoSuggestedSerials.map((s) => s['serial_no'] as String).toList(),
              });
            }
          }

          // Add empty item
          if (emptyData != null && emptyData['qty'] > 0) {
            _selectedItems.add({
              'item_code': emptyData['selected_item_code'],
              'filled_item_code': filledItemCode,
              'type': 'Empty',
              'quantity': emptyData['qty'],
            });
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load equal ERV data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // UNEQUAL MODE - API & DATA LOADING
  // ============================================================

  Future<void> _loadUnequalData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final itemsData = await _apiService.getUnlinkedItemList();

      if (itemsData == null) {
        throw Exception('API returned null response');
      }

      final bucketsData = itemsData['buckets'];
      if (bucketsData == null) {
        throw Exception('No buckets found in API response');
      }

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
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load items: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // UI - MAIN BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch Vehicle'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Equal/Unequal Mode Selector
          _buildModeSelector(),

          // Content Area
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0E5CA8)),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                              SizedBox(height: 16.h),
                              Text(
                                _errorMessage,
                                style: TextStyle(fontSize: 14.sp, color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16.h),
                              ElevatedButton.icon(
                                onPressed: _loadData,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0E5CA8),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _dispatchMode == 'Equal'
                        ? _buildEqualContent()
                        : _buildUnequalContent(),
          ),
        ],
      ),
      bottomNavigationBar: _buildSubmitButton(),
    );
  }

  // ============================================================
  // UI - MODE SELECTOR
  // ============================================================

  Widget _buildModeSelector() {
    return Container(
      margin: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              title: 'Equal',
              value: 'Equal',
              isSelected: _dispatchMode == 'Equal',
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: _buildModeTab(
              title: 'Unequal',
              value: 'Unequal',
              isSelected: _dispatchMode == 'Unequal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required String value,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        if (_dispatchMode != value) {
          setState(() {
            _dispatchMode = value;
            _selectedItems.clear();
            _expandedSerials.clear();
          });
          _loadData();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0E5CA8) : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0E5CA8).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // UI - EQUAL MODE CONTENT
  // ============================================================

  Widget _buildEqualContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Invoice Details Card
          _buildInvoiceDetailsCard(),
          SizedBox(height: 16.h),

          // Item Groups
          ..._itemGroups.asMap().entries.map((entry) {
            final index = entry.key;
            final group = entry.value;
            return Column(
              children: [
                _buildItemGroupCard(group),
                if (index < _itemGroups.length - 1) SizedBox(height: 16.h),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  // Invoice Details Card
  Widget _buildInvoiceDetailsCard() {
    if (_invoiceDetails == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: const Color(0xFF0E5CA8), size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'Invoice Details',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0E5CA8),
                  ),
                ),
              ],
            ),
            Divider(height: 24.h, thickness: 1),
            _buildDetailRow('Purchase Invoice', _invoiceDetails!['purchase_invoice']),
            _buildDetailRow('Supplier', _invoiceDetails!['supplier_name']),
            _buildDetailRow('Warehouse', _invoiceDetails!['warehouse']),
            _buildDetailRow('Grand Total', '₹${_invoiceDetails!['grand_total']}'),
            _buildDetailRow('Posting Date', _invoiceDetails!['posting_date']),
            _buildDetailRow('Bill No', _invoiceDetails!['bill_no']),
            _buildDetailRow('Bill Date', _invoiceDetails!['bill_date']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Item Group Card
  Widget _buildItemGroupCard(Map<String, dynamic> group) {
    final filledItemCode = group['filled_item_code'];
    final filledItemName = group['filled_item_name'];
    final targetQty = group['target_qty'];
    final receivedQtyCap = group['received_qty_cap'];
    final calculatedSplit = group['calculated_split'];

    final defectiveData = calculatedSplit['defective'];
    final emptyData = calculatedSplit['empty'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5CA8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.propane_tank,
                    color: const Color(0xFF0E5CA8),
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        filledItemName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Code: $filledItemCode',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Target Quantity Info
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQtyInfo('Target', targetQty.toInt(), Colors.blue),
                  Container(width: 1, height: 30.h, color: Colors.blue.shade200),
                  _buildQtyInfo('Received Cap', receivedQtyCap.toInt(), Colors.orange),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Defective Section
            _buildDefectiveSection(filledItemCode, defectiveData, targetQty.toInt()),
            SizedBox(height: 16.h),

            // Empty Section
            _buildEmptySection(filledItemCode, emptyData, targetQty.toInt()),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyInfo(String label, int qty, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            qty.toString(),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Defective Section
  Widget _buildDefectiveSection(
    String filledItemCode,
    Map<String, dynamic> defectiveData,
    int targetQty,
  ) {
    final selectedItemCode = defectiveData['selected_item_code'];
    final maxAllowed = defectiveData['max_allowed_qty'];
    final autoSuggestedQty = defectiveData['auto_suggested_qty'];
    final isCapped = defectiveData['is_capped'] ?? false;
    final totalAvailable = defectiveData['total_available'];

    final autoSuggestedSerials = List<Map<String, dynamic>>.from(
      defectiveData['auto_suggested_serials'] ?? [],
    );
    final unavailableSerials = List<String>.from(
      defectiveData['unavailable_serials'] ?? [],
    );
    final additionalSerials = List<Map<String, dynamic>>.from(
      defectiveData['additional_serials'] ?? [],
    );

    // Get current selection
    final selectedItem = _selectedItems.firstWhere(
      (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Defective',
      orElse: () => <String, dynamic>{},
    );

    final selectedQty = selectedItem['quantity'] ?? 0;
    final selectedSerialNos = List<String>.from(selectedItem['serial_nos'] ?? []);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.red.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Defective Cylinders',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
                const Spacer(),
                Text(
                  '$selectedQty / $maxAllowed',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warnings
                if (isCapped) ...[
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, size: 16.sp, color: Colors.orange.shade800),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '$totalAvailable defectives exist but only $maxAllowed can be returned (received quantity limit)',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                if (unavailableSerials.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16.sp, color: Colors.amber.shade800),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            '${unavailableSerials.length} serial(s) from inspection reports are no longer in warehouse',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],

                // Serial Selection - Inline Expandable
                _buildSerialSelection(
                  filledItemCode,
                  autoSuggestedSerials,
                  additionalSerials,
                  selectedSerialNos,
                  maxAllowed.toInt(),
                  targetQty,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Serial Selection - Inline Expandable
  Widget _buildSerialSelection(
    String filledItemCode,
    List<Map<String, dynamic>> autoSuggestedSerials,
    List<Map<String, dynamic>> additionalSerials,
    List<String> selectedSerialNos,
    int maxAllowed,
    int targetQty,
  ) {
    final expandKey = '${filledItemCode}_defective';
    final isExpanded = _expandedSerials[expandKey] ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle Button
        InkWell(
          onTap: () {
            setState(() {
              _expandedSerials[expandKey] = !isExpanded;
            });
          },
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: selectedSerialNos.length == selectedSerialNos.length
                    ? Colors.green.shade300
                    : Colors.orange.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 20.sp,
                  color: const Color(0xFF0E5CA8),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Numbers',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${selectedSerialNos.length} selected',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 24.sp,
                ),
              ],
            ),
          ),
        ),

        // Expandable Serial List
        if (isExpanded) ...[
          SizedBox(height: 12.h),

          // Auto-Suggested Serials Section
          if (autoSuggestedSerials.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome, size: 14.sp, color: Colors.blue),
                  SizedBox(width: 4.w),
                  Text(
                    'Auto-Suggested (from this PI)',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            ...autoSuggestedSerials.map((serial) {
              final serialNo = serial['serial_no'] as String;
              final isSelected = selectedSerialNos.contains(serialNo);

              return _buildSerialCard(
                serial,
                isSelected,
                () => _toggleSerial(filledItemCode, serialNo, maxAllowed, targetQty),
                isPrimary: true,
              );
            }).toList(),
            SizedBox(height: 12.h),
          ],

          // Additional Serials Section
          if (additionalSerials.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 14.sp, color: Colors.grey[700]),
                  SizedBox(width: 4.w),
                  Text(
                    'Additional Available Serials',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            ...additionalSerials.map((serial) {
              final serialNo = serial['serial_no'] as String;
              final isSelected = selectedSerialNos.contains(serialNo);

              return _buildSerialCard(
                serial,
                isSelected,
                () => _toggleSerial(filledItemCode, serialNo, maxAllowed, targetQty),
                isPrimary: false,
              );
            }).toList(),
          ],
        ],
      ],
    );
  }

  Widget _buildSerialCard(
    Map<String, dynamic> serial,
    bool isSelected,
    VoidCallback onTap,
    {required bool isPrimary}
  ) {
    final serialNo = serial['serial_no'];
    final netWeight = serial['custom_net_weight_of_cylinder'];
    final faultType = serial['custom_fault_type'];

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? (isPrimary ? Colors.blue.shade50 : Colors.green.shade50)
            : Colors.white,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected
              ? (isPrimary ? Colors.blue.shade300 : Colors.green.shade300)
              : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (_) => onTap(),
        title: Text(
          serialNo,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          'Fault: $faultType | Weight: $netWeight kg',
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.red[700],
          ),
        ),
        activeColor: isPrimary ? Colors.blue : Colors.green,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: 8.w),
        dense: true,
      ),
    );
  }

  void _toggleSerial(String filledItemCode, String serialNo, int maxAllowed, int targetQty) {
    setState(() {
      final selectedItem = _selectedItems.firstWhere(
        (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Defective',
        orElse: () => <String, dynamic>{},
      );

      if (selectedItem.isEmpty) {
        // Create new defective item entry
        _selectedItems.add({
          'filled_item_code': filledItemCode,
          'type': 'Defective',
          'quantity': 1,
          'serial_nos': [serialNo],
        });
      } else {
        final serialNos = List<String>.from(selectedItem['serial_nos'] ?? []);

        if (serialNos.contains(serialNo)) {
          // Deselect
          serialNos.remove(serialNo);
          selectedItem['serial_nos'] = serialNos;
          selectedItem['quantity'] = serialNos.length;
        } else {
          // Select (if under max allowed)
          if (serialNos.length < maxAllowed) {
            serialNos.add(serialNo);
            selectedItem['serial_nos'] = serialNos;
            selectedItem['quantity'] = serialNos.length;
          }
        }
      }

      // Recalculate empty quantity
      _recalculateEmptyQty(filledItemCode, targetQty);
    });
  }

  void _recalculateEmptyQty(String filledItemCode, int targetQty) {
    // Get defective quantity
    final defectiveItem = _selectedItems.firstWhere(
      (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Defective',
      orElse: () => <String, dynamic>{},
    );

    final defectiveQty = defectiveItem['quantity'] ?? 0;
    final emptyQty = targetQty - defectiveQty;

    // Update or create empty item
    final emptyItem = _selectedItems.firstWhere(
      (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Empty',
      orElse: () => <String, dynamic>{},
    );

    if (emptyItem.isEmpty) {
      // Get empty data from item group
      final group = _itemGroups.firstWhere(
        (g) => g['filled_item_code'] == filledItemCode,
        orElse: () => <String, dynamic>{},
      );
      final emptyData = group['calculated_split']?['empty'];

      if (emptyData != null) {
        _selectedItems.add({
          'item_code': emptyData['selected_item_code'],
          'filled_item_code': filledItemCode,
          'type': 'Empty',
          'quantity': emptyQty,
        });
      }
    } else {
      emptyItem['quantity'] = emptyQty;
    }
  }

  // Empty Section
  Widget _buildEmptySection(
    String filledItemCode,
    Map<String, dynamic> emptyData,
    int targetQty,
  ) {
    final selectedItemCode = emptyData['selected_item_code'];
    final qty = emptyData['qty'];
    final insufficientStock = emptyData['insufficient_stock'] ?? false;
    final options = List<Map<String, dynamic>>.from(emptyData['options'] ?? []);

    final primaryOption = options.firstWhere(
      (opt) => opt['is_primary'] == true,
      orElse: () => options.isNotEmpty ? options.first : {},
    );

    // Get current selection
    final selectedItem = _selectedItems.firstWhere(
      (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Empty',
      orElse: () => <String, dynamic>{},
    );

    final selectedQty = selectedItem['quantity'] ?? qty;
    final availableQty = primaryOption['available_qty'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.blue.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2, color: Colors.blue, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  'Empty Cylinders',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const Spacer(),
                Text(
                  selectedQty.toString(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Info
                Text(
                  primaryOption['item_name'] ?? '',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Code: ${primaryOption['item_code']} | Available: $availableQty',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),

                // Insufficient Stock Warning
                if (insufficientStock) ...[
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, size: 16.sp, color: Colors.red.shade800),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Insufficient stock. Need $selectedQty but only $availableQty available. Cannot submit.',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }

  // ============================================================
  // UI - UNEQUAL MODE CONTENT
  // ============================================================

  Widget _buildUnequalContent() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'Unequal Mode',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Implementation pending. API structure ready.',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI - SUBMIT BUTTON
  // ============================================================

  Widget _buildSubmitButton() {
    final canSubmit = _validateSubmission();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: canSubmit && !_isSubmitting ? _submitDispatch : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isSubmitting
              ? SizedBox(
                  height: 20.h,
                  width: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Submit Dispatch',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  // ============================================================
  // VALIDATION & SUBMISSION
  // ============================================================

  bool _validateSubmission() {
    if (_dispatchMode == 'Unequal') {
      return _selectedItems.isNotEmpty;
    }

    // Equal mode validation
    for (var group in _itemGroups) {
      final filledItemCode = group['filled_item_code'];
      final targetQty = group['target_qty'].toInt();
      final receivedQtyCap = group['received_qty_cap'].toInt();
      final emptyData = group['calculated_split']['empty'];

      // Get selected quantities
      final defectiveItem = _selectedItems.firstWhere(
        (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Defective',
        orElse: () => <String, dynamic>{},
      );
      final emptyItem = _selectedItems.firstWhere(
        (item) => item['filled_item_code'] == filledItemCode && item['type'] == 'Empty',
        orElse: () => <String, dynamic>{},
      );

      final defectiveQty = defectiveItem['quantity'] ?? 0;
      final emptyQty = emptyItem['quantity'] ?? 0;

      // Rule 1: Total must equal target
      if (defectiveQty + emptyQty != targetQty) {
        return false;
      }

      // Rule 2: Defectives cannot exceed cap
      if (defectiveQty > receivedQtyCap) {
        return false;
      }

      // Rule 3: Check insufficient stock
      if (emptyData['insufficient_stock'] == true) {
        return false;
      }
    }

    return true;
  }

  Future<void> _submitDispatch() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build payload (keeping existing structure as requested)
      final payload = {
        'supplier_gstin': widget.supplierGstin,
        'supplier_invoice_date': widget.supplierInvoiceDate,
        'supplier_invoice_number': widget.supplierInvoiceNumber,
        'warehouse': widget.warehouse,
        'dispatch_mode': _dispatchMode,
        'items': _selectedItems,
      };

      final response = await _apiService.submitDispatchVehicle(payload);

      if (mounted) {
        if (response.success) {
          context.showSuccessSnackBar(
            response.message ?? 'Vehicle dispatched successfully',
          );
          Navigator.pop(context);
        } else {
          context.showErrorSnackBar(
            response.message ?? 'Failed to dispatch vehicle',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
