import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;
  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;

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
        _error = 'Invalid credentials';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    await repository.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<bool> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    String? fcmToken,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await repository.signup(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        address: address,
        fcmToken: fcmToken,
      );
      if (user != null) {
        _user = user;
        _token = repository.getToken();
        _loading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Signup failed';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
    return false;
  }
}
