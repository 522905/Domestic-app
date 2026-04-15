import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../domain/entities/offline_delivery/offline_delivery_token.dart';
import '../../blocs/offline_delivery/offline_delivery_bloc.dart';
import '../../blocs/offline_delivery/offline_delivery_event.dart';
import '../../blocs/offline_delivery/offline_delivery_state.dart';
import '../../widgets/professional_snackbar.dart';
import '../sdms/qr_scanner_page.dart';
import 'widgets/token_detail_sheet.dart';

class ScanTokenPage extends StatefulWidget {
  const ScanTokenPage({Key? key}) : super(key: key);

  @override
  State<ScanTokenPage> createState() => _ScanTokenPageState();
}

class _ScanTokenPageState extends State<ScanTokenPage> {
  bool _isScanning = false;
  List<OfflineDeliveryToken> _partnerTokens = [];
  bool _partnerLoading = true;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    // Load partner tokens once companies are available
  }

  void _loadPartnerTokens() {
    final state = context.read<OfflineDeliveryBloc>().state;
    if (state is OfflineDeliveryLoaded && state.companies.isNotEmpty) {
      final companyId = state.lastSelectedCompanyId ?? state.companies.first.id;
      context.read<OfflineDeliveryBloc>().add(
        LoadPartnerTokens(companyId: companyId),
      );
      _initialLoadDone = true;
    }
  }

  Future<void> _handleScanQR() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        context.showErrorSnackBar(
            'Camera permission is required to scan QR codes');
      }
      return;
    }

    if (!mounted) return;
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result == null || result.isEmpty || !mounted) return;

    setState(() => _isScanning = true);
    context.read<OfflineDeliveryBloc>().add(ScanToken(uuid: result));
  }

  void _openTokenDetail(OfflineDeliveryToken token) {
    final bloc = context.read<OfflineDeliveryBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: bloc,
        child: TokenDetailSheet(token: token, hidePrint: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OfflineDeliveryBloc, OfflineDeliveryState>(
      listener: (context, state) {
        // Load partner tokens once initial data is ready
        if (state is OfflineDeliveryLoaded && !_initialLoadDone) {
          _loadPartnerTokens();
        }

        if (state is PartnerTokensLoaded) {
          setState(() {
            _partnerTokens = state.tokens;
            _partnerLoading = false;
          });
        } else if (state is PartnerTokensLoading) {
          setState(() => _partnerLoading = true);
        } else if (state is TokenScanned) {
          setState(() {
            _isScanning = false;
            // Update partner list if token is there
            final idx = _partnerTokens.indexWhere((t) => t.id == state.token.id);
            if (idx != -1) {
              _partnerTokens[idx] = state.token;
            }
          });
          _openTokenDetail(state.token);
        } else if (state is TokenDelivered) {
          setState(() {
            final idx = _partnerTokens.indexWhere((t) => t.id == state.token.id);
            if (idx != -1) {
              _partnerTokens[idx] = state.token;
            }
          });
        } else if (state is ImagesAttached) {
          setState(() {
            final idx = _partnerTokens.indexWhere((t) => t.id == state.token.id);
            if (idx != -1) {
              _partnerTokens[idx] = state.token;
            }
          });
        } else if (state is TokenScanError) {
          setState(() => _isScanning = false);
          context.showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Token'),
          backgroundColor: AppColorsEnhanced.brandBlue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPartnerTokens,
            ),
          ],
        ),
        body: _isScanning
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Looking up token...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColorsEnhanced.secondaryText,
                      ),
                    ),
                  ],
                ),
              )
            : _partnerLoading
                ? const Center(child: CircularProgressIndicator())
                : _partnerTokens.isEmpty
                    ? _buildEmptyState()
                    : _buildTokenList(),
        floatingActionButton: _isScanning
            ? null
            : FloatingActionButton(
                onPressed: _handleScanQR,
                backgroundColor: AppColorsEnhanced.brandBlue,
                child: const Icon(Icons.qr_code_scanner, color: Colors.white),
              ),
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
            size: 64.sp,
            color: AppColorsEnhanced.secondaryText.withOpacity(0.3),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'No assigned tokens',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'Tap the scan button to scan a token QR',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenList() {
    return RefreshIndicator(
      onRefresh: () async => _loadPartnerTokens(),
      child: ListView.builder(
        padding: EdgeInsets.all(AppSpacing.md),
        itemCount: _partnerTokens.length,
        itemBuilder: (context, index) {
          return _buildTokenCard(_partnerTokens[index]);
        },
      ),
    );
  }

  Widget _buildTokenCard(OfflineDeliveryToken token) {
    final detail = token.obligationDetail;
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: InkWell(
        onTap: () {
          // Scan to get full detail with available_actions
          setState(() => _isScanning = true);
          context.read<OfflineDeliveryBloc>().add(ScanToken(uuid: token.id));
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Token number badge
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: _statusColor(token).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${token.tokenNumber ?? '?'}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _statusColor(token),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token.displayName,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        _buildBadge(
                          token.isPending
                              ? 'PENDING'
                              : token.isDelivered
                                  ? 'DELIVERED'
                                  : 'VOIDED',
                          _statusColor(token),
                        ),
                        if (token.isObligation) ...[
                          SizedBox(width: 4.w),
                          _buildBadge(
                              'OBLIGATION', AppColorsEnhanced.warningYellow),
                        ],
                      ],
                    ),
                    if (detail != null) ...[
                      SizedBox(height: 4),
                      Text(
                        '${detail.itemDisplayName} x${detail.quantity} - ${detail.deliveryTypeDisplay}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                    if (token.distributionPointName != null) ...[
                      SizedBox(height: 2),
                      Text(
                        token.distributionPointName!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.secondaryText,
                          fontSize: 10.sp,
                        ),
                      ),
                    ],
                    // Pending empties / cash indicators
                    if (detail != null && (detail.hasPendingEmpties || detail.hasPendingCash)) ...[
                      SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 4.h,
                        children: [
                          if (detail.hasPendingEmpties)
                            _buildPendingChip(
                              icon: Icons.swap_vert,
                              text: '${detail.emptiesCollected}/${detail.emptiesExpected} empties',
                              isOverdue: detail.isOverdueEmpties,
                              dueDate: detail.emptiesDueDate,
                            ),
                          if (detail.hasPendingCash)
                            _buildPendingChip(
                              icon: Icons.payments,
                              text: 'Cash pending',
                              isOverdue: detail.isOverdueCash,
                              dueDate: detail.cashDueDate,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: AppColorsEnhanced.secondaryText, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingChip({
    required IconData icon,
    required String text,
    required bool isOverdue,
    DateTime? dueDate,
  }) {
    final color = isOverdue ? AppColorsEnhanced.errorRed : AppColorsEnhanced.warningYellow;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (dueDate != null) ...[
            SizedBox(width: 4.w),
            Text(
              '(${dueDate.day}/${dueDate.month})',
              style: TextStyle(
                fontSize: 10.sp,
                color: color,
              ),
            ),
          ],
          if (isOverdue) ...[
            SizedBox(width: 4.w),
            Text(
              'OVERDUE',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: AppColorsEnhanced.errorRed,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(OfflineDeliveryToken token) {
    if (token.isDelivered) return AppColorsEnhanced.successGreen;
    if (token.isVoided) return AppColorsEnhanced.errorRed;
    return Colors.grey;
  }
}
