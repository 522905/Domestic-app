import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors_enhanced.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/ujjwala/lpg_ops_installation.dart';
import '../../../domain/entities/ujjwala/ujjwala_application_detail.dart';
import '../../widgets/professional/professional_empty_state.dart';
import '../../widgets/professional/professional_status_badge.dart';

class InstallationDetailPage extends StatefulWidget {
  final LpgOpsInstallation installation;

  const InstallationDetailPage({Key? key, required this.installation})
      : super(key: key);

  @override
  State<InstallationDetailPage> createState() => _InstallationDetailPageState();
}

class _InstallationDetailPageState extends State<InstallationDetailPage> {
  bool _isLoading = true;
  String? _error;
  UjjwalaApplicationDetail? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final apiService = context.read<ApiServiceInterface>();
      final json = await apiService
          .getUjjwalaApplicationDetail(widget.installation.disbursementId);
      final detail = UjjwalaApplicationDetail.fromJson(json);
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.installation.consumerName.isNotEmpty
              ? widget.installation.consumerName
              : 'Installation Detail',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColorsEnhanced.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColorsEnhanced.brandBlue),
      );
    }

    if (_error != null) {
      return ProfessionalEmptyState(
        icon: Icons.error_outline,
        message: 'Failed to load details',
        description: _error,
        actionText: 'Retry',
        onAction: _loadDetail,
      );
    }

    final detail = _detail!;

    return RefreshIndicator(
      onRefresh: _loadDetail,
      color: AppColorsEnhanced.brandBlue,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionCard(
                  title: 'Applicant Information',
                  rows: [
                    _InfoRow('Name', detail.applicantName),
                    _InfoRow('Mobile', detail.applicantMobile),
                    _InfoRow('Date of Birth', detail.dateOfBirth),
                    _InfoRow('Gender', detail.gender),
                    _InfoRow('Caste', detail.caste),
                    if (detail.aadhaarNumber.isNotEmpty)
                      _InfoRow('Aadhaar', detail.aadhaarNumber),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Bank Details',
                  rows: [
                    _InfoRow('Bank Name', detail.bankName),
                    _InfoRow('Account Name', detail.bankAccountName),
                    _InfoRow('Account Number', detail.bankAccountNumber),
                    _InfoRow('IFSC Code', detail.ifscCode),
                    _InfoRow('Branch', detail.branchName),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Consumer Info',
                  rows: [
                    _InfoRow('Consumer ID', detail.consumerId),
                    _InfoRow('LPG Connection Type', detail.lgpConnectionType),
                    _InfoRow('Application Status', detail.applicationStatus),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                _SectionCard(
                  title: 'Address & Location',
                  rows: [
                    _InfoRow('Address', detail.fullAddress),
                    if (detail.latitude.isNotEmpty && detail.longitude.isNotEmpty)
                      _InfoRow(
                        'GPS',
                        '${detail.latitude}, ${detail.longitude}',
                        mapsUrl: detail.googleMapsUrl.isNotEmpty
                            ? detail.googleMapsUrl
                            : null,
                      ),
                  ],
                ),
                if (detail.documents.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  _DocumentsSection(documents: detail.documents),
                ],
                if (detail.installationStatus != null) ...[
                  SizedBox(height: AppSpacing.md),
                  _InstallationStatusSection(detail: detail),
                ],
                SizedBox(height: AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColorsEnhanced.brandBlue,
              ),
            ),
          ),
          Divider(color: AppColorsEnhanced.border, height: 1),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: rows,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? mapsUrl;

  const _InfoRow(this.label, this.value, {this.mapsUrl});

  @override
  Widget build(BuildContext context) {
    final display = value.isNotEmpty ? value : '—';
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130.w,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColorsEnhanced.secondaryText,
              ),
            ),
          ),
          Expanded(
            child: mapsUrl != null
                ? GestureDetector(
                    onTap: () => _openUrl(context, mapsUrl!),
                    child: Text(
                      display,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColorsEnhanced.brandBlue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    display,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openUrl(BuildContext context, String url) {
    // Graceful: if url_launcher is not available, show snackbar with coordinates
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maps: $url'),
        action: SnackBarAction(label: 'OK', onPressed: () {}),
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  final List<Map<String, String>> documents;

  const _DocumentsSection({required this.documents});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'Pre-Suraksha Documents',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColorsEnhanced.brandBlue,
              ),
            ),
          ),
          Divider(color: AppColorsEnhanced.border, height: 1),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: documents.map((doc) {
                final docType = doc['doc_type'] ?? '';
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsEnhanced.backgroundSecondary,
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(color: AppColorsEnhanced.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 14.r,
                        color: AppColorsEnhanced.brandBlue,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        docType.isNotEmpty ? docType : 'Document',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColorsEnhanced.brandBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallationStatusSection extends StatelessWidget {
  final UjjwalaApplicationDetail detail;

  const _InstallationStatusSection({required this.detail});

  @override
  Widget build(BuildContext context) {
    final status = detail.installationStatus ?? '';
    final photos = <_PhotoEntry>[
      if (detail.kitchenPhotoUrl != null && detail.kitchenPhotoUrl!.isNotEmpty)
        _PhotoEntry('Kitchen', detail.kitchenPhotoUrl!),
      if (detail.gatePhotoUrl != null && detail.gatePhotoUrl!.isNotEmpty)
        _PhotoEntry('Gate', detail.gatePhotoUrl!),
      if (detail.stovePhotoUrl != null && detail.stovePhotoUrl!.isNotEmpty)
        _PhotoEntry('Stove', detail.stovePhotoUrl!),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColorsEnhanced.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'Installation Status',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColorsEnhanced.brandBlue,
              ),
            ),
          ),
          Divider(color: AppColorsEnhanced.border, height: 1),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (status.isNotEmpty)
                  ProfessionalStatusBadge(
                    status: status,
                    size: BadgeSize.medium,
                  ),

                if (detail.rejectionReason != null &&
                    detail.rejectionReason!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColorsEnhanced.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColorsEnhanced.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColorsEnhanced.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          detail.rejectionReason!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColorsEnhanced.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (photos.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Photos',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColorsEnhanced.secondaryText,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    children: photos
                        .map(
                          (p) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: AppSpacing.sm),
                              child: _PhotoThumbnail(entry: p),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoEntry {
  final String label;
  final String url;
  const _PhotoEntry(this.label, this.url);
}

class _PhotoThumbnail extends StatelessWidget {
  final _PhotoEntry entry;

  const _PhotoThumbnail({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFullScreen(context),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.network(
              entry.url,
              height: 80.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80.h,
                color: AppColorsEnhanced.backgroundSecondary,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: AppColorsEnhanced.secondaryText,
                ),
              ),
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 80.h,
                  color: AppColorsEnhanced.backgroundSecondary,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2,
                      color: AppColorsEnhanced.brandBlue,
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            entry.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColorsEnhanced.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(entry.label),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(entry.url),
            ),
          ),
        ),
      ),
    );
  }
}
