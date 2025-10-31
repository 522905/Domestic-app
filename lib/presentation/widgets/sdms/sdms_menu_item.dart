// // lib/presentation/widgets/sdms/sdms_menu_item.dart
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import '../../blocs/sdms/create/sdms_create_bloc.dart';
// import '../../blocs/sdms/transaction/sdms_transaction_bloc.dart';
// import '../../pages/sdms/sdms_transaction_list_page.dart';
// import '../../../core/services/api_service_interface.dart';
//
// class SDMSMenuItem extends StatelessWidget {
//   const SDMSMenuItem({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Container(
//         padding: EdgeInsets.all(8.w),
//         decoration: BoxDecoration(
//           color: const Color(0xFF0E5CA8).withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8.r),
//         ),
//         child: Icon(
//           Icons.integration_instructions,
//           color: const Color(0xFF0E5CA8),
//           size: 24.sp,
//         ),
//       ),
//       title: Text(
//         'SDMS Transactions',
//         style: TextStyle(
//           fontSize: 16.sp,
//           fontWeight: FontWeight.w500,
//           color: const Color(0xFF333333),
//         ),
//       ),
//       subtitle: Text(
//         'Manage invoice assignments and credit payments',
//         style: TextStyle(
//           fontSize: 12.sp,
//           color: Colors.grey[600],
//         ),
//       ),
//       trailing: Icon(
//         Icons.arrow_forward_ios,
//         size: 16.sp,
//         color: Colors.grey[400],
//       ),
//       onTap: () => _navigateToSDMSTransactions(context),
//     );
//   }
//
//   void _navigateToSDMSTransactions(BuildContext context) {
//     // Close the drawer
//     Navigator.of(context).pop();
//
//     // Navigate to SDMS transactions with proper BLoC providers
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => MultiBlocProvider(
//           providers: [
//             BlocProvider<SDMSTransactionBloc>(
//               create: (context) => SDMSTransactionBloc(
//                 apiService: getIt<ApiServiceInterface>(), // Assuming you use GetIt
//               ),
//             ),
//             BlocProvider<SDMSCreateBloc>(
//               create: (context) => SDMSCreateBloc(
//                 apiService: getIt<ApiServiceInterface>(),
//               ),
//             ),
//           ],
//           child: const SDMSTransactionListPage(),
//         ),
//       ),
//     );
//   }
// }
//
// // Alternative simple widget if you don't have dependency injection setup
// class SimpleSDMSMenuItem extends StatelessWidget {
//   final ApiServiceInterface apiService;
//
//   const SimpleSDMSMenuItem({
//     Key? key,
//     required this.apiService,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: Container(
//         padding: EdgeInsets.all(8.w),
//         decoration: BoxDecoration(
//           color: const Color(0xFF0E5CA8).withOpacity(0.1),
//           borderRadius: BorderRadius.circular(8.r),
//         ),
//         child: Icon(
//           Icons.integration_instructions,
//           color: const Color(0xFF0E5CA8),
//           size: 24.sp,
//         ),
//       ),
//       title: Text(
//         'SDMS Transactions',
//         style: TextStyle(
//           fontSize: 16.sp,
//           fontWeight: FontWeight.w500,
//           color: const Color(0xFF333333),
//         ),
//       ),
//       subtitle: Text(
//         'Manage invoice assignments and credit payments',
//         style: TextStyle(
//           fontSize: 12.sp,
//           color: Colors.grey[600],
//         ),
//       ),
//       trailing: Icon(
//         Icons.arrow_forward_ios,
//         size: 16.sp,
//         color: Colors.grey[400],
//       ),
//       onTap: () => _navigateToSDMSTransactions(context),
//     );
//   }
//
//   void _navigateToSDMSTransactions(BuildContext context) {
//     // Close the drawer
//     Navigator.of(context).pop();
//
//     // Navigate to SDMS transactions with proper BLoC providers
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => MultiBlocProvider(
//           providers: [
//             BlocProvider<SDMSTransactionBloc>(
//               create: (context) => SDMSTransactionBloc(apiService: apiService),
//             ),
//             BlocProvider<SDMSCreateBloc>(
//               create: (context) => SDMSCreateBloc(apiService: apiService),
//             ),
//           ],
//           child: const SDMSTransactionListPage(),
//         ),
//       ),
//     );
//   }
// }
