import '../network/api_client.dart';
import 'api_service.dart';
import 'api_service_interface.dart';
import 'User.dart';

class ServiceProvider {
  // Base URL for the API
  // static const String baseUrl = 'http://192.168.171.49:9900';
  static const String baseUrl = 'https://lpg.ops.arungas.com';
  // Get the appropriate API service based on environment
  static Future<ApiServiceInterface> getApiService() async {
    ApiServiceInterface apiService;

      final apiClient = ApiClient();
      await apiClient.init(baseUrl);

      final tokenManager = User();
      final token = await tokenManager.getToken();
      if (token != null) {
        await apiClient.setToken(token);
      }

      apiService = ApiService(apiClient);


    return apiService;
  }

}