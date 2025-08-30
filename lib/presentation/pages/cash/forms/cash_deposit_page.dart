import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';

class CashDepositPage extends StatefulWidget {
  const CashDepositPage({Key? key}) : super(key: key);

  @override
  State<CashDepositPage> createState() => _CashDepositPageState();
}

class _CashDepositPageState extends State<CashDepositPage> {
  late final ApiServiceInterface apiService;
  final _formKey = GlobalKey<FormState>();
  final _remarksController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedAccountType;
  String? _selectedAccount;

  // Store full objects instead of just names
  List<Map<String, dynamic>> _accountTypeObjects = [];
  List<Map<String, dynamic>> _paidToAccountObjects = [];

  // Keep these for UI display (derived from objects)
  List<String> _accountType = [];
  List<String> _paidToAccountList = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>();
    _fetchCashData();
  }

  Future<void> _fetchCashData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch account type list - store full objects
      final accountTypeResponse = await apiService.getAccountType();
      _accountTypeObjects = List<Map<String, dynamic>>.from(accountTypeResponse);
      final accountTypeList = _accountTypeObjects
          .map<String>((item) => item['account_name'] as String)
          .toList();

      // Fetch paid-to account list - store full objects
      final paidToAccountResponse = await apiService.getCashAccount();
      _paidToAccountObjects = List<Map<String, dynamic>>.from(paidToAccountResponse);
      final paidToAccountList = _paidToAccountObjects
          .map<String>((item) => item['account_name'] as String)
          .toList();

      // Update state with the fetched data
      setState(() {
        _isLoading = false;
        _accountType = accountTypeList;
        _paidToAccountList = paidToAccountList;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching accounts: $e')),
      );
    }
  }

  // Helper function to get account type ID from name
  int? _getAccountTypeId(String accountName) {
    try {
      final account = _accountTypeObjects.firstWhere(
            (item) => item['account_name'] == accountName,
      );
      return account['id'] as int;
    } catch (e) {
      return null;
    }
  }

  // Helper function to get paid-to account ID from name
  int? _getPaidToAccountId(String accountName) {
    try {
      final account = _paidToAccountObjects.firstWhere(
            (item) => item['account_name'] == accountName,
      );
      return account['id'] as int;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _selectedAccount = null;
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E5CA8),
        title: const Text('Cash Deposit'),
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
                      // Select Account
                      Text(
                        'Select Account',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[700],
                        ),
                      ),
                      // Account Radio Buttons
                      _buildDynamicAccountRadios(),
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
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          hintText: 'Enter amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 0),
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
                        'Paid To',
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
                      SizedBox(height: 8.h),
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
                          onPressed: _submitDeposit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E5CA8),
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            'SUBMIT DEPOSIT',
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

  void _submitDeposit() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showInvalidAmountDialog();
        return;
      }

      if (_selectedAccount == null || _selectedAccount!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Account Paid To')),
        );
        return;
      }

      // Get IDs instead of names
      final accountTypeId = _selectedAccountType != null
          ? _getAccountTypeId(_selectedAccountType!)
          : null;
      final paidToAccountId = _selectedAccount != null
          ? _getPaidToAccountId(_selectedAccount!)
          : null;

      // Validate IDs were found
      if (accountTypeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid account type selected')),
        );
        return;
      }

      if (paidToAccountId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid paid-to account selected')),
        );
        return;
      }

      final transaction = CashTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: TransactionType.deposit,
        status: TransactionStatus.pending,
        amount: amount,
        createdAt: DateTime.now(),
        initiator: 'D',
        fromAccount: accountTypeId.toString(), // Send ID as string
        selectedAccount: paidToAccountId.toString(), // Send ID as string
        paidTo: paidToAccountId.toString(), // Send ID as string
        createdBy: 'Current User',
        notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
      );

      final completer = Completer<void>();
      context.read<CashManagementBloc>().add(
          AddTransaction(transaction, completer: completer)
      );
      context.read<CashManagementBloc>().add(RefreshCashData());

      try {
        await completer.future;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit submitted successfully')),
        );
        // Return success indicator instead of the transaction object
        Navigator.of(context).pop(true); // Return true to indicate success
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting deposit: $e')),
        );
      }
    }
  }

  void _showInvalidAmountDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                'Invalid Amount',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // Description
              Text(
                'Please enter an amount',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              Text(
                'greater than ₹0',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // OK Button
              SizedBox(
                width: 120.w,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
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
    );
  }

  void _showAccountSelectionDialog() {
    DialogUtils.showAccountSelectionDialog(
      context: context,
      isLoading: _isLoading,
      accounts: _paidToAccountObjects, // Pass full objects instead of just names
      onAccountSelected: (selectedAccount) {
        setState(() {
          _selectedAccount = selectedAccount;
        });
      },
    );
  }

  Widget _buildDynamicAccountRadios() {
    return Column(
      children: _accountType.map((accountName) {
        return InkWell(
          onTap: () {
            setState(() {
              _selectedAccountType = accountName;
            });
          },
          borderRadius: BorderRadius.circular(4.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: Row(
              children: [
                Radio<String>(
                  value: accountName,
                  groupValue: _selectedAccountType,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAccountType = value;
                      });
                    }
                  },
                  activeColor: const Color(0xFF0E5CA8),
                ),
                Text(
                  accountName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}