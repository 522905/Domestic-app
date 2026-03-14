import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_company.dart';
import '../../../domain/entities/offline_delivery/offline_system_status.dart';
import '../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../widgets/professional_snackbar.dart';
import 'widgets/compact_company_picker.dart';
import 'widgets/quick_delivery_form.dart';

class QuickTokenCreatePage extends StatefulWidget {
  final String distributionPointId;
  final OfflineSystemStatus systemStatus;
  final List<OfflineDeliveryCompany> companies;
  final int? initialCompanyId;

  const QuickTokenCreatePage({
    Key? key,
    required this.distributionPointId,
    required this.systemStatus,
    required this.companies,
    this.initialCompanyId,
  }) : super(key: key);

  @override
  State<QuickTokenCreatePage> createState() => _QuickTokenCreatePageState();
}

class _QuickTokenCreatePageState extends State<QuickTokenCreatePage> {
  int? _selectedCompanyId;

  @override
  void initState() {
    super.initState();
    if (widget.companies.length == 1) {
      _selectedCompanyId = widget.companies.first.id;
    } else {
      _selectedCompanyId = widget.initialCompanyId;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        if (state is QuickDelivered) {
          context.showSuccessSnackBar(state.message);
          Navigator.of(context).pop();
        } else if (state is OfflineDeliveryError) {
          context.showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quick Delivery'),
          backgroundColor: AppColorsEnhanced.brandBlue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.companies.length > 1) ...[
                SizedBox(height: AppSpacing.md),
                CompactCompanyPicker(
                  companies: widget.companies,
                  selectedId: _selectedCompanyId,
                  onSelect: (id) => setState(() => _selectedCompanyId = id),
                ),
                SizedBox(height: AppSpacing.sm),
              ],
              if (_selectedCompanyId != null)
                QuickDeliveryForm(
                  distributionPointId: widget.distributionPointId,
                  systemStatus: widget.systemStatus,
                  companyId: _selectedCompanyId!,
                )
              else
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: const Center(child: Text('Please select a company')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
