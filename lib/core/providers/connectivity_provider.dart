import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  void _init() async {
    final result = await _connectivity.checkConnectivity();
    await _updateStatus(result);
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  Future<void> _updateStatus(ConnectivityResult result) async {
    bool online = result != ConnectivityResult.none;
    if (online) {
      // Try to ping a reliable server using Dio
      try {
        final dio = Dio();
        final response = await dio.get(
          ApiConfig.baseUrl, // Use your API health endpoint if possible
          options: Options(receiveTimeout: const Duration(seconds: 5)),
        );
        online = response.statusCode == 200;
      } catch (e) {
        print('Connectivity check failed: $e');
        online = false;
      }
    }
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  Future<void> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    await _updateStatus(result);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
