import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../widgets/professional_snackbar.dart';
import 'widgets/token_list_widget.dart';
import 'widgets/verification_list_widget.dart';
import 'verify_booking_create_page.dart';
import 'normal_token_create_page.dart';
import 'quick_token_create_page.dart';
import 'obligation_token_create_page.dart';

class OfflineDeliveryPage extends StatefulWidget {
  const OfflineDeliveryPage({Key? key}) : super(key: key);

  @override
  State<OfflineDeliveryPage> createState() => _OfflineDeliveryPageState();
}

class _OfflineDeliveryPageState extends State<OfflineDeliveryPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  Timer? _statusPollTimer;
  Timer? _tokenPollTimer;
  Timer? _verificationPollTimer;
  Timer? _searchDebounce;
  bool _tokenPollingActive = false;
  int _currentTabIndex = 0;
  bool _hasAutoShownPicker = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statusPollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      context.read<OfflineDeliveryBloc>().add(const PollSystemStatus());
    });
  }

  void _ensureTabController(bool needsTabs) {
    if (needsTabs && _tabController == null) {
      _tabController = TabController(length: 2, vsync: this);
      _tabController!.addListener(_onTabChanged);
    } else if (!needsTabs && _tabController != null) {
      _tabController!.removeListener(_onTabChanged);
      _tabController!.dispose();
      _tabController = null;
      _currentTabIndex = 0;
    }
  }

  void _onTabChanged() {
    if (_tabController != null && _tabController!.index != _currentTabIndex) {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
      // Clear search when switching tabs
      if (_searchController.text.isNotEmpty) {
        _searchController.clear();
        _dispatchSearch('');
      }
    }
  }

  void _dispatchSearch(String query) {
    final bloc = context.read<OfflineDeliveryBloc>();
    final state = bloc.state;
    if (state is! OfflineDeliveryLoaded) return;

    final isManual = state.systemStatus.isManual;
    if (isManual || _currentTabIndex == 1) {
      bloc.add(SearchTokens(query));
    } else {
      bloc.add(SearchVerifications(query));
    }
  }

  void _onSearchChanged(String query) {
    setState(() {}); // Update clear button visibility
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _dispatchSearch(query);
    });
  }

  void _startTokenPolling() {
    if (_tokenPollingActive) return;
    _tokenPollingActive = true;
    _tokenPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      context.read<OfflineDeliveryBloc>().add(const RefreshTokens());
    });
  }

  void _startVerificationPolling() {
    _verificationPollTimer?.cancel();
    _verificationPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      context.read<OfflineDeliveryBloc>().add(const PollVerifications());
    });
  }

  void _stopVerificationPolling() {
    _verificationPollTimer?.cancel();
    _verificationPollTimer = null;
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _statusPollTimer?.cancel();
    _tokenPollTimer?.cancel();
    _verificationPollTimer?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is TokenCreated) {
          context.showSuccessSnackBar(
            'Token #${state.token.tokenNumber} created!',
          );
        } else if (state is TokenDelivered) {
          context.showSuccessSnackBar(state.message);
        } else if (state is TokenCorrected) {
          context.showSuccessSnackBar('Token corrected');
        } else if (state is QuickDelivered) {
          context.showSuccessSnackBar(state.message);
        } else if (state is VerificationCreated) {
          context.showSuccessSnackBar('Verification submitted');
        } else if (state is ImagesAttached) {
          context.showSuccessSnackBar('Images attached');
        } else if (state is OfflineDeliveryError) {
          context.showErrorSnackBar(state.message);
        } else if (state is OfflineDeliveryLoaded &&
            state.selectedPoint != null) {
          _startTokenPolling();
          if (state.systemStatus.isAssisted || state.systemStatus.isVerified) {
            _startVerificationPolling();
          } else {
            _stopVerificationPolling();
          }
        }
      },
      buildWhen: (prev, curr) {
        return curr is OfflineDeliveryLoading ||
            curr is OfflineDeliveryLoaded ||
            curr is OfflineDeliveryError ||
            curr is OfflineDeliveryInitial;
      },
      builder: (context, state) {
        if (state is OfflineDeliveryLoading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Offline Delivery'),
              backgroundColor: AppColorsEnhanced.brandBlue,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is OfflineDeliveryLoaded) {
          return _buildLoadedScaffold(state);
        }

        if (state is OfflineDeliveryError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Offline Delivery'),
              backgroundColor: AppColorsEnhanced.brandBlue,
              foregroundColor: Colors.white,
            ),
            body: _buildErrorView(state.message),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Offline Delivery'),
            backgroundColor: AppColorsEnhanced.brandBlue,
            foregroundColor: Colors.white,
          ),
          body: const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildLoadedScaffold(OfflineDeliveryLoaded state) {
    final isManual = state.systemStatus.isManual;
    final hasPoint = state.selectedPoint != null;
    final needsTabs = hasPoint && !isManual;

    _ensureTabController(needsTabs);

    // Auto-select if single warehouse, otherwise show picker
    if (!hasPoint &&
        !_hasAutoShownPicker &&
        state.distributionPoints.isNotEmpty) {
      _hasAutoShownPicker = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (state.distributionPoints.length == 1) {
          context
              .read<OfflineDeliveryBloc>()
              .add(SelectDistributionPoint(state.distributionPoints.first.id));
        } else {
          _showWarehousePickerSheet(state);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: state.distributionPoints.isNotEmpty
              ? () => _showWarehousePickerSheet(state)
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Offline Delivery'),
              if (state.distributionPoints.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        state.selectedPoint?.name ?? 'Select warehouse',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
            ],
          ),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        actions: [
          if (state.isSupervisor)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Due Collections',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  'offline-delivery-collections',
                  arguments: {
                    'companies': state.companies,
                    'initialCompanyId': state.lastSelectedCompanyId,
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<OfflineDeliveryBloc>().add(const LoadTokens());
              if (state.systemStatus.isAssisted ||
                  state.systemStatus.isVerified) {
                context
                    .read<OfflineDeliveryBloc>()
                    .add(const LoadVerifications());
              }
            },
          ),
        ],
        bottom: needsTabs
            ? TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.bodyMedium,
                tabs: [
                  Tab(
                    text:
                        'Verify Booking (${state.verifications.length})',
                  ),
                  Tab(
                    text: 'Tokens (${state.tokens.length})',
                  ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          SizedBox(height: AppSpacing.sm),
          if (hasPoint)
            Container(
              color: AppColorsEnhanced.backgroundSecondary,
              child: _buildSearchBar(),
            ),
          // Main content
          Expanded(
            child: hasPoint
                ? (isManual
                    ? _buildTokenList(state)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVerificationList(state),
                          _buildTokenList(state),
                        ],
                      ))
                : Center(
                    child: GestureDetector(
                      onTap: state.distributionPoints.isNotEmpty
                          ? () => _showWarehousePickerSheet(state)
                          : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 40,
                            color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.5),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tap above to select warehouse',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColorsEnhanced.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(state),
    );
  }

  void _showWarehousePickerSheet(OfflineDeliveryLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColorsEnhanced.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Warehouse',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              ...state.distributionPoints.map((point) {
                final isSelected = state.selectedPoint?.id == point.id;
                return ListTile(
                  leading: Icon(
                    point.isAdhoc ? Icons.local_shipping : Icons.warehouse,
                    color: isSelected
                        ? AppColorsEnhanced.brandBlue
                        : AppColorsEnhanced.secondaryText,
                  ),
                  title: Text(
                    point.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColorsEnhanced.brandBlue
                          : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (point.todayTokenCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${point.todayTokenCount}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColorsEnhanced.brandBlue,
                            ),
                          ),
                        ),
                      if (isSelected) ...[
                        SizedBox(width: AppSpacing.sm),
                        Icon(
                          Icons.check_circle,
                          color: AppColorsEnhanced.brandBlue,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context
                        .read<OfflineDeliveryBloc>()
                        .add(SelectDistributionPoint(point.id));
                  },
                );
              }),
              SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.sm),
        child: SizedBox(
          height: 40,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: AppColorsEnhanced.secondaryText,
              fontSize: 14,
            ),
            textAlignVertical: TextAlignVertical.center,
            decoration: InputDecoration(
              hintText: 'Search by consumer ID or number...',
              hintStyle: TextStyle(
                color: AppColorsEnhanced.secondaryText.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: AppColorsEnhanced.secondaryText,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _dispatchSearch('');
                        setState(() {});
                      },
                      child: Icon(
                        Icons.close,
                        color: AppColorsEnhanced.secondaryText,
                        size: 18,
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 0,
              ),
              filled: true,
              fillColor: Colors.white,
              isCollapsed: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColorsEnhanced.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColorsEnhanced.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: AppColorsEnhanced.brandBlue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTokenList(OfflineDeliveryLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OfflineDeliveryBloc>().add(const LoadTokens());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: TokenListWidget(
          tokens: state.tokens,
          selectedDate: state.selectedDate,
          hasMore: state.hasMoreTokens,
          isLoadingMore: state.isLoadingMoreTokens,
          isSearchActive: state.searchQuery.isNotEmpty,
          onLoadMore: () {
            context.read<OfflineDeliveryBloc>().add(const LoadMoreTokens());
          },
          onRefresh: () {
            context.read<OfflineDeliveryBloc>().add(const LoadTokens());
          },
        ),
      ),
    );
  }

  Widget _buildVerificationList(OfflineDeliveryLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OfflineDeliveryBloc>().add(const LoadVerifications());
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            _buildShowAllChip(state),
            VerificationListWidget(
              verifications: state.verifications,
              distributionPointId: state.selectedPoint?.id,
              isSupervisor: state.isSupervisor,
              showAllActive: state.showAllVerifications,
              hasMore: state.hasMoreVerifications,
              isLoadingMore: state.isLoadingMoreVerifications,
              onLoadMore: () {
                context
                    .read<OfflineDeliveryBloc>()
                    .add(const LoadMoreVerifications());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowAllChip(OfflineDeliveryLoaded state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          FilterChip(
            label: Text(
              'Show All',
              style: AppTextStyles.labelSmall.copyWith(
                color: state.showAllVerifications
                    ? Colors.white
                    : AppColorsEnhanced.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            selected: state.showAllVerifications,
            onSelected: (value) {
              context
                  .read<OfflineDeliveryBloc>()
                  .add(ToggleShowAllVerifications(value));
            },
            selectedColor: AppColorsEnhanced.brandBlue,
            checkmarkColor: Colors.white,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: state.showAllVerifications
                  ? AppColorsEnhanced.brandBlue
                  : AppColorsEnhanced.border,
            ),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(width: AppSpacing.sm),
          if (state.showAllVerifications)
            Text(
              'Showing all users\' verifications',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildFAB(OfflineDeliveryLoaded state) {
    if (state.selectedPoint == null) return null;

    final isManual = state.systemStatus.isManual;

    // In non-MANUAL mode, FAB behavior depends on the active tab
    if (!isManual && _currentTabIndex == 0) {
      // Verify Booking tab
      return FloatingActionButton(
        backgroundColor: AppColorsEnhanced.brandBlue,
        onPressed: () => _pushVerifyBookingPage(state),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    // Tokens tab (or MANUAL mode)
    return FloatingActionButton(
      backgroundColor: AppColorsEnhanced.brandBlue,
      onPressed: () => _showTokenCreationSheet(state),
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _pushVerifyBookingPage(OfflineDeliveryLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OfflineDeliveryBloc>(),
          child: VerifyBookingCreatePage(
            distributionPointId: state.selectedPoint!.id,
            companies: state.companies,
            initialCompanyId: state.lastSelectedCompanyId,
          ),
        ),
      ),
    );
  }

  void _showTokenCreationSheet(OfflineDeliveryLoaded state) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColorsEnhanced.brandBlue.withOpacity(0.1),
                    child: Icon(
                      Icons.confirmation_number,
                      color: AppColorsEnhanced.brandBlue,
                    ),
                  ),
                  title: Text(
                    'Normal Token',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Create a standard delivery token',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColorsEnhanced.secondaryText,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pushNormalTokenPage(state);
                  },
                ),
                if (state.selectedPoint!.allowQuickDelivery)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColorsEnhanced.successGreen.withOpacity(0.1),
                      child: Icon(
                        Icons.flash_on,
                        color: AppColorsEnhanced.successGreen,
                      ),
                    ),
                    title: Text(
                      'Quick Token',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Create token & deliver in one step',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pushQuickTokenPage(state);
                    },
                  ),
                if (state.isSupervisor)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          AppColorsEnhanced.warningYellow.withOpacity(0.1),
                      child: Icon(
                        Icons.assignment,
                        color: AppColorsEnhanced.warningYellow,
                      ),
                    ),
                    title: Text(
                      'Obligation Token',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Director-authorized delivery',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pushObligationTokenPage(state);
                    },
                  ),


              ],
            ),
          ),
        );
      },
    );
  }

  void _pushNormalTokenPage(OfflineDeliveryLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OfflineDeliveryBloc>(),
          child: NormalTokenCreatePage(
            distributionPointId: state.selectedPoint!.id,
            systemStatus: state.systemStatus,
            companies: state.companies,
            initialCompanyId: state.lastSelectedCompanyId,
          ),
        ),
      ),
    );
  }

  void _pushQuickTokenPage(OfflineDeliveryLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OfflineDeliveryBloc>(),
          child: QuickTokenCreatePage(
            distributionPointId: state.selectedPoint!.id,
            systemStatus: state.systemStatus,
            companies: state.companies,
            initialCompanyId: state.lastSelectedCompanyId,
          ),
        ),
      ),
    );
  }

  void _pushObligationTokenPage(OfflineDeliveryLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<OfflineDeliveryBloc>(),
          child: ObligationTokenCreatePage(
            distributionPointId: state.selectedPoint!.id,
            systemStatus: state.systemStatus,
            companies: state.companies,
            initialCompanyId: state.lastSelectedCompanyId,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColorsEnhanced.errorRed,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: () {
                context
                    .read<OfflineDeliveryBloc>()
                    .add(const LoadInitialData());
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColorsEnhanced.brandBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
