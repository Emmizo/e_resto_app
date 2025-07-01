import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/pusher_service.dart';

class RealtimeDataProvider extends ChangeNotifier {
  final PusherService _pusherService = PusherService();
  final SharedPreferences _prefs;

  // Stream subscriptions
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;
  StreamSubscription<Map<String, dynamic>>? _orderUpdateSubscription;
  StreamSubscription<Map<String, dynamic>>? _reservationUpdateSubscription;
  StreamSubscription<Map<String, dynamic>>? _restaurantUpdateSubscription;
  StreamSubscription<Map<String, dynamic>>? _menuUpdateSubscription;

  // Real-time data
  Map<String, dynamic>? _latestNotification;
  Map<String, dynamic>? _latestOrderUpdate;
  Map<String, dynamic>? _latestReservationUpdate;
  Map<String, dynamic>? _latestRestaurantUpdate;
  Map<String, dynamic>? _latestMenuUpdate;

  // Connection status
  bool _isConnected = false;
  String? _userId;

  RealtimeDataProvider(this._prefs) {
    _initialize();
  }

  // Getters
  bool get isConnected => _isConnected;
  String? get userId => _userId;
  Map<String, dynamic>? get latestNotification => _latestNotification;
  Map<String, dynamic>? get latestOrderUpdate => _latestOrderUpdate;
  Map<String, dynamic>? get latestReservationUpdate => _latestReservationUpdate;
  Map<String, dynamic>? get latestRestaurantUpdate => _latestRestaurantUpdate;
  Map<String, dynamic>? get latestMenuUpdate => _latestMenuUpdate;

  Future<void> _initialize() async {
    try {
      await _pusherService.initialize();
      _isConnected = _pusherService.isConnected;

      // Set up stream listeners
      _setupStreamListeners();

      // Subscribe to global updates
      await _pusherService.subscribeToGlobalChannel();

      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing real-time data provider: $e');
    }
  }

  void _setupStreamListeners() {
    _notificationSubscription = _pusherService.notificationStream.listen(
      (data) {
        _latestNotification = data;
        _handleNotification(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Notification stream error: $error');
      },
    );

    _orderUpdateSubscription = _pusherService.orderUpdateStream.listen(
      (data) {
        _latestOrderUpdate = data;
        _handleOrderUpdate(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Order update stream error: $error');
      },
    );

    _reservationUpdateSubscription =
        _pusherService.reservationUpdateStream.listen(
      (data) {
        _latestReservationUpdate = data;
        _handleReservationUpdate(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Reservation update stream error: $error');
      },
    );

    _restaurantUpdateSubscription =
        _pusherService.restaurantUpdateStream.listen(
      (data) {
        _latestRestaurantUpdate = data;
        _handleRestaurantUpdate(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Restaurant update stream error: $error');
      },
    );

    _menuUpdateSubscription = _pusherService.menuUpdateStream.listen(
      (data) {
        _latestMenuUpdate = data;
        _handleMenuUpdate(data);
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Menu update stream error: $error');
      },
    );
  }

  void _handleNotification(Map<String, dynamic> data) {
    // Handle different types of notifications
    final type = data['type'] as String?;
    final title = data['title'] as String?;
    final body = data['body'] as String?;

    switch (type) {
      case 'order_status':
        debugPrint('Order status notification: $title - $body');
        break;
      case 'reservation_status':
        debugPrint('Reservation status notification: $title - $body');
        break;
      case 'promo_offer':
        debugPrint('Promo offer notification: $title - $body');
        break;
      case 'restaurant_update':
        debugPrint('Restaurant update notification: $title - $body');
        break;
      default:
        debugPrint('General notification: $title - $body');
    }
  }

  void _handleOrderUpdate(Map<String, dynamic> data) {
    final orderId = data['order_id'] as String?;
    final status = data['status'] as String?;
    final estimatedTime = data['estimated_time'] as String?;

    debugPrint('Order $orderId updated: $status (ETA: $estimatedTime)');

    // You can trigger specific actions based on order status
    switch (status) {
      case 'preparing':
        // Show preparing notification
        break;
      case 'ready':
        // Show ready for pickup notification
        break;
      case 'delivered':
        // Show delivery complete notification
        break;
      case 'cancelled':
        // Show cancellation notification
        break;
    }
  }

  void _handleReservationUpdate(Map<String, dynamic> data) {
    final reservationId = data['reservation_id'] as String?;
    final status = data['status'] as String?;
    final tableNumber = data['table_number'] as String?;

    debugPrint(
        'Reservation $reservationId updated: $status (Table: $tableNumber)');

    switch (status) {
      case 'confirmed':
        // Show confirmation notification
        break;
      case 'ready':
        // Show table ready notification
        break;
      case 'cancelled':
        // Show cancellation notification
        break;
    }
  }

  void _handleRestaurantUpdate(Map<String, dynamic> data) {
    final restaurantId = data['restaurant_id'] as String?;
    final updateType = data['update_type'] as String?;
    final message = data['message'] as String?;

    debugPrint('Restaurant $restaurantId update: $updateType - $message');

    switch (updateType) {
      case 'menu_updated':
        // Refresh restaurant menu
        break;
      case 'hours_changed':
        // Update restaurant hours
        break;
      case 'special_offer':
        // Show special offer
        break;
    }
  }

  void _handleMenuUpdate(Map<String, dynamic> data) {
    final restaurantId = data['restaurant_id'] as String?;
    final menuItemId = data['menu_item_id'] as String?;
    final action = data['action'] as String?; // 'added', 'updated', 'removed'

    debugPrint(
        'Menu update for restaurant $restaurantId: $action item $menuItemId');

    // Refresh menu data for the specific restaurant
  }

  Future<void> loginUser(String userId) async {
    try {
      _userId = userId;
      await _pusherService.subscribeToUserChannel(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error subscribing to user channel: $e');
    }
  }

  Future<void> logoutUser() async {
    try {
      if (_userId != null) {
        await _pusherService.unsubscribeFromChannel('private-user-$_userId');
        _userId = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error unsubscribing from user channel: $e');
    }
  }

  Future<void> subscribeToRestaurant(String restaurantId) async {
    try {
      await _pusherService.subscribeToRestaurantChannel(restaurantId);
    } catch (e) {
      debugPrint('Error subscribing to restaurant channel: $e');
    }
  }

  Future<void> unsubscribeFromRestaurant(String restaurantId) async {
    try {
      await _pusherService.unsubscribeFromChannel('restaurant-$restaurantId');
    } catch (e) {
      debugPrint('Error unsubscribing from restaurant channel: $e');
    }
  }

  Future<void> subscribeToOrder(String orderId) async {
    try {
      await _pusherService.subscribeToOrderChannel(orderId);
    } catch (e) {
      debugPrint('Error subscribing to order channel: $e');
    }
  }

  Future<void> unsubscribeFromOrder(String orderId) async {
    try {
      await _pusherService.unsubscribeFromChannel('private-order-$orderId');
    } catch (e) {
      debugPrint('Error unsubscribing from order channel: $e');
    }
  }

  Future<void> subscribeToReservation(String reservationId) async {
    try {
      await _pusherService.subscribeToReservationChannel(reservationId);
    } catch (e) {
      debugPrint('Error subscribing to reservation channel: $e');
    }
  }

  Future<void> unsubscribeFromReservation(String reservationId) async {
    try {
      await _pusherService
          .unsubscribeFromChannel('private-reservation-$reservationId');
    } catch (e) {
      debugPrint('Error unsubscribing from reservation channel: $e');
    }
  }

  void clearLatestData() {
    _latestNotification = null;
    _latestOrderUpdate = null;
    _latestReservationUpdate = null;
    _latestRestaurantUpdate = null;
    _latestMenuUpdate = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _orderUpdateSubscription?.cancel();
    _reservationUpdateSubscription?.cancel();
    _restaurantUpdateSubscription?.cancel();
    _menuUpdateSubscription?.cancel();
    _pusherService.dispose();
    super.dispose();
  }
}
