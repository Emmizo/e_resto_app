class PusherConfig {
  // Pusher credentials
  static const String appKey = '533a42e55e800d1277d5';
  static const String cluster = 'mt1';
  static const String appId = '2006722';
  static const String secret = '6e86f001ead44e49cad3';
  static const String host = 'YOUR_PUSHER_HOST'; // Optional, for custom host
  static const int port = 443; // Optional, default is 443
  static const bool encrypted = true; // Optional, default is true

  // Channel names
  static const String globalChannel = 'global-updates';
  static String userChannel(String userId) => 'private-user-$userId';
  static String restaurantChannel(String restaurantId) =>
      'restaurant-$restaurantId';
  static String orderChannel(String orderId) => 'private-order-$orderId';
  static String reservationChannel(String reservationId) =>
      'private-reservation-$reservationId';

  // Event names
  static const String notificationEvent = 'notification';
  static const String orderUpdatedEvent = 'order-updated';
  static const String reservationUpdatedEvent = 'reservation-updated';
  static const String restaurantUpdatedEvent = 'restaurant-updated';
  static const String menuUpdatedEvent = 'menu-updated';

  // Notification types
  static const String orderStatusNotification = 'order_status';
  static const String reservationStatusNotification = 'reservation_status';
  static const String promoOfferNotification = 'promo_offer';
  static const String restaurantUpdateNotification = 'restaurant_update';
  static const String menuUpdateNotification = 'menu_update';

  // Order statuses
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Reservation statuses
  static const String reservationStatusConfirmed = 'confirmed';
  static const String reservationStatusReady = 'ready';
  static const String reservationStatusCancelled = 'cancelled';

  // Restaurant update types
  static const String restaurantUpdateMenu = 'menu_updated';
  static const String restaurantUpdateHours = 'hours_changed';
  static const String restaurantUpdateSpecialOffer = 'special_offer';

  // Menu update actions
  static const String menuActionAdded = 'added';
  static const String menuActionUpdated = 'updated';
  static const String menuActionRemoved = 'removed';
}
