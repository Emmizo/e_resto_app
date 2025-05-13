import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:e_resta_app/features/auth/presentation/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';

class SessionInterceptor extends Interceptor {
  final BuildContext context;

  SessionInterceptor(this.context);

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      // Log out user
      Provider.of<AuthProvider>(context, listen: false).logout();
      // Show snackbar with OK action to navigate to login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Session expired. Please log in again.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ),
      );
    }
    super.onError(err, handler);
  }
}
