import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/entities/credit_extension/credit_extension.dart';
import '../../../domain/entities/credit_extension/credit_extension_context.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_bloc.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_state.dart';
import '../../blocs/gm_credit_approvals/gm_credit_approvals_event.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';

class GmCreditExtensionDetailPage extends StatefulWidget {
  final CreditExtension extension;

  const GmCreditExtensionDetailPage({
    Key? key,
    required this.extension,
  }) : super(key: key);

  @override
  State<GmCreditExtensionDetailPage> createState() =>
      _GmCreditExtensionDetailPageState();
}

class _GmCreditExtensionDetailPageState
    extends State<GmCreditExtensionDetailPage> {
  CreditExtensionContext? _context;
  bool _isLoadingContext = true;
  String? _contextError;

  // Audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Collapse/Expand state
  bool _isSnapshotExpanded = false;
  bool _isHistoryExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadContext();
    _initAudioPlayer();
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

  Future<void> _loadContext() async {
    setState(() => _isLoadingContext = true);
    try {
      // Access API service through the BLoC
      final bloc = context.read<GmCreditApprovalsBloc>();
      final extensionContext = await bloc.apiService.getCreditExtensionContext(widget.extension.id);
      setState(() {
        _context = extensionContext;
        _isLoadingContext = false;
      });
    } catch (e) {
      setState(() {
        _contextError = e.toString();
        _isLoadingContext = false;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('gmCreditExtensionDetailPageTitle')),
        backgroundColor: const Color(0xFF0E5CA8),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<GmCreditApprovalsBloc, GmCreditApprovalsState>(
        listener: (context, state) {
          if (state is GmCreditApprovalsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(
                context, true); // Return true to indicate refresh needed
          }

          if (state is GmCreditApprovalsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<GmCreditApprovalsBloc, GmCreditApprovalsState>(
          builder: (context, state) {
            if (state is GmCreditApprovalsProcessing) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 16.h),
                    const Text('Processing request...'),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5.h),
                    _buildRequestSummaryCard(),
                    SizedBox(height: 5.h),

                    // Context sections
                    if (_isLoadingContext)
                      _buildLoadingCard()
                    else if (_contextError != null)
                      _buildErrorCard(_contextError!)
                    else if (_context != null) ...[
                      _buildLiveSnapshotCard(_context!.liveSnapshot),
                      SizedBox(height: 12.h),
                      _buildQuotaHistoryCard(_context!.quotaHistory),
                      SizedBox(height: 12.h),
                      if (_context!.extensionHistory.isNotEmpty) ...[
                        _buildExtensionHistoryCard(_context!.extensionHistory),
                        SizedBox(height: 12.h),
                      ],
                      if (_context!.otherPendingRequests.isNotEmpty) ...[
                        _buildOtherPendingCard(_context!.otherPendingRequests),
                        SizedBox(height: 12.h),
                      ],
                    ],

                    SizedBox(height: 10.h),
                    _buildActionButtons(widget.extension),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  Widget _buildRequestSummaryCard() {
    final audioUrl = _context?.audioUrl ?? widget.extension.justificationAudioUrl;
    final hasAudio = audioUrl != null && audioUrl.isNotEmpty;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.blue.shade50.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5CA8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: const Color(0xFF0E5CA8),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.translate('gmCreditExtensionRequestSummaryCardTitle'),
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Request #${widget.extension.id}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),

              // Partner Section
              _buildSectionHeader(Icons.person, context.l10n.translate('commonPartnerDetailsLabel')),
              SizedBox(height: 12.h),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0E5CA8),
                    radius: 28.r,
                    child: Text(
                      widget.extension.partnerName?.substring(0, 1).toUpperCase() ?? 'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24.sp,
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.extension.partnerName ?? 'Unknown Partner',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            widget.extension.partnerCode ?? '',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),

              // Item Section
              _buildSectionHeader(Icons.inventory_2, 'Item Details'),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    // Item Name Column
                    Expanded(
                      flex: 3,
                      child: _buildItemColumn(
                        Icons.label,
                        context.l10n.translate('commonItemNameLabel'),
                        widget.extension.itemName,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Vertical Divider
                    Container(
                      height: 50.h,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(width: 12.w),
                    // Item Code Column
                    Expanded(
                      flex: 2,
                      child: _buildItemColumn(
                        Icons.qr_code_2,
                        context.l10n.translate('commonItemCodeLabel'),
                        widget.extension.itemCode,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Vertical Divider
                    Container(
                      height: 50.h,
                      width: 1,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(width: 12.w),
                    // Quantity Column
                    Expanded(
                      flex: 2,
                      child: _buildItemColumn(
                        Icons.production_quantity_limits,
                        context.l10n.translate('creditExtensionRequestedQuantityLabel'),
                        widget.extension.requestedQuantity.toString(),
                        valueColor: const Color(0xFF0E5CA8),
                        isBold: true,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              Divider(height: 1, color: Colors.grey.shade300),
              SizedBox(height: 20.h),

              // Justification Section
              _buildSectionHeader(
                hasAudio ? Icons.mic : Icons.message,
                'Justification',
              ),
              SizedBox(height: 12.h),

              // Audio Player (if available)
              if (hasAudio) ...[
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
                              onPressed: () => _playPauseAudio(audioUrl!),
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
                SizedBox(height: 12.h),
              ],

              // Text Justification
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.format_quote, color: Colors.grey.shade500, size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'Written Justification',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      (_context?.justification?.isNotEmpty ?? false)
                          ? _context!.justification!
                          : widget.extension.justification,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade800,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: const Color(0xFF0E5CA8)),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildItemColumn(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 24.sp,
          color: valueColor ?? Colors.grey.shade600,
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? Colors.grey.shade900,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Center(
          child: Column(
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: 16.h),
              Text(
                'Loading decision context...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32.sp),
            SizedBox(height: 12.h),
            Text(
              'Failed to load context',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveSnapshotCard(LiveQuotaSnapshot snapshot) {
    final isNegative = snapshot.availableBalance < 0;

    return Card(
      elevation: 2,
      color: snapshot.isBlocked ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: snapshot.isBlocked
            ? BorderSide(color: Colors.red.shade300, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        context.l10n.translate('gmCreditExtensionLiveQuotaSnapshotCardTitle'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      if (snapshot.isBlocked) ...[
                        SizedBox(width: 12.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'BLOCKED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Collapse/Expand Button
                IconButton(
                  icon: Icon(
                    _isSnapshotExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF0E5CA8),
                  ),
                  onPressed: () {
                    setState(() {
                      _isSnapshotExpanded = !_isSnapshotExpanded;
                    });
                  },
                  tooltip: _isSnapshotExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),

            if (_isSnapshotExpanded) ...[
              SizedBox(height: 16.h),

            // Available Balance - Prominent
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isNegative ? Colors.red.shade100 : Colors.green.shade100,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.translate('creditExtensionAvailableBalanceLabel'),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        snapshot.availableBalance.toString(),
                        style: TextStyle(
                          fontSize: 32.sp,
                          fontWeight: FontWeight.bold,
                          color: isNegative ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    isNegative ? Icons.arrow_downward : Icons.check_circle,
                    color: isNegative ? Colors.red.shade700 : Colors.green.shade700,
                    size: 40.sp,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16.h),

            // Breakdown
            Text(
              'Breakdown',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            _buildSnapshotRow('Opening', snapshot.opening),
            _buildSnapshotRow('Adjustments', snapshot.adjustments, showSign: true),
            _buildSnapshotRow('Orders', snapshot.orders, showSign: true),
            _buildSnapshotRow('Pickups', snapshot.pickups, showSign: true),
            _buildSnapshotRow('Returns', snapshot.returns, showSign: true),
            _buildSnapshotRow('SDMS Sales', snapshot.sdmsSales, showSign: true),
            Divider(height: 24.h),
            _buildSnapshotRow('Closing Balance', snapshot.closing, isBold: true),
            _buildSnapshotRow('Bonus', snapshot.bonus, showSign: true),
            _buildSnapshotRow('Credit Limit', snapshot.creditLimit, showSign: true),
            Divider(height: 24.h, thickness: 2),
            _buildSnapshotRow(
              context.l10n.translate('creditExtensionAvailableBalanceLabel'),
              snapshot.availableBalance,
              isBold: true,
              valueColor: isNegative ? Colors.red.shade700 : Colors.green.shade700,
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSnapshotRow(
    String label,
    int value, {
    bool showSign = false,
    bool isBold = false,
    Color? valueColor,
  }) {
    String valueText = value.toString();
    if (showSign && value > 0) {
      valueText = '+$valueText';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14.sp : 13.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            valueText,
            style: TextStyle(
              fontSize: isBold ? 14.sp : 13.sp,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaHistoryCard(QuotaHistory history) {
    final avgPostingRatio = history.aggregates.avgPostingRatio;
    final isLowPosting = avgPostingRatio < 80;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.translate('gmCreditExtensionQuotaHistoryCardTitle'),
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${DateFormat('dd MMM').format(history.dateRange.from)} - ${DateFormat('dd MMM yyyy').format(history.dateRange.to)}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Collapse/Expand Button
                IconButton(
                  icon: Icon(
                    _isHistoryExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF0E5CA8),
                  ),
                  onPressed: () {
                    setState(() {
                      _isHistoryExpanded = !_isHistoryExpanded;
                    });
                  },
                  tooltip: _isHistoryExpanded ? 'Collapse' : 'Expand',
                ),
              ],
            ),

            if (_isHistoryExpanded) ...[
              SizedBox(height: 16.h),

            // Aggregates
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: isLowPosting ? Colors.orange.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: isLowPosting
                    ? Border.all(color: Colors.orange.shade300)
                    : null,
              ),
              child: Column(
                children: [
                  _buildAggregateRow('Avg Daily Pickups', history.aggregates.avgDailyPickups.toStringAsFixed(1)),
                  _buildAggregateRow('Total Orders', history.aggregates.totalOrders.toString()),
                  _buildAggregateRow('Total Pickups', history.aggregates.totalPickups.toString()),
                  _buildAggregateRow('Total SDMS Sales', history.aggregates.totalSdmsSales.toString()),
                  Divider(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Avg Posting Ratio',
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (isLowPosting) ...[
                            SizedBox(width: 8.w),
                            Icon(Icons.warning, color: Colors.orange, size: 16.sp),
                          ],
                        ],
                      ),
                      Text(
                        '${avgPostingRatio.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: isLowPosting ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (isLowPosting) ...[
                    SizedBox(height: 8.h),
                    Text(
                      'Warning: Posting ratio below 80%',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAggregateRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionHistoryCard(List<ExtensionHistoryEntry> history) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.translate('gmCreditExtensionExtensionHistoryCardTitle'),
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.h),
            ...history.map((entry) => _buildExtensionHistoryItem(entry)),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionHistoryItem(ExtensionHistoryEntry entry) {
    final isApproved = entry.isApproved;
    final isRejected = entry.isRejected;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isApproved
              ? Colors.green.shade200
              : isRejected
                  ? Colors.red.shade200
                  : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requested: ${entry.requestedQuantity}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isApproved
                      ? Colors.green
                      : isRejected
                          ? Colors.red
                          : Colors.orange,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  entry.status.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            DateFormat('dd MMM yyyy, HH:mm').format(entry.requestedAt),
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey.shade600,
            ),
          ),
          if (isApproved && entry.approvedQuantity != null) ...[
            SizedBox(height: 8.h),
            Text(
              'Approved: ${entry.approvedQuantity}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (entry.quantityConsumed != null)
              Text(
                'Consumed: ${entry.quantityConsumed}/${entry.approvedQuantity}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
          if (isRejected && entry.rejectionReason != null) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                'Reason: ${entry.rejectionReason}',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOtherPendingCard(List<PendingRequest> requests) {
    return Card(
      elevation: 2,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: Colors.orange.shade300, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange, size: 24.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    'Other Pending Requests (${requests.length})',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              'This partner has ${requests.length} other pending request${requests.length > 1 ? 's' : ''}:',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 12.h),
            ...requests.map((req) => _buildPendingRequestItem(req)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequestItem(PendingRequest request) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.itemName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  request.itemCode,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              'Qty: ${request.requestedQuantity}',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CreditExtension extension) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showRejectionDialog(extension),
              icon: const Icon(Icons.cancel),
              label: Text(context.l10n.translate('commonRejectButton')),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showApprovalDialog(extension),
              icon: const Icon(Icons.check_circle),
              label: Text(context.l10n.translate('commonApproveButton')),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(CreditExtension extension) {
    int approvedQuantity = extension.requestedQuantity;
    DateTime? validUntil;
    final quantityController = TextEditingController(
      text: approvedQuantity.toString(),
    );

    // Store BLoC reference before opening dialog
    final bloc = context.read<GmCreditApprovalsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 24.sp),
              SizedBox(width: 8.w),
              Text(context.l10n.translate('gmCreditExtensionApproveRequestDialogTitle')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.translate('gmCreditExtensionApproveRequestDescription'),
                  style: TextStyle(fontSize: 14.sp),
                ),
                SizedBox(height: 16.h),

                // Quantity Input
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('commonQuantityLabel'),
                    hintText: context.l10n.translate('creditExtensionQuantityHintText'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    prefixIcon: const Icon(Icons.numbers),
                  ),
                  onChanged: (value) {
                    approvedQuantity =
                        int.tryParse(value) ?? extension.requestedQuantity;
                  },
                ),

                SizedBox(height: 16.h),

                // Date Picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        validUntil = picked;
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('gmCreditExtensionValidUntilDialogLabel'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: validUntil != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  validUntil = null;
                                });
                              },
                            )
                          : null,
                    ),
                    child: Text(
                      validUntil != null
                          ? DateFormat('dd MMM yyyy').format(validUntil!)
                          : context.l10n.translate('gmCreditExtensionSelectDatePlaceholder'),
                      style: TextStyle(
                        fontSize: 14.sp,
                        color:
                            validUntil != null ? Colors.black87 : Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.translate('commonCancelButton')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                bloc.add(
                  ApproveExtension(
                    extensionId: extension.id,
                    approvedQuantity: approvedQuantity,
                    validUntil: validUntil,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: Text(context.l10n.translate('commonApproveButton')),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectionDialog(CreditExtension extension) {
    String? selectedReason;

    final rejectionReasons = [
      'Insufficient documentation',
      'Quota limit exceeded',
      'Invalid request timing',
      'Business policy violation',
      'Partner credit history concerns',
      'Other operational reasons',
    ];

    // Store BLoC reference before opening dialog
    final bloc = context.read<GmCreditApprovalsBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 24.sp),
              SizedBox(width: 8.w),
              Text(context.l10n.translate('gmCreditExtensionRejectRequestDialogTitle')),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.translate('gmCreditExtensionSelectRejectionReasonDescription'),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  constraints: BoxConstraints(maxHeight: 300.h),
                  child: SingleChildScrollView(
                    child: Column(
                      children: rejectionReasons.map((reason) {
                        return RadioListTile<String>(
                          title: Text(reason),
                          value: reason,
                          groupValue: selectedReason,
                          onChanged: (value) {
                            setState(() {
                              selectedReason = value;
                            });
                          },
                          dense: true,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.translate('commonCancelButton')),
            ),
            ElevatedButton(
              onPressed: selectedReason == null
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      bloc.add(
                        RejectExtension(
                          extensionId: extension.id,
                          rejectionReason: selectedReason!,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(context.l10n.translate('commonRejectButton')),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'just now';
    }
  }
}
