class ServerException implements Exception {
  final String message;

  const ServerException([this.message = 'Server error occurred']);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error occurred']);

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'Network error occurred']);

  @override
  String toString() => 'NetworkException: $message';
}

class AuthException implements Exception {
  final String message;

  const AuthException([this.message = 'Authentication error occurred']);

  @override
  String toString() => 'AuthException: $message';
}

class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  const ValidationException([this.message = 'Validation error occurred', this.errors]);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorsString = errors!.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join('; ');
      return 'ValidationException: $message ($errorsString)';
    }
    return 'ValidationException: $message';
  }
}

class BusinessRuleException implements Exception {
  final String message;
  final String? code;

  const BusinessRuleException([this.message = 'Business rule violated', this.code]);

  @override
  String toString() => 'BusinessRuleException: $message${code != null ? ' (Code: $code)' : ''}';
}