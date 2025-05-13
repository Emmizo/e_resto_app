import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:e_resta_app/core/services/database_helper.dart';

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
          'https://www.google.com/generate_204',
          options: Options(receiveTimeout: const Duration(seconds: 5)),
        );
        online = response.statusCode == 204;
      } catch (e) {
        print('Connectivity check failed: $e');
        online = false;
      }
    }
    final wasOffline = !_isOnline;
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
      if (online && wasOffline) {
        // Just came back online, process action queue
        await _processActionQueue();
      }
    }
  }

  Future<void> _processActionQueue() async {
    final db = await DatabaseHelper().db;
    final List<Map<String, dynamic>> actions =
        await db.query('action_queue', orderBy: 'createdAt ASC');
    final dio = Dio();
    const maxRetries = 3;
    for (final action in actions) {
      final String type = action['actionType'];
      final Map<String, dynamic> payload = jsonDecode(action['payload']);
      final int retryCount = action['retryCount'] ?? 0;
      try {
        if (type == 'favorite') {
          await dio.post(
            ApiEndpoints.restaurantFavorite,
            data: payload,
          );
        } else if (type == 'unfavorite') {
          await dio.post(
            ApiEndpoints.restaurantUnfavorite,
            data: payload,
          );
        } else if (type == 'add_to_cart') {
          await Future.delayed(Duration(milliseconds: 300));
        } else if (type == 'remove_from_cart') {
          await Future.delayed(Duration(milliseconds: 300));
        } else if (type == 'update_cart_quantity') {
          await Future.delayed(Duration(milliseconds: 300));
        } else if (type == 'make_reservation') {
          await Future.delayed(Duration(milliseconds: 300));
        } else if (type == 'cancel_reservation') {
          await Future.delayed(Duration(milliseconds: 300));
        }
        // If successful, remove from queue
        await db
            .delete('action_queue', where: 'id = ?', whereArgs: [action['id']]);
        // Refresh badge/provider if needed
        // (Assume you have access to context or use a callback)
      } catch (e) {
        if (retryCount + 1 >= maxRetries) {
          // Remove permanently failed action
          await db.delete('action_queue',
              where: 'id = ?', whereArgs: [action['id']]);
          // Optionally, log or notify user of permanent failure
        } else {
          await db.update(
            'action_queue',
            {
              'retryCount': retryCount + 1,
              'lastError': e.toString(),
            },
            where: 'id = ?',
            whereArgs: [action['id']],
          );
        }
        // Stop processing further actions for now
        break;
      }
    }
    // Optionally, refresh ActionQueueProvider badge here if you have access
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
