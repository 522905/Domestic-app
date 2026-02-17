import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_bloc.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_event.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_state.dart';
import '../../widgets/credit_extension/gm_approval_card.dart';
import '../../../core/services/api_service_interface.dart';
import 'gm_credit_extension_detail_page.dart';

class GmPendingApprovalsPage extends StatelessWidget {
  const GmPendingApprovalsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GmCreditApprovalsBloc(
        apiService: context.read<ApiServiceInterface>(),
      )..add(const LoadPendingApprovals()),
      child: const _GmPendingApprovalsView(),
    );
  }
}

class _GmPendingApprovalsView extends StatelessWidget {
  const _GmPendingApprovalsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('gmCreditApprovalsPendingApprovalsTitle')),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.l10n.translate('commonRefreshTooltip'),
            onPressed: () {
              context.read<GmCreditApprovalsBloc>().add(const RefreshPendingApprovals());
            },
          ),
        ],
      ),
      body: BlocBuilder<GmCreditApprovalsBloc, GmCreditApprovalsState>(
        builder: (context, state) {
          if (state is GmCreditApprovalsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is GmCreditApprovalsError) {
            return _buildErrorState(context, state.message);
          }

          if (state is GmCreditApprovalsLoaded) {
            if (state.pendingApprovals.isEmpty) {
              return _buildEmptyState(context);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<GmCreditApprovalsBloc>().add(const RefreshPendingApprovals());
                // Wait a bit for the refresh to complete
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                itemCount: state.pendingApprovals.length,
                itemBuilder: (context, index) {
                  final approval = state.pendingApprovals[index];
                  return GmApprovalCard(
                    extension: approval,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<GmCreditApprovalsBloc>(),
                            child: GmCreditExtensionDetailPage(
                              extension: approval,
                            ),
                          ),
                        ),
                      );

                      // If result is true, refresh the list
                      if (result == true) {
                        context.read<GmCreditApprovalsBloc>().add(const RefreshPendingApprovals());
                      }
                    },
                  );
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            context.l10n.translate('gmCreditApprovalsNoApprovalsEmptyTitle'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.translate('gmCreditApprovalsAllProcessedEmptyDescription'),
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load approvals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<GmCreditApprovalsBloc>().add(const RefreshPendingApprovals());
            },
            child: Text(context.l10n.translate('commonRetryButton')),
          ),
        ],
      ),
    );
  }
}
