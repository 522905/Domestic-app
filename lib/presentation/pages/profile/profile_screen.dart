// lib/presentation/pages/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lpg_distribution_app/presentation/pages/profile/pan_verification_screen.dart';
import 'package:lpg_distribution_app/presentation/pages/profile/password_change_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/User.dart';
import '../../../core/services/version_manager.dart';
import '../../../core/utils/global_drawer.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  final _versionManager = VersionManager();
  UpdateStatus? _updateStatus;
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;

  // User data variables
  int? userId;
  String? userName;
  List<String>? userRoles;
  String? userAccount;
  String? userWarehouse;
  String? userPhoneNumber;
  String? userVehicleNumber;
  String? userEmail;
  UserCompany? activeCompany;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    setState(() => _isCheckingUpdate = true);
    try {
      final status = await _versionManager.checkVersionViaAPI();
      if (mounted) {
        setState(() {
          _updateStatus = status;
          _isCheckingUpdate = false;
        });
      }
    } catch (e) {
      setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch all user data
      final roles = await User().getUserRoles();
      final _userName = await User().getUserName();
      final _userAccount = await User().getRoleNames();
      final _userPhoneNumber = await User().getUserPhoneNumber();
      final _userEmail = await User().getUserEmail();
      final _activeCompany = await User().getActiveCompany();

      // Try to get additional data if available
      String? _userWarehouse;
      String? _userVehicleNumber;
      int? _userId;

      try {
      } catch (e) {
        debugPrint('Optional user data not available: $e');
      }

      if (mounted) {
        setState(() {
          userRoles = roles.map((role) => role.role).toList();
          userName = _userName?.isNotEmpty == true ? _userName : 'User';
          // userAccount = _userAccount;
          userWarehouse = _userWarehouse;
          userPhoneNumber = _userPhoneNumber;
          userVehicleNumber = _userVehicleNumber;
          userEmail = _userEmail;
          userId = _userId;
          activeCompany = _activeCompany;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<List<UserCompany>> _fetchCompanyList() async {
      final apiService = Provider.of<ApiServiceInterface>(
          context, listen: false);
      final response = await apiService.companyList();
      return response;
  }

  Future<void> _switchCompany(UserCompany selectedCompany) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);

      // Call the API service method
      await apiService.switchCompany(selectedCompany.id);

      // Dismiss loading dialog
      if (mounted) Navigator.pop(context);

      // Restart app by terminating the process
      await _restartApp();
    } catch (e) {
      // Dismiss loading dialog if still showing
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch company: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }


  Future<void> _handleUpdate() async {
    setState(() => _isDownloading = true);
    try {
      await _versionManager.downloadAndInstallAPKWithProgress(context, _updateStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _restartApp() async {
    // Navigate to splash/login and clear all state
    Navigator.of(context).pushNamedAndRemoveUntil(
      'dashboard',
          (route) => false,
    );
  }

  void _showCompanySwitcher() async {
    try {
      final companies = await _fetchCompanyList();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          builder: (context) {
            return CompanySwitcherSheet(
              companies: companies,
              activeCompany: activeCompany,
              onCompanySelected: _switchCompany,
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load companies: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
            tooltip: 'Refresh Profile',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showActionMenu,
            tooltip: 'More Options',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading profile...'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 24.h),
              _buildProfileDetails(),
              SizedBox(height: 32.h),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0E5CA8),
            const Color(0xFF0E5CA8).withOpacity(0.8),
            const Color(0xFF1976D2),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5CA8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50.r,
              backgroundColor: const Color(0xFF0E5CA8),
              child: Text(
                _getInitials(userName ?? 'User'),
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // User name with company - tappable
          GestureDetector(
            onTap: _showCompanySwitcher,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      activeCompany != null
                          ? '${userName ?? 'User'} (${activeCompany!.shortCode})'
                          : userName ?? 'User',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.swap_horiz,
                    color: Colors.white.withOpacity(0.8),
                    size: 20.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account Information Section
        if (userAccount != null || userWarehouse != null || userRoles?.isNotEmpty == true || activeCompany != null) ...[
          _buildSectionHeader('Account Information'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (activeCompany != null) ...[
                    _buildInfoRow(
                      Icons.business,
                      'Company',
                      '${activeCompany!.name} (${activeCompany!.shortCode})',
                    ),
                    SizedBox(height: 16.h),
                  ],
                  if (userAccount != null) ...[
                    _buildInfoRow(
                      Icons.account_balance,
                      'Account',
                      userAccount!,
                    ),
                  ],
                  if (userWarehouse != null && userWarehouse != userAccount) ...[
                    if (userAccount != null) SizedBox(height: 16.h),
                    _buildInfoRow(
                      Icons.warehouse,
                      'Warehouse',
                      userWarehouse!,
                    ),
                  ],
                  if (userRoles?.isNotEmpty == true) ...[
                    if (userAccount != null || userWarehouse != null) SizedBox(height: 16.h),
                    _buildRolesRow(),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        // Contact Information Section
        if (userPhoneNumber != null || userEmail != null) ...[
          _buildSectionHeader('Contact Information'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (userPhoneNumber != null) ...[
                    _buildInfoRow(
                      Icons.phone,
                      'Phone Number',
                      userPhoneNumber!,
                    ),
                  ],
                  if (userEmail != null) ...[
                    if (userPhoneNumber != null) SizedBox(height: 16.h),
                    _buildInfoRow(
                      Icons.email,
                      'Email',
                      userEmail!,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        // Vehicle Information Section
        if (userVehicleNumber != null) ...[
          _buildSectionHeader('Vehicle Information'),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: _buildInfoRow(
                Icons.local_shipping,
                'Vehicle Number',
                userVehicleNumber!,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        _buildSectionHeader('App Information'),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.info,
                  'Current Version',
                  _versionManager.currentVersion ?? '1.0.0',
                ),

                if (_isCheckingUpdate)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: const CircularProgressIndicator(),
                  )
                else if (_updateStatus != null && _updateStatus!.type != UpdateType.none) ...[
                  SizedBox(height: 16.h),
                  Builder(
                    builder: (context) {
                      final hasApkUrl = _updateStatus?.apkUrl?.isNotEmpty ?? false;
                      final canDownload = !_isDownloading && hasApkUrl;

                      return InkWell(
                        onTap: canDownload ? _handleUpdate : null,
                        borderRadius: BorderRadius.circular(8.r),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: _getUpdateColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: _getUpdateColor().withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.system_update, color: _getUpdateColor()),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Version ${_updateStatus!.latestVersion}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _getUpdateColor(),
                                      ),
                                    ),
                                    Text(
                                      _getUpdateText(),
                                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isDownloading)
                                SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  hasApkUrl ? Icons.download : Icons.link_off,
                                  color: _getUpdateColor(),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 24.h,
            decoration: BoxDecoration(
              color: const Color(0xFF0E5CA8),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0E5CA8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5CA8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: const Color(0xFF0E5CA8),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4.h),
              SelectableText(
                value,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (label == 'Phone Number' || label == 'Email') ...[
          IconButton(
            onPressed: () => _copyToClipboard(value, label),
            icon: Icon(
              Icons.copy,
              size: 18.sp,
              color: Colors.grey[600],
            ),
            tooltip: 'Copy $label',
          ),
        ],
      ],
    );
  }

  Widget _buildRolesRow() {
    if (userRoles == null || userRoles!.isEmpty) {
      return _buildInfoRow(Icons.badge, 'Role', 'Not assigned');
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: const Color(0xFF0E5CA8).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.badge,
            size: 20.sp,
            color: const Color(0xFF0E5CA8),
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userRoles!.length > 1 ? 'Roles' : 'Role',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: userRoles!.map((role) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF0E5CA8).withOpacity(0.1),
                          const Color(0xFF0E5CA8).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: const Color(0xFF0E5CA8).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      role,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0E5CA8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Replace the _buildActionButtons method in your ProfileScreen

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Split buttons row
        Row(
          children: [
            // Become Partner Button
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: 6.w, bottom: 12.h),
                child: ElevatedButton.icon(
                  onPressed: _navigateToPartnerRegistration,
                  icon: const Icon(Icons.card_membership),
                  label: Text(
                    'BECOME PARTNER',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),

            // Edit Profile Button
            Expanded(
              child: Container(
                margin: EdgeInsets.only(left: 6.w, bottom: 12.h),
                child: ElevatedButton.icon(
                  onPressed: _navigateToChangePassword,
                  icon: const Icon(Icons.edit),
                  label: Text(
                    'EDIT PASSWORD',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0E5CA8),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Logout Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
            label: Text(
              'LOGOUT',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToPartnerRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PanVerificationScreen(),
      ),
    );
  }

  void _navigateToChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PasswordChangeScreen(),
      ),
    );
  }

  void _copyToClipboard(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editPassword() {
    // Navigate to edit profile screen or show edit dialog

  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(top: 12.h, bottom: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Text(
                'Profile Options',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              _buildActionMenuItem(
                Icons.edit,
                'Edit Profile',
                'Update your personal information',
                Colors.blue,
                    () {
                  Navigator.pop(context);
                  _editPassword();
                },
              ),
              _buildActionMenuItem(
                Icons.swap_horiz,
                'Switch Company',
                'Change your active company',
                Colors.purple,
                    () {
                  Navigator.pop(context);
                  _showCompanySwitcher();
                },
              ),
              _buildActionMenuItem(
                Icons.lock,
                'Change Password',
                'Update your security credentials',
                Colors.orange,
                    () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Change password feature coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildActionMenuItem(
                Icons.notifications,
                'Notification Settings',
                'Manage your notification preferences',
                Colors.purple,
                    () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings feature coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildActionMenuItem(
                Icons.help,
                'Help & Support',
                'Get assistance and support',
                Colors.green,
                    () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help & support feature coming soon'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              _buildActionMenuItem(
                Icons.logout,
                'Logout',
                'Sign out from your account',
                Colors.red,
                    () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionMenuItem(
      IconData icon,
      String title,
      String subtitle,
      Color color,
      VoidCallback onTap,
      ) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14.sp,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onLogout: _logout,
      ),
    );
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);
      await apiService.logout();

       if (mounted) {
          try {
            Navigator.of(context).pushNamedAndRemoveUntil(
              'login',
              (route) => false,
            );
          } catch (e) {
            debugPrint('Navigation error: $e');
          }
        }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  Color _getUpdateColor() {
    switch (_updateStatus?.type) {
      case UpdateType.block:
        return Colors.red;
      case UpdateType.nudge:
        return Colors.orange;
      case UpdateType.inform:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getUpdateText() {
    switch (_updateStatus?.type) {
      case UpdateType.block:
        return 'Required update - Tap to install';
      case UpdateType.nudge:
        return 'Recommended update available';
      case UpdateType.inform:
        return 'New version available';
      default:
        return '';
    }
  }
}

class CompanySwitcherSheet extends StatefulWidget {
  final List<UserCompany> companies;
  final UserCompany? activeCompany;
  final Function(UserCompany) onCompanySelected;

  const CompanySwitcherSheet({
    Key? key,
    required this.companies,
    required this.activeCompany,
    required this.onCompanySelected,
  }) : super(key: key);

  @override
  State<CompanySwitcherSheet> createState() => _CompanySwitcherSheetState();
}

class _CompanySwitcherSheetState extends State<CompanySwitcherSheet> {
  UserCompany? selectedCompany;

  @override
  void initState() {
    super.initState();
    selectedCompany = widget.activeCompany;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Title
            Text(
              'Switch Company',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0E5CA8),
              ),
            ),

            SizedBox(height: 20.h),

            // Company list
            Column(
              children: widget.companies.map((company) {
                final isSelected = selectedCompany?.id == company.id;
                final isActive = widget.activeCompany?.id == company.id;

                return Container(
                  margin: EdgeInsets.only(bottom: 12.h),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(() => selectedCompany = company),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF0E5CA8)
                                : Colors.grey[300]!,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                          color: isSelected
                              ? const Color(0xFF0E5CA8).withOpacity(0.05)
                              : Colors.white,
                        ),
                        child: Row(
                          children: [
                            Radio<UserCompany>(
                              value: company,
                              groupValue: selectedCompany,
                              onChanged: (value) => setState(() => selectedCompany = value),
                              activeColor: const Color(0xFF0E5CA8),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          company.name,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF0E5CA8)
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                      if (isActive) ...[
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12.r),
                                          ),
                                          child: Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Code: ${company.shortCode}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            SizedBox(height: 20.h),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedCompany != null && selectedCompany?.id != widget.activeCompany?.id
                        ? () {
                      Navigator.pop(context);
                      widget.onCompanySelected(selectedCompany!);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E5CA8),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      'SWITCH',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  final Future<void> Function() onLogout;

  const LogoutConfirmationDialog({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.logout, color: Colors.red, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          const Text('Confirm Logout'),
        ],
      ),
      content: const Text(
        'Are you sure you want to logout from your account? You will need to login again to access the app.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'CANCEL',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onLogout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: const Text(
            'LOGOUT',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}