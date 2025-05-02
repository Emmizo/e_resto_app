import 'dart:io';
import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';

class ProfileRemoteDatasource {
  final Dio dio;

  ProfileRemoteDatasource(this.dio);

  /// Uploads the profile picture to the backend.
  /// [imageFile] is the image to upload.
  /// Returns the response from the backend.
  Future<Response> uploadProfilePicture(File imageFile, {String? token}) async {
    final formData = FormData.fromMap({
      'profile_picture': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await dio.post(
      ApiEndpoints.uploadProfilePicture,
      data: formData,
      options: Options(
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ),
    );
    return response;
  }
}
