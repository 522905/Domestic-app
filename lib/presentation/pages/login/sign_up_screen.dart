import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../core/services/api_service_interface.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _aadharController = TextEditingController();
  final _panController = TextEditingController();
  final _drivingLicenseController = TextEditingController();
  final _rcController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _currentPic;
  File? _vehiclePic;
  File? _passbookPic;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aadharController.dispose();
    _panController.dispose();
    _drivingLicenseController.dispose();
    _rcController.dispose();
    _vehicleTypeController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateAadhar(String? value) {
    if (value == null || value.isEmpty) {
      return 'Aadhar number is required';
    }
    if (value.length != 12 || !RegExp(r'^\d{12}$').hasMatch(value)) {
      return 'Aadhar must be exactly 12 digits';
    }
    return null;
  }

  String? _validatePAN(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
        return 'Invalid PAN format (AAAAA9999A)';
      }
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

  Future<void> _pickImage(String type) async {
    final source = await _showImageSourceDialog();
    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          switch (type) {
            case 'current':
              _currentPic = File(image.path);
              break;
            case 'vehicle':
              _vehiclePic = File(image.path);
              break;
            case 'passbook':
              _passbookPic = File(image.path);
              break;
          }
        });
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentPic == null) {
      setState(() {
        _errorMessage = 'Current photo is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      // Create payload - adjust according to your API structure
      final signupData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'aadhar_number': _aadharController.text.trim(),
        'pan_number': _panController.text.trim(),
        'driving_license': _drivingLicenseController.text.trim(),
        'rc_number': _rcController.text.trim(),
        'vehicle_type': _vehicleTypeController.text.trim(),
        'account_number': _accountController.text.trim(),
        'password': _passwordController.text,
        // Files will need to be handled separately in your API service
      };

      /// TODO Call your signup API
      // await apiService.signup(signupData, _currentPic, _vehiclePic, _passbookPic);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful! Please login.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Signup failed. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImagePicker(String label, File? image, String type, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
            if (required) Text(' *', style: TextStyle(color: Colors.red, fontSize: 16.sp)),
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: () => _pickImage(type),
          child: Container(
            width: double.infinity,
            height: 120.h,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey[50],
            ),
            child: image != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(image, fit: BoxFit.cover),
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, size: 32.sp, color: Colors.grey),
                SizedBox(height: 8.h),
                Text('Tap to select image', style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
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
              // Personal Information
              Text('Personal Information', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value?.isEmpty == true ? 'First name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) => value?.isEmpty == true ? 'Last name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _aadharController,
                decoration: InputDecoration(
                  labelText: 'Aadhar Number *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(12),
                ],
                validator: _validateAadhar,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _panController,
                decoration: InputDecoration(
                  labelText: 'PAN Card Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                ],
                validator: _validatePAN,
              ),
              SizedBox(height: 24.h),

              // Vehicle Information (Optional)
              Text('Vehicle Information (Optional)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _drivingLicenseController,
                decoration: InputDecoration(
                  labelText: 'Driving License Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _rcController,
                decoration: InputDecoration(
                  labelText: 'RC Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _vehicleTypeController,
                decoration: InputDecoration(
                  labelText: 'Vehicle Type',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16.h),

              _buildImagePicker('Vehicle Photo', _vehiclePic, 'vehicle'),
              SizedBox(height: 24.h),

              // Bank Information (Optional)
              Text('Bank Information (Optional)', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: 'Account Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),

              _buildImagePicker('Passbook Photo', _passbookPic, 'passbook'),
              SizedBox(height: 24.h),

              // Required Information
              Text('Required Information', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),

              _buildImagePicker('Current Photo', _currentPic, 'current', required: true),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                obscureText: _obscurePassword,
                validator: _validatePassword,
              ),
              SizedBox(height: 16.h),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm Password *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
              ),
              SizedBox(height: 16.h),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[800], fontSize: 14.sp),
                  ),
                ),
              if (_errorMessage != null) SizedBox(height: 16.h),

              // Submit button
              SizedBox(
                height: 56.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                      : Text('CREATE ACCOUNT', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}