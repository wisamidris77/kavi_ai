import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  static const String _storageKey = 'app_settings_v1';

  Future<AppSettings> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return AppSettings.initial();
    }
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return AppSettings.fromJson(map);
    } catch (_) {
      return AppSettings.initial();
    }
  }

  Future<void> save(AppSettings settings) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(settings.toJson());
    await prefs.setString(_storageKey, raw);
  }
} 