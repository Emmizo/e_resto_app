import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/constants/api_endpoints.dart';

class AuthRemoteDatasource {
  final Dio dio;
  AuthRemoteDatasource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password,
      {String? fcmToken}) async {
    if (fcmToken == null) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        fcmToken = null;
      }
    }
    final data = {'email': email, 'password': password};
    if (fcmToken != null) {
      data['fcm_token'] = fcmToken;
    }
    final response = await dio.post(
      ApiEndpoints.login,
      data: data,
      options: Options(headers: {'accept': 'application/json'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    String? fcmToken,
  }) async {
    try {
      final signupData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
      final response = await dio.post(
        ApiEndpoints.signup,
        data: signupData,
        options: Options(headers: {'accept': 'application/json'}),
      );

      return response.data;
    } on DioException {
      rethrow;
    }
  }
}
