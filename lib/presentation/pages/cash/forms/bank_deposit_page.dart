import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import 'package:tus_client_dart/tus_client_dart.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/currency_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/professional_snackbar.dart';

class BankDepositScreen extends StatefulWidget {
  const BankDepositScreen({Key? key}) : super(key: key);

  @override
  State<BankDepositScreen> createState() => _BankDepositScreenState();
}

class _BankDepositScreenState extends State<BankDepositScreen> {
  late final ApiServiceInterface apiService;
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptNoController = TextEditingController();

  String? _selectedBank;
  DateTime _selectedDate = DateTime.now();

  XFile? _receiptImage;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();

  // TUS upload state
  TusClient? _tusClient;
  bool _isUploadingPhoto = false;
  double _uploadProgress = 0.0;

  // Store full bank objects instead of just names
  List<Map<String, dynamic>> _bankObjects = [];
  List<String> _banks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();

    _amountController.addListener(() {
      setState(() {});
    });

    _fetchBankList();
  }

  Future<void> _fetchBankList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final bankResponse = await apiService.getBankAccount();
      _bankObjects = List<Map<String, dynamic>>.from(bankResponse);
      final bankList = _bankObjects
          .map<String>((item) => item['account_label'] as String)
          .toList();

      setState(() {
        _isLoading = false;
        _banks = bankList;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar('Error fetching banks: $e');
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0E5CA8),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _receiptImage = photo;
          _uploadedImageUrl = null; // Reset uploaded URL when new image captured
        });
      }
    } catch (e) {
      context.showErrorSnackBar('Error taking photo: $e');
    }
  }

  Future<void> _uploadImageViaTus() async {
    if (_receiptImage == null) {
      context.showInfoSnackBar('No image to upload');
      return;
    }

    try {
      setState(() {
        _isUploadingPhoto = true;
        _uploadProgress = 0.0;
      });

      _tusClient = TusClient(_receiptImage!);

      await _tusClient!.upload(
        uri: Uri.parse('http://arungas.com:1080/files/'),
        onComplete: () {
          if (mounted) {
            setState(() {
              _uploadedImageUrl = _tusClient!.uploadUrl.toString();
              _isUploadingPhoto = false;
              _uploadProgress = 100.0;
            });
            context.showSuccessSnackBar('Receipt uploaded successfully');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _uploadProgress = 0.0;
        });

        String errorMessage = 'Failed to upload receipt';
        if (e.toString().contains('412')) {
          errorMessage = 'Upload precondition failed. Please try again.';
        } else if (e.toString().contains('NetworkException')) {
          errorMessage = 'Network error. Check your connection.';
        }

        context.showErrorSnackBar(errorMessage);
      }
    }
  }

  void _viewImageFullscreen() {
    if (_receiptImage == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenImageViewer(
          imageFile: _receiptImage!,
          imageUrl: _uploadedImageUrl,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _receiptNoController.dispose();
    _tusClient = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: const Text('Bank Deposit'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Selection Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 1,
                child: InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0E5CA8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(
                            Icons.calendar_today,
                            color: const Color(0xFF0E5CA8),
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deposit Date',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                DateFormat('dd MMM yyyy').format(_selectedDate),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF333333),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Main Form Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bank Selection
                      Text(
                        'Select Bank',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      DropdownButtonFormField<String>(
                        value: _selectedBank,
                        hint: const Text('Select Bank'),
                        items: _banks.map((bank) {
                          return DropdownMenuItem<String>(
                            value: bank,
                            child: Text(bank),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBank = value;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a bank';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      if (_amountController.text.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Center(
                          child: Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: Colors.yellow!,
                              ),
                            ),
                            child: Text(
                              amountToWords(int.tryParse(_amountController.text.replaceAll(',', '')) ?? 0), // Remove underscore
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: Colors.yellow,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: 8.h),
                      // Amount
                      Text(
                        'Amount (₹)',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IndianCurrencyInputFormatter(),
                        ],
                        style: TextStyle(
                          fontSize: 25.sp,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          prefixText: '₹ ',
                          suffixText: 'INR',
                        ),
                        onTap: () {
                          _amountController.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _amountController.text.length,
                          );
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Receipt Number
                      Text(
                        'Receipt/Reference Number',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _receiptNoController,
                        decoration: InputDecoration(
                          hintText: 'Enter receipt or reference number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Receipt Photo Section
                      Text(
                        'Receipt Photo',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Image Preview/Capture Area
                      GestureDetector(
                        onTap: _receiptImage == null
                            ? _pickImageFromCamera
                            : _viewImageFullscreen,
                        child: Container(
                          width: double.infinity,
                          height: 200.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                            color: Colors.grey[50],
                          ),
                          child: _receiptImage != null
                              ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10.r),
                                child: Image.file(
                                  File(_receiptImage!.path),
                                  width: double.infinity,
                                  height: 200.h,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // Upload Status Overlay
                              if (_uploadedImageUrl != null)
                                Positioned(
                                  top: 8.h,
                                  left: 8.w,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 6.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16.sp,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Uploaded',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              // Remove Button
                              Positioned(
                                top: 8.h,
                                right: 8.w,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _receiptImage = null;
                                      _uploadedImageUrl = null;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 18.sp,
                                    ),
                                  ),
                                ),
                              ),
                              // Tap to view hint
                              Positioned(
                                bottom: 8.h,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 6.h,
                                  ),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    'Tap to view fullscreen',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(20.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0E5CA8).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 48.sp,
                                  color: const Color(0xFF0E5CA8),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'Tap to capture receipt',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF0E5CA8),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Camera will open',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Upload Button (shown only when image captured but not uploaded)
                      if (_receiptImage != null && _uploadedImageUrl == null)
                        Padding(
                          padding: EdgeInsets.only(top: 12.h),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingPhoto ? null : _uploadImageViaTus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF7941D),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                              icon: _isUploadingPhoto
                                  ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                                  : Icon(
                                Icons.cloud_upload,
                                size: 20.sp,
                                color: Colors.white,
                              ),
                              label: Text(
                                _isUploadingPhoto
                                    ? 'Uploading...'
                                    : 'Upload Receipt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      SizedBox(height: 16.h),

                      // Remarks
                      Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter any remarks or notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitBankDeposit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E5CA8),
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'SUBMIT BANK DEPOSIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int? _getBankId(String bankName) {
    try {
      final bank = _bankObjects.firstWhere(
            (item) => item['account_label'] == bankName,
      );
      return bank['id'] as int;
    } catch (e) {
      return null;
    }
  }

  void _submitBankDeposit() async {
    if (_formKey.currentState!.validate()) {
      if (_receiptImage == null) {
        context.showWarningSnackBar('Please capture a receipt photo');
        return;
      }

      if (_uploadedImageUrl == null) {
        context.showWarningSnackBar('Please upload the receipt before submitting');
        return;
      }

      if (_selectedBank == null || _selectedBank!.isEmpty) {
        context.showWarningSnackBar('Please select a bank');
        return;
      }

      final bankId = _getBankId(_selectedBank!);

      if (bankId == null) {
        context.showWarningSnackBar('Invalid bank selected');
        return;
      }

      final amount = NumberFormat.decimalPattern('en_IN').parse(_amountController.text).toDouble();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final transaction = CashTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.bank,
        status: TransactionStatus.pending,
        amount: amount,
        createdAt: _selectedDate,
        initiator: 'D',
        selectedBank: bankId.toString(),
        bankReferenceNo: _receiptNoController.text,
        receiptImagePath: _uploadedImageUrl, // Use TUS uploaded URL
        createdBy: 'Current User',
        notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        fromAccount: bankId.toString(),
      );

      final completer = Completer<void>();
      context.read<CashManagementBloc>().add(
          AddTransaction(transaction, completer: completer));

      try {
        await completer.future;

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        context.showSuccessSnackBar('Bank deposit submitted successfully');

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        context.showErrorSnackBar('Error submitting bank deposit: $e');
      }
    }
  }
}

// Fullscreen Image Viewer Widget
class FullscreenImageViewer extends StatelessWidget {
  final XFile imageFile;
  final String? imageUrl;

  const FullscreenImageViewer({
    Key? key,
    required this.imageFile,
    this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          imageUrl != null ? 'Receipt (Uploaded)' : 'Receipt Preview',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.file(
            File(imageFile.path),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}