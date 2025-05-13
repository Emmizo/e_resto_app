import 'dart:convert';
import 'package:e_resta_app/core/services/database_helper.dart';
import 'package:e_resta_app/core/services/action_queue_helper.dart';
import 'package:e_resta_app/features/order/data/models/order_model.dart';
import 'package:e_resta_app/features/order/data/models/order_model.dart'
    show RestaurantModel;
import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';

class OrderService {
  static Future<void> placeOrder({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required double total,
    required String address,
    required RestaurantModel restaurant,
  }) async {
    final isOnline =
        Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    final db = await DatabaseHelper().db;
    final now = DateTime.now();
    final order = OrderModel(
      items: items,
      total: total,
      address: address,
      status: isOnline ? 'placed' : 'pending',
      createdAt: now,
      restaurant: restaurant,
      orderType: 'delivery',
    );
    // Save locally
    await db.insert('orders', {
      'items': jsonEncode(items),
      'total': total,
      'address': address,
      'status': order.status,
      'createdAt': now.toIso8601String(),
      'restaurant': jsonEncode(restaurant.toJson()),
    });
    if (!isOnline) {
      // Queue for sync
      await ActionQueueHelper.queueAction(
        actionType: 'place_order',
        payload: order.toJson(),
      );
      return;
    }
    // Online: send to backend
    try {
      final dio = Dio();
      final response = await dio.post(
        ApiEndpoints.orders,
        data: order.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Optionally update local order status to 'placed' if needed
      }
    } catch (e) {
      // If failed, mark as failed in local DB
      await db.update(
        'orders',
        {'status': 'failed'},
        where: 'createdAt = ?',
        whereArgs: [now.toIso8601String()],
      );
      // Optionally queue for retry
      await ActionQueueHelper.queueAction(
        actionType: 'place_order',
        payload: order.toJson(),
      );
    }
  }
}
