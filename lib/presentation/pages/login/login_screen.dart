import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_service_interface.dart';
import '../main_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _secureStorage = const FlutterSecureStorage();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _showSuggestions = false;
  List<String> _savedUsernames = [];
  String? _validationState; // 'valid', 'invalid', null

  static const String _usernameListKey = 'saved_usernames';
  static const int _maxStoredUsernames = 5;

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
    _loadSavedUsernames();
    _setupFocusListeners();
    _setupUsernameValidation();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _setupFocusListeners() {
    _usernameFocusNode.addListener(() {
      if (_usernameFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = true;
        });
      }
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() {
          _showSuggestions = false;
        });
      }
    });
  }

  void _setupUsernameValidation() {
    _usernameController.addListener(() {
      _validateUsername(_usernameController.text);
    });
  }

  void _validateUsername(String username) {
    if (username.length != 12 || !RegExp(r'^\d+$').hasMatch(username)) {
      if (_validationState != null) {
        setState(() {
          _validationState = null;
        });
      }
      return;
    }

    final isValid = _verhoeffValidate(username);
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

  Future<void> _loadSavedUsernames() async {
    final prefs = await SharedPreferences.getInstance();
    final usernames = prefs.getStringList(_usernameListKey) ?? [];
    setState(() {
      _savedUsernames = usernames;
    });
  }

  Future<void> _saveUsername(String username) async {
    if (username.trim().isEmpty) return;

    final trimmedUsername = username.trim();

    // Remove if already exists (ignore duplicates)
    _savedUsernames.remove(trimmedUsername);

    // Add to beginning of list
    _savedUsernames.insert(0, trimmedUsername);

    // Keep only last 5
    if (_savedUsernames.length > _maxStoredUsernames) {
      _savedUsernames = _savedUsernames.take(_maxStoredUsernames).toList();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usernameListKey, _savedUsernames);

    setState(() {});
  }

  Future<void> _deleteUsername(String username) async {
    _savedUsernames.remove(username);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usernameListKey, _savedUsernames);
    setState(() {});
  }

  void _selectUsername(String username) {
    _usernameController.text = username;
    _passwordController.clear();
    setState(() {
      _showSuggestions = false;
    });
    _passwordFocusNode.requestFocus();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      await apiService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );

      // Save username on successful login
      await _saveUsername(_usernameController.text.trim());

      // Store a flag or token in secure storage
      await _secureStorage.write(key: 'isLoggedIn', value: 'true');

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainContainer()),
        );
      }
    } catch (e) {
      String errorMessage = 'Login failed. Please try again.';

      // Handle Dio exceptions properly
      if (e is DioException) {
        if (e.response?.data != null) {
          try {
            final responseData = e.response!.data;

            // Handle JSON response
            if (responseData is Map<String, dynamic>) {
              if (responseData['message'] != null) {
                errorMessage = responseData['message'];
              } else if (responseData['error'] != null) {
                errorMessage = responseData['error'];
              }
            }
            // Handle string response that might be JSON
            else if (responseData is String) {
              try {
                final jsonData = jsonDecode(responseData);
                if (jsonData['message'] != null) {
                  errorMessage = jsonData['message'];
                } else if (jsonData['error'] != null) {
                  errorMessage = jsonData['error'];
                }
              } catch (_) {
                // If not JSON, use the string as error message
                errorMessage = responseData;
              }
            }
          } catch (parseError) {
            debugPrint('Error parsing API response: $parseError');
          }
        } else {
          // Handle network or other Dio errors
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
            case DioExceptionType.receiveTimeout:
            case DioExceptionType.sendTimeout:
              errorMessage = 'Connection timeout. Please try again.';
              break;
            case DioExceptionType.connectionError:
              errorMessage = 'No internet connection. Please check your network.';
              break;
            default:
              errorMessage = 'Login failed. Please try again.';
          }
        }
      } else {
        // Handle other types of exceptions
        debugPrint('Non-Dio exception: $e');
      }

      setState(() {
        _errorMessage = errorMessage;
      });
      debugPrint('Login error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildUsernameSuggestions() {
    if (_savedUsernames.isEmpty || !_showSuggestions) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 2.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _savedUsernames.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final username = _savedUsernames[index];
          return InkWell(
            onTap: () => _selectUsername(username),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 12.sp,
                    color: Colors.grey[600],
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      username,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteUsername(username),
                    icon: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: Colors.grey[500],
                    ),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  width: 200.w,
                  height: 200.h,
                ),
                SizedBox(height: 24.h),

                Text(
                  'Arun Gas Services',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8.h),

                Text(
                  'Login to your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 32.h),

                // Username field
                TextField(
                  controller: _usernameController,
                  focusNode: _usernameFocusNode,
                  onTap: () {
                    setState(() {
                      _showSuggestions = true;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.person),
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
                  textInputAction: TextInputAction.next,
                ),

                // Username suggestions
                _buildUsernameSuggestions(),

                SizedBox(height: 16.h),

                // Password field
                TextField(
                  controller: _passwordController,
                  focusNode: _passwordFocusNode,
                  onTap: () {
                    setState(() {
                      _showSuggestions = false;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _login(),
                ),
                SizedBox(height: 8.h),

                // Sign Up button
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Sign Up for New Account',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

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
                      style: TextStyle(
                        color: Colors.red[800],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                if (_errorMessage != null) SizedBox(height: 16.h),

                // Login button
                SizedBox(
                  height: 56.h,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
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
                      'LOGIN',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                // App version
                Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}