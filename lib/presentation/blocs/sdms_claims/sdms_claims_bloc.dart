import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/sdms_claims/sdms_order.dart';
import '../../../domain/entities/sdms_claims/claim_transfer.dart';
import '../../../domain/entities/sdms_claims/partner.dart';
import '../../../utils/error_handler.dart';
import 'sdms_claims_event.dart';
import 'sdms_claims_state.dart';

class SdmsClaimsBloc extends Bloc<SdmsClaimsEvent, SdmsClaimsState> {
  final ApiServiceInterface _apiService;
  List<SdmsOrder> _allOrders = [];
  List<Partner> _allPartners = [];

  // Expose apiService for direct access if needed
  ApiServiceInterface get apiService => _apiService;

  SdmsClaimsBloc({required ApiServiceInterface apiService})
      : _apiService = apiService,
        super(SdmsClaimsInitial()) {
    on<LoadSdmsOrders>(_onLoadOrders);
    on<RefreshSdmsOrders>(_onRefreshOrders);
    on<FilterSdmsOrders>(_onFilterOrders);
    on<SearchSdmsOrders>(_onSearchOrders);
    on<LoadOrderDetail>(_onLoadOrderDetail);
    on<PollOrderDetail>(_onPollOrderDetail);
    on<CreateSdmsOrder>(_onCreateOrder);
    on<ClaimOrder>(_onClaimOrder);
    on<RetryOrder>(_onRetryOrder);
    on<SwitchOrderCompany>(_onSwitchOrderCompany);
    on<ApproveTransfer>(_onApproveTransfer);
    on<RejectTransfer>(_onRejectTransfer);
    on<SearchPartners>(_onSearchPartners);
    on<LoadUnclaimedOrders>(_onLoadUnclaimedOrders);
    on<RefreshUnclaimedOrders>(_onRefreshUnclaimedOrders);
    on<SearchUnclaimedOrders>(_onSearchUnclaimedOrders);
    on<ClaimOrderFromBrowse>(_onClaimOrderFromBrowse);
    on<ClearSdmsClaimsCache>(_onClearCache);
  }

  // Draft v3: Updated to use tab/page/search params
  // Hot fix 2026-02-12: Added isBeneficiary filter support
  Future<void> _onLoadOrders(
    LoadSdmsOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(SdmsClaimsLoading());
      final response = await _apiService.getSdmsOrders(
        tab: event.tab == OrderTab.active ? 'active' : 'history',
        page: event.page,
        search: event.searchQuery,
        isBeneficiary: event.isBeneficiary,
      );

      final orders = (response['results'] as List)
          .map((json) => SdmsOrder.fromJson(json))
          .toList();

      // For history tab, check if there are more pages
      final hasMorePages = event.tab == OrderTab.history &&
          response['next'] != null;

      _allOrders = orders;
      emit(OrdersLoaded(
        orders: orders,
        currentTab: event.tab,
        currentPage: event.page,
        hasMorePages: hasMorePages,
        searchQuery: event.searchQuery,
        isBeneficiary: event.isBeneficiary,
      ));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRefreshOrders(
    RefreshSdmsOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    // Trigger reload
    add(const LoadSdmsOrders());
  }

  Future<void> _onFilterOrders(
    FilterSdmsOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(SdmsClaimsLoading());
      final response = await _apiService.getSdmsClaimsOrders(
        orderCategory: event.orderCategory,
        dataStatus: event.dataStatus,
        claimStatus: event.claimStatus,
        settlementStatus: event.settlementStatus,
        source: event.source,
        isMine: event.isMine,
      );
      final orders = (response['results'] as List)
          .map((json) => SdmsOrder.fromJson(json))
          .toList();
      _allOrders = orders;
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  // Draft v3: Search is now handled server-side via LoadSdmsOrders
  // This handler is kept for backwards compatibility but should redirect to LoadSdmsOrders
  Future<void> _onSearchOrders(
    SearchSdmsOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    // Get current state to preserve tab
    final currentState = state;
    final currentTab = currentState is OrdersLoaded
        ? currentState.currentTab
        : OrderTab.active;

    // Trigger server-side search (don't emit here, let LoadSdmsOrders handle it)
    add(LoadSdmsOrders(
      tab: currentTab,
      page: 1,
      searchQuery: event.query.isEmpty ? null : event.query,
    ));
  }

  Future<void> _onLoadOrderDetail(
    LoadOrderDetail event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderDetailLoading());
      final response = await _apiService.getSdmsClaimsOrderDetail(event.orderId);
      final order = SdmsOrder.fromJson(response);
      emit(OrderDetailLoaded(order));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  /// Silent polling - does NOT emit loading state
  /// Used for background RPA status updates without disrupting UI
  Future<void> _onPollOrderDetail(
    PollOrderDetail event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      final response = await _apiService.getSdmsClaimsOrderDetail(event.orderId);
      final order = SdmsOrder.fromJson(response);
      // Emit updated detail without loading state
      emit(OrderDetailLoaded(order));
    } catch (e) {
      // Silent failure - don't show error during polling
      // Just keep the current state
    }
  }

  Future<void> _onCreateOrder(
    CreateSdmsOrder event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderCreating());
      final response = await _apiService.createSdmsClaimsOrder(
        orderId: event.orderId,
        claimForSelf: event.claimForSelf,
        intendedPartner: event.intendedPartner,
        consumerNumber: event.consumerNumber,
      );

      final order = SdmsOrder.fromJson(response['order']);
      final created = response['created'] as bool? ?? true;
      final message = response['message'] as String? ??
          (created ? 'Order created successfully' : 'Order already exists');

      emit(OrderCreated(
        order: order,
        created: created,
        message: message,
      ));

      // Refresh all tabs after short delay
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadSdmsOrders(tab: OrderTab.active)); // Refresh Active tab
      add(const LoadUnclaimedOrders()); // Refresh Unclaimed Orders tab
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onClaimOrder(
    ClaimOrder event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderActionLoading(event.orderId));
      final response = await _apiService.claimSdmsOrder(event.orderId);

      final message = response['message'] as String? ?? 'Order claimed successfully';
      final order = SdmsOrder.fromJson(response['order']);

      emit(OrderActionSuccess(message: message, order: order));

      // Refresh after claim
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadOrderDetail(event.orderId));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRetryOrder(
    RetryOrder event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderActionLoading(event.orderId));
      final response = await _apiService.retrySdmsOrder(event.orderId);

      final message = response['message'] as String? ?? 'Order queued for retry';
      final order = SdmsOrder.fromJson(response['order']);

      emit(OrderActionSuccess(message: message, order: order));

      // Load detail to show updated status
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadOrderDetail(event.orderId));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onSwitchOrderCompany(
    SwitchOrderCompany event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderActionLoading(event.orderId));
      final response = await _apiService.switchOrderCompany(
        event.orderId,
        event.companyId,
      );

      final message = response['message'] as String? ??
          'Company switched, order re-queued';
      final order = SdmsOrder.fromJson(response['order']);

      emit(OrderActionSuccess(message: message, order: order));

      // Auto-retry in new company
      await Future.delayed(const Duration(milliseconds: 300));
      add(RetryOrder(event.orderId));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  // Draft v3: Use order-level endpoints for approve/reject
  Future<void> _onApproveTransfer(
    ApproveTransfer event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(TransferActionLoading(event.orderId));
      final response = await _apiService.approveOrderTransfer(event.orderId);

      final message = response['message'] as String? ?? 'Transfer approved';
      final order = SdmsOrder.fromJson(response['order']);

      emit(TransferActionSuccess(message: message, order: order));

      // Reload order detail to show updated state
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadOrderDetail(event.orderId));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRejectTransfer(
    RejectTransfer event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(TransferActionLoading(event.orderId));
      final response = await _apiService.rejectOrderTransfer(
        event.orderId,
        reason: event.reason,
      );

      final message = response['message'] as String? ?? 'Transfer rejected';
      final order = SdmsOrder.fromJson(response['order']);

      emit(TransferActionSuccess(message: message, order: order));

      // Reload order detail to show updated state
      await Future.delayed(const Duration(milliseconds: 300));
      add(LoadOrderDetail(event.orderId));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onSearchPartners(
    SearchPartners event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(PartnersLoading());
      final response = await _apiService.getPartners(search: event.query);
      final partners = (response['results'] as List)
          .map((json) => Partner.fromJson(json))
          .toList();
      _allPartners = partners;
      emit(PartnersLoaded(partners));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onLoadUnclaimedOrders(
    LoadUnclaimedOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(SdmsClaimsLoading());
      final response = await _apiService.getSdmsClaimsOrders(
        claimStatus: 'UNCLAIMED',
        dataStatus: 'COMPLETE',
      );
      final orders = (response['results'] as List)
          .map((json) => SdmsOrder.fromJson(json))
          .toList();
      _allOrders = orders;
      emit(OrdersLoaded(orders: orders));
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onRefreshUnclaimedOrders(
    RefreshUnclaimedOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    // Trigger reload without showing loading state
    add(const LoadUnclaimedOrders());
  }

  Future<void> _onSearchUnclaimedOrders(
    SearchUnclaimedOrders event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    final query = event.query.toLowerCase();
    if (query.isEmpty) {
      emit(OrdersLoaded(orders: _allOrders));
      return;
    }

    final filtered = _allOrders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          order.consumerName?.toLowerCase().contains(query) == true ||
          order.originalDeliveryBoyName?.toLowerCase().contains(query) == true;
    }).toList();

    emit(OrdersLoaded(orders: filtered));
  }

  Future<void> _onClaimOrderFromBrowse(
    ClaimOrderFromBrowse event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    try {
      emit(OrderActionLoading(event.orderId));
      final response = await _apiService.claimSdmsOrder(event.orderId);

      final message = response['message'] as String? ?? 'Order claimed successfully';
      final order = SdmsOrder.fromJson(response['order']);

      emit(OrderActionSuccess(message: message, order: order));

      // Refresh unclaimed orders list after claim
      await Future.delayed(const Duration(milliseconds: 300));
      add(const LoadUnclaimedOrders());
    } catch (e) {
      emit(SdmsClaimsError(ErrorHandler.handleError(e)));
    }
  }

  Future<void> _onClearCache(
    ClearSdmsClaimsCache event,
    Emitter<SdmsClaimsState> emit,
  ) async {
    _allOrders = [];
    _allPartners = [];
    emit(SdmsClaimsInitial());
  }
}
