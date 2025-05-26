import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    print('[DEBUG] FCM token used for login: $fcmToken');
    final data = {'email': email, 'password': password};
    if (fcmToken != null) {
      data['fcm_token'] = fcmToken;
    }
    print('[DEBUG] Login data sent to server: $data');
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
    print('[DEBUG] FCM token used for signup: $fcmToken');
    try {
      final signupData = {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone_number': phoneNumber,
        if (fcmToken != null) 'fcm_token': fcmToken,
      };
      print('[DEBUG] Signup data sent to server: $signupData');
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
