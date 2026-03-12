import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ujjwala/ujjwala_photo_upload.dart';

class CachedPhotoEntry {
  final String tusUrl;
  final String localFilePath;

  CachedPhotoEntry({required this.tusUrl, required this.localFilePath});

  Map<String, String> toJson() => {
        'tusUrl': tusUrl,
        'localFilePath': localFilePath,
      };

  factory CachedPhotoEntry.fromJson(Map<String, dynamic> json) =>
      CachedPhotoEntry(
        tusUrl: json['tusUrl'] as String,
        localFilePath: json['localFilePath'] as String,
      );
}

class UjjwalaPhotoCacheService {
  static const String _prefix = 'ujjwala_photo_';

  String _key(int installationId, PhotoType type) =>
      '${_prefix}${installationId}_${type.name}';

  Future<void> savePhoto(
    int installationId,
    PhotoType type,
    String tusUrl,
    String localFilePath,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final entry = CachedPhotoEntry(tusUrl: tusUrl, localFilePath: localFilePath);
    await prefs.setString(_key(installationId, type), jsonEncode(entry.toJson()));
  }

  /// Returns null if no cache entry exists or the entry is corrupt.
  Future<CachedPhotoEntry?> getPhoto(int installationId, PhotoType type) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(installationId, type));
    if (raw == null) return null;
    try {
      return CachedPhotoEntry.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearPhoto(int installationId, PhotoType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(installationId, type));
  }

  Future<void> clearAllPhotos(int installationId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final type in PhotoType.values) {
      await prefs.remove(_key(installationId, type));
    }
  }
}
