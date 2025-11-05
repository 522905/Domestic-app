import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/currency_utils.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/professional_snackbar.dart';

class HandoverScreen extends StatefulWidget {
  const HandoverScreen({Key? key}) : super(key: key);

  @override
  State<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends State<HandoverScreen> {
  late final ApiServiceInterface apiService;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  String? _selectedAccount;

  // Store full objects like in CashDepositPage
  List<Map<String, dynamic>> _paidToAccountObjects = [];
  List<String> _paidToAccountList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    // Listen to amount changes
    _amountController.addListener(() {
      setState(() {});
    });
    _fetchCashData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // Use same API call as CashDepositPage
  Future<void> _fetchCashData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Use the same API call as cash deposit page
      final paidToAccountResponse = await apiService.getCashAccount();
      _paidToAccountObjects = List<Map<String, dynamic>>.from(paidToAccountResponse);
      final paidToAccountList = _paidToAccountObjects
          .map<String>((item) => item['account_label'] as String)
          .toList();

      setState(() {
        _isLoading = false;
        _paidToAccountList = paidToAccountList;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      context.showErrorSnackBar('Error fetching accounts: $e');
    }
  }

  // Helper function to get account ID from name (same as deposit page)
  int? _getPaidToAccountId(String accountName) {
    try {
      final account = _paidToAccountObjects.firstWhere(
            (item) => item['account_label'] == accountName,
      );
      return account['id'] as int;
    } catch (e) {
      return null;
    }
  }

  void _submitHandover() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedAccount == null || _selectedAccount!.isEmpty) {
        context.showWarningSnackBar('Please select an account');
        return;
      }

      // 🔧 Strip grouping commas (and any stray spaces) before parsing
      final raw = _amountController.text.replaceAll(',', '').trim();

      // Extra guard rails
      if (raw.isEmpty) {
        context.showWarningSnackBar('Please enter a valid amount');
        return;
      }

      final amount = double.tryParse(raw);
      if (amount == null || amount <= 0) {
        context.showInfoSnackBar('Amount must be a positive number');
        return;
      }

      final paidToAccountId = _getPaidToAccountId(_selectedAccount!);
      if (paidToAccountId == null) {
        context.showWarningSnackBar('Invalid account selected');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final transaction = CashTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.handover,
        status: TransactionStatus.pending,
        amount: amount,
        createdAt: DateTime.now(),
        initiator: 'D',
        selectedAccount: paidToAccountId.toString(),
        paidTo: paidToAccountId.toString(),
        createdBy: 'Current User',
        notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
        fromAccount: paidToAccountId.toString(), // Use same account ID
        modeOfPayment: 'Cash',
      );

      final completer = Completer<void>();
      context.read<CashManagementBloc>().add(
          AddTransaction(transaction, completer: completer)
      );

      try {
        await completer.future;

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        context.showSuccessSnackBar('Handover submitted successfully');

        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          Navigator.pop(context, true);
        }

      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }

        context.showErrorSnackBar('Error submitting handover: $e');
      }
    }
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
                      // Account selection
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
                          hintText: 'Select Account for Handover',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        ),
                        onTap: _showAccountSelectionDialog,
                        validator: (value) {
                          if (_selectedAccount == null || _selectedAccount!.isEmpty) {
                            return 'Please select an account';
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.h),
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
                          onPressed: _submitHandover,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E5CA8),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'SUBMIT HANDOVER',
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

  void _showAccountSelectionDialog() {
    DialogUtils.showAccountSelectionDialog(
      context: context,
      isLoading: _isLoading,
      accounts: _paidToAccountObjects, // Pass full objects
      onAccountSelected: (selectedAccount) {
        setState(() {
          _selectedAccount = selectedAccount;
        });
      },
    );
  }
}