// lib/core/network/api_client.dart (Modified version)
import 'package:dio/dio.dart';
import '../services/User.dart';
import '../services/version_manager.dart';
import 'api_endpoints.dart';
import '../../main.dart' show NavKey;

class ApiClient {
  late final Dio _dio;
  String? _token;
  bool _isInitialized = false;
  late final ApiEndpoints endpoints;

  final VersionManager _versionManager = VersionManager();

  Future<void> init(String baseUrl) async {
    if (_isInitialized) return;

    endpoints = ApiEndpoints(baseUrl);

    // Initialize version manager
    await _versionManager.initialize();

    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add version control interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to ALL requests
        final tokenManager = User();
        final token = await tokenManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        // Add version headers to all requests
        final versionHeaders = _versionManager.getVersionHeaders();
        options.headers.addAll(versionHeaders);

        // Add user ID if available
        final userId = await tokenManager.getUserId();
        if (userId != null) {
          options.headers['X-User-ID'] = userId;
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        // Process version headers from response (for inform status)
        if (response.headers.map.isNotEmpty) {
          _versionManager.processVersionHeaders(response.headers.map);
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized globally
        if (error.response?.statusCode == 401) {
          print('🔐 401 UNAUTHORIZED detected in interceptor. Logging out...');

          // Clear tokens
          await User().clearTokens();

          // Clear dio auth header
          _dio.options.headers.remove('Authorization');
          _token = null;

          // Navigate to login screen immediately
          try {
            print('🔐 Attempting to navigate to login...');
            final navState = NavKey.currentState;
            if (navState != null) {
              print('🔐 Navigator state found, pushing to login');
              // Use 'login' route (not '/login')
              navState.pushNamedAndRemoveUntil('login', (route) => false);
              print('🔐 Successfully navigated to login');
            } else {
              print('❌ Navigator state is null!');
            }
          } catch (e) {
            print('❌ Error navigating to login: $e');
          }

          // Continue with error so BLoCs can handle it
          handler.next(error);
          return;
        }
        handler.next(error);
      },
    ));

    // Add logging interceptor
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));

    // Load saved token
    // final tokenManager = User();
    // final savedToken = await tokenManager.getToken();
    // if (savedToken != null) {
    //   _token = savedToken;
    //   _dio.options.headers['Authorization'] = 'Bearer $_token';
    //   print("Token loaded from storage: Bearer $_token");
    // }

    _isInitialized = true;
  }

  Future<void> setToken(String token) async {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
    print("Token set: Bearer $_token");
  }

  Future<void> logout() async {
    _token = null;
    _dio.options.headers.remove('Authorization');
    final tokenManager = User();
    await tokenManager.clearTokens();
    _versionManager.clearCachedStatus(notify: true);
  }

  Future<Response> patch(String path, {dynamic data, Options? options}) async {
    return await _dio.patch(path, data: data, options: options);
  }

  Future<Response> get(
      String path, {
        Map<String, dynamic>? queryParameters,
        Options? options,
      }) async {
    try {
      // if (_token != null) {
      //   _dio.options.headers['Authorization'] = 'Bearer $_token';
      // }

      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw SessionExpiredException("Your session has expired. Please login again.");
      }
      rethrow;
    }
  }

  Future<Response> post(String path,
      {dynamic data, Options? options, bool skipAuth = false}) {
    if (skipAuth) {
      final hdrs = Map<String, dynamic>.from(_dio.options.headers);
      hdrs.remove('Authorization');
      options = (options ?? Options()).copyWith(headers: hdrs);
    }
    return _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {dynamic data}) {
    return _dio.put(path, data: data);
  }

  Future<Response> delete(String path) {
    return _dio.delete(path);
  }

  // Getter for version manager
  VersionManager get versionManager => _versionManager;
}

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired']);
}