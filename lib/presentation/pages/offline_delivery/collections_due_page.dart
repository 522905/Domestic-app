import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_company.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../blocs/obligation_collection/obligation_collection_bloc.dart';
import '../../blocs/obligation_collection/obligation_collection_event.dart';
import '../../blocs/obligation_collection/obligation_collection_state.dart';
import '../../widgets/professional_snackbar.dart';
import 'widgets/collection_action_sheet.dart';

class CollectionsDuePage extends StatefulWidget {
  final List<OfflineDeliveryCompany> companies;
  final int? initialCompanyId;

  const CollectionsDuePage({
    Key? key,
    required this.companies,
    this.initialCompanyId,
  }) : super(key: key);

  @override
  State<CollectionsDuePage> createState() => _CollectionsDuePageState();
}

class _CollectionsDuePageState extends State<CollectionsDuePage> {
  late int _selectedCompanyId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedCompanyId =
        widget.initialCompanyId ?? (widget.companies.isNotEmpty ? widget.companies.first.id : 0);
    _loadCollections();
  }

  void _loadCollections() {
    context.read<ObligationCollectionBloc>().add(LoadDueCollections(
      companyId: _selectedCompanyId,
      date: _selectedDate.toIso8601String().split('T')[0],
    ));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
      _loadCollections();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Due Collections'),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Company picker
                if (widget.companies.length > 1)
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedCompanyId,
                      decoration: InputDecoration(
                        labelText: 'Company',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        isDense: true,
                      ),
                      items: widget.companies.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.shortCode,
                              style: TextStyle(fontSize: 13.sp)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCompanyId = value);
                          _loadCollections();
                        }
                      },
                    ),
                  ),
                if (widget.companies.length > 1)
                  SizedBox(width: AppSpacing.sm),
                // Date picker
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today, size: 16.sp),
                      ),
                      child: Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: TextStyle(fontSize: 13.sp),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: BlocConsumer<ObligationCollectionBloc,
                ObligationCollectionState>(
              listener: (context, state) {
                if (state is EmptiesCollected) {
                  context.showSuccessSnackBar('Empty collection recorded');
                } else if (state is CashCollected) {
                  context.showSuccessSnackBar('Cash collection recorded');
                } else if (state is ObligationCollectionError) {
                  context.showErrorSnackBar(state.message);
                }
              },
              builder: (context, state) {
                if (state is ObligationCollectionLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ObligationCollectionLoaded) {
                  if (state.tokens.isEmpty) {
                    return _buildEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<ObligationCollectionBloc>()
                          .add(const RefreshCollections());
                    },
                    child: ListView.builder(
                      padding: EdgeInsets.all(AppSpacing.md),
                      itemCount: state.tokens.length,
                      itemBuilder: (context, index) {
                        return _buildCollectionCard(state.tokens[index]);
                      },
                    ),
                  );
                }
                if (state is ObligationCollectionError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColorsEnhanced.errorRed),
                        SizedBox(height: AppSpacing.md),
                        Text(state.message),
                        SizedBox(height: AppSpacing.md),
                        ElevatedButton(
                          onPressed: _loadCollections,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline,
              size: 64, color: AppColorsEnhanced.successGreen),
          SizedBox(height: AppSpacing.md),
          Text(
            'No pending collections',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'All empties and cash have been collected',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(OfflineDeliveryToken token) {
    final detail = token.obligationDetail;
    final hasPendingEmpties = detail?.hasPendingEmpties ?? false;
    final hasPendingCash = detail?.hasPendingCash ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () => _showCollectionSheet(token),
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Token #${token.tokenNumber ?? '?'}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (detail != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color:
                            AppColorsEnhanced.warningYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        detail.itemDisplayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.warningYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                token.displayName,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
              if (detail?.directorDisplayName != null)
                Text(
                  'By: ${detail!.directorDisplayName}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColorsEnhanced.secondaryText,
                    fontSize: 10.sp,
                  ),
                ),
              SizedBox(height: AppSpacing.sm),

              // Status badges
              Row(
                children: [
                  if (hasPendingEmpties)
                    _buildStatusBadge(
                      icon: Icons.swap_vert,
                      text:
                          '${detail!.emptiesCollected}/${detail.emptiesExpected} empties',
                      color: detail.isOverdueEmpties
                          ? AppColorsEnhanced.errorRed
                          : AppColorsEnhanced.warningYellow,
                    ),
                  if (hasPendingEmpties && hasPendingCash)
                    SizedBox(width: AppSpacing.sm),
                  if (hasPendingCash)
                    _buildStatusBadge(
                      icon: Icons.payments,
                      text: 'Cash pending',
                      color: detail!.isOverdueCash
                          ? AppColorsEnhanced.errorRed
                          : AppColorsEnhanced.warningYellow,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  void _showCollectionSheet(OfflineDeliveryToken token) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: context.read<ObligationCollectionBloc>(),
          child: CollectionActionSheet(token: token),
        );
      },
    );
  }
}
