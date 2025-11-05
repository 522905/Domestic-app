import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
import '../../../../core/services/User.dart';
import '../../../../utils/gatepass_dialog.dart';
import '../../../widgets/selectors/driver_selector_dialog.dart';
import '../../../widgets/selectors/item_selector_dialog.dart';
import '../../../widgets/selectors/warehouse_selector_dialog.dart';
import '../../../widgets/professional_snackbar.dart';

class InventoryTransferScreen extends StatefulWidget {
  final List<Map<String, dynamic>> warehouses;
  final List<Map<String, dynamic>> warehousesItemList;
  final String? userName;

  const InventoryTransferScreen({
    Key? key,
    required this.warehouses,
    required this.warehousesItemList,
    required this.userName
  }) : super(key: key);

  @override
  State<InventoryTransferScreen> createState() =>
      _InventoryTransferScreenState();
}

class _InventoryTransferScreenState extends State<InventoryTransferScreen> {
  final _formKey = GlobalKey<FormState>();

  // Driver Details
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _fromWarehouseController = TextEditingController();
  final TextEditingController _toWarehouseController = TextEditingController();

  final gatepassId = 'WH1-TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';
  final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final time = DateFormat('HH:mm').format(DateTime.now());

  File? _driverPhotoFile;
  bool _isKnownDeliveryPartner = false;
  bool _isVehicleSelected = false;
  List<Map<String, dynamic>> _selectedItems = [];

  String _fromWarehouse = '' ;
  String _toWarehouse = '' ;
  String? _userName = '' ;
  List<Map<String, dynamic>> _deliveryPartners = [];
  bool _isLoading = true;

  Future<void> _loadData() async {
    try {
      final apiService = context.read<InventoryBloc>().apiService;
      var deliveryPartners = await apiService.getVehiclesList();
      String? userName = await User().getUserName();
      setState(() {
        _deliveryPartners = List<Map<String, dynamic>>.from(deliveryPartners);
        _isLoading = false;
        _userName = userName;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar('Failed to load data: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _phoneNumberController.dispose();
    _vehicleNumberController.dispose();
    _fromWarehouseController.dispose();
    _toWarehouseController.dispose();
    super.dispose();
  }

  void _checkVehicleSelection() {
    setState(() {
      _isVehicleSelected = _vehicleNumberController.text.isNotEmpty;
    });
  }

  void _populateDriverDetails(Map<String, dynamic> partner) {
    _driverNameController.text = partner['name'] ?? '';
    _phoneNumberController.text = partner['phone'] ?? '';
    _vehicleNumberController.text = partner['vehicle'] ?? '';
    _checkVehicleSelection();
  }

  Future<void> _captureDriverPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _driverPhotoFile = File(image.path);
      });
    }
  }

  void _showAddItemDialog({int? editIndex}) {
    if (widget.warehousesItemList.isEmpty) {
      context.showInfoSnackBar('No items available');
      return;
    }

    ItemSelectorDialog.showForDeposit(
      context,
      widget.warehousesItemList,
          (item) {
        setState(() {
          if (editIndex != null) {
            _selectedItems[editIndex] = item;
          } else {
            _selectedItems.add(item);
          }
        });
      },
      initialItem: editIndex != null ? _selectedItems[editIndex] : null,
    );
  }

  Widget _buildKnownDriverSelector() {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          SizedBox(
            width: 24.w,
            height: 24.h,
            child: Checkbox(
              value: _isKnownDeliveryPartner,
              onChanged: (value) {
                setState(() {
                  _isKnownDeliveryPartner = value ?? false;
                  if (_isKnownDeliveryPartner && _deliveryPartners.isNotEmpty) {
                    _populateDriverDetails(_deliveryPartners[0]);
                  } else {
                    _driverNameController.clear();
                    _phoneNumberController.clear();
                    _vehicleNumberController.clear();
                    _driverPhotoFile = null;
                    _checkVehicleSelection();
                  }
                });
              },
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Regular delivery partner',
            style: TextStyle(fontSize: 14.sp),
          ),
          SizedBox(width: 8.w),
            Expanded(
              child: TextButton(
                onPressed: () {
                  if (_deliveryPartners.isNotEmpty) {
                    DriverSelectorDialog.show(
                      context,
                      _deliveryPartners,
                          (driver) {
                        setState(() {
                          _populateDriverDetails(driver);
                        });
                      },
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_driverNameController.text} (${_vehicleNumberController.text})',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.sp, color: Colors.blue[800]),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.blue[800]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  InventoryRequest _createTransferRequestFromItems() {

    // Create transfer request with totals
    return InventoryRequest(
      id: 'TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
      warehouseId: _fromWarehouse,
      warehouse: 'From: ${_fromWarehouse.split(' ')[0]} To: ${_toWarehouse.split(' ')[0]}',
      requestedBy: widget.userName ?? 'Unknown User',
      requestType: 'Transfer',
      status: 'PENDING',
      timestamp: '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
      isFavorite: false,
      vehicle: null,
      sourceWarehouse: _fromWarehouse ,
      targetWarehouse: _toWarehouse ,
      stockEntryType: "Material Transfer",
      customerName: _toWarehouse,
      items: _selectedItems.map((item) => {
        "item_code": item['itemId'] ?? '', // Use 'itemId' instead of 'item_code'
        "qty": item['quantity'] ?? 0,      // Ensure 'quantity' is mapped correctly
        }).toList(),
        driverInfo: [
          {
            "driver_name": _driverNameController.text.isNotEmpty ? _driverNameController.text : 'Unknown',
            "phone_number": _phoneNumberController.text.isNotEmpty ? _phoneNumberController.text : 'Unknown',
            "vehicle_number": _vehicleNumberController.text.isNotEmpty ? _vehicleNumberController.text : 'Unknown',
          },
        ],
        regularDeliveryPartner: _isKnownDeliveryPartner,
        imageUrl: _driverPhotoFile?.path,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Transfer'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Warehouse Selection'),
              Text('From Warehouse',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _isVehicleSelected ? Colors.grey[300]! : Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8.r),
                  color: _isVehicleSelected ? Colors.white : Colors.grey[100],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fromWarehouseController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText:  'Select origin warehouse'
                        ),
                        onTap:() {
                            // WarehouseSelectorDialog.show(
                            //   context,
                            //   true,
                            //   widget.warehouses, // Pass the warehouses data
                            //       (warehouse) {
                            //     setState(() {
                            //       _fromWarehouseController.text = warehouse['warehouse'] ?? '';
                            //       _fromWarehouse = warehouse['warehouse'] ?? '';
                            //     });
                            //   },
                            // );
                        }
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: _isVehicleSelected ? Colors.grey : Colors.grey[400]),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Text('To Warehouse',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _isVehicleSelected ? Colors.grey[300]! : Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8.r),
                  color: _isVehicleSelected ? Colors.white : Colors.grey[100],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _toWarehouseController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Select destination warehouse'
                        ),
                        onTap: () {
                          // WarehouseSelectorDialog.show(
                          //   context,
                          //   false, // isOriginWarehouse = false for destination
                          //   widget.warehouses, // Pass the warehouses data
                          //       (warehouse) {
                          //     setState(() {
                          //       _toWarehouseController.text = warehouse['warehouse'] ?? '';
                          //       _toWarehouse = warehouse['warehouse'] ?? '';
                          //     });
                          //   },
                          // );
                        }
                      ),
                    ),
                    Icon(Icons.arrow_drop_down,
                        color: _isVehicleSelected ? Colors.grey : Colors.grey[400]),
                  ],
                ),
              ),
              SizedBox(height: 24.h),

              // Driver Details Section
              _buildSectionHeader('Driver Details'),
              _buildKnownDriverSelector(),

              // Name Field
              Text('Driver Name',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _driverNameController,
                readOnly: _isKnownDeliveryPartner,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter driver name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),

              // Phone Number Field
              Text('Phone Number',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),

              // Vehicle Number Field
              Text('Vehicle Number',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _vehicleNumberController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                onChanged: (_) => _checkVehicleSelection(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Transfer Items Section - FIXED VERSION
              _buildSectionHeader('Transfer Items'),

              // Show empty state if no items
              if (_selectedItems.isEmpty)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No items added yet',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      OutlinedButton.icon(
                        icon: Icon(Icons.add_circle_outline, color: Colors.blue[800]),
                        label: Text('ADD ITEM', style: TextStyle(color: Colors.blue[800])),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () => _showAddItemDialog(),
                      ),
                    ],
                  ),
                ),

              // Show selected items if any exist
              if (_selectedItems.isNotEmpty) ...[
                // Display each selected item
                ...List.generate(_selectedItems.length, (index) {
                  final item = _selectedItems[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    child: Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          // Item type icon
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.inventory,
                              color: Colors.blue[800],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Item details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'Quantity: ${item['quantity'] ?? 0} • Available: ${item['available'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Edit button
                          IconButton(
                            icon: Icon(Icons.edit, size: 20.sp),
                            onPressed: () => _showAddItemDialog(editIndex: index),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                          SizedBox(width: 8.w),
                          // Delete button
                          IconButton(
                            icon: Icon(Icons.delete, size: 20.sp, color: Colors.red[400]),
                            onPressed: () {
                              setState(() {
                                _selectedItems.removeAt(index);
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.add_circle_outline, color: Colors.blue[800]),
                      label: Text('ADD MORE ITEMS  ', style: TextStyle(color: Colors.blue[800])),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.blue[800]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onPressed: () => _showAddItemDialog(),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 14.h),
              // Driver Photo Section - Only shown for unknown drivers
              Visibility(
                visible: !_isKnownDeliveryPartner,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Driver Verification Photo'),
                    Text(
                      'Photo required for unknown drivers',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: () {
                        if (_driverPhotoFile == null) {
                          _captureDriverPhoto();
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: const Text('View Image'),
                                  backgroundColor: Colors.blue[800],
                                ),
                                body: Center(
                                  child: Image.file(_driverPhotoFile!),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      child: _driverPhotoFile != null
                          ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.file(
                              _driverPhotoFile!,
                              width: double.infinity,
                              height: 200.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8.h,
                            right: 8.w,
                            child: IconButton(
                              icon: Icon(Icons.edit, color: Colors.white),
                              onPressed: _captureDriverPhoto,
                            ),
                          ),
                        ],
                      )
                          : Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 32.sp,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'CAPTURE DRIVER PHOTO',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'For Internal Verification',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),

              // Generate Gatepass Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    bool isPhotoRequired = !_isKnownDeliveryPartner;

                    // Replace the ENTIRE showDialog section in your Generate Gatepass button:

                    if (_formKey.currentState!.validate() &&
                        (_driverPhotoFile != null || !isPhotoRequired) &&
                        _selectedItems.isNotEmpty) {

                      // Create gatepass data with CORRECT field mapping
                      final gatepassData = {
                        'gatepassNo': gatepassId,
                        'date': date,
                        'time': time,
                        'from': _fromWarehouse.isNotEmpty ? _fromWarehouse : 'Not specified',
                        'to': _toWarehouse.isNotEmpty ? _toWarehouse : 'Not specified',
                        'driver': _driverNameController.text.isNotEmpty ? _driverNameController.text : 'Not specified',
                        'phone': _phoneNumberController.text.isNotEmpty ? _phoneNumberController.text : 'Not specified',
                        'vehicle': _vehicleNumberController.text.isNotEmpty ? _vehicleNumberController.text : 'Not specified',
                        'items': _selectedItems.map((item) {
                          // Debug: Print the item structure to understand what fields are available
                          print('Item structure: $item');
                          return {
                            "name": item['name']?.toString() ??
                                item['item_name']?.toString() ??
                                item['itemName']?.toString() ??
                                'Unknown Item',
                            "quantity": item['quantity']?.toString() ??
                                item['qty']?.toString() ??
                                item['amount']?.toString() ??
                                '0',
                          };
                        }).toList(),
                        'authorizedBy': _userName ?? 'Unknown User',
                      };

                      // showDialog(
                      //   context: context,
                      //   builder: (context) => SimpleGatepassDialog(
                      //     gatepassData: gatepassData,
                      //   ),
                      // );
                    } else if (_driverPhotoFile == null && isPhotoRequired) {
                      context.showInfoSnackBar('Driver photo is required for unknown drivers');
                    } else if (_selectedItems.isEmpty) {
                      context.showWarningSnackBar('Please add at least one item to transfer');
                    } else if (_selectedItems.isEmpty) {
                      context.showWarningSnackBar('Please add at least one item to transfer');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'GENERATE GATEPASS',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Create Transfer Button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    bool isPhotoRequired = !_isKnownDeliveryPartner;

                    if (_formKey.currentState!.validate() &&
                        (_driverPhotoFile != null || !isPhotoRequired) &&
                        _selectedItems.isNotEmpty) {

                      final transferRequest = _createTransferRequestFromItems();
                      context
                          .read<InventoryBloc>()
                          .add(AddInventoryRequest(request: transferRequest));

                      context.showSuccessSnackBar('Transfer request created successfully');

                      Navigator.pop(context);
                    } else if (_driverPhotoFile == null && isPhotoRequired) {
                      context.showInfoSnackBar('Driver photo is required for unknown drivers');
                    } else if (_selectedItems.isEmpty) {
                      context.showWarningSnackBar('Please add at least one item to transfer');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    'CREATE TRANSFER',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}