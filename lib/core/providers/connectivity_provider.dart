import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../constants/api_endpoints.dart';
import '../services/database_helper.dart';
import 'action_queue_provider.dart';

class ConnectivityProvider extends ChangeNotifier {
  final Connectivity _connectivity;
  final Dio dio;
  final DatabaseHelper dbHelper;

  late StreamSubscription<dynamic> _subscription;
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  ConnectivityProvider({
    Connectivity? connectivity,
    Dio? dio,
    DatabaseHelper? dbHelper,
  })  : _connectivity = connectivity ?? Connectivity(),
        dio = dio ?? Dio(),
        dbHelper = dbHelper ?? DatabaseHelper() {
    _init();
  }

  void _init() async {
    final dynamic resultDynamic = await _connectivity.checkConnectivity();
    ConnectivityResult status;
    if (resultDynamic is ConnectivityResult) {
      status = resultDynamic;
    } else if (resultDynamic is List &&
        resultDynamic.isNotEmpty &&
        resultDynamic.first is ConnectivityResult) {
      status = resultDynamic.first as ConnectivityResult;
    } else {
      status = ConnectivityResult.none;
    }
    await _updateStatus(status);
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      final dynamic resultsDynamic = results;
      ConnectivityResult streamStatus;
      if (resultsDynamic is ConnectivityResult) {
        streamStatus = resultsDynamic;
      } else if (resultsDynamic is List &&
          resultsDynamic.isNotEmpty &&
          resultsDynamic.first is ConnectivityResult) {
        streamStatus = resultsDynamic.first as ConnectivityResult;
      } else {
        streamStatus = ConnectivityResult.none;
      }
      await _updateStatus(streamStatus);
    });
  }

  Future<void> _updateStatus(ConnectivityResult result) async {
    bool online = result != ConnectivityResult.none;
    if (online) {
      try {
        final response = await dio.get(
          'https://www.google.com/generate_204',
          options: Options(receiveTimeout: const Duration(seconds: 5)),
        );
        online = response.statusCode == 204;
      } catch (e) {
        // print('Connectivity check failed: $e');
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
        // Refresh ActionQueueProvider badge globally
        await ActionQueueProvider.refreshAll();
      }
    }
  }

  Future<void> _processActionQueue() async {
    final db = await dbHelper.db;
    final List<Map<String, dynamic>> actions =
        await db.query('action_queue', orderBy: 'createdAt ASC');
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
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (type == 'remove_from_cart') {
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (type == 'update_cart_quantity') {
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (type == 'make_reservation') {
          await Future.delayed(const Duration(milliseconds: 300));
        } else if (type == 'cancel_reservation') {
          await Future.delayed(const Duration(milliseconds: 300));
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
    final dynamic resultDynamic2 = await _connectivity.checkConnectivity();
    ConnectivityResult status;
    if (resultDynamic2 is ConnectivityResult) {
      status = resultDynamic2;
    } else if (resultDynamic2 is List &&
        resultDynamic2.isNotEmpty &&
        resultDynamic2.first is ConnectivityResult) {
      status = resultDynamic2.first as ConnectivityResult;
    } else {
      status = ConnectivityResult.none;
    }
    await _updateStatus(status);
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
