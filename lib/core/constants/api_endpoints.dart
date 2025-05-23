import 'dart:io';

class ApiConfig {
  static String baseUrl = Platform.isIOS
      ? 'http://localhost:8000/api/v1'
      : 'http://10.0.2.2:8000/api/v1';
  static String imageBaseUrl = Platform.isIOS
      ? 'http://localhost:8000/storage/'
      : 'http://10.0.2.2:8000/storage/';
}

class ApiEndpoints {
  static String login = '${ApiConfig.baseUrl}/login';
  static String signup = '${ApiConfig.baseUrl}/signup';
  static String uploadProfilePicture =
      '${ApiConfig.baseUrl}/user/profile-picture';
  static String restaurants = '${ApiConfig.baseUrl}/restaurants';
  static String cuisines = '${ApiConfig.baseUrl}/cuisines';
  static String orders = '${ApiConfig.baseUrl}/orders';
  static String menuFavorite = '${ApiConfig.baseUrl}/menu-items/favorite';
  static String menuUnfavorite = '${ApiConfig.baseUrl}/menu-items/unfavorite';
  static String menuFavorites = '${ApiConfig.baseUrl}/menu-items/favorites';
  static String restaurantFavorite =
      '${ApiConfig.baseUrl}/restaurants/favorite';
  static String restaurantUnfavorite =
      '${ApiConfig.baseUrl}/restaurants/unfavorite';
  static String restaurantFavorites =
      '${ApiConfig.baseUrl}/restaurants/favorites';
  static String reservations = '${ApiConfig.baseUrl}/reservations';
  static String finalStats = '${ApiConfig.baseUrl}/final-stats';
  static String promoBanners =
      '${ApiConfig.baseUrl}/promo-banners-with-restaurant';
  static String changePassword = '${ApiConfig.baseUrl}/user/change-password';
  static String addresses = '${ApiConfig.baseUrl}/addresses';
  static String addressById(int id) => '${ApiConfig.baseUrl}/addresses/$id';
  // Add more endpoints as needed
}
