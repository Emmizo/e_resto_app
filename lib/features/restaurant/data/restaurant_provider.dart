import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/dio_service.dart';
import '../../auth/domain/providers/auth_provider.dart';
import 'models/restaurant_model.dart';
import 'restaurant_remote_datasource.dart';

class RestaurantProvider extends ChangeNotifier {
  List<RestaurantModel> _restaurants = [];
  bool _isLoading = false;
  String? _error;

  List<RestaurantModel> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRestaurants(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final fetched = await RestaurantRemoteDatasource(DioService.getDio())
          .fetchRestaurants(token: token);
      _restaurants = fetched;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
