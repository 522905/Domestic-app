import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/User.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/ujjwala/lpg_ops_installation.dart';
import '../../blocs/ujjwala_installations/my_installations_bloc.dart';
import '../../blocs/ujjwala_installations/my_installations_event.dart';
import '../../blocs/ujjwala_installations/my_installations_state.dart';
import '../../widgets/ujjwala/lpg_ops_installation_card.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../profile/profile_screen.dart' show CompanySwitcherSheet;

class MyInstallationsPage extends StatefulWidget {
  const MyInstallationsPage({Key? key}) : super(key: key);

  @override
  State<MyInstallationsPage> createState() => _MyInstallationsPageState();
}

class _MyInstallationsPageState extends State<MyInstallationsPage> {
  bool _isActionLoading = false;

  static const _scopeOptions = ['mine', 'partner'];
  static const _statusFilters = [
    _FilterOption(label: 'All', value: null),
    _FilterOption(label: 'Pending Verify', value: 'PENDING_VERIFICATION'),
    _FilterOption(label: 'Verified', value: 'VERIFIED'),
    _FilterOption(label: 'Failed', value: 'FAILED'),
    _FilterOption(label: 'Reimbursed', value: 'REIMBURSED'),
    _FilterOption(label: 'Unusual', value: 'UNUSUAL'),
  ];

  Future<void> _handleBulkVerify(
      BuildContext context, List<LpgOpsInstallation> installations) async {
    final ids = installations
        .where((i) => i.status == 'PENDING_VERIFICATION')
        .map((i) => i.id)
        .toList();

    if (ids.isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      final result =
          await context.read<MyInstallationsBloc>().apiService.bulkVerifyInstallations(ids);
      context.read<MyInstallationsBloc>().add(const RefreshMyInstallations());
      if (context.mounted) {
        final summary = result['summary'] ?? 'Verification queued for ${ids.length} installations';
        ProfessionalSnackBar.show(
          context,
          message: summary.toString(),
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ProfessionalSnackBar.show(
          context,
          message: 'Failed to verify: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleRetryFailed(
      BuildContext context, List<LpgOpsInstallation> installations) async {
    final ids = installations
        .where((i) => i.status == 'FAILED' && i.canRetry)
        .map((i) => i.id)
        .toList();

    if (ids.isEmpty) return;

    setState(() => _isActionLoading = true);
    try {
      final result =
          await context.read<MyInstallationsBloc>().apiService.retryFailedInstallations(ids);
      context.read<MyInstallationsBloc>().add(const RefreshMyInstallations());
      if (context.mounted) {
        final summary = result['summary'] ?? 'Retry queued for ${ids.length} installations';
        ProfessionalSnackBar.show(
          context,
          message: summary.toString(),
          type: SnackBarType.info,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ProfessionalSnackBar.show(
          context,
          message: 'Failed to retry: $e',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  bool _isCompanyAccessError(String message) {
    return message.contains('403') || message.toLowerCase().contains('company');
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyInstallationsBloc, MyInstallationsState>(
      builder: (context, state) {
        final scope = state is MyInstallationsLoaded ? state.scope : 'mine';
        final statusFilter =
            state is MyInstallationsLoaded ? state.statusFilter : null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Installations'),
            backgroundColor: AppColorsEnhanced.brandBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              // Scope dropdown
              Padding(
                padding: EdgeInsets.only(right: AppSpacing.md),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: scope,
                    dropdownColor: AppColorsEnhanced.brandBlue,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white),
                    items: _scopeOptions.map((s) {
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(
                          s == 'mine' ? 'Mine' : 'Partner',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context
                            .read<MyInstallationsBloc>()
                            .add(ChangeScopeFilter(val));
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Filter chips
              _buildFilterChips(context, statusFilter),

              // Content
              Expanded(child: _buildContent(context, state)),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, state),
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context, String? statusFilter) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.background,
        border: Border(
          bottom: BorderSide(color: AppColorsEnhanced.border, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusFilters.map((filter) {
            final isSelected = statusFilter == filter.value;
            return Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (_) => context
                    .read<MyInstallationsBloc>()
                    .add(ChangeStatusFilter(filter.value)),
                backgroundColor: Colors.white,
                selectedColor: AppColorsEnhanced.brandBlue,
                checkmarkColor: Colors.white,
                side: BorderSide(
                  color: isSelected
                      ? AppColorsEnhanced.brandBlue
                      : AppColorsEnhanced.border,
                  width: isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : AppColorsEnhanced.secondaryText,
                  fontSize: 12.sp,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                elevation: isSelected ? 2 : 0,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MyInstallationsState state) {
    if (state is MyInstallationsLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorsEnhanced.brandBlue),
      );
    }

    if (state is MyInstallationsError) {
      final isCompanyError = _isCompanyAccessError(state.message);
      return ProfessionalEmptyState(
        icon: isCompanyError ? Icons.business : Icons.error_outline,
        message: isCompanyError
            ? 'Wrong Company'
            : 'Failed to load installations',
        description: isCompanyError
            ? 'This feature is not available for your current company. Switch to the correct company to access Ujjwala installations.'
            : state.message,
        actionText: isCompanyError ? 'Switch Company' : 'Retry',
        onAction: isCompanyError
            ? _showCompanySwitcher
            : () => context
                .read<MyInstallationsBloc>()
                .add(const LoadMyInstallations()),
      );
    }

    if (state is MyInstallationsEmpty) {
      return ProfessionalEmptyState(
        icon: Icons.home_work_outlined,
        message: 'No installations',
        description: state.statusFilter != null
            ? 'No installations with this status'
            : 'Your installations will appear here',
        actionText: 'Refresh',
        onAction: () => context
            .read<MyInstallationsBloc>()
            .add(const RefreshMyInstallations()),
      );
    }

    if (state is MyInstallationsLoaded) {
      return RefreshIndicator(
        onRefresh: () async {
          context
              .read<MyInstallationsBloc>()
              .add(const RefreshMyInstallations());
        },
        color: AppColorsEnhanced.brandBlue,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: state.installations.length,
          itemBuilder: (context, index) {
            final installation = state.installations[index];
            return LpgOpsInstallationCard(
              installation: installation,
              onTap: () => Navigator.pushNamed(
                context,
                '/ujjwala/installation-detail',
                arguments: installation,
              ),
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget? _buildBottomBar(BuildContext context, MyInstallationsState state) {
    if (state is! MyInstallationsLoaded) return null;
    if (_isActionLoading) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(
            child:
                CircularProgressIndicator(color: AppColorsEnhanced.brandBlue),
          ),
        ),
      );
    }

    final installations = state.installations;
    final statusFilter = state.statusFilter;

    if (statusFilter == 'PENDING_VERIFICATION') {
      final count = installations
          .where((i) => i.status == 'PENDING_VERIFICATION')
          .length;
      if (count == 0) return null;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ProfessionalButton(
            text: 'Verify All ($count)',
            icon: Icons.play_arrow,
            fullWidth: true,
            onPressed: () => _handleBulkVerify(context, installations),
          ),
        ),
      );
    }

    if (statusFilter == 'FAILED') {
      final retryable = installations
          .where((i) => i.status == 'FAILED' && i.canRetry)
          .length;
      if (retryable == 0) return null;
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ProfessionalButton(
            text: 'Retry All Failed ($retryable)',
            icon: Icons.refresh,
            variant: ButtonVariant.warning,
            fullWidth: true,
            onPressed: () => _handleRetryFailed(context, installations),
          ),
        ),
      );
    }

    if (statusFilter == 'VERIFIED' && installations.isNotEmpty) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: ProfessionalButton(
            text: 'Claim Reimbursement',
            icon: Icons.currency_rupee,
            variant: ButtonVariant.success,
            fullWidth: true,
            onPressed: () {
              Navigator.pushNamed(context, '/ujjwala/reimbursement');
            },
          ),
        ),
      );
    }

    return null;
  }
}

class _FilterOption {
  final String label;
  final String? value;
  const _FilterOption({required this.label, required this.value});
}
