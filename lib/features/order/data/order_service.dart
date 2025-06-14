import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../core/services/action_queue_helper.dart';
import '../../../core/services/database_helper.dart';
import '../../auth/domain/providers/auth_provider.dart';
import 'models/order_model.dart';

class OrderService {
  static Future<void> placeOrder({
    required BuildContext context,
    required List<Map<String, dynamic>> items,
    required double total,
    required String address,
    required RestaurantModel restaurant,
    required String paymentMethod,
    String? instructions,
    String orderType = 'delivery',
    List<dynamic>? dietaryInfo,
  }) async {
    // debugPrint('OrderService.placeOrder called');
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
      orderType: orderType,
      paymentMethod: paymentMethod,
    );
    // Save locally
    try {
      // debugPrint('Inserting order into local DB...');
      await db.insert('orders', {
        'items': jsonEncode(items),
        'total_amount': total,
        'delivery_address': address,
        'status': order.status,
        'created_at': now.toIso8601String(),
        'restaurant_id': restaurant.id,
        'payment_method': paymentMethod,
      });
      // debugPrint('Order inserted into local DB');
    } catch (e) {
      // debugPrint('Error inserting order into local DB: \\${e.toString()}');
    }
    if (!isOnline) {
      // debugPrint('Offline: queuing order for sync');
      // Queue for sync
      await ActionQueueHelper.queueAction(
        actionType: 'place_order',
        payload: order.toJson(),
      );
      return;
    }
    // Online: send to backend
    try {
      // debugPrint('Sending order to backend...');
      final dio = Dio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      // Build backend payload
      final backendItems = items.map((item) {
        final map = {
          'menu_item_id': item['id'],
          'quantity': item['quantity'],
        };
        if (item['dietaryInfo'] != null &&
            (item['dietaryInfo'] as List).isNotEmpty) {
          map['dietary_info'] = item['dietaryInfo'];
        }
        return map;
      }).toList();
      final payload = {
        'restaurant_id': restaurant.id,
        'delivery_address': address,
        'special_instructions': instructions ?? '',
        'order_type': orderType,
        'items': backendItems,
      };
      // debugPrint('Order payload: $payload');
      final response = await dio.post(
        ApiEndpoints.orders,
        data: payload,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        }),
      );
      // debugPrint('Order sent to backend. Response: \\${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Optionally update local order status to 'placed' if needed
        // debugPrint('Order placed successfully online');
      } else {
        // debugPrint('Order not placed. Status: \\${response.statusCode}');
      }
    } catch (e) {
      // debugPrint('Error sending order to backend: \\${e.toString()}');
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
