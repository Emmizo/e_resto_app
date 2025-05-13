import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;
  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;
  static const String _userKey = 'auth_user';

  AuthProvider(this.repository) {
    _user = repository.getUser();
    _token = repository.getToken();
  }

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<bool> login(String email, String password, {String? fcmToken}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await repository.login(email, password, fcmToken: fcmToken);
      if (user != null) {
        _user = user;
        _token = repository.getToken();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Invalid email or password. Please try again.';
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          _error = 'Invalid email or password. Please try again.';
        } else {
          _error =
              'An error occurred: \\${e.response?.statusMessage ?? e.message}';
        }
      } else {
        _error = 'An unexpected error occurred. Please try again.';
      }
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await repository.logout();
    _user = null;
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_user');
    await prefs.remove('auth_token');
    notifyListeners();
  }

  Future<bool> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    String? fcmToken,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await repository.signup(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
        fcmToken: fcmToken,
      );
      if (user != null) {
        _user = user;
        _token = repository.getToken();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign up failed';
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 422) {
          final data = e.response?.data;
          if (data is Map && data['errors'] != null) {
            final errors = data['errors'] as Map;
            _error = errors.values.expand((v) => v).join('\n');
          } else if (data is Map && data['message'] != null) {
            _error = data['message'];
          } else {
            _error = 'Invalid input. Please check your details and try again.';
          }
        } else {
          _error =
              'An error occurred: \\${e.response?.statusMessage ?? e.message}';
        }
      } else {
        _error = 'An unexpected error occurred. Please try again.';
      }
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  void updateProfilePicture(String url) {
    if (_user != null) {
      _user = UserModel(
        id: _user!.id,
        firstName: _user!.firstName,
        lastName: _user!.lastName,
        profilePicture: url,
        email: _user!.email,
        phoneNumber: _user!.phoneNumber,
        has2faEnabled: _user!.has2faEnabled,
        status: _user!.status,
        fcmToken: _user!.fcmToken,
        google2faSecret: _user!.google2faSecret,
      );
      repository.prefs.setString(
        _userKey,
        jsonEncode(_user!.toJson()),
      );
      notifyListeners();
    }
  }

  void setUser(UserModel user) {
    _user = user;
    repository.prefs.setString(_userKey, jsonEncode(user.toJson()));
    notifyListeners();
  }
}
