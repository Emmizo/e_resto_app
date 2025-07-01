import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../constants/pusher_config.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();
  factory PusherService() => _instance;

  late PusherChannelsFlutter _pusherClient;
  bool _isConnected = false;
  String? _userId;

  // Stream controllers for different types of real-time data
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _orderUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _reservationUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _restaurantUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _menuUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get orderUpdateStream =>
      _orderUpdateController.stream;
  Stream<Map<String, dynamic>> get reservationUpdateStream =>
      _reservationUpdateController.stream;
  Stream<Map<String, dynamic>> get restaurantUpdateStream =>
      _restaurantUpdateController.stream;
  Stream<Map<String, dynamic>> get menuUpdateStream =>
      _menuUpdateController.stream;

  PusherService._internal();

  Future<void> initialize() async {
    try {
      _pusherClient = PusherChannelsFlutter.getInstance();

      await _pusherClient.init(
        apiKey: PusherConfig.appKey,
        cluster: PusherConfig.cluster,
        onEvent: _handlePusherEvent,
        onConnectionStateChange: _handleConnectionStateChange,
        onError: _handlePusherError,
        onSubscriptionSucceeded: _handleSubscriptionSucceeded,
        onSubscriptionError: _handleSubscriptionError,
        // Optional: Add custom host if needed
        // host: PusherConfig.host,
        // port: PusherConfig.port,
        // encrypted: PusherConfig.encrypted,
      );

      await _connect();
    } catch (e) {
      debugPrint('Pusher initialization error: $e');
    }
  }

  Future<void> _connect() async {
    try {
      await _pusherClient.connect();
      _isConnected = true;
      debugPrint('Pusher connected successfully');
    } catch (e) {
      debugPrint('Pusher connection error: $e');
      _isConnected = false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _pusherClient.disconnect();
      _isConnected = false;
      debugPrint('Pusher disconnected');
    } catch (e) {
      debugPrint('Pusher disconnection error: $e');
    }
  }

  Future<void> subscribeToUserChannel(String userId) async {
    if (!_isConnected) {
      debugPrint('Pusher not connected. Attempting to reconnect...');
      await _connect();
    }

    try {
      _userId = userId;
      final channelName = PusherConfig.userChannel(userId);

      await _pusherClient.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleUserChannelEvent(event);
        },
      );

      debugPrint('Subscribed to user channel: $channelName');
    } catch (e) {
      debugPrint('Error subscribing to user channel: $e');
    }
  }

  Future<void> subscribeToRestaurantChannel(String restaurantId) async {
    if (!_isConnected) return;

    try {
      final channelName = PusherConfig.restaurantChannel(restaurantId);

      await _pusherClient.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleRestaurantChannelEvent(event);
        },
      );

      debugPrint('Subscribed to restaurant channel: $restaurantId');
    } catch (e) {
      debugPrint('Error subscribing to restaurant channel: $e');
    }
  }

  Future<void> subscribeToOrderChannel(String orderId) async {
    if (!_isConnected) return;

    try {
      final channelName = PusherConfig.orderChannel(orderId);

      await _pusherClient.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleOrderChannelEvent(event);
        },
      );

      debugPrint('Subscribed to order channel: $orderId');
    } catch (e) {
      debugPrint('Error subscribing to order channel: $e');
    }
  }

  Future<void> subscribeToReservationChannel(String reservationId) async {
    if (!_isConnected) return;

    try {
      final channelName = PusherConfig.reservationChannel(reservationId);

      await _pusherClient.subscribe(
        channelName: channelName,
        onEvent: (event) {
          _handleReservationChannelEvent(event);
        },
      );

      debugPrint('Subscribed to reservation channel: $reservationId');
    } catch (e) {
      debugPrint('Error subscribing to reservation channel: $e');
    }
  }

  Future<void> subscribeToGlobalChannel() async {
    if (!_isConnected) return;

    try {
      await _pusherClient.subscribe(
        channelName: PusherConfig.globalChannel,
        onEvent: (event) {
          _handleGlobalChannelEvent(event);
        },
      );

      debugPrint('Subscribed to global updates channel');
    } catch (e) {
      debugPrint('Error subscribing to global channel: $e');
    }
  }

  void _handlePusherEvent(PusherEvent event) {
    debugPrint(
        'Pusher event received: ${event.eventName} on ${event.channelName}');

    try {
      final data = jsonDecode(event.data);

      switch (event.eventName) {
        case PusherConfig.notificationEvent:
          _notificationController.add(data);
          break;
        case PusherConfig.orderUpdatedEvent:
          _orderUpdateController.add(data);
          break;
        case PusherConfig.reservationUpdatedEvent:
          _reservationUpdateController.add(data);
          break;
        case PusherConfig.restaurantUpdatedEvent:
          _restaurantUpdateController.add(data);
          break;
        case PusherConfig.menuUpdatedEvent:
          _menuUpdateController.add(data);
          break;
        default:
          debugPrint('Unhandled event: ${event.eventName}');
      }
    } catch (e) {
      debugPrint('Error parsing Pusher event data: $e');
    }
  }

  void _handleUserChannelEvent(PusherEvent event) {
    debugPrint('User channel event: ${event.eventName}');
    _handlePusherEvent(event);
  }

  void _handleRestaurantChannelEvent(PusherEvent event) {
    debugPrint('Restaurant channel event: ${event.eventName}');
    _handlePusherEvent(event);
  }

  void _handleOrderChannelEvent(PusherEvent event) {
    debugPrint('Order channel event: ${event.eventName}');
    _handlePusherEvent(event);
  }

  void _handleReservationChannelEvent(PusherEvent event) {
    debugPrint('Reservation channel event: ${event.eventName}');
    _handlePusherEvent(event);
  }

  void _handleGlobalChannelEvent(PusherEvent event) {
    debugPrint('Global channel event: ${event.eventName}');
    _handlePusherEvent(event);
  }

  dynamic _handleConnectionStateChange(
      String currentState, String previousState) {
    debugPrint(
        'Pusher connection state: $currentState (previous: $previousState)');
    _isConnected = currentState == 'CONNECTED';
    return null;
  }

  dynamic _handlePusherError(String message, dynamic code, dynamic e) {
    debugPrint('Pusher error: $message, code: $code, error: $e');
    return null;
  }

  dynamic _handleSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('Successfully subscribed to channel: $channelName');
    return null;
  }

  dynamic _handleSubscriptionError(String message, dynamic e) {
    debugPrint('Pusher subscription error: $message, error: $e');
    return null;
  }

  Future<void> unsubscribeFromChannel(String channelName) async {
    try {
      await _pusherClient.unsubscribe(channelName: channelName);
      debugPrint('Unsubscribed from channel: $channelName');
    } catch (e) {
      debugPrint('Error unsubscribing from channel: $e');
    }
  }

  Future<void> unsubscribeFromAllChannels() async {
    try {
      // Note: Pusher doesn't have an unsubscribeAll method
      // You need to unsubscribe from each channel individually
      debugPrint('Please unsubscribe from channels individually');
    } catch (e) {
      debugPrint('Error unsubscribing from all channels: $e');
    }
  }

  bool get isConnected => _isConnected;
  String? get userId => _userId;

  // Test method to verify connection
  Future<bool> testConnection() async {
    try {
      await initialize();
      await Future.delayed(const Duration(seconds: 2));
      return _isConnected;
    } catch (e) {
      debugPrint('Pusher connection test failed: $e');
      return false;
    }
  }

  void dispose() {
    _notificationController.close();
    _orderUpdateController.close();
    _reservationUpdateController.close();
    _restaurantUpdateController.close();
    _menuUpdateController.close();
    disconnect();
  }
}
