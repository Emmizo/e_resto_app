import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/restaurant/data/models/restaurant_model.dart';
import '../constants/api_endpoints.dart';
import '../constants/pusher_config.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  PusherChannelsFlutter? _pusher;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    await _requestPermission();
    await _initLocalNotifications();
    await _setupPusher(context);
  }

  Future<void> _setupPusher(BuildContext context) async {
    _pusher = PusherChannelsFlutter.getInstance();
    await _pusher?.init(
      apiKey: 'YOUR_PUSHER_KEY',
      cluster: 'YOUR_PUSHER_CLUSTER',
      onEvent: (event) => _onPusherEvent(context, event),
      onSubscriptionSucceeded: (String channelName, dynamic data) {},
      onConnectionStateChange: (String currentState, String previousState) {},
      onError: (String message, int? code, dynamic e) {},
    );
    await _pusher?.subscribe(channelName: 'your-channel');
    await _pusher?.connect();
  }

  void _onPusherEvent(BuildContext context, PusherEvent event) {
    // You can parse event.data and show a dialog/snackbar
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Notification'),
        content: Text(event.data ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission() async {
    // No-op for in-app notifications
  }

  Future<void> _initLocalNotifications() async {
    // No-op for in-app notifications
  }

  static bool _nearbyRestaurantAlerts = true;
  static bool _nearbyLikedMenuAlerts = true;
  static List<int> _likedMenuItemIds = [];
  static List<RestaurantModel> _restaurants = [];

  static Future<void> updatePreferences({
    required bool nearbyRestaurantAlerts,
    required bool nearbyLikedMenuAlerts,
  }) async {
    _nearbyRestaurantAlerts = nearbyRestaurantAlerts;
    _nearbyLikedMenuAlerts = nearbyLikedMenuAlerts;
  }

  static Future<void> updateLikedMenuItems(List<int> likedMenuItemIds) async {
    _likedMenuItemIds = likedMenuItemIds;
  }

  static Future<void> updateRestaurants(
      List<RestaurantModel> restaurants) async {
    _restaurants = restaurants;
  }

  static Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _instance._showLocalNotification(title, body);
  }

  static Future<void> startProximityMonitoring() async {
    await _fetchAllRestaurants();
    await _fetchLikedMenuItems();
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50,
      ),
    ).listen((Position position) {
      _checkNearbyRestaurants(position);
    });
  }

  static Future<void> _fetchAllRestaurants() async {
    try {
      final response = await http.get(Uri.parse(ApiEndpoints.restaurants));
      final data = jsonDecode(response.body)['data'] as List;
      _restaurants =
          data.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (_) {}
  }

  static Future<void> _fetchLikedMenuItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await http.get(
        Uri.parse(ApiEndpoints.menuFavorites),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body)['data'] as List;
      _likedMenuItemIds =
          data.map((item) => item['menu_item']['id'] as int).toList();
    } catch (_) {}
  }

  static void _checkNearbyRestaurants(Position userPosition) {
    for (final restaurant in _restaurants) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        double.tryParse(restaurant.latitude) ?? 0.0,
        double.tryParse(restaurant.longitude) ?? 0.0,
      );
      if (distance < 200) {
        if (_nearbyRestaurantAlerts) {
          showLocalNotification(
            title: 'You\'re near ${restaurant.name}!',
            body: 'Check out their menu or reserve a table.',
          );
        }
        if (_nearbyLikedMenuAlerts) {
          final liked = restaurant.menus.any((menu) => menu.menuItems
              .any((item) => _likedMenuItemIds.contains(item.id)));
          if (liked) {
            showLocalNotification(
              title: 'A favorite dish is nearby!',
              body: '${restaurant.name} has a menu item you love.',
            );
          }
        }
      }
    }
  }

  Future<void> subscribeToChannel(String channelName) async {
    await _pusher?.subscribe(channelName: channelName);
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    await _pusher?.unsubscribe(channelName: channelName);
  }

  Future<void> sendNotification({
    required String channel,
    required String event,
    required Map<String, dynamic> data,
  }) async {
    // This would typically be handled by your backend
    // The client can only subscribe to channels and receive notifications
  }

  Future<void> addInterest(String interest) async {
    // Pusher Beams methods are removed as per the new implementation
  }

  Future<void> removeInterest(String interest) async {
    // Pusher Beams methods are removed as per the new implementation
  }

  Future<List<String>> getInterests() async {
    // Pusher Beams methods are removed as per the new implementation
    return [];
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'smart_task_channel',
      'Smart Task Notifications',
      importance: Importance.max,
      priority: Priority.high,
      enableLights: true,
      color: Color.fromARGB(255, 255, 0, 0),
      ledColor: Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}
