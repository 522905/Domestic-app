import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/currency_utils.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';
import '../../../widgets/professional_snackbar.dart';

class CashDepositPage extends StatefulWidget {
  final double? initialAmount;

  const CashDepositPage({Key? key, this.initialAmount}) : super(key: key);

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

    // Pre-fill amount if provided with formatting
    if (widget.initialAmount != null && widget.initialAmount! > 0) {
      final digitsOnly = widget.initialAmount!.toInt().toString();
      _amountController.text = formatIndianNumber(digitsOnly); // Format it
    }
    // Listen to amount changes
    _amountController.addListener(() {
      setState(() {});
    });

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
          .map<String>((item) => item['account_label'] as String)
          .toList();

      // Fetch paid-to account list - store full objects
      final paidToAccountResponse = await apiService.getCashAccount();
      _paidToAccountObjects = List<Map<String, dynamic>>.from(paidToAccountResponse);
      final paidToAccountList = _paidToAccountObjects
          .map<String>((item) => item['account_label'] as String)
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
      context.showErrorSnackBar('Error fetching accounts: $e');
    }
  }

  // Helper function to get account type ID from name
  int? _getAccountTypeId(String accountName) {
    try {
      final account = _accountTypeObjects.firstWhere(
            (item) => item['account_label'] == accountName,
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
            (item) => item['account_label'] == accountName,
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
                      // Amount in words and formatted number
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
                          onPressed: _showDepositConfirmation,
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

  void _showDepositConfirmation() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      _showInvalidAmountDialog();
      return;
    }

    if (_selectedAccountType == null || _selectedAccount == null) {
      context.showWarningSnackBar('Please select account type and paid-to account');
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E5CA8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_circle_outline,
                        color: const Color(0xFF0E5CA8),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Confirm Deposit',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Deposit details
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConfirmationRow('Amount', '₹${_amountController.text}', isAmount: true),
                      SizedBox(height: 12.h),
                      _buildConfirmationRow('Account', _selectedAccountType!),
                      SizedBox(height: 12.h),
                      _buildConfirmationRow('Paid To', _selectedAccount!),
                      if (_remarksController.text.isNotEmpty) ...[
                        SizedBox(height: 12.h),
                        _buildConfirmationRow('Remarks', _remarksController.text),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop(); // Close confirmation dialog

                          // Submit deposit FIRST
                          await _submitDeposit();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E5CA8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                        ),
                        child: Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationRow(String label, String value, {bool isAmount = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isAmount ? 16.sp : 13.sp,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w600,
              color: isAmount ? const Color(0xFF0E5CA8) : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  _submitDeposit() async {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;

    // Get IDs instead of names
    final accountTypeId = _selectedAccountType != null
        ? _getAccountTypeId(_selectedAccountType!)
        : null;
    final paidToAccountId = _selectedAccount != null
        ? _getPaidToAccountId(_selectedAccount!)
        : null;

    // Validate IDs were found
    if (accountTypeId == null) {
      context.showErrorSnackBar('Invalid account type selected');
      return;
    }

    if (paidToAccountId == null) {
      context.showErrorSnackBar('Invalid paid-to account selected');
      return;
    }

    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    final transaction = CashTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      amount: amount,
      createdAt: DateTime.now(),
      initiator: 'D',
      fromAccount: accountTypeId.toString(),
      selectedAccount: paidToAccountId.toString(),
      paidTo: paidToAccountId.toString(),
      createdBy: 'Current User',
      notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
    );

    final completer = Completer<void>();

    context.read<CashManagementBloc>().add(
        AddTransaction(transaction, completer: completer)
    );

    try {
      await completer.future;

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      context.showSuccessSnackBar('Deposit submitted successfully');

      if (mounted) {
        // Return to cash page with success flag
        // Cash page will handle the refresh
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      // Close loading dialog on error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
      }

      context.showErrorSnackBar('Error submitting deposit: $e');
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