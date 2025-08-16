import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class McpToolsStorage {
  static const String _favoritesKey = 'mcp_tools_favorites_v1';
  static const String _historyKey = 'mcp_tools_history_v1';

  /// Load favorite tools from persistent storage
  Future<List<String>> loadFavorites() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_favoritesKey);
    if (raw == null || raw.isEmpty) {
      return <String>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<String>().toList();
    } catch (_) {
      return <String>[];
    }
  }

  /// Save favorite tools to persistent storage
  Future<void> saveFavorites(List<String> favorites) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(favorites);
    await prefs.setString(_favoritesKey, raw);
  }

  /// Add a tool to favorites
  Future<void> addToFavorites(String toolKey) async {
    final favorites = await loadFavorites();
    if (!favorites.contains(toolKey)) {
      favorites.add(toolKey);
      await saveFavorites(favorites);
    }
  }

  /// Remove a tool from favorites
  Future<void> removeFromFavorites(String toolKey) async {
    final favorites = await loadFavorites();
    favorites.remove(toolKey);
    await saveFavorites(favorites);
  }

  /// Check if a tool is in favorites
  Future<bool> isFavorite(String toolKey) async {
    final favorites = await loadFavorites();
    return favorites.contains(toolKey);
  }

  /// Load tool execution history from persistent storage
  Future<List<ToolExecutionRecord>> loadHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return <ToolExecutionRecord>[];
    }
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> m) => ToolExecutionRecord.fromJson(m))
          .toList();
    } catch (_) {
      return <ToolExecutionRecord>[];
    }
  }

  /// Save tool execution history to persistent storage
  Future<void> saveHistory(List<ToolExecutionRecord> history) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(history.map((h) => h.toJson()).toList());
    await prefs.setString(_historyKey, raw);
  }

  /// Add a tool execution record to history
  Future<void> addToHistory(ToolExecutionRecord record) async {
    final history = await loadHistory();
    history.insert(0, record); // Add to beginning
    
    // Keep only last 100 records
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    
    await saveHistory(history);
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await saveHistory(<ToolExecutionRecord>[]);
  }
}

class ToolExecutionRecord {
  final String toolKey;
  final String toolName;
  final DateTime timestamp;
  final Map<String, dynamic>? arguments;
  final String? result;
  final String? error;
  final Duration duration;

  ToolExecutionRecord({
    required this.toolKey,
    required this.toolName,
    required this.timestamp,
    this.arguments,
    this.result,
    this.error,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'toolKey': toolKey,
      'toolName': toolName,
      'timestamp': timestamp.toIso8601String(),
      'arguments': arguments,
      'result': result,
      'error': error,
      'duration': duration.inMilliseconds,
    };
  }

  factory ToolExecutionRecord.fromJson(Map<String, dynamic> json) {
    return ToolExecutionRecord(
      toolKey: json['toolKey'] as String,
      toolName: json['toolName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      arguments: json['arguments'] as Map<String, dynamic>?,
      result: json['result'] as String?,
      error: json['error'] as String?,
      duration: Duration(milliseconds: json['duration'] as int),
    );
  }
}