import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:kavi/core/chat/chat_message.dart';
import '../../core/thread/thread_storage_service.dart';

class ThreadView extends StatefulWidget {
  final List<ThreadMessage> threadMessages;
  final Function(ChatMessage)? onMessageSelected;
  final Function(ChatMessage)? onReplyToMessage;
  final bool showThreadIndicator;

  const ThreadView({
    super.key,
    required this.threadMessages,
    this.onMessageSelected,
    this.onReplyToMessage,
    this.showThreadIndicator = true,
  });

  @override
  State<ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<ThreadView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.threadMessages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No thread messages',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This thread is empty',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.threadMessages.length,
      itemBuilder: (context, index) {
        final threadMessage = widget.threadMessages[index];
        final isLast = index == widget.threadMessages.length - 1;

        return _ThreadMessageTile(
          threadMessage: threadMessage,
          onTap: () => widget.onMessageSelected?.call(threadMessage.message),
          onReply: () => widget.onReplyToMessage?.call(threadMessage.message),
          showThreadLine: !isLast,
          showThreadIndicator: widget.showThreadIndicator,
        );
      },
    );
  }
}

class _ThreadMessageTile extends StatelessWidget {
  final ThreadMessage threadMessage;
  final VoidCallback? onTap;
  final VoidCallback? onReply;
  final bool showThreadLine;
  final bool showThreadIndicator;

  const _ThreadMessageTile({
    required this.threadMessage,
    this.onTap,
    this.onReply,
    this.showThreadLine = true,
    this.showThreadIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thread line and indicator
        if (showThreadIndicator)
          Container(
            width: 40,
            child: Column(
              children: [
                // Thread indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (showThreadLine)
                  Container(
                    width: 2,
                    height: 40,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ),
          ),

        // Message content
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.reply,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reply to message',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatTimestamp(threadMessage.message.createdAt ?? DateTime.now()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Message content
                Text(
                  threadMessage.message.content,
                  style: theme.textTheme.bodyMedium,
                ),

                // Actions
                if (onReply != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: onReply,
                          icon: const Icon(Icons.reply, size: 16),
                          label: const Text('Reply'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

class ThreadMessage {
  final ChatMessage message;
  final String? parentMessageId;
  final int depth;
  final List<String> childMessageIds;

  const ThreadMessage({
    required this.message,
    this.parentMessageId,
    this.depth = 0,
    this.childMessageIds = const [],
  });

  ThreadMessage copyWith({
    ChatMessage? message,
    String? parentMessageId,
    int? depth,
    List<String>? childMessageIds,
  }) {
    return ThreadMessage(
      message: message ?? this.message,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      depth: depth ?? this.depth,
      childMessageIds: childMessageIds ?? this.childMessageIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': message.id,
      'parentMessageId': parentMessageId,
      'depth': depth,
      'childMessageIds': childMessageIds,
    };
  }

  factory ThreadMessage.fromJson(Map<String, dynamic> json, ChatMessage message) {
    return ThreadMessage(
      message: message,
      parentMessageId: json['parentMessageId'] as String?,
      depth: json['depth'] as int? ?? 0,
      childMessageIds: List<String>.from(json['childMessageIds'] as List? ?? []),
    );
  }
}

class ThreadManager extends ChangeNotifier {
  final Map<String, ThreadMessage> _threadMessages = {};
  final ThreadStorageService _storage = ThreadStorageService();
  final Map<String, List<String>> _threadHierarchy = {};

  List<ThreadMessage> get allThreadMessages => _threadMessages.values.toList();

  List<ThreadMessage> getThreadForMessage(String messageId) {
    final thread = <ThreadMessage>[];
    final visited = <String>{};

    void addToThread(String id) {
      if (visited.contains(id)) return;
      visited.add(id);

      final threadMessage = _threadMessages[id];
      if (threadMessage != null) {
        thread.add(threadMessage);
        
        // Add children
        for (final childId in threadMessage.childMessageIds) {
          addToThread(childId);
        }
      }
    }

    addToThread(messageId);
    return thread;
  }

  List<ThreadMessage> getRepliesToMessage(String messageId) {
    final replies = <ThreadMessage>[];
    
    for (final threadMessage in _threadMessages.values) {
      if (threadMessage.parentMessageId == messageId) {
        replies.add(threadMessage);
      }
    }

    return replies..sort((a, b) => a.message.createdAt!.compareTo(b.message.createdAt!));
  }

  void addReply(ChatMessage parentMessage, ChatMessage replyMessage) {
    final parentThreadMessage = _threadMessages[parentMessage.id];
    final depth = parentThreadMessage?.depth ?? 0;

    final threadMessage = ThreadMessage(
      message: replyMessage,
      parentMessageId: parentMessage.id,
      depth: depth + 1,
    );

    _threadMessages[replyMessage.id] = threadMessage;

    // Update parent's child list
    if (parentThreadMessage != null) {
      final updatedParent = parentThreadMessage.copyWith(
        childMessageIds: [...parentThreadMessage.childMessageIds, replyMessage.id],
      );
      _threadMessages[parentMessage.id] = updatedParent;
    }

    notifyListeners();
    _saveThreadData();
  }

  void removeThreadMessage(String messageId) {
    final threadMessage = _threadMessages[messageId];
    if (threadMessage != null) {
      // Remove from parent's child list
      if (threadMessage.parentMessageId != null) {
        final parent = _threadMessages[threadMessage.parentMessageId!];
        if (parent != null) {
          final updatedParent = parent.copyWith(
            childMessageIds: parent.childMessageIds.where((id) => id != messageId).toList(),
          );
          _threadMessages[threadMessage.parentMessageId!] = updatedParent;
        }
      }

      // Remove all children recursively
      for (final childId in threadMessage.childMessageIds) {
        removeThreadMessage(childId);
      }

      _threadMessages.remove(messageId);
      notifyListeners();
      _saveThreadData();
    }
  }

  bool isInThread(String messageId) {
    return _threadMessages.containsKey(messageId);
  }

  bool hasReplies(String messageId) {
    final threadMessage = _threadMessages[messageId];
    return threadMessage?.childMessageIds.isNotEmpty ?? false;
  }

  int getReplyCount(String messageId) {
    final threadMessage = _threadMessages[messageId];
    return threadMessage?.childMessageIds.length ?? 0;
  }

  Future<void> _saveThreadData() async {
    try {
      final threads = _threadMessages.values.map((threadMessage) {
        return ThreadRecord(
          parentMessageId: threadMessage.message.id,
          chatId: threadMessage.message.chatId ?? '',
          parentContent: threadMessage.message.content,
          parentTimestamp: threadMessage.message.createdAt ?? DateTime.now(),
          role: threadMessage.message.role.name,
          replies: threadMessage.childMessageIds.map((childId) {
            final childMessage = _threadMessages[childId]?.message;
            return ThreadReply(
              id: childId,
              content: childMessage?.content ?? '',
              role: childMessage?.role.name ?? 'user',
              timestamp: childMessage?.createdAt ?? DateTime.now(),
            );
          }).toList(),
        );
      }).toList();
      
      await _storage.saveThreads(threads);
    } catch (e) {
      // Silently handle storage errors
    }
  }

  Future<void> loadThreadData() async {
    try {
      final records = await _storage.loadThreads();
      
      _threadMessages.clear();
      for (final record in records) {
        final parentMessage = ChatMessage(
          id: record.parentMessageId,
          role: _parseRole(record.role),
          content: record.parentContent,
          createdAt: record.parentTimestamp,
          chatId: record.chatId,
        );
        
        final childMessageIds = record.replies.map((r) => r.id).toList();
        
        final threadMessage = ThreadMessage(
            message: parentMessage,
          childMessageIds: childMessageIds,
        );
        
        _threadMessages[record.parentMessageId] = threadMessage;
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
      default:
        return ChatRole.user;
    }
  }
}

class ThreadIndicator extends StatelessWidget {
  final int replyCount;
  final VoidCallback? onTap;

  const ThreadIndicator({
    super.key,
    required this.replyCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (replyCount == 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.reply,
              size: 14,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThreadReplyButton extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onReply;

  const ThreadReplyButton({
    super.key,
    required this.message,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IconButton(
      icon: const Icon(Icons.reply, size: 16),
      onPressed: onReply,
      tooltip: 'Reply in thread',
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(
        minWidth: 24,
        minHeight: 24,
      ),
    );
  }
}