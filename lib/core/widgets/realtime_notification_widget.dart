import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/realtime_data_provider.dart';

class RealtimeNotificationWidget extends StatelessWidget {
  const RealtimeNotificationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeDataProvider>(
      builder: (context, realtimeProvider, child) {
        final latestNotification = realtimeProvider.latestNotification;
        final latestOrderUpdate = realtimeProvider.latestOrderUpdate;
        final latestReservationUpdate =
            realtimeProvider.latestReservationUpdate;
        final isConnected = realtimeProvider.isConnected;

        return Column(
          children: [
            // Connection status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? 'Live' : 'Offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Latest notification
            if (latestNotification != null)
              _buildNotificationCard(
                context,
                'Notification',
                latestNotification['title'] ?? 'New Notification',
                latestNotification['body'] ?? 'You have a new notification',
                Icons.notifications,
                Colors.blue,
              ),

            // Latest order update
            if (latestOrderUpdate != null)
              _buildNotificationCard(
                context,
                'Order Update',
                'Order #${latestOrderUpdate['order_id']}',
                'Status: ${latestOrderUpdate['status']}',
                Icons.receipt,
                Colors.orange,
              ),

            // Latest reservation update
            if (latestReservationUpdate != null)
              _buildNotificationCard(
                context,
                'Reservation Update',
                'Reservation #${latestReservationUpdate['reservation_id']}',
                'Status: ${latestReservationUpdate['status']}',
                Icons.table_restaurant,
                Colors.green,
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    String type,
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // Clear the notification
              context.read<RealtimeDataProvider>().clearLatestData();
            },
            icon: const Icon(Icons.close, size: 18),
            color: Colors.grey[500],
          ),
        ],
      ),
    );
  }
}

class RealtimeStatusBar extends StatelessWidget {
  const RealtimeStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeDataProvider>(
      builder: (context, realtimeProvider, child) {
        final isConnected = realtimeProvider.isConnected;
        final userId = realtimeProvider.userId;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: isConnected
                    ? Colors.green.withOpacity(0.3)
                    : Colors.red.withOpacity(0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isConnected
                    ? 'Real-time updates active${userId != null ? ' for user $userId' : ''}'
                    : 'Real-time updates offline',
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (isConnected)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
