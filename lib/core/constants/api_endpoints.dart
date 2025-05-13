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
  static const String cuisines = '${ApiConfig.baseUrl}/cuisines';
  static const String orders = '${ApiConfig.baseUrl}/orders';
  static const String menuFavorite = '${ApiConfig.baseUrl}/menu-items/favorite';
  static const String menuUnfavorite =
      '${ApiConfig.baseUrl}/menu-items/unfavorite';
  static const String menuFavorites =
      '${ApiConfig.baseUrl}/menu-items/favorites';
  static const String restaurantFavorite =
      '${ApiConfig.baseUrl}/restaurants/favorite';
  static const String restaurantUnfavorite =
      '${ApiConfig.baseUrl}/restaurants/unfavorite';
  static const String restaurantFavorites =
      '${ApiConfig.baseUrl}/restaurants/favorites';
  static const String reservations = '${ApiConfig.baseUrl}/reservations';
  static const String finalStats = '${ApiConfig.baseUrl}/final-stats';
  static const String promoBanners =
      '${ApiConfig.baseUrl}/promo-banners-with-restaurant';
  static const String changePassword =
      '${ApiConfig.baseUrl}/user/change-password';
  static const String addresses = '${ApiConfig.baseUrl}/addresses';
  static String addressById(int id) => '${ApiConfig.baseUrl}/addresses/$id';
  // Add more endpoints as needed
}
