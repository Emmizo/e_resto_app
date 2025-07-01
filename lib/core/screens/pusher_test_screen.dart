import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/realtime_data_provider.dart';
import '../widgets/pusher_test_widget.dart';
import '../widgets/realtime_notification_widget.dart';

class PusherTestScreen extends StatelessWidget {
  const PusherTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusher Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection test widget
            const PusherTestWidget(),

            const SizedBox(height: 24),

            // Real-time notifications
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Notifications',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const RealtimeNotificationWidget(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Connection status
            Consumer<RealtimeDataProvider>(
              builder: (context, realtimeProvider, child) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connection Status',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              realtimeProvider.isConnected
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color: realtimeProvider.isConnected
                                  ? Colors.green
                                  : Colors.red,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    realtimeProvider.isConnected
                                        ? 'Connected'
                                        : 'Disconnected',
                                    style: TextStyle(
                                      color: realtimeProvider.isConnected
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (realtimeProvider.userId != null)
                                    Text(
                                      'User ID: ${realtimeProvider.userId}',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Testing Instructions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Tap "Test Connection" to verify Pusher connectivity\n'
                      '2. Use the Pusher Debug Console to send test events\n'
                      '3. Watch for real-time notifications appearing below\n'
                      '4. Check connection status indicator',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final realtimeProvider =
                                  context.read<RealtimeDataProvider>();
                              realtimeProvider.loginUser('test-user-123');
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Subscribed to test user channel')),
                              );
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Subscribe to Test User'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final realtimeProvider =
                                  context.read<RealtimeDataProvider>();
                              realtimeProvider.clearLatestData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Cleared notifications')),
                              );
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Notifications'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
