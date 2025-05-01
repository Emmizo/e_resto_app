class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api/v1';
}

class ApiEndpoints {
  static const String login = '${ApiConfig.baseUrl}/login';
  static const String signup = '${ApiConfig.baseUrl}/signup';
  // Add more endpoints as needed
}
