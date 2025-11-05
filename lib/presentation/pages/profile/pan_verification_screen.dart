// lib/presentation/pages/profile/pan_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';

class PanVerificationScreen extends StatefulWidget {
  const PanVerificationScreen({Key? key}) : super(key: key);

  @override
  State<PanVerificationScreen> createState() => _PanVerificationScreenState();
}

class _PanVerificationScreenState extends State<PanVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _apiResponse;
  String? _errorMessage;

  @override
  void dispose() {
    _panController.dispose();
    super.dispose();
  }

  String? _validatePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number is required';
    }

    // Basic PAN format validation (AAAAA9999A)
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid PAN format. Use: AAAAA9999A';
    }

    return null;
  }

  Future<void> _verifyPan() async {
    if (!_formKey.currentState!.validate()) return;

    final token = await User().getToken();
    debugPrint('🔐 Token exists: ${token != null}');
    debugPrint('🔐 Token value: $token');

    setState(() {
      _isLoading = true;
      _apiResponse = null;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);
      final response = await apiService.initiatePartner(_panController.text.toUpperCase());

      setState(() {
        _apiResponse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become Partner'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF4CAF50).withOpacity(0.1),
                      const Color(0xFF4CAF50).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_membership,
                        size: 48.sp,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Partner Registration',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Enter your PAN number to begin the partner verification process',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32.h),

              // PAN Input Section
              Text(
                'PAN Number',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              SizedBox(height: 12.h),

              TextFormField(
                controller: _panController,
                validator: _validatePan,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter PAN (e.g., AZJPG7110R)',
                  prefixIcon: Icon(
                    Icons.credit_card,
                    color: const Color(0xFF0E5CA8),
                    size: 24.sp,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Color(0xFF0E5CA8), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                ),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),

              SizedBox(height: 24.h),

              // Verify Button
              Container(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _verifyPan,
                  icon: _isLoading
                      ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.verified_user),
                  label: Text(
                    _isLoading ? 'VERIFYING...' : 'VERIFY PAN',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              SizedBox(height: 32.h),

              // Response Section
              if (_apiResponse != null) ...[
                _buildResponseSection(),
              ],

              // Error Section
              if (_errorMessage != null) ...[
                _buildErrorSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    final success = _apiResponse!['success'] ?? false;
    final message = _apiResponse!['message'] ?? '';
    final status = _apiResponse!['status'] ?? '';
    final partnerId = _apiResponse!['partner_kyc_id'];
    final deficiencyType = _apiResponse!['deficiency_type'];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: success ? Colors.green.withOpacity(0.05) : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: success ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: (success ? Colors.green : Colors.orange).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  success ? Icons.check_circle : Icons.info,
                  color: success ? Colors.green : Colors.orange,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                success ? 'Verification Response' : 'Action Required',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: success ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Response Details
          _buildResponseItem('Status', status.toUpperCase()),
          if (partnerId != null) ...[
            SizedBox(height: 12.h),
            _buildResponseItem('Partner KYC ID', partnerId.toString()),
          ],
          if (deficiencyType != null) ...[
            SizedBox(height: 12.h),
            _buildResponseItem('Issue Type', deficiencyType.toString().replaceAll('_', ' ').toUpperCase()),
          ],
          SizedBox(height: 12.h),
          _buildResponseItem('Message', message),
        ],
      ),
    );
  }

  Widget _buildResponseItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Verification Failed',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}