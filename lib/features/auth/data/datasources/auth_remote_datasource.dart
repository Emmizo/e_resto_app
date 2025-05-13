import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRemoteDatasource {
  final Dio dio;
  AuthRemoteDatasource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password,
      {String? fcmToken}) async {
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM Token (login): $fcmToken');
    } catch (e) {
      print('Error fetching FCM token: $e');
      fcmToken = null;
    }
    final data = {'email': email, 'password': password};
    if (fcmToken != null) {
      data['fcm_token'] = fcmToken;
    }
    print('Login data being sent: ' + data.toString());
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
      final response = await dio.post(
        ApiEndpoints.signup,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phoneNumber,
          if (fcmToken != null) 'fcm_token': fcmToken,
        },
        options: Options(headers: {'accept': 'application/json'}),
      );

      return response.data;
    } on DioException {
      rethrow;
    }
  }
}
