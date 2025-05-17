import 'package:dio/dio.dart';

class ParsedError {
  final String message;
  final int? code;
  ParsedError(this.message, [this.code]);
}

ParsedError parseDioError(dynamic error) {
  if (error is DioException) {
    final response = error.response;
    final code = response?.statusCode;
    String message = 'An unexpected error occurred';
    if (response?.data is Map && response?.data['message'] != null) {
      message = response?.data['message'];
    } else if (response?.statusMessage != null) {
      message = response!.statusMessage!;
    } else if (error.message != null) {
      message = error.message!;
    }
    return ParsedError(message, code);
  }
  return ParsedError(error.toString());
}
