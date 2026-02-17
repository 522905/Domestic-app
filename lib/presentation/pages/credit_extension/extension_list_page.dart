import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../blocs/credit_extension/credit_extension_list_bloc.dart';
import '../../blocs/credit_extension/credit_extension_list_event.dart';
import '../../blocs/credit_extension/credit_extension_list_state.dart';
import '../../widgets/credit_extension/credit_extension_card.dart';
import 'extension_detail_page.dart';
import 'create_extension_request_page.dart';

class ExtensionListPage extends StatefulWidget {
  const ExtensionListPage({Key? key}) : super(key: key);

  @override
  State<ExtensionListPage> createState() => _ExtensionListPageState();
}

class _ExtensionListPageState extends State<ExtensionListPage> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<CreditExtensionListBloc>().add(
          const LoadCreditExtensions(),
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CreditExtensionListBloc>().add(
            const LoadMoreCreditExtensions(),
          );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      _selectedStatus = status;
    });
    context.read<CreditExtensionListBloc>().add(
          FilterByStatus(status),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('creditExtensionMyExtensionsTitle'), style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<CreditExtensionListBloc>().add(
                    RefreshCreditExtensions(status: _selectedStatus),
                  );
            },
            tooltip: context.l10n.translate('commonRefreshTooltip'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: BlocBuilder<CreditExtensionListBloc, CreditExtensionListState>(
              builder: (context, state) {
                if (state is CreditExtensionListLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is CreditExtensionListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load extensions',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: Text(context.l10n.translate('commonRetryButton')),
                          onPressed: () {
                            context.read<CreditExtensionListBloc>().add(
                                  LoadCreditExtensions(status: _selectedStatus),
                                );
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (state is! CreditExtensionListLoaded &&
                    state is! CreditExtensionListLoadingMore) {
                  return const SizedBox.shrink();
                }

                final extensions = state is CreditExtensionListLoaded
                    ? state.extensions
                    : (state as CreditExtensionListLoadingMore).currentExtensions;

                if (extensions.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CreditExtensionListBloc>().add(
                          RefreshCreditExtensions(status: _selectedStatus),
                        );
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: extensions.length +
                        (state is CreditExtensionListLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= extensions.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final extension = extensions[index];
                      return CreditExtensionCard(
                        extension: extension,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExtensionDetailPage(
                                extension: extension,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(context.l10n.translate('creditExtensionRequestExtensionButtonLabel')),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateExtensionRequestPage(),
            ),
          );

          if (result == true && mounted) {
            context.read<CreditExtensionListBloc>().add(
                  RefreshCreditExtensions(status: _selectedStatus),
                );
          }
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context.l10n.translate('creditExtensionAllStatusFilterLabel'), null),
            const SizedBox(width: 8),
            _buildFilterChip(context.l10n.translate('creditExtensionPendingStatusFilterLabel'), 'PENDING'),
            const SizedBox(width: 8),
            _buildFilterChip(context.l10n.translate('creditExtensionApprovedStatusFilterLabel'), 'APPROVED'),
            const SizedBox(width: 8),
            _buildFilterChip(context.l10n.translate('creditExtensionRejectedStatusFilterLabel'), 'REJECTED'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status) {
    final isSelected = _selectedStatus == status;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        _onStatusFilterChanged(selected ? status : null);
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: AppColors.brandBlue.withOpacity(0.2),
      checkmarkColor: AppColors.brandBlue,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandBlue : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.translate('creditExtensionNoExtensionsEmptyTitle'),
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              context.l10n.translate('creditExtensionNoExtensionsEmptyDescription'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
