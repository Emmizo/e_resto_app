import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/pusher_config.dart';
import '../providers/realtime_data_provider.dart';
import '../services/pusher_service.dart';

class PusherTestWidget extends StatefulWidget {
  const PusherTestWidget({super.key});

  @override
  State<PusherTestWidget> createState() => _PusherTestWidgetState();
}

class _PusherTestWidgetState extends State<PusherTestWidget> {
  bool _isTesting = false;
  String _testResult = '';

  Future<void> _testPusherConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testing connection...';
    });

    try {
      final pusherService = PusherService();
      final isConnected = await pusherService.testConnection();

      setState(() {
        _testResult = isConnected
            ? '✅ Pusher connection successful!'
            : '❌ Pusher connection failed';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeDataProvider>(
      builder: (context, realtimeProvider, child) {
        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pusher Connection Test',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      realtimeProvider.isConnected
                          ? Icons.wifi
                          : Icons.wifi_off,
                      color: realtimeProvider.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      realtimeProvider.isConnected
                          ? 'Connected'
                          : 'Disconnected',
                      style: TextStyle(
                        color: realtimeProvider.isConnected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_testResult.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _testResult.contains('✅')
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _testResult,
                      style: TextStyle(
                        color: _testResult.contains('✅')
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _testPusherConnection,
                  icon: _isTesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi),
                  label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                ),
                const SizedBox(height: 8),
                Text(
                  'App Key: ${PusherConfig.appKey}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  'Cluster: ${PusherConfig.cluster}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
