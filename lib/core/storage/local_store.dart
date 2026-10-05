import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  Future<List<Map<String, dynamic>>> readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw StateError('داده ذخیره‌شده برای کلید "$key" ساختار فهرست ندارد.');
    }

    final rows = <Map<String, dynamic>>[];
    for (final item in decoded) {
      if (item is! Map) {
        throw StateError('رکورد ذخیره‌شده برای کلید "$key" ساختار معتبری ندارد.');
      }
      rows.add(Map<String, dynamic>.from(item));
    }

    return rows;
  }

  Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, jsonEncode(data));
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
