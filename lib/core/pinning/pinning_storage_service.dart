import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PinningStorageService {
  static const String _pinnedMessagesKey = 'pinned_messages_v1';

  /// Load pinned messages from persistent storage
  Future<List<PinnedMessageRecord>> loadPinnedMessages() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_pinnedMessagesKey);
    if (raw == null || raw.isEmpty) {
      return <PinnedMessageRecord>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> m) => PinnedMessageRecord.fromJson(m))
          .toList();
    } catch (_) {
      return <PinnedMessageRecord>[];
    }
  }

  /// Save pinned messages to persistent storage
  Future<void> savePinnedMessages(List<PinnedMessageRecord> pinnedMessages) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(pinnedMessages.map((p) => p.toJson()).toList());
    await prefs.setString(_pinnedMessagesKey, raw);
  }

  /// Add a pinned message
  Future<void> addPinnedMessage(PinnedMessageRecord pinnedMessage) async {
    final pinnedMessages = await loadPinnedMessages();
    
    // Check if already exists
    final existingIndex = pinnedMessages.indexWhere((p) => p.messageId == pinnedMessage.messageId);
    if (existingIndex != -1) {
      pinnedMessages[existingIndex] = pinnedMessage;
    } else {
      pinnedMessages.add(pinnedMessage);
    }
    
    await savePinnedMessages(pinnedMessages);
  }

  /// Remove a pinned message
  Future<void> removePinnedMessage(String messageId) async {
    final pinnedMessages = await loadPinnedMessages();
    pinnedMessages.removeWhere((p) => p.messageId == messageId);
    await savePinnedMessages(pinnedMessages);
  }

  /// Check if a message is pinned
  Future<bool> isPinned(String messageId) async {
    final pinnedMessages = await loadPinnedMessages();
    return pinnedMessages.any((p) => p.messageId == messageId);
  }

  /// Get pinned message for a specific message
  Future<PinnedMessageRecord?> getPinnedMessage(String messageId) async {
    final pinnedMessages = await loadPinnedMessages();
    try {
      return pinnedMessages.firstWhere((p) => p.messageId == messageId);
    } catch (_) {
      return null;
    }
  }

  /// Get all pinned messages for a chat
  Future<List<PinnedMessageRecord>> getPinnedMessagesByChat(String chatId) async {
    final pinnedMessages = await loadPinnedMessages();
    return pinnedMessages.where((p) => p.chatId == chatId).toList();
  }

  /// Clear all pinned messages
  Future<void> clearPinnedMessages() async {
    await savePinnedMessages(<PinnedMessageRecord>[]);
  }

  /// Update pinned message note
  Future<void> updatePinnedMessageNote(String messageId, String note) async {
    final pinnedMessage = await getPinnedMessage(messageId);
    if (pinnedMessage != null) {
      final updatedMessage = pinnedMessage.copyWith(note: note);
      await addPinnedMessage(updatedMessage);
    }
  }

  /// Get pinned messages count for a chat
  Future<int> getPinnedMessagesCount(String chatId) async {
    final pinnedMessages = await getPinnedMessagesByChat(chatId);
    return pinnedMessages.length;
  }
}

class PinnedMessageRecord {
  final String messageId;
  final String chatId;
  final String content;
  final String role;
  final DateTime timestamp;
  final String note;
  final DateTime pinnedAt;

  PinnedMessageRecord({
    required this.messageId,
    required this.chatId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.note = '',
    DateTime? pinnedAt,
  }) : pinnedAt = pinnedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'pinnedAt': pinnedAt.toIso8601String(),
    };
  }

  factory PinnedMessageRecord.fromJson(Map<String, dynamic> json) {
    return PinnedMessageRecord(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String? ?? '',
      pinnedAt: DateTime.parse(json['pinnedAt'] as String),
    );
  }

  PinnedMessageRecord copyWith({
    String? messageId,
    String? chatId,
    String? content,
    String? role,
    DateTime? timestamp,
    String? note,
    DateTime? pinnedAt,
  }) {
    return PinnedMessageRecord(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      pinnedAt: pinnedAt ?? this.pinnedAt,
    );
  }
}