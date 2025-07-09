// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:lpg_distribution_app/presentation/blocs/cash/cash_bloc.dart';
// import 'package:lpg_distribution_app/presentation/blocs/order_form/order_form_bloc.dart';
// import 'package:lpg_distribution_app/presentation/blocs/orders/orders_bloc.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/cash_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/deposit_details_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/forms/add_bank_transaction_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/forms/add_deposit_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/cash/forms/add_handover_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/login_screen.dart';
// import 'package:lpg_distribution_app/presentation/pages/main_container.dart';
// import 'package:lpg_distribution_app/presentation/pages/orders/create_order_page.dart';
// import 'package:lpg_distribution_app/presentation/pages/splash_screen.dart';
// import 'package:provider/provider.dart';
// import 'package:lpg_distribution_app/core/services/api_service_interface.dart';
//
// import '../pages/cash/forms/cash_deposit_page.dart';
// import '../pages/inventory/inventory_request_detials_screen.dart';
//
// class AppRoutes {
//   static Map<String, WidgetBuilder> getRoutes(BuildContext context) {
//     return {
//       '/': (context) => const SplashScreen(),
//       '/login': (context) => const LoginScreen(),
//       '/dashboard': (context) => const MainContainer(),
//
//       // Orders routes
//       '/orders/create': (context) => BlocProvider.value(
//         value: BlocProvider.of<OrdersBloc>(context),
//         child: BlocProvider.value(
//           value: BlocProvider.of<OrderFormBloc>(context),
//           child: const CreateOrderPage(),
//         ),
//       ),
//
//       '/cash/deposit': (context) => const CashDepositPage(),
//
//       // Cash management routes
//       '/cash': (context) => BlocProvider(
//         create: (context) => CashManagementBloc(
//           apiService: Provider.of<ApiServiceInterface>(context, listen: false),
//         )..add(LoadCashData()),
//         child: const CashPage(),
//       ),
//
//       '/cash/add_deposit': (context) => BlocProvider.value(
//         value: BlocProvider.of<CashManagementBloc>(context),
//         child: const AddDepositPage(),
//       ),
//
//       '/cash/add_handover': (context) => BlocProvider.value(
//         value: BlocProvider.of<CashManagementBloc>(context),
//         child: const AddHandoverPage(),
//       ),
//
//       '/cash/add_bank_transaction': (context) => BlocProvider.value(
//         value: BlocProvider.of<CashManagementBloc>(context),
//         child: const AddBankTransactionPage(),
//       ),
//
//       '/cash/deposit_details': (context) => BlocProvider.value(
//         value: BlocProvider.of<CashManagementBloc>(context),
//         child: const DepositDetailsPage(),
//       ),
//     };
//   }
// }