import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service_interface.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_extensions.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class CreateExtensionRequestPage extends StatefulWidget {
  const CreateExtensionRequestPage({Key? key}) : super(key: key);

  @override
  State<CreateExtensionRequestPage> createState() =>
      _CreateExtensionRequestPageState();
}

class _CreateExtensionRequestPageState
    extends State<CreateExtensionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _justificationController = TextEditingController();
  late final ApiServiceInterface _apiService;

  String? _selectedItemCode;
  Map<String, dynamic>? _selectedItem;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _quotaItems = [];
  bool _isLoadingItems = true;
  int _maxRequestable = 0;

  // Speech-to-text state
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastWords = '';

  // Audio recording state
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  int _recordDuration = 0;
  Timer? _recordTimer;
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<PlayerState>? _playerSub;

  @override
  void initState() {
    super.initState();
    _apiService = context.read<ApiServiceInterface>();
    _speech = stt.SpeechToText();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _loadQuotaItems();
    _initializeSpeech();
    _initializeAudio();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _justificationController.dispose();
    _speech.stop();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordTimer?.cancel();
    _recordSub?.cancel();
    _playerSub?.cancel();
    super.dispose();
  }

  Future<void> _loadQuotaItems() async {
    try {
      final snapshot = await _apiService.getQuotaSnapshot();
      setState(() {
        _quotaItems = snapshot.items
            .map((item) => {
                  'item_code': item.itemCode,
                  'item_name': item.itemName,
                  'available': item.availableBalance,
                  'credit_limit': item.creditLimit,
                })
            .toList();
        _isLoadingItems = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingItems = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load items: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedItemCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }

    // Audio justification is now required
    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio justification is required. Please record your justification.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _apiService.createCreditExtension(
        itemCode: _selectedItemCode!,
        requestedQuantity: int.parse(_quantityController.text),
        justification: _justificationController.text,
        audioPath: _audioPath,  // Include audio path
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Extension request submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildQuotaInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ====== Speech-to-Text Methods ======

  Future<void> _initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );
      setState(() {
        _speechAvailable = available;
      });
    } catch (e) {
      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      // Just update UI state - don't commit text here
      // Text is committed only when user manually stops
      setState(() {
        _isListening = false;
      });
    }
  }

  void _onSpeechError(dynamic error) {
    setState(() {
      _isListening = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Speech-to-text error: ${error.errorMsg ?? 'Unknown error'}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _handleMicTap() async {
    // If listening, stop it
    if (_isListening) {
      // Update UI immediately for instant feedback
      setState(() {
        _isListening = false;
      });

      // Commit any partial results
      if (_lastWords.isNotEmpty && mounted) {
        final currentText = _justificationController.text;
        final newText = currentText.isEmpty
            ? _lastWords
            : '$currentText $_lastWords';

        _justificationController.text = newText;
        _justificationController.selection = TextSelection.fromPosition(
          TextPosition(offset: newText.length),
        );

        setState(() {
          _lastWords = '';  // Clear the partial results
        });
      }

      // Stop speech recognition in background (non-blocking)
      _speech.stop();

      return;
    }

    // Check and request permission
    final permissionStatus = await Permission.microphone.request();

    if (!permissionStatus.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone permission is required for voice input'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
      return;
    }

    // Start ONLY speech-to-text (NO audio recording)
    await _startListening();
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition is not available on this device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    _lastWords = '';
    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
    );
  }

  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    // Don't commit text here - let user control when to commit by tapping mic
    // Just store the partial results in _lastWords
  }

  // ====== Audio Recording Methods ======

  Future<void> _initializeAudio() async {
    _recordSub = _audioRecorder.onStateChanged().listen((state) {
      if (mounted) {
        setState(() {
          _isRecording = state == RecordState.record;
        });
      }
    });

    _playerSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  Future<void> _startRecording({bool skipPermissionCheck = false}) async {
    try {
      if (!skipPermissionCheck) {
        final hasPermission = await _audioRecorder.hasPermission();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Microphone permission is required'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          }
          return;
        }
      }

      // Delete previous recording if exists
      if (_audioPath != null) {
        await _deleteAudio();
      }

      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _recordDuration = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration++;
          });

          // Auto-stop at 30 seconds
          if (_recordDuration >= 30) {
            _stopRecording();
          }
        }
      });

      setState(() {
        _audioPath = path;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();

      if (path != null && mounted) {
        setState(() {
          _audioPath = path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startPlaying() async {
    if (_audioPath == null) return;

    try {
      // Check if file exists
      final file = File(_audioPath!);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file not found. Please record again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize < 1000) {  // Less than 1KB is likely empty/corrupted
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio file is too small ($fileSize bytes). Recording may have failed. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopPlaying() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAudio() async {
    try {
      if (_audioPath != null) {
        final file = File(_audioPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await _audioPlayer.stop();

      if (mounted) {
        setState(() {
          _audioPath = null;
          _recordDuration = 0;
          _isPlaying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete audio: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.translate('creditExtensionCreateRequestPageTitle'), style: TextStyle(fontSize: 20.sp)),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoadingItems
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.translate('creditExtensionSelectItemCardTitle'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedItemCode,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: context.l10n.translate('creditExtensionSelectItemHintText'),
                              prefixIcon: const Icon(Icons.inventory_2),
                            ),
                            items: _quotaItems.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['item_code'],
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      item['item_name'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    SizedBox(width: 20.h),
                                    Text(
                                      'Code: ${item['item_code'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedItemCode = value;
                                if (value != null) {
                                  _selectedItem = _quotaItems.firstWhere(
                                    (item) => item['item_code'] == value,
                                  );

                                  final available = _selectedItem!['available'] as int;
                                  final creditLimit = _selectedItem!['credit_limit'] as int;

                                  // Calculate max requestable based on logic
                                  if (available >= 0) {
                                    _maxRequestable = creditLimit - available;
                                  } else {
                                    _maxRequestable = creditLimit;
                                  }
                                } else {
                                  _selectedItem = null;
                                  _maxRequestable = 0;
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.translate('creditExtensionSelectItemValidationMessage');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quota Information Card
                  if (_selectedItemCode != null)
                    Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.blue[200]!, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700], size: 20.sp),
                              SizedBox(width: 4.w),
                              Text(
                                context.l10n.translate('creditExtensionQuotaInformationCardTitle'),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20.h, color: Colors.blue[300]),
                          _buildQuotaInfoRow(
                            context.l10n.translate('creditExtensionAvailableBalanceLabel'),
                            '${_selectedItem!['available']}',
                            _selectedItem!['available'] < 0 ? Colors.red : Colors.green,
                          ),
                          SizedBox(height: 4.h),
                          _buildQuotaInfoRow(
                            context.l10n.translate('creditExtensionCreditLimitLabel'),
                            '${_selectedItem!['credit_limit']}',
                            Colors.blue[700]!,
                          ),
                          SizedBox(height: 4.h),
                          _buildQuotaInfoRow(
                            context.l10n.translate('creditExtensionMaxRequestableLabel'),
                            '$_maxRequestable',
                            Colors.orange[700]!,
                          ),
                        ],
                      ),
                    ),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.translate('commonQuantityLabel'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: context.l10n.translate('creditExtensionQuantityHintText'),
                              prefixIcon: const Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return context.l10n.translate('creditExtensionQuantityRequiredError');
                              }
                              final qty = int.tryParse(value);
                              if (qty == null || qty <= 0) {
                                return context.l10n.translate('creditExtensionQuantityGreaterThanZeroError');
                              }
                              if (_selectedItemCode != null && qty > _maxRequestable) {
                                return 'Maximum requestable: $_maxRequestable units';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Audio Justification Section
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.mic, color: AppColors.brandBlue),
                              SizedBox(width: 8.w),
                              Text(
                                context.l10n.translate('creditExtensionAudioJustificationLabel'),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // Recording Controls
                          Row(
                            children: [
                              // Record Button - Only show if no audio captured yet
                              if (_audioPath == null && !_isRecording)
                                ElevatedButton.icon(
                                  onPressed: _startRecording,
                                  icon: Icon(Icons.mic),
                                  label: Text(context.l10n.translate('creditExtensionRecordButtonLabel')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.brandBlue,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                ),

                              // Stop Button - Show during manual recording
                              if (_isRecording)
                                ElevatedButton.icon(
                                  onPressed: _stopRecording,
                                  icon: Icon(Icons.stop),
                                  label: Text(context.l10n.translate('creditExtensionStopButtonLabel')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                ),

                              if (_audioPath != null && !_isRecording)
                                SizedBox(width: 12.w),

                              // Play Button - Only show if audio exists
                              if (_audioPath != null)
                                ElevatedButton.icon(
                                  onPressed: _isPlaying ? _stopPlaying : _startPlaying,
                                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                                  label: Text(_isPlaying ? context.l10n.translate('creditExtensionPauseButtonLabel') : context.l10n.translate('creditExtensionPlayButtonLabel')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  ),
                                ),

                              if (_audioPath != null)
                                SizedBox(width: 12.w),

                              // Delete Button
                              if (_audioPath != null)
                                IconButton(
                                  onPressed: _deleteAudio,
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  tooltip: context.l10n.translate('creditExtensionDeleteAudioTooltip'),
                                ),

                              Spacer(),

                              // Duration Display
                              Text(
                                _formatDuration(_recordDuration),
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _isRecording ? Colors.red : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),

                          // Recording Indicator
                          if (_isRecording)
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    context.l10n.translate('creditExtensionRecordingStatus'),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Audio Status
                          if (_audioPath != null && !_isRecording)
                            Padding(
                              padding: EdgeInsets.only(top: 12.h),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    context.l10n.translate('creditExtensionAudioRecordedSuccessMessage'),
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Justification',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _justificationController,
                            decoration: InputDecoration(
                              labelText: context.l10n.translate('creditExtensionTextJustificationLabel'),
                              hintText: context.l10n.translate('creditExtensionTextJustificationHintText'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              prefixIcon: const Icon(Icons.description),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isListening ? Icons.mic : Icons.mic_none,
                                  color: _isListening
                                      ? Colors.red
                                      : (_speechAvailable ? AppColors.brandBlue : Colors.grey),
                                ),
                                onPressed: _speechAvailable ? _handleMicTap : null,
                                tooltip: _isListening ? 'Tap to stop listening' : 'Tap to speak',
                              ),
                              filled: true,
                              fillColor: _isListening ? Colors.red.withOpacity(0.05) : Colors.white,
                            ),
                            maxLines: 4,
                            minLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return context.l10n.translate('creditExtensionTextJustificationRequiredError');
                              }
                              if (value.trim().length < 10) {
                                return context.l10n.translate('creditExtensionTextJustificationMinError');
                              }
                              return null;
                            },
                          ),
                          // Listening indicator
                          if (_isListening)
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.l10n.translate('creditExtensionListeningStatus'),
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (_lastWords.isNotEmpty) ...[
                                            SizedBox(height: 4.h),
                                            Text(
                                              _lastWords,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: Colors.blue[700],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 32.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 2,
                      ),
                      child: _isSubmitting
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text('Submitting...', style: TextStyle(fontSize: 16.sp)),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(context.l10n.translate('creditExtensionSubmitRequestButtonText'), style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}
