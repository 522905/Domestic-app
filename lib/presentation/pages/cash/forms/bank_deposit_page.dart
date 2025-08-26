import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../blocs/cash/cash_bloc.dart';

class BankDepositPage extends StatefulWidget {
  const BankDepositPage({Key? key}) : super(key: key);

  @override
  State<BankDepositPage> createState() => _BankDepositPageState();
}

class _BankDepositPageState extends State<BankDepositPage> {
  late final ApiServiceInterface apiService;
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();
  final _receiptNoController = TextEditingController();

  String? _selectedBank;

  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  // Store full bank objects instead of just names
  List<Map<String, dynamic>> _bankObjects = [];
  List<String> _banks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _fetchBankList(); // Changed method name for clarity
  }

  Future<void> _fetchBankList() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch bank list - store full objects
      final bankResponse = await apiService.getBankAccount();
      _bankObjects = List<Map<String, dynamic>>.from(bankResponse);
      final bankList = _bankObjects
          .map<String>((item) => item['account_name'] as String)
          .toList();

      setState(() {
        _isLoading = false;
        _banks = bankList;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching banks: $e')),
      );
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
          _receiptImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _receiptImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Receipt Photo',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.h),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Theme.of(context).primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    _receiptNoController.dispose();
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a bank';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
                      // Receipt Number
                      Text(
                        'Receipt Number',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _receiptNoController,
                        decoration: InputDecoration(
                          hintText: 'Enter receipt number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter receipt number';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          suffixText: 'INR',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter a valid amount';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),

                      // Receipt Photo
                      Text(
                        'Receipt Photo',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: double.infinity,
                          height: 120.h,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: _receiptImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Stack(
                              children: [
                                Image.file(
                                  _receiptImage!,
                                  width: double.infinity,
                                  height: 120.h,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8.h,
                                  right: 8.w,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _receiptImage = null;
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 32.sp,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Tap to add receipt photo',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Remarks
                      Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      TextFormField(
                        controller: _remarksController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Enter any remarks or notes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'SUBMIT BANK DEPOSIT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
      ),
    );
  }

  int? _getBankId(String bankName) {
    try {
      final bank = _bankObjects.firstWhere(
            (item) => item['account_name'] == bankName,
      );
      return bank['id'] as int;
    } catch (e) {
      return null;
    }
  }

  void _submitBankDeposit() async {
    if (_formKey.currentState!.validate()) {
      if (_receiptImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add a receipt photo')),
        );
        return;
      }

      if (_selectedBank == null || _selectedBank!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a bank')),
        );
        return;
      }

      // Get bank ID from selected bank name
      final bankId = _getBankId(_selectedBank!);

      if (bankId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid bank selected')),
        );
        return;
      }

      final amount = double.parse(_amountController.text);

      final transaction = CashTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.bank,
        status: TransactionStatus.pending,
        amount: amount,
        createdAt: DateTime.now(),
        initiator: 'D',
        selectedBank: bankId.toString(), // Send bank ID as string
        bankReferenceNo: _receiptNoController.text,
        receiptImagePath: _receiptImage?.path,
        createdBy: 'Current User',
        notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        fromAccount: "", // You can set this based on your business logic
      );

      final completer = Completer<void>();
      context.read<CashManagementBloc>().add(
          AddTransaction(transaction, completer: completer)
      );

      try {
        await completer.future;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bank deposit submitted successfully')),
        );
        Navigator.of(context).pop(true); // Return success indicator
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting bank deposit: $e')),
        );
      }
    }
  }

}