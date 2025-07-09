// Make sure these are at the top of your file
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:lpg_distribution_app/core/models/inventory_request.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_bloc.dart';
import 'package:lpg_distribution_app/presentation/blocs/inventory/inventory_event.dart';
import '../../../../utils/gatepass_dialog.dart';
import '../../../widgets/selectors/driver_selector_dialog.dart';
import '../../../widgets/selectors/item_selector_dialog.dart';
import '../../../widgets/selectors/warehouse_selector_dialog.dart';

class InventoryTransferScreen extends StatefulWidget {
  const InventoryTransferScreen({Key? key}) : super(key: key);

  @override
  State<InventoryTransferScreen> createState() =>
      _InventoryTransferScreenState();
}

class _InventoryTransferScreenState extends State<InventoryTransferScreen> {
  final _formKey = GlobalKey<FormState>();

  // Driver Details
  final TextEditingController _driverNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();
  final TextEditingController _fromWarehouseController =
      TextEditingController();
  final TextEditingController _toWarehouseController = TextEditingController();

  final gatepassId =
      'WH1-TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';
  final date = DateFormat('dd/MM/yyyy').format(DateTime.now());
  final time = DateFormat('HH:mm').format(DateTime.now());

  File? _driverPhotoFile;
  bool _isKnownDeliveryPartner = false;
  bool _isVehicleSelected = false;
  List<Map<String, dynamic>> _selectedItems = [];

  String _fromWarehouse = 'Warehouse 1 (Ludhiana Central)';
  String _toWarehouse = 'Warehouse 2 (Ludhiana North)';

  final List<Map<String, dynamic>> _deliveryPartners = [
    {
      'name': 'Rajesh Kumar',
      'phone': '+91 98765 43210',
      'vehicle': 'PB 10 AB 1234'
    },
    {
      'name': 'Sunil Verma',
      'phone': '+91 87654 32109',
      'vehicle': 'PB 10 CD 5678'
    },
    {
      'name': 'Amit Singh',
      'phone': '+91 76543 21098',
      'vehicle': 'PB 11 EF 9012'
    },
  ];

  final List<String> _itemOptions = [
    '14kg cylinder',
    '5kg cylinder',
    'chotu cylinder',
    'pipe', 'regulator', 'stove'
  ];
  final List<String> _nfrOptions = ['Regulator', 'Pipe', 'Stove'];

  @override
  void initState() {
    super.initState();
    // Default to the first delivery partner
    _isKnownDeliveryPartner = true;
    _populateDriverDetails(_deliveryPartners[0]);
    _isVehicleSelected = true;
    _fromWarehouseController.text = "Warehouse 1 (Ludhiana Central)";
    _toWarehouseController.text = "Warehouse 2 (Ludhiana North)";
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
    _driverNameController.text = partner['name'];
    _phoneNumberController.text = partner['phone'];
    _vehicleNumberController.text = partner['vehicle'];
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

  // Replace _showAddItemDialog with:
  void _showAddItemDialog({int? editIndex}) {
    Map<String, dynamic>? initialItem;
    if (editIndex != null) {
      initialItem = _selectedItems[editIndex];
    }

    ItemSelectorDialog.show(
      context,
      _itemOptions,
      _nfrOptions,
          (item) {
        setState(() {
          if (editIndex != null) {
            _selectedItems[editIndex] = item;
          } else {
            _selectedItems.add(item);
          }
        });
      },
      initialItem: initialItem,
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
                  if (_isKnownDeliveryPartner) {
                    _populateDriverDetails(_deliveryPartners[0]);
                  } else {
                    _driverNameController.clear();
                    _phoneNumberController.clear();
                    _vehicleNumberController.clear();
                    _driverPhotoFile = null;
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
          if (_isKnownDeliveryPartner)
            Expanded(
              child: TextButton(
                onPressed: () {
                  // Use the reusable driver selector
                  DriverSelectorDialog.show(
                    context,
                    _deliveryPartners,
                        (driver) {
                      setState(() {
                        _populateDriverDetails(driver);
                      });
                    },
                  );
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
    // Count cylinders by type
    int cylinders14kg = 0;
    int cylinders19kg = 0;
    int smallCylinders = 0;

    for (var item in _selectedItems) {
      if (item['type'] == 'Filled Cylinder') {
        cylinders14kg += item['quantity'] as int;
      } else if (item['type'] == 'Empty Cylinder') {
        smallCylinders += item['quantity'] as int;
      }
    }

    // Create transfer request with totals
    return InventoryRequest(
      id: 'TR-${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
      warehouseId: 'Transfer-${_fromWarehouse}-${_toWarehouse}',
      warehouseName:
          'From: ${_fromWarehouse.split(' ')[0]} To: ${_toWarehouse.split(' ')[0]}',
      requestedBy: _driverNameController.text,
      role: 'Driver',
      cylinders14kg: cylinders14kg,
      cylinders19kg: cylinders19kg,
      smallCylinders: smallCylinders,
      status: 'PENDING',
      timestamp: '${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
      isFavorite: false,
    );
  }

  String _getItemDisplayName(Map<String, dynamic> item) {
    if (item['type'] == 'NFR' && item['nfrType'] != null) {
      return '${item['type']} - ${item['nfrType']}';
    }
    return item['type'];
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
              // Warehouse Selection Section
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
                        enabled: _isVehicleSelected,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isVehicleSelected
                              ? 'Select origin warehouse'
                              : 'Select a vehicle first',
                        ),
                        onTap: _isVehicleSelected
                            ? () {
                          // Use the reusable dialog
                          WarehouseSelectorDialog.show(
                            context,
                            true, // isOriginWarehouse
                                (warehouse) {
                              setState(() {
                                _fromWarehouseController.text = warehouse['name'];
                                _fromWarehouse = warehouse['name'];
                              });
                            },
                          );
                        }
                            : null,
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
                        enabled: _isVehicleSelected,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isVehicleSelected
                              ? 'Select destination warehouse'
                              : 'Select a vehicle first',
                        ),
                        onTap: _isVehicleSelected
                            ? () {
                          // Use the reusable dialog with false to indicate destination
                          WarehouseSelectorDialog.show(
                            context,
                            false, // isOriginWarehouse = false for destination
                                (warehouse) {
                              setState(() {
                                _toWarehouseController.text = warehouse['name'];
                                _toWarehouse = warehouse['name'];
                              });
                            },
                          );
                        }
                            : null,
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
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _driverNameController,
                readOnly: _isKnownDeliveryPartner,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
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
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _phoneNumberController,
                readOnly: _isKnownDeliveryPartner,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
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
                  style:
                      TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp)),
              SizedBox(height: 4.h),
              TextFormField(
                controller: _vehicleNumberController,
                readOnly: _isKnownDeliveryPartner,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter vehicle number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24.h),

              // Transfer Items Section
              _buildSectionHeader('Transfer Items'),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount:
                    _selectedItems.length + 1, // +1 for the "Add Item" button
                itemBuilder: (context, index) {
                  if (index == _selectedItems.length) {
                    // Last item - "Add Item" button
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.add_circle_outline,
                            color: Colors.blue[800]),
                        label: Text('ADD ITEM',
                            style: TextStyle(color: Colors.blue[800])),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.blue[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        onPressed: () => _showAddItemDialog(),
                      ),
                    );
                  } else {
                    // Display selected item with edit/delete options
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
                                Icons.label,
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
                                    _getItemDisplayName(item),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  Text(
                                    'Quantity: ${item['quantity']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Edit button
                            IconButton(
                              icon: Icon(Icons.edit, size: 20.sp),
                              onPressed: () =>
                                  _showAddItemDialog(editIndex: index),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                            SizedBox(width: 8.w),
                            // Delete button
                            IconButton(
                              icon: Icon(Icons.delete,
                                  size: 20.sp, color: Colors.red[400]),
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
                  }
                },
              ),
              SizedBox(height: 24.h),

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
                    // Check if photo is required (only for unknown drivers)
                    bool isPhotoRequired = !_isKnownDeliveryPartner;

                    if (_formKey.currentState!.validate() &&
                        (_driverPhotoFile != null || !isPhotoRequired) &&
                        _selectedItems.isNotEmpty) {
                      // Create gatepass data
                      final gatepassData = {
                        'gatepassNo': gatepassId,
                        'date': date,
                        'time': time,
                        'from': _fromWarehouse,
                        'to': _toWarehouse,
                        'driver': _driverNameController.text,
                        'phone': _phoneNumberController.text,
                        'vehicle': _vehicleNumberController.text,
                        'items': _selectedItems
                            .map((item) => {
                                  'name': _getItemDisplayName(item),
                                  'quantity': item['quantity'],
                                })
                            .toList(),
                        'authorizedBy': 'Amit Singh',
                      };

                      showDialog(
                          context: context,
                          builder: (context) => SimpleGatepassDialog(
                                gatepassData: gatepassData,
                              ));
                    } else if (_driverPhotoFile == null && isPhotoRequired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Driver photo is required for unknown drivers')),
                      );
                    } else if (_selectedItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please add at least one item to transfer')),
                      );
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
                    // Check if photo is required (only for unknown drivers)
                    bool isPhotoRequired = !_isKnownDeliveryPartner;

                    // Handle transfer creation
                    if (_formKey.currentState!.validate() &&
                        (_driverPhotoFile != null || !isPhotoRequired) &&
                        _selectedItems.isNotEmpty) {
                      // Create transfer request and add to bloc
                      final transferRequest = _createTransferRequestFromItems();
                      context
                          .read<InventoryBloc>()
                          .add(AddInventoryRequest(request: transferRequest));

                      // Create detailed transfer data for future reference
                      final transferDetails = {
                        'id': transferRequest.id,
                        'fromWarehouse': _fromWarehouse,
                        'toWarehouse': _toWarehouse,
                        'driver': {
                          'name': _driverNameController.text,
                          'phone': _phoneNumberController.text,
                          'vehicle': _vehicleNumberController.text,
                          'photoPath': _driverPhotoFile?.path,
                          'isKnownDriver': _isKnownDeliveryPartner,
                        },
                        'items': _selectedItems,
                        'gatepassId': gatepassId,
                        'date': date,
                        'time': time,
                      };

                      // In a real app, store this detailed data in your database

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Transfer request created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Navigate back to inventory list
                      Navigator.pop(context);
                    } else if (_driverPhotoFile == null && isPhotoRequired) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Driver photo is required for unknown drivers')),
                      );
                    } else if (_selectedItems.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please add at least one item to transfer')),
                      );
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
