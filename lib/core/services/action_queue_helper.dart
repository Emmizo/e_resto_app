import 'dart:convert';
import 'package:e_resta_app/core/services/database_helper.dart';

class ActionQueueHelper {
  static Future<void> queueAction({
    required String actionType,
    required Map<String, dynamic> payload,
  }) async {
    final db = await DatabaseHelper().db;
    await db.insert('action_queue', {
      'actionType': actionType,
      'payload': jsonEncode(payload),
      'createdAt': DateTime.now().toIso8601String(),
    });
  }
}
