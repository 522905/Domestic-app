// lib/presentation/pages/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/utils/global_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userData = {};
  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);
      final userData = await apiService.getUserProfile();

      if (mounted) {
        setState(() {
          _userData = userData;
          _userRole = userData['role'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:GlobalDrawer.getDrawer(context),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showActionMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUserProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16.sp),
          child: Column(
            crossAxisAlignment:   CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 24.h),
              _buildProfileDetails(),
              SizedBox(height: 32.h),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50.r,
            backgroundColor: const Color(0xFF0E5CA8),
            child: Text(
              _userData['name']?.substring(0, 1) ?? 'U',
              style: TextStyle(
                fontSize: 36.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            _userData['name'] ?? 'User',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _formatRole(_userRole),
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _userData['id'] ?? '',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
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
        _buildSectionHeader('Contact Information'),
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              children: [
                _buildInfoRow(Icons.email, 'Email', _userData['email'] ?? 'Not provided'),
                SizedBox(height: 12.h),
                _buildInfoRow(Icons.phone, 'Phone', _userData['phone'] ?? 'Not provided'),
              ],
            ),
          ),
        ),

        SizedBox(height: 24.h),

        if (_userData['assigned_warehouses'] != null) ...[
          _buildSectionHeader('Assigned Warehouses'),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: _buildChipList(_userData['assigned_warehouses'], Icons.warehouse),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        if (_userData['assigned_vehicles'] != null) ...[
          _buildSectionHeader('Assigned Vehicles'),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: _buildChipList(_userData['assigned_vehicles'], Icons.local_shipping),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        if (_userData['permissions'] != null) ...[
          _buildSectionHeader('Permissions'),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.sp),
              child: _buildPermissionList(_userData['permissions']),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0E5CA8),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: const Color(0xFF0E5CA8)),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChipList(List<dynamic> items, IconData icon) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: (items as List).map((item) {
        return Chip(
          avatar: Icon(icon, size: 16.sp, color: const Color(0xFF0E5CA8)),
          label: Text(item.toString()),
          backgroundColor: const Color(0xFF0E5CA8).withOpacity(0.1),
          labelStyle: TextStyle(
            color: const Color(0xFF0E5CA8),
            fontSize: 14.sp,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPermissionList(List<dynamic> permissions) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: (permissions as List).map((permission) {
        return Chip(
          avatar: Icon(
            Icons.check_circle,
            size: 16.sp,
            color: Colors.green,
          ),
          label: Text(_formatPermission(permission.toString())),
          backgroundColor: Colors.green.withOpacity(0.1),
          labelStyle: TextStyle(
            color: Colors.black87,
            fontSize: 12.sp,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _confirmLogout,
        icon: const Icon(Icons.logout),
        label: const Text('LOGOUT'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
    );
  }

  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Profile'),
                subtitle: const Text('Update your personal information'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit profile not implemented yet')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.orange),
                title: const Text('Change Password'),
                subtitle: const Text('Update your security credentials'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password not implemented yet')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.purple),
                title: const Text('Notification Settings'),
                subtitle: const Text('Manage your notification preferences'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notification settings not implemented yet')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout'),
                subtitle: const Text('Sign out from your account'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
              ),
            ],
          ),
        );
      },
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
        // Navigate to login screen and clear navigation stack
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
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

  String _formatRole(String role) {
    switch (role) {
      case 'delivery_boy':
        return 'Delivery Executive';
      case 'cse':
        return 'Customer Service Executive';
      case 'cashier':
        return 'Cashier';
      case 'warehouse_manager':
        return 'Warehouse Manager';
      case 'general_manager':
        return 'General Manager';
      default:
        return role.split('_')
            .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }

  String _formatPermission(String permission) {
    return permission.split('_')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

class LogoutConfirmationDialog extends StatelessWidget {
  final Future<void> Function() onLogout;

  const LogoutConfirmationDialog({Key? key, required this.onLogout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await onLogout();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('LOGOUT'),
        ),
      ],
    );
  }
}