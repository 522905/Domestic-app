import 'package:dio/dio.dart';
import 'api_endpoints.dart';
import 'package:lpg_distribution_app/core/services/token_manager.dart';

class ApiClient {
  late final Dio _dio;
  String? _token;
  bool _isInitialized = false;

  late final ApiEndpoints endpoints;

    Future<void> init(String baseUrl) async {
      if (_isInitialized) return;

      endpoints = ApiEndpoints(baseUrl);

      _dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ));

      // Add logging
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));

      final tokenManager = TokenManager();
      final savedToken = await tokenManager.getToken();
      if (savedToken != null) {
        _token = savedToken;
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        print("Token loaded from storage: Bearer $_token");
      }

      _isInitialized = true;
    }

  Future<void> setToken(String token) async {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
    print("Token set: Bearer $_token"); // Debug print
  }

  Future<void> logout() async {
    _token = null;
    _dio.options.headers.remove('Authorization');

    final tokenManager = TokenManager();
    await tokenManager.clearTokens();
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
      if (_token != null) {
        _dio.options.headers['Authorization'] = 'Bearer $_token';
      }

      return await _dio.get(
          path,
          queryParameters: queryParameters,
          options: options
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

}

class SessionExpiredException implements Exception {
  final String message;
  SessionExpiredException([this.message = 'Session expired']);
}

