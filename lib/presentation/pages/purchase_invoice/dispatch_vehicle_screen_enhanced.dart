import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/models/purchase_invoice/erv_models.dart';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional_snackbar.dart';
import 'serial_selection_screen.dart';

class DispatchVehicleScreenEnhanced extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;
  final String warehouse;

  const DispatchVehicleScreenEnhanced({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
    required this.warehouse,
  }) : super(key: key);

  @override
  State<DispatchVehicleScreenEnhanced> createState() =>
      _DispatchVehicleScreenEnhancedState();
}

class _DispatchVehicleScreenEnhancedState
    extends State<DispatchVehicleScreenEnhanced> {
  late ApiServiceInterface _apiService;

  // Core State
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  String _currentMode = 'equal';

  // ERV Data
  ERVCalculationResponse? _ervResponse;
  List<RequiredGroup> _originalRequiredGroups = []; // Immutable reference
  List<ItemGroupState> _currentGroups = [];
  List<ConversionRecord> _conversions = [];
  Set<String> _consumedSerialNumbers = {};
  // Add after _consumedSerialNumbers
  Map<String, double> _originalTargetQty = {};
  Map<String, double> _originalReceivedQtyCap = {};

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
        _originalRequiredGroups = List.from(ervResponse.data.requiredGroups);
        _initializeCurrentGroups();
        _calculateConsumedSerials();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load ERV data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _initializeCurrentGroups() {
    _currentGroups.clear();
    _originalTargetQty.clear();
    _originalReceivedQtyCap.clear();

    for (var group in _ervResponse!.data.requiredGroups) {
      final returnItems = <ReturnItemState>[];

      // Add defective preselection
      if (group.preselections.defective.qty > 0) {
        returnItems.add(ReturnItemState(
          itemCode: group.preselections.defective.itemCode,
          itemName: _getItemName(group.preselections.defective.itemCode, true),
          qty: group.preselections.defective.qty,
          returnType: 'Defective',
          selectedSerials:
          group.preselections.defective.serials.map((s) => s.serialNo).toList(),
          unlinkedItem: false,
        ));
      }

      // Add empty preselection
      if (group.preselections.empty.qty > 0) {
        returnItems.add(ReturnItemState(
          itemCode: group.preselections.empty.itemCode,
          itemName: _getItemName(group.preselections.empty.itemCode, false),
          qty: group.preselections.empty.qty,
          returnType: 'Empty',
          selectedSerials: [],
          unlinkedItem: false,
        ));
      }

      // ✅ Store original values
      _originalTargetQty[group.purchaseInvoiceItem] = group.targetQty;
      _originalReceivedQtyCap[group.purchaseInvoiceItem] = group.receivedQtyCap;

      _currentGroups.add(ItemGroupState(
        purchaseInvoiceItem: group.purchaseInvoiceItem,
        filledItemCode: group.filledItemCode,
        filledItemName: group.filledItemName,
        targetQty: group.targetQty,
        receivedQtyCap: group.receivedQtyCap,
        isLinked: true,
        isDeleted: false,
        returnItems: returnItems,
      ));
    }
  }

  String _getItemName(String itemCode, bool isDefective) {
    if (isDefective) {
      return _ervResponse!.data.availableItems.defective
              .firstWhere((item) => item.itemCode == itemCode,
                  orElse: () => DefectiveItem(
                      itemCode: itemCode,
                      itemName: itemCode,
                      availableQty: 0,
                      serials: []))
              .itemName;
    } else {
      return _ervResponse!.data.availableItems.empty
              .firstWhere((item) => item.itemCode == itemCode,
                  orElse: () => EmptyItem(
                      itemCode: itemCode, itemName: itemCode, availableQty: 0))
              .itemName;
    }
  }

  void _showAddUnlinkedGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Add Unlinked Item'),
          ],
        ),
        content: const Text(
          'Unlinked items are returns that don\'t correspond to any '
              'received items in this Purchase Invoice.\n\n'
              'These should only be used for special cases like:\n'
              '• Wrong items received previously\n'
              '• Dead stock returns\n'
              '• Adjustments\n\n'
              'Do you want to add an unlinked item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createUnlinkedGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Unlinked Group'),
          ),
        ],
      ),
    );
  }

  void _createUnlinkedGroup() {
    // Create a new unlinked group
    final unlinkedGroup = ItemGroupState(
      purchaseInvoiceItem: null,
      filledItemCode: null,
      filledItemName: 'Unlinked Items',
      targetQty: null,
      receivedQtyCap: null,
      isLinked: false,
      isDeleted: false,
      returnItems: [],
    );

    setState(() {
      _currentGroups.add(unlinkedGroup);
    });

    context.showSuccessSnackBar('Unlinked group created. Add items to it now.');
  }

  void _calculateConsumedSerials() {
    _consumedSerialNumbers.clear();
    for (var group in _currentGroups) {
      if (!group.isDeleted) {
        for (var item in group.returnItems) {
          _consumedSerialNumbers.addAll(item.selectedSerials);
        }
      }
    }
  }

  void _toggleMode() async {
    final newMode = _currentMode == 'equal' ? 'unequal' : 'equal';

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildModeConfirmationDialog(newMode),
    );

    if (confirmed == true) {
      if (newMode == 'equal') {
        // Validate before switching to Equal
        final errors = _validateEqualModeSwitch();
        if (errors.isNotEmpty) {
          _showValidationBlockDialog(errors);
          return;
        }
      }

      setState(() {
        _currentMode = newMode;
      });

      context.showSuccessSnackBar('Switched to ${newMode == 'equal' ? 'Equal' : 'Unequal'} Mode');
    }
  }

  Widget _buildModeConfirmationDialog(String newMode) {
    if (newMode == 'unequal') {
      return AlertDialog(
        title: const Text('Switch to Unequal ERV?'),
        content: const Text(
          'Unequal ERV removes all validation restrictions:\n\n'
          '• You can return any quantity (not matching PI totals)\n'
          '• You can delete required groups\n'
          '• You can add unlinked items\n'
          '• You can convert refill items to one-way\n\n'
          'Your current selections will be preserved.',
        ),
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
            child: const Text('Switch to Unequal'),
          ),
        ],
      );
    } else {
      return AlertDialog(
        title: const Text('Switch to Equal ERV?'),
        content: const Text(
          'Equal ERV enforces validation rules:\n\n'
          '• Returns must match PI quantities\n'
          '• All required groups must be present\n'
          '• Defectives cannot exceed received quantity\n'
          '• No oneway conversions allowed\n\n'
          'Your selections will be validated.',
        ),
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
            child: const Text('Switch to Equal'),
          ),
        ],
      );
    }
  }

  List<String> _validateEqualModeSwitch() {
    List<String> errors = [];

    // 1. Check for conversions
    if (_conversions.isNotEmpty) {
      errors.add(
        'Cannot switch to Equal mode with oneway conversions.\n'
        'Conversions detected:\n' +
            _conversions
                .map((c) => '• ${c.filledItemCode}: ${c.qty} cylinders')
                .join('\n'),
      );
      return errors;
    }

    // 2. Check all required groups are present
    for (var requiredGroup in _originalRequiredGroups) {
      final exists = _currentGroups.any((g) =>
          g.purchaseInvoiceItem == requiredGroup.purchaseInvoiceItem &&
          !g.isDeleted);

      if (!exists) {
        errors.add('Missing required group: ${requiredGroup.filledItemName}');
      }
    }

    // 3. Check totals match targets
    for (var group in _currentGroups) {
      if (group.isDeleted || !group.isLinked) continue;

      final totalReturning =
          group.returnItems.fold<double>(0, (sum, item) => sum + item.qty);

      if (totalReturning != group.targetQty) {
        errors.add(
          'Group ${group.filledItemName}: '
          'Returns ($totalReturning) must equal target (${group.targetQty})',
        );
      }
    }

    // 4. Check defectives don't exceed received_qty_cap
    for (var group in _currentGroups) {
      if (group.isDeleted || !group.isLinked) continue;

      final defectiveQty = group.returnItems
          .where((item) => item.returnType == 'Defective')
          .fold<double>(0, (sum, item) => sum + item.qty);

      if (defectiveQty > group.receivedQtyCap!) {
        errors.add(
          'Group ${group.filledItemName}: '
          'Defectives ($defectiveQty) exceed received limit (${group.receivedQtyCap})',
        );
      }
    }

    // 5. Check for duplicate serials
    final duplicates = _findDuplicateSerials();
    if (duplicates.isNotEmpty) {
      errors.add('Duplicate serials detected: ${duplicates.join(", ")}');
    }

    return errors;
  }

  List<String> _findDuplicateSerials() {
    Map<String, int> serialCounts = {};

    for (var group in _currentGroups) {
      if (group.isDeleted) continue;

      for (var item in group.returnItems) {
        for (var serial in item.selectedSerials) {
          serialCounts[serial] = (serialCounts[serial] ?? 0) + 1;
        }
      }
    }

    return serialCounts.entries
        .where((e) => e.value > 1)
        .map((e) => e.key)
        .toList();
  }

  void _showValidationBlockDialog(List<String> errors) {
    final hasConversions = errors.first.contains('oneway conversions');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot Switch to Equal Mode'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please fix the following issues:'),
              SizedBox(height: 8.h),
              ...errors.map((error) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Colors.red)),
                        Expanded(child: Text(error)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          if (hasConversions)
            TextButton(
              onPressed: () {
                _revertAllConversions();
                Navigator.pop(context);
                _toggleMode(); // Retry switch
              },
              child: const Text('Revert Conversions & Switch'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _revertAllConversions() {
    setState(() {
      // ✅ Restore original target quantities
      for (var group in _currentGroups) {
        if (group.isLinked && group.purchaseInvoiceItem != null) {
          final originalTarget = _originalTargetQty[group.purchaseInvoiceItem];
          final originalCap = _originalReceivedQtyCap[group.purchaseInvoiceItem];

          if (originalTarget != null) {
            group.targetQty = originalTarget;
          }
          if (originalCap != null) {
            group.receivedQtyCap = originalCap;
          }
        }
      }

      _conversions.clear();
    });
    context.showSuccessSnackBar('All conversions reverted. Target quantities restored.');
  }

  void _softDeleteGroup(ItemGroupState group) {
    // Special handling for unlinked groups
    if (!group.isLinked) {
      if (group.returnItems.isEmpty) {
        // Just remove it directly
        setState(() {
          _currentGroups.remove(group);
        });
        context.showSuccessSnackBar('Empty unlinked group removed');
        return;
      } else {
        // Show warning that items need to be deleted first
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Delete'),
            content: const Text(
              'Please remove all items from this unlinked group first.\n\n'
                  'Once all items are removed, the group will be automatically deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Normal linked group deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group?'),
        content: Text(
          'Delete group: ${group.filledItemName}?\n\n'
              'You can restore it later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                group.isDeleted = true;
                // Remove serials from consumed registry
                for (var item in group.returnItems) {
                  _consumedSerialNumbers.removeAll(item.selectedSerials);
                }
              });
              Navigator.pop(context);
              context.showSuccessSnackBar(
                  'Group deleted. You can restore it from the deleted groups section.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _restoreGroup(ItemGroupState group) {
    setState(() {
      group.isDeleted = false;
      // Re-add serials to consumed registry
      for (var item in group.returnItems) {
        _consumedSerialNumbers.addAll(item.selectedSerials);
      }
    });
    context.showSuccessSnackBar('Group restored successfully');
  }

  void _showConvertToOnewayDialog(ItemGroupState group) {
    if (_currentMode != 'unequal') {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Not Available'),
          content: const Text(
              'Conversion to one-way is only available in Unequal ERV mode.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _ConvertToOnewayDialog(
        group: group,
        onConfirm: (double qty) {
          _applyConversion(group, qty);
        },
      ),
    );
  }

  void _applyConversion(ItemGroupState group, double qty) {
    setState(() {
      // Add conversion record
      _conversions.add(ConversionRecord(
        purchaseInvoiceItem: group.purchaseInvoiceItem!,
        filledItemCode: group.filledItemCode!,
        qty: qty,
        originalLoadType: 'Refill',
        convertedTo: 'Oneway',
      ));

      // ✅ Reduce the target quantity
      final originalTarget = group.targetQty!;

      // group.targetQty = originalTarget - qty;
      group.targetQty = originalTarget - qty;  // ✅ Works now!

      // ✅ Also reduce received_qty_cap proportionally for defective limit
      if (group.receivedQtyCap != null && originalTarget > 0) {
        final proportion = group.receivedQtyCap! / originalTarget;
        group.receivedQtyCap = group.targetQty! * proportion;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Conversion applied!\n'
              '${qty.toInt()} cylinders converted to one-way.\n'
              'New target for returns: ${group.targetQty!.toInt()}',
        ),
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0E5CA8)))
          : _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildMainContent(),
      bottomNavigationBar: !_isLoading && _errorMessage.isEmpty
          ? _buildSubmitButton()
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Dispatch Vehicle (ERV)',
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
          child: Center(child: _buildModeToggle()),
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
          if (_conversions.isNotEmpty) _buildConversionsCard(),
          _buildActiveGroupsSection(),
          _buildDeletedGroupsSection(),
          SizedBox(height: 100.h),
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
              Icon(Icons.receipt_long,
                  color: const Color(0xFF0E5CA8), size: 20.sp),
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
          _buildInfoRow(
              'Grand Total', '₹${invoice.grandTotal.toStringAsFixed(2)}'),
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

  Widget _buildConversionsCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.orange.shade700, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'One-Way Conversions',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ..._conversions.map((c) => Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right,
                        color: Colors.orange.shade700, size: 16.sp),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        '${c.filledItemCode}: ${c.qty.toInt()} cylinders → ${c.convertedTo}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActiveGroupsSection() {
    final activeGroups = _currentGroups.where((g) => !g.isDeleted).toList();

    if (activeGroups.isEmpty) {
      return Container(
        margin: EdgeInsets.all(16.w),
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            'No active groups',
            style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Icons.inventory_2,
                  color: const Color(0xFF0E5CA8), size: 18.sp),
              SizedBox(width: 8.w),
              Text(
                _currentMode == 'equal' ? 'Required Groups' : 'Return Groups',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...activeGroups.map((group) => _buildGroupCard(group)).toList(),

        // Add Unlinked Item Button (Unequal mode only)
        if (_currentMode == 'unequal') ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showAddUnlinkedGroupDialog,
                icon: Icon(Icons.add_circle_outline, size: 20.sp),
                label: const Text('Add Unlinked Item Group'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange.shade300, width: 2),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupCard(ItemGroupState group) {
    final totalReturning =
        group.returnItems.fold<double>(0, (sum, item) => sum + item.qty);
    final isValid = _currentMode == 'unequal' ||
        (totalReturning == group.targetQty &&
            _getDefectiveQty(group) <= group.receivedQtyCap!);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: _currentMode == 'equal'
              ? (isValid ? Colors.green : Colors.orange)
              : Colors.grey.shade300,
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
                        group.filledItemName,
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      if (group.isLinked)
                        Text(
                          'Target: ${group.targetQty!.toInt()} | Max Defectives: ${group.receivedQtyCap!.toInt()}',
                          style: TextStyle(
                              fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                if (_currentMode == 'unequal' && group.isLinked) ...[
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, color: Colors.orange),
                    onPressed: () => _showConvertToOnewayDialog(group),
                    tooltip: 'Convert to One-Way',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _softDeleteGroup(group),
                    tooltip: 'Delete Group',
                  ),
                ],
              ],
            ),

            // Validation Status (Equal mode only)
            if (_currentMode == 'equal' && group.isLinked)
              _buildValidationStatus(group, totalReturning, isValid),

            SizedBox(height: 12.h),

            // Return Items
            if (group.returnItems.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Text(
                    'No return items',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13.sp),
                  ),
                ),
              )
            else
              ...group.returnItems
                  .asMap()
                  .entries
                  .map((entry) =>
                      _buildReturnItemRow(group, entry.value, entry.key))
                  .toList(),

            // Add Return Item Button
            SizedBox(height: 8.h),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddReturnItemDialog(group),
                icon: Icon(Icons.add, size: 18.sp),
                label: const Text('Add Return Item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E5CA8),
                  side: const BorderSide(color: Color(0xFF0E5CA8)),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getDefectiveQty(ItemGroupState group) {
    return group.returnItems
        .where((item) => item.returnType == 'Defective')
        .fold<double>(0, (sum, item) => sum + item.qty);
  }

  Widget _buildValidationStatus(
      ItemGroupState group, double totalReturning, bool isValid) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isValid ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            color: isValid ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Returning: ${totalReturning.toInt()} / ${group.targetQty!.toInt()} '
              '${isValid ? "✓" : "⚠ Must match target"}',
              style: TextStyle(
                color: isValid ? Colors.green.shade900 : Colors.orange.shade900,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnItemRow(
      ItemGroupState group, ReturnItemState item, int index) {
    final isDefective = item.returnType == 'Defective';
    final hasValidSerials = !isDefective ||
        item.selectedSerials.length == item.qty.toInt();

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: isDefective
                      ? Colors.red.shade100
                      : Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  item.returnType,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: isDefective
                        ? Colors.red.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  item.itemName,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _consumedSerialNumbers.removeAll(item.selectedSerials);
                    group.returnItems.removeAt(index);

                    // ✅ Auto-remove unlinked groups if they become empty
                    if (!group.isLinked && group.returnItems.isEmpty) {
                      _currentGroups.remove(group);
                      context.showSuccessSnackBar('Empty unlinked group removed automatically');
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'Qty: ${item.qty.toInt()}',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
              ),
              if (isDefective) ...[
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToSerialSelection(group, item),
                    icon: Icon(Icons.qr_code_scanner, size: 14.sp),
                    label: Text(
                      hasValidSerials
                          ? '${item.selectedSerials.length} Serials ✓'
                          : 'Select Serials',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasValidSerials ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToSerialSelection(
      ItemGroupState group, ReturnItemState item) async {
    final defectiveItem = _ervResponse!.data.availableItems.defective
        .firstWhere((di) => di.itemCode == item.itemCode);

    final result = await Navigator.push<List<SerialDetail>>(
      context,
      MaterialPageRoute(
        builder: (context) => SerialSelectionScreen(
          itemCode: defectiveItem.itemCode,
          itemName: defectiveItem.itemName,
          requiredQty: item.qty.toInt(),
          availableSerials: defectiveItem.serials,
          preselectedSerials: defectiveItem.serials
              .where((s) => item.selectedSerials.contains(s.serialNo))
              .toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // Remove old serials from consumed
        _consumedSerialNumbers.removeAll(item.selectedSerials);
        // Update with new serials
        item.selectedSerials = result.map((s) => s.serialNo).toList();
        // Add new serials to consumed
        _consumedSerialNumbers.addAll(item.selectedSerials);
      });
    }
  }

  void _showAddReturnItemDialog(ItemGroupState group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Return Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.warning, color: Colors.red),
              title: const Text('Defective Cylinder'),
              subtitle: const Text('Requires serial number selection'),
              onTap: () {
                Navigator.pop(context);
                _showDefectiveItemSelection(group);
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory_2, color: const Color(0xFF0E5CA8)),
              title: const Text('Empty Cylinder'),
              subtitle: const Text('Non-serialized item'),
              onTap: () {
                Navigator.pop(context);
                _showEmptyItemSelection(group);
              },
            ),
          ],
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

  void _showDefectiveItemSelection(ItemGroupState group) {
    // Get defective items
    List<DefectiveItem> availableDefectiveItems;

    if (group.isLinked) {
      // For linked groups, only show items that map to this filled item
      availableDefectiveItems = _ervResponse!.data.availableItems.defective
          .where((item) => item.mapsToFilled == group.filledItemCode)
          .toList();
    } else {
      // For unlinked groups, show all defective items
      availableDefectiveItems = _ervResponse!.data.availableItems.defective;
    }

    if (availableDefectiveItems.isEmpty) {
      context.showErrorSnackBar('No defective items available for this group');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Defective Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableDefectiveItems.length,
            itemBuilder: (context, index) {
              final item = availableDefectiveItems[index];
              final availableSerials = item.serials
                  .where((s) => !_consumedSerialNumbers.contains(s.serialNo))
                  .length;

              return ListTile(
                title: Text(item.itemName),
                subtitle: Text('${item.itemCode} • $availableSerials serials available'),
                trailing: Icon(Icons.arrow_forward),
                enabled: availableSerials > 0,
                onTap: availableSerials > 0
                    ? () {
                        Navigator.pop(context);
                        _showQuantityDialogForDefective(group, item);
                      }
                    : null,
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

  void _showEmptyItemSelection(ItemGroupState group) {
    // Get empty items
    List<EmptyItem> availableEmptyItems;

    if (group.isLinked) {
      // For linked groups, only show items that map to this filled item
      availableEmptyItems = _ervResponse!.data.availableItems.empty
          .where((item) => item.mapsToFilled == group.filledItemCode)
          .toList();
    } else {
      // For unlinked groups, show all empty items
      availableEmptyItems = _ervResponse!.data.availableItems.empty;
    }

    if (availableEmptyItems.isEmpty) {
      context.showErrorSnackBar('No empty items available for this group');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Empty Item'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableEmptyItems.length,
            itemBuilder: (context, index) {
              final item = availableEmptyItems[index];

              return ListTile(
                title: Text(item.itemName),
                subtitle: Text('${item.itemCode} • ${item.availableQty.toInt()} available'),
                trailing: Icon(Icons.arrow_forward),
                enabled: item.availableQty > 0,
                onTap: item.availableQty > 0
                    ? () {
                        Navigator.pop(context);
                        _showQuantityDialogForEmpty(group, item);
                      }
                    : null,
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

  void _showQuantityDialogForDefective(ItemGroupState group, DefectiveItem item) {
    final availableSerials = item.serials
        .where((s) => !_consumedSerialNumbers.contains(s.serialNo))
        .toList();

    var maxQty = availableSerials.length;

    // In Equal mode, limit by remaining capacity
    if (_currentMode == 'equal') {
      final remaining = _getRemainingCapacity(group);
      if (remaining <= 0) {
        context.showErrorSnackBar('Target quantity already reached for this group');
        return;
      }
      maxQty = maxQty.clamp(0, remaining);
    }

    showDialog(
      context: context,
      builder: (context) => _QuantityDialogForDefective(
        item: item,
        maxQty: maxQty,
        group: group,
        onConfirm: (quantity) async {
          final result = await Navigator.push<List<SerialDetail>>(
            context,
            MaterialPageRoute(
              builder: (context) => SerialSelectionScreen(
                itemCode: item.itemCode,
                itemName: item.itemName,
                requiredQty: quantity,
                availableSerials: availableSerials,
                preselectedSerials: [],
              ),
            ),
          );

          if (result != null && mounted) {
            setState(() {
              final newItem = ReturnItemState(
                itemCode: item.itemCode,
                itemName: item.itemName,
                qty: result.length.toDouble(),
                returnType: 'Defective',
                selectedSerials: result.map((s) => s.serialNo).toList(),
                unlinkedItem: !group.isLinked,
              );
              group.returnItems.add(newItem);
              _consumedSerialNumbers.addAll(newItem.selectedSerials);
            });
            context.showSuccessSnackBar('Defective item added successfully');
          }
        },
      ),
    );
  }

  void _showQuantityDialogForEmpty(ItemGroupState group, EmptyItem item) {
    final maxQty = _currentMode == 'equal'
        ? _getRemainingCapacity(group).clamp(0, item.availableQty.toInt())
        : item.availableQty.toInt();

    if (maxQty <= 0) {
      context.showErrorSnackBar('Target quantity already reached for this group');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _QuantityDialogForEmpty(
        item: item,
        maxQty: maxQty,
        group: group,
        onConfirm: (quantity) {
          setState(() {
            final newItem = ReturnItemState(
              itemCode: item.itemCode,
              itemName: item.itemName,
              qty: quantity.toDouble(),
              returnType: 'Empty',
              selectedSerials: [],
              unlinkedItem: !group.isLinked,
            );
            group.returnItems.add(newItem);
          });

          if (mounted) {
            context.showSuccessSnackBar('Empty item added successfully');
          }
        },
      ),
    );
  }

  Widget _buildDeletedGroupsSection() {
    final deletedGroups =
        _currentGroups.where((g) => g.isDeleted).toList();

    if (deletedGroups.isEmpty || _currentMode == 'equal') {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.all(16.w),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Deleted Groups (${deletedGroups.length})',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
          ),
          children: deletedGroups.map((group) {
            return ListTile(
              title: Text(group.filledItemName),
              subtitle:
                  Text('Target: ${group.targetQty!.toInt()}'),
              trailing: ElevatedButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restore'),
                onPressed: () => _restoreGroup(group),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E5CA8),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
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
        onPressed: _isSubmitting ? null : _submitERV,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2)
            : Text(
                'Submit ERV',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _submitERV() async {
    // First validate
    if (!_validateBeforeSubmit()) return;

    // Show confirmation dialog
    final confirmed = await _showSubmitConfirmationDialog();
    if (confirmed != true) return;

    // Proceed with submission
    setState(() => _isSubmitting = true);

    try {
      final payload = _buildSubmissionPayload();

      await _apiService.submitDispatchVehicle(payload);

      if (mounted) {
        context.showSuccessSnackBar('ERV submitted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Failed to submit ERV: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showSubmitConfirmationDialog() {
    // Calculate summary
    final totalGroups = _currentGroups.where((g) => !g.isDeleted && g.returnItems.isNotEmpty).length;
    final totalDefectiveItems = _currentGroups
        .where((g) => !g.isDeleted)
        .expand((g) => g.returnItems)
        .where((item) => item.returnType == 'Defective')
        .fold<double>(0, (sum, item) => sum + item.qty);
    final totalEmptyItems = _currentGroups
        .where((g) => !g.isDeleted)
        .expand((g) => g.returnItems)
        .where((item) => item.returnType == 'Empty')
        .fold<double>(0, (sum, item) => sum + item.qty);
    final totalConversions = _conversions.fold<double>(0, (sum, c) => sum + c.qty);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: const Color(0xFF0E5CA8), size: 24.sp),
            SizedBox(width: 8.w),
            const Text('Confirm ERV Submission'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You are about to submit the Equipment Return Voucher:',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 16.h),
              _buildSummaryRow('Mode', _currentMode == 'equal' ? 'Equal ERV' : 'Unequal ERV'),
              _buildSummaryRow('Purchase Invoice', _ervResponse!.data.invoiceDetails.purchaseInvoice),
              _buildSummaryRow('Warehouse', _ervResponse!.data.invoiceDetails.warehouse),
              SizedBox(height: 12.h),
              Divider(),
              SizedBox(height: 12.h),
              Text(
                'Return Summary:',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8.h),
              _buildSummaryRow('Return Groups', '$totalGroups'),
              _buildSummaryRow('Defective Items', '${totalDefectiveItems.toInt()}'),
              _buildSummaryRow('Empty Items', '${totalEmptyItems.toInt()}'),
              if (_conversions.isNotEmpty)
                _buildSummaryRow('Oneway Conversions', '${totalConversions.toInt()}'),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 20.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'This action cannot be undone. Please verify all details before proceeding.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send, size: 18),
                SizedBox(width: 8.w),
                const Text('Confirm & Submit'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140.w,
            child: Text(
              '$label:',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  bool _validateBeforeSubmit() {
    List<String> errors = [];

    if (_currentMode == 'equal') {
      errors = _validateEqualModeSwitch();
    }

    // Check at least one return or conversion
    final hasReturns = _currentGroups
        .any((g) => !g.isDeleted && g.returnItems.isNotEmpty);

    if (!hasReturns && _conversions.isEmpty) {
      errors.add('Must have at least one return item or conversion');
    }

    // Check duplicate serials
    final duplicates = _findDuplicateSerials();
    if (duplicates.isNotEmpty) {
      errors.add('Duplicate serials detected: ${duplicates.join(", ")}');
    }

    if (errors.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Validation Failed'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: errors
                  .map((error) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        child: Text('• $error'),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  Map<String, dynamic> _buildSubmissionPayload() {
    final returnGroups = _currentGroups
        .where((g) => !g.isDeleted && g.returnItems.isNotEmpty)
        .map((group) {
      return {
        'purchase_invoice_item': group.purchaseInvoiceItem,
        'filled_item_code': group.filledItemCode,
        'is_linked': group.isLinked,
        'items': group.returnItems.map((item) {
          return {
            'item_code': item.itemCode,
            'qty': item.qty,
            'return_type': item.returnType,
            'serial_no': item.selectedSerials.join(','),
            'unlinked_item': item.unlinkedItem ? 1 : 0,
          };
        }).toList(),
      };
    }).toList();

    final conversions = _conversions.map((c) {
      return {
        'purchase_invoice_item': c.purchaseInvoiceItem,
        'filled_item_code': c.filledItemCode,
        'qty': c.qty,
        'original_load_type': c.originalLoadType,
        'converted_to': c.convertedTo,
      };
    }).toList();

    return {
      'purchase_invoice':
          _ervResponse!.data.invoiceDetails.purchaseInvoice,
      'warehouse': _ervResponse!.data.invoiceDetails.warehouse,
      'mode': _currentMode,
      'conversions': conversions,
      'return_groups': returnGroups,
    };
  }

  int _getRemainingCapacity(ItemGroupState group) {
    if (_currentMode != 'equal') return 500; // Unlimited in unequal mode

    final currentTotal =
    group.returnItems.fold<double>(0, (sum, item) => sum + item.qty);
    return (group.targetQty! - currentTotal).toInt();
  }
}

// Helper Classes
class ItemGroupState {
  final String? purchaseInvoiceItem;
  final String? filledItemCode;
  final String filledItemName;
  double? targetQty;  // ✅ Can be modified
  double? receivedQtyCap;  // ✅ Can be modified
  final bool isLinked;
  bool isDeleted;
  final List<ReturnItemState> returnItems;

  ItemGroupState({
    this.purchaseInvoiceItem,
    this.filledItemCode,
    required this.filledItemName,
    this.targetQty,
    this.receivedQtyCap,
    required this.isLinked,
    required this.isDeleted,
    required this.returnItems,
  });
}

class ReturnItemState {
  final String itemCode;
  final String itemName;
  double qty;
  final String returnType;
  List<String> selectedSerials;
  final bool unlinkedItem;

  ReturnItemState({
    required this.itemCode,
    required this.itemName,
    required this.qty,
    required this.returnType,
    required this.selectedSerials,
    required this.unlinkedItem,
  });
}

class ConversionRecord {
  final String purchaseInvoiceItem;
  final String filledItemCode;
  final double qty;
  final String originalLoadType;
  final String convertedTo;

  ConversionRecord({
    required this.purchaseInvoiceItem,
    required this.filledItemCode,
    required this.qty,
    required this.originalLoadType,
    required this.convertedTo,
  });
}

// Convert to One-Way Dialog Widget
class _ConvertToOnewayDialog extends StatefulWidget {
  final ItemGroupState group;
  final Function(double) onConfirm;

  const _ConvertToOnewayDialog({
    required this.group,
    required this.onConfirm,
  });

  @override
  _ConvertToOnewayDialogState createState() => _ConvertToOnewayDialogState();
}

class _QuantityDialogForDefective extends StatefulWidget {
  final DefectiveItem item;
  final int maxQty;
  final ItemGroupState group;
  final Function(int qty) onConfirm;

  const _QuantityDialogForDefective({
    required this.item,
    required this.maxQty,
    required this.group,
    required this.onConfirm,
  });

  @override
  State<_QuantityDialogForDefective> createState() =>
      _QuantityDialogForDefectiveState();
}

class _QuantityDialogForDefectiveState
    extends State<_QuantityDialogForDefective> {
  late TextEditingController _qtyController;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.itemName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: quantity > 1
                    ? () {
                  setState(() {
                    quantity--;
                    _qtyController.text = quantity.toString();
                    _qtyController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _qtyController.text.length),
                    );
                  });
                }
                    : null,
              ),
              SizedBox(
                width: 100.w,
                child: TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        quantity = parsed;
                      });
                    } else if (value.isEmpty) {
                      setState(() {
                        quantity = 0;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: quantity < widget.maxQty
                    ? () {
                  setState(() {
                    quantity++;
                    _qtyController.text = quantity.toString();
                    _qtyController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _qtyController.text.length),
                    );
                  });
                }
                    : null,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (quantity < 1 || quantity > widget.maxQty)
                Icon(Icons.error, color: Colors.red, size: 16.sp)
              else
                Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                quantity < 1
                    ? 'Minimum: 1'
                    : quantity > widget.maxQty
                    ? 'Maximum: ${widget.maxQty}'
                    : 'Valid quantity',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: (quantity < 1 || quantity > widget.maxQty)
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (quantity >= 1 && quantity <= widget.maxQty)
              ? () {
            Navigator.pop(context);
            widget.onConfirm(quantity);
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Select Serials'),
        ),
      ],
    );
  }
}

class _QuantityDialogForEmpty extends StatefulWidget {
  final EmptyItem item;
  final int maxQty;
  final ItemGroupState group;
  final Function(int qty) onConfirm;

  const _QuantityDialogForEmpty({
    required this.item,
    required this.maxQty,
    required this.group,
    required this.onConfirm,
  });

  @override
  State<_QuantityDialogForEmpty> createState() => _QuantityDialogForEmptyState();
}

class _QuantityDialogForEmptyState extends State<_QuantityDialogForEmpty> {
  late TextEditingController _qtyController;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Quantity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.item.itemName,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: quantity > 1
                    ? () {
                  setState(() {
                    quantity--;
                    _qtyController.text = quantity.toString();
                    _qtyController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _qtyController.text.length),
                    );
                  });
                }
                    : null,
              ),
              SizedBox(
                width: 100.w,
                child: TextField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null) {
                      setState(() {
                        quantity = parsed;
                      });
                    } else if (value.isEmpty) {
                      setState(() {
                        quantity = 0;
                      });
                    }
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: quantity < widget.maxQty
                    ? () {
                  setState(() {
                    quantity++;
                    _qtyController.text = quantity.toString();
                    _qtyController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _qtyController.text.length),
                    );
                  });
                }
                    : null,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (quantity < 1 || quantity > widget.maxQty)
                Icon(Icons.error, color: Colors.red, size: 16.sp)
              else
                Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                quantity < 1
                    ? 'Minimum: 1'
                    : quantity > widget.maxQty
                    ? 'Maximum: ${widget.maxQty}'
                    : 'Valid quantity',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: (quantity < 1 || quantity > widget.maxQty)
                      ? Colors.red
                      : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: (quantity >= 1 && quantity <= widget.maxQty)
              ? () {
            Navigator.pop(context);
            widget.onConfirm(quantity);
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _ConvertToOnewayDialogState extends State<_ConvertToOnewayDialog> {
  late TextEditingController _qtyController;
  double convertQty = 0;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController();
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentReturning = widget.group.returnItems
        .fold<double>(0, (sum, item) => sum + item.qty);
    final newTarget = widget.group.targetQty! - convertQty;
    final remainingAfterConversion = newTarget;

    return AlertDialog(
      title: Text('Convert ${widget.group.filledItemName} to One-Way'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current State:',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text('Total received: ${widget.group.targetQty!.toInt()}',
                      style: TextStyle(fontSize: 12.sp)),
                  Text('Currently returning: ${currentReturning.toInt()}',
                      style: TextStyle(fontSize: 12.sp)),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _qtyController,
              decoration: InputDecoration(
                labelText: 'Convert to one-way',
                suffixText: '/ ${widget.group.targetQty!.toInt()}',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                helperText: 'Enter number of cylinders to keep as one-way',
                helperMaxLines: 2,
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  convertQty = double.tryParse(value) ?? 0;
                });
              },
            ),
            if (convertQty > 0) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning,
                            color: Colors.orange.shade700, size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          'Impact of Conversion',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _buildImpactRow(
                        '${convertQty.toInt()} cylinders', 'Kept as one-way (not returned)'),
                    _buildImpactRow(
                        'Target: ${widget.group.targetQty!.toInt()} → ${newTarget.toInt()}',
                        'New return target reduced'),
                    SizedBox(height: 8.h),
                    Text(
                      'Please adjust your return quantities to match the new target of ${newTarget.toInt()}.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: convertQty > 0 && convertQty <= widget.group.targetQty!
              ? () {
            Navigator.pop(context);
            widget.onConfirm(convertQty);
          }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E5CA8),
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm Conversion'),
        ),
      ],
    );
  }

  Widget _buildImpactRow(String label, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: Colors.orange.shade700, size: 16.sp),
          SizedBox(width: 4.w),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.orange.shade900,
                  fontSize: 12.sp,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
