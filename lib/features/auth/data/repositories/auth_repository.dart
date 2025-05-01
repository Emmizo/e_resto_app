import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepository {
  final AuthRemoteDatasource remote;
  final SharedPreferences prefs;

  AuthRepository(this.remote, this.prefs);

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<UserModel?> login(String email, String password,
      {String? fcmToken}) async {
    final data = await remote.login(email, password, fcmToken: fcmToken);
    if (data['success'] == true && data['token'] != null) {
      await prefs.setString(_tokenKey, data['token']);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      return UserModel.fromJson(data['user']);
    }
    return null;
  }

  String? getToken() => prefs.getString(_tokenKey);

  UserModel? getUser() {
    final userStr = prefs.getString(_userKey);
    if (userStr == null) return null;
    return UserModel.fromJson(jsonDecode(userStr));
  }

  Future<void> logout() async {
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<UserModel?> signup({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String address,
    String? fcmToken,
  }) async {
    final data = await remote.signup(
      name: name,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      address: address,
      fcmToken: fcmToken,
    );
    if (data['success'] == true && data['token'] != null) {
      await prefs.setString(_tokenKey, data['token']);
      await prefs.setString(_userKey, jsonEncode(data['user']));
      return UserModel.fromJson(data['user']);
    }
    return null;
  }
}
