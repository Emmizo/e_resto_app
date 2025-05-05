import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'models/restaurant_model.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint('Raw restaurant API response: \\${response.data}');
      final data = response.data['data'] as List;
      return data.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (e, stack) {
      debugPrint('Error in fetchRestaurants: \\${e.toString()}');
      debugPrint('Stack trace: \\${stack.toString()}');
      return [];
    }
  }
}
