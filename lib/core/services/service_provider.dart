import '../network/api_client.dart';
import 'api_service.dart';
import 'mock_api_service.dart';
import 'api_service_interface.dart';
import 'token_manager.dart';

class ServiceProvider {
  // Use mock in debug mode, real API in release mode
  static const bool useMock = false;
  // Base URL for the API
  static const String baseUrl = 'http://192.168.168.152:8000';
  // Get the appropriate API service based on environment
  static Future<ApiServiceInterface> getApiService() async {
    ApiServiceInterface apiService;

    if (useMock) {
      apiService = MockApiService(useMockData: true);
    } else {
      final apiClient = ApiClient();
      await apiClient.init(baseUrl);

      final tokenManager = TokenManager();
      final token = await tokenManager.getToken();
      if (token != null) {
        await apiClient.setToken(token);
      }

      apiService = ApiService(apiClient);
    }

    return apiService;
  }


}