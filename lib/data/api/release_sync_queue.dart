import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

abstract interface class ReleaseSyncQueue {
  Future<void> put(String key, Map<String, dynamic> job);
  Future<Map<String, Map<String, dynamic>>> pending();
  Future<void> remove(String key, {String? operationId});
}

/// No tokens are persisted. App and actor have separate durable outboxes.
class HiveReleaseSyncQueue implements ReleaseSyncQueue {
  HiveReleaseSyncQueue(this.scope);
  final String scope;
  Future<Box<dynamic>> _box() async {
    final name =
        'release_sync_${base64Url.encode(utf8.encode(scope)).replaceAll('=', '')}';
    return Hive.isBoxOpen(name)
        ? Hive.box<dynamic>(name)
        : Hive.openBox<dynamic>(name);
  }

  @override
  Future<void> put(String key, Map<String, dynamic> job) async =>
      (await _box()).put(key, job);
  @override
  Future<void> remove(String key, {String? operationId}) async {
    final box = await _box();
    final current = box.get(key);
    if (operationId == null ||
        current is Map && current['operationId'] == operationId) {
      await box.delete(key);
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> pending() async {
    final box = await _box();
    return {
      for (final key in box.keys)
        key.toString(): Map<String, dynamic>.from(box.get(key) as Map),
    };
  }
}
