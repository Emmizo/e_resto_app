import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'models/restaurant_model.dart';

class RestaurantRemoteDatasource {
  final Dio dio;
  RestaurantRemoteDatasource(this.dio);

  Future<List<RestaurantModel>> fetchRestaurants({String? token}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.restaurants,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      final data = response.data['data'] as List;
      final restaurants =
          data.map((json) => RestaurantModel.fromJson(json)).toList();

      return restaurants;
    } catch (e) {
    
      return [];
    }
  }
}
