import 'package:dio/dio.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart';

class DioService {
  static Dio? _dio;

  static Dio getDio() {
    _dio ??= Dio(
      BaseOptions(
        headers: {
          'Accept': 'application/json',
        },
      ),
    );
    // Remove any previous SessionInterceptor to avoid duplicates
    _dio!.interceptors.removeWhere((i) => i is SessionInterceptor);
    _dio!.interceptors.add(SessionInterceptor());
    return _dio!;
  }
}

class SessionInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        Provider.of<AuthProvider>(context, listen: false).logout();
        showDialog(
          context: context,
          barrierDismissible: false, // User must tap OK
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Session expired',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please log in again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
    super.onError(err, handler);
  }
}
