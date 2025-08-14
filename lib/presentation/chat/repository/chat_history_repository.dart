import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/models/chat_model.dart';

class ChatHistoryRepository {
  static const String _storageKey = 'chat_history_v1';

  Future<List<ChatModel>> loadAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return <ChatModel>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> m) => ChatModel.fromJson(m))
          .toList(growable: true);
    } catch (_) {
      return <ChatModel>[];
    }
  }

  Future<void> saveAll(List<ChatModel> chats) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(chats.map((ChatModel c) => c.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }
} 