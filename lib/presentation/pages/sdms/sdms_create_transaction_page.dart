// lib/presentation/pages/sdms/sdms_create_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/presentation/pages/sdms/qr_scanner_page.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/User.dart';
import '../../../utils/error_handler.dart';
import '../../blocs/sdms/create/sdms_create_bloc.dart';
import '../../blocs/sdms/create/sdms_create_event.dart';
import '../../blocs/sdms/create/sdms_create_state.dart';
import '../../widgets/sdms/sdms_error_dialog.dart';
import '../../widgets/professional_snackbar.dart';

class SDMSCreateTransactionPage extends StatefulWidget {
  const SDMSCreateTransactionPage({Key? key}) : super(key: key);

  @override
  State<SDMSCreateTransactionPage> createState() => _SDMSCreateTransactionPageState();
}

class _SDMSCreateTransactionPageState extends State<SDMSCreateTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final User _userService = User();
  bool _isInvoiceAssign = false; // true for invoice assign, false for credit payment
  String? _sdmsUserCode;
  bool _hasValidSdmsCode = false;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Add this
  }

  // Add this method to load SDMS user code
  Future<void> _loadUserData() async {
    final sdmsUserCode = await _userService.getActiveCompanySdmsUserCode();
    if (mounted) {
      setState(() {
        _sdmsUserCode = sdmsUserCode;
        _hasValidSdmsCode = sdmsUserCode != null && sdmsUserCode.isNotEmpty;
        // _isInvoiceAssign = _hasValidSdmsCode;
      });
    }
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create SDMS Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF0E5CA8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: BlocConsumer<SDMSCreateBloc, SDMSCreateState>(
        listener: (context, state) {
          if (state is SDMSCreateDetailedError) {
            showDialog(
              context: context,
              builder: (context) => SDMSErrorDialog(errorResponse: state.errorResponse),
            );
          } else if (state is SDMSCreateSuccess) {
            _showSuccessDialog(state.response.transactionId, state.response.status);
          } else if (state is SDMSCreateError) {
            ErrorHandler.showErrorSnackBar(context, state.message);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add SDMS User Code display
                  _buildSdmsUserCodeCard(),
                  SizedBox(height: 16.h),
                  _buildTransactionTypeCard(),
                  SizedBox(height: 20.h),
                  _buildOrderDetailsCard(),
                  SizedBox(height: 24.h),
                  _buildSubmitButton(state),
                ],
              ),
            ),
          );
        },
      ),

    );
  }

  // Add this new method to build the SDMS user code card
  Widget _buildSdmsUserCodeCard() {
    // Only show this card if we have a valid SDMS code
    if (!_hasValidSdmsCode) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.orange[300]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange[700],
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No SDMS User Code',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[900],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Only Credit Payment transactions are available',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Your existing SDMS card code for when we have a valid code
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0E5CA8),
            const Color(0xFF0E5CA8).withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5CA8).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SDMS User Code',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _sdmsUserCode ?? '',
                  style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  color: Colors.green[200],
                  size: 12.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.green[200],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the transaction type card
  Widget _buildTransactionTypeCard() {
    // If no valid SDMS code, only show Credit Payment (no toggle)
    if (!_hasValidSdmsCode) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction Type',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E5CA8),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payment,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Credit Payment',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E5CA8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFF0E5CA8).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: const Color(0xFF0E5CA8),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Creates a credit payment transaction for the specified order',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF0E5CA8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              'Transaction Type',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isInvoiceAssign = false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: !_isInvoiceAssign
                              ? const Color(0xFF0E5CA8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.payment,
                              size: 18.sp,
                              color: !_isInvoiceAssign ? Colors.white : Colors.grey[600],
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Credit Payment',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: !_isInvoiceAssign ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isInvoiceAssign = true),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: _isInvoiceAssign
                              ? const Color(0xFF0E5CA8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 18.sp,
                              color: _isInvoiceAssign ? Colors.white : Colors.grey[600],
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Invoice & Assign',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: _isInvoiceAssign ? Colors.white : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0E5CA8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: const Color(0xFF0E5CA8).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16.sp,
                    color: const Color(0xFF0E5CA8),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isInvoiceAssign
                          ? 'Creates an invoice and assigns it to the specified order'
                          : 'Creates a credit payment transaction for the specified order',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0E5CA8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _orderIdController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Sales Order ID *',
                      hintText: 'Enter sales order ID',
                      prefixIcon: const Icon(Icons.receipt),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF0E5CA8),
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                    onTap: () {
                      _orderIdController.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _orderIdController.text.length,
                      );
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Sales Order ID is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Sales Order ID must be at least 3 characters';
                      }
                      return null;
                    },
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleSubmit(),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  height: 56.h,
                  width: 56.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E5CA8),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: IconButton(
                    onPressed: _openQRScanner,
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    tooltip: 'Scan QR Code',
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'Enter the sales order ID manually or scan QR code',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQRScanner() async {
    // Check camera permission
    final permission = await Permission.camera.request();
    if (permission != PermissionStatus.granted) {
      if (mounted) {
        context.showErrorSnackBar('Camera permission is required to scan QR codes');
      }
      return;
    }

    // Navigate to QR scanner
    if (mounted) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => const QRScannerPage(),
        ),
      );

      if (result != null && result.isNotEmpty) {
        _orderIdController.text = result;
        setState(() {});
      }
    }
  }

  Widget _buildSubmitButton(SDMSCreateState state) {
    final isLoading = state is SDMSCreateLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E5CA8),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        child: isLoading
            ? SizedBox(
          height: 20.h,
          width: 20.w,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isInvoiceAssign ? Icons.receipt_long : Icons.payment,
              size: 20.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              _isInvoiceAssign ? 'Create Invoice & Assign' : 'Create Credit Payment',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final orderId = _orderIdController.text.trim();

    if (_isInvoiceAssign) {
      context.read<SDMSCreateBloc>().add(
        CreateInvoiceAssignEvent(orderId: orderId),
      );
    } else {
      context.read<SDMSCreateBloc>().add(
        CreateCreditPaymentEvent(orderId: orderId),
      );
    }
  }

  void _showSuccessDialog(String transactionId, String status) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green[600],
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              const Text('Success'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaction created successfully!',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16.h),
              _buildSuccessInfoRow('Transaction ID', transactionId),
              _buildSuccessInfoRow('Status', status),
              _buildSuccessInfoRow(
                'Type',
                _isInvoiceAssign ? 'Invoice & Assign' : 'Credit Payment',
              ),
              _buildSuccessInfoRow('Order ID', _orderIdController.text.trim()),
              SizedBox(height: 16.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: Colors.green[700],
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'You can track the progress of this transaction in the transaction list.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              child: const Text('Create Another'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E5CA8),
                foregroundColor: Colors.white,
              ),
              child:  Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Back to List'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSuccessInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90.w,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _orderIdController.clear();
    // setState(() {
    //   _isInvoiceAssign = true;
    // });
    context.read<SDMSCreateBloc>().add(ResetCreateStateEvent());
  }
}