import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ThreadStorageService {
  static const String _threadsKey = 'thread_view_data_v1';

  /// Load thread data from persistent storage
  Future<List<ThreadRecord>> loadThreads() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_threadsKey);
    if (raw == null || raw.isEmpty) {
      return <ThreadRecord>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> m) => ThreadRecord.fromJson(m))
          .toList();
    } catch (_) {
      return <ThreadRecord>[];
    }
  }

  /// Save thread data to persistent storage
  Future<void> saveThreads(List<ThreadRecord> threads) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(threads.map((t) => t.toJson()).toList());
    await prefs.setString(_threadsKey, raw);
  }

  /// Add or update a thread
  Future<void> saveThread(ThreadRecord thread) async {
    final threads = await loadThreads();
    
    // Check if already exists
    final existingIndex = threads.indexWhere((t) => t.parentMessageId == thread.parentMessageId);
    if (existingIndex != -1) {
      threads[existingIndex] = thread;
    } else {
      threads.add(thread);
    }
    
    await saveThreads(threads);
  }

  /// Remove a thread
  Future<void> removeThread(String parentMessageId) async {
    final threads = await loadThreads();
    threads.removeWhere((t) => t.parentMessageId == parentMessageId);
    await saveThreads(threads);
  }

  /// Get thread for a specific message
  Future<ThreadRecord?> getThread(String parentMessageId) async {
    final threads = await loadThreads();
    try {
      return threads.firstWhere((t) => t.parentMessageId == parentMessageId);
    } catch (_) {
      return null;
    }
  }

  /// Get all threads for a chat
  Future<List<ThreadRecord>> getThreadsByChat(String chatId) async {
    final threads = await loadThreads();
    return threads.where((t) => t.chatId == chatId).toList();
  }

  /// Clear all threads
  Future<void> clearThreads() async {
    await saveThreads(<ThreadRecord>[]);
  }

  /// Add a reply to a thread
  Future<void> addReply(String parentMessageId, ThreadReply reply) async {
    final thread = await getThread(parentMessageId);
    if (thread != null) {
      final updatedThread = thread.copyWith(
        replies: [...thread.replies, reply],
      );
      await saveThread(updatedThread);
    }
  }

  /// Remove a reply from a thread
  Future<void> removeReply(String parentMessageId, String replyId) async {
    final thread = await getThread(parentMessageId);
    if (thread != null) {
      final updatedReplies = thread.replies.where((r) => r.id != replyId).toList();
      final updatedThread = thread.copyWith(replies: updatedReplies);
      await saveThread(updatedThread);
    }
  }
}

class ThreadRecord {
  final String parentMessageId;
  final String chatId;
  final String parentContent;
  final DateTime parentTimestamp;
  final List<ThreadReply> replies;
  final DateTime createdAt;
  final String role;

  ThreadRecord({
    required this.parentMessageId,
    required this.chatId,
    required this.parentContent,
    required this.parentTimestamp,
    this.replies = const [],
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'parentMessageId': parentMessageId,
      'chatId': chatId,
      'parentContent': parentContent,
      'parentTimestamp': parentTimestamp.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ThreadRecord.fromJson(Map<String, dynamic> json) {
    return ThreadRecord(
      role: json['role'] as String,
      parentMessageId: json['parentMessageId'] as String,
      chatId: json['chatId'] as String,
      parentContent: json['parentContent'] as String,
      parentTimestamp: DateTime.parse(json['parentTimestamp'] as String),
      replies: (json['replies'] as List<dynamic>?)
          ?.map((r) => ThreadReply.fromJson(r as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  ThreadRecord copyWith({
    String? parentMessageId,
    String? chatId,
    String? parentContent,
    DateTime? parentTimestamp,
    List<ThreadReply>? replies,
    DateTime? createdAt,
    String? role,
  }) {
    return ThreadRecord(
      parentMessageId: parentMessageId ?? this.parentMessageId,
      chatId: chatId ?? this.chatId,
      parentContent: parentContent ?? this.parentContent,
      parentTimestamp: parentTimestamp ?? this.parentTimestamp,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}

class ThreadReply {
  final String id;
  final String content;
  final String role;
  final DateTime timestamp;

  ThreadReply({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ThreadReply.fromJson(Map<String, dynamic> json) {
    return ThreadReply(
      id: json['id'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  ThreadReply copyWith({
    String? id,
    String? content,
    String? role,
    DateTime? timestamp,
  }) {
    return ThreadReply(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}