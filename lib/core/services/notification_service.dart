import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/restaurant/data/models/restaurant_model.dart';
import '../constants/api_endpoints.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Firestore reference for users and notifications
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference _userNotifyCollection =
      FirebaseFirestore.instance.collection('user_notify');
  final CollectionReference _ordersCollection =
      FirebaseFirestore.instance.collection('orders');
  final CollectionReference _reservationsCollection =
      FirebaseFirestore.instance.collection('reservations');

  NotificationService._internal();

  Future<void> initialize(BuildContext context) async {
    await _requestPermission();
    await _initLocalNotifications();
    await _setupFCM();
    // Optionally: _listenForNotifications();
    // Optionally: startScheduledNotificationChecker();
  }

  Future<void> _requestPermission() async {
    if (Platform.isAndroid) {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImplementation?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await _firebaseMessaging.requestPermission();
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        message.notification!.title ?? 'New Notification',
        message.notification!.body ?? 'You have a new notification',
        payload: jsonEncode(message.data),
      );
      // Optionally: addNotificationToProvider(...)
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response);
      },
    );
  }

  void _handleNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        // Example: deep-link to reservation/order details
        if (data['type'] == 'reservation_status' &&
            data['reservation_id'] != null) {
          // Replace with your navigation logic
          // navigatorKey.currentState?.pushNamed(
          //   '/reservation-details',
          //   arguments: {'reservationId': data['reservation_id']},
          // );
        }
        // Add more types as needed
      } catch (e) {
        // Remove print statements
      }
    }
  }

  Future<void> _setupFCM() async {
    try {
      if (Platform.isIOS) {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
        // Wait for APNS token
        String? apnsToken;
        int apnsAttempts = 0;
        while (apnsToken == null && apnsAttempts < 3) {
          try {
            apnsToken = await _firebaseMessaging.getAPNSToken();
            if (apnsToken == null) {
              await Future.delayed(const Duration(seconds: 2));
              apnsAttempts++;
            }
          } catch (e) {
            await Future.delayed(const Duration(seconds: 2));
            apnsAttempts++;
          }
        }
        await Future.delayed(const Duration(seconds: 1));
      }
      // Get FCM token
      String? token;
      int fcmAttempts = 0;
      while (token == null && fcmAttempts < 3) {
        try {
          token = await _firebaseMessaging.getToken();
          // print('FCM Token: ${token ?? 'null'}');
          if (token == null) {
            await Future.delayed(const Duration(seconds: 2));
            fcmAttempts++;
          } else {
            await _saveTokenToFirestore(token);
          }
        } catch (e) {
          await Future.delayed(const Duration(seconds: 2));
          fcmAttempts++;
        }
      }
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        if (message.data.isNotEmpty) {
          _showLocalNotification(
            message.notification?.title ?? 'Notification',
            message.notification?.body ?? '',
            payload: jsonEncode(message.data),
          );
        }
      });
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null && initialMessage.data.isNotEmpty) {
        _showLocalNotification(
          initialMessage.notification?.title ?? 'Notification',
          initialMessage.notification?.body ?? '',
          payload: jsonEncode(initialMessage.data),
        );
      }
    } catch (e) {
      // Remove print statements
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await _usersCollection.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      await _userNotifyCollection.doc(user.uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'devices': FieldValue.arrayUnion([
          {
            'token': token,
            'platform': Platform.operatingSystem,
            'lastActive': FieldValue.serverTimestamp(),
          },
        ]),
      }, SetOptions(merge: true));
    } catch (e) {
      // Remove print statements
    }
  }

  Future<void> _showLocalNotification(
    String title,
    String body, {
    String? payload,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    const String sound = 'notification_sound';
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
      sound: RawResourceAndroidNotificationSound(sound),
    );
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'default',
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

  static Future<void> showLocalNotification(
      {required String title, required String body}) async {
    await _instance._showLocalNotification(
      title,
      body,
    );
  }

  static Future<void> startProximityMonitoring() async {
    // Fetch restaurants and liked menu items
    await _fetchAllRestaurants();
    await _fetchLikedMenuItems();
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // meters
      ),
    ).listen((Position position) {
      _checkNearbyRestaurants(position);
    });
  }

  static Future<void> _fetchAllRestaurants() async {
    try {
      final dio = Dio();
      final response = await dio.get(ApiEndpoints.restaurants);
      final data = response.data['data'] as List;
      _restaurants =
          data.map((json) => RestaurantModel.fromJson(json)).toList();
    } catch (_) {}
  }

  static Future<void> _fetchLikedMenuItems() async {
    try {
      final dio = Dio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final response = await dio.get(
        ApiEndpoints.menuFavorites,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data['data'] as List;
      _likedMenuItemIds =
          data.map((item) => item['menu_item']['id'] as int).toList();
    } catch (_) {}
  }

  static Future<void> _checkNearbyRestaurants(Position userPosition) async {
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

  /// Create a reservation in Firestore
  Future<void> createReservation({
    required String userId,
    required String restaurantId,
    String status = 'pending',
    Map<String, dynamic>? extraFields,
  }) async {
    await _reservationsCollection.add({
      'userId': userId,
      'restaurantId': restaurantId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extraFields,
    });
  }

  /// Create an order in Firestore
  Future<void> createOrder({
    required String userId,
    required String restaurantId,
    String status = 'pending',
    Map<String, dynamic>? extraFields,
  }) async {
    await _ordersCollection.add({
      'userId': userId,
      'restaurantId': restaurantId,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extraFields,
    });
  }

  /// Stream of all reservations for a user
  Stream<QuerySnapshot> reservationsStream(String userId) {
    return _reservationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of all orders for a user
  Stream<QuerySnapshot> ordersStream(String userId) {
    return _ordersCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of all favorite menu items for a user
  Stream<QuerySnapshot> favoriteMenuItemsStream(String userId) {
    return FirebaseFirestore.instance
        .collection('favorite_menu_items')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
