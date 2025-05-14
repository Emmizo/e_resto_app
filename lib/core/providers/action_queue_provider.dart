import 'package:flutter/material.dart';
import 'package:e_resta_app/core/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class ActionQueueProvider extends ChangeNotifier {
  int _pendingCount = 0;
  int get pendingCount => _pendingCount;
  bool _disposed = false;

  ActionQueueProvider() {
    refresh();
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
