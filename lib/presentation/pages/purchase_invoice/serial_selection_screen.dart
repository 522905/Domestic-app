import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/models/purchase_invoice/erv_models.dart';

class SerialSelectionScreen extends StatefulWidget {
  final String itemCode;
  final String itemName;
  final int requiredQty;
  final List<SerialDetail> availableSerials;
  final List<SerialDetail> preselectedSerials;

  const SerialSelectionScreen({
    Key? key,
    required this.itemCode,
    required this.itemName,
    required this.requiredQty,
    required this.availableSerials,
    required this.preselectedSerials,
  }) : super(key: key);

  @override
  State<SerialSelectionScreen> createState() => _SerialSelectionScreenState();
}

class _SerialSelectionScreenState extends State<SerialSelectionScreen> {
  late List<SerialDetail> _selectedSerials;
  late List<SerialDetail> _filteredSerials;
  String _searchQuery = '';
  String _filterBy = 'all'; // 'all', 'from_pi', 'other'
  String _sortBy = 'serial_no'; // 'serial_no', 'weight', 'fault_type'

  @override
  void initState() {
    super.initState();
    _selectedSerials = List.from(widget.preselectedSerials);
    _filteredSerials = List.from(widget.availableSerials);
    _applyFilters();
  }

  void _applyFilters() {
    setState(() {
      _filteredSerials = widget.availableSerials.where((serial) {
        // Filter by search query
        final matchesSearch = _searchQuery.isEmpty ||
            serial.serialNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            serial.customFaultType.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            serial.customNetWeightOfCylinder.toString().contains(_searchQuery);

        // Filter by source
        final matchesFilter = _filterBy == 'all' ||
            (_filterBy == 'from_pi' && serial.fromThisPi) ||
            (_filterBy == 'other' && !serial.fromThisPi);

        // Filter by availability
        final isAvailable = serial.isAvailable;

        return matchesSearch && matchesFilter && isAvailable;
      }).toList();

      // Sort
      _filteredSerials.sort((a, b) {
        switch (_sortBy) {
          case 'weight':
            return b.customNetWeightOfCylinder.compareTo(a.customNetWeightOfCylinder);
          case 'fault_type':
            return a.customFaultType.compareTo(b.customFaultType);
          case 'serial_no':
          default:
            return a.serialNo.compareTo(b.serialNo);
        }
      });

      // Sort selected items to top if they're in filtered list
      _filteredSerials.sort((a, b) {
        final aSelected = _selectedSerials.any((s) => s.serialNo == a.serialNo);
        final bSelected = _selectedSerials.any((s) => s.serialNo == b.serialNo);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return 0;
      });
    });
  }

  void _toggleSerial(SerialDetail serial) {
    setState(() {
      final index = _selectedSerials.indexWhere((s) => s.serialNo == serial.serialNo);
      if (index != -1) {
        _selectedSerials.removeAt(index);
      } else {
        if (_selectedSerials.length < widget.requiredQty) {
          _selectedSerials.add(serial);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.requiredQty} serials allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    });
  }

  void _selectFromThisPiFirst() {
    setState(() {
      _selectedSerials.clear();

      // First select from this PI
      final fromThisPi = _filteredSerials
          .where((s) => s.fromThisPi && s.isAvailable)
          .take(widget.requiredQty)
          .toList();

      _selectedSerials.addAll(fromThisPi);

      // If not enough, add from others
      if (_selectedSerials.length < widget.requiredQty) {
        final remaining = widget.requiredQty - _selectedSerials.length;
        final others = _filteredSerials
            .where((s) => !s.fromThisPi && s.isAvailable && !_selectedSerials.contains(s))
            .take(remaining)
            .toList();
        _selectedSerials.addAll(others);
      }

      _applyFilters();
    });
  }

  void _clearAll() {
    setState(() {
      _selectedSerials.clear();
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _selectedSerials.length == widget.requiredQty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          'Select Serial Numbers',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedSerials.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFiltersRow(),
          Expanded(child: _buildSerialsList()),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(isComplete),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.itemName,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4.h),
          Text(
            widget.itemCode,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[600]),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  'Required',
                  widget.requiredQty.toString(),
                  Colors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatusCard(
                  'Selected',
                  _selectedSerials.length.toString(),
                  _selectedSerials.length == widget.requiredQty ? Colors.green : Colors.orange,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _buildStatusCard(
                  'Available',
                  _filteredSerials.length.toString(),
                  Colors.grey,
                ),
              ),
            ],
          ),
          if (_selectedSerials.length < widget.requiredQty) ...[
            SizedBox(height: 12.h),
            ElevatedButton.icon(
              onPressed: _selectFromThisPiFirst,
              icon: Icon(Icons.auto_fix_high, size: 16.sp),
              label: const Text('Auto-select from PI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 40.h),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16.w),
      color: Colors.white,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by serial, fault type, or weight...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0E5CA8)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Filter', style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                SizedBox(height: 4.h),
                DropdownButtonFormField<String>(
                  value: _filterBy,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'from_pi', child: Text('From PI')),
                    DropdownMenuItem(value: 'other', child: Text('Others')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterBy = value!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sort by', style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
                SizedBox(height: 4.h),
                DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'serial_no', child: Text('Serial No')),
                    DropdownMenuItem(value: 'weight', child: Text('Weight')),
                    DropdownMenuItem(value: 'fault_type', child: Text('Fault Type')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _applyFilters();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSerialsList() {
    if (_filteredSerials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64.w, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              'No serials found',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty || _filterBy != 'all') ...[
              SizedBox(height: 8.h),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _filterBy = 'all';
                    _applyFilters();
                  });
                },
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _filteredSerials.length,
      itemBuilder: (context, index) {
        final serial = _filteredSerials[index];
        final isSelected = _selectedSerials.any((s) => s.serialNo == serial.serialNo);
        final canSelect = _selectedSerials.length < widget.requiredQty || isSelected;

        return _buildSerialCard(serial, isSelected, canSelect);
      },
    );
  }

  Widget _buildSerialCard(SerialDetail serial, bool isSelected, bool canSelect) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: isSelected ? const Color(0xFF0E5CA8) : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: canSelect ? () => _toggleSerial(serial) : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0E5CA8) : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF0E5CA8) : Colors.grey,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16.sp)
                    : null,
              ),
              SizedBox(width: 12.w),

              // Serial details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            serial.serialNo,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (serial.fromThisPi)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Text(
                              'From PI',
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(Icons.scale, size: 14.sp, color: Colors.grey[600]),
                        SizedBox(width: 4.w),
                        Text(
                          '${serial.customNetWeightOfCylinder} kg',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                        SizedBox(width: 12.w),
                        Icon(Icons.warning, size: 14.sp, color: Colors.red[600]),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Text(
                            serial.customFaultType,
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (!canSelect && !isSelected)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Limit reached',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isComplete) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isComplete)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20.sp),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select ${widget.requiredQty - _selectedSerials.length} more serial(s)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ElevatedButton(
            onPressed: isComplete
                ? () => Navigator.pop(context, _selectedSerials)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(
              isComplete
                  ? 'Confirm Selection (${_selectedSerials.length})'
                  : 'Select ${widget.requiredQty} Serials',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
