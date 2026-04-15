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
import 'widgets/obligation_token_form.dart';

class ObligationTokenCreatePage extends StatefulWidget {
  final String distributionPointId;
  final OfflineSystemStatus systemStatus;
  final List<OfflineDeliveryCompany> companies;
  final int? initialCompanyId;

  const ObligationTokenCreatePage({
    Key? key,
    required this.distributionPointId,
    required this.systemStatus,
    required this.companies,
    this.initialCompanyId,
  }) : super(key: key);

  @override
  State<ObligationTokenCreatePage> createState() =>
      _ObligationTokenCreatePageState();
}

class _ObligationTokenCreatePageState
    extends State<ObligationTokenCreatePage> {
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
        if (state is TokenCreated) {
          // Don't pop - let the form show success with print option
        } else if (state is OfflineDeliveryError) {
          context.showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Obligation Token'),
          backgroundColor: AppColorsEnhanced.warningYellow,
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
                ObligationTokenForm(
                  distributionPointId: widget.distributionPointId,
                  requireDacCode: widget.systemStatus.requireDacCode,
                  companyId: _selectedCompanyId!,
                )
              else
                Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child:
                      const Center(child: Text('Please select a company')),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
