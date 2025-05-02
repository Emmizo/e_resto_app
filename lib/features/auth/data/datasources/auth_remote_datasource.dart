import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';

class AuthRemoteDatasource {
  final Dio dio;
  AuthRemoteDatasource(this.dio);

  Future<Map<String, dynamic>> login(String email, String password,
      {String? fcmToken}) async {
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
    required String password,
    required String passwordConfirmation,
    required String phoneNumber,
    required String address,
    String? fcmToken,
  }) async {
    try {
      final response = await dio.post(
        ApiEndpoints.signup,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone_number': phoneNumber,
          'address': address,
          'fcm_token': fcmToken,
        },
        options: Options(headers: {'accept': 'application/json'}),
      );
      print('Signup response: \\${response.data}');
      return response.data;
    } on DioException catch (e) {
      print('Signup error: \\${e.response?.data}');
      rethrow;
    }
  }
}
