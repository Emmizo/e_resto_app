import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/services/notification_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _pushEnabled = true;
  bool _orderUpdates = true;
  bool _specialOffers = true;
  bool _deliveryUpdates = true;
  bool _reservationReminders = true;
  bool _restaurantNews = false;
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _nearbyRestaurantAlerts = true;
  bool _nearbyLikedMenuAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Push Notifications Section
            _buildSectionHeader(
              context,
              'Push Notifications',
              'Receive notifications on your device',
            ),
            SwitchListTile(
              value: _pushEnabled,
              onChanged: (value) {
                setState(() {
                  _pushEnabled = value;
                });
              },
              title: const Text('Enable Push Notifications'),
              subtitle: const Text('Turn on/off all push notifications'),
            ).animate().fadeIn().slideX(),

            if (_pushEnabled) ...[
              _buildNotificationOption(
                'Order Updates',
                'Get notified about your order status',
                _orderUpdates,
                (value) {
                  setState(() {
                    _orderUpdates = value;
                  });
                },
              ),
              _buildNotificationOption(
                'Special Offers',
                'Receive exclusive deals and promotions',
                _specialOffers,
                (value) {
                  setState(() {
                    _specialOffers = value;
                  });
                },
              ),
              _buildNotificationOption(
                'Delivery Updates',
                'Track your delivery in real-time',
                _deliveryUpdates,
                (value) {
                  setState(() {
                    _deliveryUpdates = value;
                  });
                },
              ),
              _buildNotificationOption(
                'Reservation Reminders',
                'Get reminded about upcoming reservations',
                _reservationReminders,
                (value) {
                  setState(() {
                    _reservationReminders = value;
                  });
                },
              ),
              _buildNotificationOption(
                'Restaurant News',
                'Updates from your favorite restaurants',
                _restaurantNews,
                (value) {
                  setState(() {
                    _restaurantNews = value;
                  });
                },
              ),
              _buildNotificationOption(
                'Nearby Restaurant Alerts',
                'Get notified when you are near a restaurant',
                _nearbyRestaurantAlerts,
                (value) async {
                  setState(() {
                    _nearbyRestaurantAlerts = value;
                  });
                  await NotificationService.updatePreferences(
                    nearbyRestaurantAlerts: _nearbyRestaurantAlerts,
                    nearbyLikedMenuAlerts: _nearbyLikedMenuAlerts,
                  );
                  if (_nearbyRestaurantAlerts || _nearbyLikedMenuAlerts) {
                    NotificationService.startProximityMonitoring();
                  }
                },
              ),
              _buildNotificationOption(
                'Nearby Liked Menu Alerts',
                'Get notified when you are near a restaurant with a menu item you like',
                _nearbyLikedMenuAlerts,
                (value) async {
                  setState(() {
                    _nearbyLikedMenuAlerts = value;
                  });
                  await NotificationService.updatePreferences(
                    nearbyRestaurantAlerts: _nearbyRestaurantAlerts,
                    nearbyLikedMenuAlerts: _nearbyLikedMenuAlerts,
                  );
                  if (_nearbyRestaurantAlerts || _nearbyLikedMenuAlerts) {
                    NotificationService.startProximityMonitoring();
                  }
                },
              ),
            ],

            const Divider(height: 32),

            // Other Notifications Section
            _buildSectionHeader(
              context,
              'Other Notifications',
              'Additional notification channels',
            ),
            _buildNotificationOption(
              'Email Notifications',
              'Receive updates via email',
              _emailNotifications,
              (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
            _buildNotificationOption(
              'SMS Notifications',
              'Get text message updates',
              _smsNotifications,
              (value) {
                setState(() {
                  _smsNotifications = value;
                });
              },
            ),

            // Notification Schedule
            const Divider(height: 32),
            _buildSectionHeader(
              context,
              'Quiet Hours',
              'Set times when you don\'t want to be disturbed',
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement quiet hours settings
                },
                child: const Text('Configure Quiet Hours'),
              ),
            ).animate().fadeIn().slideX(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildNotificationOption(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(subtitle),
    ).animate().fadeIn().slideX();
  }
}
