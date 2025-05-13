import 'package:flutter/material.dart';
import 'package:e_resta_app/core/services/database_helper.dart';

class FailedActionsScreen extends StatefulWidget {
  const FailedActionsScreen({super.key});

  @override
  State<FailedActionsScreen> createState() => _FailedActionsScreenState();
}

class _FailedActionsScreenState extends State<FailedActionsScreen> {
  List<Map<String, dynamic>> _failedActions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFailedActions();
  }

  Future<void> _loadFailedActions() async {
    final db = await DatabaseHelper().db;
    // Show all actions with a lastError (optionally filter by retryCount >= 3)
    final actions = await db.query(
      'action_queue',
      where: 'lastError IS NOT NULL AND lastError != ""',
      orderBy: 'createdAt ASC',
    );
    setState(() {
      _failedActions = actions;
      _loading = false;
    });
  }

  Future<void> _retryAction(int id) async {
    final db = await DatabaseHelper().db;
    await db.update(
      'action_queue',
      {'retryCount': 0, 'lastError': null},
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadFailedActions();
  }

  Future<void> _deleteAction(int id) async {
    final db = await DatabaseHelper().db;
    await db.delete('action_queue', where: 'id = ?', whereArgs: [id]);
    await _loadFailedActions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sync Errors')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failedActions.isEmpty
              ? const Center(child: Text('No failed actions!'))
              : ListView.separated(
                  itemCount: _failedActions.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final action = _failedActions[index];
                    return ListTile(
                      title: Text(
                        action['actionType'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        action['lastError'] ?? 'Unknown error',
                        style: const TextStyle(color: Colors.red),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            tooltip: 'Retry',
                            onPressed: () => _retryAction(action['id'] as int),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            tooltip: 'Delete',
                            onPressed: () => _deleteAction(action['id'] as int),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
