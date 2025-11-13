import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/models/defect_inspection/master_data.dart';
import '../../../core/models/defect_inspection/dir_item.dart';
import '../../widgets/defect_inspection/filled_item_selector.dart';
import '../../widgets/defect_inspection/defect_type_selector.dart';
import '../../widgets/defect_inspection/weight_input_card.dart';
import '../../widgets/defect_inspection/fault_type_dropdown.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional_snackbar.dart';

/// Screen for adding defective items to DIR
class AddDefectiveItemScreen extends StatefulWidget {
  final MasterDataResponse masterData;
  final List<DIRItem> existingItems;

  const AddDefectiveItemScreen({
    super.key,
    required this.masterData,
    required this.existingItems,
  });

  @override
  State<AddDefectiveItemScreen> createState() => _AddDefectiveItemScreenState();
}

class _AddDefectiveItemScreenState extends State<AddDefectiveItemScreen> {
  // Current item form state
  FilledItemMasterData? _selectedFilledItem;
  DefectiveOption? _selectedDefectType;
  String? _selectedFaultType;
  final TextEditingController _cylinderController = TextEditingController();
  final TextEditingController _tareController = TextEditingController();
  final TextEditingController _grossController = TextEditingController();

  // Form validation
  String? _filledItemError;
  String? _defectTypeError;
  String? _faultTypeError;
  String? _cylinderError;
  String? _tareError;
  String? _grossError;

  // Items added in this session
  final List<DIRItem> _newItems = [];

  @override
  void dispose() {
    _cylinderController.dispose();
    _tareController.dispose();
    _grossController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Add Defective Items',
            style: AppTextStyles.h1.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColorsEnhanced.brandBlue,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_newItems.isNotEmpty)
              TextButton(
                onPressed: _finishAdding,
                child: Text(
                  'Done (${_newItems.length})',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_newItems.isNotEmpty) ...[
                _buildItemsAddedBanner(),
                SizedBox(height: AppSpacing.lg.h),
              ],
              _buildItemFormSection(),
              SizedBox(height: AppSpacing.xl.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsAddedBanner() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColorsEnhanced.successGreen,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColorsEnhanced.successGreen,
            size: 28.sp,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_newItems.length} Item${_newItems.length > 1 ? 's' : ''} Added',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColorsEnhanced.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap "Done" to save or add more items',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColorsEnhanced.successGreen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemFormSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: AppColorsEnhanced.brandBlue,
                  size: 24.sp,
                ),
                SizedBox(width: AppSpacing.sm.w),
                Text(
                  'Item Details',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColorsEnhanced.darkGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg.h),

            // Filled Item Selector
            FilledItemSelector(
              items: widget.masterData.items,
              selectedItem: _selectedFilledItem,
              onChanged: _onFilledItemChanged,
              errorText: _filledItemError,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Defect Type Selector
            DefectTypeSelector(
              options: _selectedFilledItem?.defectiveOptions ?? [],
              selectedOption: _selectedDefectType,
              onChanged: _onDefectTypeChanged,
              errorText: _defectTypeError,
              enabled: _selectedFilledItem != null,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Cylinder Serial Input
            _buildTextField(
              label: 'Cylinder Serial *',
              controller: _cylinderController,
              errorText: _cylinderError,
              icon: Icons.qr_code,
              hint: 'Enter cylinder serial number',
            ),
            SizedBox(height: AppSpacing.md.h),

            // Weight Input Card
            WeightInputCard(
              tareController: _tareController,
              grossController: _grossController,
              tareError: _tareError,
              grossError: _grossError,
              onWeightChanged: _onWeightChanged,
            ),
            SizedBox(height: AppSpacing.md.h),

            // Fault Type Dropdown (Required)
            FaultTypeDropdown(
              selectedFaultType: _selectedFaultType,
              onChanged: (value) {
                setState(() {
                  _selectedFaultType = value;
                  _faultTypeError = null;
                });
              },
              errorText: _faultTypeError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    String? errorText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColorsEnhanced.darkGray,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.sm.h),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColorsEnhanced.brandBlue),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            errorText: errorText,
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Add Item Button
        ProfessionalButton(
          text: 'Add Item',
          icon: Icons.add,
          variant: ButtonVariant.primary,
          onPressed: _addItem,
          fullWidth: true,
        ),
        if (_newItems.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md.h),
          // Done Button
          ProfessionalButton(
            text: 'Done (${_newItems.length} Item${_newItems.length > 1 ? 's' : ''})',
            icon: Icons.check_circle,
            variant: ButtonVariant.secondary,
            onPressed: _finishAdding,
            fullWidth: true,
          ),
        ],
      ],
    );
  }

  void _onFilledItemChanged(FilledItemMasterData? item) {
    setState(() {
      _selectedFilledItem = item;
      _selectedDefectType = null; // Reset defect type
      _filledItemError = null;
    });
  }

  void _onDefectTypeChanged(DefectiveOption? option) {
    setState(() {
      _selectedDefectType = option;
      _defectTypeError = null;
    });
  }

  void _onWeightChanged() {
    setState(() {
      _tareError = null;
      _grossError = null;
    });
  }

  void _addItem() {
    // Validate current item
    if (!_validateCurrentItem()) {
      return;
    }

    // Create DIR item
    final item = DIRItem(
      sourceItemCode: _selectedFilledItem!.sourceItemCode,
      sourceItemName: _selectedFilledItem!.sourceItemName,
      targetItemCode: _selectedDefectType!.itemCode,
      targetItemName: _selectedDefectType!.itemName,
      cylinderNumber: _cylinderController.text.trim(),
      tareWeight: double.parse(_tareController.text),
      grossWeight: double.parse(_grossController.text),
      faultType: _selectedFaultType,
    );

    setState(() {
      _newItems.add(item);
      _resetCurrentItem();
    });

    context.showSuccessSnackBar('Item added! Add more or tap "Done"');
  }

  bool _validateCurrentItem() {
    bool isValid = true;

    setState(() {
      _filledItemError = null;
      _defectTypeError = null;
      _faultTypeError = null;
      _cylinderError = null;
      _tareError = null;
      _grossError = null;
    });

    if (_selectedFilledItem == null) {
      setState(() => _filledItemError = 'Please select a filled item');
      isValid = false;
    }

    if (_selectedDefectType == null) {
      setState(() => _defectTypeError = 'Please select a defect type');
      isValid = false;
    }

    if (_selectedFaultType == null) {
      setState(() => _faultTypeError = 'Please select a fault type');
      isValid = false;
    }

    if (_cylinderController.text.trim().isEmpty) {
      setState(() => _cylinderError = 'Cylinder serial is required');
      isValid = false;
    }

    final tare = double.tryParse(_tareController.text);
    if (tare == null || tare <= 0) {
      setState(() => _tareError = 'Tare weight must be greater than 0');
      isValid = false;
    }

    final gross = double.tryParse(_grossController.text);
    if (gross == null || gross <= 0) {
      setState(() => _grossError = 'Gross weight must be greater than 0');
      isValid = false;
    } else if (tare != null && gross <= tare) {
      setState(() => _grossError = 'Gross weight must be greater than tare weight');
      isValid = false;
    }

    return isValid;
  }

  void _resetCurrentItem() {
    _selectedFilledItem = null;
    _selectedDefectType = null;
    _selectedFaultType = null;
    _cylinderController.clear();
    _tareController.clear();
    _grossController.clear();
  }

  void _finishAdding() {
    if (_newItems.isEmpty) {
      context.showErrorSnackBar('Please add at least one item');
      return;
    }

    // Return all items (existing + new)
    final allItems = [...widget.existingItems, ..._newItems];
    Navigator.pop(context, allItems);
  }

  void _confirmExit() {
    if (_newItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Discard Items?',
          style: AppTextStyles.h2.copyWith(
            color: AppColorsEnhanced.darkGray,
          ),
        ),
        content: Text(
          'You have ${_newItems.length} unsaved item${_newItems.length > 1 ? 's' : ''}. Do you want to save them or discard?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen without saving
            },
            child: Text(
              'Discard',
              style: TextStyle(color: AppColorsEnhanced.errorRed),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog only
            },
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColorsEnhanced.darkGray),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _finishAdding(); // Save and exit
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEnhanced.brandBlue,
            ),
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
