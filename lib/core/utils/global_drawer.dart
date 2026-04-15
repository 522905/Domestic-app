// GlobalDrawer
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../presentation/widgets/professional_snackbar.dart';
import '../../presentation/routes/app_routes.dart';
import '../../core/services/api_service.dart';
import '../../core/services/User.dart';
import '../../core/constants/app_colors_enhanced.dart';
import '../../core/constants/spacing.dart';
import '../../core/constants/text_styles.dart';
import '../../presentation/blocs/vehicle/vehicle_bloc.dart';
import '../../presentation/blocs/vehicle/vehicle_event.dart';
import '../../presentation/blocs/orders/orders_bloc.dart';
import '../../presentation/blocs/orders/orders_event.dart';
import '../../presentation/blocs/inventory/inventory_bloc.dart';
import '../../presentation/blocs/inventory/inventory_event.dart';
import '../../presentation/blocs/sdms_claims/sdms_claims_bloc.dart';
import '../../presentation/blocs/sdms_claims/sdms_claims_event.dart';
// Hidden for release build - Digital Credit not ready
// import '../../presentation/blocs/digital_credit/digital_credit_bloc.dart';
// import '../../presentation/blocs/digital_credit/digital_credit_event.dart';
import '../../presentation/blocs/quota_history/quota_history_bloc.dart';
import '../../presentation/pages/quota/quota_history_page.dart';
import '../services/service_provider.dart';

class GlobalDrawer {
  static ApiService? _apiService;
  static BuildContext? navigatorContext;
  static Set<String>? _cachedUserRoles;

  static void initialize(ApiService apiService) {
    _apiService = apiService;
  }

  // Remove the static ValueNotifier - this was the core problem
  static Drawer getDrawer(BuildContext context, {Set<String>? userRoles}) {
    navigatorContext = context;
    if (userRoles != null) {
      _cachedUserRoles = userRoles;
    }

    // Build menu items dynamically based on userRoles
    List<Widget> menuItems = _buildMenuItems(_cachedUserRoles);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _UserProfileHeader(),
          ...menuItems,
        ],
      ),
    );
  }

  static List<Widget> _buildMenuItems(Set<String>? userRoles) {
    List<Widget> items = [
      // ListTile(
      //   leading: const Icon(Icons.report),
      //   title: const Text('Reports'),
      //   onTap: () {
      //     Navigator.push(
      //       navigatorContext!,
      //       MaterialPageRoute(builder: (context) => const ReportScreen()),
      //     );
      //   },
      // ),
      // My Bonuses - temporarily hidden
      // ListTile(
      //   leading: const Icon(Icons.card_giftcard),
      //   title: const Text('My Bonuses'),
      //   onTap: () {
      //     Navigator.pushNamed(navigatorContext!, '/bonus-list');
      //   },
      // ),

      // SDMS Claims menu item
      ListTile(
        leading: const Icon(Icons.receipt_long),
        title: const Text('SDMS Claims'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/sdms-claims');
        },
      ),

      ListTile(
        leading: const Icon(Icons.inventory_2),
        title: const Text('Stock Report'),
        onTap: () async {
          final apiService = await ServiceProvider.getApiService();
          if (navigatorContext != null && navigatorContext!.mounted) {
            // Fetch quota snapshot to get all available items for filter chips
            Map<String, String>? availableItems;
            try {
              final snapshot = await apiService.getQuotaSnapshot();
              if (snapshot.items.isNotEmpty) {
                availableItems = {};
                for (final item in snapshot.items) {
                  availableItems[item.itemCode] = item.itemName;
                }
              }
            } catch (e) {
              // If fetch fails, chips will load dynamically
              availableItems = null;
            }

            if (navigatorContext!.mounted) {
              Navigator.push(
                navigatorContext!,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => QuotaHistoryBloc(
                      apiService: apiService,
                      initialItemCode: 'M00087', // Default filter to 14.2 KG Cylinder
                    ),
                    child: QuotaHistoryPage(
                      pageTitle: 'Stock Report',
                      initialAvailableItems: availableItems,
                    ),
                  ),
                ),
              );
            }
          }
        },
      ),
      // My Installations menu item
      ListTile(
        leading: const Icon(Icons.home_work_outlined),
        title: const Text('My Installations'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/ujjwala/my-installations');
        },
      ),

      // Ujjwala Installation menu item
      ListTile(
        leading: const Icon(Icons.home_work),
        title: const Text('Ujjwala Installation'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/ujjwala-installations');
        },
      ),

      // Offline Delivery - only for users with 'Offline Delivery' role
      if (userRoles?.contains('Offline Delivery') == true)
        ListTile(
          leading: const Icon(Icons.local_shipping),
          title: const Text('Offline Delivery'),
          onTap: () {
            Navigator.pushNamed(navigatorContext!, '/offline-delivery');
          },
        ),

      // Scan Token - available to all users
      ListTile(
        leading: const Icon(Icons.qr_code_scanner),
        title: const Text('Scan Token'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/scan-token');
        },
      ),

      // Booking menu item
      ListTile(
        leading: const Icon(Icons.book_outlined),
        title: const Text('Booking'),
        onTap: () {
          Navigator.pushNamed(navigatorContext!, '/offline-booking');
        },
      ),



      // ListTile(
      //   leading: const Icon(Icons.add_box_sharp),
      //   title: const Text('SDMS Transactions'),
      //
      //   onTap: () {
      //     Navigator.push(
      //       navigatorContext!,
      //       MaterialPageRoute(
      //           builder: (context) => const SDMSTransactionListPage(),
      //     ),
      //     );
      //   },
      // ),

      ListTile(
        leading: const Icon(Icons.settings),
        title: const Text('Settings'),
        onTap: () {
          // Add navigation logic for Settings
        },
      ),

      // Hidden for release build - Digital Credit not ready
      // ListTile(
      //   leading: const Icon(Icons.payment),
      //   title: const Text('Digital Credits'),
      //   onTap: () {
      //     Navigator.push(
      //       navigatorContext!,
      //       MaterialPageRoute(
      //         builder: (context) => const DigitalCreditsListPage(),
      //       ),
      //     );
      //   },
      // ),
    ];

    // Add role-specific items
    // if (userRoles?.contains('Delivery Boy') != true) {
    //   items.add(
    //     ListTile(
    //       leading: const Icon(Icons.inventory_2_sharp),
    //       title: const Text('Procurement'),
    //       onTap: () {
    //         Navigator.push(
    //           navigatorContext!,
    //           MaterialPageRoute(
    //             builder: (context) => const PurchaseInvoiceScreen(),
    //           ),
    //         );
    //       },
    //     ),
    //   );
    // }

    // Add logout at the end
    items.add(
      ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Logout'),
        onTap: () {
          if (navigatorContext != null) {
            _confirmLogout(navigatorContext!);
          }
        },
      ),
    );

    return items;
  }

  static void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogoutConfirmationDialog(
        onLogout: () => _logout(context),
      ),
    );
  }

  static Future<void> _logout(BuildContext context) async {
    try {
      // Clear all BLoC caches first
      context.read<VehicleBloc>().add(const ClearVehicleCache());
      context.read<OrdersBloc>().add(const ClearOrdersCache());
      context.read<InventoryBloc>().add(const ClearInventoryCache());
      context.read<SdmsClaimsBloc>().add(const ClearSdmsClaimsCache());
      // Hidden for release build - Digital Credit not ready
      // context.read<DigitalCreditBloc>().add(const ClearDigitalCreditCache());

      // Clear all cached data from secure storage
      if (_apiService != null) {
        await _apiService!.logout();
      }

      // Navigate to login and remove all previous routes
      Navigator.pushNamedAndRemoveUntil(
        context,
        'login',
            (route) => false,
      );
    } catch (e) {
      context.showInfoSnackBar('Error logging out: $e');
    }
  }
}

// Logout Confirmation Dialog
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
        'Are you sure you want to logout?',
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

// User Profile Header Widget
class _UserProfileHeader extends StatefulWidget {
  const _UserProfileHeader({Key? key}) : super(key: key);

  @override
  State<_UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<_UserProfileHeader> {
  String? _userName;
  String? _photoUrl;
  String? _userRole;
  bool _isLoading = true;
  bool _imageLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userName = await User().getUserName();
      final photoUrl = await User().getPhotoUrl();
      final roles = await User().getUserRoles();

      if (mounted) {
        setState(() {
          _userName = userName;
          _photoUrl = photoUrl;
          _userRole = roles.isNotEmpty ? roles.first.role : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildAvatar() {
    final displayName = _userName ?? 'User';
    final hasPhotoUrl = _photoUrl != null &&
        _photoUrl!.isNotEmpty &&
        !_imageLoadError;

    return CircleAvatar(
      radius: 40.r,
      backgroundColor: AppColorsEnhanced.brandBlue,
      backgroundImage: hasPhotoUrl ? NetworkImage(_photoUrl!) : null,
      onBackgroundImageError: hasPhotoUrl
          ? (exception, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _imageLoadError = true);
                }
              });
            }
          : null,
      child: !hasPhotoUrl
          ? Text(
              _getInitials(displayName),
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return DrawerHeader(
        decoration: BoxDecoration(
          color: AppColorsEnhanced.brandBlue,
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return DrawerHeader(
      decoration: BoxDecoration(
        color: AppColorsEnhanced.brandBlue,
      ),
      child: InkWell(
        onTap: () {
          Navigator.pop(context); // Close drawer
          Navigator.pushNamed(context, AppRoutes.profile);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            _buildAvatar(),

            SizedBox(width: AppSpacing.md),

            // User Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Name
                  Text(
                    _userName ?? 'User',
                    style: AppTextStyles.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: AppSpacing.xs),

                  // Role Badge
                  if (_userRole != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        _userRole!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Chevron icon to indicate it's tappable
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}