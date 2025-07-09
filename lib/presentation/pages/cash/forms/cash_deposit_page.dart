import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/api_service_interface.dart';
import '../../../../domain/entities/cash/cash_transaction.dart';
import '../../../../utils/dialog_utils.dart';
import '../../../blocs/cash/cash_bloc.dart';

enum AccountType {
  refill,
  svTv,
  nfr,
}

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
  final _receiptNumberController = TextEditingController();
  String?  _selectedAccount ;

  AccountType _selectedAccountType = AccountType.refill;

  // Format currency
  final _currencyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  final List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    apiService = context.read<ApiServiceInterface>(); // Initialize apiService
    _fetchAccounts(); // Fetch accounts when the page loads
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _amountController.dispose();
    _receiptNumberController.dispose();
    _selectedAccount = null;
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
                      _buildAccountRadio(
                        type: AccountType.svTv,
                        label: 'SV/TV Account',
                      ),
                      _buildAccountRadio(
                        type: AccountType.refill,
                        label: 'Refill Account',
                      ),
                      _buildAccountRadio(
                        type: AccountType.nfr,
                        label: 'NFR Account',
                      ),
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

                      // Receipt Number
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

  String _getAccountLabel(AccountType type) {
    switch (type) {
      case AccountType.svTv:
        return 'SV/TV Account';
      case AccountType.refill:
        return 'Refill Account';
      case AccountType.nfr:
        return 'NFR Account';
      default:
        return 'Unknown Account';
    }
  }

  void _submitDeposit() {
    if (_formKey.currentState!.validate()) {
      // Check if amount is valid
      final amount = double.tryParse(_amountController.text);
      if (amount == null || amount <= 0) {
        _showInvalidAmountDialog();
        return;
      }

      if( _selectedAccount == null || _selectedAccount!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Account')),
        );
        return;
      }
      _showConfirmationDialog();
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 36.sp,
                ),
              ),
              SizedBox(height: 16.h),

              // Title
              Text(
                'Deposit Submitted',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),

              // Description
              Text(
                '${_currencyFormat.format(double.parse(_amountController.text))} deposit to ${_getAccountLabel(_selectedAccountType)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),

              Text(
                'has been submitted for approval',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Reference ID: DEP-7321',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),

              // OK Button
              SizedBox(
                width: 120.w,
                child: ElevatedButton(
                  onPressed: () {
                    final transaction = CashTransaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        type: TransactionType.deposit,
                        status: TransactionStatus.pending,
                        amount: double.parse(_amountController.text),
                        createdAt: DateTime.now(),
                        initiator: 'D',
                        accountType: _selectedAccountType == AccountType.svTv
                            ? TransactionAccountType.svTv
                            : _selectedAccountType == AccountType.refill
                            ? TransactionAccountType.refill
                            : TransactionAccountType.nfr,
                        selectedAccount: _selectedAccount,
                        notes: [
                          if (_remarksController.text.isNotEmpty) _remarksController.text,
                          if (_receiptNumberController.text.isNotEmpty) 'Receipt: ${_receiptNumberController.text}',
                          'Account: ${_getAccountLabel(_selectedAccountType)}',
                        ].join(' • ')
                      );
                    // Add transaction to the bloc

                    context.read<CashManagementBloc>().add(AddTransaction(transaction));

                    context.read<CashManagementBloc>().add(LoadCashData());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Deposit submitted successfully')),
                    );
                    context.read<CashManagementBloc>().add(RefreshCashData());

                    Navigator.of(context)
                      ..pop(transaction) // closes the dialog
                      ..pop(transaction); // goes back to Cash page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
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
      accounts: _accounts,
      onAccountSelected: (selectedAccount) {
        setState(() {
          _selectedAccount = selectedAccount;
        });
      },
    );
  }

  Widget _buildAccountRadio({required AccountType type, required String label}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedAccountType = type;
        });
      },
      borderRadius: BorderRadius.circular(4.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            Radio<AccountType>(
              value: type,
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
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}