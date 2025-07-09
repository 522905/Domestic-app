import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _accessTokenKey  = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryKey       = 'token_expiry';

  Future<void> saveTokens({
    required String token,
    required String refreshToken,
    int? expiresIn,
    List<String>? roles,
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

  Future<String?> getUserName() async {
    return _storage.read(key: 'user_name');
  }

      Future<void> saveSession({
      required String access,
      required String refresh,
      int expiresIn = 300,
      Map<String, dynamic>? user,
      List<String>? roles,
    }) async {
      try {
        // Save tokens
        await saveTokens(
          token: access,
          refreshToken: refresh,
          expiresIn: expiresIn,
          roles: roles,
        );

        // Save user details if provided
        if (user != null) {
          if (user.containsKey('id')) {
            await _storage.write(key: 'user_id', value: user['id']?.toString());
          }
          if (user.containsKey('username')) {
            await _storage.write(key: 'user_name', value: user['username'] ?? '');
          }
        }

        // Save roles as a JSON string
        if (roles != null) {
          await _storage.write(key: 'user_roles', value: roles.join(','));
        }
      } catch (e) {
        print('Error saving session: $e');
        rethrow;
      }
    }

    Future<List<String>> getUserRole() async {
      final rolesString = await _storage.read(key: 'user_roles');
      if (rolesString != null) {
        return rolesString.split(',');
      }
      return [];
    }

}
