import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'session_interceptor.dart';

class DioService {
  static Dio? _dio;

  static Dio getDio(BuildContext context) {
    _dio ??= Dio();
    // Remove any previous SessionInterceptor to avoid duplicates
    _dio!.interceptors.removeWhere((i) => i is SessionInterceptor);
    _dio!.interceptors.add(SessionInterceptor(context));
    return _dio!;
  }
}
