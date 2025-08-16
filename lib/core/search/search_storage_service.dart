import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchStorageService {
  static const String _searchHistoryKey = 'search_history_v1';
  static const String _searchFiltersKey = 'search_filters_v1';
  static const int _maxHistoryItems = 20;

  /// Load search history from persistent storage
  Future<List<String>> loadSearchHistory() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_searchHistoryKey);
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

  /// Save search history to persistent storage
  Future<void> saveSearchHistory(List<String> history) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(history);
    await prefs.setString(_searchHistoryKey, raw);
  }

  /// Add a search query to history
  Future<void> addToSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final history = await loadSearchHistory();
    
    // Remove if already exists (to move to top)
    history.remove(query.trim());
    
    // Add to beginning
    history.insert(0, query.trim());
    
    // Keep only max items
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    await saveSearchHistory(history);
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await saveSearchHistory(<String>[]);
  }

  /// Remove a specific item from search history
  Future<void> removeFromSearchHistory(String query) async {
    final history = await loadSearchHistory();
    history.remove(query);
    await saveSearchHistory(history);
  }

  /// Load search filters from persistent storage
  Future<Map<String, dynamic>> loadSearchFilters() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_searchFiltersKey);
    if (raw == null || raw.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
      return map;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Save search filters to persistent storage
  Future<void> saveSearchFilters(Map<String, dynamic> filters) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = jsonEncode(filters);
    await prefs.setString(_searchFiltersKey, raw);
  }

  /// Get recent searches (last 5)
  Future<List<String>> getRecentSearches() async {
    final history = await loadSearchHistory();
    return history.take(5).toList();
  }

  /// Check if a query exists in history
  Future<bool> hasSearchQuery(String query) async {
    final history = await loadSearchHistory();
    return history.contains(query.trim());
  }
}