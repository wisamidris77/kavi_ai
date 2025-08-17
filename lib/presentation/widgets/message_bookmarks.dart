import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/chat_message_model.dart' as domain_msg;
import '../../domain/models/chat_role.dart';
import '../../core/bookmarks/bookmarks_storage_service.dart';

class MessageBookmarks extends StatefulWidget {
  final List<BookmarkedMessage> bookmarkedMessages;
  final Function(domain_msg.ChatMessageModel)? onMessageSelected;
  final Function(BookmarkedMessage)? onRemoveBookmark;
  final bool showRemoveButton;

  const MessageBookmarks({
    super.key,
    required this.bookmarkedMessages,
    this.onMessageSelected,
    this.onRemoveBookmark,
    this.showRemoveButton = true,
  });

  @override
  State<MessageBookmarks> createState() => _MessageBookmarksState();
}

class _MessageBookmarksState extends State<MessageBookmarks> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<BookmarkedMessage> get filteredBookmarks {
    var filtered = widget.bookmarkedMessages;
    
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((bookmark) {
        return bookmark.message.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               bookmark.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               bookmark.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((bookmark) => bookmark.category == _selectedCategory).toList();
    }
    
    return filtered;
  }

  List<String> get categories {
    final categories = <String>{'All'};
    for (final bookmark in widget.bookmarkedMessages) {
      categories.add(bookmark.category);
    }
    return categories.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.bookmarkedMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No bookmarks yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bookmark important messages to find them later',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search and filter bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search field
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search bookmarks...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              
              // Category filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: colorScheme.surfaceVariant,
                        selectedColor: colorScheme.primaryContainer,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Results count
        if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${filteredBookmarks.length} bookmark${filteredBookmarks.length == 1 ? '' : 's'} found',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

        // Bookmarks list
        Expanded(
          child: filteredBookmarks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarks found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = filteredBookmarks[index];
                    return _BookmarkTile(
                      bookmark: bookmark,
                      onTap: () => widget.onMessageSelected?.call(bookmark.message),
                      onRemove: () => widget.onRemoveBookmark?.call(bookmark),
                      showRemoveButton: widget.showRemoveButton,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  final BookmarkedMessage bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const _BookmarkTile({
    required this.bookmark,
    this.onTap,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bookmark.note,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showRemoveButton)
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: onRemove,
                      tooltip: 'Remove bookmark',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bookmark.category,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Message preview
              Text(
                bookmark.message.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Footer
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimestamp(bookmark.bookmarkedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(bookmark.message.createdAt ?? DateTime.now()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class BookmarkedMessage {
  final domain_msg.ChatMessageModel message;
  final String note;
  final String category;
  final DateTime bookmarkedAt;
  final List<String> tags;

  const BookmarkedMessage({
    required this.message,
    required this.note,
    required this.category,
    required this.bookmarkedAt,
    this.tags = const [],
  });

  BookmarkedMessage copyWith({
    domain_msg.ChatMessageModel? message,
    String? note,
    String? category,
    DateTime? bookmarkedAt,
    List<String>? tags,
  }) {
    return BookmarkedMessage(
      message: message ?? this.message,
      note: note ?? this.note,
      category: category ?? this.category,
      bookmarkedAt: bookmarkedAt ?? this.bookmarkedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': message.id,
      'note': note,
      'category': category,
      'bookmarkedAt': bookmarkedAt.toIso8601String(),
      'tags': tags,
    };
  }

  factory BookmarkedMessage.fromJson(Map<String, dynamic> json, domain_msg.ChatMessageModel message) {
    return BookmarkedMessage(
      message: message,
      note: json['note'] as String,
      category: json['category'] as String,
      bookmarkedAt: DateTime.parse(json['bookmarkedAt'] as String),
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }
}

class BookmarkMessageButton extends StatelessWidget {
  final domain_msg.ChatMessageModel message;
  final bool isBookmarked;
  final VoidCallback? onBookmark;
  final VoidCallback? onUnbookmark;

  const BookmarkMessageButton({
    super.key,
    required this.message,
    required this.isBookmarked,
    this.onBookmark,
    this.onUnbookmark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      icon: Icon(
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        color: isBookmarked ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      onPressed: isBookmarked ? onUnbookmark : onBookmark,
      tooltip: isBookmarked ? 'Remove bookmark' : 'Add bookmark',
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
    );
  }
}

class BookmarkMessageDialog extends StatefulWidget {
  final domain_msg.ChatMessageModel message;
  final Function(String note, String category, List<String> tags)? onBookmark;

  const BookmarkMessageDialog({
    super.key,
    required this.message,
    this.onBookmark,
  });

  @override
  State<BookmarkMessageDialog> createState() => _BookmarkMessageDialogState();
}

class _BookmarkMessageDialogState extends State<BookmarkMessageDialog> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _handleBookmark() {
    final note = _noteController.text.trim();
    final category = _categoryController.text.trim();
    final tags = _tagsController.text.trim().split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

    if (note.isNotEmpty && category.isNotEmpty) {
      widget.onBookmark?.call(note, category, tags);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: const Text('Bookmark Message'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.message.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),

            // Note field
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'What is this message about?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Category field
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g., Code, Ideas, Questions',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Tags field
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'comma, separated, tags',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleBookmark,
          child: const Text('Bookmark'),
        ),
      ],
    );
  }
}

class BookmarkManager extends ChangeNotifier {
  final Map<String, BookmarkedMessage> _bookmarks = {};
  final BookmarksStorageService _storage = BookmarksStorageService();

  List<BookmarkedMessage> get bookmarks => _bookmarks.values.toList();

  bool isBookmarked(String messageId) {
    return _bookmarks.containsKey(messageId);
  }

  BookmarkedMessage? getBookmark(String messageId) {
    return _bookmarks[messageId];
  }

  void addBookmark(domain_msg.ChatMessageModel message, String note, String category, List<String> tags) {
    final bookmark = BookmarkedMessage(
      message: message,
      note: note,
      category: category,
      bookmarkedAt: DateTime.now(),
      tags: tags,
    );
    
    _bookmarks[message.id] = bookmark;
    notifyListeners();
    _saveBookmarks();
  }

  void removeBookmark(String messageId) {
    _bookmarks.remove(messageId);
    notifyListeners();
    _saveBookmarks();
  }

  void updateBookmark(String messageId, String note, String category, List<String> tags) {
    final existing = _bookmarks[messageId];
    if (existing != null) {
      _bookmarks[messageId] = existing.copyWith(
        note: note,
        category: category,
        tags: tags,
      );
      notifyListeners();
      _saveBookmarks();
    }
  }

  Future<void> _saveBookmarks() async {
    try {
      final bookmarks = _bookmarks.values.map((bookmark) {
        return BookmarkRecord(
          messageId: bookmark.message.id,
          chatId: bookmark.message.chatId ?? '',
          content: bookmark.message.content,
          role: bookmark.message.role.name,
          timestamp: bookmark.message.createdAt ?? DateTime.now(),
          note: bookmark.note,
          tags: bookmark.tags,
        );
      }).toList();
      
      await _storage.saveBookmarks(bookmarks);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  Future<void> loadBookmarks() async {
    try {
      final records = await _storage.loadBookmarks();
      
      _bookmarks.clear();
      for (final record in records) {
        final message = domain_msg.ChatMessageModel(
          id: record.messageId,
          role: _parseRole(record.role),
          content: record.content,
          createdAt: record.timestamp,
        );
        
        final bookmark = BookmarkedMessage(
          message: message,
          note: record.note,
          category: record.tags.isNotEmpty ? record.tags.first : 'General',
          bookmarkedAt: record.createdAt,
          tags: record.tags,
        );
        
        _bookmarks[record.messageId] = bookmark;
      }
      
      notifyListeners();
    } catch (e) {
      // Silently handle storage errors
    }
  }

  ChatRole _parseRole(String role) {
    switch (role.toLowerCase()) {
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      case 'system':
        return ChatRole.system;
      case 'tool':
        return ChatRole.tool;
      default:
        return ChatRole.user;
    }
  }
}