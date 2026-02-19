import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import '../pages/cash/cash_transaction_detail_screen.dart';
import '../pages/inventory/forms/collect_inventory_request_screen.dart';
import '../pages/inventory/forms/deposit_inventory_request_screen.dart';
import '../pages/login/login_screen.dart';
import '../pages/main_container.dart';
import '../pages/orders/forms/create_sale_order_page.dart';
import '../pages/orders/order_details_page.dart'; // Add import
import '../pages/cash/forms/cash_deposit_page.dart';
import '../pages/inventory/inventory_detail_screen.dart'; // Add import
import '../pages/defect_inspection/dir_creation_screen.dart';
import '../pages/defect_inspection/dir_list_screen.dart';
import '../pages/defect_inspection/dir_detail_screen.dart';
import '../pages/purchase_invoice/purchase_invoice_details_screen.dart';
import '../pages/purchase_invoice/purchase_invoice_screen.dart';
import '../pages/digital_credit/digital_credits_list_page.dart';
import '../pages/digital_credit/credit_detail_page.dart';
import '../pages/sdms_claims/sdms_claims_main_page.dart';
import '../pages/sdms_claims/order_entry_page.dart';
import '../pages/sdms_claims/order_detail_page.dart';
import '../pages/quota/quota_snapshot_page.dart';
import '../pages/bonus/bonus_schemes_page.dart';
import '../pages/bonus/bonus_list_page.dart';
import '../pages/bonus/bonus_detail_page.dart';
import '../blocs/orders/orders_bloc.dart';
import '../blocs/digital_credit/digital_credit_bloc.dart';
import '../blocs/sdms_claims/sdms_claims_bloc.dart';
import '../blocs/bonus_schemes/bonus_schemes_bloc.dart';
import '../blocs/bonus_schemes/bonus_schemes_event.dart';
import '../blocs/bonus_list/bonus_list_bloc.dart';
import '../blocs/bonus_list/bonus_list_event.dart';
import '../blocs/bonus_detail/bonus_detail_bloc.dart';
import '../blocs/bonus_detail/bonus_detail_event.dart';
import '../blocs/inventory/inventory_bloc.dart';
import '../blocs/defect_inspection/defect_inspection_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../core/services/User.dart';
import '../widgets/professional_snackbar.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String cash = 'cash';
  static const String orders = 'orders';
  static const String inventory = 'inventory';
  static const String cashDeposit = 'cash/deposit';
  static const String ordersCreate = 'orders/create';
  static const String inventoryCreate = 'inventory/create';

  // Defect Inspection routes
  static const String defectsPurchaseInvoices = 'defects/purchase-invoices';
  static const String defectsCreate = 'defects/create';
  static const String defectsInspections = 'defects/inspections';

  // Procurement/Purchase Invoice routes
  static const String procurementInvoiceDetail = 'procurement-invoice';

  // Digital Credit routes
  static const String digitalCredits = 'digital-credits';
  static const String digitalCreditDetail = 'digital-credit';

  // Quota routes
  static const String quota = 'quota';

  // Bonus routes
  static const String bonusSchemes = 'bonus-schemes';
  static const String bonusList = 'bonus-list';
  static const String bonusDetail = 'bonus-detail';

  // Profile route
  static const String profile = '/profile';

  // Company-aware navigation handler
  static Future<void> navigateWithCompanyCheck(
      BuildContext context,
      String fullRoute,
      ) async {
    final routeParts = fullRoute.split('/');

    if (routeParts.length < 4 || routeParts[1].toLowerCase() != 'company') {
      Navigator.pushNamed(context, fullRoute);
      return;
    }

    final targetCompanyCode = routeParts[2];
    final targetRoute = routeParts.sublist(3).join('/');

    final currentCompany = await User().getActiveCompany();

    if (currentCompany?.shortCode == targetCompanyCode) {
      Navigator.pushNamed(context, '/$targetRoute');
      return;
    }

    final shouldSwitch = await _showCompanySwitchDialog(
      context,
      targetCompanyCode,
      targetRoute,
    );

    if (!shouldSwitch) return;

    final apiService = context.read<ApiServiceInterface>();
    final companies = await apiService.companyList();

    final targetCompany = companies.firstWhere(
          (c) => c.shortCode == targetCompanyCode,
      orElse: () => throw Exception('Company $targetCompanyCode not found'),
    );

    await _switchCompanyWithoutRestart(context, apiService, targetCompany, targetRoute);
  }

  static Future<bool> _showCompanySwitchDialog(
      BuildContext context,
      String targetCompanyCode,
      String targetRoute,
      ) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0E5CA8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.swap_horiz, color: Color(0xFF0E5CA8), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Switch Company?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This notification is for $targetCompanyCode.', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Switch to $targetCompanyCode and continue?', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E5CA8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('SWITCH', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  static Future<void> _switchCompanyWithoutRestart(
      BuildContext context,
      ApiServiceInterface apiService,
      UserCompany targetCompany,
      String targetRoute,
      ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await apiService.switchCompany(targetCompany.id);

      if (context.mounted) Navigator.pop(context); // Dismiss loading

      // Clear stack and rebuild dashboard with new company data
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/dashboard',
              (route) => false,
        );

        // Small delay to let dashboard mount
        await Future.delayed(const Duration(milliseconds: 150));

        if (context.mounted) {
          Navigator.pushNamed(context, '/$targetRoute');
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        context.showErrorSnackBar('Failed to switch company: $e');
      }
      rethrow;
    }
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final segments = uri.pathSegments;

    // Login
    if (settings.name == "login") {
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    }

    // Dashboard
    if (settings.name == "dashboard") {
      return MaterialPageRoute(builder: (_) => const MainContainer());
    }

    // Tab routes - navigate to MainContainer with tab index
    if (segments.isEmpty) {
      return MaterialPageRoute(builder: (_) => const MainContainer());
    }

    switch (segments[0]) {
    // ORDERS
      case 'order':
        if (segments.length == 1) {
          return MaterialPageRoute(
            builder: (_) => const MainContainer(initialTab: 1),
          );
        }
        else if (segments[1] == 'create') {
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<OrdersBloc>(context),
              child: const CreateSaleOrderScreen(),
            ),
          );
        }
        else {
          final orderId = segments[1];
          return MaterialPageRoute(
            builder: (_) => OrderDetailsPage(orderId: orderId),  // Clean!
          );
        }

    // CASH
      case 'cash':
        if (segments.length == 1) {
          // /cash → MainContainer with cash tab
          return MaterialPageRoute(
            builder: (_) => const MainContainer(initialTab: 2),
          );
        } else if (segments[1] == 'deposit') {
          // /cash/deposit
          return MaterialPageRoute(builder: (_) => CashDepositPage());
        } else {
          // /cash/3 → Transaction details
          final transactionId = segments[1];
          return MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              transactionId: transactionId,
              canApprove: true,
            ),
          );
        }

    // INVENTORY
      case 'inventory':
        if (segments.length == 1) {
          return MaterialPageRoute(
            builder: (_) => const MainContainer(initialTab: 3),
          );
        } else if (segments[1] == 'collect') {
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<InventoryBloc>(context),
              child: const CollectInventoryScreen(),
            ),
          );
        }  else if (segments[1] == 'deposit') {
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<InventoryBloc>(context),
              child: const DepositInventoryScreen(
                depositType: "sales_order",
              ),
            ),
          );
        }
        else {
          // /inventory/3
          final requestId = segments[1];
          return MaterialPageRoute(
            builder: (context) => FutureBuilder<List<String>>(
              future: User().getUserRoles().then((roles) => roles.map((r) => r.role).toList()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Loading...'),
                      backgroundColor: const Color(0xFF0E5CA8),
                      foregroundColor: Colors.white,
                    ),
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }

                final userRoles = snapshot.data ?? [];
                return InventoryDetailScreen(
                  requestId: requestId,
                  userRole: userRoles,  // Pass List<String> not String
                  showApprovalButtons: true,
                );
              },
            ),
          );
        }

    // DEFECT INSPECTION
      case 'defects':
        if (segments.length == 1) {
          // /defects → DIR List
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<DefectInspectionBloc>(context),
              child: const DIRListScreen(),
            ),
          );
        } else if (segments[1] == 'create') {
          // /defects/create
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<DefectInspectionBloc>(context),
              child: const DIRCreationScreen(),
            ),
          );
        } else if (segments[1] == 'inspections') {
          if (segments.length == 2) {
            // /defects/inspections → DIR List
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<DefectInspectionBloc>(context),
                child: const DIRListScreen(),
              ),
            );
          } else {
            // /defects/inspections/DIR-REP-2025-00042 → DIR Detail
            final dirName = segments.sublist(2).join('/');
            return MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: BlocProvider.of<DefectInspectionBloc>(context),
                child: DIRDetailScreen(dirName: dirName),
              ),

            );
          }
        } else {
          return _errorRoute();
        }

    // PROCUREMENT/PURCHASE INVOICE
      case 'procurement':
        // /procurement → Opens Purchase Invoice List Screen
        return MaterialPageRoute(
          builder: (_) => const PurchaseInvoiceScreen(),
        );

    // DIGITAL CREDITS
      case 'digital-credits':
        if (segments.length == 1) {
          // /digital-credits → Digital Credits List with optional initialTab query param
          final initialTab = int.tryParse(uri.queryParameters['tab'] ?? '0') ?? 0;
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<DigitalCreditBloc>(context),
              child: DigitalCreditsListPage(initialTab: initialTab),
            ),
          );
        }
        return _errorRoute();

      case 'digital-credit':
        if (segments.length == 2) {
          // /digital-credit/abc123 → Credit Detail
          final creditId = segments[1];
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<DigitalCreditBloc>(context),
              child: CreditDetailPage(creditId: creditId),
            ),
          );
        }
        return _errorRoute();

      // SDMS CLAIMS ROUTES
      case 'sdms-claims':
        if (segments.length == 1) {
          // /sdms-claims → Main tabbed page
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<SdmsClaimsBloc>(context),
              child: const SdmsClaimsMainPage(),
            ),
          );
        } else if (segments[1] == 'entry') {
          // /sdms-claims/entry → Order Entry Page
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<SdmsClaimsBloc>(context),
              child: const OrderEntryPage(),
            ),
          );
        } else if (segments[1] == 'order' && segments.length == 3) {
          // /sdms-claims/order/abc123 → Order Detail
          final orderId = segments[2];
          return MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: BlocProvider.of<SdmsClaimsBloc>(context),
              child: OrderDetailPage(orderId: orderId),
            ),
          );
        }
        return _errorRoute();

      case 'quota':
        // /quota → Quota Snapshot Page
        return MaterialPageRoute(
          builder: (_) => const QuotaSnapshotPage(),
        );

      case 'profile':
        // /profile → MainContainer with profile tab (index 4)
        return MaterialPageRoute(
          builder: (_) => const MainContainer(initialTab: 4),
        );

      // BONUS ROUTES
      case 'bonus-schemes':
        // /bonus-schemes → Bonus Schemes Page
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => BonusSchemesBloc(
              apiService: context.read<ApiServiceInterface>(),
            )..add(const LoadBonusSchemes()),
            child: const BonusSchemesPage(),
          ),
        );

      case 'bonus-list':
        // /bonus-list?status=active → Bonus List Page
        final initialStatus = uri.queryParameters['status'];
        return MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => BonusListBloc(
              apiService: context.read<ApiServiceInterface>(),
            )..add(const LoadBonusList()),
            child: BonusListPage(initialStatus: initialStatus),
          ),
        );

      case 'bonus-detail':
        // /bonus-detail/123 → Bonus Detail Page
        if (segments.length == 2) {
          final bonusId = int.tryParse(segments[1]);
          if (bonusId != null) {
            return MaterialPageRoute(
              builder: (context) => BlocProvider(
                create: (context) => BonusDetailBloc(
                  apiService: context.read<ApiServiceInterface>(),
                )..add(LoadBonusDetail(bonusId)),
                child: const BonusDetailPage(),
              ),
            );
          }
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Route not found')),
      ),
    );
  }
}