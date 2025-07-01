# Pusher Real-Time Integration Setup Guide

This guide will help you set up Pusher for real-time notifications and data updates in your E-Resto Flutter app.

## 1. Pusher Account Setup

### 1.1 Create a Pusher Account
1. Go to [pusher.com](https://pusher.com) and create a free account
2. Create a new Channels app
3. Note down your app credentials:
   - App ID
   - App Key
   - App Secret
   - Cluster (e.g., us2, eu, ap1)

### 1.2 Update Configuration
Update the `lib/core/constants/pusher_config.dart` file with your actual Pusher credentials:

```dart
class PusherConfig {
  // Replace these with your actual Pusher credentials
  static const String appKey = 'YOUR_ACTUAL_APP_KEY';
  static const String cluster = 'YOUR_ACTUAL_CLUSTER';
  // ... rest of the configuration
}
```

## 2. Backend Integration

### 2.1 Backend Requirements
Your backend needs to:
1. Install Pusher server SDK for your backend language
2. Configure Pusher with your app credentials
3. Trigger events to specific channels

### 2.2 Example Backend Events (Laravel/PHP)
```php
// Trigger order status update
Pusher::trigger('private-order-123', 'order-updated', [
    'order_id' => '123',
    'status' => 'preparing',
    'estimated_time' => '20 minutes'
]);

// Trigger user notification
Pusher::trigger('private-user-456', 'notification', [
    'type' => 'order_status',
    'title' => 'Order Update',
    'body' => 'Your order is being prepared'
]);

// Trigger restaurant update
Pusher::trigger('restaurant-789', 'restaurant-updated', [
    'restaurant_id' => '789',
    'update_type' => 'menu_updated',
    'message' => 'New items added to menu'
]);
```

### 2.3 Example Backend Events (Node.js)
```javascript
const Pusher = require('pusher');

const pusher = new Pusher({
  appId: 'YOUR_APP_ID',
  key: 'YOUR_APP_KEY',
  secret: 'YOUR_APP_SECRET',
  cluster: 'YOUR_CLUSTER',
  useTLS: true
});

// Trigger order status update
pusher.trigger('private-order-123', 'order-updated', {
  order_id: '123',
  status: 'preparing',
  estimated_time: '20 minutes'
});
```

## 3. Flutter App Integration

### 3.1 Dependencies
The required dependencies are already included in your `pubspec.yaml`:
```yaml
dependencies:
  pusher_channels_flutter: ^2.4.0
```

### 3.2 Provider Setup
The `RealtimeDataProvider` is already added to your main.dart:

```dart
ChangeNotifierProvider(create: (_) => RealtimeDataProvider(prefs)),
```

### 3.3 Using Real-Time Data in Your Screens

#### Example: Order History Screen
```dart
class OrderHistoryScreen extends StatefulWidget {
  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to order updates when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeProvider = context.read<RealtimeDataProvider>();
      // Subscribe to specific order channels
      realtimeProvider.subscribeToOrder('order-123');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeDataProvider>(
      builder: (context, realtimeProvider, child) {
        final orderUpdate = realtimeProvider.latestOrderUpdate;
        
        return Scaffold(
          appBar: AppBar(title: Text('Order History')),
          body: Column(
            children: [
              // Show real-time status bar
              RealtimeStatusBar(),
              
              // Show latest order update
              if (orderUpdate != null)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Order ${orderUpdate['order_id']} is ${orderUpdate['status']}'),
                ),
              
              // Your existing order list
              Expanded(child: OrderList()),
            ],
          ),
        );
      },
    );
  }
}
```

#### Example: Restaurant Details Screen
```dart
class RestaurantDetailsScreen extends StatefulWidget {
  final String restaurantId;
  
  RestaurantDetailsScreen({required this.restaurantId});
  
  @override
  _RestaurantDetailsScreenState createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  @override
  void initState() {
    super.initState();
    // Subscribe to restaurant updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final realtimeProvider = context.read<RealtimeDataProvider>();
      realtimeProvider.subscribeToRestaurant(widget.restaurantId);
    });
  }

  @override
  void dispose() {
    // Unsubscribe when leaving the screen
    final realtimeProvider = context.read<RealtimeDataProvider>();
    realtimeProvider.unsubscribeFromRestaurant(widget.restaurantId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeDataProvider>(
      builder: (context, realtimeProvider, child) {
        final restaurantUpdate = realtimeProvider.latestRestaurantUpdate;
        
        return Scaffold(
          appBar: AppBar(title: Text('Restaurant Details')),
          body: Column(
            children: [
              RealtimeStatusBar(),
              
              if (restaurantUpdate != null)
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Restaurant update: ${restaurantUpdate['message']}'),
                ),
              
              // Your existing restaurant details
              Expanded(child: RestaurantDetails()),
            ],
          ),
        );
      },
    );
  }
}
```

## 4. Authentication Integration

### 4.1 User Login
When a user logs in, subscribe them to their personal channel:

```dart
// In your login success handler
final realtimeProvider = context.read<RealtimeDataProvider>();
await realtimeProvider.loginUser(user.id.toString());
```

### 4.2 User Logout
When a user logs out, unsubscribe them:

```dart
// In your logout handler
final realtimeProvider = context.read<RealtimeDataProvider>();
await realtimeProvider.logoutUser();
```

## 5. Channel Types

### 5.1 Public Channels
- `global-updates`: For general app updates
- `restaurant-{id}`: For restaurant-specific updates

### 5.2 Private Channels
- `private-user-{id}`: For user-specific notifications
- `private-order-{id}`: For order-specific updates
- `private-reservation-{id}`: For reservation-specific updates

## 6. Event Types

### 6.1 Notification Events
```json
{
  "type": "order_status|reservation_status|promo_offer|restaurant_update",
  "title": "Notification Title",
  "body": "Notification Message"
}
```

### 6.2 Order Update Events
```json
{
  "order_id": "123",
  "status": "preparing|ready|delivered|cancelled",
  "estimated_time": "20 minutes"
}
```

### 6.3 Reservation Update Events
```json
{
  "reservation_id": "456",
  "status": "confirmed|ready|cancelled",
  "table_number": "A5"
}
```

### 6.4 Restaurant Update Events
```json
{
  "restaurant_id": "789",
  "update_type": "menu_updated|hours_changed|special_offer",
  "message": "Update message"
}
```

## 7. Testing

### 7.1 Pusher Debug Console
1. Go to your Pusher app dashboard
2. Use the Debug Console to send test events
3. Verify events are received in your Flutter app

### 7.2 Test Event Example
```json
{
  "event": "notification",
  "channel": "private-user-123",
  "data": {
    "type": "order_status",
    "title": "Test Notification",
    "body": "This is a test notification"
  }
}
```

## 8. Best Practices

### 8.1 Channel Management
- Subscribe to channels only when needed
- Unsubscribe when leaving screens
- Use private channels for sensitive data

### 8.2 Error Handling
- Handle connection errors gracefully
- Implement reconnection logic
- Show appropriate UI feedback

### 8.3 Performance
- Limit the number of active subscriptions
- Clean up subscriptions properly
- Use appropriate channel names

## 9. Troubleshooting

### 9.1 Common Issues
1. **Connection failed**: Check your Pusher credentials
2. **Events not received**: Verify channel names and event names
3. **Private channel access denied**: Ensure proper authentication

### 9.2 Debug Information
Enable debug logging in your Pusher service to see connection and event details.

## 10. Security Considerations

1. **Private Channels**: Use private channels for sensitive data
2. **Authentication**: Implement proper user authentication
3. **Channel Authorization**: Set up channel authorization on your backend
4. **Event Validation**: Validate event data on both client and server

## 11. Next Steps

1. Update your Pusher credentials in the config file
2. Implement backend event triggers
3. Add real-time widgets to your screens
4. Test the integration thoroughly
5. Monitor usage and performance

For more information, visit the [Pusher documentation](https://pusher.com/docs).