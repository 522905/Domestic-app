// lib/presentation/widgets/profile/profile_action_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  ProfileAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class ProfileActionDialog extends StatelessWidget {
  final List<ProfileAction> actions;

  const ProfileActionDialog({
    Key? key,
    required this.actions,
  }) : super(key: key);

  static void show(BuildContext context, List<ProfileAction> actions) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) => ProfileActionDialog(actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    'Profile Actions',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: action.color.withOpacity(0.1),
                      child: Icon(action.icon, color: action.color),
                    ),
                    title: Text(action.title),
                    subtitle: Text(action.subtitle),
                    onTap: () {
                      Navigator.of(context).pop();
                      action.onTap();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Usage Example:
void showProfileActions(BuildContext context) {
  ProfileActionDialog.show(
    context,
    [
      ProfileAction(
        title: 'Edit Profile',
        subtitle: 'Update your personal information',
        icon: Icons.edit,
        color: Colors.blue,
        onTap: () {
          // Navigate to edit profile screen
        },
      ),
      ProfileAction(
        title: 'Change Password',
        subtitle: 'Update your security credentials',
        icon: Icons.lock,
        color: Colors.orange,
        onTap: () {
          // Navigate to change password screen
        },
      ),
      ProfileAction(
        title: 'Notification Settings',
        subtitle: 'Manage your notification preferences',
        icon: Icons.notifications,
        color: Colors.purple,
        onTap: () {
          // Navigate to notification settings
        },
      ),
      ProfileAction(
        title: 'Help & Support',
        subtitle: 'Get assistance with the app',
        icon: Icons.help,
        color: Colors.green,
        onTap: () {
          // Navigate to help & support
        },
      ),
      ProfileAction(
        title: 'Logout',
        subtitle: 'Sign out from your account',
        icon: Icons.logout,
        color: Colors.red,
        onTap: () {
          // Show logout confirmation
        },
      ),
    ],
  );
}