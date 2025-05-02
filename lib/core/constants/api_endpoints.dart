class ApiConfig {
  static const String baseUrl = 'http://localhost:8000/api/v1';
  static const String imageBaseUrl = 'http://localhost:8000/storage/';
}

class ApiEndpoints {
  static const String login = '${ApiConfig.baseUrl}/login';
  static const String signup = '${ApiConfig.baseUrl}/signup';
  static const String uploadProfilePicture =
      '${ApiConfig.baseUrl}/user/profile-picture';
  static const String restaurants = '${ApiConfig.baseUrl}/restaurants';
  // Add more endpoints as needed
}
