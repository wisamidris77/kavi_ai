import 'package:flutter/material.dart';
import 'package:kavi/core/chat/chat_message.dart';
import 'dart:async';
import '../../core/search/search_storage_service.dart';

class MessageSearch extends StatefulWidget {
  final List<ChatMessage> messages;
  final Function(ChatMessage)? onMessageSelected;
  final bool showFilters;
  final bool showSearchHistory;

  const MessageSearch({
    super.key,
    required this.messages,
    this.onMessageSelected,
    this.showFilters = true,
    this.showSearchHistory = true,
  });

  @override
  State<MessageSearch> createState() => _MessageSearchState();
}

class _MessageSearchState extends State<MessageSearch> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchStorageService _storage = SearchStorageService();
  
  String _searchQuery = '';
  SearchFilter _currentFilter = SearchFilter.all;
  List<ChatMessage> _searchResults = [];
  List<String> _searchHistory = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSearchHistory());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final history = await _storage.loadSearchHistory();
      setState(() {
        _searchHistory = history;
      });
    } catch (e) {
      // Fallback to empty list
      setState(() {
        _searchHistory = [];
      });
    }
  }

  Future<void> _saveSearchHistory() async {
    if (_searchQuery.isNotEmpty && !_searchHistory.contains(_searchQuery)) {
      setState(() {
        _searchHistory.insert(0, _searchQuery);
        if (_searchHistory.length > 10) {
          _searchHistory = _searchHistory.take(10).toList();
        }
      });
      
      try {
        await _storage.addToSearchHistory(_searchQuery);
      } catch (e) {
        // Silently handle storage errors
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isNotEmpty) {
      _performSearch();
    } else {
      setState(() {
        _searchResults.clear();
      });
    }
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      setState(() {
        _searchResults.clear();
      });
      return;
    }

    final results = widget.messages.where((message) {
      // Apply role filter
      if (_currentFilter != SearchFilter.all) {
        switch (_currentFilter) {
          case SearchFilter.user:
            if (message.role != ChatRole.user) return false;
            break;
          case SearchFilter.assistant:
            if (message.role != ChatRole.assistant) return false;
            break;
          case SearchFilter.system:
            if (message.role != ChatRole.system) return false;
            break;
          default:
            break;
        }
      }

      // Search in content
      final content = message.content.toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return content.contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  void _onFilterChanged(SearchFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
    _performSearch();
  }

  void _onHistoryItemSelected(String query) {
    _searchController.text = query;
    _searchFocusNode.requestFocus();
  }

  void _onResultSelected(ChatMessage message) {
    _saveSearchHistory();
    widget.onMessageSelected?.call(message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Messages'),
        actions: [
          if (widget.showFilters)
            PopupMenuButton<SearchFilter>(
              icon: const Icon(Icons.filter_list),
              onSelected: _onFilterChanged,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: SearchFilter.all,
                  child: Text('All Messages'),
                ),
                const PopupMenuItem(
                  value: SearchFilter.user,
                  child: Text('Your Messages'),
                ),
                const PopupMenuItem(
                  value: SearchFilter.assistant,
                  child: Text('Assistant Messages'),
                ),
                const PopupMenuItem(
                  value: SearchFilter.system,
                  child: Text('System Messages'),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),

          // Filter chips
          if (widget.showFilters && _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: SearchFilter.values.map((filter) {
                    final isSelected = _currentFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getFilterLabel(filter)),
                        selected: isSelected,
                        onSelected: (_) => _onFilterChanged(filter),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        selectedColor: colorScheme.primaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Results count
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${_searchResults.length} result${_searchResults.length == 1 ? '' : 's'} found',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Search history (when no query)
          if (!_isSearching && widget.showSearchHistory && _searchHistory.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Recent Searches',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        final query = _searchHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(query),
                          onTap: () => _onHistoryItemSelected(query),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchHistory.removeAt(index);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Search results
          if (_isSearching)
            Expanded(
              child: _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No messages found',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final message = _searchResults[index];
                        return _SearchResultTile(
                          message: message,
                          searchQuery: _searchQuery,
                          onTap: () => _onResultSelected(message),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  String _getFilterLabel(SearchFilter filter) {
    switch (filter) {
      case SearchFilter.all:
        return 'All';
      case SearchFilter.user:
        return 'You';
      case SearchFilter.assistant:
        return 'Assistant';
      case SearchFilter.system:
        return 'System';
    }
  }
}

class _SearchResultTile extends StatelessWidget {
  final ChatMessage message;
  final String searchQuery;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.message,
    required this.searchQuery,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.role == ChatRole.user;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isUser 
            ? colorScheme.primaryContainer 
            : colorScheme.surfaceContainerHighest,
        child: Icon(
          isUser ? Icons.person : Icons.smart_toy,
          color: isUser 
              ? colorScheme.onPrimaryContainer 
              : colorScheme.onSurfaceVariant,
        ),
      ),
      title: _HighlightedText(
        text: message.content,
        highlight: searchQuery,
        style: theme.textTheme.bodyMedium,
        highlightStyle: theme.textTheme.bodyMedium?.copyWith(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        _formatTimestamp(message.createdAt ?? DateTime.now()),
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(
        _getRoleIcon(message.role),
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getRoleIcon(ChatRole role) {
    switch (role) {
      case ChatRole.user:
        return Icons.person;
      case ChatRole.assistant:
        return Icons.smart_toy;
      case ChatRole.system:
        return Icons.settings;
      default:
        return Icons.message;
    }
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String highlight;
  final TextStyle? style;
  final TextStyle? highlightStyle;

  const _HighlightedText({
    required this.text,
    required this.highlight,
    this.style,
    this.highlightStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight.isEmpty) {
      return Text(text, style: style);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerHighlight, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: style,
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + highlight.length),
        style: highlightStyle,
      ));

      start = index + highlight.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );
  }
}

enum SearchFilter {
  all,
  user,
  assistant,
  system,
}