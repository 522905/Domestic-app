class ApiConstants {
  static const String baseUrl = 'https://api.lpgdistribution.com/api/v1';

  // Endpoints
  // static const String login = '/auth/login';
  static const String refreshToken = '/auth/refresh';
  static const String orders = '/orders';
  static const String inventory = '/inventory';
  static const String cash = '/cash';
  static const String users = '/users';

  // Cache duration
  static const int cacheDurationInMinutes = 15;
}