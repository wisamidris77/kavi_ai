import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksStorageService {
  static const String _bookmarksKey = 'message_bookmarks_v1';

  /// Load bookmarks from persistent storage
  Future<List<BookmarkRecord>> loadBookmarks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_bookmarksKey);
    if (raw == null || raw.isEmpty) {
      return <BookmarkRecord>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> m) => BookmarkRecord.fromJson(m))
          .toList();
    } catch (_) {
      return <BookmarkRecord>[];
    }
  }

  /// Save bookmarks to persistent storage
  Future<void> saveBookmarks(List<BookmarkRecord> bookmarks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(bookmarks.map((b) => b.toJson()).toList());
    await prefs.setString(_bookmarksKey, raw);
  }

  /// Add a bookmark
  Future<void> addBookmark(BookmarkRecord bookmark) async {
    final bookmarks = await loadBookmarks();
    
    // Check if already exists
    final existingIndex = bookmarks.indexWhere((b) => b.messageId == bookmark.messageId);
    if (existingIndex != -1) {
      bookmarks[existingIndex] = bookmark;
    } else {
      bookmarks.add(bookmark);
    }
    
    await saveBookmarks(bookmarks);
  }

  /// Remove a bookmark
  Future<void> removeBookmark(String messageId) async {
    final bookmarks = await loadBookmarks();
    bookmarks.removeWhere((b) => b.messageId == messageId);
    await saveBookmarks(bookmarks);
  }

  /// Check if a message is bookmarked
  Future<bool> isBookmarked(String messageId) async {
    final bookmarks = await loadBookmarks();
    return bookmarks.any((b) => b.messageId == messageId);
  }

  /// Get bookmark for a specific message
  Future<BookmarkRecord?> getBookmark(String messageId) async {
    final bookmarks = await loadBookmarks();
    try {
      return bookmarks.firstWhere((b) => b.messageId == messageId);
    } catch (_) {
      return null;
    }
  }

  /// Clear all bookmarks
  Future<void> clearBookmarks() async {
    await saveBookmarks(<BookmarkRecord>[]);
  }

  /// Get bookmarks by chat ID
  Future<List<BookmarkRecord>> getBookmarksByChat(String chatId) async {
    final bookmarks = await loadBookmarks();
    return bookmarks.where((b) => b.chatId == chatId).toList();
  }

  /// Search bookmarks by content
  Future<List<BookmarkRecord>> searchBookmarks(String query) async {
    final bookmarks = await loadBookmarks();
    final lowercaseQuery = query.toLowerCase();
    
    return bookmarks.where((b) {
      return b.content.toLowerCase().contains(lowercaseQuery) ||
             b.note.toLowerCase().contains(lowercaseQuery) ||
             b.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}

class BookmarkRecord {
  final String messageId;
  final String chatId;
  final String content;
  final String role;
  final DateTime timestamp;
  final String note;
  final List<String> tags;
  final DateTime createdAt;

  BookmarkRecord({
    required this.messageId,
    required this.chatId,
    required this.content,
    required this.role,
    required this.timestamp,
    this.note = '',
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BookmarkRecord.fromJson(Map<String, dynamic> json) {
    return BookmarkRecord(
      messageId: json['messageId'] as String,
      chatId: json['chatId'] as String,
      content: json['content'] as String,
      role: json['role'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  BookmarkRecord copyWith({
    String? messageId,
    String? chatId,
    String? content,
    String? role,
    DateTime? timestamp,
    String? note,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return BookmarkRecord(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}