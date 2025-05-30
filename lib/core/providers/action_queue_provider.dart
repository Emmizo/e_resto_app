import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_helper.dart';

class ActionQueueProvider extends ChangeNotifier {
  static ActionQueueProvider? globalInstance;
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;
  bool _disposed = false;

  ActionQueueProvider() {
    globalInstance = this;
    refresh();
  }

  static Future<void> refreshAll() async {
    if (globalInstance != null) {
      await globalInstance!.refresh();
    }
  }

  Future<void> refresh() async {
    final db = await DatabaseHelper().db;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM action_queue'),
    );
    _pendingCount = count ?? 0;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
