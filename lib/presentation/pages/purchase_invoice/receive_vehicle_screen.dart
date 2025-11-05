// lib/presentation/pages/purchase_invoice/receive_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import 'dart:async';
import 'dart:io';
import '../../../core/services/api_service_interface.dart';
import '../../widgets/professional_snackbar.dart';

class ReceiveVehicleScreen extends StatefulWidget {
  final String supplierGstin;
  final String supplierInvoiceDate;
  final String supplierInvoiceNumber;

  const ReceiveVehicleScreen({
    Key? key,
    required this.supplierGstin,
    required this.supplierInvoiceDate,
    required this.supplierInvoiceNumber,
  }) : super(key: key);

  @override
  State<ReceiveVehicleScreen> createState() => _ReceiveVehicleScreenState();
}

// Enum for better state management
enum DriverSelectionState {
  needsSelection,
  searchingDrivers,
  driversFound,
  creatingNew,
  driverSelected
}

enum ScreenState {
  loading,
  loaded,
  error,
  submitting
}

class _ReceiveVehicleScreenState extends State<ReceiveVehicleScreen> {
  late ApiServiceInterface _apiService;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _driverNameController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _seedCodeController = TextEditingController();

  // Debouncing
  Timer? _searchDebounceTimer;

  // Core state
  ScreenState _screenState = ScreenState.loading;
  DriverSelectionState _driverState = DriverSelectionState.needsSelection;

  // Data
  Map<String, dynamic> _invoiceDetails = {};
  List<Map<String, dynamic>> _warehouses = [];
  List<Map<String, dynamic>> _searchedDrivers = [];

  // Selected items
  Map<String, dynamic>? _selectedWarehouse;
  Map<String, dynamic>? _selectedDriver;
  String? _photoUrl;

  // TUS upload state
  TusClient? _tusClient;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;

  // Driver info from invoice
  int? _existingDriverId;
  bool get _needsNewDriver => _existingDriverId == null;

  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _apiService = Provider.of<ApiServiceInterface>(context, listen: false);
    _loadInitialData();
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverPhoneController.dispose();
    _seedCodeController.dispose();
    _searchDebounceTimer?.cancel();
    _tusClient = null;
    super.dispose();
  }

  // MARK: - Data Loading
  Future<void> _loadInitialData() async {
    setState(() {
      _screenState = ScreenState.loading;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        _apiService.getInvoiceDetails(
          widget.supplierGstin,
          widget.supplierInvoiceDate,
          widget.supplierInvoiceNumber,
        ),
        _apiService.getWarehouses(),
      ]);

      final details = results[0] as Map<String, dynamic>;
      final warehouses = results[1] as List<dynamic>;

      _existingDriverId = details['workflow']?['inevent']?['driver']?['id'];

      setState(() {
        _invoiceDetails = details;
        _warehouses = List<Map<String, dynamic>>.from(warehouses);
        _screenState = ScreenState.loaded;
        _driverState = _needsNewDriver
            ? DriverSelectionState.needsSelection
            : DriverSelectionState.driverSelected;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _screenState = ScreenState.error;
      });
    }
  }

  // MARK: - Driver Search
  void _searchDrivers() {
    final phone = _driverPhoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar('Please enter a valid 10-digit phone number', isError: true);
      return;
    }

    // Debounce rapid clicks
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performDriverSearch(phone);
    });
  }

  Future<void> _performDriverSearch(String phone) async {
    setState(() {
      _driverState = DriverSelectionState.searchingDrivers;
      _searchedDrivers.clear();
      _selectedDriver = null;
    });

    try {
      final results = await _apiService.searchDrivers(phone);
      final drivers = List<Map<String, dynamic>>.from(results);

      setState(() {
        _searchedDrivers = drivers;
        _driverState = drivers.isEmpty
            ? DriverSelectionState.creatingNew
            : DriverSelectionState.driversFound;
      });

      if (drivers.isNotEmpty) {
        _showDriverSelectionDialog();
      }

    } catch (e) {
      setState(() {
        _driverState = DriverSelectionState.creatingNew;
        _searchedDrivers.clear();
      });
      _showSnackBar('Search failed: $e', isError: true);
    }
  }

  // MARK: - Driver Selection Dialog
  void _showDriverSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DriverSelectionDialog(
        drivers: _searchedDrivers,
        onDriverSelected: (driver) {
          setState(() {
            _selectedDriver = driver;
            _driverState = DriverSelectionState.driverSelected;
          });
        },
        onCreateNew: () {
          setState(() {
            _driverState = DriverSelectionState.creatingNew;
          });
        },
        onDriverDetails: _showDriverDetails,
      ),
    );
  }

  // MARK: - Driver Details
  Future<void> _showDriverDetails(int driverId) async {
    showDialog(
      context: context,
      builder: (context) => DriverDetailsDialog(
        driverId: driverId,
        apiService: _apiService,
      ),
    );
  }

  // MARK: - Photo Capture with TUS Client
  Future<void> _capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 600,
      );

      if (photo != null) {
        setState(() {
          _isUploadingPhoto = true;
          _uploadProgress = 0.0;
          _photoUrl = null;
        });

        _tusClient = TusClient(photo);

        await _tusClient!.upload(
          uri: Uri.parse('http://arungas.com:1080/files/'),
          onComplete: () {
            print('TUS Upload complete! URL: ${_tusClient!.uploadUrl}');
            if (mounted) {
              setState(() {
                _photoUrl = _tusClient!.uploadUrl.toString();
                _isUploadingPhoto = false;
                _uploadProgress = 100.0;
              });
              _showSnackBar('Photo uploaded successfully');
            }
          },
        );
      }
    } catch (e) {
      print('TUS Upload failed: $e');
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _uploadProgress = 0.0;
          _photoUrl = null;
        });

        // Handle specific errors
        String errorMessage = 'Failed to upload photo';
        if (e.toString().contains('412')) {
          errorMessage = 'Upload rejected by server (412). Check file size or server configuration.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Upload server not found (404). Check TUS server is running.';
        } else if (e.toString().contains('401') || e.toString().contains('403')) {
          errorMessage = 'Upload not authorized. Check authentication.';
        }

        _showSnackBar(errorMessage, isError: true);
      }
    }
  }

  // MARK: - Form Submission
  Future<void> _submitReceive() async {
    if (!_validateForm()) return;

    setState(() {
      _screenState = ScreenState.submitting;
    });

    try {
      final payload = _buildSubmissionPayload();
      print('Submitting payload: ${payload.toString()}');

      final response = await _apiService.submitReceiveVehicle(payload);

      if (response.success) {
        print('Form submission successful');
        _showSnackBar(response.message);
        Navigator.pop(context);
      } else {
        print('Form submission failed: ${response.error ?? response.message}');
        _showSnackBar(response.error ?? response.message, isError: true);
      }
    } catch (e) {
      print('Form submission exception: $e');
      _showSnackBar('Failed to submit: $e', isError: true);
    } finally {
      setState(() {
        _screenState = ScreenState.loaded;
      });
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedWarehouse == null) {
      _showSnackBar('Please select a warehouse', isError: true);
      return false;
    }

    if (_needsNewDriver) {
      switch (_driverState) {
        case DriverSelectionState.needsSelection:
          _showSnackBar('Please search for a driver or create new', isError: true);
          return false;
        case DriverSelectionState.creatingNew:
          if (_driverNameController.text.trim().isEmpty) {
            _showSnackBar('Please enter driver name', isError: true);
            return false;
          }
          if (_isUploadingPhoto) {
            _showSnackBar('Please wait for photo upload to complete', isError: true);
            return false;
          }
          if (_photoUrl == null) {
            _showSnackBar('Please capture driver photo', isError: true);
            return false;
          }
          break;
        case DriverSelectionState.driverSelected:
          if (_selectedDriver == null) {
            _showSnackBar('Please select a driver', isError: true);
            return false;
          }
          break;
        default:
          break;
      }
    }

    return true;
  }

  Map<String, dynamic> _buildSubmissionPayload() {
    final payload = <String, dynamic>{
      'supplier_gstin': widget.supplierGstin,
      'supplier_invoice_date': widget.supplierInvoiceDate,
      'supplier_invoice_number': widget.supplierInvoiceNumber,
      'seed_code': _seedCodeController.text.trim(),
      'warehouse_id': _selectedWarehouse!['id'],
    };

    if (!_needsNewDriver) {
      payload['driver_id'] = _existingDriverId!;
    } else if (_selectedDriver != null) {
      payload['driver_id'] = _selectedDriver!['id'];
    } else {
      payload.addAll({
        'driver_name': _driverNameController.text.trim(),
        'driver_phone': _driverPhoneController.text.trim(),
        'driver_photo': _photoUrl!, // TUS upload URL
      });
    }

    return payload;
  }

  // MARK: - UI Helpers
  void _showSnackBar(String message, {bool isError = false}) {
    if (isError) {
      context.showErrorSnackBar(message);
    } else {
      context.showSuccessSnackBar(message);
    }
  }

  // MARK: - Widget Builders
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        'Receive Vehicle',
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
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case ScreenState.loading:
        return _buildLoadingState();
      case ScreenState.error:
        return _buildErrorState();
      case ScreenState.loaded:
      case ScreenState.submitting:
        return _buildLoadedState();
    }
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF0E5CA8)),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
              'Error loading data',
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
              onPressed: _loadInitialData,
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

  Widget _buildLoadedState() {
    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildInvoiceInfo(),
                  _buildSeedCodeInput(),
                  SizedBox(height: 10.h),
                  _buildWarehouseSelection(),
                  if (_needsNewDriver) _buildDriverSection(),
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ),
        ),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildInvoiceInfo() {
    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoice: ${_invoiceDetails['erp_data']?['bill_no'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666)),
                  ),
                ),
                Text(
                  'Vehicle: ${_invoiceDetails['erp_data']?['vehicle_no'] ?? 'N/A'}',
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeedCodeInput() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seed Code',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            TextFormField(
              controller: _seedCodeController,
              decoration: InputDecoration(
                labelText: 'Enter Seed Code *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter seed code';
                }
                return null;
              },
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarehouseSelection() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Warehouse Selection',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            GestureDetector(
              onTap: () => _showWarehouseDialog(),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedWarehouse?['warehouse_label'] ?? 'Select Warehouse *',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: _selectedWarehouse == null
                            ? const Color(0xFF999999)
                            : const Color(0xFF333333),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down, color: Color(0xFF666666)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWarehouseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Warehouse'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _warehouses.map((warehouse) => ListTile(
              title: Text(warehouse['warehouse_label'] ?? 'Unknown'),
              subtitle: Text(warehouse['name'] ?? ''),
              onTap: () {
                setState(() {
                  _selectedWarehouse = warehouse;
                });
                Navigator.pop(context);
              },
            )).toList(),
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

  Widget _buildDriverSection() {
    return Card(
      margin: EdgeInsets.all(16.w),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Information',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 12.h),
            _buildDriverContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverContent() {
    switch (_driverState) {
      case DriverSelectionState.needsSelection:
        return _buildDriverSearch();
      case DriverSelectionState.searchingDrivers:
        return _buildSearchingState();
      case DriverSelectionState.driversFound:
        return _buildDriverFoundState();
      case DriverSelectionState.creatingNew:
        return _buildCreateDriverForm();
      case DriverSelectionState.driverSelected:
        return _buildSelectedDriverInfo();
    }
  }

  Widget _buildDriverSearch() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
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
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E5CA8).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_search,
                  color: const Color(0xFF0E5CA8),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Driver Search',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Phone input field
          TextFormField(
            controller: _driverPhoneController,
            decoration: InputDecoration(
              labelText: 'Driver Phone Number',
              prefixIcon: Icon(
                Icons.phone,
                color: const Color(0xFF0E5CA8),
                size: 20.sp,
              ),
              suffixIcon: Container(
                margin: EdgeInsets.all(4.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: const BorderSide(color: Color(0xFF0E5CA8), width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter phone number';
              }
              if (value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
          SizedBox(height: 16.h),

          // Action buttons
          Row(
            children: [
              // Expanded(
              //   child: OutlinedButton.icon(
              //     onPressed: () {
              //       setState(() {
              //         _driverState = DriverSelectionState.creatingNew;
              //       });
              //     },
              //     icon: Icon(
              //       Icons.person_add,
              //       size: 18.sp,
              //       color: const Color(0xFF0E5CA8),
              //     ),
              //     label: Text(
              //       'Create New Driver',
              //       style: TextStyle(
              //         fontSize: 12.sp,
              //         fontWeight: FontWeight.w500,
              //       ),
              //     ),
              //     style: OutlinedButton.styleFrom(
              //       foregroundColor: const Color(0xFF0E5CA8),
              //       side: const BorderSide(color: Color(0xFF0E5CA8)),
              //       padding: EdgeInsets.symmetric(vertical: 14.h),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(10.r),
              //       ),
              //     ),
              //   ),
              // ),
              // SizedBox(width: 5.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _searchDrivers,
                  icon: Icon(
                    Icons.search,
                    size: 18.sp,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Search Driver',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingState() {
    return Column(
      children: [
        _buildDriverSearch(),
        SizedBox(height: 16.h),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0E5CA8)),
            SizedBox(width: 12),
            Text('Searching drivers...'),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverFoundState() {
    return Column(
      children: [
        _buildDriverSearch(),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E8),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${_searchedDrivers.length} driver(s) found. Please select one.',
                  style: TextStyle(fontSize: 14.sp, color: const Color(0xFF2E7D32)),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _driverState = DriverSelectionState.creatingNew;
                  });
                },
                child: const Text('Create New'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDriverInfo() {
    return Column(
      children: [
        _buildDriverSearch(),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF0E5CA8)),
              SizedBox(width: 8.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected: ${_selectedDriver!['name']}',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                    Text(
                      'Phone: ${_selectedDriver!['phone_number']} | Visits: ${_selectedDriver!['visit_count']}',
                      style: TextStyle(fontSize: 12.sp, color: const Color(0xFF666666)),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDriver = null;
                    _driverState = DriverSelectionState.driversFound;
                  });
                },
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateDriverForm() {
    return Column(
      children: [
        _buildDriverSearch(),
        SizedBox(height: 16.h),
        const Divider(),
        SizedBox(height: 12.h),
        Text(
          'Create New Driver:',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12.h),
        TextFormField(
          controller: _driverNameController,
          decoration: InputDecoration(
            labelText: 'Driver Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
          ),
          validator: (value) {
            if (_driverState == DriverSelectionState.creatingNew &&
                (value == null || value.trim().isEmpty)) {
              return 'Please enter driver name';
            }
            return null;
          },
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isUploadingPhoto
                        ? 'Uploading photo...'
                        : _photoUrl != null
                        ? 'Photo uploaded ✓'
                        : 'Capture Driver Photo *',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: _isUploadingPhoto
                          ? const Color(0xFF0E5CA8)
                          : _photoUrl != null
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF666666),
                    ),
                  ),
                  if (_isUploadingPhoto) ...[
                    SizedBox(height: 8.h),
                    Container(
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.r),
                        child: LinearProgressIndicator(
                          value: _uploadProgress / 100,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0E5CA8)),
                        ),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '${_uploadProgress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 12.w),
            ElevatedButton.icon(
              onPressed: _isUploadingPhoto ? null : _capturePhoto,
              icon: _isUploadingPhoto
                  ? SizedBox(
                width: 16.w,
                height: 16.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.camera_alt),
              label: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                    _isUploadingPhoto
                        ? 'Uploading...'
                        : _photoUrl != null
                        ? 'Retake'
                        : 'Capture'
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isSubmitting = _screenState == ScreenState.submitting;
    final canSubmit = _selectedWarehouse != null && !isSubmitting && !_isUploadingPhoto;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16.w),
      child: ElevatedButton(
        onPressed: canSubmit ? _submitReceive : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          elevation: 2,
        ),
        child: isSubmitting
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
              'Submitting...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : _isUploadingPhoto
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
              'Uploading Photo...',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        )
            : Text(
          'Receive Vehicle',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// MARK: - Driver Selection Dialog
class DriverSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> drivers;
  final Function(Map<String, dynamic>) onDriverSelected;
  final VoidCallback onCreateNew;
  final Function(int) onDriverDetails;

  const DriverSelectionDialog({
    Key? key,
    required this.drivers,
    required this.onDriverSelected,
    required this.onCreateNew,
    required this.onDriverDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Driver'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: drivers.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final driver = drivers[index];
            return ListTile(
              title: Text(
                driver['name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Phone: ${driver['phone_number'] ?? 'N/A'} | Visits: ${driver['visit_count'] ?? 0}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                onPressed: () => onDriverDetails(driver['id']),
                icon: const Icon(Icons.info_outline, color: Color(0xFF0E5CA8)),
                tooltip: 'View Details',
              ),
              onTap: () {
                Navigator.pop(context);
                onDriverSelected(driver);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onCreateNew();
          },
          child: const Text('Create New Driver'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// MARK: - Driver Details Dialog
class DriverDetailsDialog extends StatelessWidget {
  final int driverId;
  final ApiServiceInterface apiService;

  const DriverDetailsDialog({
    Key? key,
    required this.driverId,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: FutureBuilder<Map<String, dynamic>>(
        future: apiService.getDriverDetails(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingContent();
          }

          if (snapshot.hasError) {
            return _buildErrorContent(context, snapshot.error.toString());
          }

          return _buildDriverContent(context, snapshot.data!);
        },
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFF0E5CA8)),
          SizedBox(height: 16.h),
          Text(
            'Loading driver details...',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF666666)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, String error) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48.w, color: const Color(0xFFF44336)),
          SizedBox(height: 16.h),
          Text(
            'Failed to load driver details',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF666666)),
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverContent(BuildContext context, Map<String, dynamic> driver) {
    return Container(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Driver Details',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Driver Photo
          if (driver['photo'] != null && driver['photo'].toString().isNotEmpty)
            Center(
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0E5CA8), width: 2),
                ),
                child: ClipOval(
                  child: Image.network(
                    driver['photo'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 60,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
              ),
            ),

          SizedBox(height: 20.h),

          // Driver Information
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Column(
              children: [
                _buildDetailRow('Name:', driver['name'] ?? 'N/A'),
                _buildDetailRow('Phone:', driver['phone_number'] ?? 'N/A'),
                _buildDetailRow('Visit Count:', driver['visit_count']?.toString() ?? '0'),
                _buildDetailRow(
                  'Last Seen:',
                  driver['last_seen_date'] != null
                      ? DateFormat('dd-MMM-yyyy HH:mm').format(
                      DateTime.parse(driver['last_seen_date']))
                      : 'N/A',
                ),
              ],
            ),
          ),

          SizedBox(height: 20.h),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                'Close',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF333333),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}