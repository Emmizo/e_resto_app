import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'models/restaurant_model.dart';

class RestaurantRemoteDatasource {
  final Dio dio;
  RestaurantRemoteDatasource(this.dio);

  Future<List<RestaurantModel>> fetchRestaurants() async {
    final response = await dio.get(ApiEndpoints.restaurants);
    final data = response.data['data'] as List;
    return data.map((json) => RestaurantModel.fromJson(json)).toList();
  }
}
