import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class UserRole {
  final String role;
  final String? details;

  UserRole({required this.role, this.details});

  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      role: json['role'] ?? '',
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'details': details,
    };
  }
}

class User {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryKey = 'token_expiry';

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
    int? expiresIn,
  }) async {
    await _storage.write(key: _accessTokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);

    if (expiresIn != null) {
      final expiry = DateTime.now()
          .add(Duration(seconds: expiresIn))
          .millisecondsSinceEpoch
          .toString();
      await _storage.write(key: _expiryKey, value: expiry);
    }
  }

  Future<void> saveSession({
    required String access,
    required String refresh,
    int expiresIn = 300,
    required Map<String, dynamic> user,
  }) async {
    try {
      // Save tokens
      await saveTokens(
        token: access,
        refreshToken: refresh,
        expiresIn: expiresIn,
      );

      // Save user details
      await _storage.write(key: 'user_id', value: user['id']?.toString() ?? '');
      await _storage.write(key: 'user_name', value: user['username'] ?? '');
      await _storage.write(key: 'phone_number', value: user['phone_number'] ?? '');
      await _storage.write(key: 'email', value: user['email'] ?? '');

      // Handle roles properly - convert array of objects to JSON string
      if (user['roles'] != null) {
        final roles = List<Map<String, dynamic>>.from(user['roles']);
        await _storage.write(key: 'user_roles', value: jsonEncode(roles));
      }
    } catch (e) {
      print('Error saving session: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<bool> isTokenExpired() async {
    final expiryString = await _storage.read(key: _expiryKey);
    if (expiryString == null) return true;
    final expiry = int.tryParse(expiryString);
    if (expiry == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiry;
  }

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<String?> getUserId() async {
    return _storage.read(key: 'user_id');
  }

  Future<String?> getUserName() async {
    return _storage.read(key: 'user_name');
  }

  Future<String?> getUserPhoneNumber() async {
    return _storage.read(key: 'phone_number');
  }

  Future<String?> getUserEmail() async {
    return _storage.read(key: 'email');
  }

  Future<List<UserRole>> getUserRoles() async {
    final rolesString = await _storage.read(key: 'user_roles');
    if (rolesString != null && rolesString.isNotEmpty) {
      try {
        final List<dynamic> rolesList = jsonDecode(rolesString);
        return rolesList.map((role) => UserRole.fromJson(role)).toList();
      } catch (e) {
        print('Error parsing user roles: $e');
        return [];
      }
    }
    return [];
  }

  // Helper method to check if user has a specific role
  Future<bool> hasRole(String roleName) async {
    final roles = await getUserRoles();
    return roles.any((role) => role.role.toLowerCase() == roleName.toLowerCase());
  }

  // Helper method to get role names only (for backward compatibility)
  Future<List<String>> getRoleNames() async {
    final roles = await getUserRoles();
    return roles.map((role) => role.role).toList();
  }
}