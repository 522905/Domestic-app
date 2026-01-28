import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../blocs/digital_credit/digital_credit_bloc.dart';
import '../../blocs/digital_credit/digital_credit_event.dart';
import '../../blocs/digital_credit/digital_credit_state.dart';
import 'widgets/company_switch_dialog.dart';

class CreateCreditPage extends StatefulWidget {
  const CreateCreditPage({Key? key}) : super(key: key);

  @override
  State<CreateCreditPage> createState() => _CreateCreditPageState();
}

class _CreateCreditPageState extends State<CreateCreditPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  DateTime? _selectedDate;
  bool _autoClaim = true;

  @override
  void initState() {
    super.initState();
    // Auto-set date to today
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final now = DateTime.now();
    final initialDate = _selectedDate ?? now;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select order date')),
        );
        return;
      }

      final orderDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      context.read<DigitalCreditBloc>().add(
        CreateDigitalCredit(
          orderId: _orderIdController.text.trim(),
          orderDate: orderDate,
          autoClaim: _autoClaim,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Digital Credit'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<DigitalCreditBloc, DigitalCreditState>(
        listener: (context, state) {
          if (state is CreditCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state is CompanyMismatchError) {
            showDialog(
              context: context,
              builder: (_) => CompanySwitchDialog(
                currentCompanyName: state.currentCompany['name'] ?? 'Current Company',
                suggestedCompanies: state.orderFoundIn,
                onSwitch: (companyId) async {
                  // TODO: Implement company switch
                  // This would require calling an API to switch company
                  // then navigating to dashboard and retrying
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Company switch feature coming soon'),
                    ),
                  );
                },
              ),
            );
          } else if (state is DigitalCreditError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<DigitalCreditBloc, DigitalCreditState>(
          builder: (context, state) {
            final isLoading = state is CreditCreating;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Info card
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24.sp),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Create a digital credit for an order with digital payment',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Order ID field
                    Text(
                      'Order ID',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _orderIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter order ID (e.g., 2-005106665284)',
                        prefixIcon: const Icon(Icons.receipt_long),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter order ID';
                        }
                        if (value.trim().length < 3) {
                          return 'Order ID must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    // Order Date field
                    Text(
                      'Order Date',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    InkWell(
                      onTap: _selectDate,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12.r),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey.shade700),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                _selectedDate != null
                                    ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                                    : 'Select order date',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: _selectedDate != null
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    // Auto-claim checkbox
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          CheckboxListTile(
                            value: _autoClaim,
                            onChanged: (value) {
                              setState(() {
                                _autoClaim = value ?? false;
                              });
                            },
                            title: Text(
                              'Auto-claim if I\'m the delivery boy',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: const Color(0xFF0E5CA8),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            'If you delivered this order, the credit will be automatically claimed to your account after processing.',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),
                    // Submit button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E5CA8),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: isLoading
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Create Credit',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
