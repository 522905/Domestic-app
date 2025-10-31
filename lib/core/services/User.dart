import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

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

class Novu {
  final String applicationIdentifier;
  final String subscriberId;
  final String? subscriberHash;

  Novu({
    required this.applicationIdentifier,
    required this.subscriberId,
    this.subscriberHash,
  });

  factory Novu.fromJson(Map<String, dynamic> json) {
    return Novu(
      applicationIdentifier: json['applicationIdentifier'] ?? '',
      subscriberId: json['subscriberId'] ?? '',
      subscriberHash: json['subscriberHash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'applicationIdentifier': applicationIdentifier,
      'subscriberId': subscriberId,
      'subscriberHash': subscriberHash,
    };
  }
}

class UserCompany {
  final int id;
  final String name;
  final String shortCode;
  final String? sdmsUserCode; // Add this field

  UserCompany({
    required this.id,
    required this.name,
    required this.shortCode,
    this.sdmsUserCode, // Add this parameter
  });

  factory UserCompany.fromJson(Map<String, dynamic> json) {
    return UserCompany(
      id: json['id'],
      name: json['name'] ?? '',
      shortCode: json['short_code'] ?? '',
      sdmsUserCode: json['sdms_user_code'], // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_code': shortCode,
      'sdms_user_code': sdmsUserCode, // Add this line
    };
  }
}

class User {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryKey = 'token_expiry';

  // Company storage keys+
  static const String _companyIdKey = 'company_id';
  static const String _companyNameKey = 'company_name';
  static const String _companyShortCodeKey = 'company_short_code';
  static const String _companySdmsUserCodeKey = 'company_sdms_user_code';

  // Novu storage keys
  static const String _novuAppIdKey = 'novu_app_id';
  static const String _novuSubscriberIdKey = 'novu_subscriber_id';
  static const String _novuSubscriberHashKey = 'novu_subscriber_hash';

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

  // In User class - make sure it handles null:
  Future<void> saveCompany({
    required int companyId,
    required String companyName,
    required String companyShortCode,
    String? sdmsUserCode,
  }) async {
    // Use FlutterSecureStorage, not SharedPreferences!
    await _storage.write(key: _companyIdKey, value: companyId.toString());
    await _storage.write(key: _companyNameKey, value: companyName);
    await _storage.write(key: _companyShortCodeKey, value: companyShortCode);

    if (sdmsUserCode != null) {
      await _storage.write(key: _companySdmsUserCodeKey, value: sdmsUserCode);
    } else {
      await _storage.delete(key: _companySdmsUserCodeKey);
    }
  }

  Future<void> saveNovu({
    required String applicationIdentifier,
    required String subscriberId,
    String? subscriberHash,
  }) async {
    await _storage.write(key: _novuAppIdKey, value: applicationIdentifier);
    await _storage.write(key: _novuSubscriberIdKey, value: subscriberId);

    if (subscriberHash != null) {
      await _storage.write(key: _novuSubscriberHashKey, value: subscriberHash);
    } else {
      await _storage.delete(key: _novuSubscriberHashKey);
    }
  }

  Future<Novu?> getNovu() async {
    final appId = await _storage.read(key: _novuAppIdKey);
    final subscriberId = await _storage.read(key: _novuSubscriberIdKey);
    final subscriberHash = await _storage.read(key: _novuSubscriberHashKey);

    if (appId != null && subscriberId != null) {
      return Novu(
        applicationIdentifier: appId,
        subscriberId: subscriberId,
        subscriberHash: subscriberHash,
      );
    }
    return null;
  }

  Future<String?> getNovuApplicationIdentifier() async {
    return _storage.read(key: _novuAppIdKey);
  }

  Future<String?> getNovuSubscriberId() async {
    return _storage.read(key: _novuSubscriberIdKey);
  }

  Future<String?> getNovuSubscriberHash() async {
    return _storage.read(key: _novuSubscriberHashKey);
  }

  Future<void> saveSession({
    required String access,
    required String refresh,
    int expiresIn = 300,
    required Map<String, dynamic> user,
    Map<String, dynamic>? company,
    Map<String, dynamic>? novu, // Add this parameter
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
        final roles = user["roles"].values.toList();
        await _storage.write(
            key: 'user_roles',
            value: jsonEncode(roles)
        );
      }

      // Save company information if provided
      if (company != null) {
        await saveCompany(
          companyId: company['id'],
          companyName: company['name'] ?? '',
          companyShortCode: company['short_code'] ?? '',
          sdmsUserCode: company['sdms_user_code'],
        );
      }

      // Save novu information if provided
      if (novu != null) {
        await saveNovu(
          applicationIdentifier: novu['applicationIdentifier'] ?? '',
          subscriberId: novu['subscriberId'] ?? '',
          subscriberHash: novu['subscriberHash'],
        );
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

  // Company related methods
  Future<UserCompany?> getActiveCompany() async {
    final companyIdStr = await _storage.read(key: _companyIdKey);
    final companyName = await _storage.read(key: _companyNameKey);
    final companyShortCode = await _storage.read(key: _companyShortCodeKey);
    final sdmsUserCode = await _storage.read(key: _companySdmsUserCodeKey);

    if (companyIdStr != null && companyName != null && companyShortCode != null) {
      final companyId = int.tryParse(companyIdStr);
      if (companyId != null) {
        return UserCompany(
          id: companyId,
          name: companyName,
          shortCode: companyShortCode,
          sdmsUserCode: sdmsUserCode,
        );
      }
    }
    return null;
  }

  Future<int?> getActiveCompanyId() async {
    final companyIdStr = await _storage.read(key: _companyIdKey);
    return companyIdStr != null ? int.tryParse(companyIdStr) : null;
  }

  Future<String?> getActiveCompanyName() async {
    return _storage.read(key: _companyNameKey);
  }

  Future<String?> getActiveCompanyShortCode() async {
    return _storage.read(key: _companyShortCodeKey);
  }

  Future<String?> getActiveCompanySdmsUserCode() async {
    return _storage.read(key: _companySdmsUserCodeKey);
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