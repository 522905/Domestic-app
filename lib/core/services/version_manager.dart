// lib/core/services/version_manager.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';
import 'User.dart';

enum UpdateType { none, inform, nudge, block }

class UpdateStatus {
  final UpdateType type;
  final String? message;
  final String? apkUrl;
  final String? latestVersion;
  final bool isBeta;

  UpdateStatus({
    required this.type,
    this.message,
    this.apkUrl,
    this.latestVersion,
    this.isBeta = false,
  });
}

class VersionManager {
  static final _instance = VersionManager._internal();
  factory VersionManager() => _instance;
  VersionManager._internal();

  final _prefs = SharedPreferences.getInstance();
  final Dio _dio = Dio();

  String? _deviceId;
  String? _currentVersion;
  UpdateStatus? _currentStatus;
  bool _isBetaUser = false;

  // Callbacks for UI updates
  Function(UpdateStatus)? onStatusChanged;
  Function(double)? onDownloadProgress;

  Future<void> initialize() async {
    final prefs = await _prefs;
    final packageInfo = await PackageInfo.fromPlatform();

    _currentVersion = packageInfo.version;
    _deviceId = await _getOrCreateDeviceId();
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await _prefs;
    String? deviceId = prefs.getString('device_uuid');

    if (deviceId == null) {
      deviceId = _generateUUID();
      await prefs.setString('device_uuid', deviceId);
    }

    return deviceId;
  }

  String _generateUUID() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = (now * 1000 + (now % 1000)).toString();
    return 'flutter_${random}_${now}';
  }

  // Process headers from API responses
  void processVersionHeaders(Map<String, dynamic> headers) {
    final status = headers['x-update-status']?.first;
    if (status == null) return;

    UpdateType updateType;
    switch (status) {
      case 'available':
        updateType = UpdateType.inform;
        break;
      case 'recommended':
        updateType = UpdateType.nudge;
        break;
      case 'beta':
        updateType = UpdateType.inform;
        _isBetaUser = true;
        break;
      default:
        return;
    }

    _currentStatus = UpdateStatus(
      type: updateType,
      message: 'Update available',
      isBeta: status == 'beta',
    );

    onStatusChanged?.call(_currentStatus!);
  }

  // Check version via API
  Future<UpdateStatus> checkVersionViaAPI() async {
    try {
      final user = User();
      final token = await user.getToken();

      final response = await _dio.get(
        'http://192.168.171.49:9900/app-config',
        // 'https://lpg.ops.arungas.com/app-config',
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        ),
      );

      final data = response.data['android'];
      if (data == null) {
        return UpdateStatus(type: UpdateType.none);
      }

      final status = _determineUpdateType(data);

      _currentStatus = UpdateStatus(
        type: status,
        message: _getMessage(data, status),
        apkUrl: data['apk_url'],
        latestVersion: data['latest'],
        isBeta: data['update_channel'] == 'beta',
      );

      _isBetaUser = _currentStatus!.isBeta;

      // Handle nudge dismissal tracking
      if (status == UpdateType.nudge) {
        final shouldShow = await _shouldShowNudge(data['latest']);
        if (!shouldShow) {
          _currentStatus = UpdateStatus(type: UpdateType.none);
        }
      }

      onStatusChanged?.call(_currentStatus!);
      return _currentStatus!;

    } catch (e) {
      print('Version check error: $e');
      return UpdateStatus(type: UpdateType.none);
    }
  }

  UpdateType _determineUpdateType(Map<String, dynamic> config) {
    if (_currentVersion == null) return UpdateType.none;

    try {
      // Check blocked versions
      final blockedVersions = List<String>.from(config['blocked_versions'] ?? []);
      if (blockedVersions.contains(_currentVersion)) {
        return UpdateType.block;
      }

      // Check minimum version
      if (_compareVersions(_currentVersion!, config['min_supported']) < 0) {
        return UpdateType.block;
      }

      // Check soft minimum
      final softMin = config['soft_min'] ?? config['min_supported'];
      if (_compareVersions(_currentVersion!, softMin) < 0) {
        return UpdateType.nudge;
      }

      // Check if update available
      if (_compareVersions(_currentVersion!, config['latest']) < 0) {
        return UpdateType.inform;
      }

      return UpdateType.none;
    } catch (e) {
      print('Version comparison error: $e');
      return UpdateType.none;
    }
  }

  String _getMessage(Map<String, dynamic> config, UpdateType type) {
    final messages = config['messages'] as Map<String, dynamic>? ?? {};
    switch (type) {
      case UpdateType.block:
        return messages['block'] ?? 'Your app version is no longer supported. Please update to continue.';
      case UpdateType.nudge:
        return messages['nudge'] ?? 'An update is recommended for the best experience.';
      case UpdateType.inform:
        return messages['update'] ?? 'A new version is available.';
      default:
        return '';
    }
  }

  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    while (parts1.length < parts2.length) parts1.add(0);
    while (parts2.length < parts1.length) parts2.add(0);

    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] < parts2[i]) return -1;
      if (parts1[i] > parts2[i]) return 1;
    }

    return 0;
  }

  // Nudge dismissal tracking
  Future<bool> _shouldShowNudge(String version) async {
    final prefs = await _prefs;
    final key = 'nudge_dismissed_$version';
    final dismissedTime = prefs.getInt(key);

    if (dismissedTime == null) return true;

    final elapsed = DateTime.now().millisecondsSinceEpoch - dismissedTime;
    return elapsed > (12 * 60 * 60 * 1000); // 12 hours
  }

  Future<void> dismissNudge() async {
    if (_currentStatus?.latestVersion == null) return;

    final prefs = await _prefs;
    final key = 'nudge_dismissed_${_currentStatus!.latestVersion}';
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  // Download APK with progress
  Future<void> downloadAndInstallAPK([UpdateStatus? status]) async {
    final updateStatus = status ?? _currentStatus;

    if (updateStatus?.apkUrl == null) {
      throw Exception('No APK URL available');
    }

    final permissionStatus = await Permission.storage.request();
    if (!permissionStatus.isGranted) {
      throw Exception('Storage permission denied');
    }

    final dir = await getExternalStorageDirectory();
    final fileName = 'app_update_${updateStatus!.latestVersion ?? 'latest'}.apk';
    final savePath = '${dir!.path}/$fileName';

    try {
      await _dio.download(
        updateStatus.apkUrl!,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            onDownloadProgress?.call(progress);
          }
        },
      );

      await OpenFile.open(savePath);

    } catch (e) {
      print('Download error: $e');
      throw Exception('Failed to download update: $e');
    }
  }

  // Getters and Setters
  String? get deviceId => _deviceId;
  String? get currentVersion => _currentVersion;
  UpdateStatus? get currentStatus => _currentStatus;
  bool get isBetaUser => _isBetaUser;

  // Set current status (needed when handling 426 from login)
  void setCurrentStatus(UpdateStatus status) {
    _currentStatus = status;
    _isBetaUser = status.isBeta;
  }

  // Headers for API requests
  Map<String, String> getVersionHeaders() {
    return {
      'X-App-Version': _currentVersion ?? '',
      'X-Device-ID': _deviceId ?? '',
      'X-App-Platform': 'android',
    };
  }

  Future<void> downloadAndInstallAPKWithProgress(
      BuildContext context,
      [UpdateStatus? status]
      ) async {
    final updateStatus = status ?? _currentStatus;

    if (updateStatus?.apkUrl == null) {
      throw Exception('No APK URL available');
    }

    final installPermission = await Permission.requestInstallPackages.request();
    if (!installPermission.isGranted) {
      throw Exception('Install permission denied');
    }

    // Use a simpler approach with overlays
    OverlayEntry? overlayEntry;
    final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    overlayEntry = OverlayEntry(
      builder: (context) => Material(
        color: Colors.black54,
        child: Center(
          child: ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, _) {
              return Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Downloading Update',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    LinearProgressIndicator(value: progress),
                    const SizedBox(height: 10),
                    Text('${(progress * 100).toInt()}%'),
                    const SizedBox(height: 10),
                    Text('v${updateStatus!.latestVersion ?? 'latest'}'),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    final dir = Directory('/storage/emulated/0/Download');
    final fileName = 'app_update_${updateStatus?.latestVersion ?? 'latest'}.apk';
    final savePath = '${dir.path}/$fileName';

    try {
      print('Starting download: ${updateStatus?.apkUrl}');

      await _dio.download(
        updateStatus?.apkUrl ?? '',
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            print('Progress: ${(progress * 100).toInt()}%');
            progressNotifier.value = progress;
          }
        },
      );

      print('Download completed: $savePath');

      // Remove overlay
      overlayEntry.remove();
      progressNotifier.dispose();

      // Verify file
      final file = File(savePath);
      if (!await file.exists()) {
        throw Exception('File not found after download');
      }

      print('File size: ${await file.length()} bytes');

      // Install
      if (context.mounted) {
        final result = await OpenFile.open(
            savePath,
            type: 'application/vnd.android.package-archive'
        );
        print('Install result: ${result.message}');
      }

    } catch (e) {
      print('Error: $e');

      // Remove overlay on error
      overlayEntry?.remove();
      progressNotifier.dispose();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Download Failed'),
            content: Text('$e\n\nManual download: ${updateStatus?.apkUrl}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      throw e;
    }
  }

}