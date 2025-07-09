import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
class HandoverScreen extends StatefulWidget {
  const HandoverScreen({Key? key}) : super(key: key);

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  late final ApiServiceInterface apiService;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  bool _isReceiverManager = true;
  String? _selectedManager;
  String? _selectedBank;
  String?  _selectedAccount ;

  final List<String> _banks = [];

  final ImagePicker _picker = ImagePicker();
  File? _receiptImage;
  String? _receiptFileName;

  final List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;


  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>(); // Initialize apiService
    _fetchAccounts();
    _fetchBankList();// Fetch accounts when the page loads
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  //   void _showFileUploadDialog() {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => Container(
  //       padding: EdgeInsets.all(24.w),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Row(
  //             children: [
  //               Icon(Icons.upload_file, color: Theme.of(context).primaryColor),
  //               SizedBox(width: 12.w),
  //               Text(
  //                 'Upload Receipt',
  //                 style: TextStyle(
  //                   fontSize: 18.sp,
  //                   fontWeight: FontWeight.w500,
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 16.h),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceAround,
  //             children: [
  //               Column(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 28.r,
  //                     backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
  //                     child: IconButton(
  //                       icon: Icon(Icons.camera_alt, color: Theme.of(context).primaryColor),
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         _takePicture();
  //                       },
  //                     ),
  //                   ),
  //                   SizedBox(height: 8.h),
  //                   Text('Camera', style: TextStyle(fontSize: 14.sp)),
  //                 ],
  //               ),
  //               Column(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 28.r,
  //                     backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
  //                     child: IconButton(
  //                       icon: Icon(Icons.image, color: Theme.of(context).primaryColor),
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         _pickImage();
  //                       },
  //                     ),
  //                   ),
  //                   SizedBox(height: 8.h),
  //                   Text('Gallery', style: TextStyle(fontSize: 14.sp)),
  //                 ],
  //               ),
  //               Column(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 28.r,
  //                     backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
  //                     child: IconButton(
  //                       icon: Icon(Icons.file_copy, color: Theme.of(context).primaryColor),
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                         _pickFile();
  //                       },
  //                     ),
  //                   ),
  //                   SizedBox(height: 8.h),
  //                   Text('Files', style: TextStyle(fontSize: 14.sp)),
  //                 ],
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Future<void> _fetchAccounts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await apiService.getAccountsList();
      if (response['success'] == true) {
        final accounts = response['accounts'];
        if (accounts is List) { // Ensure accounts is a list
          setState(() {
            _accounts.clear();
            _accounts.addAll(
              accounts.map((account) =>
              {
                'value': account['username'] ?? 'Unknown Account',
                'type': account['account_type'] ?? 'Unknown Type',
              },
              ).toList(),
            );
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid accounts format');
        }
      } else {
        throw Exception('Failed to fetch accounts');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching accounts: $e')),
      );
    }
  }

    Future<List<String>> _fetchBankList() async {
      try {
        final response = await apiService.getBankList(); // Call the API
        if (response.containsKey('banks')) { // Check if 'banks' key exists
          final bank_data = response['banks'];
          if (bank_data is List) { // Ensure bank_data is a list
            setState(() {
              _banks.clear();
              _banks.addAll(bank_data.map((bank) => bank.toString()).toList()); // Convert to List<String>
            });
            return _banks; // Return the updated list
          } else {
            throw Exception('Invalid banks format');
          }
        } else {
          throw Exception('Banks key not found in response');
        }
      } catch (e) {
        debugPrint('Error fetching bank list: $e');
        return []; // Return an empty list in case of error
      }
    }
  //
  // Future<void> _takePicture() async {
  //   try {
  //     final XFile? photo = await _picker.pickImage(
  //       source: ImageSource.camera,
  //       imageQuality: 80,
  //       maxWidth: 1200,
  //     );
  //
  //     if (photo != null) {
  //       final directory = await getApplicationDocumentsDirectory();
  //       final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //       final savedImage = File(path.join(directory.path, fileName));
  //
  //       await savedImage.writeAsBytes(await photo.readAsBytes());
  //
  //       setState(() {
  //         _receiptImage = savedImage;
  //         _receiptFileName = fileName;
  //       });
  //
  //       _showUploadSuccessMessage();
  //     }
  //   } catch (e) {
  //     debugPrint('Error taking picture: $e');
  //     _showErrorMessage('Failed to capture image');
  //   }
  // }
  //
  // Future<void> _pickImage() async {
  //   try {
  //     final XFile? image = await _picker.pickImage(
  //       source: ImageSource.gallery,
  //       imageQuality: 80,
  //       maxWidth: 1200,
  //     );
  //
  //     if (image != null) {
  //       final directory = await getApplicationDocumentsDirectory();
  //       final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
  //       final savedImage = File(path.join(directory.path, fileName));
  //
  //       await savedImage.writeAsBytes(await image.readAsBytes());
  //
  //       setState(() {
  //         _receiptImage = savedImage;
  //         _receiptFileName = path.basename(image.path);
  //       });
  //
  //       _showUploadSuccessMessage();
  //     }
  //   } catch (e) {
  //     debugPrint('Error picking image: $e');
  //     _showErrorMessage('Failed to select image');
  //   }
  // }
  //
  // Future<void> _pickFile() async {
  //   try {
  //     FilePickerResult? result = await FilePicker.platform.pickFiles(
  //       type: FileType.image,
  //       allowMultiple: false,
  //     );
  //
  //     if (result != null && result.files.single.path != null) {
  //       final file = File(result.files.single.path!);
  //       final directory = await getApplicationDocumentsDirectory();
  //       final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
  //       final savedFile = File(path.join(directory.path, fileName));
  //
  //       await savedFile.writeAsBytes(await file.readAsBytes());
  //
  //       setState(() {
  //         _receiptImage = savedFile;
  //         _receiptFileName = result.files.single.name;
  //       });
  //
  //       _showUploadSuccessMessage();
  //     }
  //   } catch (e) {
  //     debugPrint('Error picking file: $e');
  //     _showErrorMessage('Failed to select file');
  //   }
  // }

  // void _showUploadSuccessMessage() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Receipt uploaded successfully'),
  //       backgroundColor: Colors.green,
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }
  //
  // void _showErrorMessage(String message) {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(message),
  //       backgroundColor: Colors.red,
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }
  //
  // void _viewFullImage() {
  //   if (_receiptImage == null) return;
  //
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => Scaffold(
  //         appBar: AppBar(
  //           backgroundColor: const Color(0xFF0E5CA8),
  //           title: Text(_receiptFileName ?? 'Receipt Preview'),
  //         ),
  //         body: PhotoView(
  //           imageProvider: FileImage(_receiptImage!),
  //           minScale: PhotoViewComputedScale.contained,
  //           maxScale: PhotoViewComputedScale.covered * 2,
  //           backgroundDecoration: BoxDecoration(
  //             color: Colors.black,
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
  //
  // String _getCashAvailableFormatted(BuildContext context) {
  //   // Get the cash available from the bloc
  //   final state = context.read<CashManagementBloc>().state;
  //   if (state is CashManagementLoaded) {
  //     final currencyFormat = NumberFormat.currency(
  //       symbol: '₹',
  //       decimalDigits: 0,
  //       locale: 'en_IN',
  //     );
  //     return currencyFormat.format(state.cashData.cashInHand);
  //   }
  //   return '₹0';
  // }
  //
  // String _getLastUpdatedFormatted(BuildContext context) {
  //   // Get the last updated timestamp from the bloc
  //   final state = context.read<CashManagementBloc>().state;
  //   if (state is CashManagementLoaded) {
  //     return 'Last updated: Today, ${DateFormat('h:mm a').format(state.cashData.lastUpdated)}';
  //   }
  //   return 'Last updated: N/A';
  // }

  void _submitHandover() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (!_isReceiverManager && _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank')),
      );
      return;
    }

    if (_selectedAccount == null || _selectedAccount!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    // if (_receiptImage == null) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please upload a receipt image')),
    //   );
    //   return;
    // }

    // try {
    //
    //   final bloc = context.read<CashManagementBloc>();
    //   final apiService = bloc.apiService;
    //
    //   // Step 1: Upload receipt
    //   // String? documentId;
    //   // if (_receiptImage != null) {
    //   //   documentId = await apiService.uploadDocument(
    //   //     _receiptImage!,
    //   //     'handover_receipt',
    //   //     null,
    //   //   );
    //   // }
    //
    //   // Step 2: Prepare transaction data
    //
    //   final transactionPayload = {
    //     'type': 'handover',
    //     'account_type': 'svTv',
    //     'amount': amount,
    //     'notes': _remarksController.text,
    //     if (_isReceiverManager) 'recipient': _selectedManager,
    //     if (!_isReceiverManager) 'bank_details': _selectedBank,
    //     // if (documentId != null) 'receipt_image_id': documentId,
    //   };
    //
    //   // Step 3: Send to API
    //   final response = await apiService.submitHandover(transactionPayload);
    //
    //   // Step 4: Add to BLoC for UI update
    //   final createdTransaction = CashTransaction(
    //     id: response['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    //     type: TransactionType.handover,
    //     status: TransactionStatus.pending,
    //     amount: amount,
    //     createdAt: DateTime.now(),
    //     initiator: 'C',
    //     accountType: TransactionAccountType.svTv,
    //     selectedAccount: _isReceiverManager ? _selectedManager : null,
    //     bankDetails: !_isReceiverManager ? _selectedBank : null,
    //     notes: _remarksController.text,
    //     receiptImagePath: _receiptImage?.path,
    //   );
    //
    //   bloc.add(AddTransaction(createdTransaction));
    //
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('Handover submitted successfully'),
    //       backgroundColor: Colors.green,
    //     ),
    //   );
    //
    //   Navigator.pop(context, createdTransaction);
    // } catch (e) {
    //   debugPrint("Handover submission failed: $e");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Submission failed: $e')),
    //   );
    // }

    final transaction = CashTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.handover,
        status: TransactionStatus.pending,
        amount: double.parse(_amountController.text),
        createdAt: DateTime.now(),
        initiator: 'D',
        selectedAccount: _selectedAccount,
        selectedBank: _selectedBank,
          notes: [
             if (_remarksController.text.isNotEmpty) _remarksController.text,
          ].join(' • '),
        accountType: TransactionAccountType.svTv,
        modeOfPayment: _isReceiverManager ? 'Cash' : 'Bank Draft',
    );

    context.read<CashManagementBloc>().add(AddTransaction(transaction));

    context.read<CashManagementBloc>().add(LoadCashData());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deposit submitted successfully')),
    );
    context.read<CashManagementBloc>().add(RefreshCashData());
    Navigator.pop(context, transaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: const Text('Cash Handover'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receiver type selection
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _isReceiverManager,
                            onChanged: (value) {
                              setState(() {
                                _isReceiverManager = value!;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          const Text('Cashier to Cashier/Manager'),
                        ],
                      ),
                      Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: _isReceiverManager,
                            onChanged: (value) {
                              setState(() {
                                _isReceiverManager = value!;
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          const Text('Cashier to Bank'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // Cash available
              // Container(
              //   padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
              //   decoration: BoxDecoration(
              //     color: const Color(0xFFE3F2FD),
              //     borderRadius: BorderRadius.circular(8.r),
              //   ),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       Text(
              //         'Cash Available',
              //         style: TextStyle(
              //           fontSize: 14.sp,
              //           color: Colors.grey[700],
              //         ),
              //       ),
              //       Row(
              //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //         children: [
              //           Text(
              //             _getCashAvailableFormatted(context),
              //             style: TextStyle(
              //               fontSize: 20.sp,
              //               fontWeight: FontWeight.bold,
              //               color: Theme.of(context).primaryColor,
              //             ),
              //           ),
              //           Text(
              //             _getLastUpdatedFormatted(context),
              //             style: TextStyle(
              //               fontSize: 12.sp,
              //               color: Colors.grey[600],
              //             ),
              //           ),
              //         ],
              //       ),
              //     ],
              //   ),
              // ),
              // SizedBox(height: 24.h),
              // Recipient selection
              if (_isReceiverManager) ...[
                Text(
                  'Select Account for Handover',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: _selectedAccount),
                  decoration: InputDecoration(
                    hintText: 'Select Account Paid To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onTap: _showAccountSelectionDialog,
                ),
              ] else ...[

                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: _selectedAccount),
                  decoration: InputDecoration(
                    hintText: 'Select Account Paid To',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onTap: _showAccountSelectionDialog,
                ),
                SizedBox(height: 8.h),
                Text(
                  'Select Bank',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 8.h),
                // InkWell(
                //   onTap: () {
                //     // Show bank selection dialog
                //     showDialog(
                //       context: context,
                //       builder: (context) {
                //         return AlertDialog(
                //           title: const Text('Select Bank'),
                //           content: SizedBox(
                //             width: double.maxFinite,
                //             child: ListView.builder(
                //               itemCount: _banks.length,
                //               itemBuilder: (context, index) {
                //                 return ListTile(
                //                   title: Text(_banks[index]),
                //                   onTap: () {
                //                     setState(() {
                //                       _selectedBank = _banks[index];
                //                     });
                //                     Navigator.pop(context);
                //                   },
                //                 );
                //               },
                //             ),
                //           ),
                //         );
                //       },
                //     );
                //   },
                //   child: Container(
                //     padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.grey.shade300),
                //       borderRadius: BorderRadius.circular(8.r),
                //     ),
                //     child: Row(
                //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //       children: [
                //         Text(
                //           _selectedBank ?? 'Select bank',
                //           style: TextStyle(
                //             fontSize: 16.sp,
                //             color: _selectedBank == null ? Colors.grey[600] : Colors.black,
                //           ),
                //         ),
                //         Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                //       ],
                //     ),
                //   ),
                // ),
                SizedBox(height: 16.h),
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  hint: Text('Select Bank'),
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
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  ),
                ),
              ],
              SizedBox(height: 16.h),
              // Amount
              Row(
                children: [
                  Text(
                    'Amount (₹)',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  suffixText: 'INR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              // SizedBox(height: 16.h),
              // Receipt upload
              // Center(
              //   child: Column(
              //     children: [
              //       if (_receiptImage != null) ...[
              //         InkWell(
              //           onTap: _viewFullImage,
              //           child: Container(
              //             width: double.infinity,
              //             height: 120.h,
              //             decoration: BoxDecoration(
              //               color: const Color(0xFFE3F2FD),
              //               borderRadius: BorderRadius.circular(8.r),
              //               image: DecorationImage(
              //                 image: FileImage(_receiptImage!),
              //                 fit: BoxFit.cover,
              //               ),
              //             ),
              //           ),
              //         ),
              //         SizedBox(height: 8.h),
              //         Row(
              //           mainAxisAlignment: MainAxisAlignment.center,
              //           children: [
              //             Text(
              //               _receiptFileName ?? 'Receipt Image',
              //               style: TextStyle(
              //                 fontSize: 12.sp,
              //                 color: Colors.grey[600],
              //               ),
              //             ),
              //             SizedBox(width: 8.w),
              //             InkWell(
              //               onTap: _showFileUploadDialog,
              //               child: Text(
              //                 'Change',
              //                 style: TextStyle(
              //                   fontSize: 12.sp,
              //                   color: Theme.of(context).primaryColor,
              //                   fontWeight: FontWeight.w500,
              //                 ),
              //               ),
              //             ),
              //           ],
              //         ),
              //       ] else ...[
              //         InkWell(
              //           onTap: _showFileUploadDialog,
              //           child: Container(
              //             padding: EdgeInsets.all(16.w),
              //             decoration: BoxDecoration(
              //               color: const Color(0xFFE3F2FD),
              //               borderRadius: BorderRadius.circular(8.r),
              //             ),
              //             child: Column(
              //               children: [
              //                 Icon(
              //                   Icons.upload_file,
              //                   size: 32.sp,
              //                   color: Theme.of(context).primaryColor,
              //                 ),
              //                 SizedBox(height: 8.h),
              //                 Text(
              //                   'Tap to upload document',
              //                   style: TextStyle(
              //                     fontSize: 14.sp,
              //                     color: Theme.of(context).primaryColor,
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ),
              //         SizedBox(height: 4.h),
              //         Text(
              //           'Receipt Upload (Optional)',
              //           style: TextStyle(
              //             fontSize: 12.sp,
              //             color: Colors.grey[600],
              //           ),
              //         ),
              //       ],
              //     ],
              //   ),
              // ),

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
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Daily cash handover',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16.w),
        child:    ElevatedButton(
          onPressed: _submitHandover,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0E5CA8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
            minimumSize: Size(double.infinity, 48.h),
          ),
          child: Text(
            'SUBMIT HANDOVER',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showAccountSelectionDialog() {
    DialogUtils.showAccountSelectionDialog(
      context: context,
      isLoading: _isLoading,
      accounts: _accounts,
      onAccountSelected: (selectedAccount) {
        setState(() {
          _selectedAccount = selectedAccount;
        });
      },
    );
  }

}