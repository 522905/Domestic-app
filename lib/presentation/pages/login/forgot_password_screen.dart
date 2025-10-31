import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service_interface.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadharController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _successMessage;
  String? _validationState; // 'valid', 'invalid', null

  // Verhoeff algorithm tables
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
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must be exactly 6 digits';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
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

  void _clearMessages() {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _sendOTP() async {
    if (_aadharController.text.isEmpty || _validateAadharField(_aadharController.text) != null) {
      setState(() {
        _errorMessage = 'Please enter a valid Aadhar number';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _clearMessages();
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      final otpData = {
        'aadhar_number': _aadharController.text.trim(),
      };

      // Call send OTP API
      final response = await apiService.sendOTP(otpData);

      // Assuming API returns success status and message
      if (response['success'] == true) {
        setState(() {
          _successMessage = response['message'] ?? 'OTP sent successfully to your registered mobile number';
          _currentStep = 1; // Move to OTP step
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to send OTP';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to send OTP. Please check your Aadhar number and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendOTP() async {
    await _sendOTP(); // Reuse the same function
  }

  Future<void> _resetPassword() async {
    if (_otpController.text.isEmpty || _validateOTP(_otpController.text) != null) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP';
      });
      return;
    }

    if (_passwordController.text.isEmpty || _validatePassword(_passwordController.text) != null ||
        _validateConfirmPassword(_confirmPasswordController.text) != null) {
      setState(() {
        _errorMessage = 'Please check your password fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _clearMessages();
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      final resetData = {
        'aadhar_number': _aadharController.text.trim(),
        'otp': _otpController.text.trim(),
        'new_password': _passwordController.text,
        'confirm_password': _confirmPasswordController.text,
      };

      // Call reset password API
      final response = await apiService.resetPassword(resetData);

      if (response['success'] == true) {
        setState(() {
          _successMessage = response['message'] ?? 'Password reset successfully! You can now login with your new password.';
          _currentStep = 2; // Move to success step
        });

        // Navigate back to login after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Password reset failed';
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Password reset failed. Please check your details and try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          // Step 1
          _buildStepCircle(0, 'Aadhar', Icons.credit_card),
          _buildStepLine(0),

          // Step 2
          _buildStepCircle(1, 'OTP', Icons.sms),
          _buildStepLine(1),

          // Step 3
          _buildStepCircle(2, 'Password', Icons.lock),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int stepIndex, String label, IconData icon) {
    final isActive = _currentStep >= stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48.w,
            height: 48.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isActive || isCompleted ? Colors.white : Colors.grey[600],
              size: 20.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Theme.of(context).primaryColor : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;

    return Expanded(
      child: Container(
        height: 2.h,
        margin: EdgeInsets.only(top: 24.h),
        color: isCompleted ? Colors.green : Colors.grey[300],
      ),
    );
  }

  Widget _buildAadharStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter Your Aadhar Number',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'We\'ll send an OTP to your registered mobile number',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24.h),

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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _sendOTP(),
        ),
        SizedBox(height: 24.h),

        SizedBox(
          height: 56.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
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
      ],
    );
  }

  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Enter the 6-digit OTP sent to your registered mobile number',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24.h),

        TextFormField(
          controller: _otpController,
          decoration: InputDecoration(
            labelText: '6-Digit OTP',
            prefixIcon: const Icon(Icons.sms),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.next,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 8.w,
          ),
        ),
        SizedBox(height: 16.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive OTP? ',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            TextButton(
              onPressed: _isLoading ? null : _resendOTP,
              child: Text(
                'Resend',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        Text(
          'Set New Password',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 16.h),

        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'New Password',
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
        ),
        SizedBox(height: 16.h),

        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Confirm New Password',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _resetPassword(),
        ),
        SizedBox(height: 24.h),

        SizedBox(
          height: 56.h,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _resetPassword,
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
              'RESET PASSWORD',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle,
          size: 80.sp,
          color: Colors.green,
        ),
        SizedBox(height: 24.h),
        Text(
          'Password Reset Successful!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          _successMessage ?? 'Your password has been reset successfully. You can now login with your new password.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Redirecting to login...',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
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
              // Step Indicator
              _buildStepIndicator(),
              SizedBox(height: 32.h),

              // Error message
              if (_errorMessage != null)
                Container(
                  margin: EdgeInsets.only(bottom: 16.h),
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

              // Success message (for OTP sent)
              if (_successMessage != null && _currentStep != 2)
                Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[800], size: 20.sp),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Step Content
              if (_currentStep == 0) _buildAadharStep(),
              if (_currentStep == 1) _buildOTPStep(),
              if (_currentStep == 2) _buildSuccessStep(),

              SizedBox(height: 24.h),

              // Back to login (only show on first step or success step)
              if (_currentStep == 0 || _currentStep == 2)
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
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