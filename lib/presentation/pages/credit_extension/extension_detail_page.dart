import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';

class ExtensionDetailPage extends StatefulWidget {
  final CreditExtension? extension;
  final int? extensionId;

  const ExtensionDetailPage({
    Key? key,
    this.extension,
    this.extensionId,
  }) : super(key: key);

  @override
  State<ExtensionDetailPage> createState() => _ExtensionDetailPageState();
}

class _ExtensionDetailPageState extends State<ExtensionDetailPage> {
  late final ApiServiceInterface _apiService;
  CreditExtension? _extension;
  bool _isLoading = true;
  String? _errorMessage;

  // Audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiServiceInterface>();
    _initAudioPlayer();

    // If extension object is provided, show it immediately
    if (widget.extension != null) {
      _extension = widget.extension;
      _isLoading = false;
      // But still fetch complete details in background
      _loadExtensionDetail();
    } else if (widget.extensionId != null) {
      // Otherwise, fetch from API with loading state
      _loadExtensionDetail();
    }
  }

  void _initAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadExtensionDetail() async {
    final id = widget.extension?.id ?? widget.extensionId;
    if (id == null) return;

    // Only show loading if we don't have initial data
    if (widget.extension == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _apiService.getCreditExtensionDetail(id);
      setState(() {
        _extension = CreditExtension.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor() {
    if (_extension == null) return Colors.grey;
    switch (_extension!.status) {
      case CreditExtensionStatus.pending:
        return Colors.orange;
      case CreditExtensionStatus.approved:
        return Colors.green;
      case CreditExtensionStatus.rejected:
        return Colors.red;
    }
  }

  String _getStatusText() {
    if (_extension == null) return '';
    switch (_extension!.status) {
      case CreditExtensionStatus.pending:
        return 'Pending Approval';
      case CreditExtensionStatus.approved:
        return 'Approved';
      case CreditExtensionStatus.rejected:
        return 'Rejected';
    }
  }

  Future<void> _playPauseAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_position == Duration.zero) {
          await _audioPlayer.play(UrlSource(audioUrl));
        } else {
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to play audio: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _seekAudio(double value) async {
    final position = Duration(seconds: value.toInt());
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('creditExtensionDetailPageTitle'), style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadExtensionDetail,
                        child: Text(context.l10n.translate('commonRetryButton')),
                      ),
                    ],
                  ),
                )
              : _extension == null
                  ? Center(child: Text(context.l10n.translate('creditExtensionNotFoundMessage')))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Status Header
                        Card(
                          color: _getStatusColor().withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor().withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _extension!.isPending
                                        ? Icons.schedule
                                        : _extension!.isApproved
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                    size: 48,
                                    color: _getStatusColor(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _getStatusText(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Item Details
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.translate('creditExtensionItemDetailsCardTitle'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.inventory_2,
                                  context.l10n.translate('commonItemNameLabel'),
                                  _extension!.itemName,
                                ),
                                _buildInfoRow(
                                  Icons.qr_code,
                                  context.l10n.translate('commonItemCodeLabel'),
                                  _extension!.itemCode,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Request Information
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.l10n.translate('creditExtensionRequestInfoCardTitle'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildInfoRow(
                                  Icons.numbers,
                                  context.l10n.translate('creditExtensionRequestedQuantityLabel'),
                                  '${_extension!.requestedQuantity}',
                                ),
                                _buildInfoRow(
                                  Icons.calendar_today,
                                  context.l10n.translate('commonCreatedAtLabel'),
                                  dateFormat.format(_extension!.createdAt),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  context.l10n.translate('creditExtensionJustificationLabel'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Audio Player (if available)
                                if (_extension!.hasAudio && _extension!.justificationAudioUrl != null) ...[
                                  Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.purple.shade50,
                                          Colors.blue.shade50,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                      border: Border.all(color: Colors.purple.shade200),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.headphones, color: Colors.purple.shade600, size: 20.sp),
                                            SizedBox(width: 8.w),
                                            Text(
                                              context.l10n.translate('creditExtensionVoiceRecordingLabel'),
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.purple.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12.h),
                                        Row(
                                          children: [
                                            // Play/Pause Button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.purple.shade200,
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                                  color: Colors.purple.shade600,
                                                  size: 28.sp,
                                                ),
                                                onPressed: () => _playPauseAudio(_extension!.justificationAudioUrl!),
                                              ),
                                            ),
                                            SizedBox(width: 12.w),
                                            // Progress bar
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  SliderTheme(
                                                    data: SliderThemeData(
                                                      trackHeight: 4.h,
                                                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                                                      overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                                                    ),
                                                    child: Slider(
                                                      value: _position.inSeconds.toDouble(),
                                                      max: _duration.inSeconds.toDouble() > 0
                                                          ? _duration.inSeconds.toDouble()
                                                          : 1.0,
                                                      activeColor: Colors.purple.shade600,
                                                      inactiveColor: Colors.purple.shade200,
                                                      onChanged: _seekAudio,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          _formatDuration(_position),
                                                          style: TextStyle(
                                                            fontSize: 11.sp,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatDuration(_duration),
                                                          style: TextStyle(
                                                            fontSize: 11.sp,
                                                            color: Colors.grey.shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // Text Justification
                                if (_extension!.justification.isNotEmpty)
                                  Text(_extension!.justification)
                                else
                                  Text(
                                    context.l10n.translate('creditExtensionNoWrittenJustificationMessage'),
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Approval Information
                        if (_extension!.isApproved) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.green.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.translate('creditExtensionApprovalDetailsCardTitle'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildInfoRow(
                                    Icons.check,
                                    context.l10n.translate('creditExtensionApprovedQuantityLabel'),
                                    '${_extension!.approvedQuantity}',
                                  ),
                                  _buildInfoRow(
                                    Icons.person,
                                    context.l10n.translate('creditExtensionApprovedByLabel'),
                                    _extension!.approvedBy ?? context.l10n.translate('commonNotAvailableText'),
                                  ),
                                  if (_extension!.approvedAt != null)
                                    _buildInfoRow(
                                      Icons.access_time,
                                      context.l10n.translate('creditExtensionApprovedAtLabel'),
                                      dateFormat.format(_extension!.approvedAt!),
                                    ),
                                  if (_extension!.validUntil != null)
                                    _buildInfoRow(
                                      Icons.event,
                                      context.l10n.translate('creditExtensionValidUntilLabel'),
                                      DateFormat('MMM dd, yyyy')
                                          .format(_extension!.validUntil!),
                                    ),
                                  const Divider(height: 24),
                                  Text(
                                    context.l10n.translate('creditExtensionUsageBreakdownLabel'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildUsageRow(
                                    context.l10n.translate('creditExtensionReservedLabel'),
                                    _extension!.quantityReserved ?? 0,
                                    Colors.orange,
                                  ),
                                  _buildUsageRow(
                                    context.l10n.translate('creditExtensionConsumedLabel'),
                                    _extension!.quantityConsumed ?? 0,
                                    Colors.blue,
                                  ),
                                  _buildUsageRow(
                                    context.l10n.translate('creditExtensionRemainingLabel'),
                                    _extension!.quantityRemaining ?? 0,
                                    Colors.green,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Rejection Information
                        if (_extension!.isRejected &&
                            _extension!.rejectionReason != null) ...[
                          const SizedBox(height: 16),
                          Card(
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.cancel,
                                          color: Colors.red.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.translate('creditExtensionRejectionDetailsCardTitle'),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    context.l10n.translate('commonReasonLabel'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_extension!.rejectionReason!),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 100),
                      ],
                    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color),
            ),
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
