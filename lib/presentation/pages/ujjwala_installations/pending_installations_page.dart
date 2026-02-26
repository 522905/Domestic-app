import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_bloc.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_event.dart';
import '../../blocs/ujjwala_installations/ujjwala_installations_state.dart';
import '../../widgets/ujjwala/installation_card.dart';
import '../../widgets/ujjwala/installation_search_bar.dart';
import '../../widgets/ujjwala/ujjwala_map_view.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../profile/profile_screen.dart' show CompanySwitcherSheet;

class PendingInstallationsPage extends StatefulWidget {
  const PendingInstallationsPage({Key? key}) : super(key: key);

  @override
  State<PendingInstallationsPage> createState() => _PendingInstallationsPageState();
}

class _PendingInstallationsPageState extends State<PendingInstallationsPage>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  bool _isCompanyAccessError(String message) =>
      message.contains('403') || message.toLowerCase().contains('company');

  Future<void> _showCompanySwitcher() async {
    try {
      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);
      final companies = await apiService.companyList();
      final activeCompany = await User().getActiveCompany();

      if (mounted) {
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          builder: (ctx) => CompanySwitcherSheet(
            companies: companies,
            activeCompany: activeCompany,
            onCompanySelected: _switchCompany,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ProfessionalSnackBar.show(
          context,
          message: 'Failed to load companies: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _switchCompany(UserCompany selectedCompany) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final apiService = Provider.of<ApiServiceInterface>(context, listen: false);
      await apiService.switchCompany(selectedCompany.id);

      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          'dashboard',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ProfessionalSnackBar.show(
          context,
          message: 'Failed to switch company: $e',
          type: SnackBarType.error,
        );
      }
    }
  }

  void _onSearchPressed(String query) {
    setState(() {
      _searchQuery = query;
    });

    // No debounce - immediate search
    context.read<UjjwalaInstallationsBloc>().add(
          SearchInstallations(query: query),
        );
  }

  void _navigateToSubmitPage(BuildContext context, dynamic installation) {
    Navigator.pushNamed(
      context,
      '/ujjwala-installation/submit',
      arguments: installation,
    ).then((_) {
      context.read<UjjwalaInstallationsBloc>().add(
            const RefreshPendingInstallations(),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.ujjwalaPendingListTitle),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<UjjwalaInstallationsBloc>().add(
                    const RefreshPendingInstallations(),
                  );
            },
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'List', icon: Icon(Icons.list)),
            Tab(text: 'Map', icon: Icon(Icons.map)),
          ],
        ),
      ),
      // TabBarView is always alive - never recreated on BLoC state changes.
      // BlocListener handles error snackbars separately.
      body: BlocListener<UjjwalaInstallationsBloc, UjjwalaInstallationsState>(
        listener: (context, state) {
          // Error is handled by the full-screen error state in _ListTab — no snackbar needed
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _ListTab(
              searchQuery: _searchQuery,
              onSearchPressed: _onSearchPressed,
              onTap: (installation) => _navigateToSubmitPage(context, installation),
              onSwitchCompany: _showCompanySwitcher,
            ),
            _MapTab(
              onMarkerTap: (installation) => _navigateToSubmitPage(context, installation),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── List Tab ─────────────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchPressed;
  final void Function(dynamic installation) onTap;
  final VoidCallback onSwitchCompany;

  const _ListTab({
    required this.searchQuery,
    required this.onSearchPressed,
    required this.onTap,
    required this.onSwitchCompany,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UjjwalaInstallationsBloc, UjjwalaInstallationsState>(
      builder: (context, state) {
        if (state is PendingInstallationsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColorsEnhanced.brandBlue,
            ),
          );
        }

        if (state is PendingInstallationsEmpty) {
          return Column(
            children: [
              InstallationSearchBar(onSearchPressed: onSearchPressed),
              Expanded(
                child: ProfessionalEmptyState(
                  icon: searchQuery.isEmpty ? Icons.assignment_outlined : Icons.search_off,
                  message: searchQuery.isEmpty
                      ? context.l10n.ujjwalaPendingListEmpty
                      : 'No installations found',
                  description: searchQuery.isEmpty
                      ? 'There are no pending installations at the moment'
                      : 'Try searching with different keywords',
                ),
              ),
            ],
          );
        }

        if (state is PendingInstallationsLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<UjjwalaInstallationsBloc>().add(
                    const RefreshPendingInstallations(),
                  );
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: AppColorsEnhanced.brandBlue,
            child: Column(
              children: [
                InstallationSearchBar(onSearchPressed: onSearchPressed),
                if (searchQuery.isNotEmpty)
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.brandBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16.r,
                          color: AppColorsEnhanced.brandBlue,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Showing ${state.installations.length} of ${state.totalCount} installations',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    itemCount: state.installations.length,
                    itemBuilder: (context, index) {
                      final installation = state.installations[index];
                      return InstallationCard(
                        installation: installation,
                        onTap: () => onTap(installation),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }

        if (state is PendingInstallationsError) {
          final isCompanyError = state.message.contains('403') ||
              state.message.toLowerCase().contains('company');
          return ProfessionalEmptyState(
            icon: isCompanyError ? Icons.business : Icons.error_outline,
            message: isCompanyError ? 'Wrong Company' : 'Error loading installations',
            description: isCompanyError
                ? 'This feature is not available for your current company. Switch to the correct company to access Ujjwala installations.'
                : state.message,
            actionText: isCompanyError ? 'Switch Company' : 'Retry',
            onAction: isCompanyError
                ? onSwitchCompany
                : () => context.read<UjjwalaInstallationsBloc>().add(
                      const RefreshPendingInstallations(),
                    ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ─── Map Tab ──────────────────────────────────────────────────────────────────
// Kept as a StatefulWidget with AutomaticKeepAliveClientMixin so the
// GoogleMap surface is NOT destroyed when the user switches to the List tab.

class _MapTab extends StatefulWidget {
  final void Function(dynamic installation) onMarkerTap;

  const _MapTab({required this.onMarkerTap});

  @override
  State<_MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<_MapTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    return BlocBuilder<UjjwalaInstallationsBloc, UjjwalaInstallationsState>(
      builder: (context, state) {
        if (state is PendingInstallationsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColorsEnhanced.brandBlue,
            ),
          );
        }

        if (state is PendingInstallationsLoaded) {
          return UjjwalaMapView(
            installations: state.installations,
            onMarkerTap: widget.onMarkerTap,
          );
        }

        if (state is PendingInstallationsEmpty) {
          return ProfessionalEmptyState(
            icon: Icons.location_off,
            message: 'No installations to display',
            description: 'There are no installations with location data available',
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
