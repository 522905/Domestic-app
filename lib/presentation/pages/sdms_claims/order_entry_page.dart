import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/sdms_claims/partner.dart';
import '../../blocs/sdms_claims/sdms_claims_bloc.dart';
import '../../blocs/sdms_claims/sdms_claims_event.dart';
import '../../blocs/sdms_claims/sdms_claims_state.dart';
import '../../widgets/professional/professional_button.dart';
import '../../widgets/professional_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';

class OrderEntryPage extends StatefulWidget {
  const OrderEntryPage({Key? key}) : super(key: key);

  @override
  State<OrderEntryPage> createState() => _OrderEntryPageState();
}

class _OrderEntryPageState extends State<OrderEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _orderIdController = TextEditingController();
  final _partnerSearchController = TextEditingController();
  final _consumerNumberController = TextEditingController();

  bool _isNcDbc = false; // Default: Digital mode
  bool _claimForMyself = true; // Default: checked
  Partner? _selectedPartner;
  bool _isSubmitting = false;

  Timer? _debounceTimer;
  List<Partner> _searchResults = [];

  @override
  void dispose() {
    _orderIdController.dispose();
    _partnerSearchController.dispose();
    _consumerNumberController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool _isFormValid() {
    final trimmed = _orderIdController.text.trim();
    final pattern = RegExp(r'^\d{1,2}-\d{12}$');
    final orderIdValid = pattern.hasMatch(trimmed);
    final claimValid = _claimForMyself || _selectedPartner != null;
    final consumerValid = !_isNcDbc ||
        RegExp(r'^\d{16}$').hasMatch(_consumerNumberController.text.trim());
    return orderIdValid && claimValid && consumerValid;
  }

  void _onPartnerSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<SdmsClaimsBloc>().add(SearchPartners(query));
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_isFormValid()) return;

    setState(() => _isSubmitting = true);

    context.read<SdmsClaimsBloc>().add(CreateSdmsOrder(
          orderId: _orderIdController.text.trim(),
          claimForSelf: _claimForMyself,
          intendedPartner: _selectedPartner?.id,
          consumerNumber: _isNcDbc
              ? _consumerNumberController.text.trim()
              : null,
        ));
  }

  Widget _buildToggle() {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: AppColorsEnhanced.backgroundSecondary,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
      ),
      child: Row(
        children: [
          // Digital option
          Expanded(
            child: GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () {
                      if (_isNcDbc) {
                        setState(() {
                          _isNcDbc = false;
                          _consumerNumberController.clear();
                        });
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: !_isNcDbc
                      ? AppColorsEnhanced.brandBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  context.l10n.translate('sdmsClaimsDigitalToggleLabel'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: !_isNcDbc
                        ? Colors.white
                        : AppColorsEnhanced.secondaryText,
                    fontWeight:
                        !_isNcDbc ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          // NC & DBC option
          Expanded(
            child: GestureDetector(
              onTap: _isSubmitting
                  ? null
                  : () {
                      if (!_isNcDbc) {
                        setState(() => _isNcDbc = true);
                      }
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _isNcDbc
                      ? AppColorsEnhanced.brandBlue
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  context.l10n.translate('sdmsClaimsNcDbcToggleLabel'),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: _isNcDbc
                        ? Colors.white
                        : AppColorsEnhanced.secondaryText,
                    fontWeight:
                        _isNcDbc ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeInfoCard() {
    if (!_isNcDbc) {
      // Digital mode card
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
              color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.smartphone,
                color: AppColorsEnhanced.brandBlue, size: 20.sp),
            SizedBox(width: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColorsEnhanced.brandBlue,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                context.l10n.translate('sdmsClaimsDigitalBadgeText'),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // NC & DBC mode card
    const ncDbcTypes = ['NC', 'DBC', 'Conversion', 'Add On', 'TV IN', 'TV OUT'];
    return Container(
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColorsEnhanced.backgroundSecondary,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColorsEnhanced.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.translate('sdmsClaimsOrderTypesLabel'),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: ncDbcTypes
                .map(
                  (type) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.brandBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color:
                            AppColorsEnhanced.brandBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      type,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColorsEnhanced.brandBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsEnhanced.background,
      appBar: AppBar(
        title: Text(context.l10n.translate('sdmsClaimsNewOrderPageTitle')),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<SdmsClaimsBloc, SdmsClaimsState>(
        listener: (context, state) {
          if (state is OrderCreated) {
            final navigator = Navigator.of(context);
            navigator.pop();
            ProfessionalSnackBar.show(
              context,
              message: state.message,
              type: state.created ? SnackBarType.success : SnackBarType.info,
            );
            navigator.pushNamed('/sdms-claims/order/${state.order.id}');
          }

          if (state is SdmsClaimsError) {
            setState(() => _isSubmitting = false);
            ProfessionalSnackBar.show(
              context,
              message: state.message,
              type: SnackBarType.error,
            );
          }

          if (state is PartnersLoaded) {
            setState(() => _searchResults = state.partners);
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Toggle: Digital / NC & DBC
                  _buildToggle(),
                  SizedBox(height: AppSpacing.sm),

                  // Type info card
                  _buildTypeInfoCard(),
                  SizedBox(height: AppSpacing.lg),

                  // Section Header
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: AppColorsEnhanced.brandBlue,
                        size: 24.sp,
                      ),
                      SizedBox(width: AppSpacing.xs),
                      Text(context.l10n.translate('sdmsClaimsOrderDetailsHeaderLabel'), style: AppTextStyles.h2),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Consumer Number Field (NC & DBC only)
                  Visibility(
                    visible: _isNcDbc,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _consumerNumberController,
                          keyboardType: TextInputType.number,
                          enabled: !_isSubmitting,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            labelText: context.l10n.translate('sdmsClaimsConsumerIdLabel'),
                            hintText: context.l10n.translate('sdmsClaimsConsumerIdHintText'),
                            prefixIcon: Icon(
                              Icons.person_pin,
                              color: AppColorsEnhanced.brandBlue,
                            ),
                            filled: true,
                            fillColor: AppColorsEnhanced.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.brandBlue,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.errorRed,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.errorRed,
                                width: 2,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (!_isNcDbc) return null;
                            if (value == null || value.trim().isEmpty) {
                              return context.l10n.translate('sdmsClaimsConsumerIdRequiredError');
                            }
                            if (value.trim().length != 16) {
                              return context.l10n.translate('sdmsClaimsConsumerIdFormatError');
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(height: AppSpacing.md),
                      ],
                    ),
                  ),

                  // Order ID Field
                  TextFormField(
                    controller: _orderIdController,
                    keyboardType: TextInputType.phone,
                    autofocus: true,
                    enabled: !_isSubmitting,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('sdmsClaimsOrderIdLabel'),
                      hintText: context.l10n.translate('sdmsClaimsOrderIdHintText'),
                      prefixIcon: Icon(
                        Icons.receipt_long,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                      filled: true,
                      fillColor: AppColorsEnhanced.backgroundSecondary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColorsEnhanced.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColorsEnhanced.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColorsEnhanced.brandBlue,
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColorsEnhanced.errorRed,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: AppColorsEnhanced.errorRed,
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return context.l10n.translate('sdmsClaimsOrderIdRequiredError');
                      }
                      final trimmed = value.trim();
                      final pattern = RegExp(r'^\d{1,2}-\d{12}$');
                      if (!pattern.hasMatch(trimmed)) {
                        return context.l10n.translate('sdmsClaimsOrderIdFormatError');
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  SizedBox(height: AppSpacing.sm),

                  // Info banner
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsEnhanced.infoBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16.sp, color: AppColorsEnhanced.infoBlue),
                        SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            context.l10n.translate('sdmsClaimsOrderIdInfoMessage'),
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColorsEnhanced.infoBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // "Claiming for myself" Checkbox
                  Container(
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.backgroundSecondary,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColorsEnhanced.border,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _claimForMyself,
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              setState(() {
                                _claimForMyself = value ?? true;
                                if (_claimForMyself) {
                                  _selectedPartner = null;
                                  _partnerSearchController.clear();
                                  _searchResults = [];
                                }
                              });
                            },
                      title: Text(
                        context.l10n.translate('sdmsClaimsClaimingForMyselfLabel'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        context.l10n.translate('sdmsClaimsClaimingForMyselfHelpText'),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColorsEnhanced.brandBlue,
                    ),
                  ),
                  SizedBox(height: AppSpacing.md),

                  // Partner Picker (conditional)
                  Visibility(
                    visible: !_claimForMyself,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(
                                child: Divider(
                                    color: AppColorsEnhanced.border,
                                    thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md),
                              child: Text(context.l10n.translate('sdmsClaimsOrDividerText'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColorsEnhanced.secondaryText,
                                    fontWeight: FontWeight.bold,
                                  )),
                            ),
                            Expanded(
                                child: Divider(
                                    color: AppColorsEnhanced.border,
                                    thickness: 1)),
                          ],
                        ),
                        SizedBox(height: AppSpacing.md),

                        // Partner Section Header
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: AppColorsEnhanced.brandBlue,
                              size: 24.sp,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(context.l10n.translate('sdmsClaimsPartnerDeliveryBoyHeaderLabel'),
                                style: AppTextStyles.h3),
                          ],
                        ),
                        SizedBox(height: AppSpacing.sm),

                        // Partner Search Field
                        TextFormField(
                          controller: _partnerSearchController,
                          enabled: !_isSubmitting,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            labelText: context.l10n.translate('sdmsClaimsPartnerSearchLabel'),
                            hintText: context.l10n.translate('sdmsClaimsPartnerSearchHintText'),
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColorsEnhanced.brandBlue,
                            ),
                            suffixIcon: _partnerSearchController.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear,
                                        color: AppColorsEnhanced.secondaryText),
                                    onPressed: () {
                                      setState(() {
                                        _partnerSearchController.clear();
                                        _searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColorsEnhanced.backgroundSecondary,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide(
                                color: AppColorsEnhanced.brandBlue,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: _onPartnerSearchChanged,
                        ),
                        SizedBox(height: AppSpacing.sm),

                        // Search results dropdown
                        if (_searchResults.isNotEmpty &&
                            _selectedPartner == null)
                          Container(
                            constraints: BoxConstraints(maxHeight: 200.h),
                            decoration: BoxDecoration(
                              color: AppColorsEnhanced.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColorsEnhanced.border,
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, color: AppColorsEnhanced.border),
                              itemBuilder: (context, index) {
                                final partner = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColorsEnhanced.brandBlue
                                        .withValues(alpha: 0.1),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColorsEnhanced.brandBlue,
                                      size: 20.sp,
                                    ),
                                  ),
                                  title: Text(
                                    partner.partnerName,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'ID: ${partner.partnerId}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColorsEnhanced.secondaryText,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16.sp,
                                    color: AppColorsEnhanced.secondaryText,
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedPartner = partner;
                                      _partnerSearchController.text =
                                          partner.partnerName;
                                      _searchResults = [];
                                    });
                                  },
                                );
                              },
                            ),
                          ),

                        // Loading indicator for partner search
                        if (state is PartnersLoading)
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColorsEnhanced.brandBlue,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Text(
                                  context.l10n.translate('commonSearchingStatus'),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColorsEnhanced.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Selected Partner Display
                        if (_selectedPartner != null)
                          Container(
                            padding: EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColorsEnhanced.successGreen
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: AppColorsEnhanced.successGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColorsEnhanced.successGreen
                                      .withValues(alpha: 0.2),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: AppColorsEnhanced.successGreen,
                                    size: 24.sp,
                                  ),
                                ),
                                SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        context.l10n.translate('sdmsClaimsSelectedPartnerLabel'),
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color:
                                              AppColorsEnhanced.successGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        _selectedPartner!.partnerName,
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        'ID: ${_selectedPartner!.partnerId}',
                                        style:
                                            AppTextStyles.labelSmall.copyWith(
                                          color:
                                              AppColorsEnhanced.secondaryText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    color: AppColorsEnhanced.errorRed,
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () {
                                          setState(() {
                                            _selectedPartner = null;
                                            _partnerSearchController.clear();
                                          });
                                        },
                                ),
                              ],
                            ),
                          ),

                        // Validation message when partner not selected
                        if (!_claimForMyself && _selectedPartner == null)
                          Padding(
                            padding: EdgeInsets.only(top: AppSpacing.sm),
                            child: Container(
                              padding: EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: AppColorsEnhanced.warningYellow
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: AppColorsEnhanced.warningYellow
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16.sp,
                                    color: AppColorsEnhanced.warningYellow,
                                  ),
                                  SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(
                                      context.l10n.translate('sdmsClaimsSelectPartnerValidationMessage'),
                                      style:
                                          AppTextStyles.labelSmall.copyWith(
                                        color: AppColorsEnhanced.warningYellow,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),

                  // Submit Button
                  ProfessionalButton(
                    text: _isSubmitting
                        ? context.l10n.translate('commonSubmittingStatus')
                        : context.l10n.translate('sdmsClaimsSubmitOrderButtonText'),
                    onPressed: _isSubmitting || !_isFormValid() ? null : _submit,
                    isLoading: _isSubmitting,
                    variant: ButtonVariant.primary,
                    fullWidth: true,
                    icon: Icons.send,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
