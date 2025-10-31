import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service_interface.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _validationState; // 'valid', 'invalid', null

  // Verhoeff algorithm tables (same as login)
  static const List<List<int>> _d = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 2, 3, 4, 0, 6, 7, 8, 9, 5],
    [2, 3, 4, 0, 1, 7, 8, 9, 5, 6],
    [3, 4, 0, 1, 2, 8, 9, 5, 6, 7],
    [4, 0, 1, 2, 3, 9, 5, 6, 7, 8],
    [5, 9, 8, 7, 6, 0, 4, 3, 2, 1],
    [6, 5, 9, 8, 7, 1, 0, 4, 3, 2],
    [7, 6, 5, 9, 8, 2, 1, 0, 4, 3],
    [8, 7, 6, 5, 9, 3, 2, 1, 0, 4],
    [9, 8, 7, 6, 5, 4, 3, 2, 1, 0]
  ];

  static const List<List<int>> _p = [
    [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    [1, 5, 7, 6, 2, 8, 3, 0, 9, 4],
    [5, 8, 0, 3, 7, 9, 6, 1, 4, 2],
    [8, 9, 1, 6, 0, 4, 3, 5, 2, 7],
    [9, 4, 5, 3, 1, 2, 6, 8, 7, 0],
    [4, 2, 8, 6, 5, 7, 3, 9, 0, 1],
    [2, 7, 9, 3, 8, 0, 6, 4, 1, 5],
    [7, 0, 4, 6, 9, 1, 3, 2, 5, 8]
  ];

  static const List<int> _inv = [0, 4, 3, 2, 1, 5, 6, 7, 8, 9];

  @override
  void initState() {
    super.initState();
    _setupAadharValidation();
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupAadharValidation() {
    _aadharController.addListener(() {
      _validateAadhar(_aadharController.text);
    });
  }

  void _validateAadhar(String aadhar) {
    if (aadhar.length != 12 || !RegExp(r'^\d+$').hasMatch(aadhar)) {
      if (_validationState != null) {
        setState(() {
          _validationState = null;
        });
      }
      return;
    }

    final isValid = _verhoeffValidate(aadhar);
    setState(() {
      _validationState = isValid ? 'valid' : 'invalid';
    });
  }

  bool _verhoeffValidate(String input) {
    if (input.length != 12) return false;

    final digits = input.split('').map(int.parse).toList();
    final checkDigit = digits.removeLast();

    // Generate checksum for first 11 digits
    final calculatedChecksum = _verhoeffGenerate(digits);

    return calculatedChecksum == checkDigit;
  }

  int _verhoeffGenerate(List<int> digits) {
    int c = 0;
    final invertedArray = digits.reversed.toList();

    for (int i = 0; i < invertedArray.length; i++) {
      c = _d[c][_p[((i + 1) % 8)][invertedArray[i]]];
    }

    return _inv[c];
  }

  String? _validateAadharField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (value.length != 12 || !RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Aadhar must be exactly 12 digits';
    }
    if (!_verhoeffValidate(value)) {
      return 'Invalid Aadhar number';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10 || !RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  Widget? _buildValidationIcon() {
    if (_validationState == null) return null;

    return Icon(
      _validationState == 'valid' ? Icons.check_circle : Icons.warning,
      color: _validationState == 'valid' ? Colors.green : Colors.orange,
      size: 20.sp,
    );
  }

  Color _getValidationBorderColor() {
    switch (_validationState) {
      case 'valid':
        return Colors.green;
      case 'invalid':
        return Colors.orange;
      default:
        return Colors.grey[300]!;
    }
  }

  Future<void> _initiateSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      final response = await apiService.initiateAadhaar(
        _aadharController.text.trim(),
        _phoneController.text.trim(),
      );

      if (response['success'] == true) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                aadhaarNumber: _aadharController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                refId: response['ref_id'],
                message: response['message'] ?? 'OTP sent successfully',
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to send OTP';
        });
      }
    } catch (e) {
      String errorMessage = 'Failed to send OTP. Please try again.';

      if (e is DioException) {
        if (e.response?.data != null) {
          try {
            final responseData = e.response!.data;
            if (responseData is Map<String, dynamic>) {
              errorMessage = responseData['message'] ?? responseData['error'] ?? errorMessage;
            } else if (responseData is String) {
              errorMessage = responseData;
            }
          } catch (_) {
            // Use default error message
          }
        }
      }

      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.sp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32.h),

              Icon(
                Icons.person_add,
                size: 80.sp,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 24.h),

              Text(
                'Create New Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 8.h),

              Text(
                'Enter your Aadhar and phone number for verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 32.h),

              // Aadhar field
              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number',
                  prefixIcon: const Icon(Icons.credit_card),
                  suffixIcon: _buildValidationIcon(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: _getValidationBorderColor(),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: _getValidationBorderColor(),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: _getValidationBorderColor(),
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: _validateAadharField,
                textInputAction: TextInputAction.next,
              ),
              SizedBox(height: 16.h),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: _validatePhone,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _initiateSignup(),
              ),
              SizedBox(height: 24.h),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[800], size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[800],
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null) SizedBox(height: 16.h),

              // Submit button
              SizedBox(
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _initiateSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : Text(
                    'SEND OTP',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Back to login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 16.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}