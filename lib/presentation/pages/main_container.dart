// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/dashboard/dashboard_screen.dart';
// import 'package:lpg_distribution_app/presentation/pages/profile/profile_screen.dart';
// import 'package:lpg_distribution_app/presentation/pages/orders/orders_page.dart';
// import 'package:lpg_distribution_app/presentation/widgets/version/version_update_widgets.dart';
// import '../../core/services/version_manager.dart';
// import 'inventory/inventory_screen.dart';
//
// class MainContainer extends StatefulWidget {
//   final int initialTab;
//
//   const MainContainer({Key? key, this.initialTab = 0}) : super(key: key);
//
//   @override
//   State<MainContainer> createState() => _MainContainerState();
// }
//
// class _MainContainerState extends State<MainContainer> with WidgetsBindingObserver {
//   late int _currentIndex;
//   final _versionManager = VersionManager();
//   UpdateStatus? _updateStatus;
//   bool _showBanner = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentIndex = widget.initialTab; // Use initial tab from constructor
//     WidgetsBinding.instance.addObserver(this);
//
//     _versionManager.onStatusChanged = (status) {
//       setState(() {
//         _updateStatus = status;
//         _showBanner = status.type == UpdateType.inform;
//       });
//     };
//
//     _checkVersion();
//   }
//
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }
//
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       _checkVersion();
//     }
//   }
//
//   Future<void> _checkVersion() async {
//     await _versionManager.checkVersionViaAPI();
//   }
//
//   void _startDownload() async {
//     try {
//       // If no APK URL, fetch full config first
//       if (_updateStatus?.apkUrl == null) {
//         final fullStatus = await _versionManager.checkVersionViaAPI();
//         if (fullStatus.type != UpdateType.none && fullStatus.apkUrl != null) {
//           setState(() {
//             _updateStatus = fullStatus;
//           });
//           await _versionManager.downloadAndInstallAPKWithProgress(context, fullStatus);
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Unable to get download URL')),
//           );
//         }
//       } else {
//         await _versionManager.downloadAndInstallAPKWithProgress(context, _updateStatus);
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Download failed: $e')),
//       );
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: _currentIndex,
//         children: const [
//           DashboardScreen(),
//           OrdersPage(),
//           CashPage(),
//           InventoryPage(),
//           ProfileScreen(),
//         ],
//       ),
//       bottomNavigationBar: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Update banner above navigation
//           if (_showBanner && _updateStatus != null)
//             UpdateBanner(
//               status: _updateStatus!,
//               onDownload: _startDownload,
//               onDismiss: () {
//                 setState(() {
//                   _showBanner = false;
//                 });
//               },
//             ),
//
//           // Navigation bar
//           BottomNavigationBar(
//             currentIndex: _currentIndex,
//             onTap: (index) {
//               setState(() {
//                 _currentIndex = index;
//               });
//             },
//             type: BottomNavigationBarType.fixed,
//             selectedItemColor: const Color(0xFF0E5CA8),
//             unselectedItemColor: Colors.grey,
//             selectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
//             unselectedLabelStyle: TextStyle(fontSize: 12.sp),
//             items: const [
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.home),
//                 label: 'Home',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.receipt_long),
//                 label: 'Orders',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.account_balance_wallet),
//                 label: 'Cash',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.inventory),
//                 label: 'Inventory',
//               ),
//               BottomNavigationBarItem(
//                 icon: Icon(Icons.person),
//                 label: 'Profile',
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
import 'package:lpg_distribution_app/presentation/pages/dashboard/dashboard_screen.dart';
import 'package:lpg_distribution_app/presentation/pages/profile/profile_screen.dart';
import 'package:lpg_distribution_app/presentation/pages/orders/orders_page.dart';
import 'package:lpg_distribution_app/presentation/widgets/version/version_update_widgets.dart';
import '../../core/services/version_manager.dart';
import 'inventory/inventory_screen.dart';

class MainContainer extends StatefulWidget {
  final int initialTab;

  const MainContainer({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late int _currentIndex;
  final _versionManager = VersionManager();
  UpdateStatus? _updateStatus;
  bool _showBanner = false;

  // One controller per tab to allow replay on re-select
  late final List<AnimationController> _iconCtrls;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;

    _iconCtrls = List.generate(
      5,
          (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      ),
    );

    WidgetsBinding.instance.addObserver(this);

    _versionManager.onStatusChanged = (status) {
      setState(() {
        _updateStatus = status;
        _showBanner = status.type == UpdateType.inform;
      });
    };

    _checkVersion();
  }

  @override
  void dispose() {
    for (final c in _iconCtrls) {
      c.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVersion();
    }
  }

  Future<void> _checkVersion() async {
    await _versionManager.checkVersionViaAPI();
  }

  void _startDownload() async {
    try {
      if (_updateStatus?.apkUrl == null) {
        final fullStatus = await _versionManager.checkVersionViaAPI();
        if (fullStatus.type != UpdateType.none && fullStatus.apkUrl != null) {
          setState(() {
            _updateStatus = fullStatus;
          });
          await _versionManager
              .downloadAndInstallAPKWithProgress(context, fullStatus);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to get download URL')),
          );
        }
      } else {
        await _versionManager
            .downloadAndInstallAPKWithProgress(context, _updateStatus!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardScreen(),
          OrdersPage(),
          CashPage(),
          InventoryPage(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showBanner && _updateStatus != null)
            UpdateBanner(
              status: _updateStatus!,
              onDownload: _startDownload,
              onDismiss: () {
                setState(() {
                  _showBanner = false;
                });
              },
            ),

          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              // Replay animation even if tapping the already-selected tab
              _iconCtrls[index].forward(from: 0);
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF0E5CA8),
            unselectedItemColor: Colors.grey,
            selectedLabelStyle:
            TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(fontSize: 12.sp),
            items: [
              BottomNavigationBarItem(
                label: 'Home',
                icon: _AnimatedTabIcon(
                  selected: _currentIndex == 0,
                  fallbackIcon: Icons.home_outlined,
                  lottieAsset: 'assets/lottie/home.json',
                  controller: _iconCtrls[0],
                ),
                activeIcon: _AnimatedTabIcon(
                  selected: true,
                  fallbackIcon: Icons.home,
                  lottieAsset: 'assets/lottie/home.json',
                  controller: _iconCtrls[0],
                ),
              ),
              BottomNavigationBarItem(
                label: 'Orders',
                icon: _AnimatedTabIcon(
                  selected: _currentIndex == 1,
                  fallbackIcon: Icons.receipt_long_outlined,
                  lottieAsset: 'assets/lottie/orders.json',
                  controller: _iconCtrls[1],
                ),
                activeIcon: _AnimatedTabIcon(
                  selected: true,
                  fallbackIcon: Icons.receipt_long,
                  lottieAsset: 'assets/lottie/orders.json',
                  controller: _iconCtrls[1],
                ),
              ),
              BottomNavigationBarItem(
                label: 'Cash',
                icon: _AnimatedTabIcon(
                  selected: _currentIndex == 2,
                  fallbackIcon: Icons.account_balance_wallet_outlined,
                  lottieAsset: 'assets/lottie/cash.json',
                  controller: _iconCtrls[2],
                ),
                activeIcon: _AnimatedTabIcon(
                  selected: true,
                  fallbackIcon: Icons.account_balance_wallet,
                  lottieAsset: 'assets/lottie/cash.json',
                  controller: _iconCtrls[2],
                ),
              ),
              BottomNavigationBarItem(
                label: 'Inventory',
                icon: _AnimatedTabIcon(
                  selected: _currentIndex == 3,
                  fallbackIcon: Icons.inventory_2_outlined,
                  lottieAsset: 'assets/lottie/inventory.json',
                  controller: _iconCtrls[3],
                ),
                activeIcon: _AnimatedTabIcon(
                  selected: true,
                  fallbackIcon: Icons.inventory,
                  lottieAsset: 'assets/lottie/inventory.json',
                  controller: _iconCtrls[3],
                ),
              ),
              BottomNavigationBarItem(
                label: 'Profile',
                icon: _AnimatedTabIcon(
                  selected: _currentIndex == 4,
                  fallbackIcon: Icons.person_outline,
                  lottieAsset: 'assets/lottie/profile.json',
                  controller: _iconCtrls[4],
                ),
                activeIcon: _AnimatedTabIcon(
                  selected: true,
                  fallbackIcon: Icons.person,
                  lottieAsset: 'assets/lottie/profile.json',
                  controller: _iconCtrls[4],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Internal: tab icon that plays a Lottie clip when selected.
/// When unselected, shows the fallback Material icon.
/// - We keep size small to avoid baseline jumps.
/// - We don't auto-animate; we drive via the provided controller so we can replay.
class _AnimatedTabIcon extends StatelessWidget {
  final bool selected;
  final IconData fallbackIcon;
  final String lottieAsset;
  final AnimationController controller;

  const _AnimatedTabIcon({
    required this.selected,
    required this.fallbackIcon,
    required this.lottieAsset,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (!selected) {
      return AnimatedOpacity(
        opacity: 0.7,
        duration: const Duration(milliseconds: 150),
        child: Icon(fallbackIcon),
      );
    }

    return SizedBox(
      height: 28,
      width: 28,
      child: Lottie.asset(
        lottieAsset,
        controller: controller,
        onLoaded: (comp) {
          // Ensure we match the composition duration for smooth playback
          controller.duration = comp.duration;
          if (controller.status != AnimationStatus.forward &&
              controller.status != AnimationStatus.reverse) {
            controller.forward(from: 0);
          }
        },
        repeat: false,
        animate: false, // we manually drive it
      ),
    );
  }
}
